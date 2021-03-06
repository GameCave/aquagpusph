/*
 *  This file is part of AQUAgpusph, a free CFD program based on SPH.
 *  Copyright (C) 2012  Jose Luis Cercos Pita <jl.cercos@upm.es>
 *
 *  AQUAgpusph is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  AQUAgpusph is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with AQUAgpusph.  If not, see <http://www.gnu.org/licenses/>.
 */

/** @file
 * @brief Particles interactions computation.
 */

#if defined(LOCAL_MEM_SIZE) && defined(NO_LOCAL_MEM)
    #error NO_LOCAL_MEM has been set.
#endif

#ifndef HAVE_3D
    #include "../../types/2D.h"
    #include "../../KernelFunctions/Wendland2D.hcl"
#else
    #include "../../types/3D.h"
    #include "../../KernelFunctions/Wendland3D.hcl"
#endif

/** @brief Particles interactions computation.
 *
 * Compute the rates of variation due to the fluid (fixed particles will be
 * included here).
 *
 * During this stage some other operations are performed as well, like the
 * values interpolation in the boundaries (for DeLeffe boundary conditions),
 * the sensors meassurement, or the Shepard factor computation.
 * @param iset Set of particles index.
 * @param imove Moving flags.
 *   - imove > 0 for regular fluid particles.
 *   - imove = 0 for sensors.
 *   - imove < 0 for boundary elements/particles.
 * @param imirrored 0 if the particle has not been mirrored, 1 otherwise.
 * @param r Position \f$ \mathbf{r} \f$.
 * @param rmirrored Mirrored position of the particle, \a r if \a imirrored is
 * false (0).
 * @param u Velocity \f$ \mathbf{u} \f$.
 * @param umirrored Mirrored velocity of the particle, \a u if \a imirrored is
 * false (0).
 * @param rho Density \f$ \rho \f$.
 * @param m Mass \f$ m \f$.
 * @param p Pressure \f$ p \f$.
 * @param refd Density of reference \f$ \rho_0 \f$ (one per set of particles)
 * @param grad_p Pressure gradient \f$ \frac{\nabla p}{rho} \f$.
 * @param lap_u Velocity laplacian \f$ \frac{\Delta \mathbf{u}}{rho} \f$.
 * @param div_u Velocity divergence \f$ \rho \nabla \cdot \mathbf{u} \f$.
 * @param lap_p Pressure laplacian \f$ \Delta p \f$.
 * @param shepard Shepard term
 * \f$ \gamma(\mathbf{x}) = \int_{\Omega}
 *     W(\mathbf{y} - \mathbf{x}) \mathrm{d}\mathbf{x} \f$.
 * @param icell Cell where each particle is located.
 * @param ihoc Head of chain for each cell (first particle found).
 * @param N Number of particles.
 * @param n_cells Number of cells in each direction
 * @param g Gravity acceleration \f$ \mathbf{g} \f$.
 */
__kernel void entry(const __global uint* iset,
                    const __global int* imove,
                    const __global int* imirrored,
                    const __global vec* r,
                    const __global vec* rmirrored,
                    const __global vec* u,
                    const __global vec* umirrored,
                     const __global float* rho,
                    const __global float* m,
                    const __global float* p,
                    __constant float* refd,
                    __global vec* grad_p,
                    __global vec* lap_u,
                    __global float* div_u,
                    __global float* lap_p,
                    __global float* shepard,
                    // Link-list data
                    __global uint *icell,
                     __global uint *ihoc,
                    // Simulation data
                    uint N,
                    uivec4 n_cells,
                    vec g)
{
    const uint i = get_global_id(0);
    const uint it = get_local_id(0);
    if(i >= N)
        return;
    if((!imirrored[i]) || (imove[i] <= 0))
        return;

    const uint c_i = icell[i];
    const vec_xyz r_i = r[i].XYZ;
    const vec_xyz u_i = u[i].XYZ;
    const float p_i = p[i];
    const float rho_i = rho[i];
    const float refd_i = refd[iset[i]];

    const float prfac_i = p_i / (rho_i * rho_i);

    // Initialize the output
    #ifndef LOCAL_MEM_SIZE
        #define _GRADP_ grad_p[i].XYZ
        #define _LAPU_ lap_u[i].XYZ
        #define _DIVU_ div_u[i]
        #define _LAPP_ lap_p[i]
        #define _SHEPARD_ shepard[i]
    #else
        #define _GRADP_ grad_p_l[it]
        #define _LAPU_ lap_u_l[it]
        #define _DIVU_ div_u_l[it]
        #define _LAPP_ lap_p_l[it]
        #define _SHEPARD_ shepard_l[it]
        __local vec_xyz grad_p_l[LOCAL_MEM_SIZE];
        __local vec_xyz lap_u_l[LOCAL_MEM_SIZE];
        __local float div_u_l[LOCAL_MEM_SIZE];
        __local float lap_p_l[LOCAL_MEM_SIZE];
        __local float shepard_l[LOCAL_MEM_SIZE];
        _GRADP_ = grad_p[i].XYZ;
        _LAPU_ = lap_u[i].XYZ;
        _DIVU_ = div_u[i];
        _LAPP_ = lap_p[i];
        _SHEPARD_ = shepard[i];
    #endif

    // Loop over neighs
    // ================
    for(int ci = -1; ci <= 1; ci++) {
        for(int cj = -1; cj <= 1; cj++) {
            #ifdef HAVE_3D
            for(int ck = -1; ck <= 1; ck++) {
            #else
            const int ck = 0; {
            #endif
                const uint c_j = c_i +
                                 ci +
                                 cj * n_cells.x +
                                 ck * n_cells.x * n_cells.y;
                uint j = ihoc[c_j];
                while((j < N) && (icell[j] == c_j)) {
                    const int move_j = imove[j];
                    if((!imirrored[j]) ||
                       ((imove[j] != 1) && (imove[j] != -1))){
                        j++;
                        continue;
                    }
                    const vec_xyz r_ij = rmirrored[j].XYZ - r_i;
                    const float q = length(r_ij) / H;
                    if(q >= SUPPORT)
                    {
                        j++;
                        continue;
                    }

                    {
                        #include "Interactions.hcl"
                    }
                    j++;
                }
            }
        }
    }

    #ifdef LOCAL_MEM_SIZE
        grad_p[i].XYZ = _GRADP_;
        lap_u[i].XYZ = _LAPU_;
        div_u[i] = _DIVU_;
        lap_p[i] = _LAPP_;
        shepard[i] = _SHEPARD_;
    #endif
}

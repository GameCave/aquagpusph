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

#ifndef HAVE_3D
    #include "types/2D.h"
	#include "KernelFunctions/Wendland2D.hcl"
#else
    #include "types/3D.h"
	#include "KernelFunctions/Wendland3D.hcl"
#endif

#ifndef HAVE_3D
	#ifndef NEIGH_CELLS
		/** @def NEIGH_CELLS Number of neighbour cells. In 2D case 8,
		 * and the main cells must be computed, but in 3D 27 cells,
		 * must be computed.
		 */ 
		#define NEIGH_CELLS 9
	#endif
#else
	#ifndef NEIGH_CELLS
		#define NEIGH_CELLS 27
	#endif
#endif

__kernel void main(const __global uint* iset, const __global int* imove,
                   const __global vec* pos, const __global vec* v,
                   const __global float* rho, const __global float* m,
                   const __global float* p, __constant float* refd,
                   __global vec* grad_p, __global vec* lap_u,
                   __global float* div_u, __global float* lap_p,
                   __global float* shepard,
                    // Link-list data
                    __global uint *icell, __global uint *ihoc,
                    // Simulation data
                    uint N, uivec4 n_cells, float h, float support, vec g)
{
	const uint i = get_global_id(0);
	const uint it = get_local_id(0);
	if(i >= N)
		return;

    const uint c_i = icell[i];
    const int move_i = imove[i];
    const vec pos_i = pos[i];
    const vec v_i = v[i];
    const float p_i = p[i];
    const float rho_i = rho[i];
    const float refd_i = refd[iset[i]];

    const float prfac_i = p_i / (rho_i * rho_i);

	#ifndef HAVE_3D
		const float conw = 1.f/(h*h);
		const float conf = 1.f/(h*h*h*h);
	#else
		const float conw = 1.f/(h*h*h);
		const float conf = 1.f/(h*h*h*h*h);
	#endif

	// Initialize the output
    #ifndef LOCAL_MEM_SIZE
	    #define _GRADP_ grad_p[i]
	    #define _LAPU_ lap_u[it]
	    #define _DIVU_ div_u[i]
	    #define _LAPP_ lap_p[i]
    	#define _SHEPARD_ shepard[i]
    #else
	    #define _GRADP_ grad_p_l[it]
	    #define _LAPU_ lap_u_l[it]
	    #define _DIVU_ div_u_l[i]
	    #define _LAPP_ lap_p_l[it]
	    #define _SHEPARD_ shepard_l[it]
        __local vec grad_p_l[LOCAL_MEM_SIZE];
        __local vec lap_u_l[LOCAL_MEM_SIZE];
        __local float div_u_l[LOCAL_MEM_SIZE];
        __local float lap_p_l[LOCAL_MEM_SIZE];
        __local float shepard_l[LOCAL_MEM_SIZE];
    #endif
	_GRADP_ = VEC_ZERO;
	_LAPU_ = VEC_ZERO;
	_DIVU_ = 0.f;
	_LAPP_ = 0.f;
	_SHEPARD_ = 0.f;

	// Loop over neighbour particles
    // =============================
	{
        uint j;
        // Home cell, starting from the next particle
        // ==========================================
        j = i + 1;
		while((j < N) && (icell[j] == c_i) ) {
			if(move_i == 0){
				#include "InteractionsSensors.hcl"
			}
			else if((move_i == 1) || (move_i == -1)){
				#include "Interactions.hcl"
            }
            else{
				#include "InteractionsBounds.hcl"
            }
			j++;
		}

		// Neighbour cells
        // ===============
		for(uint cell = 1; cell < NEIGH_CELLS; cell++) {
            uint c_j;
			switch(cell) {
				case 0: c_j = c_i + 0; break;
				case 1: c_j = c_i + 1; break;
				case 2: c_j = c_i - 1; break;
				case 3: c_j = c_i + n_cells.x; break;
				case 4: c_j = c_i + n_cells.x + 1; break;
				case 5: c_j = c_i + n_cells.x - 1; break;
				case 6: c_j = c_i - n_cells.x; break;
				case 7: c_j = c_i - n_cells.x + 1; break;
				case 8: c_j = c_i - n_cells.x - 1; break;
				#ifdef HAVE_3D
					case 9 : c_j = c_i + 0             - n_cells.x*n_cells.y; break;
					case 10: c_j = c_i + 1             - n_cells.x*n_cells.y; break;
					case 11: c_j = c_i - 1             - n_cells.x*n_cells.y; break;
					case 12: c_j = c_i + n_cells.x     - n_cells.x*n_cells.y; break;
					case 13: c_j = c_i + n_cells.x + 1 - n_cells.x*n_cells.y; break;
					case 14: c_j = c_i + n_cells.x - 1 - n_cells.x*n_cells.y; break;
					case 15: c_j = c_i - n_cells.x     - n_cells.x*n_cells.y; break;
					case 16: c_j = c_i - n_cells.x + 1 - n_cells.x*n_cells.y; break;
					case 17: c_j = c_i - n_cells.x - 1 - n_cells.x*n_cells.y; break;

					case 18: c_j = c_i + 0             + n_cells.x*n_cells.y; break;
					case 19: c_j = c_i + 1             + n_cells.x*n_cells.y; break;
					case 20: c_j = c_i - 1             + n_cells.x*n_cells.y; break;
					case 21: c_j = c_i + n_cells.x     + n_cells.x*n_cells.y; break;
					case 22: c_j = c_i + n_cells.x + 1 + n_cells.x*n_cells.y; break;
					case 23: c_j = c_i + n_cells.x - 1 + n_cells.x*n_cells.y; break;
					case 24: c_j = c_i - n_cells.x     + n_cells.x*n_cells.y; break;
					case 25: c_j = c_i - n_cells.x + 1 + n_cells.x*n_cells.y; break;
					case 26: c_j = c_i - n_cells.x - 1 + n_cells.x*n_cells.y; break;
				#endif
			}

			j = ihoc[c_j];
			while((j < N) && (icell[j] == c_j)) {
			    if(move_i == 0){
				    #include "InteractionsSensors.hcl"
			    }
			    else if((move_i == 1) || (move_i == -1)){
				    #include "Interactions.hcl"
                }
                else{
				    #include "InteractionsBounds.hcl"
                }
				j++;
			}			
		}

		// Home cell, starting from the head of chain
        // ==========================================
		j = ihoc[c_i];
		while(j < i) {
			if(move_i == 0){
				#include "InteractionsSensors.hcl"
			}
			else if((move_i == 1) || (move_i == -1)){
				#include "Interactions.hcl"
            }
            else{
				#include "InteractionsBounds.hcl"
            }
			j++;
		}
    }

	// Self particle effect
	// ====================
	if((move_i == 1) || (move_i == -1)){
		const float wab = kernelW(0.f) * conw * m[i];
		_SHEPARD_ += wab / rho_i;
    }

	#ifdef LOCAL_MEM_SIZE
		grad_p[i] = _GRADP_;
		lap_u[i] = _LAPU_;
		div_u[i] = _DIVU_;
		lap_p[i] = _LAPP_;
		shepard[i] = _SHEPARD_;
	#endif
}

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
 * @brief Type definitions for the OpenCL kernels (3D version).
 */

#define unit unsigned int
#define vec2 float2
#define vec3 float3
#define vec4 float4
#define ivec2 int2
#define ivec3 int3
#define ivec4 int4
#define uivec2 uint2
#define uivec3 uint3
#define uivec4 uint4

/** @def vec
 * @brief Vector of real components.
 *
 * The number of components depends on weather the 2D version or 3D
 * version is compiled:
 *   - 2D = 2 components
 *   - 3D = 4 components
 * 
 * This type should be used for input arguments, but for the local variables
 * maybe you can consider using vec_xyz (which has just 3 components in 3D)
 */
#define vec float4

/** @def ivec
 * @brief Vector of integer components.
 *
 * The number of components depends on weather the 2D version or 3D
 * version is compiled:
 *   - 2D = 2 components
 *   - 3D = 4 components
 * 
 * This type should be used for input arguments, but for the local variables
 * maybe you can consider using ivec_xyz (which has just 3 components in 3D)
 */
#define ivec int4

/** @def ivec
 * @brief Vector of unsigned integer components.
 *
 * The number of components depends on weather the 2D version or 3D
 * version is compiled:
 *   - 2D = 2 components
 *   - 3D = 4 components
 * 
 * This type should be used for input arguments, but for the local variables
 * maybe you can consider using uivec_xyz (which has just 3 components in 3D)
 */
#define uivec uint4

/** @def VEC_ZERO
 * @brief Null #vec, i.e. filled with zero components.
 */
#define VEC_ZERO (float4)(0.f,0.f,0.f,0.f)
/** @def VEC_ONE
 * @brief Ones #vec, i.e. filled with one components (except the w component).
 */
#define VEC_ONE (float4)(1.f, 1.f, 1.f, 0.f)
/** @def VEC_ALL_ONE
 * @brief Ones #vec, i.e. filled with one components.
 */
#define VEC_ALL_ONE (float4)(1.f, 1.f, 1.f, 1.f)
/** @def VEC_INFINITY
 * @brief Infinity #vec, i.e. filled with infinity components (except the w
 * component).
 */
#define VEC_INFINITY (float4)(INFINITY, INFINITY, INFINITY, 0.f)
/** @def VEC_ALL_INFINITY
 * @brief Infinity #vec, i.e. filled with infinity components.
 */
#define VEC_ALL_INFINITY (float4)(INFINITY, INFINITY, INFINITY, INFINITY)
/** @def VEC_NEG_INFINITY
 * @brief -Infinity #vec, i.e. filled with -infinity components (except the w
 * component).
 */
#define VEC_NEG_INFINITY (-VEC_INFINITY)
/** @def VEC_ALL_NEG_INFINITY
 * @brief -Infinity #vec, i.e. filled with -infinity components.
 */
#define VEC_ALL_NEG_INFINITY (-VEC_ALL_INFINITY)

/** @def vec_xyz
 * @brief Vector of real components with the minimum number of components.
 *
 * The number of components depends on weather the 2D version or 3D
 * version is compiled:
 *   - 2D = 2 components
 *   - 3D = 3 components
 *
 * This type can be used for the local variables to reduce the VGPRs.
 */
#define vec_xyz vec3

/** @def ivec_xyz
 * @brief Vector of integer components.
 *
 * The number of components depends on weather the 2D version or 3D
 * version is compiled:
 *   - 2D = 2 components
 *   - 3D = 3 components
 *
 * This type can be used for the local variables to reduce the VGPRs.
 */
#define ivec_xyz ivec3

/** @def uivec_xyz
 * @brief Vector of unsigned integer components.
 *
 * The number of components depends on weather the 2D version or 3D
 * version is compiled:
 *   - 2D = 2 components
 *   - 3D = 3 components
 *
 * This type can be used for the local variables to reduce the VGPRs.
 */
#define uivec_xyz uivec3

/** @def XYZ
 * @brief Convenient access to the vector components.
 * 
 * It is useful to be used with #vec_xyz, #ivec_xyz and #uivec_xyz type:
 *   - 2D = .xy
 *   - 3D = .xyz
 */
#define XYZ xyz
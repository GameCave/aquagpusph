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

if((imove[j] != -1) &&
   (imove[j] != 1)){
    j++;
    continue;
}

const vec r = pos_i - pos[j];
const float q = fast_length(r) / h;
if(q < support)
{
	//---------------------------------------------------------------
	//       calculate the kernel wab and the function fab
	//---------------------------------------------------------------
	const float rho_j = rho[j];
	const float m_j = m[j];
    const float p_j = p[j];
	const float wab = kernelW(q) * conw * m_j;
	//---------------------------------------------------------------
	//       pressure computation (stored on f)
	//---------------------------------------------------------------
	_DVDT_.x += p_j / rho_j * wab;
	_DVDT_.y += dot(g, r) * wab;
	//---------------------------------------------------------------
	// 	density computation (stored on drdt)
	//---------------------------------------------------------------
	_DRDT_ += wab;
	//---------------------------------------------------------------
	// 	Shepard term
	//---------------------------------------------------------------
	_SHEPARD_ += wab / rho_j;
}

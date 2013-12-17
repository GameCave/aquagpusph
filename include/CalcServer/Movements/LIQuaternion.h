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

#ifndef LIQUATERNION_H_INCLUDED
#define LIQUATERNION_H_INCLUDED

// ----------------------------------------------------------------------------
// Include the Movement
// ----------------------------------------------------------------------------
#include <CalcServer/Movements/Quaternion.h>

// ----------------------------------------------------------------------------
// Include the Linear interpolator
// ----------------------------------------------------------------------------
#include <CalcServer/Movements/LinearInterpolation.h>

namespace Aqua{ namespace CalcServer{ namespace Movement{

/** @class LIQuaternion LIQuaternion.h CalcServer/Movements/LIQuaternion.h
 * @brief Linear interpolated solid quaternion movement. Quaternion defines
 * the solid position at any time.
 */
class LIQuaternion : public Aqua::CalcServer::Movement::Quaternion
{
public:
	/** Constructor.
	 */
	LIQuaternion();

	/** Destructor.
	 */
	~LIQuaternion();

	/** Executes the movement.
	 * @return false if all gone right. \n true otherwise.
	 */
	bool execute();

protected:
	/** Parse input definition file.
	 * @param root Input node of reader.
	 * @return false if all gone right. \n true otherwise.
	 */
	bool _parse(xercesc::DOMElement *root);

private:
	/** Reads initial quaternion position.
	 * @return false if all gone right. \n true otherwise.
	 */
	bool setInitialPositions();

	/// Data file linear interpolator
	LinearInterpolation *mData;
};

}}} // namespace

#endif // LIQUATERNION_H_INCLUDED
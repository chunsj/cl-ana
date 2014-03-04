;;;; cl-ana is a Common Lisp data analysis library.
;;;; Copyright 2013, 2014 Gary Hollis
;;;; 
;;;; This file is part of cl-ana.
;;;; 
;;;; cl-ana is free software: you can redistribute it and/or modify it
;;;; under the terms of the GNU General Public License as published by
;;;; the Free Software Foundation, either version 3 of the License, or
;;;; (at your option) any later version.
;;;; 
;;;; cl-ana is distributed in the hope that it will be useful, but
;;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;;;; General Public License for more details.
;;;; 
;;;; You should have received a copy of the GNU General Public License
;;;; along with cl-ana.  If not, see <http://www.gnu.org/licenses/>.
;;;;
;;;; You may contact Gary Hollis (me!) via email at
;;;; ghollisjr@gmail.com
(in-package :quantity)

(defun convert-units (quantity new-units)
  "Gets the scale of quantity if expressed in new-units.

new-units can be either a product unit (usual unit, e.g. meter/second)
or a list of product units which is interpreted as a sum of units.

Using a list of units results in a list of unit-scales, one element
per unit in the sum.  The quantity value is the result of multiplying
the unit-scales with the corresponding product units and them summing.
Useful for expressing U.S. quantities like heights in feet and
inches."
  (if (listp new-units)
      (let ((units (butlast new-units))
            (last-unit (first (last new-units)))
            (result ())
            (q quantity)
            factor)
        (dolist (unit units)
          (setf factor (floor (/ q unit)))
          (setf q (- q (* unit factor)))
          (push factor result))
        (push (/ q last-unit) result)
        (nreverse result))
      (/ quantity new-units)))
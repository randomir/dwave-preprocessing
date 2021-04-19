# distutils: language = c++
# cython: language_level=3
#
# Copyright 2018 D-Wave Systems Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#
# =============================================================================

from libcpp.utility cimport pair
from libcpp.vector cimport vector

import dimod
from dimod import AdjVectorBQM
from dimod.bqm.cppbqm cimport AdjVectorBQM as cppAdjVectorBQM
from dimod cimport cyAdjVectorBQM
from dimod.vartypes import Vartype

cdef extern from "include/dwave-preprocessing/fix_variables.hpp" namespace "fix_variables_":
    vector[pair[int, int]] fixQuboVariables[V, B](cppAdjVectorBQM[V, B]& refBQM,
                                            int method) except +

def fix_variables_wrapper(bqm, method):
    """Cython wrapper for fix_variables().

    Args:
        bqm (:obj:`.BinaryQuadraticModel`):
            Should be binary and linear indexed.

        method (int):
            1 -> roof-duality & strongly connected components
            2 -> roof-duality only

    """
    if bqm.vartype is not Vartype.BINARY:
        raise ValueError("bqm must be BINARY")
    if not all(v in bqm.linear for v in range(len(bqm))):
        raise ValueError("bqm must be integer-labeled")
    if not isinstance(method, int):
        raise TypeError("method should be an int")
    if method < 1 or method > 2:
        raise ValueError("method should be 1 or 2")

    cdef cyAdjVectorBQM cybqm = dimod.as_bqm(bqm, cls=AdjVectorBQM)
    fixed = fixQuboVariables(cybqm.bqm_, method)
    return {int(v): int(val) for v, val in fixed}

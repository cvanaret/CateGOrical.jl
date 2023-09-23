# Copyright (c) 2023 Charlie Vanaret
# Licensed under the MIT license. See LICENSE file in the project directory for details.

using StaticArrays
using IntervalArithmetic
include("Optimization.jl")
# include("Catalog.jl")

X = IntervalBox(-15..12)
objective = x -> x[1]*cos(x[1])
constraints = []
(best_solution, best_objective_upper_bound) = minimize(objective, constraints, X; tolerance=1e-5, verbose=true)

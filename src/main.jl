# Copyright (c) 2023 Charlie Vanaret
# Licensed under the MIT license. See LICENSE file in the project directory for details.

using StaticArrays
using IntervalArithmetic
include("Catalog.jl")
include("Optimization.jl")

bars_catalog = Catalog(
    "bars",
    ["cross_section", "density"],
    [(7.28e-4, 7830.), (8e-4, 8270.), (8.66e-4, 7930.), (8.66e-4, 8440.), (9.00e-4, 8890.), (9.39e-4, 7830.), (1.00e-3, 8270.), (1.28e-3, 7830.), (1.32e-3, 8440.)]
)

X = IntervalBox(-1.5..1, -3..2)
function f(x, y)
    return x[1]*cos(x[1]) - x[2]
end
upper_bound = minimize(f, [], X, [], bars_catalog, tolerance=1e-6)
println("Upper bound: ", upper_bound)

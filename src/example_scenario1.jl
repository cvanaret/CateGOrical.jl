# Copyright (c) 2023 Charlie Vanaret
# Licensed under the MIT license. See LICENSE file in the project directory for details.

using IntervalArithmetic
include("Constraints.jl")
include("Optimization.jl")

# define the optimization problem
initial_domain = IntervalBox(0..16, 0..20, -10..10)
objective = x -> x[2]^3
catalog = Catalog("example_scenario1",
    ["y_1", "y_2"],
    [[4., -8.],
    [3., 2.],
    [7., -3.],
    [14., 8.],
    [19., -8.]])
constraints = [
    GeneralConstraint(x -> x[1] - x[3]^2 - 2*x[2], 0..0),
    CatalogConstraint(catalog, [2, 3]) # indices of the property variables
]

# create contractors here to avoid world age problem (of course, you want this automatically done)
variables = @variables x[1:length(initial_domain)]
variables = vcat(variables...)
objective_contractor = Contractor(variables, objective(variables))
constraint_contractors = [
    create_constraint_contractor(constraint, variables)
    for constraint in constraints
]

# compute the global minimum and one of the minimizers
(approximate_minimizer, approximate_minimum, number_bisections) = minimize(objective, objective_contractor, constraints, constraint_contractors, initial_domain; tolerance=1e-3, verbose=true)
println("---------------------------------------------------")
println("Global minimizer: ", approximate_minimizer)
println("Global minimum: ", approximate_minimum)
println("Number of bisections: ", number_bisections)

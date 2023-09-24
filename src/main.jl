# Copyright (c) 2023 Charlie Vanaret
# Licensed under the MIT license. See LICENSE file in the project directory for details.

using IntervalArithmetic
include("Optimization.jl")
include("Constraints.jl")

# define the optimization problem
initial_domain = IntervalBox(-15..12)
objective = x -> x[1]*cos(x[1])
constraints = [GeneralConstraint(x -> sin(x[1] - 1), 0..∞)]

# create contractors here to avoid world age problem
variables = @variables x[1:length(initial_domain)]
variables = vcat(variables...)
objective_contractor = Contractor(variables, objective(x))
constraint_contractors = [
    begin
        contractor = Contractor(variables, constraint.constraint_function(x))
        # capture the constraint range
        box -> contractor(constraint.range, box)
    end
    for constraint in constraints
]

# compute the global minimum and one of the minimizers
(best_solution, best_objective_upper_bound, number_bisections) = minimize(objective, objective_contractor, constraints, constraint_contractors, initial_domain; tolerance=1e-3, verbose=true)

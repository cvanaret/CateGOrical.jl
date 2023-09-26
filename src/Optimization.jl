# Copyright (c) 2023 Charlie Vanaret
# Licensed under the MIT license. See LICENSE file in the project directory for details.

using IntervalArithmetic
using IntervalConstraintProgramming
using IntervalOptimisation: HeapedVector
using ModelingToolkit

# evaluate at midpoint of current box
function compute_objective_upper_bound(objective, constraints, box, verbose)
    midpoint = mid.(box)
    midpoint_interval = Interval.(midpoint)
    
    # test feasibility wrt the constraints
    for constraint in constraints
        if !is_point_feasible(midpoint_interval, constraint)
            verbose && println("Midpoint is infeasible")
            return nothing
        end
    end
    
    # if the midpoint is feasible, evaluate its objective value
    midpoint_objective = objective(midpoint_interval)
    return (midpoint, sup(midpoint_objective))
end

function filter_constraints(objective_contractor, constraint_contractors, box, objective_bound)
    # TODO fixed point

    # objective
    box = objective_contractor(-∞..objective_bound, box)
    if isempty(box)
        return box
    end
    
    # constraints
    for constraint_contractor in constraint_contractors
        box = constraint_contractor(box)
        if isempty(box)
            return box
        end
    end
    return box
end

function minimize(objective, objective_contractor, constraints, constraint_contractors, initial_domain; structure = HeapedVector, tolerance=1e-6, verbose=false)
    # list of boxes with corresponding lower bound, arranged according to selected structure
    queue = structure([(initial_domain, inf(objective(initial_domain)))], tuple -> tuple[2])
    
    # keep track of best known solution
    best_solution = nothing
    best_objective_upper_bound = +∞

    number_bisections = 0
    while !isempty(queue)
        # exploration
        (box, objective_lower_bound) = popfirst!(queue)
        verbose && println("Current box: ", box, " with objective lower bound: ", objective_lower_bound)
        
        # pruning
        if best_objective_upper_bound - tolerance < objective_lower_bound
            verbose && println("Current box pruned")
            continue
        end
        
        # upper bounding: if a feasible point is found, update the best known upper bound
        optional_feasible_point = compute_objective_upper_bound(objective, constraints, box, verbose)
        if optional_feasible_point != nothing
            (feasible_point, feasible_point_objective_upper_bound) = optional_feasible_point
            if feasible_point_objective_upper_bound < best_objective_upper_bound
                best_solution = feasible_point
                best_objective_upper_bound = feasible_point_objective_upper_bound
                verbose && println("Best objective upper bound improved: ", best_objective_upper_bound)
            end
        end

        # branching
        for subbox in bisect(box)
            # filtering
            subbox = filter_constraints(objective_contractor, constraint_contractors, subbox, best_objective_upper_bound - tolerance)
            if isempty(subbox)
                verbose && println("Subbox empty after filtering")
                continue
            end
            
            # lower bounding
            subbox_objective_lower_bound = inf(objective(subbox))
            if best_objective_upper_bound - tolerance < subbox_objective_lower_bound
                verbose && println("Subbox pruned")
                continue
            end
            push!(queue, (subbox, subbox_objective_lower_bound))
        end
        number_bisections += 1
    end
    return (best_solution, best_objective_upper_bound, number_bisections)
end

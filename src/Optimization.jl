# Copyright (c) 2023 Charlie Vanaret
# Licensed under the MIT license. See LICENSE file in the project directory for details.

using IntervalArithmetic
using IntervalOptimisation
using IntervalConstraintProgramming
using ModelingToolkit

# evaluate at midpoint of current box
function compute_objective_upper_bound(objective, box)
    midpoint = Interval.(mid.(box))
    midpoint_objective = sup(objective(midpoint))   
    return (midpoint, midpoint_objective)
end

function minimize(objective, constraints, initial_domain; structure = HeapedVector, tolerance=1e-6, verbose=false) where {T}
    # list of boxes with corresponding lower bound, arranged according to selected structure
    queue = structure([(initial_domain, inf(objective(initial_domain)))], x -> x[2])
    
    # keep track of best known solution
    best_solution = nothing
    best_objective_upper_bound = ∞

    number_bisections = 0
    while !isempty(queue)
        # exploration
        (box, objective_lower_bound) = popfirst!(queue)
        verbose && println("Current box: ", box, " with objective lower bound: ", objective_lower_bound)
        
        # pruning
        if best_objective_upper_bound - tolerance < objective_lower_bound
            continue
        end
        
        # upper bounding: if a feasible point is available, update the best known upper bound
        (feasible_point, feasible_point_objective_upper_bound) = compute_objective_upper_bound(objective, box)
        if feasible_point_objective_upper_bound < best_objective_upper_bound
            best_solution = feasible_point
            best_objective_upper_bound = feasible_point_objective_upper_bound
            verbose && println("Best objective upper bound improved: ", best_objective_upper_bound)
        end

        # branching
        for subbox in bisect(box)
            # filtering
            # TODO
            
            # lower bounding
            subbox_objective_lower_bound = inf(objective(box))
            if best_objective_upper_bound - tolerance < subbox_objective_lower_bound
                continue
            end
            push!(queue, (subbox, subbox_objective_lower_bound))
        end
        number_bisections += 1
    end
    return (best_solution, best_objective_upper_bound)
end

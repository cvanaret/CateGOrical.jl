# Copyright (c) 2023 Charlie Vanaret
# Licensed under the MIT license. See LICENSE file in the project directory for details.

using IntervalArithmetic
using IntervalConstraintProgramming
using IntervalOptimisation: HeapedVector
using ModelingToolkit

function select_point_in_box(box, point, constraint::GeneralConstraint{FunctionType}) where {FunctionType}
    # do not do anything
    return point
end

function select_point_in_box(box, point, catalog_constraint::CatalogConstraint{TypeProperties, NumberItems}) where {TypeProperties, NumberItems}
    # find first catalog item that is in the box
    for item in catalog_constraint.catalog.items
        if item in IntervalBox(box[catalog_constraint.property_indices])
            # set the properties to this item
            item_component = 1
            for property_index in catalog_constraint.property_indices
                # update the components of the result
                point = setindex(point, item[item_component], property_index)
                item_component = item_component + 1
            end
            return point
        end
    end
end

# evaluate at midpoint of current box
function compute_objective_upper_bound(objective, constraints, box, verbose)
    point = mid.(box)
    for constraint in constraints
        point = select_point_in_box(box, point, constraint)
    end
    point_interval = Interval.(point)
    
    # test feasibility wrt the constraints
    for constraint in constraints
        if !is_point_feasible(point_interval, constraint)
            verbose && println("Selected point ", point, " is infeasible")
            return nothing
        end
    end
    
    # if the point is feasible, evaluate its objective value
    verbose && println("Selected point ", point, " is feasible")
    point_objective = objective(point_interval)
    return (point, sup(point_objective))
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
    initial_domain = filter_constraints(objective_contractor, constraint_contractors, initial_domain, +∞)

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
            verbose && println("Current box pruned by objective test")
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

        # termination
        if diam(box) == 0.
            continue
        end
        
        # branching
        for subbox in bisect(box)
            verbose && print("  Current subbox: ", subbox)
            
            # filtering
            subbox = filter_constraints(objective_contractor, constraint_contractors, subbox, best_objective_upper_bound - tolerance)
            if isempty(subbox)
                verbose && println(" pruned by filtering")
                continue
            end
            
            # lower bounding
            subbox_objective_lower_bound = inf(objective(subbox))
            if best_objective_upper_bound - tolerance < subbox_objective_lower_bound
                verbose && println(" pruned")
                continue
            end
            verbose && println(" contracted to ", subbox)
            push!(queue, (subbox, subbox_objective_lower_bound))
        end
        number_bisections += 1
    end
    return (best_solution, best_objective_upper_bound, number_bisections)
end

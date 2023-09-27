# Copyright (c) 2023 Charlie Vanaret
# Licensed under the MIT license. See LICENSE file in the project directory for details.

using IntervalArithmetic
using IntervalConstraintProgramming
using IntervalOptimisation: HeapedVector
using ModelingToolkit

function collapse_categorical_properties(box, catalog_feasible_box, constraint::GeneralConstraint{FunctionType}) where {FunctionType}
    # nothing to do
    return catalog_feasible_box
end

function collapse_categorical_properties(box, catalog_feasible_box, catalog_constraint::CatalogConstraint{TypeProperties, NumberItems}) where {TypeProperties, NumberItems}
    # find first catalog item that is in the box (should exist)
    for item in catalog_constraint.catalog.items
        if item in IntervalBox(box[catalog_constraint.property_indices])
            # set the properties to this item
            for (item_component, property_index) in enumerate(catalog_constraint.property_indices)
                # update the components of the result
                catalog_feasible_box = setindex(catalog_feasible_box, Interval(item[item_component]), property_index)
            end
            return catalog_feasible_box
        end
    end
end

# find a feasible point in the current box and compute an upper bound of the objective
function compute_objective_upper_bound(objective, constraints, box, verbose)
    # start with the initial box
    catalog_feasible_box = IntervalBox(box)
    # collapse the categorical properties by picking a catalog item in box
    for constraint in constraints
        catalog_feasible_box = collapse_categorical_properties(box, catalog_feasible_box, constraint)
    end
    # use constraint propagation to reduce the continuous variables
    catalog_feasible_box = filter_constraints(objective_contractor, constraint_contractors, catalog_feasible_box, +∞)
    if isempty(catalog_feasible_box)
        return (nothing, +∞)
    end
    
    # pick the midpoint of this box
    point = mid.(catalog_feasible_box)
    point_interval = Interval.(point)
    
    # test feasibility wrt the constraints
    for constraint in constraints
        if !is_point_feasible(point_interval, constraint)
            verbose && println("  Selected point ", point, " is infeasible")
            return (nothing, +∞)
        end
    end
    
    # if the point is feasible, evaluate its objective value
    verbose && println("  Selected point ", point, " is feasible")
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
    # filter the initial domain
    verbose && print("Initial domain ", initial_domain)
    initial_domain = filter_constraints(objective_contractor, constraint_contractors, initial_domain, +∞)
    verbose && println(" filtered to ", initial_domain)

    # list of boxes with corresponding lower bound, arranged according to selected structure
    queue = structure([(initial_domain, inf(objective(initial_domain)))], tuple -> tuple[2])
    
    # keep track of best known solution
    best_solution = nothing
    best_objective_upper_bound = +∞

    number_bisections = 0
    verbose && println("--- Starting branch and bound ---")
    while !isempty(queue)
        # exploration
        (box, objective_lower_bound) = popfirst!(queue)
        verbose && println("Current box: ", box, " with objective lower bound: ", objective_lower_bound)
        
        # upper bounding: if a feasible point is found, update the best known upper bound
        (feasible_point, objective_upper_bound) = compute_objective_upper_bound(objective, constraints, box, verbose)
        if objective_upper_bound < best_objective_upper_bound
            best_solution = feasible_point
            best_objective_upper_bound = objective_upper_bound
            verbose && println("  Best objective upper bound improved: ", best_objective_upper_bound)
        end
        
        # pruning
        if best_objective_upper_bound - tolerance < objective_lower_bound
            verbose && println("  Pruned by objective test")
            continue
        end

        # termination
        if diam(box) == 0.
            continue
        end
        
        # branching: (default) branch in the center of the largest component
        verbose && println("  Branching")
        for subbox in bisect(box, 0.5)
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
                verbose && println(" pruned by objective test")
                continue
            end
            verbose && println(" contracted to ", subbox)
            push!(queue, (subbox, subbox_objective_lower_bound))
        end
        number_bisections += 1
    end
    return (best_solution, best_objective_upper_bound, number_bisections)
end

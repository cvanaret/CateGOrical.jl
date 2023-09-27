# Copyright (c) 2023 Charlie Vanaret
# Licensed under the MIT license. See LICENSE file in the project directory for details.

include("Catalog.jl")

struct GeneralConstraint{FunctionType <: Function}
    constraint_function::FunctionType
    range::Interval{Float64}
end

struct CatalogConstraint{TypeProperties <: Real, NumberItems}
    catalog::Catalog{TypeProperties, NumberItems}
    property_indices::Array{Int64,1}
end

function create_constraint_contractor(constraint::GeneralConstraint{FunctionType}, variables) where {FunctionType}
    # generate an instance of HC4Revise (aka forward-backward contractor)
    contractor = Contractor(variables, constraint.constraint_function(variables))
    
    # capture the constraint range
    return box -> contractor(constraint.range, box)
end

function create_constraint_contractor(catalog_constraint::CatalogConstraint{TypeProperties, NumberItems}, variables) where {TypeProperties, NumberItems}
    # TODO: ugly but works
    function clutch_contractor(box)
        # filtered_box will receive the convex hull of all catalog items that are present in box
        filtered_box = IntervalBox(box)
        for property_index in catalog_constraint.property_indices
            filtered_box = setindex(filtered_box, ∅, property_index)
        end
        
        # determine if catalog items belong to the current box
        for item in catalog_constraint.catalog.items
            if item in IntervalBox(box[catalog_constraint.property_indices])
                # perform convex hull for each property
                for (item_component, property_index) in enumerate(catalog_constraint.property_indices)
                    # update the components of the result
                    new_component = filtered_box[property_index] ∪ Interval(item[item_component])
                    filtered_box = setindex(filtered_box, new_component, property_index)
                end
            end
        end
        return filtered_box
    end
    return clutch_contractor
end

function is_point_feasible(x, constraint::GeneralConstraint{FunctionType}) where {FunctionType}
    constraint_value = constraint.constraint_function(x)
    return issubset(constraint_value, constraint.range)
end

function is_point_feasible(x, constraint::CatalogConstraint{TypeProperties, NumberItems}) where {TypeProperties, NumberItems}
    # by construction, this is always true
    return true
end

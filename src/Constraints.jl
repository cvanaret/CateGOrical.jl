# Copyright (c) 2023 Charlie Vanaret
# Licensed under the MIT license. See LICENSE file in the project directory for details.

include("Catalog.jl")

struct GeneralConstraint{FunctionType <: Function}
    constraint_function::FunctionType
    range::Interval{Float64}
end

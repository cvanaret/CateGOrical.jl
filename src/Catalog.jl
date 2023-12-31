# Copyright (c) 2023 Charlie Vanaret
# Licensed under the MIT license. See LICENSE file in the project directory for details.

struct Catalog{PropertyTypes <: Real, NumberItems}
    name::String
    properties_names::Array{String,1}
    items::Array{Array{PropertyTypes, NumberItems},1}
end

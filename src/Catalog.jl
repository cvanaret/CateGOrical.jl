# Copyright (c) 2023 Charlie Vanaret
# Licensed under the MIT license. See LICENSE file in the project directory for details.

struct Catalog
    name::String
    properties_names::Array{String,1}
    properties::Array{Tuple{Float64,Float64},1}
end

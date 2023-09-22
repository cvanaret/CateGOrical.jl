# Copyright (c) 2023 Charlie Vanaret
# Licensed under the MIT license. See LICENSE file in the project directory for details.

using IntervalArithmetic
using IntervalConstraintProgramming
using ModelingToolkit
import Base: in
include("Catalog.jl")

vars = @variables x y1 y2
hc4revise = Contractor(vars, x - y2^2 - 2*y1)
catalog = Catalog("example_scenario1", ["y_1", "y_2"], [(4., -8.), (3., 2.), (7., -3.), (14., 8.), (19., -8.)])

function in(x::NTuple{N, T}, X::IntervalBox, shift) where {T <: Real, N}
    @assert length(x) <= length(X)
    for i in 1:length(x)
        if !in(x[i], X[i + shift])
            return false
        end
    end
    return true
end

function clutch_contractor(X::IntervalBox, catalog::Catalog)
    Y_clutch = IntervalBox(∅, 2)
    for item in catalog.properties
        if in(item, X, 1)
            println(item, " is in X")
            Y_clutch = hull(Y_clutch, IntervalBox(item))
        end
    end
    X = setindex(X, Y_clutch[1], 2)
    X = setindex(X, Y_clutch[2], 3)
    return X
end

X = IntervalBox(0..16, 0..20, -10..10)
println("Initial box: ", X)

# HC4Revise filtering
X = hc4revise(0..0, X)
println("After HC4Revise: ", X)

# catalog filtering
X = clutch_contractor(X, catalog)
println("After CLUTCH: ", X)

# HC4Revise filtering
X = hc4revise(0..0, X)
println("After HC4Revise: ", X)

# branch
X = setindex(X, 3..5, 2)
println("After branching on y1: ", X)

# catalog filtering
X = clutch_contractor(X, catalog)
println("After CLUTCH: ", X)

# HC4Revise filtering
X = hc4revise(0..0, X)
println("After HC4Revise: ", X)

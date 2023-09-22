using IntervalArithmetic
using IntervalConstraintProgramming
using ModelingToolkit
import Base: in
include("Catalog.jl")

vars = @variables x z1 z2 z3 z4 z5
hc4revise = Contractor(vars, x - (-8*z1 + 2*z2 - 3*z3 + 8*z4 - 8*z5)^2 - 2*(4*z1 + 3*z2 + 7*z3 + 14*z4 + 19*z5))
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

X = IntervalBox(0..16, 0..1, 0..1, 0..1, 0..1, 0..1)
println("Initial box: ", X)

# HC4Revise filtering
X = hc4revise(0..0, X)
println("After HC4Revise: ", X)

# binary contraction
X = setindex(X, 0..0, 5)
X = setindex(X, 0..0, 6)
println("After binary contraction: ", X)

# HC4Revise filtering
X = hc4revise(0..0, X)
println("After HC4Revise: ", X)

# branch
#X = setindex(X, 3..5, 2)
#println("After branching on y1: ", X)

# binary contraction
X = setindex(X, 0..0, 2)
println("After binary contraction: ", X)

# HC4Revise filtering
X = hc4revise(0..0, X)
println("After HC4Revise: ", X)

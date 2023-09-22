using IntervalArithmetic
using IntervalConstraintProgramming
using ModelingToolkit
import Base: in
include("Catalog.jl")

function f(x, y1, y2)
    return y1^3
end

epsilon = 1e-6
vars = @variables x y1 y2
hc4revise_c1 = Contractor(vars, x - y2^2 - 2*y1)
hc4revise_f = Contractor(vars, f(x, y1, y2))
catalog = Catalog("example_scenario2", ["y_1", "y_2"], [(4., -8.), (3., 2.), (7., -3.), (14., 8.), (19., -8.), (1, -1)])

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
            println("  ", item, " is in X")
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
X = hc4revise_c1(0..0, X)
println("After HC4Revise(c1): ", X)

# catalog filtering
X = clutch_contractor(X, catalog)
println("After CLUTCH: ", X)

# HC4Revise filtering
X = hc4revise_c1(0..0, X)
println("After HC4Revise(c1): ", X)

# upper bounding
feasible_point = (10, 3, 2)
best_upper_bound = f(feasible_point[1], feasible_point[2], feasible_point[3])
println("Upper bounding, best upper bound: ", best_upper_bound)
println("f range: ", -Inf..(best_upper_bound - epsilon))
X = hc4revise_f(-Inf..(best_upper_bound - epsilon), X)
println("After HC4Revise(f): ", X)

# catalog filtering
X = clutch_contractor(X, catalog)
println("After CLUTCH: ", X)

# HC4Revise filtering
X = hc4revise_c1(0..0, X)
println("After HC4Revise(c1): ", X)

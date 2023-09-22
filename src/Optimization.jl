using IntervalArithmetic
using IntervalOptimisation
using IntervalConstraintProgramming

function minimize(f, constraints, X, Y, catalog; structure = HeapedVector, tolerance=1e-6) where {T}
    # list of boxes with corresponding lower bound, arranged according to selected structure :
    queue = structure([(X, Y, -∞)], x -> x[3])
    upper_bound = ∞  # upper bound

    num_bisections = 0
    while !isempty(queue)
        (X, Y, parent_lower_bound) = popfirst!(queue)
        println("Current box: ", X)
        if upper_bound - tolerance < parent_lower_bound
            continue
        end
        
        # lower bounding
        current_lower_bound = inf(f(X, Y))
        if upper_bound - tolerance < current_lower_bound
            continue
        end

        # CLUTCH filtering: filter inconsistent values wrt the constraints
        # catalog lookup: reduce the categorical variables to the convex hull of the catalog items in Y

        # upper bounding: if a feasible point is available, update the best known upper bound
        m = sup(f(Interval.(mid.(X)), Y))   # evaluate at midpoint of current interval
        if m < upper_bound
            upper_bound = m
        end

        # CLUTCH branching
        for Xi in bisect(X)
            # catalog lookup and reduce Y
            push!(queue, (Xi, Y, current_lower_bound))
        end
        num_bisections += 1
    end
    return upper_bound
end

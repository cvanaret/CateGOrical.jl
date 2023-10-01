# Categorical.jl

## What is Categorical.jl?

Categorical.jl is a Julia prototype for solving mixed categorical optimization problems to global optimality. It implements:
* an interval branch-and-contract method that interleaves branching and constraint propagation phases on continuous domains. It is based on rigorous interval techniques that are robust to roundoff errors;  
* a new contractor called Clutch that handles catalog constraints (aka table constraints).

## Run an example

Run one of the provided examples (also described in the companion article):
```./julia example_scenario1.jl```

## Contributions

Categorical.jl was designed and implemented by [Charlie Vanaret](https://github.com/cvanaret/) (Zuse-Institut Berlin).  

## License

Categorical.jl is released under the MIT license (see the [license file](LICENSE)).

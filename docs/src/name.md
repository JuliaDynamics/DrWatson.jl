# Naming Simulations
Here we overview functionality that helps you quickly produce containers of parameters and name them using a consistent and intuitive naming scheme.

## Naming Schemes

A robust naming scheme allows you to create quick names for simulations, create lists of simulations, check existing simulations, etc. More importantly it allows you to easily create simulation-based names **consistently** and **deterministically**.

This is what the function [`savename`](@ref) does. Of course, you don't have to use it only for using names to save files. You could use it for anything that fits you (like e.g. adding identifiers to tabular data).
[`savename`](@ref) is also surprisingly useful for creating titles of figures, e.g. `savename(c; connector = ", ")`.

```@docs
savename
```

Notice that this naming scheme integrates perfectly with Parameters.jl.

## Convenience functions
Convenience functions are provided to shorten common function calls and easily create named tuples, dictionaries as well as switch between them:
```@docs
@dict
@strdict
@ntuple
@savename
ntuple2dict
dict2ntuple
tostringdict
tosymboldict
```

DrWatson also re-exports `@pack!, @unpack` tools from [UnPack.jl](https://github.com/mauro3/UnPack.jl), because they play very well with [`@dict`](@ref) and similar functions. Be aware of the syntactic `,` difference: `d = @dict a b c` versus `@unpack a, b, c = d`.

## Customizing `savename`
You can customize [`savename`](@ref) for your own Types. For example you could make it so that it only uses some specific keys instead of all of them, only specific types, or you could make it access data in a different way (maybe even loading files!). You can even make it have a custom `prefix`!

To do that you may extend any of the following functions:
```@docs
DrWatson.allaccess
DrWatson.access
DrWatson.allignore
DrWatson.default_allowed
DrWatson.default_prefix
DrWatson.default_expand
```

See [Real World Examples](@ref) for an example of customizing `savename`.
Specifically, have a look at [`savename` and nested containers](@ref) for a way to

## Reverse-engineering `savename`
```@docs
parse_savename
```

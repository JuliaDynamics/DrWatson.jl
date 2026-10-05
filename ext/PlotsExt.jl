module PlotsExt

using DrWatson
using Plots

function DrWatson._wsave(filename, p::AbstractPlot, args...; kwargs...)
    isempty(args) || @warn "Saving a `Plots.Plot` does not support additional `args...`; ignoring `args = $args`"
    isempty(kwargs) || @warn "Saving a `Plots.Plot` does not support `kwargs...`; ignoring `kwargs = $(NamedTuple(kwargs))`"

    savefig(p, filename)
end

end

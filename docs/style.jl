# Color theme definitions
struct CyclicContainer <: AbstractVector{String}
    c::Vector{String}
    n::Int
end
CyclicContainer(c) = CyclicContainer(c, 0)

Base.length(c::CyclicContainer) = length(c.c)
Base.size(c::CyclicContainer) = size(c.c)
Base.iterate(c::CyclicContainer, state=1) = iterate(c.c, state)
Base.getindex(c::CyclicContainer, i) = c.c[(i-1)%length(c.c) + 1]
Base.getindex(c::CyclicContainer, i::AbstractArray) = c.c[i]
function Base.getindex(c::CyclicContainer)
    c.n += 1
    c[c.n]
end
Base.iterate(c::CyclicContainer, i = 1) = iterate(c.c, i)

COLORSCHEME = [
    "#7143E0",
    "#0A9A84",
    "#191E44",
    "#AF9327",
    "#701B80",
    "#2E6137",
]

COLORS = CyclicContainer(COLORSCHEME)
LINESTYLES = CyclicContainer(["-", ":", "--", "-."])

# other styling elements for Makie
set_theme!(;
    palette = (color = COLORSCHEME,),
    fontsize = 22,
    figure_padding = 8,
    size = (800, 400),
    linewidth = 3.0,
)

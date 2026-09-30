# Construction layer: turn the declarative model settings into fully-built physics scheme
# instances. `model_settings.jl` is evaluated at package load, before any domain grid exists, so
# it stores declarative *specs* (`scheme(Type; kwargs...)`) and elevation *recipes*
# (`ElevationTuned`) rather than instances. `build_physics!` materializes them against the run's
# grid + landuse, so `setup` receives ready-made structs — FSM itself does no name-based routing.

"""
    ElevationTuned(elev_breaks, breaks)

Declarative recipe for an elevation-interpolated per-cell parameter: linear between the two
`elev_breaks`, clamped to `breaks` outside them. Resolved against the domain elevation by
[`resolve`](@ref).
"""
struct ElevationTuned{E, B}
    elev_breaks::E
    breaks::B
end

"""
    scheme(T; kwargs...)

Declarative spec for physics scheme type `T` with `kwargs` that may be literals (e.g. `adm = 130`)
or recipes (e.g. `adc = ElevationTuned(...)`). Materialized to `T{eltype(grid)}(grid; …)` by
[`materialize`](@ref), so the scheme's parameters travel with it.
"""
struct SchemeSpec{T}
    kwargs::NamedTuple
end
scheme(::Type{T}; kwargs...) where {T} = SchemeSpec{T}((; kwargs...))

"""
    resolve(value, grid, landuse)

Resolve a declarative value to a concrete parameter: a literal is returned unchanged; an
`ElevationTuned` recipe is linearly interpolated over the domain elevation at the grid's precision
(clamped outside the breaks).
"""
resolve(x, grid, landuse) = x

function resolve(r::ElevationTuned, grid, landuse)
    Tf = eltype(grid)
    dem = Tf.(landuse["elevation"]["data"])
    elev_breaks = Tf.(r.elev_breaks)
    breaks = Tf.(r.breaks)

    @assert length(elev_breaks) == 2 && elev_breaks[1] < elev_breaks[2] "elev_breaks must be (lower, upper) and strictly increasing; got $(elev_breaks)"

    out = breaks[1] .+ (dem .- elev_breaks[1]) ./ (elev_breaks[2] - elev_breaks[1]) .* (breaks[2] - breaks[1])
    out[dem .>= elev_breaks[2]] .= breaks[2]
    out[dem .<= elev_breaks[1]] .= breaks[1]
    return reshape(out, grid.Nx, grid.Ny)
end

"""
    materialize(value, grid, landuse)

Build a physics scheme from a declarative `value`: a [`SchemeSpec`](@ref) is constructed as
`T{eltype(grid)}(grid; resolved_kwargs...)` with its kwargs resolved against `landuse`; a bare type
or ready-made instance defers to FSM's `instantiate`.
"""
materialize(x, grid, landuse) = instantiate(x, grid)

function materialize(s::SchemeSpec{T}, grid, landuse) where {T}
    resolved = map(s.kwargs) do v
        r = resolve(v, grid, landuse)
        r isa AbstractVector ? reshape(r, grid.Nx, grid.Ny) : r
    end
    return T{eltype(grid)}(grid; resolved...)
end

"""
    build_physics!(grid, settings, landuse)

Materialize a tile's declarative `settings` against `grid` and `landuse`, in place: each
`settings["physics"]` spec becomes a scheme instance, and each `settings["params"]` recipe becomes
a literal array/scalar. Mutates and returns `settings`, ready to hand to `setup`.
"""
function build_physics!(grid, settings::AbstractDict, landuse)
    if haskey(settings, "physics")
        settings["physics"] = Dict{String, Any}(k => materialize(v, grid, landuse) for (k, v) in settings["physics"])
    end
    if haskey(settings, "params")
        settings["params"] = Dict{String, Any}(k => resolve(v, grid, landuse) for (k, v) in settings["params"])
    end
    return settings
end
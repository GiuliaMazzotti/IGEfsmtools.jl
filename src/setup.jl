# Translate an operational settings Dict (tile / physics / params) into a call to FSM's
# `FSM(grid, landuse; ...)` constructor.

const PHYSICS_KEYS = (
    "snow_albedo", "land_cover", "substrate", "conductivity", "compaction", "hydrology",
    "fresh_snow_density", "layering", "snow_fraction",
)

# Tile-fraction threshold below which a forest/glacier cell is inactive
const DEFAULT_TTHRESH = 0.1

"""
    setup([arch], grid, landuse, settings; tthresh = DEFAULT_TTHRESH)

Build an FSM for one tile from a `settings` Dict with keys `"tile"` (required) and optional
`"physics"` / `"params"`. Physics schemes default from the tile; parameter overrides are routed to
`Parameters` (scalars) or `Surface` (per-cell fields). `tthresh` sets which forest/glacier cells run
(open runs everywhere). With a non-`CPU` `arch` the model is moved to that device after construction.
"""
function setup(arch::AbstractArchitecture, grid::Grid, landuse::Dict, settings::AbstractDict; tthresh = DEFAULT_TTHRESH)
    tile = settings["tile"]
    tile in ("open", "forest", "glacier") ||
        error("tile requires open, forest or glacier (got tile = $tile)")

    physics = get(settings, "physics", Dict())
    for key in keys(physics)
        key in PHYSICS_KEYS ||
            throw(ArgumentError("unknown physics key \"$key\" (known: $(join(PHYSICS_KEYS, ", ")))"))
    end

    # Land_cover / substrate default from the tile.
    land_cover = get(physics, "land_cover", tile == "forest" ? ForestCover : OpenCover)
    if tile == "forest"
        (land_cover isa ForestCover || land_cover === ForestCover) ||
            error("forest tile requires a ForestCover")
        substrate = get(physics, "substrate", SoilSubstrate)
    else
        substrate = get(physics, "substrate", tile == "open" ? SoilSubstrate : IceSubstrate)
    end

    schemes = (; (Symbol(k) => v for (k, v) in physics if !(k in ("land_cover", "substrate")))...)

    # Active cells: open runs everywhere; forest/glacier where the tile fraction >= tthresh.
    Tf = eltype(grid)
    active = tile == "open" ? trues(grid.Nx, grid.Ny) : (Tf.(landuse[tile]["data"]) .>= Tf(tthresh))

    @infiltrate

    # Build on the CPU, apply parameter overrides, then move to the target architecture.
    fsm = FSM(grid, landuse; active = active, land_cover = land_cover, substrate = substrate, schemes...)
    apply_params!(fsm, get(settings, "params", Dict()))
    arch isa CPU || (fsm = on_architecture(arch, fsm))
    return fsm
end

setup(grid::Grid, landuse::Dict, settings::AbstractDict; kwargs...) = setup(CPU(), grid, landuse, settings; kwargs...)

# Route a scalar into the immutable Parameters via a functional update.
function set_param!(fsm, sym::Symbol, value)
    v = convert(fieldtype(typeof(fsm.params), sym), value)
    fsm.params = reconstruct(fsm.params; NamedTuple{(sym,)}((v,))...)
    return fsm
end

"""
    apply_params!(fsm, params)

Apply parameter overrides: a `Parameters` scalar is reconstructed onto `fsm.params`;
a `Surface` per-cell array is filled (scalar) or copied (array) in place.
"""
function apply_params!(fsm, params)
    for (key, value) in params
        sym = Symbol(key)
        if hasfield(typeof(fsm.params), sym)
            set_param!(fsm, sym, value)
        elseif hasfield(typeof(fsm.surface), sym)
            arr = getfield(fsm.surface, sym)
            value isa AbstractArray ? (arr .= eltype(arr).(value)) : fill!(arr, eltype(arr)(value))
        else
            throw(ArgumentError("unknown parameter override \"$key\""))
        end
    end
    return fsm
end
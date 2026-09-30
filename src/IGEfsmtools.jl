module IGEfsmtools

using FlexibleSnowModelOSHD
using Dates
using NCDatasets
using CSV
using DataFrames
using Base: findall
using ArchGDAL
using GeoDataFrames
using DataStructures
using Statistics
using Infiltrator

include("model_settings.jl")
include("setup.jl")
include("prepare_landuse.jl")
include("build_physics.jl")

export settings
export scheme, ElevationTuned, build_physics!
export setup
export prepare_landuse

function __init__()
    global settings = build_settings()
    return nothing
end

end # module IGEfsmtools

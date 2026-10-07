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

include("build_physics.jl")
include("precip_cor.jl")
include("model_settings.jl")
include("apply_params.jl")
include("apply_settings.jl")
include("prepare_landuse.jl")

export scheme, ElevationTuned, build_physics!
export build_precip
export AbstractCorrection, AbstractPrecip, LinearPrecip, LogPrecip, LogbisPrecip, ExpPrecip, TanhPrecip, precip_cor
export build_settings, settings, build_path_settings, settings_path
export set_param!, apply_params!
export set_nested!, apply_overrides
export prepare_landuse


function __init__()
    global settings = build_settings()
    global settings_path = build_path_settings()
    return nothing
end

end # module IGEfsmtools

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

include("settings.jl")
include("init.jl")
include("meteo_readers.jl")
include("output.jl")
include("run_simu.jl")

export setup
export init_grid!, init_poste!, init_point!
export make_saver, fill_saver, fill_daily_saver, grid_saver, pt_saver
export read_meteo!
export run_grid_simulation, run_grid_daily_simulation, run_poste_simulation, run_point_simulation

end # module IGEfsmtools

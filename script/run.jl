cd(@__DIR__)

using IGEfsmtools

# include("../src/IGEfsmtools.jl")

const settings = Dict(
    "tile" => "open",
    "config" => Dict(),
    "params" => Dict("dt" => 3600, "zT" => 1.5, "zU" => 5.0, "zRH" => 1.5), #"tcld", "tmlt", "Sfmin" => 15, "bstb" => 8
    "file_path" => "C:/Users/navarrel/Documents/Workspace/Data/s2m/balises/mask_balises_lautaret_bioclim/meteo/FORCING_1998080106_2023080106.nc", # change it
    "shapefile" => "C:/Users/navarrel/Documents/Workspace/MNT_alpes/shapefile/1D/s2m/stations_reanalysis_S2M_alpes.shp", # for s2m poste only
    "list_id" => [5079402, 5181002, 38375402, 5101003, 74056416, 5063402, 73071403], #"all", # for s2m poste only
    "landcover" => Int32(1), # only for glacier simu (now only adapted in init_point)
    "out_file" => "C:/Users/navarrel/Documents/Workspace/Data/outputs/gblanc/balises/output_1998-2023_S2M_balises_lautaret_bioclim.nc",
    "output_vars" => ["Ds", "Tsnow1", "Tsnow2", "Tsnow3", "Tsrf", "asrf_out", "Sice", "Sliq", "SWE", "Sbsrf", "meltflux_out", "Roff_snow", "Roff", "Tsoil1", "Tsoil2", "Tsoil3", "Tsoil4"],
)

###
# run_grid_simulation(settings, Tf, Ti, verbose)

# run_grid_daily_simulation(settings, Tf, Ti, verbose) 

# run_poste_simulation(settings, Tf, Ti, verbose) => list_id, shapefile

# run_point_simulation(settings, Tf, Ti, verbose)
###

run_point_simulation(settings=settings)



############################# Defaults settings #################################

# *************** Selected poste - calibration *******************
# const settings = Dict(
#     "tile" => "open",
#     "config" => Dict("ALBEDO" => 1, "EXCHNG" => 0),
#     "params" => Dict("wind_scaling" => 1.0, "dt" => 3600, "zT" => 1.5, "zU" => 5.0, "zRH" => 1.5), #"tcld", "tmlt", "Sfmin" => 15, "bstb" => 8
#     "file_path" => "C:/Users/navarrel/Documents/Workspace/Data/s2m/postes/meteo/FORCING_s2m_subset.nc", # change it
#     "shapefile" => "C:/Users/navarrel/Documents/Workspace/MNT_alpes/shapefile/1D/s2m/stations_reanalysis_S2M_alpes.shp", # for s2m poste only
#     "list_id" => [5079402, 5181002, 38375402, 5101003, 74056416, 5063402, 73071403], #"all", # for s2m poste only
#     "out_file" => "C:/Users/navarrel/Documents/Workspace/Data/outputs/calibration/output_2018-2024_S2M_selected_stations_Tinit_ALBEDO=1_EXCHGN=0.nc",
#     "output_vars" => ["Ds", "Tsnow1", "Tsnow2", "Tsnow3", "Tsrf", "asrf_out", "Sice", "Sliq", "SWE", "Sbsrf", "meltflux_out", "Roff_snow", "Roff", "Tsoil1", "Tsoil2", "Tsoil3", "Tsoil4"],
# )

# *************** Point on glacier *******************

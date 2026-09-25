cd(@__DIR__)

using IGEfsmtools

# include("../src/IGEfsmtools.jl")

const settings = Dict(
    "precision" => Float32,
    "file_path" => "C:/Users/navarrel/Documents/Workspace/Data/s2m/postes/meteo/FORCING_alpes_2018080106_2024080106.nc", # change it
    "shapefile" => "C:/Users/navarrel/Documents/Workspace/MNT_alpes/shapefile/1D/s2m/stations_reanalysis_S2M_alpes.shp", # for s2m poste only
    "list_id" => "all", #[38375402], #"all", # for s2m poste only
    "out_file" => "C:/Users/navarrel/Documents/Workspace/Data/outputs/output_grid_daily_test.nc",
    "output_vars" => ["Ds", "Tsnow1", "Tsnow2", "Tsnow3"], #, "Tsrf", "asrf_out", "Sice", "Sliq", "Sbsrf", "meltflux_out", "SWE", "Roff_snow", "Roff", "Tsoil1", "Tsoil2", "Tsoil3", "Tsoil4", "Rnet", "G", "Gsoil", "Hsrf", "LEsrf", "Esrf"
)

###
# run_grid_simulation(settings, Tf, Ti, verbose)

# run_grid_daily_simulation(settings, Tf, Ti, verbose) 

# run_glacier_grid_simulation(settings, Tf, Ti, verbose)

# run_glacier_grid_daily_simulation(settings, Tf, Ti, verbose) 

# run_poste_simulation(settings, Tf, Ti, verbose) => list_id, shapefile

# run_point_simulation(settings, Tf, Ti, verbose)
###

run_poste_simulation(settings=settings)

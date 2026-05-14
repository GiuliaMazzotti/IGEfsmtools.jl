cd(@__DIR__)

using IGEfsmtools

# include("../src/IGEfsmtools.jl")

const settings = Dict(
    "tile" => "open",
    "config" => Dict("SNFRAC" => 0),
    "params" => Dict("wind_scaling" => 1.0, "dt" => 3600, "zT" => 1.5, "zU" => 5.0, "zRH" => 1.5),
    "file_path" => "C:/Users/navarrel/Documents/Workspace/Data/s2m/balises/mask/meteo/FORCING_1999080106_2000080106.nc", # change it
    "shapefile" => "C:/Users/navarrel/Documents/Workspace/MNT_alpes/shapefile/1D/s2m/stations_reanalysis_S2M_alpes.shp", # for s2m poste only
    "list_id" => "all", # for s2m poste only
    "out_file" => "C:/Users/navarrel/Documents/Workspace/Data/outputs/gblanc/balises/output_1999-2000_S2M_balises_gblanc.nc",
    "output_vars" => ["Ds", "Tsnow1", "Tsnow2", "Tsnow3", "Tsrf", "asrf_out", "Sice", "Sliq", "Sbsrf", "meltflux_out", "Melt", "Roff_snow", "Roff", "Tsoil1", "Tsoil2", "Tsoil3", "Tsoil4", "Rnet", "Gsoil", "Hsrf", "LEsrf", "Esrf"],
)

###
# run_grid_simulation(settings, Tf, Ti, verbose)

# run_grid_daily_simulation(settings, Tf, Ti, verbose) 

# run_poste_simulation(settings, Tf, Ti, verbose) => list_id, shapefile

# run_point_simulation(settings, Tf, Ti, verbose)
###

run_point_simulation(settings=settings)

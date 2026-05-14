const settings = Dict(
    "tile" => "open",
    "config" => Dict("SNFRAC" => 0),
    "params" => Dict("wind_scaling" => 1.0, "dt" => 3600, "zT" => 1.5, "zU" => 5.0, "zRH" => 1.5),
    "file_path" => "C:/Users/navarrel/Documents/Workspace/Data/s2m/balises/mask/meteo/FORCING_2000080106_2001080106.nc", # change it
    "shapefile" => "C:/Users/navarrel/Documents/Workspace/MNT_alpes/shapefile/1D/s2m/stations_reanalysis_S2M_alpes.shp", # for s2m poste only
    "list_id" => "all", # for s2m poste only
    "out_folder" => string(@__DIR__, "/../../../Data/outputs"),
    "output_vars" => ["time", "Ds", "Tsnow1", "Tsnow2", "Tsnow3", "Tsrf", "asrf_out", "Sice", "Sliq", "Sbsrf", "meltflux_out", "Melt", "Roff_snow", "Roff", "Tsoil1", "Tsoil2", "Tsoil3", "Tsoil4", "Rnet", "G", "Gsoil", "Hsrf", "LEsrf", "Esrf"],
)

# settings[:poste]["tile"]
# add file_name ? 

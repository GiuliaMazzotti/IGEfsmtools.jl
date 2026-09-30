# const PHYSICS_DEFAULT = Dict(
#     "snow_albedo" => ::PrognosticAlbedo, 
#     "land_cover" => ::OpenCover, 
#     "substrate" => ::SoilSubstrate, 
#     "conductivity" => ::DensityConductivity, 
#     "compaction" => ::AgeCompaction, 
#     "hydrology" => ::DensityBucketHydrology,
#     "fresh_snow_density" => ::ElevationFreshSnowDensity, 
#     "layering" => ::OriginalLayering, 
#     "snow_fraction" => ::PointSnowFraction,
# )

function build_settings()
    return OrderedDict(
        "INIT" => Dict(
            "precision" => Float32,
            "file_path" => "C:/Users/navarrel/Documents/Workspace/Data/s2m/postes/meteo/FORCING_alpes_2018080106_2024080106.nc", # change it
            "shapefile" => "C:/Users/navarrel/Documents/Workspace/MNT_alpes/shapefile/1D/s2m/stations_reanalysis_S2M_alpes.shp", # for s2m poste only
            "list_id" => [38375402, 5079402], #[38375402], #"all", # for s2m poste only
            "out_file" => "C:/Users/navarrel/Documents/Workspace/Data/outputs/output_postes_test.nc"
        ),
        "TUNING" => Dict(
            "physics" => Dict(),
            "params" => Dict(),
            "tile" => "open"
        )
    )
end

# function build_physics_settings()
#     return PHYSICS_DEFAULT
# end

settings = build_settings()
# settings["TUNING"]["physics"] = build_physics_settings()
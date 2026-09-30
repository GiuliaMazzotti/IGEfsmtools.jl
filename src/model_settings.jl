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
            "list_id" => [5079402, 5181002, 38375402, 5101003, 74056416, 5063402, 73071403], #[38375402], #"all", # for s2m poste only
            "out_file" => "C:/Users/navarrel/Documents/Workspace/Data/outputs/output_postes_test.nc"
        ),
        "TUNING" => Dict(
            "physics" => Dict(),
            "params" => Dict(),
            "tile" => "open"
        )
    )
end

settings = build_settings()
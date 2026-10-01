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
            "list_id" => [38472403], #[38005402, 73013001, 73139401, 38191002,  5007001, 73034002, 73071403, 73055001,  5026001,  5026400,  5027001,  5077402, 38472403, 73132003, 74136003, 73093001,  6073405,  6073400, 6073005, 73150400, 73296406, 74136005, 74191003, 74056005, 38375402,  5064403, 73306401,  6153400,  5096404,  5044400, 73206001,  5110001,  4096401,  5096003, 73290002, 73296005, 5181002], #[5079402, 5181002, 38375402, 5101003, 74056416, 5063402, 73071403], #[38472403], #"all", # for s2m poste only
        ),
        "TUNING" => Dict(
            "physics" => Dict(),
            "params" => Dict(),
            "tile" => "open"
        )
    )
end

settings = build_settings()
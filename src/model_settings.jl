function build_settings()
    return OrderedDict(
        "INIT" => Dict(
            "precision" => Float32,
            "prec_multi" => scheme(TanhPrecip;), #LogbisPrecip; mult1 = -0.015, mult2 = 0.44, cst = 48
            "file_path" => "C:/Users/navarrel/Documents/Workspace/Data/s2m/postes/meteo/FORCING_alpes_2018080106_2024080106.nc", # change it
            "shapefile" => "C:/Users/navarrel/Documents/Workspace/MNT_alpes/shapefile/1D/s2m/stations_reanalysis_S2M_alpes_massif.shp", # for s2m poste only
            "list_id" => [38005402, 73013001, 73139401, 38191002,  5007001, 73034002, 73071403, 73055001,  5026001,  5026400,  5027001,  5077402, 38472403, 73132003, 74136003, 73093001,  6073405,  6073400, 6073005, 73150400, 73296406, 74136005, 74191003, 74056005, 38375402,  5064403, 73306401,  6153400,  5096404,  5044400, 73206001,  5110001,  4096401,  5096003, 73290002, 73296005, 5181002], #[38375402], #[38472403], #[38005402, 73013001, 73139401, 38191002,  5007001, 73034002, 73071403, 73055001,  5026001,  5026400,  5027001,  5077402, 38472403, 73132003, 74136003, 73093001,  6073405,  6073400, 6073005, 73150400, 73296406, 74136005, 74191003, 74056005, 38375402,  5064403, 73306401,  6153400,  5096404,  5044400, 73206001,  5110001,  4096401,  5096003, 73290002, 73296005, 5181002], #[5079402, 5181002, 38375402, 5101003, 74056416, 5063402, 73071403], #"all", # for s2m poste only
        ),
        "TUNING" => Dict(
            "physics" => Dict(),
            "params" => Dict("Tprof" => 273.15),
            "tile" => "open"
        )
    )
end

function build_path_settings()
    return OrderedDict(
        "metrics" => "C:/Users/navarrel/Documents/Workspace/Plots/figure/calib/z0/metrics_z0.csv",
        "alt_band" => "C:/Users/navarrel/Documents/Workspace/Plots/figure/calib/z0/snowdepth_band_loop_z0.png",
        "multi_station" => "C:/Users/navarrel/Documents/Workspace/Plots/figure/calib/z0/snowdepth_stations_z0.png",
        "single_station" => "C:/Users/navarrel/Documents/Workspace/Plots/figure/calib/z0/snowdepth_station_z0",
        "boxplot_band" => "C:/Users/navarrel/Documents/Workspace/Plots/figure/calib/rmse_by_config_band.png",
        "boxplot" => "C:/Users/navarrel/Documents/Workspace/Plots/figure/calib/rmse_by_config.png",
    )
end

settings = build_settings()
settings_path = build_path_settings()
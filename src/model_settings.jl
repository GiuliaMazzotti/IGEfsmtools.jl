function build_settings()
    return OrderedDict(
        "INIT" => Dict(
            "precision" => Float32,
            "prec_multi" => scheme(LinearPrecip; mult = 0, cst = 1), #scheme(LinearPrecip; mult = 0, cst = 1), #LogbisPrecip; mult1 = -0.015, mult2 = 0.44, cst = 48
            "file_path" => "C:/Users/navarrel/Documents/Workspace/Data/s2m/postes/meteo/FORCING_alpes_1958080106_2024080106_trans.nc", # change it
            "shapefile" => "C:/Users/navarrel/Documents/Workspace/MNT_alpes/shapefile/1D/s2m/stations_reanalysis_S2M_alpes_massif_skyview.shp", # for s2m poste only
            "list_id" => sort([73071403, 73040402, 38472002, 38187400, 38375402, 4096401]), #"all", #[38005402, 73013001, 73139401, 38191002,  5007001, 73034002, 73071403, 73055001,  5026001,  5026400,  5027001,  5077402, 38472403, 73132003, 74136003, 73093001,  6073405,  6073400, 6073005, 73150400, 73296406, 74136005, 74191003, 74056005, 38375402,  5064403, 73306401,  6153400,  5096404,  5044400, 73206001,  5110001,  4096401,  5096003, 73290002, 73296005, 5181002], #[38375402], #[38472403], #[38005402, 73013001, 73139401, 38191002,  5007001, 73034002, 73071403, 73055001,  5026001,  5026400,  5027001,  5077402, 38472403, 73132003, 74136003, 73093001,  6073405,  6073400, 6073005, 73150400, 73296406, 74136005, 74191003, 74056005, 38375402,  5064403, 73306401,  6153400,  5096404,  5044400, 73206001,  5110001,  4096401,  5096003, 73290002, 73296005, 5181002], #[5079402, 5181002, 38375402, 5101003, 74056416, 5063402, 73071403], # for s2m poste only
            "period" => [2014,2024], 
        ),
        "TUNING" => Dict(
            "physics" => Dict(),
            "params" => Dict{String, Any}("Tprof" => 273.15),
            "tile" => "open"
        )
    )
end

function build_path_settings()
    return OrderedDict(
        "metrics" => "C:/Users/navarrel/Documents/Workspace/Plots/figure/calib/stations/metrics.csv",  #z0/metrics_z0.csv #precip/metrics_precip
        "hs_metrics" => "C:/Users/navarrel/Documents/Workspace/Plots/figure/calib/stations/metrics_max_hs.csv",
        "plot" => "C:/Users/navarrel/Documents/Workspace/Plots/figure/calib/stations/test/",
    )
end

settings = build_settings()
settings_path = build_path_settings()
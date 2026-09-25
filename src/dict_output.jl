const AVAILABLE_OUTPUT_VARS = Dict(
    # Grid
    # "Dzsnow", "Dzsoil"
    "Nb_points" => Dict(
        "longname" => "stations id",
        "unit" => "",
        "type" => INSTANT
    ),
    "Nx" => Dict(
        "longname" => "latitude",
        "unit" => "",
        "type" => INSTANT
    ),
    "Ny" => Dict(
        "longname" => "longitude",
        "unit" => "",
        "type" => INSTANT
    ),

    # Parameters
    # "dt", "zT", "zU", "zRH", "Nitr", "cvai", "pmultf_for", "Tsnow_min", "rho0, "rhob", rhoc", "rhof", "rhos_min", "Ds_min", "fsat", "Tprof"

    # Surface
    # "grid", "dem", "Ld", "slopemu", "xi", "fsky_terr", "active", "z0_snow", "z0sf", "alb0", "VAI", "lai", "fveg", "fves", "fsky", "vfhp", "hcan",
    # "canh", "scap", "trcn", "pmultf", "prec_multi", "fcly", "fsnd", "b", "hcap_soil", "hcon_soil", "sathh", "Vsat", "Vcrit"

    # State 
    #"grid", "Qcan", "Sveg", "Tcan", "theta", "Tveg", "histowet"
    "Ds" => Dict(
        "longname" => "snow depth",
        "unit" => "m",
        "type" => INSTANT
    ),
    "Tsrf" => Dict(
        "longname" => "surface temperature",
        "unit" => "K",
        "type" => INSTANT
    ),
    "fsnow" => Dict(
        "longname" => "snow covered fraction",
        "unit" => "-",
        "type" => INSTANT
    ),
    "Sliq" => Dict(
        "longname" => "liquid water content",
        "unit" => "mm",
        "type" => INSTANT
    ),
    "Sice" => Dict(
        "longname" => "solid water content",
        "unit" => "mm",
        "type" => INSTANT
    ),
    "Nsnow" => Dict(
        "longname" => "number of snow layers",
        "unit" => "-",
        "type" => INSTANT
    ),
    "albs" => Dict(
        "longname" => "snow albedo",
        "acronymn" => "alse",
        "unit" => "-",
        "type" => INSTANT
    ),
    "Tsnow1" => Dict(
        "longname" => "snow temperatures in layer 1",
        "unit" => "K",
        "type" => INSTANT
    ),
    "Tsnow2" => Dict(
        "longname" => "snow temperatures in layer 2",
        "unit" => "K",
        "type" => INSTANT
    ),
    "Tsnow3" => Dict(
        "longname" => "snow temperatures in layer 3",
        "unit" => "K",
        "type" => INSTANT
    ),
    "Tsoil1" => Dict(
        "longname" => "soil temperatures in layer 1",
        "unit" => "K",
        "type" => INSTANT
    ),
    "Tsoil2" => Dict(
        "longname" => "soil temperatures in layer 2",
        "unit" => "K",
        "type" => INSTANT
    ),
    "Tsoil3" => Dict(
        "longname" => "soil temperatures in layer 3",
        "unit" => "K",
        "type" => INSTANT
    ),
    "Tsoil4" => Dict(
        "longname" => "soil temperatures in layer 4",
        "unit" => "K",
        "type" => INSTANT
    ),
    "snowdepthmin" => Dict(
        "longname" => "minimum snow depth at time step of swemin",
        "unit" => "m",
        "type" => INSTANT
    ),
    "snowdepthmax" => Dict(
        "longname" => "maximum snow depth at time stemp of swemax",
        "unit" => "m",
        "type" => INSTANT
    ),
    "snowdepthhist" => Dict(
        "longname" => "history of snow depth during last 14 days (most recent entries first)",
        "unit" => "m",
        "type" => INSTANT
    ),
    "swemin" => Dict(
        "longname" => "minimum swe during the season",
        "unit" => "mm",
        "type" => INSTANT
    ),
    "swemax" => Dict(
        "longname" => "maximum swe during the season",
        "unit" => "mm",
        "type" => INSTANT
    ),
    "swehist" => Dict(
        "longname" => "history of SWE during last 14 days",
        "unit" => "mm",
        "type" => INSTANT
    ),
    
    # Diagnostics
    # "grid", "es", "Qa", "Uaeff", "Sfeff", "SWveg", "SWsci", "LWeff", "ksnow", "csoil", "ksoil", "gs1", "Ds1", "Ts1", "ks1", "Tveg0", "KHa", "KHv",  
    # "KWv", "Usc", "Eveg", "LWsci", "LWveg","intcpt", "Sbveg", "unload", "Roff_bare", "snowdepth0", "Sice0", "Ds0"
    "Roff" => Dict(
        "longname" => "total runoff",
        "unit" => "mm/tstep",
        "type" => SUM
    ),
    "Roff_snow" => Dict(
        "longname" => "runoff from snow tile",
        "unit" => "mm/tstep",
        "type" => SUM
    ),
    "meltflux_out" => Dict(
        "longname" => "runoff from snow",
        "unit" => "mm/tstep",
        "type" => SUM
    ),
    "Sbsrf" => Dict(
        "longname" => "sublimation from snow",
        "unit" => "mm/tstep",
        "type" => SUM
    ),
    "G" => Dict(
        "longname" => "heat flux into the surface",
        "unit" => "W/m^2",
        "type" => MEAN
    ),
    "H" => Dict(
        "longname" => "sensible heat flux",
        "unit" => "W/m^2",
        "type" => MEAN
    ),
    "LE" => Dict(
        "longname" => "latent heat flux",
        "unit" => "W/m^2",
        "type" => MEAN
    ),
    "Rnet" => Dict(
        "longname" => "net radiation",
        "unit" => "W/m^2",
        "type" => MEAN
    ),
    "SWsrf" => Dict(
        "longname" => "net shortwave radiation absorbed by the surface",
        "unit" => "W/m^2",
        "type" => MEAN
    ),
    "Esrf" => Dict(
        "longname" => "moisture flux from the surface",
        "unit" => "kg/m^2/s",
        "type" => MEAN
    ),
    "Hsrf" => Dict(
        "longname" => "sensible heat flux from the surface",
        "unit" => "W/m^2",
        "type" => MEAN
    ),
    "LEsrf" => Dict(
        "longname" => "latent heat flux from the surface",
        "unit" => "W/m^2",
        "type" => MEAN
    ),
    "Rsrf" => Dict(
        "longname" => "net radiation at surface",
        "unit" => "W/m^2",
        "type" => MEAN
    ),
    "Melt" => Dict(
        "longname" => "surface melt rate",
        "unit" => "kg/m^2/s",
        "type" => MEAN
    ),    
    "Gsoil" => Dict(
        "longname" => "heat flux into soil",
        "unit" => "W/m^2",
        "type" => MEAN
    ),
    "KH" => Dict(
        "longname" => "Eddy diffusivity for heat to the atmosphere",
        "unit" => "m/s",
        "type" => MEAN
    ),
    "KHg" => Dict(
        "longname" => "Eddy diffusivity for heat from the ground",
        "unit" => "m/s",
        "type" => MEAN
    ),
    "KWg" => Dict(
        "longname" => "Eddy diffusivity for water from the ground",
        "unit" => "m/s",
        "type" => MEAN
    ),

    # Physics
    # "snow_albedo", "land_cover", "substrate", "conductivity", "fresh_snow_density", "compaction", "hydrology", "layering", "snow_fraction"
    
    # Others
    "time" => Dict(
        "longname" => "datetime",
        "unit" => "",
        "type" => INSTANT
    ),
    "Icemlt" => Dict(
        "longname" => "runoff rate from ice",
        "unit" => "mm/s",
        "type" => SUM
    ),
    "SWE" => Dict(
        "longname" => "snow water equivalent",
        "unit" => "mm",
        "type" => INSTANT
    ),
    "Sdirt" => Dict(
        "longname" => "incoming direct shortwave radiation",
        "unit" => "W/m^2",
        "type" => MEAN
    ),
    "Sdift" => Dict(
        "longname" => "incoming diffuse shortwave radiation",
        "unit" => "W/m^2",
        "type" => MEAN
    ),
    "LWt" => Dict(
        "longname" => "incoming longwave radiation",
        "unit" => "W/m^2",
        "type" => MEAN
    ),
    "asrf_out" => Dict(
        "longname" => "surface albedo",
        "unit" => "-",
        "type" => INSTANT
    )
)
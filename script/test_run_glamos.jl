using Dates
using IGEfsmtools
 
settings = Dict(
    "tile" => "open",
    "config" => Dict("SNFRAC" => 0),
    "params" => Dict("wind_scaling" => 1.0),
    "met_type" => :GLAMOS,
    "met_folder" => "C:/Users/mazzottg/Documents/10_Data/fsm4glamos/OUTPUT_GRID_GALE_0100/PROCESSED_ANALYSIS/COSMO_1EFA",
    "met_prefix" => "COSMO",
    "tvt_folder" => "",
    "lus_file" => "C:/Users/mazzottg/Documents/10_Data/fsm4glamos/GALE_LUS_2025_100.mat",
    "out_folder" => "C:/Users/mazzottg/Documents/10_Data/fsm4glamos/output_test_mat",
    "output_vars" => ["snowdepth", "fsnow", "Roff", "meltflux_out"],
    )
 
settings_nc = Dict(
    "tile" => "open",
    "config" => Dict("SNFRAC" => 0),
    "params" => Dict("wind_scaling" => 1.0),
    "met_type" => :GLAMOS_nc,
    "met_folder" => "C:/Users/mazzottg/Documents/10_Data/fsm4glamos/ncfiles",
    "met_prefix" => "COSMO",
    "tvt_folder" => "",
    "lus_file" => "C:/Users/mazzottg/Documents/10_Data/fsm4glamos/GALE_LUS_2025_100.mat",
    "out_folder" => "C:/Users/mazzottg/Documents/10_Data/fsm4glamos/output_test",
    "output_vars" => ["snowdepth", "fsnow", "Roff", "meltflux_out"],
    )

settings_wtrans = Dict(
    "tile" => "open",
    "config" => Dict("SNFRAC" => 0, "SNTRAN" => 1, ),
    "params" => Dict("wind_scaling" => 1.0),
    "met_type" => :GLAMOS,
    "met_folder" => "C:/Users/mazzottg/Documents/10_Data/fsm4glamos/OUTPUT_GRID_GALE_0100/PROCESSED_ANALYSIS/COSMO_1EFA",
    "met_prefix" => "COSMO",
    "tvt_folder" => "",
    "lus_file" => "C:/Users/mazzottg/Documents/10_Data/fsm4glamos/GALE_LUS_2025_100.mat",
    "out_folder" => "C:/Users/mazzottg/Documents/10_Data/fsm4glamos/output_test_transport",
    "output_vars" => ["snowdepth", "fsnow", "Roff", "meltflux_out"],
    )
 
times = DateTime(2022, 9, 1, 6):Hour(1):DateTime(2023, 9, 1, 6)
 
run_grid_simulation(settings=settings_wtrans, times=times)
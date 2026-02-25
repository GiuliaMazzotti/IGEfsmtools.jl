cd(@__DIR__)

using Dates
using CSV
using DataFrames
using FSMOSHD
using NCDatasets
using Base: findall
using ArchGDAL
using GeoDataFrames
using NetCDF
# using IGEfsmtools

#####################################################################################
# df_meteo       => fast dim : Number_of_points (Column read time: 0.1630676 / Row read time: 288.5276814)
# df_meteo_trans => fast dim : time
#####################################################################################

# initialization function
    # sets parameters (topo, meteo), configuration, variables (format)
    # opens meteo file
function setup_meteo()

     # read meteo file
    df_meteo_trans = Dataset("C:/Users/navarrel/Documents/Workspace/Data/s2m/alp_allslopes/meteo/FORCING_2023080106_2024080106.nc")

    # define meteo data struct
    met = MET{Float32,Int32}()

    return met, df_meteo_trans
end

#####################################################################################
function setup_output(N, t, time, df_meteo_trans)

    ds_out = NCDataset("C:/Users/navarrel/Documents/Workspace/Data/outputs/output_2023-2024_S2M_full.nc", "c")

    # --- define dimensions ---
    defDim(ds_out, "Number_of_points", N)
    defDim(ds_out, "time", t)
    
    defVar(ds_out, "massif", Int32, ("Number_of_points",))[:] = df_meteo_trans["massif_number"]
    defVar(ds_out, "ZS", Float32, ("Number_of_points",))[:] = df_meteo_trans["ZS"]
    defVar(ds_out, "slope", Float32, ("Number_of_points",))[:] = df_meteo_trans["slope"]
    defVar(ds_out, "aspect", Float32, ("Number_of_points",))[:] = df_meteo_trans["aspect"]
    defVar(ds_out, "time", String, ("time",))[:] = string.(time)[:]

    var_out = ["hs", "Tsnow1", "Tsnow2", "Tsnow3", "Ts", "albedo", "I", "W", "snow_depth_min", "snow_depth_max", "swemin", "swemax"]
    for var in var_out
        defVar(ds_out, var, Float64, ("time","Number_of_points"))
    end

    return ds_out
end

#####################################################################################
function setup_fsm(zs)

    # define custom settings
    settings = Dict("tile" => "open", "params" => Dict("wind_scaling" => 0.7,
                                                        "dt" => 3600,
                                                        "zT" => 1.5,
                                                        "zU" => 5.0,
                                                        "zRH" => 1.5))

    lus = Dict()
    lus["skyvf"] = Dict("data" => [1.0;;])           
    lus["x"] = Dict("data" => [1.0;;])
    lus["y"] = Dict("data" => [1.0;;])
    lus["elevation"] = Dict("data" => [Float32(zs);;])
    lus["slopemu"] = Dict("data" => [1.0;;])
    lus["xi"] = Dict("data" => [1.0;;])
    lus["Ld"] = Dict("data" => [1.0;;])
    lus["prec_multi"] = Dict("data" => [1.0;;])

    # create fsm struct
    fsm = setup(Float32, Int32, lus, 1, 1, settings)
    
    return fsm 

end

#####################################################################################
function run_fsm(n, t, fsm, met, df_meteo_trans, time)

    # allocate output variable-wise
    hs = zeros(t)
    Tsnow1 = fill(NaN, t)
    Tsnow2 = fill(NaN, t)
    Tsnow3 = fill(NaN, t)
    Tsrf = zeros(t)
    alb = zeros(t)
    Sice = zeros(t)
    Sliq = zeros(t)
    snowdepthmin = zeros(t)
    snowdepthmax = zeros(t)
    swemin = zeros(t)
    swemax = zeros(t)

        # --- Preload everything from disk once ---               
    DIR_SW    = df_meteo_trans["DIR_SWdown"][n, :]           
    SCA_SW    = df_meteo_trans["SCA_SWdown"][n, :]
    LWdown    = df_meteo_trans["LWdown"][n, :]
    Snowf     = df_meteo_trans["Snowf"][n, :]
    Rainf     = df_meteo_trans["Rainf"][n, :]
    Tair      = df_meteo_trans["Tair"][n, :]
    Qair      = df_meteo_trans["Qair"][n, :]
    Wind      = df_meteo_trans["Wind"][n, :]
    PSurf     = df_meteo_trans["PSurf"][n, :]

    # time loop
    for i in 1:t

        t_i = time[i]

        # assign met fields 
        met.year  .= year(t_i)
        met.month .= month(t_i)
        met.day   .= day(t_i)
        met.hour  .= hour(t_i)
        met.Sdir  .= DIR_SW[i]
        met.Sdif  .= SCA_SW[i]
        met.Sdird .= DIR_SW[i]
        met.LW    .= LWdown[i]
        met.Sf    .= Snowf[i] * Int32(3600)
        met.Rf    .= Rainf[i] * Int32(3600)
        met.Ta    .= Tair[i]
        met.RH    .= Qair[i]
        met.Ua    .= Wind[i]
        met.Ps    .= PSurf[i]
        met.Sf24h .= sum(Snowf[max(1,i-23):i])
    
        # run model
        step!(fsm, met, t_i)
        println(i)

        # store outputs (unchanged from your code)
        hs[i] = dropdims(sum(fsm.Ds, dims=1), dims=1)[1]
        if fsm.Nsnow[1,1] == 1
            Tsnow1[i] = fsm.Tsnow[1,1,1]
        elseif fsm.Nsnow[1,1] == 2
            Tsnow1[i] = fsm.Tsnow[1,1,1]
            Tsnow2[i] = fsm.Tsnow[2,1,1]
        elseif fsm.Nsnow[1,1] == 3
            Tsnow1[i] = fsm.Tsnow[1,1,1]
            Tsnow2[i] = fsm.Tsnow[2,1,1]
            Tsnow3[i] = fsm.Tsnow[3,1,1]
        end
        if fsm.asrf_out[1,1] < 0.6
            alb[i] = NaN
        else
            alb[i] = fsm.asrf_out[1,1]
        end
        Tsrf[i] = fsm.Tsrf[1,1]
        Sice[i] = dropdims(sum(fsm.Sice,dims=1), dims=1)[1]
        Sliq[i] = dropdims(sum(fsm.Sliq,dims=1), dims=1)[1]
        snowdepthmin[i] = fsm.snowdepthmin[1,1]
        snowdepthmax[i] = fsm.snowdepthmax[1,1]
        swemin[i]       = fsm.swemin[1,1]
        swemax[i]       = fsm.swemax[1,1]
    end

    df_results = DataFrame(hs=hs, Tsnow1=Tsnow1, Tsnow2=Tsnow2, Tsnow3=Tsnow3, Ts=Tsrf, albedo=alb, I=Sice, W=Sliq, snow_depth_min=snowdepthmin, snow_depth_max=snowdepthmax, swemin=swemin, swemax=swemax)

    return df_results

end
#####################################################################################
met, df_meteo_trans = setup_meteo()
N = df_meteo_trans.dim["Number_of_points"]
t = df_meteo_trans.dim["time"]
time = df_meteo_trans["time"]

# Initialize output dataset
ds_out = setup_output(N, t, time, df_meteo_trans)

for n in 1:N
    zs = df_meteo_trans["ZS"][n]
    fsm = setup_fsm(zs)
    df_results = run_fsm(n, t, fsm, met, df_meteo_trans, time)
    
    for var in names(df_results)[:] #[2:end]
        ds_out[var][:,n] = df_results[!,var]
        # NetCDF.putvar!(ds_out, var, df_results[!, var], start=[1,n], count=[t,1])
    end
    println(n)
end

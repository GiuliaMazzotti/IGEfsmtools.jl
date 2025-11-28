cd(@__DIR__)

using Dates
using CSV
using DataFrames
using FSMOSHD
using NCDatasets
using Base: findall
using ArchGDAL
using GeoDataFrames
# using IGEfsmtools

#####################################################################################
# df_meteo       => fast dim : Number_of_points (Column read time: 0.1630676 / Row read time: 288.5276814)
# df_meteo_trans => fast dim : time
# This script takes RAM but is suppose to be faster
#####################################################################################

# initialization function
    # sets parameters (topo, meteo), configuration, variables (format)
    # opens meteo file
function setup_example()

    # read meteo file
    df_meteo_trans = Dataset("C:/Users/elise/Documents/These/Workspace/Data/S2M/meteo/FORCING_1958080106_2024080106_trans.nc")
    massif_shp = ArchGDAL.read("C:/Users/elise/Documents/These/Workspace/Data/S2M/shapefile/massifs_alpes_2154.shp")
    shapefile = ArchGDAL.getlayer(massif_shp, 0) |> DataFrame

    # --- Preload everything from disk once ---
    t = df_meteo_trans.dim["time"]
    n = df_meteo_trans.dim["Number_of_points"]

    DIR_SW = Array{Float32}(undef, t, n)
    SCA_SW = Array{Float32}(undef, t, n)
    LWdown = Array{Float32}(undef, t, n)
    Snowf  = Array{Float32}(undef, t, n)
    Rainf  = Array{Float32}(undef, t, n)
    Tair   = Array{Float32}(undef, t, n)
    Qair   = Array{Float32}(undef, t, n)
    Wind   = Array{Float32}(undef, t, n)
    PSurf  = Array{Float32}(undef, t, n)
    println("init")
    time   = df_meteo_trans["time"][:] 

    for nb in 1:df_meteo_trans.dim["Number_of_points"]                
        DIR_SW[nb, :]    = df_meteo_trans["DIR_SWdown"][nb, :]            
        SCA_SW[nb, :]    = df_meteo_trans["SCA_SWdown"][nb, :] 
        LWdown[nb, :]    = df_meteo_trans["LWdown"][nb, :] 
        Snowf[nb, :]     = df_meteo_trans["Snowf"][nb, :] 
        Rainf[nb, :]     = df_meteo_trans["Rainf"][nb, :] 
        Tair[nb, :]      = df_meteo_trans["Tair"][nb, :] 
        Qair[nb, :]      = df_meteo_trans["Qair"][nb, :] 
        Wind[nb, :]      = df_meteo_trans["Wind"][nb, :] 
        PSurf[nb, :]     = df_meteo_trans["PSurf"][nb, :] 
    end
    
    # define custom settings
    settings = Dict("tile" => "open", "params" => Dict("wind_scaling" => 0.7,
                                                        "dt" => 3600,
                                                        "zT" => 1.5,
                                                        "zU" => 5.0,
                                                        "zRH" => 1.5))
    
    # create fsm struct
    fsm = setup(Float32, Int32, lus, 1, 1, settings)
    
    # define meteo data struct
    met = MET{Float32,Int32}()
    
    return fsm, met, df_meteo_trans, shapefile, time, DIR_SW, SCA_SW, LWdown, Snowf, Rainf, Tair, Qair, Wind, PSurf 

end

#####################################################################################
# function mask(massif, alt, asp, slope, df_meteo_trans, shapefile)

#     # set landuse properties
#     lus = Dict()
#     lus["skyvf"] = Dict("data" => [1.0;;])           
#     lus["x"] = Dict("data" => [1.0;;])
#     lus["y"] = Dict("data" => [1.0;;])
#     lus["dem"] = Dict("data" => [Float32(alt);;])
#     lus["slopemu"] = Dict("data" => [1.0;;])
#     lus["xi"] = Dict("data" => [1.0;;])
#     lus["Ld"] = Dict("data" => [1.0;;])
#     lus["prec_multi"] = Dict("data" => [1.0;;])

#     # set mask
#     id_massif = shapefile[shapefile.nom .== massif, "massif_num"]
#     if slope == 0.0
#         mask = (df_meteo_trans["ZS"][:] .== alt) .& (df_meteo_trans["massif_number"][:] .== id_massif) .& (df_meteo_trans["slope"][:] .== slope)
#     else
#         mask = (df_meteo_trans["ZS"][:] .== alt) .& (df_meteo_trans["massif_number"][:] .== id_massif) .& (df_meteo_trans["slope"][:] .== slope) .& (df_meteo_trans["aspect"][:] .== asp)
#     end
#     idx = findall(!=(0), mask)
#     return idx
# end

#####################################################################################
function run_fsm(idx, fsm, met, time, DIR_SW, SCA_SW, LWdown, Snowf, Rainf, Tair, Qair, Wind, PSurf)

    N = size(time, 1)

    # allocate output variable-wise
    hs = zeros(N)
    Tsnow1 = fill(NaN, N)
    Tsnow2 = fill(NaN, N)
    Tsnow3 = fill(NaN, N)
    Tsrf = zeros(N)
    alb = zeros(N)
    Sice = zeros(N)
    Sliq = zeros(N)
    snowdepthmin = zeros(N)
    snowdepthmax = zeros(N)
    swemin = zeros(N)
    swemax = zeros(N)

    # time loop
    for i in 1:N

        t_i = time[i]

        # assign met fields 
        met.year  .= year(t_i)
        met.month .= month(t_i)
        met.day   .= day(t_i)
        met.hour  .= hour(t_i)
        met.Sdir  .= DIR_SW[idx, i]
        met.Sdif  .= SCA_SW[idx, i]
        met.Sdird .= DIR_SW[idx, i]
        met.LW    .= LWdown[idx, i]
        met.Sf    .= Snowf[idx, i] * Int32(3600)
        met.Rf    .= Rainf[idx, i] * Int32(3600)
        met.Ta    .= Tair[idx, i]
        met.RH    .= Qair[idx, i]
        met.Ua    .= Wind[idx, i] 
        met.Ps    .= PSurf[idx, i]
        met.Sf24h .= sum(Snowf[idx, max(1,i-23):i])

        # run model
        println("step")
        step!(fsm, met, t_i)

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
        alb[i] = fsm.asrf_out[1,1]
        Tsrf[i] = fsm.Tsrf[1,1]
        Sice[i] = dropdims(sum(fsm.Sice,dims=1), dims=1)[1]
        Sliq[i] = dropdims(sum(fsm.Sliq,dims=1), dims=1)[1]
        snowdepthmin[i] = fsm.snowdepthmin[1,1]
        snowdepthmax[i] = fsm.snowdepthmax[1,1]
        swemin[i]       = fsm.swemin[1,1]
        swemax[i]       = fsm.swemax[1,1]
    end

    alb_snow = copy(alb) 
    alb_snow[alb .< 0.6] .= NaN

    df_results = DataFrame(time=time, hs=hs, Tsnow1=Tsnow1, Tsnow2=Tsnow2, Tsnow3=Tsnow3, Ts=Tsrf, albedo=alb_snow, I=Sice, W=Sliq, snow_depth_min=snowdepthmin, snow_depth_max=snowdepthmax, swemin=swemin, swemax=swemax)

    return df_results

end
#####################################################################################
fsm, met, df_meteo_trans, shapefile, time, DIR_SW, SCA_SW, LWdown, Snowf, Rainf, Tair, Qair, Wind, PSurf = setup_example() 
print("setup")

# Initialize output dataset
ds_out = NCDataset("C:/Users/elise/Documents/These/Workspace/Data/S2M/meteo/output_1958-2024_S2M_full.nc", "c")
nb = df_meteo_trans.dim["Number_of_points"]
time_str = string.(time)

# --- define dimensions ---
defDim(ds_out, "massif", nb)
defDim(ds_out, "ZS", nb)
defDim(ds_out, "slope", nb)
defDim(ds_out, "aspect", nb)
for var in names(df_results)[:]
    defDim(ds_out, var, nb) 
end

# --- assigne variables value ---
defVar(ds_out, "time", String, ("time",))[:] = time_str

for n in 1:nb
    m = df_meteo_trans["massif_number"][n]
    zs = df_meteo_trans["ZS"][n]
    s = df_meteo_trans["slope"][n]
    a = df_meteo_trans["aspect"][n]

    defVar(ds_out, "massif", String, ("massif",))[n] = m
    defVar(ds_out, "ZS", Float32, ("ZS",))[n] = zs
    defVar(ds_out, "slope", Float32, ("slope",))[n] = s
    defVar(ds_out, "aspect", Float32, ("aspect",))[n] = a

    lus = Dict()
    lus["skyvf"] = Dict("data" => [1.0;;])           
    lus["x"] = Dict("data" => [1.0;;])
    lus["y"] = Dict("data" => [1.0;;])
    lus["dem"] = Dict("data" => [Float32(alt);;])
    lus["slopemu"] = Dict("data" => [1.0;;])
    lus["xi"] = Dict("data" => [1.0;;])
    lus["Ld"] = Dict("data" => [1.0;;])
    lus["prec_multi"] = Dict("data" => [1.0;;])

    # idx = mask(m, zs, a, s, df_meteo_trans, shapefile)
    df_results = run_fsm(n, fsm, met, time, DIR_SW, SCA_SW, LWdown, Snowf, Rainf, Tair, Qair, Wind, PSurf)
    for var in names(df_results)[:]
        defVar(ds_out, var, Float32, (var,))[n,:] = df_results
    end
end

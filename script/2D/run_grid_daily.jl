cd(@__DIR__)

using Dates
using CSV
using DataFrames
using FSMOSHD
using NCDatasets
using Base: findall
using ArchGDAL
using GeoDataFrames
using DataStructures
using Statistics
# using IGEfsmtools

# /!\ Retirer wind_scaling
# /!\ SNFRAC = 3
# /!\ Dims mismatch

# initialization function 
    # sets parameters (topo, meteo), configuration, variables (format)
    # opens meteo file
function setup_example()

    # read meteo file
    df_meteo = Dataset("C:/Users/navarrel/Documents/Workspace/Data/s2m/interpol/FORCING_s2m_argentiere_100m/meteo/FORCING_2023080106_2024080106.nc")

    Nx = df_meteo.dim["x"]
    Ny = df_meteo.dim["y"]

    # set landuse properties
    lus = Dict()
    lus["skyvf"] = Dict("data" => [fill(1.0, Nx);;])           
    lus["x"] = Dict("data" => [df_meteo["LON"];;])
    lus["y"] = Dict("data" => [df_meteo["LAT"];;])
    lus["dem"] = Dict("data" => [df_meteo["ZS"];;])
    lus["slopemu"] = Dict("data" => [fill(1.0, Nx);;])
    lus["xi"] = Dict("data" => [fill(1.0, Nx);;])
    lus["Ld"] = Dict("data" => [fill(1.0, Nx);;])
    lus["prec_multi"] = Dict("data" => [fill(1.0, Nx);;])
   # lus["landcover"] = Dict("data" => [df_meteo["GRILLE a faire 1 = open 2 = glacier"];;])  
    
    # define custom settings
    settings = Dict("tile" => "open", "Nx" => Nx, "Ny" => Ny, "params" => Dict("wind_scaling" => 0.7, "dt" => 3600,
                                                                                         "zT" => 10,
                                                                                         "zU" => 10,
                                                                                        "zRH" => 10))
    
    # create fsm struct
    fsm = setup(Float32, Int32, lus, Nx, Ny, settings)
    
    # define meteo data struct
    met = MET{Float32,Int32}(Nx=Nx, Ny=Ny)
    
     return fsm, met, df_meteo

end

#####################################################################################
function run_fsm(fsm, met, df_meteo, time_res)

    dims = (df_meteo.dim["x"], df_meteo.dim["y"], trunc(Int, df_meteo.dim["time"]./time_res)) # (df_meteo.dim["time"],df_meteo.dim["Number_of_points"])
    dims_day =  (df_meteo.dim["x"], df_meteo.dim["y"], time_res)

    # allocate output variable-wise
    hs = zeros(dims)
    Tsnow1 = fill(NaN, dims)
    Tsnow2 = fill(NaN, dims)
    Tsnow3 = fill(NaN, dims)
    Tsrf = zeros(dims)
    alb = zeros(dims)
    Sice = zeros(dims)
    Sliq = zeros(dims)
    # snowdepthmin = zeros(dims)
    # snowdepthmax = zeros(dims)
    # swemin = zeros(dims)
    # swemax = zeros(dims)

    # allocate output temporary variable-daily
    hs_day = zeros(dims_day)
    Tsnow1_day = fill(NaN, dims_day)
    Tsnow2_day = fill(NaN, dims_day)
    Tsnow3_day = fill(NaN, dims_day)
    Tsrf_day = zeros(dims_day)
    alb_day = zeros(dims_day)
    Sice_day = zeros(dims_day)
    Sliq_day = zeros(dims_day)
    
    # sf24 = [sum(df_meteo["Snowf"][id_station, max(1, i-23):i]) for i in 1:length(df_meteo["Snowf"][id_station,:])]

    # --- Preload everything from disk once ---
    time      = df_meteo["time"]                
    DIR_SW    = df_meteo["DIR_SWdown"]           
    SCA_SW    = df_meteo["SCA_SWdown"]
    LWdown    = df_meteo["LWdown"]
    Snowf     = df_meteo["Snowf"]
    Rainf     = df_meteo["Rainf"]
    Tair      = df_meteo["Tair"]
    Qair      = df_meteo["Qair"]
    Wind      = df_meteo["Wind"]
    PSurf     = df_meteo["PSurf"]

    N = size(time, 1)   # or length(time)
    daily = 1
    d = 1

    # time loop
    for i in 1:N

        t_i = time[i]

        # assign met fields 
        met.year  .= year(t_i)
        met.month .= month(t_i)
        met.day   .= day(t_i)
        met.hour  .= hour(t_i)
        met.Sdir  .= DIR_SW[:,:,i]
        met.Sdif  .= SCA_SW[:,:,i]
        met.Sdird .= DIR_SW[:,:,i]
        met.LW    .= LWdown[:,:,i]
        met.Sf    .= Snowf[:,:,i] .* Int32(3600)
        met.Rf    .= Rainf[:,:,i] .* Int32(3600)
        met.Ta    .= Tair[:,:,i]
        met.RH    .= Qair[:,:,i]
        met.Ua    .= Wind[:,:,i]
        met.Ps    .= PSurf[:,:,i]
        met.Sf24h .= dropdims(sum(Snowf[:,:,max(1,i-23):i], dims=3), dims=3)
        
        # run model
        step!(fsm, met, t_i)
        
        if daily <= 24
            # store temporary daily outputs 
            hs_day[:,:,daily] = dropdims(sum(fsm.Ds, dims=1), dims=1)[:]
            
            Tsnow1_day[:,:,daily] = fsm.Tsnow[1,:,:]
            Tsnow2_day[:,:,daily] = fsm.Tsnow[2,:,:]
            Tsnow3_day[:,:,daily] = fsm.Tsnow[3,:,:]

            alb_day[:,:,daily] = fsm.asrf_out[:]
            Tsrf_day[:,:,daily] = fsm.Tsrf[:]
            Sice_day[:,:,daily] = dropdims(sum(fsm.Sice,dims=1), dims=1)[:]
            Sliq_day[:,:,daily] = dropdims(sum(fsm.Sliq,dims=1), dims=1)[:]

            daily += 1
            
        else 
            # store outputs (unchanged from your code)
            hs[:,:,d] = dropdims(mean(hs_day, dims=3), dims=3) # Really take mean ? (hs at the end of the day ?)
            
            Tsnow1[:,:,d] = dropdims(mean(Tsnow1_day, dims=3), dims=3)
            Tsnow2[:,:,d] = dropdims(mean(Tsnow2_day, dims=3), dims=3)
            Tsnow3[:,:,d] = dropdims(mean(Tsnow3_day, dims=3), dims=3)

            alb[:,:,d] = dropdims(mean(alb_day, dims=3), dims=3)
            Tsrf[:,:,d] = dropdims(mean(Tsrf_day, dims=3), dims=3)
            Sice[:,:,d] = dropdims(mean(Sice_day, dims=3), dims=3)
            Sliq[:,:,d] = dropdims(mean(Sliq_day, dims=3), dims=3)
            
            # snowdepthmin[i,:] = fsm.snowdepthmin[:]
            # snowdepthmax[i,:] = fsm.snowdepthmax[:]
            # swemin[i,:]       = fsm.swemin[:]
            # swemax[i,:]       = fsm.swemax[:]
            
            d+=1
            daily = 1
        end

    end

    # alb_snow = copy(alb) 
    # alb_snow[alb .< 0.6] .= NaN

    # write results to dataframe
    time = df_meteo["time"]

    return time, hs, Tsnow1, Tsnow2, Tsnow3, Tsrf, alb, Sice, Sliq 

end
#####################################################################################
# station = "GALIBIER-NIVOSE" # "GALIBIER-NIVOSE", "VILLAR D'ARENE"

print("setup")
fsm, met, df_meteo = setup_example() 

print("fsm")
time_res = 24
time, hs, Tsnow1, Tsnow2, Tsnow3, Ts, albedo, I, W = run_fsm(fsm, met, df_meteo, time_res)

#*********************************************************
pass = "C:/Users/navarrel/Documents/Workspace/Data/outputs/argentiere/output_argentiere_100m_2023-2024_daily.nc"

#*********************************************************
# open("C:/Users/elise/Documents/These/Workspace/Data/outputs/README.md", "a") do f
#     println(f, "**$(pass)**")
#     println(f, "- input = C:/Users/elise/Documents/These/Workspace/Data/S2M/postes/meteo/FORCING_alpes_1958080106_2024080106.nc")
#     println(f, "- SNFRAC = 0")
#     println(f, "")
# end

ds_results = NCDataset(pass,"c")

# Define the dimension "lon" and "lat" with the size 100 and 110 resp.
defDim(ds_results,"time",trunc(Int,size(time)[1]./time_res))
defDim(ds_results,"x",size(df_meteo["x"])[1])
defDim(ds_results,"y",size(df_meteo["y"])[1])

# Define the variables temperature
defVar(ds_results,"time",time[1:24:end][1:end-1],("time",))
defVar(ds_results,"x",df_meteo["x"],("x",))
defVar(ds_results,"y",df_meteo["y"],("y",))
defVar(ds_results,"hs",hs,("x","y","time"), attrib = OrderedDict("units" => "m"))
defVar(ds_results,"Tsnow1",Tsnow1,("x","y","time"), attrib = OrderedDict("units" => "K"))
defVar(ds_results,"Tsnow2",Tsnow2,("x","y","time"), attrib = OrderedDict("units" => "K"))
defVar(ds_results,"Tsnow3",Tsnow3,("x","y","time"), attrib = OrderedDict("units" => "K"))
defVar(ds_results,"Ts",Ts,("x","y","time"), attrib = OrderedDict("units" => "K"))
defVar(ds_results,"albedo",albedo,("x","y","time"))
defVar(ds_results,"I",I,("x","y","time"), attrib = OrderedDict("units" => "kg/m2"))
defVar(ds_results,"W",W,("x","y","time"), attrib = OrderedDict("units" => "kg/m2"))


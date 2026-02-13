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
# using IGEfsmtools

# /!\ Retirer wind_scaling
# /!\ SNFRAC = 3
# /!\ Dims mismatch

# initialization function 
    # sets parameters (topo, meteo), configuration, variables (format)
    # opens meteo file
function setup_example()

    # read meteo file
    df_meteo = Dataset("C:/Users/elise/Documents/These/Workspace/Data/S2M/postes/meteo/FORCING_alpes_2018080106_2024080106_trans.nc")
    station_shapefile = ArchGDAL.read("C:/Users/elise/Documents/These/Workspace/Data/S2M/shapefile/stations_reanalysis_S2M_alpes.shp")
    shapefile = ArchGDAL.getlayer(station_shapefile, 0) |> DataFrame  

    Nx = 434
    Ny = 1

    # set landuse properties
    lus = Dict()
    lus["skyvf"] = Dict("data" => [fill(1.0, size(shapefile)[1]);;])           
    lus["x"] = Dict("data" => [shapefile.Longitude;;])
    lus["y"] = Dict("data" => [shapefile.Latitude;;])
    lus["dem"] = Dict("data" => [shapefile.Elevation;;])
    lus["slopemu"] = Dict("data" => [fill(1.0, size(shapefile)[1]);;])
    lus["xi"] = Dict("data" => [fill(1.0, size(shapefile)[1]);;])
    lus["Ld"] = Dict("data" => [fill(1.0, size(shapefile)[1]);;])
    lus["prec_multi"] = Dict("data" => [fill(1.0, size(shapefile)[1]);;])
    
    # define custom settings
    settings = Dict("tile" => "open", "Nx" => Nx, "Ny" => Ny, "params" => Dict("wind_scaling" => 0.7, "dt" => 3600,
                                                                                         "zT" => 1.5,
                                                                                         "zU" => 5.0,
                                                                                        "zRH" => 1.5))
    
    # create fsm struct
    fsm = setup(Float32, Int32, lus, Nx, Ny, settings)
    
    # define meteo data struct
    met = MET{Float32,Int32}(Nx=Nx, Ny=Ny)
    
     return shapefile, fsm, met, df_meteo

end

#####################################################################################
function run_fsm(fsm, met, df_meteo)

    dims = (df_meteo.dim["Number_of_points"], df_meteo.dim["time"]) # (df_meteo.dim["time"],df_meteo.dim["Number_of_points"])

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

    # time loop
    for i in 1:N

        t_i = time[i]

        # assign met fields 
        met.year  .= year(t_i)
        met.month .= month(t_i)
        met.day   .= day(t_i)
        met.hour  .= hour(t_i)
        met.Sdir  .= DIR_SW[:,i]
        met.Sdif  .= SCA_SW[:,i]
        met.Sdird .= DIR_SW[:,i]
        met.LW    .= LWdown[:,i]
        met.Sf    .= Snowf[:,i] .* Int32(3600)
        met.Rf    .= Rainf[:,i] .* Int32(3600)
        met.Ta    .= Tair[:,i]
        met.RH    .= Qair[:,i]
        met.Ua    .= Wind[:,i]
        met.Ps    .= PSurf[:,i]
        met.Sf24h .= dropdims(sum(Snowf[:,max(1,i-23):i], dims=2), dims=2)

        # run model
        step!(fsm, met, t_i)

        # store outputs (unchanged from your code)
        hs[i,:] = dropdims(sum(fsm.Ds, dims=1), dims=1)[:]

        Tsnow1[i,:] = fsm.Tsnow[1,:,:]
        Tsnow2[i,:] = fsm.Tsnow[2,:,:]
        Tsnow3[i,:] = fsm.Tsnow[3,:,:]

        alb[i,:] = fsm.asrf_out[:]
        Tsrf[i,:] = fsm.Tsrf[:]
        Sice[i,:] = dropdims(sum(fsm.Sice,dims=1), dims=1)[:]
        Sliq[i,:] = dropdims(sum(fsm.Sliq,dims=1), dims=1)[:]
        
        # snowdepthmin[i,:] = fsm.snowdepthmin[:]
        # snowdepthmax[i,:] = fsm.snowdepthmax[:]
        # swemin[i,:]       = fsm.swemin[:]
        # swemax[i,:]       = fsm.swemax[:]

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
shapefile, fsm, met, df_meteo = setup_example() 

print("fsm")
time, hs, Tsnow1, Tsnow2, Tsnow3, Ts, albedo, I, W = run_fsm(fsm, met, df_meteo)

#*********************************************************
pass = "C:/Users/elise/Documents/These/Workspace/Data/outputs/output_2018-2024_S2M_stations2.nc"

#*********************************************************
# open("C:/Users/elise/Documents/These/Workspace/Data/outputs/README.md", "a") do f
#     println(f, "**$(pass)**")
#     println(f, "- input = C:/Users/elise/Documents/These/Workspace/Data/S2M/postes/meteo/FORCING_alpes_1958080106_2024080106.nc")
#     println(f, "- SNFRAC = 0")
#     println(f, "")
# end

ds_results = NCDataset(pass,"c")

# Define the dimension "lon" and "lat" with the size 100 and 110 resp.
defDim(ds_results,"time",size(time)[1])
defDim(ds_results,"Nb_stations",size(hs)[2])

# Define the variables temperature
defVar(ds_results,"time",time,("time",))
defVar(ds_results,"station",shapefile.Name,("Nb_stations",))
defVar(ds_results,"hs",hs,("time","Nb_stations"), attrib = OrderedDict("units" => "m"))
defVar(ds_results,"Tsnow1",Tsnow1,("time","Nb_stations"), attrib = OrderedDict("units" => "K"))
defVar(ds_results,"Tsnow2",Tsnow2,("time","Nb_stations"), attrib = OrderedDict("units" => "K"))
defVar(ds_results,"Tsnow3",Tsnow3,("time","Nb_stations"), attrib = OrderedDict("units" => "K"))
defVar(ds_results,"Ts",Ts,("time","Nb_stations"), attrib = OrderedDict("units" => "K"))
defVar(ds_results,"albedo",albedo,("time","Nb_stations"))
defVar(ds_results,"I",I,("time","Nb_stations"), attrib = OrderedDict("units" => "kg/m2"))
defVar(ds_results,"W",W,("time","Nb_stations"), attrib = OrderedDict("units" => "kg/m2"))


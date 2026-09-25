function read_meteo!(met::MET{Tf}, i::Int, settings::Dict) where {Tf<:Real}
  
  meteo_file = Dataset(settings["file_path"]) 
              
  DIR_SW    = meteo_file["DIR_SWdown"]           
  SCA_SW    = meteo_file["SCA_SWdown"]
  LWdown    = meteo_file["LWdown"]
  Snowf     = meteo_file["Snowf"]
  Rainf     = meteo_file["Rainf"]
  Tair      = meteo_file["Tair"]
  Qair      = meteo_file["Qair"]
  Wind      = meteo_file["Wind"]
  PSurf     = meteo_file["PSurf"]

  if ! (settings["Ny"] == 1)
    # assign met fields 
    met.Sdir  .= DIR_SW[:,:,i]
    met.Sdif  .= SCA_SW[:,:,i]
    met.Sdird .= DIR_SW[:,:,i]
    met.LW    .= LWdown[:,:,i]
    met.Sf    .= Snowf[:,:,i] 
    met.Rf    .= Rainf[:,:,i] 
    met.Ta    .= Tair[:,:,i]
    met.RH    .= Qair[:,:,i]
    met.Ua    .= Wind[:,:,i]
    met.Ps    .= PSurf[:,:,i]
    met.Sf24h .= dropdims(sum(Snowf[:,:,max(1,i-23):i] .*3600, dims=3), dims=3) 
  else
      if  ! (settings["list_id"] == "all") 
        # assign met fields 
        met.Sdir  .= DIR_SW[settings["mask"],i]
        met.Sdif  .= SCA_SW[settings["mask"],i]
        met.Sdird .= DIR_SW[settings["mask"],i]
        met.LW    .= LWdown[settings["mask"],i]
        met.Sf    .= Snowf[settings["mask"],i]
        met.Rf    .= Rainf[settings["mask"],i] 
        met.Ta    .= Tair[settings["mask"],i]
        met.RH    .= Qair[settings["mask"],i]
        met.Ua    .= Wind[settings["mask"],i]
        met.Ps    .= PSurf[settings["mask"],i]
        met.Sf24h .= dropdims(sum(Snowf[settings["mask"], max(1,i-23):i] .*3600, dims=2), dims=2) 
      else
        # assign met fields 
        met.Sdir  .= DIR_SW[:,i]
        met.Sdif  .= SCA_SW[:,i]
        met.Sdird .= DIR_SW[:,i]
        met.LW    .= LWdown[:,i]
        met.Sf    .= Snowf[:,i]
        met.Rf    .= Rainf[:,i] 
        met.Ta    .= Tair[:,i]
        met.RH    .= Qair[:,i]
        met.Ua    .= Wind[:,i]
        met.Ps    .= PSurf[:,i]
        met.Sf24h .= dropdims(sum(Snowf[:, max(1,i-23):i] .*3600, dims=2), dims=2) 
      end
  end

  close(meteo_file)

end

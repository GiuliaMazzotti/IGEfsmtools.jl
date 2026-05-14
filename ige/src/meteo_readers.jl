function read_meteo!(met::MET{Tf,Ti}, i::Int32, settings::Dict) where {Tf<:Real,Ti<:Integer}
  
  meteo_file = NCDataset(settings["file_path"]) # Dataset() ?

  time      = meteo_file["time"]                
  DIR_SW    = meteo_file["DIR_SWdown"]           
  SCA_SW    = meteo_file["SCA_SWdown"]
  LWdown    = meteo_file["LWdown"]
  Snowf     = meteo_file["Snowf"]
  Rainf     = meteo_file["Rainf"]
  Tair      = meteo_file["Tair"]
  Qair      = meteo_file["Qair"]
  Wind      = meteo_file["Wind"]
  PSurf     = meteo_file["PSurf"]

  close(meteo_file)

  t_i = time[i]

  if ! Ny == 1
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
  else
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
    met.Sf24h .= dropdims(sum(Snowf[:, max(1,i-23):i], dims=2), dims=2)
  end

end

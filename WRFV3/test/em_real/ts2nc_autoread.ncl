
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; NCL Libraries
;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

begin

    setfileoption("nc","Format","NetCDF4")  ; these are going to be big files
    setfileoption("nc","CompressionLevel",5)



    dir_for_wrf_output = "/projects/biomimicry/WRF_RUNS/Namibia/2016-03-05_00/ens01/"

    domainstring       = ".d03."

    wrf_full_model_file =  "wrfout_d03_2016-03-05_00:00:00"

    tke_on = False

    station_id =  (/ "FYGF" , "CRSV"/)


    f_wrf = addfile(dir_for_wrf_output + wrf_full_model_file + ".nc", "r")
         sigmas   = f_wrf->ZNU(0,:)
         wrf_elev = f_wrf->HGT(0,:,:)


    wrf_time =    wrf_times_c(f_wrf->Times, 0 )

    wrf_utc_date = cd_calendar(wrf_time(0), -5)



    ptop = (/ f_wrf->P_TOP(0) /) ; Pa.
    ptop@long_name = "Pressure at Top of Model Space"
    ptop@description = "Pressure at Top of Model Space"
    ptop@standard_name = "air_pressure"
    ptop@units     = "Pa"
    ptop!0         = "ptop"
    ptop&ptop      =  ptop


    nlevels = 15
    
    sigma               = (/ sigmas(0:nlevels-1) /)
    sigma!0             = "sigma"
    sigma&sigma         = sigma
    sigma@units         = ""
    sigma@long_name     = "Sigma Coordinate from WRF"
    sigma@description   = "Sigma Coordinate from WRF"
    sigma@standard_name = "atmosphere_sigma_coordinate"
    sigma@comment1      = "pressure(n,k) = ptop + sigma(k)*(psfc(n,k)-ptop)"
    sigma@formula_terms = "sigma: sigma ps: psfc ptop: ptop"
    sigma@positive      = "down"

    ; run date must be in this format "2015-02-08_12" "YYYY-MM-DD_HH"
    run_date = "2015-01-23_12"

    run_date = sprinti("%0.4i-", wrf_utc_date(0,0)) + \
               sprinti("%0.2i-", wrf_utc_date(0,1)) + \
               sprinti("%0.2i_", wrf_utc_date(0,2)) + \
               sprinti("%0.2i",  wrf_utc_date(0,3))


    datestring = sprinti("%0.4i-", wrf_utc_date(0,0)) + \
                 sprinti("%0.2i-", wrf_utc_date(0,1)) + \
                 sprinti("%0.2i",  wrf_utc_date(0,2))

    hourstring = sprinti("%0.2i",  wrf_utc_date(0,3))
  
    ; these match the time series file names




   ncol = 19


do ss = 0, dimsizes(station_id)-1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   filename = station_id(ss) +  domainstring  +"TS"

   data2 = asciiread(dir_for_wrf_output + filename, -1, "string" )
   headerstring = data2(0)


   ;000000000011111111112222222222333333333344444444445555555555666666666677777777778888888888999999999911111111112
   ;012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
   ;Grootfontein               3  4 FYGF  (-19.599,  18.116) ( 125, 126) (-19.600,  18.103) 1416.6 meters

   station_name2 = str_get_cols(headerstring, 0,26)
   station_name  = str_left_strip(str_right_strip(station_name2(0)))

   latitude_wrf     = stringtofloat(str_get_cols(headerstring, 70, 76))
   longitude_wrf    = stringtofloat(str_get_cols(headerstring, 78, 85))

   latitude_sta     = stringtofloat(str_get_cols(headerstring, 39, 45))
   longitude_sta    = stringtofloat(str_get_cols(headerstring, 47, 54))

   gettheparents = str_split(headerstring,")")
   elev   = stringtofloat(str_split(gettheparents(3)," meters"))

   data = readAsciiTable(dir_for_wrf_output + filename, ncol, "float", 1)


   time = data(:,1)
      time_min = round( time(0),0)
      print(time_min)
      time(:)            = (/ time - time_min /)
      time@long_name     = "Time"
      time@description   = "Time"
      time@standard_name = "time"
      time@units         = "hours since "+ datestring + " "+  hourstring + ":00:00"
      time!0             = "time"
      time&time          = time
   
   print("maxtime = "+max(time))


   domain = data(0,0)
     domain@long_name = "WRF Domain Nest"
     domain@description = "WRF Domain Nest"

   grid_x = data(0,3)
     grid_x@long_name = "WRF X Coordinate"
     grid_x@description = "WRF X Coordinate"

   grid_y = data(0,4)
     grid_y@long_name = "WRF Y Coordinate"
     grid_y@description = "WRF Y Coordinate"

   
   data!0 = "time"
   data&time = time
   data@lat = latitude_wrf
   data@lon = longitude_wrf
   data@lat_sta = latitude_sta
   data@lon_sta = longitude_sta
   data@elev = elev
   data@domain = domain
   data@grid_x = grid_x
   data@grid_y = grid_y
   

   temperature = data(:,5)
      temperature@long_name     = "2-m Air Temperature"
      temperature@description   = "2-m Air Temperature"
      temperature@standard_name = "air_temperature"
      temperature@units         = "K"

   q = data(:,6)
      q@long_name     = "2-m Vapor Mixing Ratio"
      q@description   = "2-m Vapor Mixing Ratio"
      q@standard_name = "specific_humidity"
      q@units         = "kg kg-1"

   w = q / (1-q)

   u = data(:,7)
      u@long_name     = "10-m Eastward Wind"
      u@description   = "10-m Eastward Wind"
      u@standard_name = "eastward_wind"
      u@units         = "m s-1"

   v = data(:,8)
      v@long_name     = "10-m Northward Wind"
      v@description   = "10-m Northward Wind"
      v@standard_name = "northward_wind"
      v@units         = "m s-1"

   psfc = data(:,9)
      psfc@long_name     = "Mean Sea Level Pressure"
      psfc@description   = "Mean Sea Level Pressure"
      psfc@standard_name = "air_pressure_at_sea_level"
      psfc@units         = "Pa"
   
   rh=temperature
   rh(:) = relhum(temperature, w, psfc)
      rh@long_name     = "2-m relative humidity"
      rh@description   = "2-m relative humidity"
      rh@standard_name = "relative_humidity"
      rh@units         = "%"

   rh = where(rh .lt. 0, 0, rh)
   rh = where(rh .gt.100,100,rh)
   rh!0 = "time"
   printVarSummary(rh)

   dewpoint=temperature
   dewpoint(:) = dewtemp_trh(temperature, rh)
   dewpoint@long_name     = "2-m Dewpoint Temp"
   dewpoint@description   = "2-m Dewpoint Temp"
   dewpoint@standard_name = "2-m dewpoint Temp"
   dewpoint@units = "K"
   dewpoint!0 = "time"
   printVarSummary(dewpoint)
   printVarSummary(temperature)

   glw = data(:,10)
      glw@long_name     = "Surface Downward Longwave Radiation"
      glw@description   = "Surface Downward Longwave Radiation"
      glw@standard_name = "surface_net_downward_longwave_flux"
      glw@units         = "W m-2"
   

   gsw = data(:,11)
      gsw@long_name     = "Surface Downward Shortwave Radiation"
      gsw@description   = "Surface Downward Shortwave Radiation"
      gsw@standard_name = "surface_net_downward_shortwave_flux"
      gsw@units         = "W m-2"
      
   hfx = data(:,12)
      hfx@long_name     = "Surface Sensible Heat Flux"
      hfx@description   = "Surface Sensible Heat Flux"
      hfx@standard_name = "surface_upward_sensible_heat_flux"
      hfx@units         = "W m-2"
   
   lfx = data(:,13)
      lfx@long_name     = "Surface Latent Heat Flux"
      lfx@description   = "Surface Latent Heat Flux"
      lfx@standard_name = "surface_upward_latent_heat_flux"
      lfx@units         = "W m-2"

   tsoil = data(:,14)
      tsoil@long_name     = "Surface Skin Temperature"
      tsoil@description   = "Surface Skin Temperature"
      tsoil@standard_name = "surface_temperature"
      tsoil@units         = "K"

   tslb = data(:,15)
      tslb@long_name     = "Topmost Soil Layer Temperature"
      tslb@description   = "Topmost Soil Layer Temperature"
      tslb@standard_name = "soil_temperature"
      tslb@comment1      = "depth from surface to 10 cm below surface for NOAH land model"
      tslb@units         = "K"

   rainc = data(:,16)
      rainc@long_name     = "Cumulus Cumulative Precipitation"
      rainc@description   = "Cumulus Cumulative Precipitation"
      rainc@standard_name = "convective_precipitation_amount"
      rainc@units         = "kg m-2"

    rainnc = data(:,17) 
      rainnc@long_name     = "Grid-Scale Cumulative Precipitation"
      rainnc@description   = "Grid-Scale Cumulative Precipitation"
      rainnc@standard_name = "stratiform_precipitation_amount"
      rainnc@units         = "kg m-2"

   clw = data(:,18)
      clw@long_name     = "Columnar Water Vapor"
      clw@description   = "Columnar Water Vapor"
      clw@standard_name = "atmosphere_mass_content_of_water_vapor"
      clw@units         = "kg m-2"
      

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  delete(data)

   filename = station_id(ss) + domainstring + "UU"
   print(filename)

   data = readAsciiTable(dir_for_wrf_output + filename, (1+nlevels), "float", 1)
      data!0       = "time"
      data&time    =  time
      data@lat     = latitude_wrf
      data@lon     = longitude_wrf
      data@lat_sta = latitude_sta
      data@lon_sta = longitude_sta
      data@elev    = elev
      data@domain  = domain
      data@grid_x  = grid_x
      data@grid_y  = grid_y

      
   u_profile = data(:,1:dimsizes(sigma))
      u_profile!1     = "sigma"
      u_profile&sigma = sigma

   u_profile@long_name     = "Eastward Wind Speed"
   u_profile@description   = "Eastward Wind Speed"
   u_profile@standard_name = "eastward_wind"
   u_profile@units     = "m s-1"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  delete(data)

   filename = station_id(ss) + domainstring + "VV"
   print(filename)

   data = readAsciiTable(dir_for_wrf_output + filename, (1+nlevels), "float", 1)
      data!0       = "time"
      data&time    =  time
      data@lat     = latitude_wrf
      data@lon     = longitude_wrf
      data@lat_sta = latitude_sta
      data@lon_sta = longitude_sta
      data@elev    = elev
      data@domain  = domain
      data@grid_x  = grid_x
      data@grid_y  = grid_y
      
   v_profile = data(:,1:dimsizes(sigma))
      v_profile!1     = "sigma"
      v_profile&sigma = sigma

   v_profile@long_name     = "Northward Wind Speed"
   v_profile@description   = "Northward Wind Speed"
   v_profile@standard_name = "northward_wind"
   v_profile@units         = "m s-1"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   wind_speed_profile = v_profile
   wind_speed_profile(:,:) = (/  v_profile*v_profile + u_profile*u_profile /)
   wind_speed_profile@long_name     = "Wind Speed"
   wind_speed_profile@description   = "Wind Speed"
   wind_speed_profile@standard_name = "wind_speed"
   wind_speed_profile@units         = "m s-1"

   wind_dir_profile = v_profile
   wind_dir_profile(:,:) = (/ atan2(-u_profile, -v_profile /)
   wind_dir_profile@long_name     = "Wind Direction"
   wind_dir_profile@description   = "Wind Direction"
   wind_dir_profile@standard_name = "wind_from_direction"
   wind_dir_profile@units         = "degree"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  delete(data)

   filename = station_id(ss) + domainstring + "TH"

   data = readAsciiTable(dir_for_wrf_output + filename, (1+nlevels), "float", 1)
      data!0       = "time"
      data&time    =  time
      data@lat     = latitude_wrf
      data@lon     = longitude_wrf
      data@lat_sta = latitude_sta
      data@lon_sta = longitude_sta
      data@elev    = elev
      data@domain  = domain
      data@grid_x  = grid_x
      data@grid_y  = grid_y

      
   potential_temperature_profile = data(:,1:dimsizes(sigma))
      potential_temperature_profile!1     = "sigma"
      potential_temperature_profile&sigma = sigma

   potential_temperature_profile@long_name     = "Potential Temperature"
   potential_temperature_profile@description   = "Potential Temperature"
   potential_temperature_profile@standard_name = "air_potential_temperature"
   potential_temperature_profile@units         = "K"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  delete(data)

   filename = station_id(ss) + domainstring + "QV"

   data = readAsciiTable(dir_for_wrf_output + filename, (1+nlevels), "float", 1)
      data!0       = "time"
      data&time    =  time
      data@lat     = latitude_wrf
      data@lon     = longitude_wrf
      data@lat_sta = latitude_sta
      data@lon_sta = longitude_sta
      data@elev    = elev
      data@domain  = domain
      data@grid_x  = grid_x
      data@grid_y  = grid_y
      
   specific_humidity_profile = data(:,1:dimsizes(sigma))
      specific_humidity_profile!1     = "sigma"
      specific_humidity_profile&sigma = sigma

   specific_humidity_profile@long_name     = "Specific Humidity"
   specific_humidity_profile@description   = "Specific Humidity"
   specific_humidity_profile@standard_name = "specific_humidity"
   specific_humidity_profile@units         = "kg kg-1"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  delete(data)

   filename = station_id(ss) + domainstring + "PH"

   data = readAsciiTable(dir_for_wrf_output + filename, (1+nlevels), "float", 1)
      data!0       = "time"
      data&time    =  time
      data@lat     = latitude_wrf
      data@lon     = longitude_wrf
      data@lat_sta = latitude_sta
      data@lon_sta = longitude_sta
      data@elev    = elev
      data@domain  = domain
      data@grid_x  = grid_x
      data@grid_y  = grid_y

   geopotential_height_profile = data(:,1:dimsizes(sigma))
      geopotential_height_profile!1     = "sigma"
      geopotential_height_profile&sigma = sigma

   geopotential_height_profile@long_name     = "Geopotential Height"
   geopotential_height_profile@description   = "Geopotential Height"
   geopotential_height_profile@standard_name = "geopotential_height"

   geopotential_height_profile@units       = "m"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
if (tke_on) then

  delete(data)

   filename = station_id(ss) + domainstring + "TE"

   data = readAsciiTable(dir_for_wrf_output + filename, (1+nlevels), "float", 1)
      data!0       = "time"
      data&time    =  time
      data@lat     = latitude_wrf
      data@lon     = longitude_wrf
      data@lat_sta = latitude_sta
      data@lon_sta = longitude_sta
      data@elev    = elev
      data@domain  = domain
      data@grid_x  = grid_x
      data@grid_y  = grid_y

   turbulent_kinetic_energy_profile = data(:,1:dimsizes(sigma))
      turbulent_kinetic_energy_profile!1     = "sigma"
      turbulent_kinetic_energy_profile&sigma = sigma

   turbulent_kinetic_energy_profile@long_name     = "Turbulent Kinetic Energy"
   turbulent_kinetic_energy_profile@description   = "Turbulent Kinetic Energy"
   turbulent_kinetic_energy_profile@standard_name = "specific_kinetic_energy_of_air_due_to_turbulence"
   turbulent_kinetic_energy_profile@units         = "m2 s-2"

end if

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
          
    wrf_file= "wrfout_d" + sprinti("%0.2i", tointeger(domain)) + "_" + \
              datestring + "_" + hourstring + "_" + station_id(ss) + ".nc"

    system("rm -frv "+dir_for_wrf_output + wrf_file)
    nc              = addfile(dir_for_wrf_output + wrf_file, "c")
      nc@station_id   = station_id(ss)
      nc@station_name = station_name
      nc@lat     = latitude_wrf
      nc@lon     = longitude_wrf
      nc@lat_sta = latitude_sta
      nc@lon_sta = longitude_sta
      nc@elev    = elev

      nc@domain       = domain
    
    nc->time        = time
    nc->sigma       = sigma
    nc->temperature = temperature
    nc->rh          = rh
    nc->dewpoint    = dewpoint
    nc->q           = q
    nc->u           = u
    nc->v           = v
    nc->psfc        = psfc
    nc->glw         = glw
    nc->gsw         = gsw
    nc->hfx         = hfx
    nc->lfx         = lfx
    nc->tsoil       = tsoil
    nc->tslb        = tslb
    nc->rainc       = rainc
    nc->rainnc      = rainnc
    nc->clw         = clw
    nc->ptop        = ptop
    
    nc->u_wind_profile                           = u_profile
    nc->v_wind_profile                      = v_profile
    nc->wind_speed_profile                  = wind_speed_profile
    nc->wind_direction_profile              = wind_dir_profile
    nc->potential_temperature_profile       = potential_temperature_profile
    nc->specific_humidity_profile           = specific_humidity_profile
    nc->geopotential_height_profile         = geopotential_height_profile
    if (tke_on) then
       nc->turbulent_kinetic_energy_profile = turbulent_kinetic_energy_profile
    end if


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
printVarSummary(time)

delete(data)
end do

end

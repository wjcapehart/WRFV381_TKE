
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; NCL Libraries
;
; $NCARG_ROOT is /usr on gamow
;
load "/usr/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "/usr/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "/usr/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
load "/usr/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "/usr/lib/ncarg/nclscripts/csm/contributed.ncl"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

begin

    setfileoption("nc","Format","NetCDF4")  ; these are going to be big files
    setfileoption("nc","CompressionLevel",5)

    dir_local            = "/home/wcapehart/WRFV381_TKE/"
    wrf_home_dir         = "/home/wcapehart/WRFV381_TKE/"
    wrf_version          = "WRFV381"
    wrf_program_root_dir = wrf_home_dir + wrf_version+"/"

    dir_for_wrf_output = wrf_program_root_dir+"WRFV3/test/em_real/"

    run_date = systemfunc("cat " + dir_local + "current_day.txt")

    domainstring       = ".d01."

    wrf_full_model_file =  "nam02_d01_"+run_date+"_F00.nc"

    print(wrf_full_model_file)

    tke_on   = True
    soils_on = True

    station_id =  (/ "CRSV", \
                     "FYGB", \
                     "FYGF", \
                     "FYOO", \
                     "FYOW", \
                     "FYWH", \
                     "FYWB", \
                     "FYRU"  /)


    f_wrf = addfile(dir_for_wrf_output + wrf_full_model_file + ".nc", "r")

    sigmas      = f_wrf->ZNU(0,:)

    wrf_elev    = f_wrf->HGT(0,:,:)

    soil_levels = f_wrf->ZS(0,:)
       delete(soil_levels@stagger)
       delete(soil_levels@FieldType)
       delete(soil_levels@MemoryOrder)
       soil_levels!0             = "soil_levels"
       soil_levels&soil_levels   = soil_levels
       soil_levels@positive      = "down"
       soil_levels@standard_name = "depth"
       soil_levels@long_name     = "Depths of Center of the Soil Layers"
       soil_levels@description   = "Depths of Center of the Soil Layers"
       soil_levels@units         = "m"


    wrf_time     = wrf_times_c(f_wrf->Times, 0 )

    wrf_utc_date = cd_calendar(wrf_time(0), -5)



    ptop = (/ f_wrf->P_TOP(0) /) ; Pa.
    ptop@long_name     = "Pressure at Top of Model Space"
    ptop@description   = "Pressure at Top of Model Space"
    ptop@standard_name = "air_pressure"
    ptop@units         = "Pa"
    ptop!0             = "ptop"
    ptop&ptop          =  ptop


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

   station_name!0           = "ncl_scalar"
   station_name@long_name   = "station name"
   station_name@description = "station name"
   station_name@cf_role     = "timeseries_id"

   latitude_wrf     = stringtofloat(str_get_cols(headerstring, 70, 76))
   longitude_wrf    = stringtofloat(str_get_cols(headerstring, 78, 85))

   latitude_wrf!0 = "ncl_scalar"
   longitude_wrf!0 = "ncl_scalar"

   latitude_wrf@long_name     = "latitude"
   latitude_wrf@description   = "latitude"
   latitude_wrf@standard_name = "latitude"
   latitude_wrf@comment       = "relative to wrf grid"
   latitude_wrf@units         = "degrees_north"
   latitude_wrf@axis          = "Y"

   longitude_wrf@long_name     = "longitude"
   longitude_wrf@description   = "longitude"
   longitude_wrf@standard_name = "longitude"
   latitude_wrf@comment        = "relative to wrf grid"
   longitude_wrf@units         = "degrees_east"
   longitude_wrf@axis          = "X"


   latitude_sta     = stringtofloat(str_get_cols(headerstring, 39, 45))
   longitude_sta    = stringtofloat(str_get_cols(headerstring, 47, 54))


   latitude_sta!0 = "ncl_scalar"
   longitude_sta!0 = "ncl_scalar"

   gettheparents = str_split(headerstring,")")
   elev   = stringtofloat(str_split(gettheparents(3)," meters"))

   elev!0 = "ncl_scalar"
   elev@description   = "surface elevation"
   elev@long_name     = "surface elevation"
   elev@standard_name = "height"
   elev@comment        = "relative to wrf grid"
   elev@units         = "m"
   elev@positive      = "up"
   elev@axis          = "Z"
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
      temperature@coordinates   = "time lat lon alt" ;

   q = data(:,6)
      q@long_name     = "2-m Vapor Mixing Ratio"
      q@description   = "2-m Vapor Mixing Ratio"
      q@standard_name = "specific_humidity"
      q@units         = "kg kg-1"
      q@coordinates   = "time lat lon alt" ;

   w = q / (1-q)

   u = data(:,7)
      u@long_name     = "10-m Eastward Wind"
      u@description   = "10-m Eastward Wind"
      u@standard_name = "eastward_wind"
      u@units         = "m s-1"
      u@coordinates   = "time lat lon alt" ;

   v = data(:,8)
      v@long_name     = "10-m Northward Wind"
      v@description   = "10-m Northward Wind"
      v@standard_name = "northward_wind"
      v@units         = "m s-1"
      v@coordinates   = "time lat lon alt" ;

   psfc = data(:,9)
      psfc@long_name     = "Mean Sea Level Pressure"
      psfc@description   = "Mean Sea Level Pressure"
      psfc@standard_name = "air_pressure_at_sea_level"
      psfc@units         = "Pa"
      psfc@coordinates   = "time lat lon alt" ;

   rh=temperature
   rh(:) = relhum(temperature, w, psfc)
      rh@long_name     = "2-m relative humidity"
      rh@description   = "2-m relative humidity"
      rh@standard_name = "relative_humidity"
      rh@units         = "%"
      rh@coordinates   = "time lat lon alt" ;

   rh = where(rh .lt. 0, 0, rh)
   rh = where(rh .gt.100,100,rh)
   rh!0 = "time"
   printVarSummary(rh)

   dewpoint=temperature
   dewpoint(:) = dewtemp_trh(temperature, rh)
   dewpoint@long_name     = "2-m Dewpoint Temp"
   dewpoint@description   = "2-m Dewpoint Temp"
   dewpoint@standard_name = "dew_point_temperature"
   dewpoint@units = "K"
   dewpoint!0 = "time"
   dewpoint@coordinates   = "time lat lon alt" ;
   printVarSummary(dewpoint)
   printVarSummary(temperature)

   glw = data(:,10)
      glw@long_name     = "Surface Downward Longwave Radiation"
      glw@description   = "Surface Downward Longwave Radiation"
      glw@standard_name = "surface_net_downward_longwave_flux"
      glw@units         = "W m-2"
      glw@coordinates   = "time lat lon alt" ;


   gsw = data(:,11)
      gsw@long_name     = "Surface Downward Shortwave Radiation"
      gsw@description   = "Surface Downward Shortwave Radiation"
      gsw@standard_name = "surface_net_downward_shortwave_flux"
      gsw@units         = "W m-2"
      gsw@coordinates   = "time lat lon alt" ;

   hfx = data(:,12)
      hfx@long_name     = "Surface Sensible Heat Flux"
      hfx@description   = "Surface Sensible Heat Flux"
      hfx@standard_name = "surface_upward_sensible_heat_flux"
      hfx@units         = "W m-2"
      hfx@coordinates   = "time lat lon alt" ;

   lfx = data(:,13)
      lfx@long_name     = "Surface Latent Heat Flux"
      lfx@description   = "Surface Latent Heat Flux"
      lfx@standard_name = "surface_upward_latent_heat_flux"
      lfx@units         = "W m-2"
      lfx@coordinates   = "time lat lon alt" ;

   tskin = data(:,14)
      tskin@long_name     = "Surface Skin Temperature"
      tskin@description   = "Surface Skin Temperature"
      tskin@standard_name = "surface_temperature"
      tskin@units         = "K"
      tskin@coordinates   = "time lat lon alt" ;

   tsoil_top = data(:,15)
      tsoil_top@long_name     = "Topmost Soil Layer Temperature"
      tsoil_top@description   = "Topmost Soil Layer Temperature"
      tsoil_top@standard_name = "soil_temperature"
      tsoil_top@comment1      = "depth from surface to 10 cm below surface for NOAH land model"
      tsoil_top@units         = "K"
      tsoil_top@coordinates   = "time lat lon alt" ;

   rainc = data(:,16)
      rainc@long_name     = "Cumulus Cumulative Precipitation"
      rainc@description   = "Cumulus Cumulative Precipitation"
      rainc@standard_name = "convective_precipitation_amount"
      rainc@units         = "kg m-2"
      rainc@coordinates   = "time lat lon alt" ;

    rainnc = data(:,17)
      rainnc@long_name     = "Grid-Scale Cumulative Precipitation"
      rainnc@description   = "Grid-Scale Cumulative Precipitation"
      rainnc@standard_name = "stratiform_precipitation_amount"
      rainnc@units         = "kg m-2"
      rainnc@coordinates   = "time lat lon alt" ;

   clw = data(:,18)
      clw@long_name     = "Columnar Water Vapor"
      clw@description   = "Columnar Water Vapor"
      clw@standard_name = "atmosphere_mass_content_of_water_vapor"
      clw@units         = "kg m-2"
      clw@coordinates   = "time lat lon alt" ;


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
      data@coordinates   = "time sigma lat lon" ;


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
      data@coordinates   = "time sigma lat lon" ;

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
   wind_dir_profile(:,:) = (/ atan2(-u_profile, -v_profile) /)
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
      data@alt      = elev
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
      data@coordinates   = "time sigma lat lon" ;

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
      data@coordinates   = "time sigma lat lon" ;

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
      data@coordinates   = "time sigma lat lon" ;

   turbulent_kinetic_energy_profile = data(:,1:dimsizes(sigma))
      turbulent_kinetic_energy_profile!1     = "sigma"
      turbulent_kinetic_energy_profile&sigma = sigma

   turbulent_kinetic_energy_profile@long_name     = "Turbulent Kinetic Energy"
   turbulent_kinetic_energy_profile@description   = "Turbulent Kinetic Energy"
   turbulent_kinetic_energy_profile@standard_name = "specific_kinetic_energy_of_air_due_to_turbulence"
   turbulent_kinetic_energy_profile@units         = "m2 s-2"

end if

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
if (soils_on) then

   delete(data)

   filename = station_id(ss) + domainstring + "SM"

   data = readAsciiTable(dir_for_wrf_output + filename, (1+dimsizes(soil_levels)), "float", 1)
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
      data@coordinates   = "time soil_levels lat lon" ;

   soil_moisture_profile = data(:,1:dimsizes(soil_levels))
      soil_moisture_profile!1           = "soil_levels"
      soil_moisture_profile&soil_levels = soil_levels

   soil_moisture_profile@long_name     = "Soil Water Content"
   soil_moisture_profile@description   = "Soil Water Content"
   soil_moisture_profile@standard_name = "liquid_water_content_of_soil_layer"
   soil_moisture_profile@units         = "kg m-2"

   soil_levels_2d = conform(soil_moisture_profile,soil_levels,1)

   soil_moisture_profile(:,:) = (/ soil_moisture_profile * soil_levels_2d /)

      delete(data)

      filename = station_id(ss) + domainstring + "ST"

      data = readAsciiTable(dir_for_wrf_output + filename, (1+dimsizes(soil_levels)), "float", 1)
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
         data@coordinates   = "time soil_levels lat lon" ;

      soil_temperature_profile = data(:,1:dimsizes(soil_levels))
         soil_temperature_profile!1           = "soil_levels"
         soil_temperature_profile&soil_levels = soil_levels

      soil_temperature_profile@long_name     = "Soil Temperature"
      soil_temperature_profile@description   = "Soil Temperature"
      soil_temperature_profile@standard_name = "soil_temperature"
      soil_temperature_profile@units         = "K"



end if

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


    wrf_file= "wrfout_d" + sprinti("%0.2i", tointeger(domain)) + "_" + \
              datestring + "_" + hourstring + "_" + station_id(ss) + ".nc"

    system("rm -frv "+dir_for_wrf_output + wrf_file)
    nc                = addfile(dir_for_wrf_output + wrf_file, "c")
      nc@station_id   = station_id(ss)
      nc@station_name = station_name
      nc@featureType  = "timeSeries"
      nc@Conventions  = "CF-1.6"
      nc@lat          = latitude_wrf
      nc@lon          = longitude_wrf
      nc@lat_sta      = latitude_sta
      nc@lon_sta      = longitude_sta
      nc@elev         = elev
      nc@domain       = domain
      delete(time@_FillValue)

      nc->time         = time
      nc->sigma        = sigma
      nc->soil_levels  = soil_levels
      nc->lat          = latitude_wrf
      nc->lon          = longitude_wrf
      nc->alt          = elev
      nc->station_name = station_name
      nc->temperature  = temperature
      nc->rh           = rh
      nc->dewpoint     = dewpoint
      nc->q            = q
      nc->u            = u
      nc->v            = v
      nc->psfc         = psfc
      nc->glw          = glw
      nc->gsw          = gsw
      nc->hfx          = hfx
      nc->lfx          = lfx
      nc->tskin        = tskin
      nc->tsoil_top    = tsoil_top
      nc->rainc        = rainc
      nc->rainnc       = rainnc
      nc->clw          = clw
      nc->ptop         = ptop

      nc->u_wind_profile                      = u_profile
      nc->v_wind_profile                      = v_profile
      nc->wind_speed_profile                  = wind_speed_profile
      nc->wind_direction_profile              = wind_dir_profile
      nc->potential_temperature_profile       = potential_temperature_profile
      nc->specific_humidity_profile           = specific_humidity_profile
      nc->geopotential_height_profile         = geopotential_height_profile

      if (tke_on) then
         nc->turbulent_kinetic_energy_profile = turbulent_kinetic_energy_profile
      end if

      if (soils_on) then
         nc->soil_temperature_profile = soil_temperature_profile
         nc->soil_moisture_profile    = soil_moisture_profile
      end if


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   printVarSummary(time)

   delete(data)
end do

end

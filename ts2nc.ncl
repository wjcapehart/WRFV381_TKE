
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

   setfileoption("nc","Format","NetCDF4")
      setfileoption("nc","CompressionLevel",5)


    dir_local = "/home/wjc/WRF_REALTIME_KUNR-3DOM/"
    dir = "/home/wjc/WRF_REALTIME_KUNR-3DOM/WRFV370/WRFV3/test/em_real/"



   sigmas = (/ 0.9965, 0.988, 0.9765, 0.962, 0.944, 0.9215, 0.8945, \
               0.8603331, 0.8209995,  0.7816658, 0.7423322, 0.6876204, \
               0.6201558, 0.5577776, 0.5001665, 0.4470201, 0.3980518, \
               0.3529909, 0.3115811, 0.2735802, 0.2387594, 0.2069024, \
               0.1778054, 0.1512759, 0.1271323, 0.1054426, 0.08629245, \
               0.06946228, 0.05467104, 0.0416717, 0.03024719, \
               0.02020672, 0.01138261, 0.003627522 /)


    nlevels = 15

    sigma       = sigmas(0:nlevels-1)
    sigma!0     = "sigma"
    sigma&sigma = sigma

  ; print("cat " + dir_local + "current_day.txt")
      run_date = systemfunc("cat " + dir_local + "current_day.txt")
   print(run_date)



    splitted_date = str_split(run_date, "_")

    datestring = splitted_date(0)
    hourstring = splitted_date(1)


        station_id =  (/ "CRSV", \
                         "FYGB", \
                         "FYGF", \
                         "FYOO", \
                         "FYOW", \
                         "FYWH", \
                         "FYWB", \
                         "FYRU"  /)

 station_name = (/ "Rapid City, SD", "Gillette, WY", "Custer, SD" /)


 lat =  (/ 44.0453333, 44.3489167, 43.7336542  /)
    lat@long_name = "latitude"
    lat@units = "degrees north"
 lon = (/ -103.0573611, -105.5393611, -103.6194403 /)
    lon@long_name = "longitude"
    lon@units = "degrees east"

  elev = (/ 940.8 , 1330.1, 1707.  /)
    elev@long_name = "terrain elevation"
    elev@units = "m"


   ncol = 19


do ss = 0, dimsizes(station_id)-1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   filename = station_id(ss) + ".d02.TS"

   data = readAsciiTable(dir + filename, ncol, "float", 1)

   time = data(:,1)
   time_min = round( time(0),0)
   print(time_min)
   time(:) = (/ time - time_min /)
   time@long_name = "time"
   time@units = "hours since "+ datestring + " "+  hourstring + ":00:00"
   time!0    = "time"
   time&time = time

   print("maxtime = "+max(time))


   domain = data(0,0)
     domain@long_name = "WRF Domain Nest"

   grid_x = data(0,3)
     grid_x@long_name = "WRF X Coordinate"

   grid_y = data(0,4)
     grid_y@long_name = "WRF Y Coordinate"


   data!0 = "time"
  ; data&time = time
   data@lat = lat(ss)
   data@lon = lon(ss)
   data@elev = elev(ss)
   data@domain = domain
   data@grid_x = grid_x
   data@grid_y = grid_y


   temperature = data(:,5)
      temperature@long_name = "2-m Air Temperature"
      temperature@units     = "K"

   q = data(:,6)
      q@long_name = "2-m vapor mixing ratio"
      q@units     = "kg kg-1"

   w = q / (1-q)

   u = data(:,7)
      u@long_name = "eastward wind"
      u@units     = "m s-1"

   v = data(:,8)
      v@long_name = "nortward wind"
      v@units     = "m s-1"

   psfc = data(:,9)
      psfc@long_name = "mean sea level pressure"
      psfc@units     = "Pa"

   rh=temperature
   rh(:) = relhum(temperature, w, psfc)
      rh@long_name = "2-m relative humidity"
      rh@units = "%"

   rh = where(rh .lt. 0, 0, rh)
   rh = where(rh .gt.100,100,rh)
   rh!0 = "time"
   printVarSummary(rh)

   dewpoint=temperature
   dewpoint(:) = dewtemp_trh(temperature, rh)
      dewpoint@long_name = "2-m dewpoint Temp"
      dewpoint@units = "K"
   dewpoint!0 = "time"
   printVarSummary(dewpoint)
  printVarSummary(temperature)

   glw = data(:,10)
      glw@long_name = "Downward Longwave Radiation"
      glw@units     = "W m-2"


   gsw = data(:,11)
      gsw@long_name = "Downward Shortwave Radiation"
      gsw@units     = "W m-2"

   hfx = data(:,12)
      hfx@long_name = "Sensible Heat Flux"
      hfx@units     = "W m-2"

   lfx = data(:,13)
      lfx@long_name = "Latent Heat Flux"
      lfx@units     = "W m-2"

   tsoil = data(:,14)
      tsoil@long_name = "Sfc Skin Temperature"
      tsoil@units     = "K"

   tslb = data(:,15)
      tslb@long_name = "Deep Soil Reservoir"
      tslb@units     = "K"

   rainc = data(:,16)
      rainc@long_name = "Cumulus Cumulative Precipitation "
      rainc@units     = "kg m-2"

    rainnc = data(:,17)
      rainnc@long_name = "Grid-Scale Cumulative Precipitation "
      rainnc@units     = "kg m-2"

   clw = data(:,18)
      clw@long_name = "Columnar Water"
      clw@units     = "kg m-2"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  delete(data)

   filename = station_id(ss) + ".d02.UU"

   data = readAsciiTable(dir + filename, (1+nlevels), "float", 1)
      data!0 = "time"
      data&time = time
      data@lat = lat(ss)
      data@lon = lon(ss)
      data@elev = elev(ss)
      data@domain = domain
      data@grid_x = grid_x
      data@grid_y = grid_y

   u_profile = data(:,1:dimsizes(sigma))
      u_profile!1     = "sigma"
     ; u_profile&sigma = sigma

   u_profile@long_name = "U-wind"
   u_profile@units       = "m s-1"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  delete(data)

   filename = station_id(ss) + ".d02.VV"

   data = readAsciiTable(dir + filename, (1+nlevels), "float", 1)
      data!0 = "time"
      data&time = time
      data@lat = lat(ss)
      data@lon = lon(ss)
      data@elev = elev(ss)
      data@domain = domain
      data@grid_x = grid_x
      data@grid_y = grid_y

   v_profile = data(:,1:dimsizes(sigma))
      v_profile!1     = "sigma"
     ; v_profile&sigma = sigma

   v_profile@long_name = "V-wind"
   v_profile@units       = "m s-1"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  delete(data)

   filename = station_id(ss) + ".d02.TH"

   data = readAsciiTable(dir + filename, (1+nlevels), "float", 1)
      data!0 = "time"
      data&time = time
      data@lat = lat(ss)
      data@lon = lon(ss)
      data@elev = elev(ss)
      data@domain = domain
      data@grid_x = grid_x
      data@grid_y = grid_y

   potential_temperature_profile = data(:,1:dimsizes(sigma))
      potential_temperature_profile!1     = "sigma"
     ; potential_temperature_profile&sigma = sigma

   potential_temperature_profile@long_name = "Potential Temperature"
   potential_temperature_profile@units       = "K"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  delete(data)

   filename = station_id(ss) + ".d02.QV"

   data = readAsciiTable(dir + filename, (1+nlevels), "float", 1)
      data!0 = "time"
      data&time = time
      data@lat = lat(ss)
      data@lon = lon(ss)
      data@elev = elev(ss)
      data@domain = domain
      data@grid_x = grid_x
      data@grid_y = grid_y

   specific_humidity_profile = data(:,1:dimsizes(sigma))
      specific_humidity_profile!1     = "sigma"
    ;  specific_humidity_profile&sigma = sigma

   specific_humidity_profile@long_name = "Specific Humidity"
   specific_humidity_profile@units       = "kg kg-1"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  delete(data)

   filename = station_id(ss) + ".d02.PH"

   data = readAsciiTable(dir + filename, (1+nlevels), "float", 1)
      data!0 = "time"
      data&time = time
      data@lat = lat(ss)
      data@lon = lon(ss)
      data@elev = elev(ss)
      data@domain = domain
      data@grid_x = grid_x
      data@grid_y = grid_y

   geopotential_height_profile = data(:,1:dimsizes(sigma))
      geopotential_height_profile!1     = "sigma"
   ;   geopotential_height_profile&sigma = sigma

   geopotential_height_profile@long_name = "Geopotential Height"
   geopotential_height_profile@units       = "m"


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    wrf_file= "wrfout_d" + sprinti("%0.2i", tointeger(domain)) + "_" + \
              datestring + "_" + hourstring + "_" + station_id(ss) + ".nc"

    system("rm -frv "+dir + wrf_file)
    nc = addfile(dir + wrf_file, "c")
    nc@station_id = station_id(ss)
    nc@station_name = station_name(ss)
    nc@lon    = lon(ss)
    nc@lat    = lat(ss)
    nc@elev   = elev(ss)
    nc@domain = domain

    nc->time = time
    nc->sigma = sigma
    nc->temperature = temperature
    nc->rh = rh
    nc->dewpoint = dewpoint
    nc->q = q
    nc->u = u
    nc->v = v
    nc->psfc = psfc
    nc->glw = glw
    nc->gsw = gsw
    nc->hfx = hfx
    nc->lfx = lfx
    nc->tsoil = tsoil
    nc->tslb = tslb
    nc->rainc = rainc
    nc->rainnc = rainnc
    nc->clw = clw

    nc->u_profile = u_profile
    nc->v_profile = v_profile
    nc->potential_temperature_profile = potential_temperature_profile
    nc->specific_humidity_profile = specific_humidity_profile
     nc->geopotential_height_profile = geopotential_height_profile


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
printVarSummary(time)

delete(data)
end do

end

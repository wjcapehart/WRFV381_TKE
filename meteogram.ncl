;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; NCL Libraries
;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"

;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

begin

  dir_local        = "/home/wjc/WRF_REALTIME/"
;  dir_local        = "/Users/wjc/Desktop/WRF_REALTIME/newplots/"
 
  system("rm -fr "+dir_local + "METAR_*nc*")

  dir_wrf = "/cyclone1/WRF_REALTIME/OUTPUT/"
  wrf_dir  =  "WRF36_KUNR_3DOM_WSM6_NOAH_MYNN2_KF2_DUDHIA_NAM218-09km_150x150/"
  metar_dir = "/data/NCAR/UNIDATA_LITTLE_R/"
  stationid = "KRAP"
  station_nice_name =  "Rapid City Airport" 
  dir_url = "wjc@kyrill:/var/www/html/firemet/wrf_rap/"  



  utcoffset = -6
  utclabel = "MDT"

;  utcoffset = -7
;  utclabel = "MST"

    
 ; utcoffset = 0
 ; utclabel = "UTC"
    
    
  run_date = systemfunc("cat " + dir_local + "current_day_meteogram.txt")
  print(run_date)
domain = "d02"
dir_png = "/projects/WRF_REALTIME/OUTPUT_PNG/"
full_png_dir  = "/projects/WRF_REALTIME/OUTPUT_PNG/"+run_date+"/"+domain

  wrf3Dfiles = dir_wrf + wrf_dir+ "wrfout_d02_" + run_date + "_F"
  
  wrftsfile = dir_wrf + wrf_dir+ "wrfout_d02_" + run_date + "_" + stationid + ".nc"
  
  wrfplotfile = "./wrfout_d02_" + run_date + "_" + stationid 
  
  ; system("ncdump -h  " + wrftsfile)
  
  ts  = addfile( wrftsfile, "r")
   

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  print(ts)
   time = ts->time
   tk   = ts->temperature
   time(:) = time + utcoffset
   

   
  
   delta_t = time(1)-time(0)
   delta_t@units = "hour"
   delta_t@long_name = "time_interval"
   
   
   
   tsperhour = tointeger(1/delta_t)
   
   
   
   
                      
                      
                      
  
  
  
   timehourly = ispan(tointeger(min(time)), tointeger(max(time)), 1)
   timehourly@units = time@units
   timehourly@long_name = "time"
  
   temperature = tk
   temperature(:) = (tk - 273.17) * 1.8 + 32
     temperature@long_name = "2-m Air Temperature"
     temperature@units = "deg F"
     temperature&time = time
    

   rainnc_in = ts->rainnc
   rainc_in  = ts->rainc
 
   cprecip = ts->rainnc
printVarSummary(cprecip)
   cprecip(:) = (/ rainnc_in  +   rainc_in  /) * 0.0393701
 printVarSummary(cprecip) 
  cprecip@units = "in"
   cprecip@long_name = "Cumulative Precipitation (in)"
     cprecip&time = time
     
     ;;;;;;
   tdk  = ts->dewpoint   
   tdc = tdk
   tdc(:) = (tdk - 273.17) * 1.8 + 32
   tdc@units = "deg F" 

glw = ts->glw
gsw = ts->gsw
hfx = ts->hfx
lfx = ts->lfx     
     
     ;;;;;;;
   
   precip = cprecip
   precip(:) = 0
   precip(0) = cprecip(0)
   precip(1:dimsizes(time)-1) = cprecip(1:dimsizes(time)-1)-cprecip(0:dimsizes(time)-2)
   precip@long_name = "Precip per Time Step"
   
   precip_hourly = new(dimsizes(timehourly), float)
   precip_hourly!0 = "timehourly"
   precip_hourly&timehourly = timehourly
   precip_hourly@long_name = "Hourly Precipitation"
   precip_hourly@units     = "mm"

   t = 0
   
   lastindex = -1
   nowindex = lastindex + tsperhour
   print(" T = "+t + " "+  lastindex+ ":" + nowindex + "  "+ (-1) +":"+time(nowindex))
   precip_hourly(t) = (/ cprecip(tsperhour-1) /)
   lastindex = nowindex
   
   do t = 1, dimsizes(timehourly) - 2
      nowindex = lastindex + tsperhour
   print(" T = "+t + " "+  lastindex+ ":" + nowindex + "  "+time(lastindex) +":"+time(nowindex))
      precip_hourly(t) = (/ cprecip(nowindex) - cprecip(lastindex)  /)
      lastindex = nowindex 
   end do
   
   print("SUM PREC | Sumhourly=" + sum(precip_hourly) + " sum_raw=" + sum(precip) + " true=" + max(cprecip) + "|"+  (max(cprecip)-sum(precip_hourly) )  )
   
   lon  = ts@lon
   lat  = ts@lat
   elev = ts@elev
   
   
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


 
   timestr = sprinti("%0.2i",ispan(0,max(tointeger(time-utcoffset)),1))


   wrf_full_filenames = wrf3Dfiles+timestr+".nc"

   ;   f3d = addfiles(wrf_full_filenames, "r") 

    Times_from_WRF = new((/ dimsizes(timestr), 19 /), character)
    print("reading time")
    do fxhour = 0, dimsizes(timestr)-1
          f3d_onefile = addfile(wrf_full_filenames(fxhour), "r") 
          Times_from_WRF(fxhour,:) = f3d_onefile->Times
    end do



   print(chartostring(Times_from_WRF) )
   time_wrf   = wrf_times_c(Times_from_WRF,0)         ; built-in function
   time_wrf_utc = time_wrf
   time_wrf(:) = time_wrf+utcoffset
   nt3d          = dimsizes(time_wrf)                    ; # of time steps


   nt_wrf = dimsizes(time_wrf)

   time_6hrs = ispan(tointeger(min(time_wrf)), tointeger(max(time_wrf)), 6) 
   time_6hrs@units = time@units
   time_6hrs!0 = "time_6hrs"
   time_6hrs&time_6hrs = time_6hrs
   calendarnums_6 = cd_calendar(time_6hrs, -5)



   print("inputing wrf data")



   f3d_onefile = addfile(wrf_full_filenames(0), "r") 
   lon2d = wrf_user_getvar(f3d_onefile,"lon",0)
   lat2d = wrf_user_getvar(f3d_onefile,"lat",0)

 printVarSummary( lon2d )

   z_wrf_single_3d      = wrf_user_getvar(f3d_onefile, "z",       0)
   p_wrf_single_3d      = wrf_user_getvar(f3d_onefile, "pressure",0)
   t2dm_wrf_single_3d   = wrf_user_getvar(f3d_onefile, "td2",     0)
   uv_wrf_single_3d     = wrf_user_getvar(f3d_onefile, "uvmet",   0)  
   uv10_wrf_single_3d   = wrf_user_getvar(f3d_onefile, "uvmet10", 0)  

   printVarSummary(p_wrf_single_3d)
   dims_nznynx = dimsizes(z_wrf_single_3d)
   print(dims_nznynx)
   nz = dims_nznynx(0)
   ny = dims_nznynx(1)
   nx = dims_nznynx(2)
   nt = (/ dimsizes(timestr) /)

   td2m_wrf_2d = new((/ nt,     ny, nx /), float)
   u10_wrf_2d  = td2m_wrf_2d
   v10_wrf_2d  = td2m_wrf_2d

   p_wrf_3d    = new((/ nt, nz, ny, nx /), float)
   z_wrf_3d    = p_wrf_3d
   u_wrf_3d    = p_wrf_3d
   v_wrf_3d    = p_wrf_3d
   w_wrf_3d    = p_wrf_3d

   
   td2m_wrf_2d!0    = "time_wrf"
   u10_wrf_2d!0     = "time_wrf"
   v10_wrf_2d!0     = "time_wrf"

   td2m_wrf_2d&time_wrf   = time_wrf
   u10_wrf_2d&time_wrf    = time_wrf
   v10_wrf_2d&time_wrf    = time_wrf


   p_wrf_3d!0 = "time_wrf"
   z_wrf_3d!0 = "time_wrf"
   u_wrf_3d!0 = "time_wrf"
   v_wrf_3d!0 = "time_wrf"
   w_wrf_3d!0 = "time_wrf"
  
   p_wrf_3d&time_wrf    = time_wrf
   z_wrf_3d&time_wrf    = time_wrf
   u_wrf_3d&time_wrf    = time_wrf
   v_wrf_3d&time_wrf    = time_wrf
   w_wrf_3d&time_wrf    = time_wrf

   do fxhour = 0, dimsizes(timestr)-1
      f3d_onefile = addfile(wrf_full_filenames(fxhour), "r") 
      print("Forecast Hour "+fxhour)





      ;printVarSummary(wrf_user_getvar(f3d_onefile, "pressure", 0))
      ;printVarSummary(p_wrf_3d(fxhour,:,:,:))
      p_wrf_3d(fxhour,:,:,:) = wrf_user_getvar(f3d_onefile, "pressure", 0)
      z_wrf_3d(fxhour,:,:,:) = wrf_user_getvar(f3d_onefile, "z",        0)
      w_wrf_3d(fxhour,:,:,:) = wrf_user_getvar(f3d_onefile, "wa",       0)
      

      uv10_wrf_3d = wrf_user_getvar(f3d_onefile,"uvmet10", 0)


      uv_wrf_3d   = wrf_user_getvar(f3d_onefile,"uvmet", 0)
      u_wrf_3d(fxhour,:,:,:)  = uv_wrf_3d(0,:,:,:)
      v_wrf_3d(fxhour,:,:,:)  = uv_wrf_3d(1,:,:,:)
   
      td2m_wrf_2d(fxhour,:,:) = wrf_user_getvar(f3d_onefile,"td2", 0)

      u10_wrf_2d(fxhour,:,:)  = uv10_wrf_3d(0,:,:)
      v10_wrf_2d(fxhour,:,:)  = uv10_wrf_3d(1,:,:)

   end do

   u10_wrf_2d(:,:,:) = (/ u10_wrf_2d(:,:,:)  * 1.94384/) 
   v10_wrf_2d(:,:,:) = (/ v10_wrf_2d(:,:,:)  * 1.94384/) 

   v_wrf_3d(:,:,:,:) = (/ v_wrf_3d(:,:,:,:)  * 1.94384/) 
   u_wrf_3d(:,:,:,:) = (/ u_wrf_3d(:,:,:,:)  * 1.94384/) 

   llres = True
   llres@ReturnInt = True   ; Return integer values
   wrfloc = wrf_user_ll_to_ij (f3d_onefile, lon, lat, llres)
   wrfloc = wrfloc - 1        ; array pointers in NCL space
   locX = wrfloc(0)
   locY = wrfloc(1)

   
   printVarSummary(td2m_wrf_2d)

   td2m_wrf_2d_f = td2m_wrf_2d(:,locY,locX) * 1.8 + 32
   
   p_timeseries_wrf = p_wrf_3d(:,:,locY,locX)
   z_timeseries_wrf = z_wrf_3d(:,:,locY,locX)
   u_timeseries_wrf = u_wrf_3d(:,:,locY,locX)
   v_timeseries_wrf = v_wrf_3d(:,:,locY,locX)
   w_timeseries_wrf = w_wrf_3d(:,:,locY,locX)
   
   U10_timeseries_wrf = u10_wrf_2d(:,locY,locX)
   V10_timeseries_wrf = v10_wrf_2d(:,locY,locX)
   
   printVarSummary(p_timeseries_wrf)
   
   p_avg = dim_avg_Wrap(p_timeseries_wrf(bottom_top|:,time_wrf|:))

   isobaric = tofloat(ispan(100, 1000, 10))
   isobaric(:) = isobaric(::-1)
   isobaric@long_name = "pressure"
   isobaric@units = "hPa"
   isobaric!0 = "isobaric"
   isobaric&isobaric = isobaric
   
   
   isobaricplot = (/  850, 700, 500, 400, 300, 250, 200, 150 /)
   isobaricplot@long_name = isobaric@long_name
   isobaricplot@units = isobaric@units
   isobaricplot!0 = "isobaricplot"
   isobaricplot&isobaricplot = isobaricplot
   
   
   w_timeseries_iso = new((/ dimsizes(isobaric), dimsizes(time_wrf) /), float)
   w_timeseries_iso!0 = "isobaric"
   w_timeseries_iso!1 = "time_wrf"
   w_timeseries_iso&isobaric = isobaric
   w_timeseries_iso&time_wrf = time_wrf
   
   w_timeseries_iso@units = "m s-1"
   
   u_timeseries_iso = w_timeseries_iso
   v_timeseries_iso = w_timeseries_iso
   
   
    w_timeseries_iso@long_name = "vertical veolocity"
    u_timeseries_iso@long_name = "vertical veolocity"
    v_timeseries_iso@long_name = "vertical veolocity"
    
    printVarSummary(w_timeseries_wrf)
    printVarSummary(p_timeseries_wrf)
    printVarSummary(w_timeseries_iso)
    
    
    do t = 0, dimsizes(time_wrf)-1 
       print(" Interpolating Step "+t+" of "+(dimsizes(time_wrf)-1))
       w_timeseries_iso(:,t) = (/ wrf_interp_1d(w_timeseries_wrf(t,:), \
                                             p_timeseries_wrf(t,:), \
                                             isobaric) /)
       u_timeseries_iso(:,t) = (/ wrf_interp_1d(u_timeseries_wrf(t,:), \
                                             p_timeseries_wrf(t,:), \
                                             isobaric) /)
       v_timeseries_iso(:,t) = (/ wrf_interp_1d(v_timeseries_wrf(t,:), \
                                             p_timeseries_wrf(t,:), \
                                             isobaric) /)
    end do


   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   
   
   ; use the wrf timesteps to pull the netcdffiles containing available
   ; metar data
   
      calendarnums_hrlu = cd_calendar(time_wrf_utc, -5)
      
      temp_metar = new( dimsizes(time_wrf) , float)
      temp_metar@units = "deg F"
      temp_metar!0 = "time_wrf"
      temp_metar&time_wrf = time_wrf

      metar_distance_from_node =temp_metar
      metar_distance_from_node@long_name = "Metar Distance from Node"
       metar_distance_from_node@units = "m"
      
      dewp_metar = temp_metar
      time_metar = temp_metar
        u_metar = temp_metar
      v_metar = temp_metar          
      temp_metar@long_name = "Temperature"
      dewp_metar@long_name = "Dew Point Temperature"
      v_metar@long_name = "V"
      u_metar@long_name = "U"
      time_metar@long_name = "time"
      time_metar@units = time_wrf@units
      
      
      
      
      
   do t = 0, dimsizes(time_wrf)-1 
   
      filedate = sprinti("%0.4i",calendarnums_hrlu(t,0)) + "-" + \
                 sprinti("%0.2i",calendarnums_hrlu(t,1)) + "-" + \
                 sprinti("%0.2i",calendarnums_hrlu(t,2)) + "_" + \
                 sprinti("%0.2i00",calendarnums_hrlu(t,3)) 
                 
       metar_file = metar_dir+ "METAR_"+filedate+".nc"
       
       system("gunzip -f9v "+metar_file+".gz")
       
       ; check if file exists
       
      if (isfilepresent(metar_file)) then
      
          metar = addfile(metar_file,"r")
          
          mall_temp = metar->tmpk
          mall_dewp = metar->dwpk
          mall_u = metar->uwnd
          mall_v  = metar->vwnd
             mall_u(:) = (/ mall_u *   1.94384 /) 
             mall_v(:) = (/ mall_v *   1.94384 /) 
          mall_lon  = metar->lon
          mall_lat  = metar->lat
          mall_time = metar->time
          
          pi = 3.14159265359

          distance_meters_x = (mall_lon-lon) * cos(pi / 180. * lat)  * pi / 180.0 * 6371e3   
          distance_meters_y = (mall_lat-lat) * pi / 180.0 * 6371e3 

          distance_ll = sqrt((mall_lon-lon)^2 + (mall_lat-lat)^2)
          distance_ll = sqrt(distance_meters_x*distance_meters_x +  distance_meters_y * distance_meters_y)      


          indtarg_raw = ind( distance_ll .eq. min(distance_ll)  )
          print(indtarg_raw)
          indtarg = indtarg_raw(0)      
 
          print("METAR DATA : "+filedate+" "+indtarg + " " +mall_lat(indtarg) + mall_lon(indtarg) )


          
          if (.not.all(ismissing(indtarg)))  then 
  
                  metar_distance_from_node(t) =  min(distance_ll)

             temp_metar(t) = (mall_temp(indtarg) - 273.17) * 1.8 + 32
             dewp_metar(t) = (mall_dewp(indtarg) - 273.17) * 1.8 + 32
             time_metar(t) = tofloat(ut_convert(mall_time(indtarg), time_wrf@units))

             u_metar(t) = (/ mall_u(indtarg) /)
             v_metar(t) = (/ mall_v(indtarg) /)
        
           end if
        
                delete(mall_temp)
                delete(mall_dewp)
                delete(mall_u)
                delete(mall_v)
                delete(mall_lon)
                delete(mall_lat)
                delete(mall_time)
    
       delete(distance_ll)
        delete(indtarg)
       delete(indtarg_raw)
      delete( distance_meters_y)
      delete(distance_meters_x)
       end if
   
         
   end do
   
   
   print(temp_metar)
   print(dewp_metar)
   print(time_metar)
   

   
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   
   restemp = True
   restemp@trXMinF = min(time_wrf)
   restemp@trXMaxF = max(time_wrf)
   restemp@gsnYRefLine           = 0. 
   restemp@gsnMaximize = True
      restemp@gsnMaximize = True

   
   resprecip = restemp
   resbox = restemp
     rescumprec = resbox
 
   resbox@gsnXYBarChart = True 
   
   restemp@gsnFrame = False
   restemp@gsnDraw = False
   
system("rm -fv "+full_png_dir+ "/wrf_plot_METEOGRAM_" +domain + "_" + run_date+".png")
   wks = gsn_open_wks("png",full_png_dir+ "/wrf_plot_METEOGRAM_" +domain + "_" + run_date)
   gsn_define_colormap(wks,"BlueDarkRed18")


       restemp@trYMinF = min( (/ min(td2m_wrf_2d_f), min(temperature) , min(temp_metar), min(dewp_metar) /) )-1
       restemp@trYMaxF = max( (/ max(td2m_wrf_2d_f), max(temperature) , max(temp_metar), max(dewp_metar) /) )+1
       restemp@xyLineColor = 2 
       restemp@tiYAxisString = "Temperature/Dewpoint (F)"

       restick = True
       restick@ttmFormat = "%H" + utclabel + "~C~%D%C"
       restick@ttmValues = calendarnums_6
       restick@ttmMajorStride = 6
       restick@ttmMinorStride = 1

       time_axis_labels(time_wrf, restemp, restick)
       
       restemp@tmXBLabelJust = "TopCenter"
       
       print(restemp)

       emptyset = td2m_wrf_2d_f
       emptyset(:) = emptyset@_FillValue
       plot_Twrf = gsn_csm_xy(wks,time_wrf,emptyset,restemp)
       restemp@xyLineColor = 19 
          ;plot_T = gsn_xy(wks,time,temperature,restemp)
          ;overlay(plot_Twrf,plot_T)


       resdot = restemp
       resdot@xyMarkLineModes   = "Markers"                ; choose which have markers
       resdot@xyMarkers         =  16                      ; choose type of marker  
       resdot@xyMarkerColor     = 16                    ; Marker color
       resdot@xyMarkerSizeF     = 0.01                     ; Marker size (default 0.01)
       print(temp_metar)
       plot_Tmetar = gsn_xy(wks,time_wrf,temp_metar,resdot)
       overlay(plot_Twrf,plot_Tmetar)

       resdot@xyMarkerColor     = 6                    ; Marker color
       
       plot_TDmetar = gsn_xy(wks,time_wrf,dewp_metar,resdot)
       overlay(plot_Twrf,plot_TDmetar)

       restemp@xyLineColor = 19
       plot_T = gsn_xy(wks,time,temperature,restemp)
       overlay(plot_Twrf,plot_T)

       restemp@xyLineColor = 2
       plot_Tdw = gsn_xy(wks,time,tdc,restemp)
       overlay(plot_Twrf, plot_Tdw)

     ;  restemp@xyLineColor = 2
     ;  plot_T = gsn_xy(wks,time_wrf,td2m_wrf_2d_f,restemp)
     ;  overlay(plot_Twrf,plot_T)
     
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  


    if (max(precip_hourly) .gt. 0) then 
       precip_hourly = where((precip_hourly .gt. 0).and.(precip_hourly .lt. 0.001), 0.001, precip_hourly)

       precipcoord = (/ (/ max(precip_hourly)/3 /),  (/  max(precip_hourly)*100 /)  /)

    end if    

    if (max(precip_hourly) .eq. 0) then 


       precipcoord = (/  -0.4, 99 /)

    end if    


           precipcoord!0 = "precipcoord"
           precipcoord&precipcoord = precipcoord
           
           print(precipcoord)



    if (max(precip_hourly) .gt. 0) then 


       precipcoord2 = (/ (/ max(precip_hourly)*2/3 /),  (/  max(precip_hourly)*100 /)  /)

    end if    

    if (max(precip_hourly) .eq. 0) then 


       precipcoord2 = (/  0.4, 99 /)

    end if    


           precipcoord2!0 = "precipcoord2"
           precipcoord2&precipcoord2 = precipcoord2
           
           print(precipcoord2)

            
      windvector_u10 = new( (/ 2, dimsizes(time_wrf) /), float)
          windvector_u10!1 = "time_wrf"
          windvector_u10&time_wrf = time_wrf
          windvector_u10!0 = "precipcoord"
          windvector_u10&precipcoord = precipcoord
          
      windvector_v10 = windvector_u10
      
      windvector_null = windvector_u10
      windvector_null(:,:) = 0.0001
      
      printVarSummary(windvector_u10)
      printVarSummary(U10_timeseries_wrf)
  
        windvector_u10(0,:) =  (/ U10_timeseries_wrf /)
        windvector_v10(0,:) =  (/ V10_timeseries_wrf /)
        windvector_u10(1,:) =  (/ U10_timeseries_wrf /)
        windvector_v10(1,:) =  (/ V10_timeseries_wrf /)
  

      windvector_u10metar = windvector_u10
          windvector_u10metar!0 = "precipcoord2"
          windvector_u10metar&precipcoord2 = precipcoord2
      windvector_v10metar = windvector_u10metar
      windvector_nullmetar = windvector_v10metar         

        windvector_u10metar(0,:) =  (/ u_metar/)
        windvector_v10metar(0,:) =  (/ v_metar /)
        windvector_u10metar(1,:) =  (/ u_metar/)
        windvector_v10metar(1,:) =  (/ v_metar /)


      windvector_nullmetar = where (ismissing(windvector_u10metar), windvector_nullmetar@_FillValue, 0.0001)
  
  
       resbox@gsnAboveYRefLineColor = 6  
     ;  resbox@trYMaxF = max(precip_hourly)
     ;  resbox@trYMinF = min(precip_hourly)
        resbox@tiYAxisString = "Hourly Precip (in), 10-m Wind (kts)"

       resbox@xyLineColor = 6
       resbox@tmXBLabelJust = "TopCenter"
       resbox@gsnFrame = False
       resbox@gsnDraw = False
       
       restick@ttmMajorStride = 6
       restick@ttmMinorStride = 1
       
       time_axis_labels(timehourly, resbox, restick)


             
          rescumprec@xyLineColor           = "blue"
          rescumprec@xyLineThicknessF           = 2.0
          rescumprec@tmXUseBottom      = True
          rescumprec@tmXTOn = False
 

                    plotP3 = gsn_csm_x2y2(wks,(timehourly-0.5),(cprecip&time-0.5),precip_hourly,cprecip,resbox, rescumprec)
 
            
  resvec1=True
  resvec1@gsnFrame=False
  resvec1@gsnDraw=False
  resvec1@vcRefAnnoOn         = False      ; turns off the ref vector
  resvec1@vcRefLengthF        = 0.050      ; set length of ref vector
  resvec1@vcGlyphStyle        = "WindBarb" ; turn on windbarbs
  resvec1@vcMonoWindBarbColor = True       ; to color the windbarbs with
                                          ; respect to speed use False
  resvec1@vcNoDataLabelOn = False
  resvec1@vcMapDirection = False			      ; needed to disassociate the coordinate plane from the wind barbs
    resvec1@vcPositionMode =        "ArrowHead"  
           print(windvector_u10(0,::3))
           print(windvector_null(0,::3))           
           print(windvector_u10metar(0,::3))
           print(windvector_nullmetar(0,::3))           
  plotvecline = gsn_csm_vector(wks, windvector_u10(:,::2), windvector_v10(:,::2), resvec1)
             overlay(plotP3,plotvecline)
  plotvecline = gsn_csm_vector(wks, windvector_null(:,::2), windvector_null(:,::2), resvec1)
             overlay(plotP3,plotvecline)

  resvec1@vcWindBarbColor = "Red"
  plotvecline = gsn_csm_vector(wks, windvector_u10metar(:,::2), windvector_v10metar(:,::2), resvec1)
             overlay(plotP3,plotvecline)
  plotvecline = gsn_csm_vector(wks, windvector_nullmetar(:,::2), windvector_nullmetar(:,::2), resvec1)
             overlay(plotP3,plotvecline)
   
            
;;;;;;;;;;;;;;;;;;;;;;
       
  rescross = True
     rescross@gsnMaximize = True

  rescross@cnLevelSelectionMode = "ManualLevels"        ; manual contour levels
  rescross@cnLevelSpacingF      = .10                   ; contour interval
  rescross@cnMinLevelValF       = -1.                  ; min level
  rescross@cnMaxLevelValF       =  1.                  ; max level
  rescross@cnLinesOn            = False                 ;
 ; rescross@gsnContourZeroLineThicknessF = 2             ; doubles thickness of zero contour
  ;rescross@gsnContourNegLineDashPattern = 1 		; sets negative contours to dash pattern 1
 ; rescross@cnLineLabelsOn       = True                  ; turn on line labels
  rescross@cnFillOn             = True                  ; turn on color fill
  rescross@gsnSpreadColors      = True                  ; use full range of colors
  rescross@lbLabelAutoStride    = True                  ; optimal labels
  rescross@gsnDraw = False
  rescross@gsnFrame = False
        rescross@tiYAxisString = "Isobaric Height (hPa)"
        rescross@cnLineLabelBackgroundColor= -1
rescross@pmLabelBarOrthogonalPosF = -0.05  
;rescross@lbOrientation = "vertical"

 resvec=True
  resvec@gsnFrame=False
  resvec@gsnDraw=False
  resvec@vcRefAnnoOn         = False      ; turns off the ref vector
  resvec@vcRefLengthF        = 0.040      ; set length of ref vector
  resvec@vcGlyphStyle        = "WindBarb" ; turn on windbarbs
  resvec@vcMonoWindBarbColor = True       ; to color the windbarbs with
                                          ; respect to speed use False
  resvec@vcMapDirection = False			      ; needed to disassociate the coordinate plane from the wind barbs
     
     printVarSummary(u_timeseries_iso)
  restick2 = True
     restick2@ttmFormat = "%H"+utclabel+"~C~%D%C"
     restick2@ttmValues = calendarnums_6
     restick2@ttmMajorStride = 6
     restick2@ttmMinorStride = 1
            time_axis_labels(time_wrf, rescross, restick2)

  plotcross = gsn_csm_pres_hgt(wks,w_timeseries_iso,rescross)
  plotvec = gsn_csm_vector(wks, u_timeseries_iso({isobaricplot},::3), v_timeseries_iso({isobaricplot},::3), resvec)
    overlay(plotcross,plotvec)
    
    
    
    
    
    ;;;;;;;;;;;;;;;;;;;
    
       multi_array = (/  lfx, hfx, glw, gsw /)
       
       flux_colors = (/ 13, 15, 18, 3/)
       flux_labels = (/ "Sw", "Lw", "H", "LE" /)
       flux_thick = (/ 3., 3, 1.5, 1.5 /)
       
        flux_colors(:) =  flux_colors(::-1) 
        flux_labels(:) =  flux_labels(::-1) 
        flux_thick(:) =  flux_thick(::-1) 
       
       
    
  resflux = True
   resflux@trXMinF = min(time_wrf)
   resflux@trXMaxF = max(time_wrf)
   resflux@gsnYRefLine           = 0. 
   resflux@gsnMaximize = True
   resflux@gsnMaximize = True

   
   resflux@gsnFrame = False
   resflux@gsnDraw = False
       resflux@trYMinF = min( (/ min(multi_array) /) )-10
       resflux@trYMaxF = max( (/ max(multi_array) /) )+10
       resflux@xyLineColors = 2 
       resflux@tiYAxisString = "Energy Flux (W m-2)"

       restick = True
       restick@ttmFormat = "%H" + utclabel + "~C~%D%C"
       restick@ttmValues = calendarnums_6
       restick@ttmMajorStride = 6
       restick@ttmMinorStride = 1

       time_axis_labels(time_wrf, resflux, restick)
       
       restemp@tmXBLabelJust = "TopCenter"
       

       emptyset = td2m_wrf_2d_f
       emptyset(:) = emptyset@_FillValue
       plot_flux = gsn_csm_xy(wks,time_wrf,emptyset,resflux)
       
  reslines = True
 reslines@xyDashPattern = 0               ; Make curves all solid
  reslines@xyMarkLineMode = "Lines"    ; Markers *and* lines
  reslines@xyLineColors = flux_colors ; 3 different colors
  reslines@gsnFrame = False
  reslines@gsnDraw =  False
  reslines@xyLineThicknesses = flux_thick
       print(resflux)
    
    
  reslines@pmLegendDisplayMode    = "Always"              ; turn on legend
 
 reslines@pmLegendSide           = "Top"                 ; Change location of 
 reslines@pmLegendParallelPosF   = .90                   ; move units right
 reslines@pmLegendOrthogonalPosF =  -0.27                  ; more neg = down
 
 reslines@pmLegendWidthF         = 0.12                  ; Change width and
 reslines@pmLegendHeightF        = 0.15                 ; height of legend.
 reslines@lgLabelFontHeightF     = .015                   ; change font height
 reslines@lgPerimOn              = False                 ; no box around
; labels for the legend
 reslines@xyExplicitLegendLabels = flux_labels

      
 plot_fluxlines  = gsn_xy (wks,time,multi_array,reslines) ; create plot
       
       
     overlay(plot_flux,plot_fluxlines)
      
       
  
    
    ;;;;;;;;;;;;;;;;;;
    


         resP = True
         resP@txString = station_nice_name +  " SDSMT WRF Meteogram for "+run_date
         resP@gsnLeftString    = " "
         resP@gsnRightString   = " "
            resP@gsnMaximize      = True
         resP@gsnOrientation   = "Landscape"
         resP@gsnPaperOrientation = "Landscape"

  gsn_panel(wks,(/  plot_Twrf,plotP3, plot_flux, plotcross/),(/2,2/),resP)             ; now draw as one plot

system("rm -fv "+dir_png + "/currentRAP/wrf_plot_METEOGRAM_"+domain+ ".png")
  system ("scp " +  full_png_dir + "/wrf_plot_METEOGRAM_"+domain + "_" + run_date+".png  "+ dir_url+ "/wrf_plot_METEOGRAM_"+domain+ ".png")


     print(     metar_distance_from_node )

end

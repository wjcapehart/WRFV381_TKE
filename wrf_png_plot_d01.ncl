
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

 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Identify Output File/Device
;
;  pdf  = PDF file (recommended)       ps  = Postscript File 
;  ncgm = NCAR Graphics File           x11 = X11 Graphics Image
;  eps  = Encapsulated Postcript File 
;
  output_format = "png"  ; pdf file
    output_format@wkWidth = 800
  output_format@wkHeight = 800

  convert_to_inches = 1
hours_in_a_forecast = 36
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; File Control (default directory location of netCDF file)
;
  dir_local = "/home/wjc/WRF_REALTIME_KUNR-3DOM/"
  dir_wrf   = "/cyclone1/WRF_REALTIME/OUTPUT/"
  dir_png   = "/projects/WRF_REALTIME/OUTPUT_PNG/"
  dir_url = "wjc@kyrill:/var/www/html/firemet/wrf_rap/"
 
  ;dir_local = "./"
  ;dir_wrf   = "./"
  ;dir_png   = "./"
 
  time = ispan(0,hours_in_a_forecast,1) 
  deltat = time(1)-time(0)
  
  domain = "d01"
  
  
 ; ens_dir  = (/ "WRF32_KUNR_3DOM_WSM6_NOAH_YSU_KF2_DUDHIA_NARRFNL-09km_150x150/"    /)
   ens_dir  = (/ "WRF36_KUNR_3DOM_WSM6_NOAH_MYNN2_KF2_DUDHIA_NAM218-09km_150x150/"    /)

   ; ens_dir  = (/ "./"    /)

  
  ;ens_dir = (/ "./", "./", "./" /)
  
  ens_label = (/ "Rapid City CWA" /)
  
  ns = dimsizes(ens_dir)
  nt = dimsizes(time)

 ;  print("cat " + dir_local + "current_day.txt")
  run_date = systemfunc("cat " + dir_local + "current_day.txt")
 ; print(run_date)
  
;;;run_date = "2009-04-14_06"

  wrf_file = new( (/ ns, nt/),  string)
  
  
;  print(run_date)


  full_png_dir = dir_png +"/"+run_date+"/"+domain

  system("mkdir -v "+dir_png +"/"+run_date)

  system("mkdir -v "+ full_png_dir )

 do t = 0, nt-1
     do s = 0, ns-1
        wrf_file(s,t) = dir_wrf + ens_dir(s) + "wrfout_" + domain + "_" + run_date + "_F" + sprinti("%0.2i",time(t))  + ".nc"
        result = systemfunc("gunzip -vfr "+wrf_file(s,t)+".gz") 

        if ((s .eq. 0) .and. (t .eq. 0)) then

           f = addfile(wrf_file(0,0), "r")

           time_zero_string = chartostring(f->Times )

           ;time_zero_string)

           time_unit = "hours since "+time_zero_string +"z"
           time@units = time_unit
           time!0     = "time"
           time&time  = time
           time@long_name = "time"
       

        ;   print(time)

      


           temp = f->T2(0,:,:)
           lat2d   = f->XLAT(0,:,:)     
           lon2d   = f->XLONG(0,:,:)      

           nxny = dimsizes(temp)
           nx   = nxny(1)
           ny   = nxny(0)

           ptile_005 = floattointeger(0.05 * nx * ny * ns)
           ptile_095 = floattointeger(0.95 * nx * ny * ns)

       ;    print((/ ptile_005,ptile_095 /))

           t2m_all = new( (/ns, nt-1, ny, nx/), float)
           tmax = new( (/ ny, nx/), float)  + 1e99
           tmin = new( (/ ny, nx/), float)  - 1e99

           t2m_max = new( nt, float)

           t2m_all!0           = "scenario"
           t2m_all!1           = "time"
           t2m_all!2           = temp!0
           t2m_all!3           = temp!1
           t2m_all@description = temp@description 
           t2m_all@units       = temp@units
           t2m_all&time        = time(1:nt-1)
           


          
          tmax!0           = temp!0
           tmax!1           = temp!1
          tmax@description = "MAX " + temp@description 
          tmax@units       = temp@units
          tmax@lon2d       = lon2d
          tmax@lat2d       = lat2d




           tmin!0           = temp!0
           tmin!1           = temp!1
           tmin@description = "MIN " + temp@description
           tmin@units       = temp@units
          tmin@lon2d       = lon2d
          tmin@lat2d       = lat2d


           t2m_max!0           = "time"
           t2m_max@description = "maxium 2-m air temperature for a given set of scenarios" 
           t2m_max@units       = "deg F"
           t2m_max&time        = time

           t2m_min = t2m_max
           t2m_min@description = "maxium 2-m air temperature for a given set of scenarios" 

           ;arSummary(t2m_all)
         ;  printVarSummary(t2m_max)
         ;  printVarSummary(t2m_min)

           delete(temp)   
          

        end if

        if (t .gt. 0) then 


           f = addfile(wrf_file(s,t), "r")

           t2m_all(s,t-1,:,:) = f->T2(0,:,:)

        end if

     end do 


      if (t .gt. 0) then 

        temp = ndtooned(t2m_all(:,t-1,:,:))

        qsort(temp)

        t2m_max(t) = (max(temp) - 273.17) * 9. / 5. + 32
        t2m_min(t) = (min(temp) - 273.17) * 9. / 5. + 32

        t2m_max(t) = (temp(ptile_095) - 273.17) * 9. / 5. + 32
        t2m_min(t) = (temp(ptile_005) - 273.17) * 9. / 5. + 32

     end if



  end do
  
  
;  print(t2m_max)
;print(t2m_min)


         ; print((/ ptile_005,ptile_095,(nx*ny*ns) /))



;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

   

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Color Tables
;

;
; PRISM Graphical Products (good for monthly)
; http://www.prism.oregonstate.edu/
;


ahps_snow  = (/  0.01,0.10,0.25,0.50,1.0,2.,3,4,5,6,7,8,9,10,12 /)

ahps_6hrly  = (/  0.01,0.10,0.25,0.50,0.75,1.0,1.25,1.5,2.0,2.5,3,4,5,6,7 /)*25.4
ahps_daily  = (/  0.01,0.10,0.25,0.50,0.75,1.0,1.5,2.0,2.5,3,4,5,06,08,10 /)*25.4
ahps_monthly = (/ 0.01,0.10,0.25,0.50,1.00,1.5,2.0,3.0,4.0,5,6,8,10,15,20 /)*25.4
ahps_colors =       (/ (/ 1.00000,1.00000,1.00000 /), \  ; Foreground
                       (/ 0.00000,0.00000,0.00000 /), \  ; Background
                       (/ 1.00000,1.00000,1.00000 /), \  ; 0 (white)
                       (/ 0.68628,0.93333,0.93333 /), \  ; 0.01
                       (/ 0.00392,0.63137,0.96078 /), \  ; 0.10 (cyan)
                       (/ 0.01176,0.00000,0.96471 /), \  ; 0.25
                       (/ 0.60392,0.80392,0.19608 /), \  ; 0.50 
                       (/ 0.00392,0.78431,0.00392 /), \  ; 0.75
                       (/ 0.00000,0.56863,0.00000 /), \  ; 1.00
                       (/ 0.98824,0.97255,0.01176 /), \  ; 1.25
                       (/ 0.99216,0.76471,0.00588 /), \  ; 1.50
                       (/ 0.99608,0.55686,0.00000 /), \  ; 2.00
                       (/ 1.00000,0.50000,0.50000 /), \  ; 2.50
                       (/ 1.00000,0.00000,0.00000 /), \  ; 3.00
                       (/ 0.40000,0.00000,0.00000 /), \  ; 4.00
                       (/ 1.00000,0.73333,1.00000 /), \  ; 5.00
                       (/ 0.47843,0.21569,0.54510 /), \  ; 6.00
                       (/ 0.40784/3*2,0.13333/3*2,0.54509/3*2 /) /)  ; 7.00 

shading_contours =  ahps_6hrly 
shading_colors   =  ahps_colors

ahps_max = 17
ahps_min = 2
bwr_min = 19
bwr_max = 39
bwr_range = bwr_max-bwr_min+1.0

ahps_color_range = ispan(ahps_min,ahps_max,1)
bwr_color_range = ispan(bwr_min,bwr_max,1)


if ( convert_to_inches .eq. 1 ) then
   shading_contours  = shading_contours / 25.4  ; mm to inches
end if

;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Open Plotting Device for Graphics Output and Set Color Table
;
  wks  = gsn_open_wks(output_format ,full_png_dir + "/wrf_plot_SFC_" +domain + "_" + run_date )      
  wks2 = gsn_open_wks(output_format ,full_png_dir + "/wrf_plot_PREC_"+domain + "_" + run_date )      
  wks3 = gsn_open_wks(output_format ,full_png_dir + "/wrf_plot_TOTALPREC_"+domain + "_" + run_date )     
  wkssnof = gsn_open_wks(output_format ,full_png_dir + "/wrf_plot_SNOWFALL_"+domain + "_" + run_date )     
  wkssnoft = gsn_open_wks(output_format ,full_png_dir + "/wrf_plot_TOTALSNOWFALL_"+domain + "_" + run_date )       
wksdbz  = gsn_open_wks(output_format ,full_png_dir + "/wrf_plot_DBZ_" +domain + "_" + run_date )      
 ;wksvhl  = gsn_open_wks(output_format ,full_png_dir + "/wrf_plot_VHL_" +domain + "_" + run_date )      

  gsn_define_colormap(wks, "precip2_15lev")  
  gsn_define_colormap(wks2, shading_colors )
  gsn_define_colormap(wks3, shading_colors )    
  gsn_define_colormap(wkssnof, shading_colors )    
  gsn_define_colormap(wkssnoft, shading_colors )    

    gsn_define_colormap(wksdbz, "prcp_1" )    
  ;  gsn_define_colormap(wksvhl, "prcp_1" )    

;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Loop em through
;

do t = 0, nt-1

   plot = new((/ 2*ns /), graphic)

   do s = 0, ns-1
   
   
      f = addfile(wrf_file(s,t), "r")
    

      time_chars = f->Times
      
      time_valid = chartostring(time_chars(:,0:12)) + " UTC"
                                printVarSummary(f)  
      time_valid_string =  sprinti("SDSMT WRF %0.2i-hr Fx Valid @ ",time(t)) + time_valid
      
 ;    print(time_valid_string)

      lat2d   = f->XLAT(0,:,:)     
      lon2d   = f->XLONG(0,:,:)      


      mapfct = wrf_user_getvar(f, "MAPFAC_M", 0)   ; Map projection scale factor
      us     = wrf_user_getvar(f,"ua",0)          ; u averaged to mass points
      vs     = wrf_user_getvar(f,"va",0)          ; v averaged to mass points
      w      = wrf_user_getvar(f, "W",0)          ; vertical velocity
      ph     = wrf_user_getvar(f,"PH",0)
      phb    = wrf_user_getvar(f,"PHB",0)
      zp     = ph ;+ phb
      dx     = f@DX
      dy     = f@DY

;  

; Compute updraft helicity. uhmnhgt and uhmxhgt will
; default to 2000 and 5000.
;

  uh = wrf_updraft_helicity(zp, mapfct, us, vs, w, dx, dy, 0)
  uh@lon2d = lon2d
  uh@lat2d = lat2d

      u10       = f->U10(0,:,:) ; kts ; (Time, south_north, west_east)
      v10       = f->V10(0,:,:); kts ; 
      
      u10 = u10*1.94384449 
      v10 = v10*1.94384449 
      v10@units = "kts"
      u10@units = "kts"


      t2m       = f->T2(0,:,:)
      t2mC       = f->T2(0,:,:)

     t2m       = (t2m  - 273.17) * 9. / 5. + 32
      t2mC       = (t2mC    - 273.17)



      mslp = wrf_user_getvar(f,"slp",0)       ; Get MSLP   
        
     ;       ivarint to 1 , iliqskin to 1 (second "1" below)
      dbz = wrf_user_getvar(f, "mdbz"  ,0)   
      dbz@lon2d = lon2d
      dbz@lat2d = lat2d

      
      mslp@lon2d = lon2d
      mslp@lat2d = lat2d
      mslp@units = "hPa"
      
      u10@lon2d = lon2d
      u10@lat2d = lat2d
      u10@units = "kt"
      
      v10@lat2d = lat2d
      v10@lon2d = lon2d
      v10@units = "kt"
      
      t2m@lon2d = lon2d
      t2m@lat2d = lat2d
      t2m@units = "deg F"

      t2mC@lon2d = lon2d
      t2mC@lat2d = lat2d
      t2mC@units = "deg C"

      
      rainc   = f->RAINC(0,:,:)               ; (Time, south_north, west_east)
      rainnc  = f->RAINNC(0,:,:)    
 

      rainc   = rainc  / 25.4                ; (Time, south_north, west_east)
      rainnc  = rainnc / 25.4    

  
printVarSummary(rainnc)

   
      snowh = wrf_user_getvar(f,"SNOWH",0) 
      snowh(:,:) = snowh* 39.3700787 ; m->inches 
      snowh@units = "in"
         snowh@lat2d = lat2d
         snowh@lon2d = lon2d

      total_precip = rainc + rainnc
      total_precip@lat2d = lat2d
      total_precip@lon2d = lon2d



      dimll = dimsizes(lat2d)
      ny  = dimll(0)
      nx  = dimll(1)

printVarSummary(total_precip)
      if ((s .eq. 0) .and. ((t.eq.0))) then
         old_prec   = new((/ ns, ny, nx /), float)
         delta_snowh = new((/ nt, ny, nx /), float)
         delta_snowh@lat2d = lat2d
         delta_snowh@lon2d = lon2d
         delta_snowh@description=deltat+"-hrly Snow Accumulation"
         delta_snowh@units = "in"
         delta_snowh(:,:,:)= 0.0
        ;            printVarSummary(delta_snowh)
       ;    printVarSummary(snowh)

         
           delta_snowh!0           = "time"
           delta_snowh!1           = snowh!0
           delta_snowh!2           = snowh!1
     ;      printVarSummary(delta_snowh)
         snowh_arch = delta_snowh
         snowh_arch@description=snowh@description
         
         snowh@lat2d = lat2d
         snowh@lon2d = lon2d
         old_snowh   = snowh
         total_snow  = snowh
         total_snow(:,:) = 0.00
         original_snow = snowh
        
      end if
  
  snowh_arch(t,:,:) = snowh
    
    
      if (t .eq. 0) then 
         prec3hr = total_precip
      end if
      
      if (t .gt. 0) then
         prec3hr = total_precip  - old_prec(s,:,:)
         
         
         delta_snowh(t,:,:) = snowh_arch(t,:,:)  - snowh_arch(t-1,:,:) 
         delta_snowh(t,:,:) = delta_snowh(t,:,:) > 0.0
         
         total_snow(:,:) = total_snow(:,:) + delta_snowh(t,:,:)
         
         
      end if

      old_prec(s,:,:) = total_precip(:,:)
         old_snow = snowh

      
      
      prec3hr@lon2d = lon2d
      prec3hr@lat2d = lat2d
      prec3hr@units = "in"
      
 
      res                       = True             ; plot mods desired
      res@gsnMaximize           = True             ; maximize size
      res@gsnBoxMargin          = 0                ; no box margin
      res@cnInfoLabelOn=False
      cnres = res

      res@gsnDraw             = False            ; Turn off draw.
      res@gsnFrame            = False             ; Turn off frame advance.

      res@mpFillOn                 = False       ; turn off map fill
      res@mpProjection             = "LambertConformal"
	  res@mpLambertParallel1F      = f@TRUELAT1
	  res@mpLambertParallel2F      = f@TRUELAT2
	  res@mpLambertMeridianF       = f@CEN_LON
	  res@mpLimitMode              = "Corners"  
	  res@mpLeftCornerLatF         = lat2d(0,0)
	  res@mpLeftCornerLonF         = lon2d(0,0)
	  res@mpRightCornerLatF        = lat2d(ny-1,nx-1)
	  res@mpRightCornerLonF        = lon2d(ny-1,nx-1)
      res@pmLabelBarOrthogonalPosF = -0.05          ; Move labelbar closer to plo
      res@mpOutlineOn = True
 

       res@mpOutlineBoundarySets = "AllBoundaries" ; all boundaries
       res@mpDataBaseVersion     = "Ncarg4_1"
       res@mpDataSetName         = "Earth..4"
       res@lbLabelFontHeightF           =0.02

      res@mpOutlineBoundarySets       = "AllBoundaries" ; all boundaries
      res@pmLabelBarOrthogonalPosF    = -0.05          ; Move labelbar closer to plo
      res@mpNationalLineThicknessF    =  1.0
      res@mpGeophysicalLineThicknessF = 1.0
       res@mpUSStateLineThicknessF     = 2.0

      res1 = res   ; surface maps
      res2 = res   ; precip maps


     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
     ;
     ;  Plot sea-level pressure, temperatures and 10-m winds
     ;

     res1@tiMainString     =  time_valid_string 
     res1@gsnLeftString    = "MSLP/10-m Winds/2-m Temp"
     res1@gsnRightString   = "hPa/kts/~S~o~N~F"
     res1@gsnScalarContour = True             ; enable contours
     res1@gsnSpreadColors  = True             ; use full range of colors

     ;
     ; resX does the master maps [vectors(vc*) and shaded contours(cn*)]
     ;   Levels are automatic for this plot and the default settings
     ;   indeed call for automated leveling

     res1@cnLineLabelsOn       = True             ; turn on line labels
     res1@cnFillOn             = True             ; color plot desired
     res1@cnLinesOn            = False            ; turn off contour lines
     res1@cnFillMode            = "RasterFill"     ; raster
     res1@cnLineLabelsOn       = False            ; turn off contour labels
     res1@lbLabelAutoStride    = False             ; skip legend labels as needed
     res1@mpOutlineOn = True
     res1@cnLevelSelectionMode       = "ManualLevels" ; manual contour levels

     res1@cnMinLevelValF             = floattointeger(min(t2m_min(:)))  +1         ; min level
     res1@cnMaxLevelValF             = floattointeger(max(t2m_max(:)))  -1         ; max level

     res1@cnLevelSpacingF            = ceil((res1@cnMaxLevelValF-res1@cnMinLevelValF)/14.)          ; contour interval


     res1@vcGlyphStyle          = "WindBarb"
     res1@vcRefLengthF          = 0.025            ; ref vec length
     res1@vcMinDistanceF        = 0.025            ; larger means sparser
     res1@vcWindBarbTickLengthF = 0.4              ; default 0.3
     res1@vcRefAnnoOn           = False
   
res2@lbLabelAngleF = 315.
res2@lbLabelJust   = "centerLeft"

     ;
     ; cnresX are the settings for addition contour overlays
     ;
	 
     cnres1                = True
     cnres1@tfDoNDCOverlay = True    ; don't transform	 
     cnres1@gsnDraw        = False   ; Turn off draw.
     cnres1@gsnFrame       = False   ; Turn off frame advance.
     cnres1@cnFillOn       = False   ; just plain contours (no color fills)
     cnres1@cnLinesOn      = True    ; turn lines on 
     cnres1@cnLineLabelsOn = True    ; turn line labels on
     cnres1@cnInfoLabelOn = False 
 
 
 
     cnres1@cnLevelSelectionMode       = "ManualLevels" ; manual contour levels
     cnres1@cnLevelSpacingF            =    2           ; contour interval
     cnres1@cnMinLevelValF             =  950           ; min level
     cnres1@cnMaxLevelValF             = 1500           ; max level
     cnres1@cnHighLabelsOn             = True           ; mark your highs
     cnres1@cnLowLabelsOn              = True           ; same for lows
     cnres1@cnLineLabelBackgroundColor = -1   ; no lines through labels
     cnres1@cnLineColor                = "Black"
     cnres1@cnLineLabelFontColor       = cnres1@cnLineColor
     cnres1@cnLineThicknessF = 1.5
     cnres1@cnInfoLabelOn=False
     plot(0*3+s) = gsn_csm_vector_scalar_map(wks,u10,v10,t2m,res1)
	 
     plot_contours1 =  gsn_contour(wks,mslp,cnres1)

     overlay(plot(0*ns+s), plot_contours1)
     draw(plot(0*ns+s))
     frame(wks2)



res2@tiMainString     =  time_valid_string  
res2@gsnLeftString    =  deltat+"-hrly Precip"
res2@gsnRightString   = "in"
res2@gsnScalarContour = True             ; enable contours
res2@gsnSpreadColors  = True             ; use full range of colors

res2@cnLevels              = shading_contours ; contour/shade levels
res2@cnFillOn              = True             ; color plot desired
res2@cnLinesOn             = False            ; turn off contour lines
res2@cnLineLabelsOn        = False            ; turn off contour labels
res2@cnFillMode            = "AreaFill"     ; raster
res2@cnLevelSelectionMode  = "ExplicitLevels" ; explicit [unequal] cn levels
res2@gsnMaximize           = True             ; maximize size
res2@gsnSpreadColors       = False             ; use full range of colormap
res2@cnFillColors          = ahps_color_range  ; manual color selection
res2@mpOutlineOn = True
res2@mpOutlineDrawOrder = "PostDraw"
res2@lbLabelAngleF = 315.
res2@lbLabelJust   = "centerLeft"
res2@mpPerimOn         = True             ; turn off box around plot
res2@mpPerimDrawOrder = "PostDraw"
res2@lbLabelAutoStride    = False 

cnres2a = cnres1
cnres2b = cnres1
cnres2a@cnInfoLabelOn = False
cnres2a@cnLevelSelectionMode = "ManualLevels"
cnres2a@cnHighLabelsOn             = False           ; mark your highs
cnres2a@cnLowLabelsOn              = False           ; same for lows
cnres2a@cnLevelSelectionMode  = "ExplicitLevels" ; explicit [unequal] cn levels
cnres2a@cnLevels               = (/ 0 /) ; contour/shade levels
cnres2a@cnLineLabelStrings = (/"0~S~o~N~C"/)
cnres2a@cnLineLabelFontColor       = "Red"
cnres2a@cnLineColor           = cnres2a@cnLineLabelFontColor 
cnres2a@cnExplicitLineLabelsOn = True
cnres2a@cnLineThicknessF = 1.

cnres2b@cnLevelSelectionMode = "ManualLevels"
cnres2b@cnLevelSelectionMode  = "ExplicitLevels" ; explicit [unequal] cn levels
cnres2b@cnHighLabelsOn             = False           ; mark your highs
cnres2b@cnLowLabelsOn              = False           ; same for lows
cnres2b@cnLevels               = (/ 0.0005 /) ; contour/shade levels
cnres2b@cnLineLabelStrings = (/"T"/)
cnres2b@cnLineLabelFontColor       = "Cyan"
cnres2b@cnLineColor           = "Cyan"
cnres2b@cnExplicitLineLabelsOn = True
cnres2b@cnLineThicknessF = 1.
cnres2b@cnInfoLabelOn=False

 plot(1*ns+s) =gsn_csm_contour_map(wks2,prec3hr,res2)
 plot_contours2a =  gsn_contour(wks2,t2mC,cnres2a)
 plot_contours2b =  gsn_contour(wks2,prec3hr,cnres2b)

     overlay(plot(1*ns+s), plot_contours2a)
     overlay(plot(1*ns+s), plot_contours2b)
     
     
     draw(plot(1*ns+s))
     frame(wks)





;if (t .gt. 0) then
res2@tiMainString     =  time_valid_string  
res2@gsnLeftString    =  "Est. "+deltat+"-hrly Snowfall"
res2@gsnRightString   = "in"
res2@gsnScalarContour = True             ; enable contours
res2@gsnSpreadColors  = True             ; use full range of colors

res2@cnLevels              = ahps_snow ; contour/shade levels
res2@cnFillOn              = True             ; color plot desired
res2@cnLinesOn             = False            ; turn off contour lines
res2@cnLineLabelsOn        = False            ; turn off contour labels
res2@cnFillMode            = "AreaFill"     ; raster
res2@cnLevelSelectionMode  = "ExplicitLevels" ; explicit [unequal] cn levels
res2@gsnMaximize           = True             ; maximize size
res2@gsnSpreadColors       = False             ; use full range of colormap
res2@cnFillColors          = ahps_color_range  ; manual color selection
res2@mpOutlineOn = True
res2@mpOutlineDrawOrder = "PostDraw"
res2@lbLabelAngleF = 315.
res2@lbLabelJust   = "centerLeft"
res2@mpPerimOn         = True             ; turn off box around plot
res2@mpPerimDrawOrder = "PostDraw"

 plotsnowfall =gsn_csm_contour_map(wkssnof,delta_snowh(t,:,:),res2)

draw(plotsnowfall)
frame(wkssnof)
;endif
     ;
     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



res2@tiMainString     =  time_valid_string  
res2@gsnLeftString    =  "Est. Max Radar Reflectivity"
res2@gsnRightString   = "dbz"
res2@gsnScalarContour = True             ; enable contours
res2@gsnSpreadColors  = True             ; use full range of colors

delete(res2@cnlevels)
res2@cnLevels              = ispan(5,75,5)*1.0 ; contour/shade levels
res2@cnFillOn              = True             ; color plot desired
res2@cnLinesOn             = False            ; turn off contour lines
res2@cnLineLabelsOn        = False            ; turn off contour labels
res2@cnFillMode            = "AreaFill"     ; raster
res2@cnLevelSelectionMode  = "ExplicitLevels" ; explicit [unequal] cn levels
res2@gsnMaximize           = True             ; maximize size
res2@gsnSpreadColors       = True             ; use full range of colormap
res2@cnFillColors          = ahps_color_range  ; manual color selection
res2@mpOutlineOn = True
res2@mpOutlineDrawOrder = "PostDraw"
res2@lbLabelAngleF = 315.
res2@lbLabelJust   = "centerLeft"
res2@mpPerimOn         = True             ; turn off box around plot
res2@mpPerimDrawOrder = "PostDraw"

 plotdbz =gsn_csm_contour_map(wksdbz,dbz,res2)
draw(plotdbz)
frame(wksdbz)

delete(res2@cnlevels)

 
res2@tiMainString     =  time_valid_string  
res2@gsnLeftString    =  "2000-5000m Updraft Helicity"
res2@gsnRightString   = uh@units
res2@gsnScalarContour = True             ; enable contours
res2@gsnSpreadColors  = True             ; use full range of colors

delete(res2@cnLevels)

;;;;   res2@cnLevels_blanl              = round(fspan(25,250,15),0) ; contour/shade levels
res2@cnLevels              = round(fspan(25,250,15),0) ; contour/shade levels

res2@cnFillOn              = True             ; color plot desired
res2@cnLinesOn             = False            ; turn off contour lines
res2@cnLineLabelsOn        = False            ; turn off contour labels
res2@cnFillMode            = "AreaFill"     ; raster
res2@cnLevelSelectionMode  = "ExplicitLevels" ; explicit [unequal] cn levels


res2@cnFillOn              = True             ; color plot desired
res2@cnLinesOn             = False            ; turn off contour lines
res2@cnLineLabelsOn        = False            ; turn off contour labels
res2@cnFillMode            = "AreaFill"     ; raster

res2@gsnMaximize           = True             ; maximize size
res2@gsnSpreadColors       = True             ; use full range of colormap
;res2@cnFillColors          = ahps_color_range(0:max(res2@cnLevels))  ; manual color selection
res2@mpOutlineOn = True
res2@mpOutlineDrawOrder = "PostDraw"
res2@lbLabelAngleF = 315.
res2@lbLabelJust   = "centerLeft"
res2@mpPerimOn         = True             ; turn off box around plot
res2@mpPerimDrawOrder = "PostDraw"

 ;plotvhl =gsn_csm_contour_map(wksvhl,uh,res2)
;draw(plotvhl)
;frame(wksvhl)

delete(res2@cnlevels)
     delete(res2@cnFillColors)

   end do
   
   resP            = True                         ; modify the panel plot
   resP@txString         = time_valid_string
   resP@gsnLeftString    = " "
   resP@gsnRightString   = " "
   resP@gsnMaximize      = True
   resP@gsnOrientation   = "Landscape"
   resP@gsnPaperOrientation = "Landscape"
;   gsn_panel(wks,plot,(/2,ns/),resP) 
  

end do

 

  res2@tiMainString     =  time_valid_string  
     res2@gsnLeftString    =  "Total 36-hr Precip"
     res2@gsnRightString   = "in"
     res2@gsnScalarContour = True             ; enable contours
     res2@gsnSpreadColors  = True             ; use full range of colors

res2@cnLevels              = shading_contours ; contour/shade levels
res2@cnFillOn              = True             ; color plot desired
res2@cnLinesOn             = False            ; turn off contour lines
res2@cnLineLabelsOn        = False            ; turn off contour labels
res2@cnFillMode            = "AreaFill"     ; raster
res2@cnLevelSelectionMode  = "ExplicitLevels" ; explicit [unequal] cn levels
res2@gsnMaximize           = True             ; maximize size
res2@gsnSpreadColors       = False             ; use full range of colormap
res2@cnFillColors          = ahps_color_range  ; manual color selection
res2@mpOutlineOn = True
res2@mpOutlineDrawOrder = "PostDraw"
res2@lbLabelAngleF = 315.
res2@lbLabelJust   = "centerLeft"
res2@mpPerimOn         = True             ; turn off box around plot
res2@mpPerimDrawOrder = "PostDraw"


cnres2b@cnLevelSelectionMode = "ManualLevels"
cnres2b@cnLevelSelectionMode  = "ExplicitLevels" ; explicit [unequal] cn levels
cnres2b@cnHighLabelsOn             = False           ; mark your highs
cnres2b@cnLowLabelsOn              = False           ; same for lows
cnres2b@cnLevels               = (/ 0.0005 /) ; contour/shade levels
cnres2b@cnLineLabelStrings = (/"T"/)
cnres2b@cnLineLabelFontColor       = "Cyan"
cnres2b@cnLineColor           = "Cyan"
cnres2b@cnExplicitLineLabelsOn = True
cnres2b@cnLineThicknessF = 1.

;printVarSummary(total_precip)

 plottotalprec =gsn_csm_contour_map(wks3,total_precip,res2)
 plot_contours2b =  gsn_contour(wks3,total_precip,cnres2b)


     overlay(plottotalprec, plot_contours2b)
     draw(plottotalprec)
     frame(wks3)






;print("plotting final snowfall")

   

res2@tiMainString     =  time_valid_string  
res2@gsnLeftString    =  "Est. Total 36-hrly Snowfall"
res2@gsnRightString   = "in"
res2@gsnScalarContour = True             ; enable contours
res2@gsnSpreadColors  = True             ; use full range of colors

res2@cnLevels              = ahps_snow ; contour/shade levels
res2@cnFillOn              = True             ; color plot desired
res2@cnLinesOn             = False            ; turn off contour lines
res2@cnLineLabelsOn        = False            ; turn off contour labels
res2@cnFillMode            = "AreaFill"     ; raster
res2@cnLevelSelectionMode  = "ExplicitLevels" ; explicit [unequal] cn levels
res2@gsnMaximize           = True             ; maximize size
res2@gsnSpreadColors       = False             ; use full range of colormap
res2@cnFillColors          = ahps_color_range  ; manual color selection
res2@mpOutlineOn = True
res2@mpOutlineDrawOrder = "PostDraw"
res2@lbLabelAngleF = 315.
res2@lbLabelJust   = "centerLeft"
res2@mpPerimOn         = True             ; turn off box around plot
res2@mpPerimDrawOrder = "PostDraw"
  if (max(total_snow) .gt. 12) then
       res2@cnHighLabelsOn             = True           ; mark your highs
   end if
 plotsnowfall =gsn_csm_contour_map(wkssnoft,total_snow,res2)


draw(plotsnowfall)
frame(wkssnoft)
;print("plotted final snowfall")
     
     
system("convert -delay 100 " + full_png_dir + "/wrf_plot_PREC_"+domain + "_" + run_date +"*.png "+ full_png_dir + "/wrf_plot_PREC_"+domain + "_" + run_date+".gif")
system("convert -delay 100 " + full_png_dir + "/wrf_plot_SFC_"+domain + "_" + run_date +"*.png "+ full_png_dir + "/wrf_plot_SFC_"+domain + "_" + run_date+".gif")
system("convert -delay 100 " + full_png_dir + "/wrf_plot_SNOWFALL_"+domain + "_" + run_date +"*.png "+ full_png_dir + "/wrf_plot_SNOWFALL_"+domain + "_" + run_date+".gif")
system("convert -delay 100 " + full_png_dir + "/wrf_plot_DBZ_"+domain + "_" + run_date +"*.png "+ full_png_dir + "/wrf_plot_DBZ_"+domain + "_" + run_date+".gif")
;system("convert -delay 100 " + full_png_dir + "/wrf_plot_VHL_"+domain + "_" + run_date +"*.png "+ full_png_dir + "/wrf_plot_VHL_"+domain + "_" + run_date+".gif")


system("rm -fr "+ dir_png + "/currentRAP/wrf*"+domain+ "*")
system("cp -frv current_day.txt "+ dir_png + "/currentRAP/")
system("cp -frv /home/wjc/WRF_REALTIME/nudge.status.txt "+ dir_png + "/currentRAP/")


  system ("ln -sv " +  full_png_dir + "/wrf_plot_PREC_"+domain + "_" + run_date+".gif "+ dir_png + "/currentRAP/wrf_plot_PREC_"+domain+ ".gif")
  system ("ln -sv " +  full_png_dir + "/wrf_plot_SNOWFALL_"+domain + "_" + run_date+".gif "+ dir_png + "/currentRAP/wrf_plot_SNOWFALL_"+domain+ ".gif")
  system ("ln -sv " +  full_png_dir + "/wrf_plot_SFC_"+domain + "_" + run_date+".gif "+ dir_png + "/currentRAP/wrf_plot_SFC_"+domain+ ".gif")
  system ("ln -sv " +  full_png_dir + "/wrf_plot_DBZ_"+domain + "_" + run_date+".gif "+ dir_png + "/currentRAP/wrf_plot_DBZ_"+domain+ ".gif")
 ; system ("ln -sv " +  full_png_dir + "/wrf_plot_VHL_"+domain + "_" + run_date+".gif "+ dir_png + "/currentRAP/wrf_plot_VHL_"+domain+ ".gif")
  system ("ln -sv " +  full_png_dir + "/wrf_plot_TOTALPREC_"+domain + "_" + run_date+".png  "+ dir_png + "/currentRAP/wrf_plot_TOTALPREC_"+domain+ ".png")
  system ("ln -sv " +  full_png_dir + "/wrf_plot_TOTALSNOWFALL_"+domain + "_" + run_date+".png  "+ dir_png + "/currentRAP/wrf_plot_TOTALSNOWFALL_"+domain+ ".png")


 
  system ( "scp " +  full_png_dir + "/wrf_plot_PREC_"+domain + "_" + run_date+".gif "          + dir_url + "/wrf_plot_PREC_"+domain+ ".gif")
  system ( "scp " +  full_png_dir + "/wrf_plot_SNOWFALL_"+domain + "_" + run_date+".gif "      + dir_url + "/wrf_plot_SNOWFALL_"+domain+ ".gif")
  system ( "scp " +  full_png_dir + "/wrf_plot_SFC_"+domain + "_" + run_date+".gif "           + dir_url + "/wrf_plot_SFC_"+domain+ ".gif")
  system ( "scp " +  full_png_dir + "/wrf_plot_DBZ_"+domain + "_" + run_date+".gif "           + dir_url + "/wrf_plot_DBZ_"+domain+ ".gif")
 ; system ("scp " +  full_png_dir + "/wrf_plot_VHL_"+domain + "_" + run_date+".gif "           + dir_url + "/wrf_plot_VHL_"+domain+ ".gif")
  system ( "scp " +  full_png_dir + "/wrf_plot_TOTALPREC_"+domain + "_" + run_date+".png  "    + dir_url + "/wrf_plot_TOTALPREC_"+domain+ ".png")
  system ( "scp " +  full_png_dir + "/wrf_plot_TOTALSNOWFALL_"+domain + "_" + run_date+".png  "+ dir_url + "/wrf_plot_TOTALSNOWFALL_"+domain+ ".png")




;system ("rm -frv "+ full_png_dir + "/wrf_plot_PREC_"+domain + "_" + run_date +"*.png ")
;system ("rm -frv "+ full_png_dir + "/wrf_plot_SFC_"+domain + "_" + run_date +"*.png ")
;system ("rm -frv "+ full_png_dir + "/wrf_plot_DBZ_"+domain + "_" + run_date +"*.png ")
;system ("rm -frv "+ full_png_dir + "/wrf_plot_SNOWFALL_"+domain + "_" + run_date +"*.png ")



do t = 1, nt
sixnum =  sprinti("%0.6i", t)
system ("cp -frv "+ full_png_dir + "/wrf_plot_PREC_"+domain + "_" + run_date +"."+sixnum+ ".png " + dir_png + "/currentRAP/wrf_plot_PREC_"+domain+"."+sixnum+ ".png")
system ("cp -frv "+ full_png_dir + "/wrf_plot_SFC_"+domain + "_"  + run_date +"."+sixnum+ ".png " + dir_png + "/currentRAP/wrf_plot_SFC_"+domain+"."+sixnum+ ".png")
system ("cp -frv "+ full_png_dir + "/wrf_plot_DBZ_"+domain + "_"  + run_date +"."+sixnum+ ".png " + dir_png + "/currentRAP/wrf_plot_DBZ_"+domain+"."+sixnum+ ".png")
;system ("cp -frv "+ full_png_dir + "/wrf_plot_VHL_"+domain + "_"  + run_date +"."+sixnum+ ".png " + dir_png + "/currentRAP/wrf_plot_VHL_"+domain+"."+sixnum+ ".png")
system ("cp -frv "+ full_png_dir + "/wrf_plot_SNOWFALL_"+domain + "_" + run_date +"."+sixnum+ ".png " + dir_png + "/currentRAP/wrf_plot_SNOWFALL_"+domain+"."+sixnum+ ".png")

system  ("scp  "+ full_png_dir + "/wrf_plot_PREC_"+domain + "_" + run_date +"."+sixnum+ ".png "     + dir_url + "/wrf_plot_PREC_"+domain+"."+sixnum+ ".png")
system  ("scp  "+ full_png_dir + "/wrf_plot_SFC_"+domain + "_"  + run_date +"."+sixnum+ ".png "     + dir_url + "/wrf_plot_SFC_"+domain+"."+sixnum+ ".png")
system  ("scp  "+ full_png_dir + "/wrf_plot_DBZ_"+domain + "_"  + run_date +"."+sixnum+ ".png "     + dir_url + "/wrf_plot_DBZ_"+domain+"."+sixnum+ ".png")
;system ("scp  "+ full_png_dir + "/wrf_plot_VHL_"+domain + "_"  + run_date +"."+sixnum+ ".png "     + dir_url + "/wrf_plot_VHL_"+domain+"."+sixnum+ ".png")
system ( "scp  "+ full_png_dir + "/wrf_plot_SNOWFALL_"+domain + "_" + run_date +"."+sixnum+ ".png " + dir_url + "/wrf_plot_SNOWFALL_"+domain+"."+sixnum+ ".png")



end do



;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;do t = 1, nt-1
;   do s = 0, ns-1
;      result = systemfunc("gzip -v9 "+wrf_file(s,t))
;   end do
;end do

end

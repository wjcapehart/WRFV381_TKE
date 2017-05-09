


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
 
  dir_local = "./"
;  dir_wrf   = "./"
;  dir_png   = "./"
    
  time = ispan(0,hours_in_a_forecast ,1)
  
;  ens_dir  = (/ "WRF32_KUNR_3DOM_WSM6_NOAH_MYNN2_KF2_DUDHIA_NARRFNL-09km_150x150/"    /)
;    ens_dir  = (/ "./"    /)

  ens_dir  = (/ "WRF36_KUNR_3DOM_WSM6_NOAH_MYNN2_KF2_DUDHIA_NAM218-09km_150x150/"    /)

domains = (/  "d02", "d01" /)

do  dd = 0,0


    d0n = domains(dd)
domain = d0n

  nt = dimsizes(time)
  deltat = time(1)-time(0)


  
 ; print("cat " + dir_local + "current_day.txt")
   run_date = systemfunc("cat " + dir_local + "current_day.txt")
   print(run_date)
   
 full_png_dir = dir_png +"/"+run_date+"/"+domain

  system("mkdir -v "+dir_png +"/"+run_date)

  system("mkdir -v "+ full_png_dir )


  wrf_file = new( (/ nt/),  string)
  
  
  wks  = gsn_open_wks(output_format ,full_png_dir + "/wrf_plot_PBL_" +domain + "_" + run_date )      


gsn_define_colormap(wks,"WhViBlGrYeOrRe")

   
   minpbl = 99999999999.
   maxpbl = -minpbl

   do t = 0, nt-1
        wrf_file(t) = dir_wrf + ens_dir + "/wrfout_" + d0n + "_" + run_date + "_F" + sprinti("%0.2i",time(t))  + ".nc"
        
        result = systemfunc("gunzip -frv "+wrf_file(t)+".gz") 


        f = addfile(wrf_file(t), "r")

            pbl = wrf_user_getvar(f,"PBLH",0)
            
            maxpbl = max( (/ maxpbl,  max(pbl) /) )
            minpbl = min( (/ minpbl, min(pbl) /) )


   end do
   
   maxpbl=round(maxpbl/10,0)*10
   print(maxpbl)
print(minpbl)

  
   do t = 0, nt-1
   
        wrf_file(t) = dir_wrf + ens_dir + "/wrfout_" + d0n + "_" + run_date + "_F" + sprinti("%0.2i",time(t))  + ".nc"
        


        f = addfile(wrf_file(t), "r")
            time_zero_string = chartostring(f->Times )

           ;time_zero_string)

           time_unit = "hours since "+time_zero_string +"z"
           time@units = time_unit
           time!0     = "time"
           time&time  = time
           time@long_name = "time"
       

         ;  print(time)
           
           time_chars = f->Times
      
           time_valid = chartostring(time_chars(:,0:12)) + " UTC"
            
           time_valid_string =  sprinti("SDSMT WRF %0.2i-hr Fx Valid @ ",time(t)) + time_valid
      
         ;  print(time_valid_string)

        lon2d   = wrf_user_getvar(f,"lon",0)
        lat2d   = wrf_user_getvar(f,"lat",0)
        terrain = wrf_user_getvar(f,"ter",0)
        landuse = wrf_user_getvar(f,"LU_INDEX",0)
	
   
        waterindex = f@ISWATER
        iceindex   = f@ISICE
   
   
        terrain@lon2d = lon2d
        terrain@lat2d = lat2d
   
        nynx = dimsizes(terrain)
      ;  print(nynx)
   
        ny = nynx(0)
        nx = nynx(1)
        

        
        res = True
        wrf_mapres_c(f, res, 0)
            
      res@mpProjection             = "LambertConformal"
	  res@mpLambertParallel1F      = f@TRUELAT1
	  res@mpLambertParallel2F      = f@TRUELAT2
	  res@mpLambertMeridianF       = f@CEN_LON
	  res@mpLimitMode              = "Corners"  
	  res@mpLeftCornerLatF         = lat2d(0,0)
	  res@mpLeftCornerLonF         = lon2d(0,0)
	  res@mpRightCornerLatF        = lat2d(ny-1,nx-1)
	  res@mpRightCornerLonF        = lon2d(ny-1,nx-1)
            res@mpOutlineBoundarySets =	"AllBoundaries"
            res@mpOutlineBoundarySets = "AllBoundaries" ; all boundaries
            res@mpDataBaseVersion     = "Ncarg4_1"
            res@mpDataSetName         = "Earth..4"
            
            res@mpGeophysicalLineColor = "white"
             res@mpUSStateLineColor = "white"
            res@mpNationalLineColor = "white"
            res@mpGeophysicalLineColor = "white"
            res@mpGeophysicalLineColor = "white"
           
      res@pmLabelBarOrthogonalPosF = -0.05          ; Move labelbar closer to plo
       res@lbLabelFontHeightF           =0.02

      res@mpOutlineBoundarySets       = "AllBoundaries" ; all boundaries
      res@pmLabelBarOrthogonalPosF    = -0.05          ; Move labelbar closer to plo
      res@mpNationalLineThicknessF    =  2.0
      res@mpGeophysicalLineThicknessF = 4.0
      res@mpUSStateLineThicknessF     = 4.0

res@cnInfoLabelOn=False
        
 ;       print(res)


        print(time_zero_string+ " " )

        time_unit = "hours since "+time_zero_string +"z"
        time@units = time_unit
        time!0     = "time"
        time&time  = time
        time@long_name = "time"
        
    ;    print(time)

        Times = f->Times                    ; Times(Time, DateStrLen)    (type character)

        Time_s = chartostring( Times )      ; string

        
                ;printVarSummary(landuse)
                ;printVarSummary(terrain)


      ;  print(iceindex)
      ;  print(waterindex)
      ;  print(max(landuse))
        
        temparray = ind((ndtooned(landuse) .eq. waterindex) .or. (ndtooned(landuse) .eq. iceindex) ) 

       ; print(temparray)
    
        wherewet = ind_resolve(temparray , nynx)
        minterrain = min(terrain)
   
  
        if (.not.all(ismissing(wherewet(0,0))))
          ; print(waterindex)
          ; print(wherewet)
           dim_ida  = dimsizes(wherewet)     
           npts     = dim_ida(0)       ; number of elements > 5 (here 9)
           ndim     = dim_ida(1)       ; rank of "a"  (here 3)
           do n=0,npts-1
              terrain(wherewet(n,0),wherewet(n,1)) = minterrain-150
           end do
        else
           delete(wherewet)
           delete(dim_ida)
           delete(npts)
           delete(ndim)
           wherewet = ind_resolve(ind(ndtooned(terrain) .eq. minterrain), nynx)
           dim_ida  = dimsizes(wherewet)     
           npts     = dim_ida(0)       ; number of elements > 5 (here 9)
           ndim     = dim_ida(1)       ; rank of "a"  (here 3)
           ;print(waterindex)
           ;print(wherewet)
           do n=0,npts-1
              terrain(wherewet(n,0),wherewet(n,1)) = minterrain+100
           end do
           
        end if
        delete(temparray)
   
        res@cnFillOn             = True               ; turn on color for contours
        res@cnLinesOn            = False              ; turn off contour lines
        res@cnLineLabelsOn       = False              ; turn off contour line labels
        res@cnFillMode           = "RasterFill"
   
        res@gsnSpreadColors      = True               ; use full color map

        res@lbTitleOn = False
        res@lbTitleString = " "

        Times = f->Times                    ; Times(Time, DateStrLen)    (type character)

        Time_s = chartostring( Times )      ; string

   
         pbl = wrf_user_getvar(f,"PBLH",0)
	 
        
           
         pbl@lon2d = lon2d
         pbl@lat2d = lat2d
         
         res@gsnMaximize  = True         ; maximize size
         res@gsnBoxMargin = 0            ; no box margin
       ;  res@tiMainFont   = "helvetica"  ; set default font
     
        res@lbLabelAutoStride = False
        res@lbLabelStride = 2
              res@tiMainString     =  time_valid_string 
          print(domain+  " " + time_valid_string)
         res@gsnLeftString    = "Model-Estimated PBL Height"
         res@gsnRightString   ="m"
         
  

   
     res@cnLevelSelectionMode       = "ManualLevels" ; manual contour levels
     res@cnLevelSpacingF            =  (5000-250)/19         ; contour interval
     res@cnMinLevelValF             =  250; minpbl           ; min level
     res@cnMaxLevelValF             =  5000; maxpbl           ; max level
     res@pmLabelBarOrthogonalPosF   = -0.05          ; Move labelbar closer to plo
     res@lbLabelAngleF              = 315.
     res@lbLabelJust                = "centerLeft"
     res@cnHighLabelsOn             = False           ; mark your highs
     res@cnLowLabelsOn              = False           ; same for lows



         plot = gsn_csm_contour_map(wks,pbl, \
                                             res)
                                              
  


         
         delete(res)
         delete(terrain)
         delete(landuse)
         delete(pbl)
         delete(lon2d)
         delete(lat2d)
         delete(wherewet)  



      end do  ; t-loop
      
  system("convert -verbose -delay 100 " + full_png_dir + "/wrf_plot_PBL_"+domain + "_" + run_date +"*.png "+ full_png_dir + "/wrf_plot_PBL_"+domain + "_" + run_date+".gif")
  system("rm -frv  "+ dir_png + "/currentRAP/wrf_plot_PBL_"+domain+ ".gif")
  system ("ln -sv " +  full_png_dir + "/wrf_plot_PBL_"+domain + "_" + run_date+".gif "+ dir_png + "/currentRAP/wrf_plot_PBL_"+domain+ ".gif")
  system ("scp  " +  full_png_dir + "/wrf_plot_PBL_"+domain + "_" + run_date+".gif "+ dir_url + "/wrf_plot_PBL_"+domain+ ".gif")

;   system(" rm -fr " + full_png_dir + "/wrf_plot_PBL_"+domain + "_" + run_date +"*.png ")



do t = 1, nt
sixnum =  sprinti("%0.6i", t)
system ("cp -frv "+ full_png_dir + "/wrf_plot_PBL_"+domain + "_" + run_date +"."+sixnum+ ".png "+ dir_png + "/currentRAP/wrf_plot_PBL_"+domain+"."+sixnum+ ".png")
system ("scp  "+ full_png_dir + "/wrf_plot_PBL_"+domain + "_" + run_date +"."+sixnum+ ".png "+ dir_url + "/wrf_plot_PBL_"+domain+"."+sixnum+ ".png")

end do

print(maxpbl)
print(minpbl)


end do
end




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; NCL Libraries
;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/skewt_func.ncl"

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


krap_lat =  44.072965
krap_lon = -103.210173

lats = (/ krap_lat /)
lons = (/ krap_lon /)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; File Control (default directory location of netCDF file)
;
  dir_local = "/home/wjc/WRF_REALTIME_KUNR-3DOM/"
  dir_wrf   = "/cyclone1/WRF_REALTIME/OUTPUT/"
  dir_png   = "/projects/WRF_REALTIME/OUTPUT_PNG/"
  dir_url = "wjc@kyrill:/var/www/html/firemet/wrf_rap/"

 
;  dir_local = "./"
;  dir_wrf   = "./"
;  dir_png   = "./"
    
  time = ispan(0,hours_in_a_forecast,1)
  
;  ens_dir  = (/ "WRF32_KUNR_3DOM_WSM6_NOAH_MYNN2_KF2_DUDHIA_NARRFNL-09km_150x150/"    /)
;    ens_dir  = (/ "./"    /)
  ens_dir  = (/ "WRF36_KUNR_3DOM_WSM6_NOAH_MYNN2_KF2_DUDHIA_NAM218-09km_150x150/"    /)

domains = (/ "d02" /) ;, "d02", "d01" /)

;do  dd = 0, 0

dd  = 0

    d0n = domains(dd)
   domain = d0n

   nt = dimsizes(time)
   deltat = time(1)-time(0)


  
  ; print("cat " + dir_local + "current_day.txt")
   run_date = systemfunc("cat " + dir_local + "current_day.txt")
  ; print(run_date)
   
   full_png_dir = dir_png +"/"+run_date+"/"+domain

   system("mkdir -v "+dir_png +"/"+run_date)

   system("mkdir -v "+ full_png_dir )


   wrf_file = new( (/ nt/),  string)
  
  
   wks  = gsn_open_wks(output_format ,full_png_dir + "/wrf_plot_SKEWT_" +domain + "_" + run_date )      


colors = (/"white","black","White","Green4","Green3","Green2","Green1","darkseagreen1",\
           "Green","Black","Orange","Brown","greenyellow","darkgreen","PaleGreen","sienna","tan4","brown","forestgreen",\
           "SeaGreen","SeaGreen2","Blue","Grey65","Red","Tan4","Sienna","palegreen",\
           "Pink","Tan","OliveDrab1","ForestGreen","DarkGreen","RoyalBlue","DarkOliveGreen1"/)
  gsn_define_colormap(wks, colors)  

  
   do t = 0, nt-1
   
        wrf_file(t) = dir_wrf + ens_dir + "/wrfout_" + d0n + "_" + run_date + "_F" + sprinti("%0.2i",time(t))  + ".nc"
        
        result = systemfunc("gunzip -frv "+wrf_file(t)+".gz") 


        f = addfile(wrf_file(t), "r")
        time_zero_string = chartostring(f->Times )

     ;   print(time_zero_string)

        time_unit = "hours since "+time_zero_string +"z"
        time@units = time_unit
        time!0     = "time"
        time&time  = time
        time@long_name = "time"
       

     ;   print(time)
        
        time_chars = f->Times
      
        time_valid = chartostring(time_chars(:,0:12)) + " UTC"
            
        time_valid_string =  sprinti("SDSMT WRF @ KUNR %0.2i-hr Fx Valid @ ",time(t)) + time_valid
      
     ;   print(time_valid_string)

    
    
        tc_00    = wrf_user_getvar(f,"tc",0)         ; T in C
    
        if (t .eq. 0) then
        
           lon2d    = wrf_user_getvar(f,"lon",0)         ; T in C
           lat2d    = wrf_user_getvar(f,"lat",0)         ; T in C

    
           nynx = dimsizes(tc_00)
   
           nz  = nynx(0)
           ny = nynx(1)
           nx = nynx(2)
        
           tc = new( (/ nt,nz,ny,nx  /) , float)
           td = tc
           z  = tc
           u  = tc
           v  = tc
           p  = tc
           
           ; loc(1,:) is south-north (y) and loc(0,:) is west-east (x)
           locs = wrf_user_ll_to_ij(f, lons, lats, True)

           ; Remove the data points outside our model domain
           num_st = dimsizes(lons)

           loc1D = ndtooned(locs)
           indloc = ind(.not. ismissing(loc1D))
           loc1D_new = loc1D(indloc)
           num_st = num(.not. ismissing(locs))/2
           loc = new( (/2/), typeof(locs) )
           loc = onedtond(loc1D_new,dimsizes(loc))
           loc = loc - 1    ; location in NCL space to use as array indeses

           ip = 0
        end if
    
       tc(t,:,:,:)  = wrf_user_getvar(f, "tc",      0)         ; T in C
        td(t,:,:,:)  = wrf_user_getvar(f, "td",      0)         ; dew point temperature
        p(t,:,:,:)   = wrf_user_getvar(f, "pressure",0)  ; grid point pressure
        z(t,:,:,:)   = wrf_user_getvar(f, "z",       0)         ; grid point height
        uvm          = wrf_user_getvar(f, "uvmet",   0)      ; umet and vmet averaged to mass points
        u(t,:,:,:)   = uvm(0,:,:,:)*1.94386
        v(t,:,:,:)   = uvm(1,:,:,:)*1.94386
   
       
        time_unit = "hours since "+time_zero_string +"z"
        time@units = time_unit
        time!0     = "time"
        time&time  = time
        time@long_name = "time"
        

        Times = f->Times                    ; Times(Time, DateStrLen)    (type character)
        Time_s = chartostring( Times )      ; string

           
      
      


  ;      Define a few skew-T plotting options
         skewtOpts          = True
         
skewtOpts@gsnDraw             = False
skewtOpts@gsnFrame           = False
         skewtOpts@DrawHeightScale   = True    ; plot height scale on side
         skewtOpts@DrawHeightScaleFt = False   ; plot height scale in km
         skewtOpts@DrawStandardAtm   = True    ; draw standard atm on plot
         skewtOpts@vpXF              = 0.12    ; controls off-set from left
         skewtOpts@vpYF              = 0.87    ; controls off-set from top
         skewtOpts@vpWidthF          = 0.75    ; controls size of plot
         skewtOpts@vpHeightF         = 0.75    ; controls size of plot
         skewtOpts@DrawFahrenheit    = False   ; use deg C scale
         skewtOpts@tiMainFontHeightF = 0.015   ; change height of main title
        ;skewtOpts@DrawColLine       = False   ; draw lines in black
         skewtOpts@DrawColAreaFill   = True    ; color on background plot
        ;skewtOpts@DrawColAreaColor  = "Green" ; final color may depend on the color table used
         skewtOpts@DrawColAreaColor  = 53      ; Light Green for WhViBlGrYeOrReWh color table
         skewtOpts@PrintOpts         = False   ; do not print options out
         maximize_output(wks,skewtOpts)

  ;      Get the skew-T background
         skewtOpts@tiMainString = time_valid_string
         skewt_bkgd             = skewT_BackGround (wks, skewtOpts)

         draw (skewt_bkgd)


  ;      Draw the skew-T plot
         dataOpts           = True
         dataOpts@Parcel    = 1
         dataOpts@WspdWdir  = False  ; wind speed and dir [else: u,v]
         dataOpts@HspdHdir  = True   ; wind speed and dir [else: u,v]
         dataOpts@PlotWindH = False  ; plot wind barbs at h lvls [pibal; special]
         skewT_data = skewT_PlotData(wks, skewt_bkgd, p(t,:,loc(1),loc(0)), \
                                                     tc(t,:,loc(1),loc(0)), \
                                                     td(t,:,loc(1),loc(0)), \
                                                      z(t,:,loc(1),loc(0)), \
                                                      u(t,:,loc(1),loc(0)), \
                                                      v(t,:,loc(1),loc(0)), \
                                                      dataOpts)

  ;      Close the frame

         draw (skewt_bkgd)
         draw (skewT_data)

         frame(wks)

         delete(skewtOpts)
         delete(dataOpts)
         delete(skewT_data)
         delete(skewt_bkgd)

      
      
      



      end do  ; t-loop
      
  system("convert -verbose -delay 100 " + full_png_dir + "/wrf_plot_SKEWT_"+domain + "_" + run_date +"*.png "+ full_png_dir + "/wrf_plot_SKEWT_"+domain + "_" + run_date+".gif")
  system("rm -frv  "+ dir_png + "/currentRAP/wrf_plot_SKEWT_"+domain+ ".gif")
  system ("ln -sv " +  full_png_dir + "/wrf_plot_SKEWT_"+domain + "_" + run_date+".gif "+ dir_png + "/currentRAP/wrf_plot_SKEWT_"+domain+ ".gif")
print("Sending Files to "+dir_url)
  system("scp  " +  full_png_dir + "/wrf_plot_SKEWT_"+domain + "_" + run_date+".gif "+ dir_url + "/wrf_plot_SKEWT_"+domain+ ".gif")

;  system("rm -frv " + full_png_dir + "/wrf_plot_SKEWT_"+domain + "_" + run_date +"*.png ")


do t = 1, nt
sixnum =  sprinti("%0.6i", t)
system ("cp -frv "+ full_png_dir + "/wrf_plot_SKEWT_"+domain + "_" + run_date +"."+sixnum+ ".png "+ dir_png + "/currentRAP/wrf_plot_SKEWT_"+domain+"."+sixnum+ ".png")
print("Sending File to "+dir_url)

system ("scp "+ full_png_dir + "/wrf_plot_SKEWT_"+domain + "_" + run_date +"."+sixnum+ ".png "+ dir_url + "/wrf_plot_SKEWT_"+domain+"."+sixnum+ ".png")

end do



;end do
end

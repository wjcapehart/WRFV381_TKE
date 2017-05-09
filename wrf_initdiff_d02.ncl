

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

;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; File Control (default directory location of netCDF file)
;
dir_wrf       = "/home/wjc/WRF_REALTIME/WRFV360/WRFV3/test/em_real/"
dir_wrf_root  = "/home/wjc/WRF_REALTIME/"

dir_png       = "/projects/WRF_REALTIME/OUTPUT_PNG/"
  dir_url = "wjc@kyrill:/var/www/html/firemet/wrf_rap/"

run_date = systemfunc("cat " + dir_wrf_root + "current_day.txt")
  
domain = "d02"

full_png_dir  = "/projects/WRF_REALTIME/OUTPUT_PNG/"+run_date+"/"+domain


file_wrf = dir_wrf + "./wrfinput_"+ domain + ".wrfinit.nc"
file_nmc = dir_wrf + "./wrfinput_"+ domain + ".nmcinit.nc"
file_var = dir_wrf + "./wrfinput_"+ domain + ".varinit.nc"

plot = new(3, graphic)

have_var = False
have_wrf = False
have_nmc = False

if (isfilepresent(file_var)) then
   f_var = addfile(file_var, "r")
   have_var = True
end if

if (isfilepresent(file_wrf)) then
   f_wrf = addfile(file_wrf, "r")
   have_wrf = True
end if

if (isfilepresent(file_nmc)) then
   f_nmc = addfile(file_nmc, "r")
   have_nmc = True
end if

print(have_var)
print(have_nmc)
print(have_wrf)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Open Plotting Device for Graphics Output and Set Color Table
;
  wks  = gsn_open_wks(output_format ,full_png_dir + "/wrf_plot_INITDIF_" +domain + "_" + run_date )      

  gsn_define_colormap(wks,"BlWhRe")

;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Get Base Data
;


if (have_var) then

      ua_var = wrf_user_getvar(f_var,"ua",0)          ; u averaged to mass points
      va_var = wrf_user_getvar(f_var,"va",0)          ; v averaged to mass points
      ta_var = wrf_user_getvar(f_var,"tk",0)          ; t averaged to mass points
   
      lat2d   = f_var->XLAT(0,:,:)
      lon2d   = f_var->XLONG(0,:,:)   

      ua_var@lon2d = lon2d
      va_var@lon2d = lon2d
      ta_var@lon2d = lon2d

      ua_var@lat2d = lat2d
      va_var@lat2d = lat2d
      ta_var@lat2d = lat2d
         
end if


if (have_wrf) then

      ua_wrf = wrf_user_getvar(f_wrf,"ua",0)          ; u averaged to mass points
      va_wrf = wrf_user_getvar(f_wrf,"va",0)          ; v averaged to mass points
      ta_wrf = wrf_user_getvar(f_wrf,"tk",0)          ; t averaged to mass points
   
      lat2d   = f_wrf->XLAT(0,:,:)     
      lon2d   = f_wrf->XLONG(0,:,:)   
      
      ua_wrf@lon2d = lon2d
      va_wrf@lon2d = lon2d
      ta_wrf@lon2d = lon2d

      ua_wrf@lat2d = lat2d
      va_wrf@lat2d = lat2d
      ta_wrf@lat2d = lat2d
         
end if

if (have_nmc) then

      ua_nmc = wrf_user_getvar(f_nmc,"ua",0)          ; u averaged to mass points
      va_nmc = wrf_user_getvar(f_nmc,"va",0)          ; v averaged to mass points
      ta_nmc = wrf_user_getvar(f_nmc,"tk",0)          ; t averaged to mass points
   
      lat2d   = f_nmc->XLAT(0,:,:)     
      lon2d   = f_nmc->XLONG(0,:,:)   
         
      ua_nmc@lon2d = lon2d
      va_nmc@lon2d = lon2d
      ta_nmc@lon2d = lon2d

      ua_nmc@lat2d = lat2d
      va_nmc@lat2d = lat2d
      ta_nmc@lat2d = lat2d

end if

nynx = dimsizes(lon2d)
ny = nynx(0)
nx = nynx(1)

;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Initialize Error Matricies
;
      ta_wrf_nmc = ta_nmc(0,:,:)
      ta_var_nmc = ta_nmc(0,:,:)
      ta_var_wrf = ta_nmc(0,:,:)
      
      ta_wrf_nmc@description = "REC-NAM T Diff"
      ta_var_nmc@description = "WRF-NAM T Diff"
      ta_var_wrf@description = "WRF-REC T Diff"


      ua_wrf_nmc = ua_nmc(0,:,:)
      ua_var_nmc = ua_nmc(0,:,:)
      ua_var_wrf = ua_nmc(0,:,:)

      ua_wrf_nmc@description = "REC-NAM U Diff"
      ua_var_nmc@description = "WRF-NAM U Diff"
      ua_var_wrf@description = "WRF-REC U Diff"

      ua_wrf_nmc@units = "kt"
      ua_var_nmc@units = "kt"
      ua_var_wrf@units = "kt"

      va_wrf_nmc = va_nmc(0,:,:)
      va_var_nmc = va_nmc(0,:,:)
      va_var_wrf = va_nmc(0,:,:)

      va_wrf_nmc@units = "kt"
      va_var_nmc@units = "kt"
      va_var_wrf@units = "kt"

;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Calculate Errors
;

   if (have_wrf .and. have_nmc) then
   
         ta_wrf_nmc(:,:) = (/ ta_wrf(0,:,:) - ta_nmc(0,:,:) /)
         ua_wrf_nmc(:,:) = (/ ua_wrf(0,:,:) - ua_nmc(0,:,:) /) * 1.94384
         va_wrf_nmc(:,:) = (/ va_wrf(0,:,:) - va_nmc(0,:,:) /) * 1.94384
         
   end if

   if (have_var .and. have_nmc) then

         ta_var_nmc(:,:) = (/ ta_var(0,:,:) - ta_nmc(0,:,:) /)
         ua_var_nmc(:,:) = (/ ua_var(0,:,:) - ua_nmc(0,:,:) /) * 1.94384
         va_var_nmc(:,:) = (/ va_var(0,:,:) - va_nmc(0,:,:) /) * 1.94384
         
   end if

   if (have_wrf  .and. have_var) then

         ta_var_wrf(:,:) = ta_var(0,:,:) - ta_wrf(0,:,:)
         ua_var_wrf(:,:) = (/ ua_var(0,:,:) - ua_wrf(0,:,:) /) * 1.94384
         va_var_wrf(:,:) = (/ va_var(0,:,:) - va_wrf(0,:,:) /) * 1.94384
         
   end if

;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Get Mapping Data
;

   resproj = True
      resproj@mpFillOn                 = False       ; turn off map fill
      resproj@mpProjection             = "LambertConformal"
	  resproj@mpLambertParallel1F      = f_nmc@TRUELAT1
	  resproj@mpLambertParallel2F      = f_nmc@TRUELAT2
	  resproj@mpLambertMeridianF       = f_nmc@CEN_LON
	  resproj@mpLimitMode              = "Corners"  
	  resproj@mpLeftCornerLatF         = lat2d(0,0)
	  resproj@mpLeftCornerLonF         = lon2d(0,0)
	  resproj@mpRightCornerLatF        = lat2d(ny-1,nx-1)
	  resproj@mpRightCornerLonF        = lon2d(ny-1,nx-1)
      resproj@pmLabelBarOrthogonalPosF = -0.05          ; Move labelbar closer to plo
      resproj@mpOutlineOn = True
 

      resproj@mpOutlineBoundarySets = "AllBoundaries" ; all boundaries
      resproj@mpDataBaseVersion     = "Ncarg4_1"
      resproj@mpDataSetName         = "Earth..4"
      resproj@lbLabelFontHeightF    =0.02

      resproj@mpOutlineBoundarySets       = "AllBoundaries" ; all boundaries
      resproj@pmLabelBarOrthogonalPosF    = -0.05          ; Move labelbar closer to plo
      resproj@mpNationalLineThicknessF    =  1.0
      resproj@mpGeophysicalLineThicknessF = 1.0
      resproj@mpUSStateLineThicknessF     = 2.0

;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Create REC vs NMC plot
;
if (have_wrf .and. have_nmc) then

    var_t = ta_wrf_nmc
    var_u = ua_wrf_nmc
    var_v = va_wrf_nmc
    
    res = resproj
    res@gsnLeftString = "REC vs NMC T & Wind Diffs"
    res@gsnRightString = "K, kts"
    res@gsnDraw             = False            ; Turn off draw.
    res@gsnFrame            = False             ; Turn off frame advance.
    res@gsnMaximize         = True

    res@vcGlyphStyle          = "WindBarb"
    res@vcRefLengthF          = 0.025            ; ref vec length
    res@vcMinDistanceF        = 0.025            ; larger means sparser
    res@vcWindBarbTickLengthF = 0.4              ; default 0.3
    res@vcRefAnnoOn           = False


    res@gsnScalarContour = True             ; enable contours
    res@gsnSpreadColors  = True             ; use full range of colors

    res@cnLineLabelsOn       = True             ; turn on line labels
    res@cnFillOn             = True             ; color plot desired
    res@cnLinesOn            = False            ; turn off contour lines
    res@cnFillMode           = "RasterFill"     ; raster
    res@cnLineLabelsOn       = False            ; turn off contour labels
    res@lbLabelAutoStride    = True             ; skip legend labels as needed

    res@cnLevelSelectionMode       = "ManualLevels" ; manual contour levels
    res@cnMinLevelValF             = -round(max(abs(var_t)),0)         ; min level
    res@cnMaxLevelValF             =  round(max(abs(var_t)),0)         ; min level
    ;res@cnLevelSpacingF            = ceil((res1@cnMaxLevelValF-res1@cnMinLevelValF)/14.)          ; contour interval

    plot(0) = gsn_csm_vector_scalar_map(wks,var_u,var_v,var_t,res)
    
end if

;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Create WRF vs NMC plot
;

if (have_var .and. have_nmc) then

    var_t = ta_var_nmc
    var_u = ua_var_nmc
    var_v = va_var_nmc
    
    res = resproj
    res@gsnLeftString = "WRF vs NMC T & Wind Diffs"
    res@gsnRightString = "K, kts"
    res@gsnDraw             = False            ; Turn off draw.
    res@gsnFrame            = False             ; Turn off frame advance.
    res@gsnMaximize         = True

    res@vcGlyphStyle          = "WindBarb"
    res@vcRefLengthF          = 0.025            ; ref vec length
    res@vcMinDistanceF        = 0.025            ; larger means sparser
    res@vcWindBarbTickLengthF = 0.4              ; default 0.3
    res@vcRefAnnoOn           = False


    res@gsnScalarContour = True             ; enable contours
    res@gsnSpreadColors  = True             ; use full range of colors

    res@cnLineLabelsOn       = True             ; turn on line labels
    res@cnFillOn             = True             ; color plot desired
    res@cnLinesOn            = False            ; turn off contour lines
    res@cnFillMode           = "RasterFill"     ; raster
    res@cnLineLabelsOn       = False            ; turn off contour labels
    res@lbLabelAutoStride    = True             ; skip legend labels as needed

    res@cnLevelSelectionMode       = "ManualLevels" ; manual contour levels
    res@cnMinLevelValF             = -round(max(abs(var_t)),0)         ; min level
    res@cnMaxLevelValF             =  round(max(abs(var_t)),0)         ; min level
    ;res@cnLevelSpacingF            = ceil((res1@cnMaxLevelValF-res1@cnMinLevelValF)/14.)          ; contour interval

    plot(1) = gsn_csm_vector_scalar_map(wks,var_u,var_v,var_t,res)

end if

;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Create WRF vs REC plot
;

if (have_var .and. have_wrf) then

    var_t = ta_var_wrf
    var_u = ua_var_wrf
    var_v = va_var_wrf
    
    res = resproj
    res@gsnLeftString = "WRF vs REC T & Wind Diffs"
    res@gsnRightString = "K, kts"
    res@gsnDraw             = False            ; Turn off draw.
    res@gsnFrame            = False             ; Turn off frame advance.
    res@gsnMaximize         = True

    res@vcGlyphStyle          = "WindBarb"
    res@vcRefLengthF          = 0.025            ; ref vec length
    res@vcMinDistanceF        = 0.025            ; larger means sparser
    res@vcWindBarbTickLengthF = 0.4              ; default 0.3
    res@vcRefAnnoOn           = False


    res@gsnScalarContour = True             ; enable contours
    res@gsnSpreadColors  = True             ; use full range of colors

    res@cnLineLabelsOn       = True             ; turn on line labels
    res@cnFillOn             = True             ; color plot desired
    res@cnLinesOn            = False            ; turn off contour lines
    res@cnFillMode           = "RasterFill"     ; raster
    res@cnLineLabelsOn       = False            ; turn off contour labels
    res@lbLabelAutoStride    = True             ; skip legend labels as needed

    res@cnLevelSelectionMode       = "ManualLevels" ; manual contour levels
    res@cnMinLevelValF             = -round(max(abs(var_t)),0)         ; min level
    res@cnMaxLevelValF             =  round(max(abs(var_t)),0)         ; min level
    ;res@cnLevelSpacingF            = ceil((res1@cnMaxLevelValF-res1@cnMinLevelValF)/14.)          ; contour interval

    plot(2) = gsn_csm_vector_scalar_map(wks,var_u,var_v,var_t,res)

end if

;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Pannel Them
;

   resP                  = True   ; modify the panel plot
   resP@txString         = "Domain "+domain+" Assimilation Comparisons for "+ run_date
   resP@gsnLeftString    = " "
   resP@gsnRightString   = " "
   resP@gsnMaximize      = True
   resP@gsnOrientation   = "Landscape"
   resP@gsnPaperOrientation = "Landscape"

    gsn_panel(wks,plot,(/2,2/),resP) 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

     
system("rm -fv "+dir_png + "/currentRAP/wrf_plot_INITDIF_"+domain+ ".png")
system("ln -sv " +  full_png_dir + "/wrf_plot_INITDIF_" +domain + "_" + run_date+".png  "+ dir_png + "/currentRAP/wrf_plot_INITDIF_"+domain+ ".png")
system("scp  " +  full_png_dir + "/wrf_plot_INITDIF_" +domain + "_" + run_date+".png  "+ dir_url + "/wrf_plot_INITDIF_"+domain+ ".png")



end

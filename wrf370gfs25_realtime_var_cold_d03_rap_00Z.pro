;
;   USER MODIFICATION
;
 time_start_in_sec = systime(/seconds)

   WRF_OUTSTORE         = "/projects/biomimicry/WRF_RT_OUTPUT/NAM02"
   wrf_home_dir         = "/home/wcapehart/WRFV381_TKE/"
   wrf_version          = "WRFV381"
   wrf_program_root_dir = wrf_home_dir + wrf_version+"/"
   wrfda_obsproc_exe    = wrf_program_root_dir + "WRFDA/var/obsproc/src/obsproc.exe "

   WRFVERSION     = 3L   ;       (version of WRF)

   GRIB_DT        = 01L ; HOURS (timestep for WRF Input Data)
   WRFOUT_DT      = 01L ; HOURS (timestep for WRF Output Data)
   WRFOUT_DT3     = 01L ; HOURS (timestep for WRF Output Data)
   NUDGING_PERIOD = 03L ; hOURS

  SHORTRUN_DT =   36L ; HOURS (numbers of hours for a single WRF run)
   WRF_RUN_INTERVAL = 24L ; HOURS (numbers of hours  between WRF run)



      systime_start = systime(/UTC,/JULIAN)
        systime_end = systime(/UTC,/JULIAN)+1

   CALDAT, systime_start,  START_MONTH, START_DAY, START_YEAR
   CALDAT, systime_end,   END_MONTH,   END_DAY,   END_YEAR

   START_HOUR  = 00
   END_HOUR    =  START_HOUR

   model_run_datetime = STRING(START_YEAR,   $
                                START_MONTH,  $
                                START_DAY,    $
                                START_HOUR,   $
                                FORMAT='(I4.4,"-",I2.2,"-",I2.2,"_",I2.2)')

   openw, 1, wrf_home_dir+ "current_day.txt"
   printf, 1, STRING(  $
                     START_YEAR, START_MONTH, START_DAY, START_HOUR, $
                     FORMAT='(I4.4,"-",I2.2,"-",I2.2,"_",I2.2)')
   close, 1


   openw, 1, wrf_home_dir+ "current_day_upp.txt"
   printf, 1, STRING(  $
                     START_YEAR, START_MONTH, START_DAY, START_HOUR, $
                     FORMAT='(I4.4,I2.2,I2.2,I2.2)')
                 close, 1




   PNGDIR               =   "/projects/biomimicry/WRF_RT_OUTPUT_PNG/NAM02/" + model_run_datetime


;if (three_daytest eq 0) then begin


   spawn, "hostname", hostname


    print, "RUNNING on "+hostname
    spawn, "echo $OMP_NUM_THREADS"

    HOURS_TO_RECYCLE = 6L

   CALDAT,  JULDAY(START_MONTH, START_DAY, START_YEAR, start_hour,0, 0)-HOURS_TO_RECYCLE/24.,  RECYCLE_MONTH, RECYCLE_DAY, RECYCLE_YEAR, RECYCLE_HOUR

   recycle_timestamp = STRING(RECYCLE_YEAR,   $
                                        RECYCLE_MONTH,  $
                                        RECYCLE_DAY,    $
                                        RECYCLE_HOUR,HOURS_TO_RECYCLE,   $
                                        FORMAT='(I4.4,"-",I2.2,"-",I2.2,"_",I2.2,"_F",I2.2)')

   openw, 1, wrf_home_dir + "current_day.txt"
   printf, 1, STRING(  $
           START_YEAR, START_MONTH, START_DAY, START_HOUR, $
           FORMAT='(I4.4,"-",I2.2,"-",I2.2,"_",I2.2)')
   close, 1


   openw, 1, wrf_home_dir+ "current_day_upp.txt"
      printf, 1, STRING(  $
		                    START_YEAR, START_MONTH, START_DAY, START_HOUR, $
				                  FORMAT='(I4.4,I2.2,I2.2,I2.2)')
         close, 1



   max_domains = 2L

   WHERE_IS_MY_RESTART_TIME =  6L ;(first timestep = 0)

   WINDOW_3DVAR = (3L -1L) /2L   ; Plus and minus in days (should be 1 hour)
   N_VARWIN = WINDOW_3DVAR * 2 + 1

  N_VARWIN = 4

   ;
   ; Destination of climate files
   ;

   SHELL_CONTROL = '  ';


   YEAR_STRING = STRING(START_YEAR, FORMAT='(I4.4)')

   GRIB_VTABLE           = wrf_program_root_dir+'/WPS/ungrib/Variable_Tables/Vtable.GFSENS'

   SST_ON                = 0
   SST_DIR               = '/projects/ngpClimate/WRF_PORTAL/NARR_SFC_UNGRIB/'
   SST_PREFIX            = 'NARR_SFC:'

   kyrill_COMMAND         = 'ssh kyrill "'
   squall_COMMAND         = 'ssh squall "'

   WRF_WORKAREA          =  wrf_program_root_dir+'/WRFV3/test/em_real/'
   WPS_LNKGRID_CMD       =  wrf_program_root_dir+'WPS/link_grib.csh '
   WPS_UNGRIB_CMD        =  wrf_program_root_dir+'WPS/ungrib.exe ' ;> ungrib.output'
   WPS_METGRID_CMD       =  wrf_program_root_dir+'WPS/metgrid.exe ';> metgrid.output'


   WPS_WORKAREA          = wrf_home_dir + '/WPSWORK/'



   WRF_REAL_CMD          = ' qsub ./run_real.job '
   WRF_WRF_CMD           = ' qsub ./run_wrf.job '



   NT_SUBOUTFILES =  1L ;   SHORTRUN_DT/WRFOUT_DT + 1

   SPAWN, "ssh wjc@kyrill.ias.sdsmt.edu 'mkdir -v "   + WRF_OUTSTORE + " '"


   WRF_OUTSTORE = WRF_OUTSTORE + STRING(  $
           START_YEAR, START_MONTH, START_DAY, START_HOUR, $
           FORMAT='("/",I4.4,"-",I2.2,"-",I2.2,"_",I2.2,"/")')


;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   DATE MANAGEMENT
;

   START_JULIAN    = JULDAY(START_MONTH, START_DAY, START_YEAR, START_HOUR)
   END_JULIAN      = JULDAY(END_MONTH,   END_DAY,   END_YEAR,   END_HOUR)




   NT_SHORTRUN =  LONG((END_JULIAN-START_JULIAN) * 24L / WRF_RUN_INTERVAL )
   NT_SHORTRUN = 1

   JULAIN_DATES_SHORTRUN_A = TIMEGEN(NT_SHORTRUN,      $
                                    START=START_JULIAN,   $
                                    STEP_SIZE=WRF_RUN_INTERVAL, $
                                    UNITS='HOURS')


   JULAIN_DATES_SHORTRUN_B = TIMEGEN(NT_SHORTRUN,      $
                                    START=START_JULIAN+SHORTRUN_DT/24D,   $
                                    STEP_SIZE=WRF_RUN_INTERVAL, $
                                    UNITS='HOURS')


   CALDAT, JULAIN_DATES_SHORTRUN_A, MONTH_SHORTRUN_A, DAY_SHORTRUN_A, YEAR_SHORTRUN_A, HOUR_SHORTRUN_A
   CALDAT, JULAIN_DATES_SHORTRUN_B, MONTH_SHORTRUN_B, DAY_SHORTRUN_B, YEAR_SHORTRUN_B, HOUR_SHORTRUN_B

   SHORTRUN_DATE_STRING_A = STRARR(NT_SHORTRUN)
   SHORTRUN_DATE_STRING_B = STRARR(NT_SHORTRUN)

   FOR T = 0L, NT_SHORTRUN-1L DO $
       SHORTRUN_DATE_STRING_A(T) = STRING(YEAR_SHORTRUN_A(T),   $
                                        MONTH_SHORTRUN_A(T),  $
                                        DAY_SHORTRUN_A(T),    $
                                        HOUR_SHORTRUN_A(T),   $
                                        FORMAT='(I4.4,"-",I2.2,"-",I2.2,"_",I2.2)')


   FOR T = 0L, NT_SHORTRUN-1L DO $
       SHORTRUN_DATE_STRING_B(T) = STRING(YEAR_SHORTRUN_B(T),   $
                                         MONTH_SHORTRUN_B(T),  $
                                         DAY_SHORTRUN_B(T),    $
                                         HOUR_SHORTRUN_B(T),   $
                                         FORMAT='(I4.4,"-",I2.2,"-",I2.2,"_",I2.2)')
   T = 0
   openw, 1, wrf_home_dir + "current_day.txt"
   printf, 1, STRING(YEAR_SHORTRUN_A(T),  $
		   MONTH_SHORTRUN_A(T),  $
		   DAY_SHORTRUN_A(T),    $
	          HOUR_SHORTRUN_A(T),  $
		  FORMAT='(I4.4,"-",I2.2,"-",I2.2,"_",I2.2)')
   close, 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   WRF LOOP
;

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;
   ;   WRF LOOP
   ;


   FOR T = 0L, NT_SHORTRUN-1L  DO BEGIN

       time_start_in_sec_wps = systime(/seconds)

       PRINT, '   '
       PRINT, ' ===============================================  '
       PRINT, '   '

       PRINT, '-> PROCESSING INTERMEDIATE WRF RUN FROM ' + $
              SHORTRUN_DATE_STRING_A(T) + ' TO ' + $
              SHORTRUN_DATE_STRING_B(T)

       PRINT, '   '

       ; This one sets the first step of the assimilation window
       VAR_WINDOW_JULDATE = TIMEGEN(2,      $
                                    START=JULAIN_DATES_SHORTRUN_A(T),   $
                                    STEP_SIZE=-WINDOW_3DVAR, $
                                    UNITS='HOURS')
       ; This one sets all of the assimilation window time steps
       VAR_WINDOW_JULDATE = TIMEGEN(N_VARWIN,      $
                                    START=VAR_WINDOW_JULDATE(1),   $
                                    STEP_SIZE=WINDOW_3DVAR, $
                                    UNITS='HOURS')


       CALDAT, VAR_WINDOW_JULDATE, MONTH_VARWIN, DAY_VARWIN, YEAR_VARWIN, HOUR_VARWIN


       ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
       ;
       ; WPS AREA
       ;

          CD,  WPS_WORKAREA


          SPAWN, 'rm -frv ' + WPS_WORKAREA + 'NAMELIST_WPS.DATESTAMPS'
          SPAWN, 'rm -frv ' + WPS_WORKAREA + 'namelist.wps'
          SPAWN, 'rm -frv ' + WPS_WORKAREA + 'FILE:*'
          SPAWN, 'rm -frv ' + WPS_WORKAREA + 'FILE218:*'
          SPAWN, 'rm -frv ' + WPS_WORKAREA + 'PFILE:*'
          SPAWN, 'rm -frv ' + WRF_WORKAREA + '????.d0?.??'

          SPAWN, 'rm -frv ' + WPS_WORKAREA + 'GRIBFILE*'
          SPAWN, 'rm -frv ' + WRF_WORKAREA + 'sfc_obs*
          SPAWN, 'rm -frv ' + WRF_WORKAREA + 'obs*'
          SPAWN, 'rm -frv ' + WRF_WORKAREA + 'wrfinput*'
          SPAWN, 'rm -frv ' + WRF_WORKAREA + 'wrfbdy*'
          SPAWN, 'rm -frv ' + WRF_WORKAREA + 'nam*nc'
          SPAWN, 'rm -frv ' + WRF_WORKAREA + 'OBS*'
          SPAWN, 'rm -frv ' + WRF_WORKAREA + 'met_em*.nc'
          SPAWN, 'rm -frv ' + WPS_WORKAREA + 'met_em*.nc'
          SPAWN, 'rm -frv ' + WPS_WORKAREA + 'nam*.grib2'

          SPAWN, 'rm -frv ' + WPS_WORKAREA + 'gefs*.g*2'
          SPAWN, 'rm -frv ' + WPS_WORKAREA + 'gens*.g*2'
          SPAWN, 'rm -frv ' + WPS_WORKAREA + 'gfs*.g*2'

          SPAWN, 'rm -frv ' + WPS_WORKAREA + 'g*z.pgrb2.0p25.f*'

          ;;; BLOCK TO CREATE DATESTAMP

          UNGRIB_DATE_A = JULAIN_DATES_SHORTRUN_A(T)
          UNGRIB_DATE_B = JULAIN_DATES_SHORTRUN_B(T)

          CALDAT, UNGRIB_DATE_A, MONTH_UNGRIB_A, DAY_UNGRIB_A, YEAR_UNGRIB_A, HOUR_UNGRIB_A
          CALDAT, UNGRIB_DATE_B, MONTH_UNGRIB_B, DAY_UNGRIB_B, YEAR_UNGRIB_B, HOUR_UNGRIB_B

          NT_UNGRIB = LONG((UNGRIB_DATE_B - UNGRIB_DATE_A)*24L/GRIB_DT +1L)

          print, (UNGRIB_DATE_B - UNGRIB_DATE_A)
          print, GRIB_DT
         print, LONG((UNGRIB_DATE_B - UNGRIB_DATE_A)*24L/GRIB_DT +1L)

          JULAIN_DATES_UNGRIB = TIMEGEN(NT_UNGRIB,            $
                                        START=UNGRIB_DATE_A,  $
                                        STEP_SIZE=GRIB_DT,    $
                                        UNITS='HOURS')


          JULAIN_DATES_SUBOUT     = TIMEGEN(NT_SUBOUTFILES,      $
                                       START=JULAIN_DATES_SHORTRUN_A(T),   $
                                       STEP_SIZE=WRFOUT_DT, $
                                       UNITS='HOURS')

          CALDAT, JULAIN_DATES_SUBOUT, MONTH_SUBOUT, DAY_SUBOUT, YEAR_SUBOUT, HOUR_SUBOUT

          SUBOUT_DATE_STRING    = STRARR(NT_SUBOUTFILES)
          SUBOUT_DATE_STRING_SM = STRARR(NT_SUBOUTFILES)

          FOR TT = 0L, NT_SUBOUTFILES-1L DO $
              SUBOUT_DATE_STRING(TT)    = STRING(YEAR_SUBOUT(TT),   $
                                                MONTH_SUBOUT(TT),  $
                                                DAY_SUBOUT(TT),    $
                                                HOUR_SUBOUT(TT),   $
                                     FORMAT='(I4.4,"-",I2.2,"-",I2.2,"_",I2.2,":00:00")')

          FOR TT = 0L, NT_SUBOUTFILES-1L DO $
              SUBOUT_DATE_STRING_SM(TT)  = STRING(YEAR_SUBOUT(0),   $
                                                MONTH_SUBOUT(0),  $
                                                DAY_SUBOUT(0),    $
                                                HOUR_SUBOUT(0),   $
                                                TT*WRFOUT_DT,      $
                                                FORMAT='(I4.4,"-",I2.2,"-",I2.2,"_",I2.2)')

          CALDAT, JULAIN_DATES_UNGRIB, MONTH_UNGRIB, DAY_UNGRIB, YEAR_UNGRIB, HOUR_UNGRIB

          UNGRIB_DATE_STRING  = STRARR(NT_UNGRIB)
          UNGRIB_DIR_STRING   = STRARR(NT_UNGRIB)
          GRIB_FILE_LOCAL     = STRARR(NT_UNGRIB)
          GRIB_FILE_MSS       = STRARR(NT_UNGRIB)
          METEM_FILE_NAME     = STRARR(NT_UNGRIB)
          SST_FILE_NAME       = STRARR(NT_UNGRIB)
          ALL_GRIBFILE_FORMAT = '(' + STRING(NT_UNGRIB)+'(A," "))'

          FOR TT = 0L, NT_UNGRIB-1L DO $
               UNGRIB_DIR_STRING(TT) = STRING(YEAR_UNGRIB(0),   $
                                         MONTH_UNGRIB(0),  $
                                         DAY_UNGRIB(0), $
                                         FORMAT='(I4.4,"/",I2.2,"/",I2.2)')


          FOR TT = 0L, NT_UNGRIB-1L DO $
               UNGRIB_DATE_STRING(TT) = STRING(YEAR_UNGRIB(0),   $
                                         MONTH_UNGRIB(0),  $WRF_WORKAREA
                                         DAY_UNGRIB(0),    $
                                         HOUR_UNGRIB(0),   $
                                         FORMAT='(I4.4,"-",I2.2,"-",I2.2,"_",I2.2)')+ "_f" + string(TT*GRIB_DT,format='(I3.3)')

          FOR TT = 0L, NT_UNGRIB-1L DO $
               METEM_FILE_NAME(TT)    =  "met_em.d01." + $
	                                 STRING(YEAR_UNGRIB(TT),   $
                                         MONTH_UNGRIB(TT),  $
                                         DAY_UNGRIB(TT),    $
                                         HOUR_UNGRIB(TT),   $
                                         FORMAT='(I4.4,"-",I2.2,"-",I2.2,"_",I2.2,":00:00.nc")')

           ncdc_dir1 = string(YEAR_UNGRIB(0),MONTH_UNGRIB(0),DAY_UNGRIB(0),format="(I4.4,I2.2,I2.2)")
           ncdc_dir2 = string(HOUR_UNGRIB(0),format="(I2.2)")

           website = "ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/gens/prod/gefs." + $
                      ncdc_dir1 + "/" + ncdc_dir2 + "/pgrb2/"
           website = "http://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs." + $
                     ncdc_dir1 + ncdc_dir2 + "/"
           ;;;     gfs.t00z.pgrb2.0p25.f000
           pref = "gfs."

           fx= intarr(NT_UNGRIB)

           FOR TT = 0L, NT_UNGRIB-1L DO $
               fx(TT) = TT*GRIB_DT

           FOR TT = 0L, NT_UNGRIB-1L DO $
                GRIB_FILE_MSS(TT) = website+ "/" + pref+string(HOUR_UNGRIB(0),fx(TT),format="('t',I2.2,'z.pgrb2.0p25.f',I3.3)")

           FOR TT = 0L, NT_UNGRIB-1L DO $
                GRIB_FILE_LOCAL(TT) =  pref+string(HOUR_UNGRIB(0),fx(TT),format="('t',I2.2,'z.pgrb2.0p25.f',I3.3)")
; http://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.2017051000//gfs..t00z.pgrb2.0p25.f008
; http://nomads.ncep.noaa.gov/pub/data/nccf/com/gfs/prod/gfs.2017051000/gfs.t00z.pgrb2.0p25.f008
           print, GRIB_FILE_MSS
           print, GRIB_FILE_LOCAL

           spawn, "rm -frv ./g*z.pgrb2.0p25.f*"


           FOR TT = 0L, NT_UNGRIB-1L DO $
              spawn, "nohup wget "+GRIB_FILE_MSS(TT)

           FOR TT = 0L, NT_UNGRIB-1L DO $
              SPAWN, 'ls -al ' + GRIB_FILE_LOCAL(TT)

          FOR TT = 0L, NT_UNGRIB-1L DO $
             SPAWN, 'ls -al ' + GRIB_FILE_LOCAL(TT)

          PRINT, '--- LINKING GRIB FILES ' + SHORTRUN_DATE_STRING_A(T)

          SPAWN, 'time ' + WPS_LNKGRID_CMD + ' ' + STRING(GRIB_FILE_LOCAL, FORMAT=ALL_GRIBFILE_FORMAT)

          CLOSE, 1
          OPENW, 1, WPS_WORKAREA + 'NAMELIST_WPS.DATESTAMPS'
             PRINTF, 1, "&share"
             PRINTF, 1, " wrf_core   = 'ARW',"
             PRINTF, 1, " max_dom    = " + string(max_domains, FORMAT="(I4)") + ","
             PRINTF, 1, " start_date =  '" + SHORTRUN_DATE_STRING_A(T) + ":00:00','"+ SHORTRUN_DATE_STRING_A(T) + ":00:00','"+ SHORTRUN_DATE_STRING_A(T) + ":00:00',"
             PRINTF, 1, " end_date   =  '" + SHORTRUN_DATE_STRING_B(T) + ":00:00','"+ SHORTRUN_DATE_STRING_A(T) + ":00:00','"+ SHORTRUN_DATE_STRING_A(T) + ":00:00',"
             PRINTF, 1, " interval_seconds =  " + string(1 * 3600L, FORMAT='(I5.5)') + ","
             PRINTF, 1, " io_form_geogrid = 2,"
             PRINTF, 1, " opt_output_from_geogrid_path = '"+WPS_WORKAREA+"',"
             PRINTF, 1, " debug_level = 0,"
             PRINTF, 1, "/"
          CLOSE, 1

          ; spawn, 'cat '+WPS_WORKAREA + 'NAMELIST_WPS.DATESTAMPS'

          SPAWN, 'cat ' + WPS_WORKAREA + 'NAMELIST_WPS.DATESTAMPS '   $
                        + WPS_WORKAREA + 'NAMELIST_WPS.ROOT_BACKEND  > ' $
                        + WPS_WORKAREA + 'namelist.wps'

          PRINT, 'UNPACKING GRIB212 FILES ' + SHORTRUN_DATE_STRING_A(T)

          SPAWN, "time  " + WPS_UNGRIB_CMD



          PRINT, 'CREATING METE_EM ' + SHORTRUN_DATE_STRING_A(T)

          SPAWN, "time  " + WPS_METGRID_CMD


          time_end_in_sec_wps = systime(/seconds)
       ;
       ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


       ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
       ;
       ; WRF AREA
       ;

          time_start_in_sec_wrfprep = systime(/seconds)

          CD, WRF_WORKAREA

          SPAWN, 'rm -frv wrf.log real.log'

          SPAWN, "cp -frv  " + WPS_WORKAREA + "/met_em*.nc ./"


          SPAWN, 'rm -fvr '+ WRF_WORKAREA + '/rsl.*'

          SPAWN, 'rm -fvr '+ WRF_WORKAREA + '/OBS_DOMAIN*'
          SPAWN, 'rm -frv ' + WPS_WORKAREA + 'g*z.pgrb2.0p25.f*'
          SPAWN, 'rm -frv ' + WPS_WORKAREA + 'FILE:*'
          SPAWN, 'rm -frv ' + WPS_WORKAREA + 'FILE218:*'
          SPAWN, 'rm -frv ' + WPS_WORKAREA + 'PFILE:*'

         ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
         ;
         ;;;  nudgeprep
	      print, "pulling nudging data"
         nudge_data_dir = "/data/NCAR/UNIDATA_LITTLE_R_NAMIBIA/"

         help, NUDGING_PERIOD+1
         help, START_JULIAN

         JULIAN_DATE_NUDGE = TIMEGEN(NUDGING_PERIOD+1,      $
                                    START=START_JULIAN,   $
                                    STEP_SIZE=1, $
                                    UNITS='HOURS')


         print, JULIAN_DATE_NUDGE

         CALDAT, JULIAN_DATE_NUDGE,  MONTH_NUDGE, DAY_NUDGE, YEAR_NUDGE, HOUR_NUDGE

         print, JULIAN_DATE_NUDGE,  MONTH_NUDGE, DAY_NUDGE, YEAR_NUDGE, HOUR_NUDGE

         NUDGE_OBS_DATE_STRINGS = STRARR(NUDGING_PERIOD+1)

         VAR_OBS_DATE_STRINGS = STRARR(N_VARWIN)
         help, NUDGE_OBS_DATE_STRINGS
         help, N_VARWIN
         help, NUDGING_PERIOD+1
         help, NUDGING_PERIOD+1
         FOR TT = 0, N_VARWIN-1 DO $
             VAR_OBS_DATE_STRINGS(tt) = STRING(YEAR_VARWIN(TT),MONTH_VARWIN(TT),DAY_VARWIN(TT),HOUR_VARWIN(TT),FORMAT='(i4.4,"-",i2.2,"-",i2.2,"_",i2.2)')
         print, "VAR_OBS_DATE_STRINGS = "+VAR_OBS_DATE_STRINGS
         FOR TT = 0, NUDGING_PERIOD+1-1 DO $
             VAR_OBS_DATE_STRINGS(tt) = STRING(YEAR_VARWIN(TT),MONTH_VARWIN(TT),DAY_VARWIN(TT),HOUR_VARWIN(TT),FORMAT='(i4.4,"-",i2.2,"-",i2.2,"_",i2.2)')
         print, "VAR_OBS_DATE_STRINGS = "+VAR_OBS_DATE_STRINGS

         FOR TT = 0, NUDGING_PERIOD+1-1 DO $
             NUDGE_OBS_DATE_STRINGS(tt) = STRING(YEAR_NUDGE(TT),MONTH_NUDGE(TT),DAY_NUDGE(TT),HOUR_NUDGE(TT),FORMAT='(i4.4,"-",i2.2,"-",i2.2,"_",i2.2,"00")')
         print, "NUDGE_OBS_DATE_STRINGS="+NUDGE_OBS_DATE_STRINGS

         FOR TT = 0L, NUDGING_PERIOD+1-1 DO $
             SPAWN, "scp wjc@kyrill.ias.sdsmt.edu:" + nudge_data_dir + "obs_" + NUDGE_OBS_DATE_STRINGS(TT) + ".txt.gz  ."


         SPAWN, "gunzip -v  obs_*.gz"

         spawn, "cat obs_????-??-??_????.txt > obs_bigfile.txt"

         spawn, "./RT_fdda_reformat_obsnud.pl obs_bigfile.txt"

         spawn, "mv -v obs_bigfile.txt.obsnud  OBS_DOMAIN101"

         spawn, "cp -v OBS_DOMAIN101  OBS_DOMAIN201"
         spawn, "cp -v OBS_DOMAIN101  OBS_DOMAIN301"

	 ;;
	 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

         SPAWN, 'rm -frv wrfinput_d0* wrfbdy_d0* wrfinput_dxx  namelist.input ' + $
	         WRF_WORKAREA + 'NAMELIST.DATESTAMP'

 	     CLOSE, 1
             OPENW, 1, WRF_WORKAREA + 'NAMELIST.DATESTAMP'
                PRINTF, 1, "&time_control"
                PRINTF, 1, " run_days              = 000,"
                PRINTF, 1, " run_hours             = "  + STRING(SHORTRUN_DT, FORMAT='(I3.3)')+ ","
                PRINTF, 1, " run_minutes           = 000,"
                PRINTF, 1, " run_seconds           = 000,"
                PRINTF, 1, " start_year            = " + STRING(YEAR_SHORTRUN_A(T),  FORMAT='(I4.4)') + "," + STRING(YEAR_SHORTRUN_A(T),  FORMAT='(I4.4)') + "," + STRING(YEAR_SHORTRUN_A(T),  FORMAT='(I4.4)') + ","
                PRINTF, 1, " start_month           = " + STRING(MONTH_SHORTRUN_A(T), FORMAT='(I2.2)') + "," + STRING(MONTH_SHORTRUN_A(T), FORMAT='(I2.2)') + ","+  STRING(MONTH_SHORTRUN_A(T), FORMAT='(I2.2)') + ","
                PRINTF, 1, " start_day             = " + STRING(DAY_SHORTRUN_A(T),   FORMAT='(I2.2)') + "," + STRING(DAY_SHORTRUN_A(T),   FORMAT='(I2.2)') + "," + STRING(DAY_SHORTRUN_A(T),   FORMAT='(I2.2)') + ","
                PRINTF, 1, " start_hour            = " + STRING(HOUR_SHORTRUN_A(T),  FORMAT='(I2.2)') + "," + STRING(HOUR_SHORTRUN_A(T),  FORMAT='(I2.2)') + "," + STRING(HOUR_SHORTRUN_A(T),  FORMAT='(I2.2)') + ","
                PRINTF, 1, " start_minute          = 00,00,"
                PRINTF, 1, " start_second          = 00,00,"
                PRINTF, 1, " end_year              = " + STRING(YEAR_SHORTRUN_B(T),  FORMAT='(I4.4)') + "," + STRING(YEAR_SHORTRUN_B(T),  FORMAT='(I4.4)') + "," + STRING(YEAR_SHORTRUN_B(T),  FORMAT='(I4.4)') + ","
                PRINTF, 1, " end_month             = " + STRING(MONTH_SHORTRUN_B(T), FORMAT='(I2.2)') + "," + STRING(MONTH_SHORTRUN_B(T), FORMAT='(I2.2)') + "," + STRING(MONTH_SHORTRUN_B(T), FORMAT='(I2.2)') + ","
                PRINTF, 1, " end_day               = " + STRING(DAY_SHORTRUN_B(T),   FORMAT='(I2.2)') + "," + STRING(DAY_SHORTRUN_B(T),   FORMAT='(I2.2)') + "," + STRING(DAY_SHORTRUN_B(T),   FORMAT='(I2.2)') + ","
                PRINTF, 1, " end_hour              = " + STRING(HOUR_SHORTRUN_B(T),  FORMAT='(I2.2)') + "," + STRING(HOUR_SHORTRUN_B(T),  FORMAT='(I2.2)') + "," + STRING(HOUR_SHORTRUN_B(T),  FORMAT='(I2.2)') + ","
                PRINTF, 1, " end_minute            = 00,00,"
                PRINTF, 1, " end_second            = 00,00,"
                PRINTF, 1, " interval_seconds   = " + STRING(GRIB_DT*3600L,    FORMAT='(I5.5)') + ","
                PRINTF, 1, " input_from_file    = .true., .true., .true.,"
                PRINTF, 1, " io_form_auxinput2  = 2,"
                PRINTF, 1, " fine_input_stream  = 0,0,0,"
                PRINTF, 1, " history_interval   = " + STRING(WRFOUT_DT*60L,    FORMAT='(I5.5)') + "," + STRING(WRFOUT_DT*60L,    FORMAT='(I5.5)') + "," + STRING(WRFOUT_DT*60L,    FORMAT='(I5.5)') + ","
                PRINTF, 1, " frames_per_outfile = 99999999,99999999,99999999,"
                PRINTF, 1, " restart               = .false.,"
                PRINTF, 1, " restart_interval      = 99999999,"
                PRINTF, 1, " io_form_history       = 2,"
                PRINTF, 1, " io_form_restart       = 2,"
                PRINTF, 1, " io_form_input         = 2,"
                PRINTF, 1, " io_form_boundary      = 2,"
                PRINTF, 1, " debug_level           = 0,"
                PRINTF, 1, " auxinput11_interval_s = 180, 180,180,"
                PRINTF, 1, " auxinput11_end_h      = 3,3,3,"
                PRINTF, 1, "/"
 	     CLOSE, 1

 	     CLOSE, 1
             OPENW, 1, WRF_WORKAREA + 'NAMELIST.DATESTAMP.NONUDGE'
                PRINTF, 1, "&time_control"
                PRINTF, 1, " run_days           = 000,"
                PRINTF, 1, " run_hours          = "  + STRING(SHORTRUN_DT, FORMAT='(I3.3)')+ ","
                PRINTF, 1, " run_minutes        = 000,"
                PRINTF, 1, " run_seconds        = 000,"
                PRINTF, 1, " start_year         = " + STRING(YEAR_SHORTRUN_A(T),  FORMAT='(I4.4)') + "," + STRING(YEAR_SHORTRUN_A(T),  FORMAT='(I4.4)') + "," + STRING(YEAR_SHORTRUN_A(T),  FORMAT='(I4.4)') + ","
                PRINTF, 1, " start_month        = " + STRING(MONTH_SHORTRUN_A(T), FORMAT='(I2.2)') + "," + STRING(MONTH_SHORTRUN_A(T), FORMAT='(I2.2)') + ","+  STRING(MONTH_SHORTRUN_A(T), FORMAT='(I2.2)') + ","
                PRINTF, 1, " start_day          = " + STRING(DAY_SHORTRUN_A(T),   FORMAT='(I2.2)') + "," + STRING(DAY_SHORTRUN_A(T),   FORMAT='(I2.2)') + "," + STRING(DAY_SHORTRUN_A(T),   FORMAT='(I2.2)') + ","
                PRINTF, 1, " start_hour         = " + STRING(HOUR_SHORTRUN_A(T),  FORMAT='(I2.2)') + "," + STRING(HOUR_SHORTRUN_A(T),  FORMAT='(I2.2)') + "," + STRING(HOUR_SHORTRUN_A(T),  FORMAT='(I2.2)') + ","
                PRINTF, 1, " start_minute       = 00,00,"
                PRINTF, 1, " start_second       = 00,00,"
                PRINTF, 1, " end_year           = " + STRING(YEAR_SHORTRUN_B(T),  FORMAT='(I4.4)') + "," + STRING(YEAR_SHORTRUN_B(T),  FORMAT='(I4.4)') + "," + STRING(YEAR_SHORTRUN_B(T),  FORMAT='(I4.4)') + ","
                PRINTF, 1, " end_month          = " + STRING(MONTH_SHORTRUN_B(T), FORMAT='(I2.2)') + "," + STRING(MONTH_SHORTRUN_B(T), FORMAT='(I2.2)') + "," + STRING(MONTH_SHORTRUN_B(T), FORMAT='(I2.2)') + ","
                PRINTF, 1, " end_day            = " + STRING(DAY_SHORTRUN_B(T),   FORMAT='(I2.2)') + "," + STRING(DAY_SHORTRUN_B(T),   FORMAT='(I2.2)') + "," + STRING(DAY_SHORTRUN_B(T),   FORMAT='(I2.2)') + ","
                PRINTF, 1, " end_hour           = " + STRING(HOUR_SHORTRUN_B(T),  FORMAT='(I2.2)') + "," + STRING(HOUR_SHORTRUN_B(T),  FORMAT='(I2.2)') + "," + STRING(HOUR_SHORTRUN_B(T),  FORMAT='(I2.2)') + ","
                PRINTF, 1, " end_minute         = 00,00,"
                PRINTF, 1, " end_second         = 00,00,"
                PRINTF, 1, " interval_seconds   = " + STRING(GRIB_DT*3600L,    FORMAT='(I5.5)') + ","
                PRINTF, 1, " input_from_file    = .true., .true., .true.,"
                PRINTF, 1, " io_form_auxinput2  = 2,"
                PRINTF, 1, " fine_input_stream  = 0,0,0,"
                PRINTF, 1, " history_interval   = " + STRING(WRFOUT_DT*60L,    FORMAT='(I5.5)') + "," + STRING(WRFOUT_DT*60L,    FORMAT='(I5.5)') + "," + STRING(WRFOUT_DT*60L,    FORMAT='(I5.5)') + ","
                PRINTF, 1, " restart            = .false.,"
                PRINTF, 1, " restart_interval   = 999999999,"
                PRINTF, 1, " io_form_history    = 2,"
                PRINTF, 1, " history_interval   = " + STRING(WRFOUT_DT*60L,    FORMAT='(I5.5)') + "," + STRING(WRFOUT_DT*60L,    FORMAT='(I5.5)') + "," + STRING(WRFOUT_DT*60L,    FORMAT='(I5.5)') + ","
                PRINTF, 1, " frames_per_outfile = 99999999,99999999,99999999,"
                PRINTF, 1, " restart            = .false.,"
                PRINTF, 1, " restart_interval   = " + STRING(WRF_RUN_INTERVAL*60L,  FORMAT='(I5.5)') + ","
                PRINTF, 1, " io_form_history    = 2,"
                PRINTF, 1, " io_form_restart    = 2,"
                PRINTF, 1, " io_form_input      = 2,"
                PRINTF, 1, " io_form_boundary   = 2,"
                PRINTF, 1, " debug_level        = 0,"
                PRINTF, 1, "/"
 	     CLOSE, 1

 	     SPAWN, 'rm -frv ' +  WRF_WORKAREA + 'namelist.input'

 	     SPAWN, 'cat ' + WRF_WORKAREA + 'NAMELIST.DATESTAMP '   $
                       + WRF_WORKAREA + 'NAMELIST.ROOT_END.NUDGE > ' $
                       + WRF_WORKAREA + 'namelist.input'

 	     SPAWN, 'cat ' + WRF_WORKAREA + 'NAMELIST.DATESTAMP '   $
                       + WRF_WORKAREA + 'NAMELIST.ROOT_END.NUDGE > ' $
                       + WRF_WORKAREA + 'namelist.input.wrf'

 	     SPAWN, 'ls -alt  ' + WRF_WORKAREA + 'NAMELIST.DATESTAMP '  $
                            + WRF_WORKAREA + 'NAMELIST.ROOT_END.NUDGE '  $
                            + WRF_WORKAREA + 'namelist.input '

         SPAWN, 'rm -fr ./rsl.*'
         SPAWN, ' cp namelist.input.wrf namelist.input'

         spawn, 'rm -frv my_real_is_done.txt'


         SPAWN, 'ls -al ' + WRF_WORKAREA + 'met_em*.nc'

         PRINT, '--- RUNNING REAL.EXE ' + SHORTRUN_DATE_STRING_A(T)
         print, 'time  ' + WRF_REAL_CMD
         spawn, 'nohup time  '+WRF_REAL_CMD



           spawn, "date -u"
           while  ( file_test("./my_real_is_done.txt") ne 1)  do begin
                 WAIT, 60.
                 spawn, "date -u"
           endwhile
         SPAWN, 'ls -al wrfinput_d0* wrfbdy_d01'
        SPAWN, 'rm -frv ' + WRF_WORKAREA + 'met_em*.nc'
         SPAWN, 'rm -frv ' + WPS_WORKAREA + 'met_em*.nc'




         IF ( FILE_TEST("./wrfinput_d01") EQ 0) THEN BEGIN
             PRINT, "REAL FAILED"
             SPAWN, "cat rsl.out.0000"

             EXIT
         ENDIF
         SPAWN, 'rm -frv ./rsl* '

         WRF_INIT_INFO = FILE_INFO("./wrfinput_d01")
         help,WRF_INIT_INFO

         time_end_in_sec_wrfprep = systime(/seconds)
         time_start_in_sec_wrf = systime(/seconds)


         spawn, 'rm -frv my_wrf_is_done.txt'


          PRINT, '--- RUNNING WRF.EXE WITH NUDGING' + SHORTRUN_DATE_STRING_A(T)
                    SPAWN, ' cp namelist.input.wrf namelist.input'
                    print, 'time  ' + WRF_WRF_CMD
          SPAWN, 'time  ' + WRF_WRF_CMD



           spawn, "date -u"
           while  ( file_test("./my_wrf_is_done.txt") ne 1)  do begin
                 WAIT, 60.
                 spawn, "date -u"
           endwhile

           spawn, 'rm -frv my_wrf_is_done.txt'

          WRF_FILENAMES    = "wrfout_d01_" +  SUBOUT_DATE_STRING


       SPAWN, "echo Nudging Enabled > /home/wcapehart/WRFV381_TKE/nudge.status.txt"


              IF ( FILE_TEST( WRF_FILENAMES(0)) EQ 0) THEN BEGIN
                 SPAWN, "cat rsl.error.0000"
                 PRINT, "WRF  FAILED "
                 STOP
              ENDIF

          time_end_in_sec_wrf       = systime(/seconds)
          time_start_in_sec_wrfpost = systime(/seconds)

          WRF_FILENAMES    = "wrfout_d01_" +  SUBOUT_DATE_STRING(0)
          WRF_SM_FILENAMES = "nam02_d01_" +  SUBOUT_DATE_STRING_SM(0) + ".nc"
          FOR TT = 0L,NT_SUBOUTFILES-1L DO $    ;  NT_SUBOUTFILES-1L DO $
              SPAWN, 'export NETCDF=/opt/package/netcdf/netcdf-4.3.3.1 && export LD_LIBRARY_PATH="${NETCDF}/lib:${LD_LIBRARY_PATH}" && export LD_RUN_PATH="${NETCDF}/lib:${LD_RUN_PATH}" &&  /opt/package/netcdf/netcdf-4.3.3.1/bin/nccopy -d 7 -s -u '  + WRF_FILENAMES(TT) + ' ' + WRF_SM_FILENAMES(TT)


          WRF_FILENAMES    = "wrfout_d02_" +  SUBOUT_DATE_STRING(0)
          WRF_SM_FILENAMES =  "nam02_d02_" +  SUBOUT_DATE_STRING_SM(0) + ".nc"
          FOR TT = 0L,NT_SUBOUTFILES-1L DO $    ;  NT_SUBOUTFILES-1L DO $
              SPAWN, 'export NETCDF=/opt/package/netcdf/netcdf-4.3.3.1 && export LD_LIBRARY_PATH="${NETCDF}/lib:${LD_LIBRARY_PATH}" && export LD_RUN_PATH="${NETCDF}/lib:${LD_RUN_PATH}" &&  /opt/package/netcdf/netcdf-4.3.3.1/bin/nccopy -d 7 -s -u '  + WRF_FILENAMES(TT) + ' ' + WRF_SM_FILENAMES(TT)

;          WRF_FILENAMES    = "wrfout_d03_" +  SUBOUT_DATE_STRING(0)
;          WRF_SM_FILENAMES =  "nam02_d03_" +  SUBOUT_DATE_STRING_SM(0) + ".nc"
;          FOR TT = 0L,NT_SUBOUTFILES-1L DO $    ;  NT_SUBOUTFILES-1L DO $
;              SPAWN, 'export NETCDF=/opt/package/netcdf/netcdf-4.3.3.1 && export LD_LIBRARY_PATH="${NETCDF}/lib:${LD_LIBRARY_PATH}" && export LD_RUN_PATH="${NETCDF}/lib:${LD_RUN_PATH}" &&  /opt/package/netcdf/netcdf-4.3.3.1/bin/nccopy -d 7 -s -u '  + WRF_FILENAMES(TT) + ' ' + WRF_SM_FILENAMES(TT)

          FOR TT = 0L,NT_SUBOUTFILES-1L DO $    ;  NT_SUBOUTFILES-1L DO $
              SPAWN, 'rm -v ' + WRF_FILENAMES(TT)


          SPAWN, "export NCL_ROOT=/usr/  &&  ncl "+wrf_home_dir+"ts2nc_autoread_d01.ncl"
          SPAWN, "export NCL_ROOT=/usr/  &&  ncl "+wrf_home_dir+"ts2nc_autoread_d02.ncl"

          ; SPAWN, 'gzip -frv9 wrfout*.nc '

          SPAWN, "ssh wjc@kyrill.ias.sdsmt.edu 'mkdir -v "   + WRF_OUTSTORE + " '"

          SPAWN, 'scp -v ./nam*.nc   wjc@kyrill.ias.sdsmt.edu:' + WRF_OUTSTORE

          SPAWN, 'rm -frv rsl* wrfout*.nc* wrfrst_d0* nam*nc'

          FOR TT = 0L, NT_UNGRIB-1L DO $
             SPAWN, 'rm -frv ' + WPS_WORKAREA + GRIB_FILE_LOCAL(TT)

   ENDFOR




;endif else begin
;endelse


END

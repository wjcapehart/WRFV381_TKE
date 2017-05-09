;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   USER MODIFICATION
;
 time_start_in_sec = systime(/seconds)


   wrf_home_dir = "/home/wjc/WRF_REALTIME/"
   wrf_version = "WRFV370"
   wrf_program_root_dir = "/home/wjc/WRF_REALTIME_KUNR-3DOM/"+wrf_version+"/"
   wrfda_obsproc_exe    = wrf_program_root_dir + "WRFDA/var/obsproc/src/obsproc.exe "
        systime_start = systime(/UTC,/JULIAN)
	systime_end = systime(/UTC,/JULIAN)+1

   CALDAT, systime(/UTC,/JULIAN),  START_MONTH, START_DAY, START_YEAR
   CALDAT, systime(/UTC,/JULIAN)+1, END_MONTH, END_DAY, END_YEAR

   START_HOUR  = 00
   END_HOUR    =  START_HOUR


   spawn, "hostname", hostname

   if (hostname eq "hurricane.ias.sdsmt.edu") then begin
         NUMBEROFPROCS = '32'
	 CO_NODE       = "gale.ias.sdsmt.edu"
   endif

   if (hostname eq "gale.ias.sdsmt.edu") then begin
         NUMBEROFPROCS = '32'
	 CO_NODE       = "hurricane.ias.sdsmt.edu"
   endif

   if (hostname eq "maelstrom.ias.sdsmt.edu") then begin
         NUMBEROFPROCS =  '32'
	 CO_NODE       = "cyclone.ias.sdsmt.edu"
   endif

   if (hostname eq "cyclone.ias.sdsmt.edu") then begin
         NUMBEROFPROCS =  '32'
	 CO_NODE       = "maelstrom.ias.sdsmt.edu"
   endif

    print, "RUNNING on "+hostname+" and "+CO_NODE
    spawn, "echo $OMP_NUM_THREADS"

    HOURS_TO_RECYCLE = 6L

   CALDAT,  JULDAY(START_MONTH, START_DAY, START_YEAR, start_hour,0, 0)-HOURS_TO_RECYCLE/24.,  RECYCLE_MONTH, RECYCLE_DAY, RECYCLE_YEAR, RECYCLE_HOUR

   recycle_timestamp = STRING(RECYCLE_YEAR,   $
                                        RECYCLE_MONTH,  $
                                        RECYCLE_DAY,    $
                                        RECYCLE_HOUR,HOURS_TO_RECYCLE,   $
                                        FORMAT='(I4.4,"-",I2.2,"-",I2.2,"_",I2.2,"_F",I2.2)')

   openw, 1, "/home/wjc/WRF_REALTIME/current_day.txt"
   printf, 1, STRING(  $
           START_YEAR, START_MONTH, START_DAY, START_HOUR, $
           FORMAT='(I4.4,"-",I2.2,"-",I2.2,"_",I2.2)')
   close, 1


   openw, 1, "/home/wjc/WRF_REALTIME/current_day_upp.txt"
      printf, 1, STRING(  $
		                    START_YEAR, START_MONTH, START_DAY, START_HOUR, $
				                  FORMAT='(I4.4,I2.2,I2.2,I2.2)')
         close, 1



   max_domains = 2L

   WHERE_IS_MY_RESTART_TIME =  6L ;(first timestep = 0)

   WINDOW_3DVAR = (3L -1L) /2L   ; Plus and minus in days (should be 1 hour)
   N_VARWIN = WINDOW_3DVAR * 2 + 1

   WRFVERSION     = 3L   ;       (version of WRF)

   GRIB_DT        = 03L ; HOURS (timestep for WRF Input Data)
   WRFOUT_DT      = 01L ; HOURS (timestep for WRF Output Data)
   WRFOUT_DT3     = 01L ; HOURS (timestep for WRF Output Data)
   NUDGING_PERIOD = 03L ; hOURS

   SHORTRUN_DT = 36L ; HOURS (numbers of hours for a single WRF run)
   WRF_RUN_INTERVAL = 6L ; HOURS (numbers of hours  between WRF run)

   WRF_OUTSTORE = '/cyclone1/WRF_REALTIME/OUTPUT/WRF37_KUNR_3DOM_WSM6_NOAH_MYNN2_KF2_DUDHIA_NAM218-09km_150x150/'

   ;
   ; Destination of climate files
   ;

   SHELL_CONTROL = '  ';


   YEAR_STRING = STRING(START_YEAR, FORMAT='(I4.4)')

   GRIB_NCAR_DIR         = '/ldm/data/gempak/grib/nam'
   GRIB_PREFIX           = 'nam212_'
   GRIB_PREFIX_218       = 'nam218_'
   GRIB_VTABLE           = wrf_program_root_dir+'/WPS/ungrib/Variable_Tables/Vtable.NAM'

   SST_ON                = 0
   SST_DIR               = '/projects/ngpClimate/WRF_PORTAL/NARR_SFC_UNGRIB/'
   SST_PREFIX            = 'NARR_SFC:'

   kyrill_COMMAND         = 'ssh kyrill "'
   squall_COMMAND         = 'ssh squall "'

   WRF_WORKAREA          =  wrf_program_root_dir+'/WRFV3/test/em_real/'
   WPS_LNKGRID_CMD       =  wrf_program_root_dir+'WPS/link_grib.csh '
   WPS_UNGRIB_CMD        =  wrf_program_root_dir+'WPS/ungrib.exe ' ;> ungrib.output'
   WPS_METGRID_CMD       =  wrf_program_root_dir+'WPS/metgrid.exe ';> metgrid.output'


   WPS_WORKAREA          = '/home/wjc/WRF_REALTIME/WPSWORK/'



   WRF_REAL_CMD          = ' nohup    real.exe   >& real.log  '
   WRF_WRF_CMD           = ' nohup    wrf.exe    >& wrf.log '

   WRF_REAL_CMD          = ' nohup mpiexec -f ~/nodeswrf -np '+ NUMBEROFPROCS + ' real.exe    '
   WRF_WRF_CMD           = ' nohup mpiexec -f ~/nodeswrf -np '+ NUMBEROFPROCS + ' wrf.exe    '



   NT_SUBOUTFILES =  SHORTRUN_DT/WRFOUT_DT + 1

   SPAWN, 'mkdir -v '   + WRF_OUTSTORE
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
          SPAWN, 'rm -frv ' + WRF_WORKAREA + 'KRAP.d0?.??'

          SPAWN, 'rm -frv ' + WPS_WORKAREA + 'met_em*.nc'
          SPAWN, 'rm -frv ' + WPS_WORKAREA + 'GRIBFILE*'
          SPAWN, 'rm -frv ' + WRF_WORKAREA + 'sfc_obs*
          SPAWN, 'rm -frv ' + WRF_WORKAREA + 'obs*'
          SPAWN, 'rm -frv ' + WRF_WORKAREA + 'Wrfinput*'
          SPAWN, 'rm -frv ' + WRF_WORKAREA + 'wrfbdy*'
          SPAWN, 'rm -frv ' + WRF_WORKAREA + 'OBS*'
          SPAWN, 'rm -frv ' + WRF_WORKAREA + 'met_em*.nc'
          SPAWN, 'rm -frv ' + WPS_WORKAREA + 'nam*.grib2'
          SPAWN, 'cp -frv ' + wrf_program_root_dir + '/WRFDA/var/obsproc/obserr.txt '+WRF_WORKAREA
          SPAWN, 'cp -frv ' + wrf_program_root_dir + '/WRFDA/var/obsproc/prepbufr_table_filename '+WRF_WORKAREA

          ;;; BLOCK TO CREATE DATESTAMP

          UNGRIB_DATE_A = JULAIN_DATES_SHORTRUN_A(T)
          UNGRIB_DATE_B = JULAIN_DATES_SHORTRUN_B(T)

          CALDAT, UNGRIB_DATE_A, MONTH_UNGRIB_A, DAY_UNGRIB_A, YEAR_UNGRIB_A, HOUR_UNGRIB_A
          CALDAT, UNGRIB_DATE_B, MONTH_UNGRIB_B, DAY_UNGRIB_B, YEAR_UNGRIB_B, HOUR_UNGRIB_B

          NT_UNGRIB = LONG((UNGRIB_DATE_B - UNGRIB_DATE_A)*24L/GRIB_DT +1L)

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
                                                FORMAT='(I4.4,"-",I2.2,"-",I2.2,"_",I2.2,"_F",I2.2)')

          CALDAT, JULAIN_DATES_UNGRIB, MONTH_UNGRIB, DAY_UNGRIB, YEAR_UNGRIB, HOUR_UNGRIB

          UNGRIB_DATE_STRING  = STRARR(NT_UNGRIB)
          UNGRIB_DIR_STRING  = STRARR(NT_UNGRIB)
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
                                         FORMAT='(I4.4,"-",I2.2,"-",I2.2,"_",I2.2)')+ "_F" + string(TT*3,format='(I2.2)')

          FOR TT = 0L, NT_UNGRIB-1L DO $
               METEM_FILE_NAME(TT)    =  "met_em.d01." + $
	                                 STRING(YEAR_UNGRIB(TT),   $
                                         MONTH_UNGRIB(TT),  $
                                         DAY_UNGRIB(TT),    $
                                         HOUR_UNGRIB(TT),   $
                                         FORMAT='(I4.4,"-",I2.2,"-",I2.2,"_",I2.2,":00:00.nc")')


          FOR TT = 0L, NT_UNGRIB-1L DO $
               GRIB_FILE_MSS(TT) = GRIB_NCAR_DIR+ "/" + GRIB_PREFIX + UNGRIB_DATE_STRING(TT) +".grib2"

          FOR TT = 0L, NT_UNGRIB-1L DO $
               GRIB_FILE_LOCAL(TT) = GRIB_PREFIX + UNGRIB_DATE_STRING(TT)+ ".grib2"

 ;         FOR TT = 0L, NT_UNGRIB-1L DO $
 ;            SPAWN, 'gzip -fr9v ' + GRIB_FILE_MSS(TT) + "*"


          FOR TT = 0L, NT_UNGRIB-1L DO $
             SPAWN, 'scp squall:' + GRIB_FILE_MSS(TT) + ".gz ."
          FOR TT = 0L, NT_UNGRIB-1L DO $
             SPAWN, 'scp squall:' + GRIB_FILE_MSS(TT) + " ."
          FOR TT = 0L, NT_UNGRIB-1L DO $
             SPAWN, 'gunzip -fr9v ' + GRIB_FILE_LOCAL(TT) + "*"

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
             PRINTF, 1, " end_date   =  '" + SHORTRUN_DATE_STRING_B(T) + ":00:00','"+ SHORTRUN_DATE_STRING_B(T) + ":00:00','"+ SHORTRUN_DATE_STRING_B(T) + ":00:00',"
             PRINTF, 1, " interval_seconds =  " + string(GRIB_DT * 3600L, FORMAT='(I5.5)') + ","
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

          SPAWN, "time nohup " + WPS_UNGRIB_CMD


          ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

          GRIB_PREFIX_218       = 'nam218_'

          FOR TT = 0L, NT_UNGRIB-1L DO $
               GRIB_FILE_MSS(TT) = GRIB_NCAR_DIR+ $
                                    "/" + GRIB_PREFIX_218 + UNGRIB_DATE_STRING(TT) +".grib2"

          FOR TT = 0L, NT_UNGRIB-1L DO $
               GRIB_FILE_LOCAL(TT) = GRIB_PREFIX_218 + UNGRIB_DATE_STRING(TT)+ ".grib2"

          FOR TT = 0L, NT_UNGRIB-1L DO $
             SPAWN, 'scp squall:' + GRIB_FILE_MSS(TT) + " ."

          FOR TT = 0L, NT_UNGRIB-1L DO $
             SPAWN, 'ls -al ' + GRIB_FILE_LOCAL(TT)

          PRINT, '--- LINKING GRIB FILES ' + SHORTRUN_DATE_STRING_A(T)

          SPAWN, 'time ' + WPS_LNKGRID_CMD + ' ' + STRING(GRIB_FILE_LOCAL, FORMAT=ALL_GRIBFILE_FORMAT)

          ; spawn, 'cat '+WPS_WORKAREA + 'NAMELIST_WPS.DATESTAMPS'

          SPAWN,                    'cat ' + WPS_WORKAREA + 'NAMELIST_WPS.DATESTAMPS '   $
                                           + WPS_WORKAREA + 'NAMELIST_WPS.ROOT_BACKEND.218  > ' $
                                           + WPS_WORKAREA + 'namelist.wps'

          SPAWN,                    'cat ' + WPS_WORKAREA + 'NAMELIST_WPS.DATESTAMPS '   $
                                           + WPS_WORKAREA + 'NAMELIST_WPS.ROOT_BACKEND.218  > ' $
                                           + WPS_WORKAREA + 'namelist.wps'


          PRINT, 'UNPACKING GRIB218 FILES ' + SHORTRUN_DATE_STRING_A(T)

          SPAWN, "time nohup " + WPS_UNGRIB_CMD
          ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

          PRINT, 'CREATING METE_EM ' + SHORTRUN_DATE_STRING_A(T)

          SPAWN, "time nohup " + WPS_METGRID_CMD

          ;  SPAWN, kyrill_COMMAND + 'cd -v '+ WPS_WORKAREA + ' && ls -alt met_em*"'

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

          SPAWN, 'cp -frv  ' + WPS_WORKAREA + '/met_em*.nc ./'


          SPAWN, 'rm -fr '+ WRF_WORKAREA + '/rsl.*'

          SPAWN, 'rm -fr '+ WRF_WORKAREA + '/OBS_DOMAIN*'

         ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
         ;
         ;;;  nudgeprep

         nudge_data_dir = "/data/NCAR/UNIDATA_LITTLE_R/"

         JULIAN_DATE_NUDGE = TIMEGEN(NUDGING_PERIOD+1,      $
                                    START=START_JULIAN,   $
                                    STEP_SIZE=1, $
                                    UNITS='HOURS')

         CALDAT, JULIAN_DATE_NUDGE,  MONTH_NUDGE, DAY_NUDGE, YEAR_NUDGE, HOUR_NUDGE

         NUDGE_OBS_DATE_STRINGS = STRARR(NUDGING_PERIOD+1)

         VAR_OBS_DATE_STRINGS = STRARR(N_VARWIN)

         FOR TT = 0, N_VARWIN-1 DO $
             VAR_OBS_DATE_STRINGS(tt) = STRING(YEAR_VARWIN(TT),MONTH_VARWIN(TT),DAY_VARWIN(TT),HOUR_VARWIN(TT),FORMAT='(i4.4,"-",i2.2,"-",i2.2,"_",i2.2)')

         FOR TT = 0, NUDGING_PERIOD+1-1 DO $
             NUDGE_OBS_DATE_STRINGS(tt) = STRING(YEAR_NUDGE(TT),MONTH_NUDGE(TT),DAY_NUDGE(TT),HOUR_NUDGE(TT),FORMAT='(i4.4,"-",i2.2,"-",i2.2,"_",i2.2,"00")')

         FOR TT = 0L, NUDGING_PERIOD+1-1 DO $
             SPAWN, "scp kyrill:" + nudge_data_dir + "obs_" + NUDGE_OBS_DATE_STRINGS(TT) + ".txt.gz  ."

         print, "Getting raws data"
         FOR TT = 0L, N_VARWIN-1 DO begin
	         print,  "cp -v " + nudge_data_dir + "obs_" + VAR_OBS_DATE_STRINGS(TT) + '*.txt.gz  .'
             SPAWN, "cp -v " + nudge_data_dir + "obs_" + VAR_OBS_DATE_STRINGS(TT) + '*.txt.gz  .'
         endfor

         SPAWN, "gunzip -v  obs_*.gz"

         spawn, "cat obs_????-??-??_????.txt > obs_bigfile.txt"

         spawn, "RT_fdda_reformat_obsnud.pl obs_bigfile.txt"

         spawn, "mv -v obs_bigfile.txt.obsnud  OBS_DOMAIN101"

         spawn, "cp -v OBS_DOMAIN101  OBS_DOMAIN201"
         spawn, "cp -v OBS_DOMAIN101  OBS_DOMAIN301"
         print, "scp ./OBS_DOMAIN* "+ CO_NODE + ":"+WRF_WORKAREA+"/"
         spawn, "scp ./OBS_DOMAIN* "+ CO_NODE + ":"+WRF_WORKAREA+"/"

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
                PRINTF, 1, " interval_seconds      = " + STRING(GRIB_DT*3600L,    FORMAT='(I5.5)') + ","
                PRINTF, 1, " input_from_file       = .true., .true., .true.,"
                PRINTF, 1, " io_form_auxinput2     = 2,"
                printf, 1, " fine_input_stream     = 0,2,2,"
                PRINTF, 1, " history_interval      = " + STRING(WRFOUT_DT*60L,    FORMAT='(I5.5)') + "," + STRING(WRFOUT_DT*60L,    FORMAT='(I5.5)') + "," + STRING(WRFOUT_DT*60L,    FORMAT='(I5.5)') + ","
                PRINTF, 1, " frames_per_outfile    = 1,1,1,"
                PRINTF, 1, " restart               = .false.,"
                PRINTF, 1, " restart_interval      = " + STRING(WRF_RUN_INTERVAL*60L,  FORMAT='(I5.5)') + ","
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
                PRINTF, 1, " fine_input_stream  = 0,2,2,"
                PRINTF, 1, " history_interval   = " + STRING(WRFOUT_DT*60L,    FORMAT='(I5.5)') + "," + STRING(WRFOUT_DT*60L,    FORMAT='(I5.5)') + "," + STRING(WRFOUT_DT*60L,    FORMAT='(I5.5)') + ","
                PRINTF, 1, " frames_per_outfile = 1,1,1,"
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

         PRINT, '--- RUNNING REAL.EXE ' + SHORTRUN_DATE_STRING_A(T)
         ;     SPAWN, "ls -alt met_em.*.nc"
         spawn, "scp ./namelist.input "+ CO_NODE + ":"+WRF_WORKAREA+"/"
         print, 'time nohup ' + WRF_REAL_CMD
         SPAWN, 'time nohup ' + WRF_REAL_CMD

         IF ( FILE_TEST("./wrfinput_d01") EQ 0) THEN BEGIN
             PRINT, "REAL FAILED"
             SPAWN, "tail real.log"

             EXIT
         ENDIF

         SPAWN, 'cp -frv wrfinput_d01 wrfinput_d01.nmcinit.nc'
         SPAWN, 'cp -frv wrfinput_d02 wrfinput_d02.nmcinit.nc'

         SPAWN, 'cp -frv RECYCLE_FORECAST_D01.nc wrfinput_d01.wrfinit.nc'
         SPAWN, 'cp -frv RECYCLE_FORECAST_D02.nc wrfinput_d02.wrfinit.nc'

         SPAWN, 'rm -frv ./rsl* '

         WRF_INIT_INFO = FILE_INFO("./wrfinput_d01")
         help,WRF_INIT_INFO

         time_end_in_sec_wrfprep = systime(/seconds)
         time_start_in_sec_wrf = systime(/seconds)

          PRINT, '--- RUNNING WRF.EXE WITH NUDGING' + SHORTRUN_DATE_STRING_A(T)
                    SPAWN, ' cp namelist.input.wrf namelist.input'
                    spawn, "scp ./wrfbdy_d01 "     + CO_NODE + ":" + WRF_WORKAREA+"/"
                    spawn, "scp ./wrfinput_d01 "   + CO_NODE + ":" + WRF_WORKAREA+"/"
                    spawn, "scp ./wrfinput_d02 "   + CO_NODE + ":" + WRF_WORKAREA+"/"
                    spawn, "scp ./namelist.input " + CO_NODE + ":" + WRF_WORKAREA+"/"
                    print, 'time  ' + WRF_WRF_CMD
          SPAWN, 'time  ' + WRF_WRF_CMD

          ;; check if there was an error

          WRF_FILENAMES    = "wrfout_d01_" +  SUBOUT_DATE_STRING
          WRF_SM_FILENAMES = "wrfout_d01_" +  SUBOUT_DATE_STRING_SM + ".nc"

          SPAWN, "echo Nudging Enabled > /home/wjc/WRF_REALTIME/nudge.status.txt"

          IF ( FILE_TEST( WRF_FILENAMES(NT_SUBOUTFILES-1)) EQ 0) THEN BEGIN

            ; SPAWN, "tail wrf.log"

             PRINT, "WRF WITH NUDGING FAILED "
             SPAWN, "cat rsl.error.0000"
             SPAWN, "rm -frv rsl*"

             SPAWN, 'cat '+ WRF_WORKAREA + 'NAMELIST.DATESTAMP.NONUDGE '   $
                          + WRF_WORKAREA + 'NAMELIST.ROOT_END.NONUDGE > ' $
                          + WRF_WORKAREA + 'namelist.input'

              PRINT, '--- RUNNING WRF.EXE WITHOUT NUDGING' + SHORTRUN_DATE_STRING_A(T)
              SPAWN, "scp ./namelist.input " + CO_NODE + ":" + WRF_WORKAREA+"/"
              PRINT, 'time  ' + WRF_WRF_CMD
              SPAWN, 'time  ' + WRF_WRF_CMD

              SPAWN, "echo Nudging Disabled > /home/wjc/WRF_REALTIME/nudge.status.txt"

              IF ( FILE_TEST( WRF_FILENAMES(NT_SUBOUTFILES-1)) EQ 0) THEN BEGIN
                 SPAWN, "cat rsl.error.0000"
                 PRINT, "WRF WITHOUT NUDGING FAILED "
                 STOP
              ENDIF

          ENDIF

          time_end_in_sec_wrf       = systime(/seconds)
          time_start_in_sec_wrfpost = systime(/seconds)

          SPAWN, 'cp -frv wrfinput_d01  wrfinput_d01.varinit.nc'
          SPAWN, 'cp -frv wrfinput_d02  wrfinput_d02.varinit.nc'

          WRF_FILENAMES    = "wrfout_d01_" +  SUBOUT_DATE_STRING
          WRF_SM_FILENAMES = "wrfout_d01_" +  SUBOUT_DATE_STRING_SM + ".nc"
          FOR TT = 0L, NT_SUBOUTFILES-1L DO $
              SPAWN, '/usr/local/netcdf/bin/nccopy  -k 3 ' + WRF_FILENAMES(TT) + ' ' + WRF_SM_FILENAMES(TT)
          FOR TT = 0L, NT_SUBOUTFILES-1L DO $
              SPAWN, 'rm -v ' + WRF_FILENAMES(TT)


          WRF_FILENAMES    = "wrfout_d02_" +  SUBOUT_DATE_STRING
          WRF_SM_FILENAMES = "wrfout_d02_" +  SUBOUT_DATE_STRING_SM + ".nc"
          FOR TT = 0L, NT_SUBOUTFILES-1L DO $
              SPAWN, '/usr/local/netcdf/bin/nccopy   -k 3   ' + WRF_FILENAMES(TT) + ' ' + WRF_SM_FILENAMES(TT)
          FOR TT = 0L, NT_SUBOUTFILES-1L DO $
              SPAWN, 'rm -v ' + WRF_FILENAMES(TT)


          ; WRF_FILENAMES    = "wrfout_d03_" +  SUBOUT_DATE_STRING
          ; WRF_SM_FILENAMES = "wrfout_d03_" +  SUBOUT_DATE_STRING_SM + ".nc"
          ; FOR TT = 0L, NT_SUBOUTFILES-1L DO $
          ;     SPAWN, 'nccopy -k 3 -d 9 ' + WRF_FILENAMES(TT) + ' ' + WRF_SM_FILENAMES(TT)
          ; FOR TT = 0L, NT_SUBOUTFILES-1L DO $
          ;     SPAWN, 'rm -v ' + WRF_FILENAMES(TT)

          SPAWN, "ncl "+wrf_home_dir+"ts2nc.ncl"

          WRF_FILENAMES = WRF_FILENAMES  + '.nc '

          ; SPAWN, 'gzip -frv9 wrfout*.nc '

          SPAWN, 'cp -v ./wrfout*.nc*   ' + WRF_OUTSTORE

          SPAWN, "scp  /home/wjc/WRF_REALTIME/*.status.txt kyrill:/projects/WRF_REALTIME/OUTPUT_PNG/currentRAP"
          SPAWN, "scp  /home/wjc/WRF_REALTIME/*.status.txt wjc@kyrill:/var/www/html/firemet/wrf_rap"

          SPAWN, 'rm -frv rsl* wrfout*.nc* wrfrst_d0*'

          FOR TT = 0L, NT_UNGRIB-1L DO $
             SPAWN, 'rm -frv ' + WPS_WORKAREA + GRIB_FILE_LOCAL(TT)

   ENDFOR

   spawn, 'ls -l '+ WRF_WORKAREA  +'be_rap_d??.dat >   /home/wjc/WRF_REALTIME/background_error_file.txt'
   spawn, "sed -i 's/lrwxrwxrwx. 1 wjc iasuser/<br>/g' /home/wjc/WRF_REALTIME/background_error_file.txt"
   spawn, "sed -i 's/82//g'                            /home/wjc/WRF_REALTIME/background_error_file.txt"
   spawn, "sed -i 's/home//g'                          /home/wjc/WRF_REALTIME/background_error_file.txt"
   spawn, "sed -i 's/wjc//g'                           /home/wjc/WRF_REALTIME/background_error_file.txt"
   spawn, "sed -i 's/WRF_REALTIME_KUNR-3DOM//g'        /home/wjc/WRF_REALTIME/background_error_file.txt"
   spawn, "sed -i 's/WRF_REALTIME//g'                  /home/wjc/WRF_REALTIME/background_error_file.txt"
   spawn, "sed -i 's/'"+wrf_version+"'//g'             /home/wjc/WRF_REALTIME/background_error_file.txt"
   spawn, "sed -i 's/WRFV3//g'                         /home/wjc/WRF_REALTIME/background_error_file.txt"
   spawn, "sed -i 's/test//g'                          /home/wjc/WRF_REALTIME/background_error_file.txt"
   spawn, "sed -i 's/em_real//g'                       /home/wjc/WRF_REALTIME/background_error_file.txt"

   wrf_home_dir = "/home/wjc/WRF_REALTIME/"
   cd, wrf_home_dir

   spawn, "cp -frv /home/wjc/WRF_REALTIME/current_day.txt /home/wjc/WRF_REALTIME/current_day_meteogram.txt"
   spawn, "cat /home/wjc/WRF_REALTIME/current_day.txt /home/wjc/WRF_REALTIME/current_day_meteogram.txt"
   spawn, "scp /home/wjc/WRF_REALTIME/current_day_meteogram.txt wjc@kyrill:/home/wjc/WRF_REALTIME_WEB"
   spawn, "scp  /home/wjc/WRF_REALTIME/current_day.txt kyrill://var/www/html/firemet/wrf_rap/"
   spawn,  wrf_home_dir+ "ncl_graphics_scripts_cold.csh"

   model_run_datetime = STRING(START_YEAR,   $
                               START_MONTH,  $
                               START_DAY,    $
                               START_HOUR,   $
                               FORMAT='(I4.4,"-",I2.2,"-",I2.2,"_",I2.2)')

   PNGDIR =   "/projects/WRF_REALTIME/OUTPUT_PNG/" + model_run_datetime


   for domaincodeindex = 1, 2 do begin

       domaincode = "d" + string(domaincodeindex, format="(I2.2)")

       ;openr, 1, "current_day.txt"
       ;model_run_datetime = " "
       ;readf, 1, model_run_datetime
       ;close, 1

       openw, 1, PNGDIR + "/" + domaincode+ ".php"

       printf, 1, '<html>'
       printf, 1, ' <h1>'
       printf, 1, '   WRF Forecast for ' + model_run_datetime
       printf, 1, '</h1>'
       printf, 1, 'Approved use of products is limited to educational use within SDSMT-Atmospheric Sciences only.<br>'
       printf, 1, 'Direct all queries to Bill Capehart <a href="mailto:William.Capehart@sdsmt.edu">William.Capehart@sdsmt.edu</a>.<br>'

       printf, 1, ' <a href="./d03.php">Black Hills domain (&#x394;1-km)</a>  FORECASTS FOR THIS DOMAIN ARE TEMPORARILY SUSPENDED<br>'
       printf, 1, '  <a href="./d02.php">Western SD domain (&#x394;3-km)</a><br>'
       printf, 1, ' <a href="./d01.php">Northern Great Plains domain (&#x394;9-km)</a><br>'
       printf, 1, ' '
       printf, 1, '<p>'
       printf, 1, '<a href="' +  domaincode + '/wrf_plot_TOTALPREC_' + domaincode + '_' + model_run_datetime + '.png">'
       printf, 1, '   <img SRC="' +  domaincode + '/wrf_plot_TOTALPREC_' + domaincode + '_' + model_run_datetime + '.png" height=400 width=400></a>'
       printf, 1, '&nbsp; &nbsp;'
       printf, 1, '<a href="' +  domaincode + '/wrf_plot_STREAM_' + domaincode + '_' + model_run_datetime + '.gif">'
       printf, 1, '   <img SRC="' +  domaincode + '/wrf_plot_STREAM_' + domaincode + '_' + model_run_datetime + '.gif" height=400 width=400></a><p>'
       printf, 1, ''
       printf, 1, '<a href="' +  domaincode + '/wrf_plot_PREC_' + domaincode + '_' + model_run_datetime + '.gif">'
       printf, 1, '   <img SRC="' +  domaincode + '/wrf_plot_PREC_' + domaincode + '_' + model_run_datetime + '.gif"  height=400 width=400></a>'
       printf, 1, '&nbsp; &nbsp;'
       printf, 1, '<a href="' +  domaincode + '/wrf_plot_SFC_' + domaincode + '_' + model_run_datetime + '.gif">'
       printf, 1, '   <img SRC="' +  domaincode + '/wrf_plot_SFC_' + domaincode + '_' + model_run_datetime + '.gif"  height=400 width=400></a><p>'
       printf, 1, ''
       printf, 1, '<a href="' +  domaincode + '/wrf_plot_SNOWFALL_' + domaincode + '_' + model_run_datetime + '.gif">'
       printf, 1, '   <img SRC="' +  domaincode + '/wrf_plot_SNOWFALL_' + domaincode + '_' + model_run_datetime + '.gif"  height=400 width=400></a>'
       printf, 1, '&nbsp; &nbsp;'
       printf, 1, '<a href="' +  domaincode + '/wrf_plot_TOTALSNOWFALL_' + domaincode + '_' + model_run_datetime + '.png">'
       printf, 1, '   <img SRC="' +  domaincode + '/wrf_plot_TOTALSNOWFALL_' + domaincode + '_' + model_run_datetime + '.png"  height=400 width=400></a><p>'
       printf, 1, '<p>'
       printf, 1, ''
       printf, 1, ''
       if (domaincodeindex eq 2) then printf, 1, '<a href="'  +  domaincode + '/wrf_plot_SKEWT_' + domaincode + '_' + model_run_datetime + '.gif">'
       if (domaincodeindex eq 2) then printf, 1, '<img SRC="' +  domaincode + '/wrf_plot_SKEWT_' + domaincode + '_' + model_run_datetime + '.gif"></a>'
       printf, 1, ''
       printf, 1, ''
       printf, 1, '</html>'

       close, 1
       if (domaincodeindex ge max_domains) then spawn, "cp -frv " +  PNGDIR + "/" + domaincode+ ".php"  +  " " + PNGDIR + "/index.html"

   endfor


   time_end_in_sec_wrfpost = systime(/seconds)
   time_end_in_sec = systime(/seconds)

   print, 'And We are Done.  Total Time = ',(time_end_in_sec - time_start_in_sec)/3600.0," hours"

   print, '        WPS Time = ',   (time_end_in_sec_wps     - time_start_in_sec_wps     )/60.0  , ' minutes (' , (time_end_in_sec_wps     - time_start_in_sec_wps     )/3600.0 , ' hours)</br>'  ;
   print, '   WRF PREP Time = ',   (time_end_in_sec_wrfprep - time_start_in_sec_wrfprep )/60.0  , ' minutes (' , (time_end_in_sec_wrfprep - time_start_in_sec_wrfprep )/3600.0 , ' hours)</br>'  ;
   print, '    WRF RUN Time = ',   (time_end_in_sec_wrf     - time_start_in_sec         )/60.0  , ' minutes (' , (time_end_in_sec_wrf     - time_start_in_sec         )/3600.0 , ' hours)</br>'  ;
   print, '   WRF POST Time = ',   (time_end_in_sec_wrfpost - time_start_in_sec_wrfpost )/60.0  , ' minutes (' , (time_end_in_sec_wrfpost - time_start_in_sec_wrfpost )/3600.0 , ' hours)</br>'  ;
   print, '      TOTAL Time = ',   (time_end_in_sec         - time_start_in_sec         )/60.0  , ' minutes (' , (time_end_in_sec         - time_start_in_sec         )/3600.0 , ' hours)</br>'  ;

   final_clocktime = systime(/UTC) + " UTC"


   openw, 11, "/projects/WRF_REALTIME/OUTPUT_PNG/currentRAP/timings.txt"
      printf, 11, '        WPS Time = ',   (time_end_in_sec_wps     - time_start_in_sec_wps     )/60.0  , ' minutes (' , (time_end_in_sec_wps     - time_start_in_sec_wps     )/3600.0 , ' hours)<br>'  ;
      printf, 11, '   WRF PREP Time = ',   (time_end_in_sec_wrfprep - time_start_in_sec_wrfprep )/60.0  , ' minutes (' , (time_end_in_sec_wrfprep - time_start_in_sec_wrfprep )/3600.0 , ' hours)<br>'  ;
      printf, 11, '    WRF RUN Time = ',   (time_end_in_sec_wrf     - time_start_in_sec         )/60.0  , ' minutes (' , (time_end_in_sec_wrf     - time_start_in_sec         )/3600.0 , ' hours)<br>'  ;
      printf, 11, '   WRF POST Time = ',   (time_end_in_sec_wrfpost - time_start_in_sec_wrfpost )/60.0  , ' minutes (' , (time_end_in_sec_wrfpost - time_start_in_sec_wrfpost )/3600.0 , ' hours)<br>'  ;
      printf, 11, '      TOTAL Time = ',   (time_end_in_sec         - time_start_in_sec         )/60.0  , ' minutes (' , (time_end_in_sec         - time_start_in_sec         )/3600.0 , ' hours)<br>'  ;
      printf, 11,  ' FINAL END TIME = ' + final_clocktime


   close, 11


   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; run UPP
      spawn, wrf_program_root_dir + "/UPPV3.0/scripts/run_unipost_SDSMT >& /home/wjc/WRF_REALTIME/UPP.log"



END

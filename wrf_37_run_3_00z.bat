setenv OMP_NUM_THREADS 24
cp -frv /home/wcapehart/tools/timegen.pro /home/wcapehart/
cp -frv /home/wcapehart/tools/timegen.pro /home/wcapehart/WRFV381_TKE/
cp -frv /home/wcapehart/tools/timegen.pro /home/wcapehart/WRFV381_TKE/


nohup /usr/bin/gdl   << endidl
.run /home/wcapehart/WRFV381_TKE/wrf370gfs25_realtime_var_cold_d03_rap_00Z.pro 
endidl


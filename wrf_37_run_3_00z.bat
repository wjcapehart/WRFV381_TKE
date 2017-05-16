cp -frv /home/wcapehart/tools/timegen.pro /home/wcapehart/
cp -frv /home/wcapehart/tools/timegen.pro /home/wcapehart/WRFV381_TKE/
cp -frv /home/wcapehart/tools/timegen.pro /home/wcapehart/WRFV381_TKE/




PATH=$PATH:$HOME/bin:$NETCDF/bin:$NETCDF/lib
export PATH

GDL_STARTUP=/home/wcapehart/.gdl_startup
export GDL_STARTUP

source ~/bin/loadpackage.sh openmpi





nohup /usr/bin/gdl   << endidl
.run /home/wcapehart/WRFV381_TKE/wrf370gfs25_realtime_var_cold_d03_rap_00Z.pro
endidl

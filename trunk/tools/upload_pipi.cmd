set rel_path=double-dragon-fpga\build

cd ..\..
fpgaprog -d "400100000001A" -f %rel_path%\pipistrello_top.bit

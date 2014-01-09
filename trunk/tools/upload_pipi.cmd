set rel_path=double-dragon-fpga\build

cd ..\..
fpgaprog -d "Pipistrello LX45 A" -f %rel_path%\pipistrello_top.bit

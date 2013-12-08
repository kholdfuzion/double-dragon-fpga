set rel_path=double-dragon-fpga\build

cd ..\..
fpgaprog                                  -f %rel_path%\pipistrello_top.bit

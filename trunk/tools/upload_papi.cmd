set rel_path=double-dragon-fpga\build

cd ..\..
copy/b %rel_path%\..\roms\ddragon\21j-6 + %rel_path%\..\roms\ddragon\21j-7 %rel_path%\adpcm.bin
fpgaprog -Sa -B bscan_sram_lx9_qfp144.bit -f %rel_path%\adpcm.bin
fpgaprog                                  -f %rel_path%\papilio_top.bit

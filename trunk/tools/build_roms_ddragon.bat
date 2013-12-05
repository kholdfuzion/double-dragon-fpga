@echo off

REM SHA1 sums of files required
REM da997d9cc7b9e7b2c70a4b6d30db693086a6f7d8 21j-0-1
REM 0983705ea3bb87c4c239692f400e02f15c243479 21j-1-5.26
REM 4b8f22225d10f5414253ce0383bbebd6f720f3af 21j-2-3.25
REM d9038c80646a6ce3ea61da222873237b0383680e 21j-3.24
REM d7442be24d41bb9fc021587ef44ae5b830e4503d 21j-4-1.23
REM 8368182234f9d4d763d4714fd7567a9e31b7ebeb 21j-5
REM 57c06d6ce9497901072fa50a92b6ed0d2d4d6528 21j-6
REM 3623e5ea05fd7c455992b7ed87e605b87c3850aa 21j-7
REM ecb76f2148fa9773426f05aac208eb3ac02747db 21j-8
REM f156c337f48dfe4f7e9caee9a72c7ea3d53e3098 21j-9
REM 481fe574cb79d0159a65ff7486cbc945d50538c5 21j-a
REM 74581a4b6f48100bddf20f319903af2fe36f39fa 21j-b
REM 37b2225e0593335f636c1e5fded9b21fdeab2f5a 21j-c
REM 9f2270f9ceedfe51c5e9a9bbb00d6f43dbc4a3ea 21j-d
REM 25c534d82bd237386d447d72feee8d9541a5ded4 21j-e
REM a301ff809be0e1471f4ff8305b30c2fa4aa57fae 21j-f
REM 24a16ea509e9aff82b9ddd14935d61bb71acff84 21j-g
REM f177ba9c1c7cc75ff04d5591b9865ee364788f94 21j-h
REM 1f21acb15dad824e831ed9a42b3fde096bb31141 21j-i
REM 7953316712c56c6f8ca6bba127319e24b618b646 21j-j
REM 4c4f214229b9fab2b5d69c745ec5428787b89e1f 21j-k-0
REM 64f4c42a826d67b7cbaa8a23a45ebc4eb6248891 21j-l-0
REM e2a194e38633592fd6587690b3cb2669d93985c7 21jm-0.ic55

set rom_path_src=..\roms
set rom_path=..\build
set romgen_path=.

mkdir %rom_path%
REM generate RAMB structures for larger ROMS

REM romgen can't handle 32K ROMs so I manually split ROM file "21j-0-1" in two
%romgen_path%\romgen %rom_path_src%\21j-0-1.0 ROM_21J00 14 l r e > %rom_path%\ROM_21J00.vhd
%romgen_path%\romgen %rom_path_src%\21j-0-1.1 ROM_21J01 14 l r e > %rom_path%\ROM_21J01.vhd

echo done
pause

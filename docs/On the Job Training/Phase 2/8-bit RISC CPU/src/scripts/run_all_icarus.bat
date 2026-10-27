@echo off
REM ============================================================================
REM File    : scripts\run_all_icarus.bat   (Windows version of run_all_icarus.sh)
REM Project : 8-bit RISC CPU, 5-stage pipeline (8-bit upgrade of the 4-bit CPU)
REM Author  : Vu Quoc Anh (SE203519)
REM Needs   : python, iverilog and vvp on the PATH
REM ============================================================================
setlocal enabledelayedexpansion
cd /d "%~dp0\.."
if not exist build mkdir build
python scripts\asm8.py asm\demo.asm rtl\program.mem
for %%P in (prog_arith prog_logic prog_mem prog_branch prog_wrap) do python scripts\asm8.py asm\%%P.asm tb\%%P.mem
copy /y rtl\*.mem build\ > nul
copy /y tb\*.mem  build\ > nul
set FAIL=0
for %%T in (tb_alu tb_mux2 tb_mux3 tb_register_file tb_program_counter tb_instruction_memory tb_instruction_register tb_control_unit tb_hazard_unit tb_halt_unit tb_forwarding_unit tb_id_ex_register tb_flag_register tb_ex_mem_register tb_data_memory tb_mem_wb_register tb_cpu) do (
    iverilog -g2001 -Wall -s %%T -c scripts/files.f -o build/%%T.vvp tb/%%T.v 2> build\%%T.compile.log
    if errorlevel 1 ( echo    FAILED: %%T did not compile & set FAIL=1 ) else (
        pushd build & vvp -n %%T.vvp > %%T.log 2>&1 & popd
        findstr /B /C:"PASS:" /C:"FAILED:" build\%%T.log
        findstr /B /C:"PASS:" build\%%T.log > nul || set FAIL=1 )
)
if !FAIL!==0 (echo ALL PASS ^(Vu Quoc Anh, SE203519^)) else (echo SOME CHECKS FAILED)
exit /b !FAIL!

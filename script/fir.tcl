variable dispScriptFile [file normalize [info script]]

proc getScriptDirectory {} {
    variable dispScriptFile
    set scriptFolder [file dirname $dispScriptFile]
    return $scriptFolder
}

set sdir [getScriptDirectory]
cd [getScriptDirectory]

# KORAK#1: Definisanje direktorijuma u kojima ce biti smesteni projekat i konfiguracioni fajl
set resultDir ..\/result
file mkdir $resultDir

create_project FIR_redudancy  $resultDir -part xc7z020clg400-1 -force
set_property board_part xilinx.com:zc702:part0:1.0 [current_project]
set_property target_language VHDL [current_project]

# # ===================================================================================
# # Ukljucivanje hdl fajlova u projekat
# # ===================================================================================

add_files -norecurse ../Projekat-sa-FIR-filtrom-i-otpornoscu-na-greske/hdl/top_structure.vhd
add_files -norecurse ../Projekat-sa-FIR-filtrom-i-otpornoscu-na-greske/hdl/BRAM.vhd
add_files -norecurse ../Projekat-sa-FIR-filtrom-i-otpornoscu-na-greske/hdl/fir_param.vhd
add_files -norecurse ../Projekat-sa-FIR-filtrom-i-otpornoscu-na-greske/hdl/mac.vhd
add_files -norecurse ../Projekat-sa-FIR-filtrom-i-otpornoscu-na-greske/hdl/big_voter.vhd
add_files -norecurse ../Projekat-sa-FIR-filtrom-i-otpornoscu-na-greske/hdl/voter.vhd
add_files -norecurse ../Projekat-sa-FIR-filtrom-i-otpornoscu-na-greske/hdl/txt_util.vhd
add_files -norecurse ../Projekat-sa-FIR-filtrom-i-otpornoscu-na-greske/hdl/util_pkg.vhd

# set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset constrs_1 ../Projekat-sa-FIR-filtrom-i-otpornoscu-na-greske/hdl/constr.xdc
add_files -fileset sim_1 -norecurse ../Projekat-sa-FIR-filtrom-i-otpornoscu-na-greske/hdl/tb.vhd
add_files -fileset sim_1 -norecurse ../Projekat-sa-FIR-filtrom-i-otpornoscu-na-greske/hdl/force.tcl
update_compile_order -fileset sources_1

# # ===================================================================================
# # Pokretanje sinteze
# # ===================================================================================

set_property -name {STEPS.SYNTH_DESIGN.ARGS.MORE OPTIONS} -value {-mode out_of_context} -objects [get_runs synth_1]
launch_runs synth_1
wait_on_run synth_1
puts "*****************************************************"
puts "* Sinteza zavrsena! *"
puts "*****************************************************"


# # ===================================================================================
# # Pokretanje  implementacije
# # ===================================================================================
launch_runs impl_1
wait_on_run impl_1
# set time_i 400
# for {set x 4} {$x < 6} {incr x 1} {
 # incr time_i 400  
 # }
#add_force {/tb/data_o} -radix hex {0 20000ns} -cancel_after 26000ns
#add_force {/tb/top_structure/\gen_FIR_other_modules(1)\/FIR_others/data_o_FIR} -radix hex {0 10000ns} -cancel_after 12000ns
add_force {/tb/top_structure/\gen_FIR_other_modules(2)\/FIR_others/data_o_FIR} -radix hex {0 10000ns} -cancel_after 12000ns
incr time_i 16000  



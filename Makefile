
.PHONY: all lint join_fadd run_join_fadd

all: 
	@echo "Select the set of tests to run"


lint:
	verilator --assert -I./rtl --Wall --lint-only --top-module top_2core2dr ./rtl/*.v

REGLIST:=
###########################
join_fadd:
	verilator --assert --debug-check -I./rtl --Wall --cc --trace ./rtl/join_fadd.v ./rtl/fflop.v --exe tests/join_fadd_tb.cpp -CFLAGS "-DTRACE=1 -DVL_DEBUG"
	make -C obj_dir/ -f Vjoin_fadd.mk Vjoin_fadd

run_join_fadd: join_fadd
	./obj_dir/Vjoin_fadd

REGLIST+=join_fadd
###########################
fork_fflop:
	verilator --assert --debug-check -I./rtl --Wall --cc --trace ./rtl/fork_fflop.v ./rtl/fflop.v --exe tests/fork_fflop_tb.cpp -CFLAGS "-DTRACE=1 -DVL_DEBUG"
	make -C obj_dir/ -f Vfork_fflop.mk Vfork_fflop

run_fork_fflop: fork_fflop
	./obj_dir/Vfork_fflop

#REGLIST+=fork_fflop
###########################
l2:
	verilator --assert --debug-check -I./rtl --Wall --cc --trace --top-module l2cache_pipe_wp ./tests/l2cache_pipe_wp.v ./rtl/fflop.v --exe ./tests/l2cache_pipe_wp_tb.cpp -CFLAGS -DTRACE=1 #--exe tests/ram_1port_fast_wp_tb.cpp -CFLAGS -DTRACE=1
	make -C obj_dir/ -f Vl2cache_pipe_wp.mk Vl2cache_pipe_wp

run_l2: l2
	./obj_dir/Vl2cache_pipe_wp

###########################
ram_1port_fast_wp:
	verilator --assert --debug-check -I./rtl --Wall --cc --trace --top-module ram_1port_fast_wp ./rtl/ram_1port_fast.v ./tests/ram_1port_fast_wp.v ./rtl/fflop.v --exe tests/ram_1port_fast_wp_tb.cpp -CFLAGS -DTRACE=1
	make -C obj_dir/ -f Vram_1port_fast_wp.mk Vram_1port_fast_wp

run_ram_1port_fast_wp: ram_1port_fast_wp
	./obj_dir/Vram_1port_fast_wp

REGLIST+=ram_1port_fast_wp
###########################
ram_1port_dense_wp:
	verilator --assert --debug-check -I./rtl --Wall --cc --trace --top-module ram_1port_dense_wp ./rtl/ram_1port_dense.v ./tests/ram_1port_dense_wp.v ./rtl/fflop.v --exe tests/ram_1port_dense_wp_tb.cpp -CFLAGS -DTRACE=1
	make -C obj_dir/ -f Vram_1port_dense_wp.mk Vram_1port_dense_wp

run_ram_1port_dense_wp: ram_1port_dense_wp
	./obj_dir/Vram_1port_dense_wp

REGLIST+=ram_1port_dense_wp
###########################
pfengine_wp:
	verilator --assert --debug-check -I./rtl --Wall --cc --trace --top-module pfengine_wp ./rtl/pfengine.v ./tests/pfengine_wp.v ./rtl/fflop.v ./rtl/flop.v --exe tests/pfengine_wp_tb.cpp -CFLAGS -DTRACE=1
	make -C obj_dir/ -f Vpfengine_wp.mk Vpfengine_wp

run_pfengine_wp: pfengine_wp
	./obj_dir/Vpfengine_wp

REGLIST+=pfengine_wp
###########################
directory_bank_wp:
	verilator --assert --debug-check -I./rtl --Wall --cc --trace --top-module directory_bank_wp ./tests/directory_bank_wp.v ./rtl/directory_bank.v ./rtl/fflop.v ./rtl/flop_r.v --exe tests/directory_bank_wp_tb.cpp -CFLAGS -DTRACE=1
	make -C obj_dir/ -f Vdirectory_bank_wp.mk Vdirectory_bank_wp

run_directory_bank_wp: directory_bank_wp
	./obj_dir/Vdirectory_bank_wp

#REGLIST+=directory_bank_wp
###########################
integration_2core2dr:
	verilator --assert --debug-check -I./rtl --Wall --cc --trace --top-module integration_2core2dr ./tests/integration_2core2dr.v ./rtl/top_2core2dr.v ./rtl/fflop.v --exe tests/integration_2core2dr_tests.cpp -CFLAGS -DTRACE=1
	make -C obj_dir/ -f Vintegration_2core2dr.mk Vintegration_2core2dr

run_integration_2core2dr: integration_2core2dr
	./obj_dir/Vintegration_2core2dr

REGLIST+=integration_2core2dr
###########################
regression: lint $(REGLIST)
	ruby scripts/regcheck.rb $(REGLIST)

clean:
	rm -rf obj_dir *.vcd a.out


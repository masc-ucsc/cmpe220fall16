
all: 
	@echo "Select the set of tests to run"


lint:
	verilator --assert -I./rtl --Wall --lint-only --top-module net_2core2dr ./rtl/*.v

REGLIST:=
###########################
join_fadd:
	verilator --assert --debug-check -I./rtl --Wall --cc --trace ./rtl/join_fadd.v ./rtl/fflop.v --exe tests/join_fadd_tb.cpp -CFLAGS -DTRACE=1
	make -C obj_dir/ -f Vjoin_fadd.mk Vjoin_fadd

run_join_fadd: join_fadd
	./obj_dir/Vjoin_fadd

REGLIST+=join_fadd
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

#REGLIST+=ram_1port_dense_wp
###########################
regression: lint $(REGLIST)
	./scripts/regcheck.rb $(REGLIST)

clean:
	rm -rf obj_dir output.vcd a.out


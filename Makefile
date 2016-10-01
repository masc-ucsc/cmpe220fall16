
all: 
	@echo "Select the set of tests to run"

regression: lint

lint:
	verilator --assert -I./rtl --Wall --lint-only --top-module net_2core2dr ./rtl/*.v

join_fadd:
	verilator --assert --debug-check -I./rtl --Wall --cc --trace ./rtl/join_fadd.v ./rtl/fflop.v --exe tests/join_fadd_tb.cpp -CFLAGS -DTRACE=1
	make -C obj_dir/ -f Vjoin_fadd.mk Vjoin_fadd

run_join_fadd: join_fadd
	./obj_dir/Vjoin_fadd

clean:
	rm -rf obj_dir output.vcd a.out



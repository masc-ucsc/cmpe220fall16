
#include "Vdirectory_bank_wp.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <list>

#include <time.h>

#define DEBUG_TRACE 1

vluint64_t global_time = 0;
VerilatedVcdC* tfp = 0;

void advance_half_clock(Vdirectory_bank_wp *top) {
#ifdef TRACE
  tfp->dump(global_time);
#endif

  top->eval();
  top->clk = !top->clk;
  top->eval();

  global_time++;
  if (Verilated::gotFinish())  
    exit(0);
}

void advance_clock(Vdirectory_bank_wp *top, int nclocks=1) {

  for( int i=0;i<nclocks;i++) {
    for (int clk=0; clk<2; clk++) {
      advance_half_clock(top);
    }
  }
}

void sim_finish(bool pass) {
#ifdef TRACE
  tfp->close();
#endif

  if (pass)
    printf("\nTB:PASS\n");
  else
    printf("\nTB:FAILED\n");

  exit(0);
}

struct InputPacket {
  int we;
  uint16_t data;
  uint8_t  addr;
};

struct OutputPacket {
  uint16_t data; // read result
};

double sc_time_stamp() {
  return 0;
}

uint16_t memory[256];

std::list<InputPacket>  inp_list;
std::list<OutputPacket> out_list;

void error_found(Vdirectory_bank_wp *top) {
  advance_half_clock(top);
  advance_half_clock(top);
  sim_finish(false);
}



int main(int argc, char **argv, char **env) {
  int i;
  int clk;
  Verilated::commandArgs(argc, argv);
  // init top verilog instance
  Vdirectory_bank_wp *top = new Vdirectory_bank_wp;

  int t = (int)time(0);
  srand(t);
  printf("My RAND Seed is %d\n",t);

#ifdef TRACE
  // init trace dump
  Verilated::traceEverOn(true);
  tfp = new VerilatedVcdC;

  top->trace(tfp, 99);
  tfp->open("output.vcd");
#endif

  // initialize simulation inputs
  top->clk = 1;
  top->reset = 1;

  advance_clock(top,1024);  // Long reset to give time to the state machine
  //-------------------------------------------------------
  top->reset = 0;

  advance_clock(top,1);

#if 1

#endif

  sim_finish(true);

}


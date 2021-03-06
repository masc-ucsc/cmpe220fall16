#include "Vfflop_understand.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <list>

#include <time.h>
#include <math.h>

#define DEBUG_TRACE 1

vluint64_t global_time = 0;
VerilatedVcdC* tfp = 0;

void advance_half_clock(Vfflop_understand *top) {
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

void advance_clock(Vfflop_understand *top, int nclocks=1) {

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

//
void error_found(Vfflop_understand *top) {
  advance_half_clock(top);
  advance_half_clock(top);
  sim_finish(false);
}

void try_send_packet (Vfflop_understand *top) {
    //Try to add some noise when there is not drive
#ifndef NO_RETRY
    top->out1_retry = (rand()&0xF)==0; // randomly,
#endif
    if ( !top-> in1_retry ) {
        top->in1 = rand();
        if ((rand() & 0xF)==0) { // Once every 4
          top->in1_valid = 0;
        }else{
          top->in1_valid = 1;
        }
    }
    
    // Drive signals
    if (top->in1_valid && !top->in1_retry){
        top->in1 = rand() & 0xFFFF;
    }
}

double sc_time_stamp() {
  return 0;
}

int main(int argc, char **argv, char **env) {
      int i;
  int clk;
  Verilated::commandArgs(argc, argv);
  // init top verilog instance
  Vfflop_understand* top = new Vfflop_understand;

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

  for(int i =0;i<6000;i++) {
    try_send_packet(top);
    advance_half_clock(top);
    advance_half_clock(top);
  }
  sim_finish(true);

}

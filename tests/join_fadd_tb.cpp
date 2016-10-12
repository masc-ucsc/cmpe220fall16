#include "Vjoin_fadd.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <list>

#include <time.h>

#define DEBUG_TRACE 1

vluint64_t global_time = 0;
VerilatedVcdC* tfp = 0;

void advance_half_clock(Vjoin_fadd *top) {
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

void advance_clock(Vjoin_fadd *top, int nclocks=1) {

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

#if 1
  if (pass)
    printf("\nTB:PASS\n");
  else
    printf("\nTB:FAILED\n");
#endif

  exit(0);
}

struct InputPacketA {
  int inp_a;
};

struct InputPacketB {
  int inp_b;
};

struct OutputPacket {
  int nset ;
  int sum;
};

double sc_time_stamp() {
  return 0;
}

std::list<InputPacketA>  inpa_list;
std::list<InputPacketB>  inpb_list;
std::list<OutputPacket> out_list;

void try_send_packet(Vjoin_fadd *top) {
  top->sumRetry = (rand()&0xF)==0; // randomly, one every 8 packets

  if (!top->inp_aRetry) {
    top->inp_a = rand();
    if (inpa_list.empty() || (rand() & 0x3)) { // Once every 4
      top->inp_aValid = 0;
    }else{
      top->inp_aValid = 1;
    }
  }

  if (!top->inp_bRetry) {
    top->inp_b = rand();

    if (inpb_list.empty() || (rand() & 0x7)) { // Once every 8 cycles
      top->inp_bValid = 0;
    }else{
      top->inp_bValid = 1;
    }
  }

  if (top->inp_aValid && !top->inp_aRetry) {
    if (inpa_list.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty inpa\n");
    }
    InputPacketA inp = inpa_list.back();
    top->inp_a = inp.inp_a;
#ifdef DEBUG_TRACE
    printf("@%lld inp_a=%d\n",global_time, inp.inp_a);
#endif
    inpa_list.pop_back();
  }

  if (top->inp_bValid && !top->inp_bRetry) {
    if (inpb_list.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty inpb\n");
    }
    InputPacketB inp = inpb_list.back();
    top->inp_b = inp.inp_b;
#ifdef DEBUG_TRACE
    printf("@%lld inp_b=%d\n",global_time, inp.inp_b);
#endif
    inpb_list.pop_back();
  }

}

void error_found(Vjoin_fadd *top) {
  advance_half_clock(top);
  advance_half_clock(top);
  sim_finish(false);
}

void try_recv_packet(Vjoin_fadd *top) {

  if (top->sumValid && out_list.empty()) {
    printf("ERROR: unexpected result %d\n",top->sum);
    error_found(top);
    return;
  }

  if (top->sumRetry)
    return;

  if (!top->sumValid)
    return;

  if (out_list.empty())
    return;

#ifdef DEBUG_TRACE
    printf("@%lld sum=%d\n",global_time, top->sum);
#endif
  OutputPacket o = out_list.back();
  if (top->sum != o.sum) {
    printf("ERROR: expected %d but sum is %d\n",o.sum,top->sum);
    error_found(top);
  }

  out_list.pop_back();
}


int main(int argc, char **argv, char **env) {
  int i;
  int clk;
  Verilated::commandArgs(argc, argv);
  // init top verilog instance
  Vjoin_fadd* top = new Vjoin_fadd;

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

  advance_clock(top,4); // May be larger as required by reset state machines
  //-------------------------------------------------------
  top->reset = 0;
  top->inp_a = 1;
  top->inp_b = 2;
  top->inp_aValid = 0;
  top->inp_bValid = 0;
  top->sumRetry = 1;

  advance_clock(top,1);

#if 1
  for(int i =0;i<1024;i++) {
    try_send_packet(top);
    advance_half_clock(top);
    try_recv_packet(top);
    advance_half_clock(top);

    if (((rand() & 0x3)==0) && inpa_list.size() < 3 && inpb_list.size() < 3 ) {
      InputPacketA ia;
      InputPacketB ib;
      ia.inp_a = rand() & 0xFF;
      ib.inp_b = rand() & 0xFF;
      inpa_list.push_front(ia);
      inpb_list.push_front(ib);

      OutputPacket o;
      o.sum = (ia.inp_a + ib.inp_b) & 0xFF;

      out_list.push_front(o);
    }
    //advance_clock(top,1);
  }
#endif

  sim_finish(true);
}


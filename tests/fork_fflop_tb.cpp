//This testbench is used to test the fork_fflop module. That module takes a fflop input and forks the value
//and forks it into two separate fflops. This testbench gives inputs and checks if both outputs match the input.
#include "Vfork_fflop.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <list>

#include <time.h>

#define DEBUG_TRACE 1


vluint64_t global_time = 0;
VerilatedVcdC* tfp = 0;

void advance_half_clock(Vfork_fflop *top) {
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

void advance_clock(Vfork_fflop *top, int nclocks=1) {

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

struct InputPacket {
  int inp;
};

struct OutputPacketA {
  int out_a;
};

struct OutputPacketB {
  int out_b;
};

double sc_time_stamp() {
  return 0;
}

std::list<InputPacket>  inp_list;
std::list<OutputPacketA>  outa_list;
std::list<OutputPacketB> outb_list;

void try_send_packet(Vfork_fflop *top) {
  
  static int set_a_retry_for = 0;
  if ((rand()&0xF)==0 && set_a_retry_for == 0) {
    set_a_retry_for = rand()&0x1F;
  }
  if (set_a_retry_for) {
    set_a_retry_for--;
    top->out_aRetry = 1;
  }else{
    top->out_aRetry = (rand()&0xF)==0; // randomly, one every 8 packets
  }
  
  static int set_b_retry_for = 0;
  if ((rand()&0xF)==0 && set_b_retry_for == 0) {
    set_b_retry_for = rand()&0x1F;
  }
  if (set_b_retry_for) {
    set_b_retry_for--;
    top->out_bRetry = 1;
  }else{
    top->out_bRetry = (rand()&0xF)==0; // randomly, one every 8 packets
  }

  if (!top->inp_Retry) {
    top->inp = rand();
    if (inp_list.empty() || (rand() & 0x3)) { // Once every 4
      top->inp_Valid = 0;
    }else{
      top->inp_Valid = 1;
    }
  }


  if (top->inp_Valid && !top->inp_Retry) {
    if (inp_list.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty inp\n");
    }
    InputPacket inp = inp_list.back();
    top->inp = inp.inp;
#ifdef DEBUG_TRACE
    printf("@%lld inp=%d\n",global_time, inp.inp);
#endif
    inp_list.pop_back();
  }


}

void error_found(Vfork_fflop *top) {
  advance_half_clock(top);
  advance_half_clock(top);
  sim_finish(false);
}

void try_recv_packet_a(Vfork_fflop *top) {

  if (top->out_aValid && outa_list.empty()) {
    printf("ERROR: unexpected result %d\n",top->out_a);
    error_found(top);
    return;
  }

  if (top->out_aRetry)
    return;

  if (!top->out_aValid)
    return;

  if (outa_list.empty())
    return;

#ifdef DEBUG_TRACE
    printf("@%lld out_a=%d\n",global_time, top->out_a);
#endif
  OutputPacketA o = outa_list.back();
  if (top->out_a != o.out_a) {
    printf("ERROR: expected %d but data a is %d\n",o.out_a, top->out_a);
    error_found(top);
  }

  outa_list.pop_back();
}

void try_recv_packet_b(Vfork_fflop *top) {

  if (top->out_bValid && outb_list.empty()) {
    printf("ERROR: unexpected result %d\n",top->out_b);
    error_found(top);
    return;
  }

  if (top->out_bRetry)
    return;

  if (!top->out_bValid)
    return;

  if (outb_list.empty())
    return;

#ifdef DEBUG_TRACE
    printf("@%lld out_b=%d\n",global_time, top->out_b);
#endif
  OutputPacketB o = outb_list.back();
  if (top->out_b != o.out_b) {
    printf("ERROR: expected %d but data b is %d\n",o.out_b, top->out_b);
    error_found(top);
  }

  outb_list.pop_back();
}


int main(int argc, char **argv, char **env) {
  int i;
  int clk;
  Verilated::commandArgs(argc, argv);
  // init top verilog instance
  Vfork_fflop* top = new Vfork_fflop;

  int t = (int)time(0);
#if 1
  srand(1477696983);
#else
  srand(t);
#endif
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
  top->inp = 1;
  top->inp_Valid = 0;
  top->out_aRetry = 1;
  top->out_bRetry = 1;

  advance_clock(top,1);

#if 1
  for(int i =0;i<102400;i++) {
    try_send_packet(top);
    advance_half_clock(top);
    try_recv_packet_a(top);
    try_recv_packet_b(top);
    advance_half_clock(top);

    if (((rand() & 0x3)==0) && inp_list.size() < 3 ) {
      InputPacket i;
      i.inp = rand() & 0xFF;
      inp_list.push_front(i);

      OutputPacketA oa;
      OutputPacketB ob;
      oa.out_a = i.inp;
      ob.out_b = i.inp;

      outa_list.push_front(oa);
      outb_list.push_front(ob);
    }
    //advance_clock(top,1);
  }

#endif

  sim_finish(true);
}


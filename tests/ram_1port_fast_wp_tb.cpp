
#include "Vram_1port_fast_wp.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <list>

#include <time.h>

#define DEBUG_TRACE 1

vluint64_t global_time = 0;
VerilatedVcdC* tfp = 0;

void advance_half_clock(Vram_1port_fast_wp *top) {
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

void advance_clock(Vram_1port_fast_wp *top, int nclocks=1) {

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

void try_send_packet(Vram_1port_fast_wp *top) {
  top->ack_retry = (rand()&0xF)==0; // randomly, one every 8 packets

  if (!top->req_retry) {
    top->req_data = rand();
    top->req_we   = rand();
    if (inp_list.empty() || (rand() & 0x3)) { // Once every 4
      top->req_valid = 0;
    }else{
      top->req_valid = 1;
    }
  }

  if (top->req_valid && !top->req_retry) {
    if (inp_list.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty inpa\n");
    }
    InputPacket inp = inp_list.back();
    top->req_we   = inp.we;
    top->req_addr = inp.addr;
    top->req_data = inp.data;
#ifdef DEBUG_TRACE
    printf("@%lld req addr:%x data:%x we:%d mem:%x\n",global_time, inp.addr, inp.data, inp.we, memory[inp.addr]);
#endif
    if (top->req_we) {
      memory[inp.addr] = inp.data;
    }else{
      OutputPacket out;
      out.data = memory[inp.addr];
      out_list.push_front(out);
    }

    inp_list.pop_back();
  }

}

void error_found(Vram_1port_fast_wp *top) {
  advance_half_clock(top);
  advance_half_clock(top);
  sim_finish(false);
}

void try_recv_packet(Vram_1port_fast_wp *top) {

  if (top->ack_valid && out_list.empty()) {
    printf("ERROR: unexpected ack data:%x\n",top->ack_data);
    error_found(top);
    return;
  }

  if (top->ack_retry)
    return;

  if (!top->ack_valid)
    return;

  if (out_list.empty())
    return;

#ifdef DEBUG_TRACE
    printf("@%lld ack data:%x\n",global_time, top->ack_data);
#endif
  OutputPacket o = out_list.back();
  if (top->ack_data != o.data) {
    printf("ERROR: expected data:%x but ack is %x\n",o.data,top->ack_data);
    error_found(top);
  }

  out_list.pop_back();
}


int main(int argc, char **argv, char **env) {
  int i;
  int clk;
  Verilated::commandArgs(argc, argv);
  // init top verilog instance
  Vram_1port_fast_wp* top = new Vram_1port_fast_wp;

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
  top->ack_retry = 1;

  advance_clock(top,1);

#if 1
  for(int i =0;i<1024;i++) {
    try_send_packet(top);
    advance_half_clock(top);
    try_recv_packet(top);
    advance_half_clock(top);

    if (((rand() & 0x3)==0) && inp_list.size() < 3 ) {
      InputPacket i;
      i.we   = rand() & 0x1;
      i.data = rand() & 0xFFFF;
      i.addr = rand() & 0xFF;
      inp_list.push_front(i);
    }
  }
#endif

  sim_finish(true);

}


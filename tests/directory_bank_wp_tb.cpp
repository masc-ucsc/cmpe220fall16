
#include "Vdirectory_bank_wp.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <list>

#include <time.h>

#define DEBUG_TRACE 1

vluint64_t global_time = 0;
VerilatedVcdC* tfp = 0;

//Below is code from other tb
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
  uint64_t addr;
};

struct OutputPacket {
  uint64_t addr; // read result
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

void try_send_packet(Vdirectory_bank_wp *top) {
  top->drtomem_pfreq_retry = (rand()&0x3F)==0; 

  if (!top->l2todr_pfreq_retry) {
    top->l2todr_pfreq_paddr = rand();
    if (inp_list.empty() || (rand() & 0x3)) { // Once every 4
      top->l2todr_pfreq_valid = 0;
    }else{
      top->l2todr_pfreq_valid = 1;
    }
  }

  if (top->l2todr_pfreq_valid && !top->l2todr_pfreq_retry) {
    if (inp_list.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty inpa\n");
      error_found(top);
    }

    static vluint64_t last_clk = 0;

    if (last_clk >= (global_time+2)) {
      fprintf(stderr,"ERROR: dense RAMs have 2 cycle delay. No back to back requests accepted\n");
      error_found(top);
    }

    InputPacket inp = inp_list.back();
    top->l2todr_pfreq_paddr = inp.addr;
#ifdef DEBUG_TRACE
    printf("@%lu req addr:%lu \n",global_time, inp.addr);
#endif
   
    OutputPacket out;
    out.addr = inp.addr;
    out_list.push_front(out);
    

    inp_list.pop_back();
  }

}

//above is code from other tb
void try_recv_packet(Vdirectory_bank_wp *top) {

  if (top->drtomem_pfreq_valid && out_list.empty()) {
    printf("ERROR: unexpected ack addr:%lu\n",top->drtomem_pfreq_paddr);
    error_found(top);
    return;
  }

  if (top->drtomem_pfreq_retry)
    return;

  if (!top->drtomem_pfreq_valid)
    return;

  if (out_list.empty())
    return;

#ifdef DEBUG_TRACE
    printf("@%lu ack addr:%lu\n",global_time, top->drtomem_pfreq_paddr);
#endif
  OutputPacket o = out_list.back();
  if (top->drtomem_pfreq_paddr != o.addr) {
    printf("ERROR: expected addr:%lu but ack is %lu\n",o.addr,top->drtomem_pfreq_paddr);
    error_found(top);
  }

  out_list.pop_back();
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
  top->drtomem_pfreq_retry = 1;
  //First test: only test a single set of signals like the l2 to dr or even prefetch
  //Associate retry signal with one I am testing.... prefetch it is.
  advance_clock(top,1);

  
  //I think I have given up converting this and it will be easier writing my own testbench.
  //I could actually use the code, but I have to alter the send packet function.

#if 1
  for(int i =0;i<10240;i++) {
    try_send_packet(top);
    advance_half_clock(top);
    try_recv_packet(top);
    advance_half_clock(top);

    if (((rand() & 0x3)==0) && inp_list.size() < 3 ) {
      InputPacket i;

      if (rand() % 3)
        i.addr = rand() & 0x0001FFFFFFFFFFFF;
      else if (!inp_list.empty())
        i.addr = inp_list.front().addr;
      else
        i.addr = rand() & 0x00000000FFFFFFFF;

      inp_list.push_front(i);
    }
  }
#endif

  sim_finish(true);

}


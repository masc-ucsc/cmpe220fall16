
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

struct InputPacket_l2todr_pfreq {
  uint64_t addr;
};

struct OutputPacket_drtomem_pfreq {
  uint64_t addr; // read result
};

struct InputPacket_l2todr_req {
  uint8_t nid;
  uint8_t l2id;
  uint8_t cmd;
  uint64_t addr;
};

struct OutputPacket_drtomem_req {
  uint8_t drid;
  uint8_t cmd;
  uint64_t addr; // read result
};

double sc_time_stamp() {
  return 0;
}

uint16_t memory[256];

std::list<InputPacket_l2todr_pfreq>  inp_list_pfreq;
std::list<OutputPacket_drtomem_pfreq> out_list_pfreq;

std::list<InputPacket_l2todr_req>  inp_list_req;
std::list<OutputPacket_drtomem_req> out_list_req;

void error_found(Vdirectory_bank_wp *top) {
  advance_half_clock(top);
  advance_half_clock(top);
  sim_finish(false);
}

void try_send_packet(Vdirectory_bank_wp *top) {
  
  //pfreq
  top->drtomem_pfreq_retry = (rand()&0x3F)==0; 

  if (!top->l2todr_pfreq_retry) {
    top->l2todr_pfreq_paddr = rand();
    if (inp_list_pfreq.empty() || (rand() & 0x3)) { // Once every 4
      top->l2todr_pfreq_valid = 0;
    }else{
      top->l2todr_pfreq_valid = 1;
    }
  }
  
  //req
  top->drtomem_req_retry = (rand()&0x3F)==0; 

  if (!top->l2todr_req_retry) {
    top->l2todr_req_paddr = rand();
    if (inp_list_req.empty() || (rand() & 0x3)) { // Once every 4
      top->l2todr_req_valid = 0;
    }else{
      top->l2todr_req_valid = 1;
    }
  }
  
  
  //pfreq
  if (top->l2todr_pfreq_valid && !top->l2todr_pfreq_retry) {
    if (inp_list_pfreq.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty inpa\n");
      error_found(top);
    }

    static vluint64_t last_clk = 0;

    if (last_clk >= (global_time+2)) {
      fprintf(stderr,"ERROR: dense RAMs have 2 cycle delay. No back to back requests accepted\n");
      error_found(top);
    }

    InputPacket_l2todr_pfreq inp1 = inp_list_pfreq.back();
    top->l2todr_pfreq_paddr = inp1.addr;
#ifdef DEBUG_TRACE
    printf("@%lu pfreq addr:%lu \n",global_time, inp1.addr);
#endif
   
    OutputPacket_drtomem_pfreq out1;
    out1.addr = inp1.addr;
    out_list_pfreq.push_front(out1);
    

    inp_list_pfreq.pop_back();
  }
  
  //req
  if (top->l2todr_req_valid && !top->l2todr_req_retry) {
    if (inp_list_req.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty inpa\n");
      error_found(top);
    }

    static vluint64_t last_clk = 0;

    if (last_clk >= (global_time+2)) {
      fprintf(stderr,"ERROR: dense RAMs have 2 cycle delay. No back to back requests accepted\n");
      error_found(top);
    }

    InputPacket_l2todr_req inp2   = inp_list_req.back();
    top->l2todr_req_paddr = inp2.addr;
#ifdef DEBUG_TRACE
    printf("@%lu req addr:%lu \n",global_time, inp2.addr);
#endif
   
    OutputPacket_drtomem_req out2;
    out2.addr = inp2.addr;
    out_list_req.push_front(out2);
    

    inp_list_req.pop_back();
  }

}

//above is code from other tb
void try_recv_packet(Vdirectory_bank_wp *top) {

  //pfreq
  if (top->drtomem_pfreq_valid && out_list_pfreq.empty()) {
    printf("ERROR: unexpected pfreq ack addr:%lu\n",top->drtomem_pfreq_paddr);
    error_found(top);
    return;
  }

  if (top->drtomem_pfreq_retry)
    return;

  if (!top->drtomem_pfreq_valid)
    return;

  if (out_list_pfreq.empty())
    return;

#ifdef DEBUG_TRACE
    printf("@%lu pfreq ack addr:%lu\n",global_time, top->drtomem_pfreq_paddr);
#endif
  OutputPacket_drtomem_pfreq o1 = out_list_pfreq.back();
  if (top->drtomem_pfreq_paddr != o1.addr) {
    printf("ERROR: expected addr:%lu but ack is %lu\n",o1.addr,top->drtomem_pfreq_paddr);
    error_found(top);
  }

  out_list_pfreq.pop_back();
  
}

void try_recv_packet_req(Vdirectory_bank_wp *top) {

  //req
  if (top->drtomem_req_valid && out_list_req.empty()) {
    printf("ERROR: unexpected req ack addr:%lu\n",top->drtomem_req_paddr);
    error_found(top);
    return;
  }

  if (top->drtomem_req_retry)
    return;

  if (!top->drtomem_req_valid)
    return;

  if (out_list_req.empty())
    return;

#ifdef DEBUG_TRACE
    printf("@%lu req ack addr:%lu\n",global_time, top->drtomem_req_paddr);
#endif
  OutputPacket_drtomem_req o2 = out_list_req.back();
  if (top->drtomem_req_paddr != o2.addr) {
    printf("ERROR: expected addr:%lu but ack is %lu\n",o2.addr,top->drtomem_req_paddr);
    error_found(top);
  }

  out_list_req.pop_back();
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
  top->drtomem_req_retry = 1;
  top->drtomem_pfreq_valid = 0;
  top->drtomem_req_valid = 0;
  
  top->l2todr_req_nid = 0;
  top->l2todr_req_l2id = 0;
  top->l2todr_req_cmd = 0;
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
    try_recv_packet_req(top);
    advance_half_clock(top);

    if (((rand() & 0x3)==0) && inp_list_pfreq.size() < 3 ) {
      InputPacket_l2todr_pfreq i;

      if (rand() % 3)
        i.addr = rand() & 0x0001FFFFFFFFFFFF;
      else if (!inp_list_pfreq.empty())
        i.addr = inp_list_pfreq.front().addr;
      else
        i.addr = rand() & 0x00000000FFFFFFFF;

      inp_list_pfreq.push_front(i);
    }
    
    if (((rand() & 0x3)==0) && inp_list_req.size() < 3 ) {
      InputPacket_l2todr_req i;

      if (rand() % 3)
        i.addr = rand() & 0x0001FFFFFFFFFFFF;
      else if (!inp_list_req.empty())
        i.addr = inp_list_req.front().addr;
      else
        i.addr = rand() & 0x00000000FFFFFFFF;

      inp_list_req.push_front(i);
    }
  }
#endif

  sim_finish(true);

}


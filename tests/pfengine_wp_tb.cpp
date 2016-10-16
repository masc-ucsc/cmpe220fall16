
#include "Vpfengine_wp.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <list>

#include <time.h>

#define DEBUG_TRACE 1

vluint64_t global_time = 0;
VerilatedVcdC* tfp = 0;

void advance_half_clock(Vpfengine_wp *top) {
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

void advance_clock(Vpfengine_wp *top, int nclocks=1) {

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
  uint8_t  pf_req_addr;
};

struct OutputPacket {
  uint8_t pf_predicted_addr; // read result
};

double sc_time_stamp() {
  return 0;
}

uint16_t memory[256];

std::list<InputPacket>  inp_list;
std::list<OutputPacket> out_list;

void try_send_packet(Vpfengine_wp *top) {
  top->pftodc_req0_retry = (rand()&0xF)==0;
  top->pftodc_req1_retry = (rand()&0xF)==0;
  top->pftodc_req2_retry = (rand()&0xF)==0;
  top->pftodc_req3_retry = (rand()&0xF)==0;
  top->pftol2_req0_retry = (rand()&0xF)==0;
  top->pftol2_req1_retry = (rand()&0xF)==0;
  top->pftol2_req2_retry = (rand()&0xF)==0;
  top->pftol2_req3_retry = (rand()&0xF)==0;

  if (!top->pfgtopfe_op_retry) {
    //top->pfgtopfe_op = (I_pfgtopfe_op_type)128;
    if (inp_list.empty() || (rand() & 0x3)) { // Once every 4 cycles
      top->pfgtopfe_op_valid = 0;
    }else{
      top->pfgtopfe_op_valid = 1;
    }
  }

  if (top->pfgtopfe_op_valid && !top->pfgtopfe_op_retry) {
    if (inp_list.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty input\n");
    }
    InputPacket inp = inp_list.back();
    //top->pfgtopfe_op = inp.pf_req_addr;
#ifdef DEBUG_TRACE
    printf("@%lld req_addr:%x \n",global_time, inp.pf_req_addr);
#endif

    OutputPacket out;
    out.pf_predicted_addr = rand();
    out_list.push_front(out);

    inp_list.pop_back();
  }

}

void error_found(Vpfengine_wp *top) {
  advance_half_clock(top);
  advance_half_clock(top);
  sim_finish(false);
}

void try_recv_packet(Vpfengine_wp *top) {

  if (top->pftodc_req0_valid && out_list.empty()) {
    printf("ERROR: unexpected prefetch:%x\n", rand());
    error_found(top);
    return;
  }

  if (top->pftodc_req1_valid && out_list.empty()) {
    printf("ERROR: unexpected prefetch req:%x\n", rand());
    error_found(top);
    return;
  }

  if (top->pftodc_req2_valid && out_list.empty()) {
    printf("ERROR: unexpected prefetch:%x\n", rand());
    error_found(top);
    return;
  }

  if (top->pftodc_req3_valid && out_list.empty()) {
    printf("ERROR: unexpected prefetch:%x\n", rand());
    error_found(top);
    return;
  }

  if (top->pftol2_req0_valid && out_list.empty()) {
    printf("ERROR: unexpected prefetch:%x\n", rand());
    error_found(top);
    return;
  }

  if (top->pftol2_req1_valid && out_list.empty()) {
    printf("ERROR: unexpected prefetch:%x\n", rand());
    error_found(top);
    return;
  }

  if (top->pftol2_req2_valid && out_list.empty()) {
    printf("ERROR: unexpected prefetch:%x\n", rand());
    error_found(top);
    return;
  }

  if (top->pftol2_req3_valid && out_list.empty()) {
    printf("ERROR: unexpected prefetch:%x\n", rand());
    error_found(top);
    return;
  }

  if (top->pftodc_req0_retry)
    return;

  if (top->pftodc_req1_retry)
    return;

  if (top->pftodc_req2_retry)
    return;

  if (top->pftodc_req3_retry)
    return;

  if (top->pftol2_req0_retry)
    return;

  if (top->pftol2_req1_retry)
    return;
  
  if (top->pftol2_req2_retry)
    return;

  if (top->pftol2_req3_retry)
    return;

  if (!top->pftodc_req0_valid)
    return;

  if (!top->pftodc_req1_valid)
    return;

  if (!top->pftodc_req2_valid)
    return;

  if (!top->pftodc_req3_valid)
    return;

  if (!top->pftol2_req0_valid)
    return;

  if (!top->pftol2_req1_valid)
        return;

  if (!top->pftol2_req2_valid)
        return;

  if (!top->pftol2_req3_valid)
        return;

  if (out_list.empty())
    return;

#ifdef DEBUG_TRACE
    printf("@%lld req prefetch:%x\n",global_time, rand());
#endif
  OutputPacket o = out_list.back();

  out_list.pop_back();
}


int main(int argc, char **argv, char **env) {
  int i;
  int clk;
  Verilated::commandArgs(argc, argv);
  // init top verilog instance
  Vpfengine_wp* top = new Vpfengine_wp;

  int t = (int)time(0);
  srand(t);
  printf("My RAND Seed is %d\n",t);

#ifdef TRACE
  // init trace dump
  Verilated::traceEverOn(true);
  tfp = new VerilatedVcdC;

  top->trace(tfp, 99);
  tfp->open("pfoutput.vcd");
#endif

  // initialize simulation inputs
  top->clk = 1;
  top->reset = 1;

  advance_clock(top,1024);  // Long reset to give time to the state machine
  //-------------------------------------------------------
  top->reset = 0;
  //top->pfgtopfe_op.laddr = rand();
  top->pftodc_req0_retry = 1; 
  top->pftodc_req1_retry = 1;
  top->pftodc_req2_retry = 1;
  top->pftodc_req3_retry = 1;
  top->pftol2_req0_retry = 1;
  top->pftol2_req1_retry = 1;
  top->pftol2_req2_retry = 1;
  top->pftol2_req3_retry = 1;

  advance_clock(top,1);

#if 1
  for(int i =0;i<1024;i++) {
    try_send_packet(top);
    advance_half_clock(top);
    try_recv_packet(top);
    advance_half_clock(top);

    if (((rand() & 0x3)==0) && inp_list.size() < 3 ) {
      InputPacket i;
      i.pf_req_addr = rand() & 0xFF;
      inp_list.push_front(i);
    }
  }
#endif

  sim_finish(true);

}



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
  uint8_t  pf_d;
  uint8_t  pf_w;
  uint8_t  pf_pcsign;
  uint8_t  pf_laddr;
  uint8_t  pf_sptbr;
};

struct OutputPacket {
  uint8_t pf_dcreq0_laddr;
  uint8_t pf_dcreq0_sptbr;
  uint8_t pf_dcreq1_laddr;
  uint8_t pf_dcreq1_sptbr;
  uint8_t pf_dcreq2_laddr;
  uint8_t pf_dcreq2_sptbr;
  uint8_t pf_dcreq3_laddr;
  uint8_t pf_dcreq3_sptbr;

  uint8_t pf_l2req0_laddr;
  uint8_t pf_l2req0_sptbr;
  uint8_t pf_l2req1_laddr;
  uint8_t pf_l2req1_sptbr;
  uint8_t pf_l2req2_laddr;
  uint8_t pf_l2req2_sptbr;
  uint8_t pf_l2req3_laddr;
  uint8_t pf_l2req3_sptbr;
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
    top->pfgtopfe_op_pcsign = rand();
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
    top->pfgtopfe_op_d      = inp.pf_d;
    top->pfgtopfe_op_w      = inp.pf_w;
    top->pfgtopfe_op_pcsign = inp.pf_pcsign;
    top->pfgtopfe_op_laddr  = inp.pf_laddr;
    //top->pfgtopfe_op_sptbr  = inp.pf_sptbr;

#ifdef DEBUG_TRACE
    printf("@%lld delta:%x weight:%x laddr:%x pcsign:%x \n",global_time, inp.pf_d, inp.pf_w, inp.pf_laddr, inp.pf_pcsign);
#endif

    OutputPacket out;
    if (inp.pf_laddr%2 == 0)
      out.pf_dcreq0_laddr = inp.pf_laddr;
    else
      out.pf_dcreq1_laddr = inp.pf_laddr;

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
    printf("ERROR: unexpected prefetch:%x\n", top->pftodc_req0_laddr);
    error_found(top);
    return;
  }

  if (top->pftodc_req1_valid && out_list.empty()) {
    printf("ERROR: unexpected prefetch req:%x\n", top->pftodc_req1_laddr);
    error_found(top);
    return;
  }

  if (top->pftodc_req2_valid && out_list.empty()) {
    printf("ERROR: unexpected prefetch:%x\n", top->pftodc_req2_laddr);
    error_found(top);
    return;
  }

  if (top->pftodc_req3_valid && out_list.empty()) {
    printf("ERROR: unexpected prefetch:%x\n", top->pftodc_req3_laddr);
    error_found(top);
    return;
  }

  if (top->pftol2_req0_valid && out_list.empty()) {
    printf("ERROR: unexpected prefetch:%x\n", top->pftol2_req0_laddr);
    error_found(top);
    return;
  }

  if (top->pftol2_req1_valid && out_list.empty()) {
    printf("ERROR: unexpected prefetch:%x\n", top->pftol2_req1_laddr);
    error_found(top);
    return;
  }

  if (top->pftol2_req2_valid && out_list.empty()) {
    printf("ERROR: unexpected prefetch:%x\n", top->pftol2_req2_laddr);
    error_found(top);
    return;
  }

  if (top->pftol2_req3_valid && out_list.empty()) {
    printf("ERROR: unexpected prefetch:%x\n", top->pftol2_req3_laddr);
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
    if (top->pftodc_req0_valid)
      printf("@%lld prefetch_addr:%x\n",global_time, top->pftodc_req0_laddr);

    if (top->pftodc_req1_valid)
      printf("@%lld prefetch_addr:%x\n",global_time, top->pftodc_req1_laddr);

    if (top->pftodc_req2_valid)
      printf("@%lld prefetch_addr:%x\n",global_time, top->pftodc_req2_laddr);

    if (top->pftodc_req3_valid)
      printf("@%lld prefetch_addr:%x\n",global_time, top->pftodc_req3_laddr);

    if (top->pftol2_req0_valid)
      printf("@%lld prefetch_addr:%x\n",global_time, top->pftol2_req0_laddr);

    if (top->pftol2_req1_valid)
      printf("@%lld prefetch_addr:%x\n",global_time, top->pftol2_req1_laddr);

    if (top->pftol2_req2_valid)
      printf("@%lld prefetch_addr:%x\n",global_time, top->pftol2_req2_laddr);

    if (top->pftol2_req3_valid)
      printf("@%lld prefetch_addr:%x\n",global_time, top->pftol2_req3_laddr);
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
  tfp->open("output.vcd");
#endif

  // initialize simulation inputs
  top->clk = 1;
  top->reset = 1;

  advance_clock(top,1024);  // Long reset to give time to the state machine
  //-------------------------------------------------------
  top->reset = 0;
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
      i.pf_d      = 0;
      i.pf_w      = 1;
      i.pf_laddr  = rand() & 0xFF;
      i.pf_pcsign = rand() & 0xFFFF;
      inp_list.push_front(i);
    }
  }
#endif

  sim_finish(true);

}


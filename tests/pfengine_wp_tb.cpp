
#include "Vpfengine_wp.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <list>
#include <vector>

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
  uint8_t  pf_delta;
  uint8_t  pf_w1;
  uint8_t  pf_w2;
  uint64_t  pf_pcsign;
  uint64_t  pf_laddr;
  uint64_t  pf_sptbr;

  uint8_t pf0_dcstats_nhitmissd;
  uint8_t pf0_dcstats_nhitmissp;
  uint8_t pf0_dcstats_nhithit;
  uint8_t pf0_dcstats_nmiss;
  uint8_t pf0_dcstats_ndrop;
  uint8_t pf0_dcstats_nreqs;
  uint8_t pf0_dcstats_nsnoops;
  uint8_t pf0_dcstats_ndisp;

  uint8_t pf0_l2stats_nhitmissd;
  uint8_t pf0_l2stats_nhitmissp;
  uint8_t pf0_l2stats_nhithit;
  uint8_t pf0_l2stats_nmiss;
  uint8_t pf0_l2stats_ndrop;
  uint8_t pf0_l2stats_nreqs;
  uint8_t pf0_l2stats_nsnoops;
  uint8_t pf0_l2stats_ndisp;

  uint8_t pf1_dcstats_nhitmissd;
  uint8_t pf1_dcstats_nhitmissp;
  uint8_t pf1_dcstats_nhithit;
  uint8_t pf1_dcstats_nmiss;
  uint8_t pf1_dcstats_ndrop;
  uint8_t pf1_dcstats_nreqs;
  uint8_t pf1_dcstats_nsnoops;
  uint8_t pf1_dcstats_ndisp;

  uint8_t pf1_l2stats_nhitmissd;
  uint8_t pf1_l2stats_nhitmissp;
  uint8_t pf1_l2stats_nhithit;
  uint8_t pf1_l2stats_nmiss;
  uint8_t pf1_l2stats_ndrop;
  uint8_t pf1_l2stats_nreqs;
  uint8_t pf1_l2stats_nsnoops;
  uint8_t pf1_l2stats_ndisp;

  uint8_t pf2_dcstats_nhitmissd;
  uint8_t pf2_dcstats_nhitmissp;
  uint8_t pf2_dcstats_nhithit;
  uint8_t pf2_dcstats_nmiss;
  uint8_t pf2_dcstats_ndrop;
  uint8_t pf2_dcstats_nreqs;
  uint8_t pf2_dcstats_nsnoops;
  uint8_t pf2_dcstats_ndisp;

  uint8_t pf2_l2stats_nhitmissd;
  uint8_t pf2_l2stats_nhitmissp;
  uint8_t pf2_l2stats_nhithit;
  uint8_t pf2_l2stats_nmiss;
  uint8_t pf2_l2stats_ndrop;
  uint8_t pf2_l2stats_nreqs;
  uint8_t pf2_l2stats_nsnoops;
  uint8_t pf2_l2stats_ndisp;

  uint8_t pf3_dcstats_nhitmissd;
  uint8_t pf3_dcstats_nhitmissp;
  uint8_t pf3_dcstats_nhithit;
  uint8_t pf3_dcstats_nmiss;
  uint8_t pf3_dcstats_ndrop;
  uint8_t pf3_dcstats_nreqs;
  uint8_t pf3_dcstats_nsnoops;
  uint8_t pf3_dcstats_ndisp;

  uint8_t pf3_l2stats_nhitmissd;
  uint8_t pf3_l2stats_nhitmissp;
  uint8_t pf3_l2stats_nhithit;
  uint8_t pf3_l2stats_nmiss;
  uint8_t pf3_l2stats_ndrop;
  uint8_t pf3_l2stats_nreqs;
  uint8_t pf3_l2stats_nsnoops;
  uint8_t pf3_l2stats_ndisp;
};

struct OutputPacket {
  uint64_t pf_dcreq0_laddr;
  uint64_t pf_dcreq0_sptbr;
  uint8_t pf_dcreq0_l2;

  uint64_t pf_dcreq1_laddr;
  uint64_t pf_dcreq1_sptbr;
  uint8_t pf_dcreq1_l2;

  uint64_t pf_dcreq2_laddr;
  uint64_t pf_dcreq2_sptbr;
  uint8_t pf_dcreq2_l2;

  uint64_t pf_dcreq3_laddr;
  uint64_t pf_dcreq3_sptbr;
  uint8_t pf_dcreq3_l2;

  uint8_t pf_agg_dcstats_nhitmissd;
  uint8_t pf_agg_dcstats_nhitmissp;
  uint8_t pf_agg_dcstats_nhithit;
  uint8_t pf_agg_dcstats_nmiss;
  uint8_t pf_agg_dcstats_ndrop;
  uint8_t pf_agg_dcstats_nreqs;
  uint8_t pf_agg_dcstats_nsnoops;
  uint8_t pf_agg_dcstats_ndisp;

  uint8_t pf_agg_l2stats_nhitmissd;
  uint8_t pf_agg_l2stats_nhitmissp;
  uint8_t pf_agg_l2stats_nhithit;
  uint8_t pf_agg_l2stats_nmiss;
  uint8_t pf_agg_l2stats_ndrop;
  uint8_t pf_agg_l2stats_nreqs;
  uint8_t pf_agg_l2stats_nsnoops;
  uint8_t pf_agg_l2stats_ndisp;
};

double sc_time_stamp() {
  return 0;
}

uint16_t memory[256];
std::vector<uint64_t> l1_generated_prefetch;  //L1 can have max of 4 pretfetch generations
std::vector<uint64_t> l2_generated_prefetch;

std::list<InputPacket>  inp_list;
std::list<OutputPacket> out_list;

//input to pfengine (laddr, pcsign, sptbr, delta, weight and cache stats)
void try_send_input_packet_to_pfe(Vpfengine_wp *top) {
  top->pftodc_req0_retry = (rand()&0xF)==0;
  top->pftodc_req1_retry = (rand()&0xF)==0;
  top->pftodc_req2_retry = (rand()&0xF)==0;
  top->pftodc_req3_retry = (rand()&0xF)==0;

  if (!top->pfgtopfe_op_retry) {
    top->pfgtopfe_op_delta  = 0;
    top->pfgtopfe_op_w1     = 1;
    top->pfgtopfe_op_w2     = 1;
    top->pfgtopfe_op_laddr  = rand();
    top->pfgtopfe_op_pcsign = rand();
    top->pfgtopfe_op_sptbr  = rand();
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
    top->pfgtopfe_op_delta  = inp.pf_delta;
    top->pfgtopfe_op_w1     = inp.pf_w1;
    top->pfgtopfe_op_w2     = inp.pf_w2;
    top->pfgtopfe_op_pcsign = inp.pf_pcsign;
    top->pfgtopfe_op_laddr  = inp.pf_laddr;
    top->pfgtopfe_op_sptbr  = inp.pf_sptbr;

    top->pf0_dcstats_nhitmissd = inp.pf0_dcstats_nhitmissd;
    top->pf0_dcstats_nhitmissp = inp.pf0_dcstats_nhitmissp;
    top->pf0_dcstats_nhithit   = inp.pf0_dcstats_nhithit;
    top->pf0_dcstats_nmiss     = inp.pf0_dcstats_nmiss;
    top->pf0_dcstats_ndrop     = inp.pf0_dcstats_ndrop;
    top->pf0_dcstats_nreqs     = inp.pf0_dcstats_nreqs;
    top->pf0_dcstats_nsnoops   = inp.pf0_dcstats_nsnoops;
    top->pf0_dcstats_ndisp     = inp.pf0_dcstats_ndisp;
    top->pf0_l2stats_nhitmissd = inp.pf0_l2stats_nhitmissd;
    top->pf0_l2stats_nhitmissp = inp.pf0_l2stats_nhitmissp;
    top->pf0_l2stats_nhithit   = inp.pf0_l2stats_nhithit;
    top->pf0_l2stats_nmiss     = inp.pf0_l2stats_nmiss;
    top->pf0_l2stats_ndrop     = inp.pf0_l2stats_ndrop;
    top->pf0_l2stats_nreqs     = inp.pf0_l2stats_nreqs;
    top->pf0_l2stats_nsnoops   = inp.pf0_l2stats_nsnoops;
    top->pf0_l2stats_ndisp     = inp.pf0_l2stats_ndisp;

    top->pf1_dcstats_nhitmissd = inp.pf1_dcstats_nhitmissd;
    top->pf1_dcstats_nhitmissp = inp.pf1_dcstats_nhitmissp;
    top->pf1_dcstats_nhithit   = inp.pf1_dcstats_nhithit;
    top->pf1_dcstats_nmiss     = inp.pf1_dcstats_nmiss;
    top->pf1_dcstats_ndrop     = inp.pf1_dcstats_ndrop;
    top->pf1_dcstats_nreqs     = inp.pf1_dcstats_nreqs;
    top->pf1_dcstats_nsnoops   = inp.pf1_dcstats_nsnoops;
    top->pf1_dcstats_ndisp     = inp.pf1_dcstats_ndisp;
    top->pf1_l2stats_nhitmissd = inp.pf1_l2stats_nhitmissd;
    top->pf1_l2stats_nhitmissp = inp.pf1_l2stats_nhitmissp;
    top->pf1_l2stats_nhithit   = inp.pf1_l2stats_nhithit;
    top->pf1_l2stats_nmiss     = inp.pf1_l2stats_nmiss;
    top->pf1_l2stats_ndrop     = inp.pf1_l2stats_ndrop;
    top->pf1_l2stats_nreqs     = inp.pf1_l2stats_nreqs;
    top->pf1_l2stats_nsnoops   = inp.pf1_l2stats_nsnoops;
    top->pf1_l2stats_ndisp     = inp.pf1_l2stats_ndisp;

#ifdef DEBUG_TRACE
    printf("@%lld delta:%x w1:%x w2:%x laddr:%x pcsign:%x sptbr:%x \n",global_time, inp.pf_delta, inp.pf_w1, inp.pf_w2, inp.pf_laddr, inp.pf_pcsign, inp.pf_sptbr);
#endif

    //prefetch generation using laddr, delta, w1 and w2
    //single stride prefetch
    //delta:123 # or whatever stride
    //w1:3   # num of L1 prefs
    //w2:0   # num of L2 prefs
    //laddr: addr 
    //generated prefetches: addr+123,addr+2*123,addr+3*123

    //first 4 generated prefs for w1 is sent to L1 tlb; others are sent to L2
    for (int i = 1; i <= top->pfgtopfe_op_w1; i++) {
      if (i <= 4)
        l1_generated_prefetch.push_back(top->pfgtopfe_op_laddr + (i * top->pfgtopfe_op_delta));
      else
        l2_generated_prefetch.push_back(top->pfgtopfe_op_laddr + (i * top->pfgtopfe_op_delta));  
    }

    for (int j = 1; j <= top->pfgtopfe_op_w2; j++) {
      l2_generated_prefetch.push_back(top->pfgtopfe_op_laddr + (j * top->pfgtopfe_op_delta));
    }

    OutputPacket out;
    for (int k = 0; k < l1_generated_prefetch.size(); k++) {
      //odd pref addr are sent to dc1; even addr sent to dc0
      if (l1_generated_prefetch[k]%2 == 0)
        out.pf_dcreq0_laddr = l1_generated_prefetch[k];
      else
        out.pf_dcreq1_laddr = l1_generated_prefetch[k];
    }

    //aggregated cache stats for dc and l2

    out.pf_agg_dcstats_nhitmissd = inp.pf0_dcstats_nhitmissd + inp.pf1_dcstats_nhitmissd;
    out.pf_agg_dcstats_nhitmissp = inp.pf0_dcstats_nhitmissp + inp.pf1_dcstats_nhitmissp;
    out.pf_agg_dcstats_nhithit   = inp.pf0_dcstats_nhithit + inp.pf1_dcstats_nhithit;
    out.pf_agg_dcstats_nmiss     = inp.pf0_dcstats_nmiss + inp.pf1_dcstats_nmiss;
    out.pf_agg_dcstats_ndrop     = inp.pf0_dcstats_ndrop + inp.pf1_dcstats_ndrop;
    out.pf_agg_dcstats_nreqs     = inp.pf0_dcstats_nreqs + inp.pf1_dcstats_nreqs;
    out.pf_agg_dcstats_nsnoops   = inp.pf0_dcstats_nsnoops + inp.pf1_dcstats_nsnoops;
    out.pf_agg_dcstats_ndisp     = inp.pf0_dcstats_ndisp + inp.pf1_dcstats_ndisp;

    out.pf_agg_l2stats_nhitmissd = inp.pf0_l2stats_nhitmissd + inp.pf1_l2stats_nhitmissd;
    out.pf_agg_l2stats_nhitmissp = inp.pf0_l2stats_nhitmissp + inp.pf1_l2stats_nhitmissp;
    out.pf_agg_l2stats_nhithit   = inp.pf0_l2stats_nhithit + inp.pf1_l2stats_nhithit;
    out.pf_agg_l2stats_nmiss     = inp.pf0_l2stats_nmiss + inp.pf1_l2stats_nmiss;
    out.pf_agg_l2stats_ndrop     = inp.pf0_l2stats_ndrop + inp.pf1_l2stats_ndrop;
    out.pf_agg_l2stats_nreqs     = inp.pf0_l2stats_nreqs + inp.pf1_l2stats_nreqs;
    out.pf_agg_l2stats_nsnoops   = inp.pf0_l2stats_nsnoops + inp.pf1_l2stats_nsnoops;
    out.pf_agg_l2stats_ndisp     = inp.pf0_l2stats_ndisp + inp.pf1_l2stats_ndisp;

    out_list.push_front(out);

    inp_list.pop_back();
  }

}


void error_found(Vpfengine_wp *top) {
  advance_half_clock(top);
  advance_half_clock(top);
  sim_finish(false);
}


void try_recv_output_packet_from_pfe(Vpfengine_wp *top) {

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

  if (top->pftodc_req0_retry)
    return;

  if (top->pftodc_req1_retry)
    return;

  if (top->pftodc_req2_retry)
    return;

  if (top->pftodc_req3_retry)
    return;
  
  if (!top->pftodc_req0_valid)
    return;

  if (!top->pftodc_req1_valid)
    return;

  if (!top->pftodc_req2_valid)
    return;

  if (!top->pftodc_req3_valid)
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

  advance_clock(top,1);

#if 1
  for(int i =0;i<1024;i++) {
    try_send_input_packet_to_pfe(top);
    advance_half_clock(top);
    try_recv_output_packet_from_pfe(top);
    advance_half_clock(top);

    if (((rand() & 0x3)==0) && inp_list.size() < 3 ) {
      InputPacket i;
      i.pf_delta  = rand()%64;
      i.pf_w1     = rand()%4;
      i.pf_w2     = rand()%4;
      i.pf_laddr  = rand() & 0xFF;
      i.pf_pcsign = rand() & 0xFFFF;
      i.pf_sptbr  = rand() & 0xFFFF;
      //generate cache stats for pf0_dc, pf1_dc, pf0_l2 and pf1_l2 (can include remaining cases after testing)
      i.pf0_dcstats_nhitmissd = rand()%10+1; // generate random num between 1 to 10
      i.pf0_dcstats_nhitmissp = rand()%10+1;
      i.pf0_dcstats_nhithit   = rand()%10+1;
      i.pf0_dcstats_nmiss     = rand()%10+1;
      i.pf0_dcstats_ndrop     = rand()%10+1;
      i.pf0_dcstats_nreqs     = rand()%10+1;
      i.pf0_dcstats_nsnoops   = rand()%10+1;
      i.pf0_dcstats_ndisp     = rand()%10+1;
      i.pf0_l2stats_nhitmissd = rand()%10+1;
      i.pf0_l2stats_nhitmissp = rand()%10+1;
      i.pf0_l2stats_nhithit   = rand()%10+1;
      i.pf0_l2stats_nmiss     = rand()%10+1;
      i.pf0_l2stats_ndrop     = rand()%10+1;
      i.pf0_l2stats_nreqs     = rand()%10+1;
      i.pf0_l2stats_nsnoops   = rand()%10+1;
      i.pf0_l2stats_ndisp     = rand()%10+1;

      i.pf1_dcstats_nhitmissd = rand()%10+1;
      i.pf1_dcstats_nhitmissp = rand()%10+1;
      i.pf1_dcstats_nhithit   = rand()%10+1;
      i.pf1_dcstats_nmiss     = rand()%10+1;
      i.pf1_dcstats_ndrop     = rand()%10+1;
      i.pf1_dcstats_nreqs     = rand()%10+1;
      i.pf1_dcstats_nsnoops   = rand()%10+1;
      i.pf1_dcstats_ndisp     = rand()%10+1;
      i.pf1_l2stats_nhitmissd = rand()%10+1;
      i.pf1_l2stats_nhitmissp = rand()%10+1;
      i.pf1_l2stats_nhithit   = rand()%10+1;
      i.pf1_l2stats_nmiss     = rand()%10+1;
      i.pf1_l2stats_ndrop     = rand()%10+1;
      i.pf1_l2stats_nreqs     = rand()%10+1;
      i.pf1_l2stats_nsnoops   = rand()%10+1;
      i.pf1_l2stats_ndisp     = rand()%10+1;

      inp_list.push_front(i);
    }
  }
#endif

  sim_finish(true);

}


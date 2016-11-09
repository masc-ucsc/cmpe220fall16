
#include "Victlb_wp.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <list>

#include <time.h>

#define DEBUG_TRACE 1

vluint64_t global_time = 0;
VerilatedVcdC* tfp = 0;

long ntests = 0;

void advance_half_clock(Victlb_wp *top) {
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

void advance_clock(Victlb_wp *top, int nclocks=1) {

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

struct InputPacket_Load { //coretoictlb_pc_type
  int coreid;
  uint64_t laddr;
  int sptbr;
};

struct InputPacket_Prefetch { // prefetch request
  int l2;
  uint64_t laddr;
  int sptbr;
};

struct OutputPacket { //l1tlbtl1_fwd_type
  int coreid;
  int prefetch;
  int l2_prefetch;
  int fault;
  int hpaddr;
  int ppaddr;
};

double sc_time_stamp() {
  return 0;
}

std::list<InputPacket_Load>  in_pc_list;
std::list<InputPacket_Prefetch>  in_pf_list;
std::list<OutputPacket> out_pc_list;
std::list<OutputPacket> out_pf_list;


void try_send_packet(Victlb_wp *top) {
  static int set_retry_for_pc = 0;
  if ((rand()&0xF)==0 && set_retry_for_pc == 0) {
    set_retry_for_pc = rand()&0x1F;
  }
  if (set_retry_for_pc) {
    set_retry_for_pc--;
    top->l1tlbtol1_fwd_retry = 1;
  }else{
    top->l1tlbtol1_fwd_retry = 0; //(rand()&0xF)==0; // randomly, one every 8 packets
  }

  if (!top->coretoictlb_pc_retry) {
    if (in_pc_list.empty() || (rand() & 0x3)) { // Once every 4
      top->coretoictlb_pc_valid = 0;

      top->coretoictlb_pc_coreid = rand();
      top->coretoictlb_pc_laddr = rand();
      top->coretoictlb_pc_sptbr = rand();
    } else {
      top->coretoictlb_pc_valid = 1;

      InputPacket_Load in_pc = in_pc_list.back();
      top->coretoictlb_pc_coreid = in_pc.coreid;
      top->coretoictlb_pc_laddr = in_pc.laddr;
      top->coretoictlb_pc_sptbr = in_pc.sptbr;
#ifdef DEBUG_TRACE
      printf("@%lld \tin_pc_coreid=%X\n",global_time, in_pc.coreid);
      printf("\tin_pc_laddr=%X\n", in_pc.laddr);
      printf("\tin_pc_sptbr=%X\n", in_pc.sptbr);
#endif

      in_pc_list.pop_back();
    }
  }


  if (!top->pfetol1tlb_req_retry) {
    top->pfetol1tlb_req_l2 = rand();
    top->pfetol1tlb_req_laddr = rand();
    top->pfetol1tlb_req_sptbr = rand();

    if (in_pf_list.empty() || (rand() & 0x3)) { // Once every 4 cycles
      top->pfetol1tlb_req_valid = 0;
    }else{
      top->pfetol1tlb_req_valid = 1;
    }
  }


  if (top->pfetol1tlb_req_valid && !top->pfetol1tlb_req_retry) {
    if (in_pf_list.empty()) {
      fprintf(stderr,"ERROR: Internal error, in_pf_list could not be empty\n");
    }
    InputPacket_Prefetch in_pf = in_pf_list.back();
    top->pfetol1tlb_req_l2 = in_pf.l2;
    top->pfetol1tlb_req_laddr = in_pf.laddr;
    top->pfetol1tlb_req_sptbr = in_pf.sptbr;
#ifdef DEBUG_TRACE
    printf("@%lld in_pf_l2=%X\n",global_time, in_pf.l2);
    printf("\tin_pf_laddr=%X\n", in_pf.laddr);
    printf("\tin_pf_sptbr=%X\n", in_pf.sptbr);
#endif
    in_pf_list.pop_back();
  }

}

void error_found(Victlb_wp *top) {
  advance_half_clock(top);
  advance_half_clock(top);
  sim_finish(false);
}

void try_recv_packet(Victlb_wp *top) {

  if (top->l1tlbtol1_fwd_valid && out_pc_list.empty() && out_pf_list.empty() && !top->l1tlbtol1_fwd_retry) {
    printf("ERROR: unexpected result in fwd pc: hpaddr=%X, ppaddr=%X\n .",top->l1tlbtol1_fwd_hpaddr, top->l1tlbtol1_fwd_ppaddr);
    error_found(top);
    return;
  }

  if (top->l1tlbtol1_fwd_retry)
    return;

  if (!top->l1tlbtol1_fwd_valid)
    return;

  if (out_pc_list.empty() && out_pf_list.empty())
    return;

#ifdef DEBUG_TRACE
    //printf("@%lld fwd_hpaddr=%X fwd_ppaddr\n",global_time, top->l1tlbtol1_fwd_hpaddr, top->l1tlbtol1_fwd_ppaddr);
#endif
  OutputPacket out_pc = out_pc_list.back();
  OutputPacket out_pf;
  bool is_in_pf;

  int out_pc_hpaddr = top->l1tlbtol1_fwd_hpaddr;
  int out_pc_ppaddr = top->l1tlbtol1_fwd_ppaddr;
  int out_pc_coreid = top->l1tlbtol1_fwd_coreid;
  int out_pc_prefetch = top->l1tlbtol1_fwd_prefetch;

  if(top->l1tlbtol1_fwd_valid && !top->l1tlbtol1_fwd_retry) {
    if(out_pc_hpaddr == out_pc.hpaddr &&
          out_pc_ppaddr == out_pc.ppaddr &&
          out_pc_coreid == out_pc.coreid){


      out_pc_list.pop_back();

    } else {
      is_in_pf = false;
      while(!out_pf_list.empty() && !out_pc_coreid && out_pc_prefetch){
        out_pf = out_pf_list.back();
        //printf("prefetch hpaddr %X, ppaddr %X, coreid %X\n", out_pf.hpaddr, out_pf.ppaddr, out_pf.coreid);
        out_pf_list.pop_back();
        if(out_pc_hpaddr == out_pf.hpaddr && out_pc_ppaddr == out_pf.ppaddr){
          is_in_pf = true;
          break;
        }
      }
      if(!is_in_pf){
        printf("ERROR: got %X but expected out_pc.hpaddr = %X\n", out_pc_hpaddr, out_pc.hpaddr);
        printf("\t got %X but expected out_pc.ppaddr = %X\n", out_pc_ppaddr, out_pc.ppaddr);
        printf("\t got %X but expected out_pc.coreid = %X\n", out_pc_coreid, out_pc.coreid);
        printf("\t value not sent as a prefetch\n");
        error_found(top);
      }
    }
  }


  ntests++;
}


int main(int argc, char **argv, char **env) {
  int i;
  int clk;
  Verilated::commandArgs(argc, argv);
  // init top verilog instance
  Victlb_wp* top = new Victlb_wp;

  int t = (int)time(0);
#if 0
  srand(1477809920);
#else
  srand(t);
#endif
  printf("My RAND Seed is %d\n",t);

#ifdef TRACE
  // init trace dump
  Verilated::traceEverOn(true);
  tfp = new VerilatedVcdC;

  top->trace(tfp, 99);
  tfp->open("ictlb_output.vcd");
#endif

  // initialize simulation inputs
  top->clk = 1;

  for(int niters=0 ; niters < 50; niters++) {
    //-------------------------------------------------------

#ifdef DEBUG_TRACE
    printf("reset\n");
#endif
    top->reset = 1;

    in_pc_list.clear();
    in_pf_list.clear();
    out_pc_list.clear();

    top->coretoictlb_pc_valid = 0;
    top->pfetol1tlb_req_valid = 0;
    int ncycles= rand() & 0xFF;
    ncycles++; // At least one cycle reset
    for(int i =0;i<ncycles;i++) {
      top->coretoictlb_pc_coreid = rand() & 0x3F;
      top->coretoictlb_pc_laddr  = (((uint64_t)rand() << 32) | (uint64_t)rand()) & 0x7FFFFFFFFF;
      top->coretoictlb_pc_sptbr  = (((uint64_t)rand() << 32) | (uint64_t)rand()) & 0x3FFFFFFFFF;
      //top->coretoictlb_pc_retry  = rand() & 1;

      top->pfetol1tlb_req_l2     = rand() & 1;
      top->pfetol1tlb_req_laddr  = (((uint64_t)rand() << 32) | (uint64_t)rand()) & 0x7FFFFFFFFF;
      top->pfetol1tlb_req_sptbr  = (((uint64_t)rand() << 32) | (uint64_t)rand()) & 0x3FFFFFFFFF;
      //top->pfetol1tlb_req_retry  = rand() & 1;
      
      top->l1tlbtol1_fwd_retry  = rand() & 1;


      advance_clock(top,1);
    }

#ifdef DEBUG_TRACE
    printf("no reset\n");
#endif
    //-------------------------------------------------------
    top->reset = 0;
    top->coretoictlb_pc_valid   = 0; 
    top->coretoictlb_pc_coreid  = 0;
    top->coretoictlb_pc_laddr   = 0; 
    top->coretoictlb_pc_sptbr   = 0;

    top->pfetol1tlb_req_valid   = 0;
    top->pfetol1tlb_req_l2      = 0;
    top->pfetol1tlb_req_laddr   = 0;
    top->pfetol1tlb_req_sptbr   = 0;

    top->l1tlbtol1_fwd_retry   = 1;

    //advance_clock(top,1);


#if 1
    for(int i =0;i<1024;i++) {
      try_send_packet(top);
      advance_half_clock(top);
      try_recv_packet(top);
      advance_half_clock(top);
      

      if (((rand() & 0x3)==0) && in_pc_list.size() < 3) {
        InputPacket_Load in_pc;
        in_pc.coreid = rand() & 0x3F;
        in_pc.laddr  = (((uint64_t)rand() << 32) | (uint64_t)rand()) & 0x7FFFFFFFFF;
        in_pc.sptbr  = (((uint64_t)rand() << 32) | (uint64_t)rand()) & 0x3FFFFFFFFF;
        in_pc_list.push_front(in_pc);

        OutputPacket out_pc;
        out_pc.coreid   = in_pc.coreid;
        out_pc.prefetch = 0;
        out_pc.hpaddr   = (in_pc.laddr >> 12) & 0x7FF;
        out_pc.ppaddr   = (in_pc.laddr >> 12) & 0x7;
        out_pc_list.push_front(out_pc);
      }

      if (((rand() & 0x3)==0) && in_pf_list.size() < 3) {
        InputPacket_Prefetch in_pf;
        in_pf.l2     = rand() & 1;
        in_pf.laddr  = (((uint64_t)rand() << 32) | (uint64_t)rand()) & 0x7FFFFFFFFF;
        in_pf.sptbr  = (((uint64_t)rand() << 32) | (uint64_t)rand()) & 0x3FFFFFFFFF;
        in_pf_list.push_front(in_pf);

        OutputPacket out_pf;
        out_pf.coreid   = 0;
        out_pf.prefetch = 1;
        out_pf.hpaddr   = (in_pf.laddr >> 12) & 0x7FF;
        out_pf.ppaddr   = (in_pf.laddr >> 12) & 0x7;
        out_pf_list.push_front(out_pf);
      }
      //advance_clock(top,1);
    }
#endif
  }

  printf("performed %lld test in %lld cycles\n",ntests,(long long)global_time/2);

  sim_finish(true);
}


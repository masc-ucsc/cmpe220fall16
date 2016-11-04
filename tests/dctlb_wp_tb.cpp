
#include "Vdctlb_wp.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <list>

#include <time.h>

#define DEBUG_TRACE 1

vluint64_t global_time = 0;
VerilatedVcdC* tfp = 0;

long ntests = 0;

void advance_half_clock(Vdctlb_wp *top) {
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

void advance_clock(Vdctlb_wp *top, int nclocks=1) {

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

struct InputPacket_Load { //coretodctlb_ld_type
  int ckpid;
  int coreid;
  int lop;
  int pnr;
  int laddr;
  int imm;
  int sptbr;
  int user;
};

struct InputPacket_Store { //coretodctlb_st_type
  int ckpid;
  int coreid;
  int mop;
  int pnr;
  int laddr;
  int imm;
  int sptbr;
  int user;
};

struct InputPacket_Prefetch { // prefetch request
  int l2;
  int laddr;
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

std::list<InputPacket_Load>  in_ld_list;
std::list<InputPacket_Store>  in_st_list;
std::list<InputPacket_Prefetch>  in_pf_list;
std::list<OutputPacket> out_ld_list;
std::list<OutputPacket> out_st_list;
std::list<OutputPacket> out_pf_list;


void try_send_packet(Vdctlb_wp *top) {
 /* static int set_retry_for = 0;
  if ((rand()&0xF)==0 && set_retry_for == 0) {
    set_retry_for = rand()&0x1F;
  }
  if (set_retry_for) {
    set_retry_for--;
    top->sumRetry = 1;
  }else{
    top->sumRetry = (rand()&0xF)==0; // randomly, one every 8 packets
  }
  */

  if (!top->coretodctlb_ld_retry) {
    top->coretodctlb_ld_ckpid = rand();
    top->coretodctlb_ld_coreid = rand();
    top->coretodctlb_ld_lop = rand();
    top->coretodctlb_ld_pnr = rand();
    top->coretodctlb_ld_laddr = rand();
    top->coretodctlb_ld_imm = rand();
    top->coretodctlb_ld_sptbr = rand();
    top->coretodctlb_ld_user = rand();

    if (in_ld_list.empty() || (rand() & 0x3)) { // Once every 4
      top->coretodctlb_ld_valid = 0;
    }else{
      top->coretodctlb_ld_valid = 1;
    }
  }

  if (!top->coretodctlb_st_retry) {
    top->coretodctlb_st_ckpid = rand();
    top->coretodctlb_st_coreid = rand();
    top->coretodctlb_st_mop = rand();
    top->coretodctlb_st_pnr = rand();
    top->coretodctlb_st_laddr = rand();
    top->coretodctlb_st_imm = rand();
    top->coretodctlb_st_sptbr = rand();
    top->coretodctlb_st_user = rand();

    if (in_st_list.empty() || (rand() & 0x3)) { // Once every 4 cycles
      top->coretodctlb_st_valid = 0;
    }else{
      top->coretodctlb_st_valid = 1;
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

  if (top->coretodctlb_ld_valid && !top->coretodctlb_ld_retry) {
    if (in_ld_list.empty()) {
      fprintf(stderr,"ERROR: Internal error, in_ld_list could not be empty\n");
    }
    InputPacket_Load in_ld = in_ld_list.back();
    top->coretodctlb_ld_ckpid = in_ld.ckpid;
    top->coretodctlb_ld_coreid = in_ld.coreid;
    top->coretodctlb_ld_lop = in_ld.lop;
    top->coretodctlb_ld_pnr = in_ld.pnr;
    top->coretodctlb_ld_laddr = in_ld.laddr;
    top->coretodctlb_ld_imm = in_ld.imm;
    top->coretodctlb_ld_sptbr = in_ld.sptbr;
    top->coretodctlb_ld_user = in_ld.user;
#ifdef DEBUG_TRACE
    printf("@%lld \tin_ld_ckpid=%X\n",global_time, in_ld.ckpid);
    printf("\t\tin_ld_coreid=%X\n", in_ld.coreid);
    printf("\t\tin_ld_lop=%X\n", in_ld.lop);
    printf("\t\tin_ld_pnr=%X\n", in_ld.pnr);
    printf("\t\tin_ld_laddr=%X\n", in_ld.laddr);
    printf("\t\tin_ld_imm=%X\n", in_ld.imm);
    printf("\t\tin_ld_sptbr=%X\n", in_ld.sptbr);
    printf("\t\tin_ld_user=%X\n", in_ld.user);
#endif
    in_ld_list.pop_back();
  }

  if (top->coretodctlb_st_valid && !top->coretodctlb_st_retry) {
    if (in_st_list.empty()) {
      fprintf(stderr,"ERROR: Internal error, in_st_list could not be empty\n");
    }
    InputPacket_Store in_st = in_st_list.back();
    top->coretodctlb_st_ckpid = in_st.ckpid;
    top->coretodctlb_st_coreid = in_st.coreid;
    top->coretodctlb_st_mop = in_st.mop;
    top->coretodctlb_st_pnr = in_st.pnr;
    top->coretodctlb_st_laddr = in_st.laddr;
    top->coretodctlb_st_imm = in_st.imm;
    top->coretodctlb_st_sptbr = in_st.sptbr;
    top->coretodctlb_st_user = in_st.user;
#ifdef DEBUG_TRACE
    printf("@%lld in_st_ckpid=%X\n",global_time, in_st.ckpid);
    printf("\t\tin_st_coreid=%X\n", in_st.coreid);
    printf("\t\tin_st_mop=%X\n", in_st.mop);
    printf("\t\tin_st_pnr=%X\n", in_st.pnr);
    printf("\t\tin_st_laddr=%X\n", in_st.laddr);
    printf("\t\tin_st_imm=%X\n", in_st.imm);
    printf("\t\tin_st_sptbr=%X\n", in_st.sptbr);
    printf("\t\tin_st_user=%X\n", in_st.user);
#endif
    in_st_list.pop_back();
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
    printf("\t\tin_pf_laddr=%X\n", in_pf.laddr);
    printf("\t\tin_pf_sptbr=%X\n", in_pf.sptbr);
#endif
    in_pf_list.pop_back();
  }

}

void error_found(Vdctlb_wp *top) {
  advance_half_clock(top);
  advance_half_clock(top);
  sim_finish(false);
}

void try_recv_packet(Vdctlb_wp *top) {

  if (top->l1tlbtol1_fwd0_valid && out_ld_list.empty() && out_pf_list.empty()) {
    printf("ERROR: unexpected result in fwd ld: hpaddr=%X, ppaddr=%X\n",top->l1tlbtol1_fwd0_hpaddr, top->l1tlbtol1_fwd0_ppaddr);
    error_found(top);
    return;
  }

  if (top->l1tlbtol1_fwd1_valid && out_st_list.empty() && out_pf_list.empty()) {
    printf("ERROR: unexpected result in fwd st: hpaddr=%X, ppaddr=%X\n",top->l1tlbtol1_fwd1_hpaddr, top->l1tlbtol1_fwd1_ppaddr);
    error_found(top);
    return;
  }

  if (top->l1tlbtol1_fwd0_retry || top->l1tlbtol1_fwd1_retry)
    return;

  if (!top->l1tlbtol1_fwd0_valid || !top->l1tlbtol1_fwd1_valid)
    return;

  if (out_ld_list.empty() || out_st_list.empty())
    return;

#ifdef DEBUG_TRACE
    printf("@%lld fwd0_hpaddr=%X fwd0_ppaddr\n",global_time, top->l1tlbtol1_fwd0_hpaddr, top->l1tlbtol1_fwd0_ppaddr);
    printf("@%lld fwd1_hpaddr=%X fwd1_ppaddr\n",global_time, top->l1tlbtol1_fwd1_hpaddr, top->l1tlbtol1_fwd1_ppaddr);
#endif
  OutputPacket out_ld = out_ld_list.back();
  OutputPacket out_st = out_st_list.back();
  OutputPacket out_pf;
  bool is_in_pf;

  int out_ld_hpaddr = top->l1tlbtol1_fwd0_hpaddr;
  int out_ld_ppaddr = top->l1tlbtol1_fwd0_ppaddr;
  int out_st_hpaddr = top->l1tlbtol1_fwd1_hpaddr;
  int out_st_ppaddr = top->l1tlbtol1_fwd1_ppaddr;

  if(out_ld_hpaddr != out_ld.hpaddr || out_ld_ppaddr != out_ld_ppaddr){
      is_in_pf = false;
      while(!out_pf_list.empty()){
        out_pf = out_pf_list.back();
        out_pf_list.pop_back();
        if(out_ld_hpaddr == out_pf.hpaddr && out_ld_ppaddr == out_pf.ppaddr){
            is_in_pf = true;
            break;
        }
      }
      if(!is_in_pf){
          printf("ERROR: got %X but expected out_ld.hpaddr = %X\n", out_ld_hpaddr, out_ld.hpaddr);
          printf("\t got %X but expected out_ld.ppaddr = %X\n", out_ld_ppaddr, out_ld.ppaddr);
          printf("\t value not sent as a prefetch\n");
          error_found(top);
      }
  }

  if(out_st_hpaddr != out_st.hpaddr || out_st_ppaddr != out_st_ppaddr){
      is_in_pf = false;
      while(!out_pf_list.empty()){
        out_pf = out_pf_list.back();
        out_pf_list.pop_back();
        if(out_st_hpaddr == out_pf.hpaddr && out_st_ppaddr == out_pf.ppaddr){
            is_in_pf = true;
            break;
        }
      }
      if(!is_in_pf){
          printf("ERROR: got %X but expected out_st.hpaddr = %X\n", out_st_hpaddr, out_st.hpaddr);
          printf("\t got %X but expected out_st.ppaddr = %X\n", out_st_ppaddr, out_st.ppaddr);
          printf("\t value not sent as a prefetch\n");
          error_found(top);
      }
  }

  out_ld_list.pop_back();
  out_st_list.pop_back();
  ntests++;
}


int main(int argc, char **argv, char **env) {
  int i;
  int clk;
  Verilated::commandArgs(argc, argv);
  // init top verilog instance
  Vdctlb_wp* top = new Vdctlb_wp;

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
  tfp->open("output.vcd");
#endif

  // initialize simulation inputs
  top->clk = 1;

  for(int niters=0 ; niters < 50; niters++) {
    //-------------------------------------------------------

#ifdef DEBUG_TRACE
    printf("reset\n");
#endif
    top->reset = 1;

    in_ld_list.clear();
    in_st_list.clear();
    in_pf_list.clear();
    out_ld_list.clear();
    out_st_list.clear();

    top->coretodctlb_ld_valid = 1;
    top->coretodctlb_st_valid = 1;
    top->pfetol1tlb_req_valid = 1;
    int ncycles= rand() & 0xFF;
    ncycles++; // At least one cycle reset
    for(int i =0;i<ncycles;i++) {
      //top->inp_a = rand() & 0xFF;
      //top->inp_b = rand() & 0xFF;
      top->coretodctlb_ld_ckpid  = rand() & 0xF;
      top->coretodctlb_ld_coreid = rand() & 0x3F;
      top->coretodctlb_ld_lop    = rand() & 0x5F;
      top->coretodctlb_ld_pnr    = rand() & 0x1;
      top->coretodctlb_ld_laddr  = rand() & 0x7FFFFFFFFF;
      top->coretodctlb_ld_imm    = rand() & 0xFFF;
      top->coretodctlb_ld_sptbr  = rand() & 0x3FFFFFFFFF;
      top->coretodctlb_ld_user   = rand() & 0x1;
      //top->coretodctlb_ld_retry  = rand() & 1;

      top->coretodctlb_st_ckpid  = rand() & 0xF;
      top->coretodctlb_st_coreid = rand() & 0x3F;
      top->coretodctlb_st_mop    = rand() & 0x5F;
      top->coretodctlb_st_pnr    = rand() & 0x1;
      top->coretodctlb_st_laddr  = rand() & 0x7FFFFFFFFF;
      top->coretodctlb_st_imm    = rand() & 0xFFF;
      top->coretodctlb_st_sptbr  = rand() & 0x3FFFFFFFFF;
      top->coretodctlb_st_user   = rand() & 0x1;
      //top->coretodctlb_st_retry  = rand() & 1;

      top->pfetol1tlb_req_l2     = rand() & 1;
      top->pfetol1tlb_req_laddr  = rand() & 0x7FFFFFFFFF;
      top->pfetol1tlb_req_sptbr  = rand() & 0x3FFFFFFFFF;
      //top->pfetol1tlb_req_retry  = rand() & 1;
      
      top->l1tlbtol1_fwd0_retry  = rand() & 1;
      top->l1tlbtol1_fwd1_retry  = rand() & 1;


      advance_clock(top,1);
    }

#ifdef DEBUG_TRACE
    printf("no reset\n");
#endif
    //-------------------------------------------------------
    top->reset = 0;
    top->coretodctlb_ld_valid   = 0; 
    top->coretodctlb_ld_ckpid   = 0;
    top->coretodctlb_ld_coreid  = 0;
    top->coretodctlb_ld_lop     = 0; 
    top->coretodctlb_ld_pnr     = 0; 
    top->coretodctlb_ld_laddr   = 0; 
    top->coretodctlb_ld_imm     = 0; 
    top->coretodctlb_ld_sptbr   = 0;
    top->coretodctlb_ld_user    = 0;

    top->coretodctlb_st_valid   = 0;
    top->coretodctlb_st_ckpid   = 0;
    top->coretodctlb_st_coreid  = 0;
    top->coretodctlb_st_mop     = 0; 
    top->coretodctlb_st_pnr     = 0; 
    top->coretodctlb_st_laddr   = 0; 
    top->coretodctlb_st_imm     = 0; 
    top->coretodctlb_st_sptbr   = 0;
    top->coretodctlb_st_user    = 0;

    top->pfetol1tlb_req_valid   = 0;
    top->pfetol1tlb_req_l2      = 0;
    top->pfetol1tlb_req_laddr   = 0;
    top->pfetol1tlb_req_sptbr   = 0;

    top->l1tlbtol1_fwd0_retry   = 1;
    top->l1tlbtol1_fwd1_retry   = 1;

    advance_clock(top,1);

#if 1
    for(int i =0;i<1024;i++) {
      try_send_packet(top);
      advance_clock(top,1);
      try_recv_packet(top);
      advance_clock(top,1);

      if (((rand() & 0x3)==0) && in_ld_list.size() < 3 && in_st_list.size() < 3 && in_pf_list.size() < 3) {
        InputPacket_Load in_ld;
        in_ld.ckpid  = rand() & 0xF;
        in_ld.coreid = rand() & 0x3F;
        in_ld.lop    = rand() & 0x5F;
        in_ld.pnr    = rand() & 0x1;
        in_ld.laddr  = rand() & 0x7FFFFFFFFF;
        in_ld.imm    = rand() & 0xFFF;
        in_ld.sptbr  = rand() & 0x3FFFFFFFFF;
        in_ld.user   = rand() & 0x1;
        in_ld_list.push_front(in_ld);

        OutputPacket out_ld;
        out_ld.coreid   = in_ld.coreid;
        out_ld.prefetch = 0;
        out_ld.hpaddr   = in_ld.laddr & 0x7FF000;
        printf("ld hpaddr = %X\n", out_ld.hpaddr);
        out_ld.ppaddr   = in_ld.laddr & 0x7000;
        printf("ld ppaddr = %X\n", out_ld.ppaddr);
        out_ld_list.push_front(out_ld);


        InputPacket_Store in_st;
        in_st.ckpid  = rand() & 0xF;
        in_st.coreid = rand() & 0x3F;
        in_st.mop    = rand() & 0x5F;
        in_st.pnr    = rand() & 0x1;
        in_st.laddr  = rand() & 0x7FFFFFFFFF;
        in_st.imm    = rand() & 0xFFF;
        in_st.sptbr  = rand() & 0x3FFFFFFFFF;
        in_st.user   = rand() & 0x1;
        in_st_list.push_front(in_st);

        OutputPacket out_st;
        out_st.coreid   = in_st.coreid;
        out_st.prefetch = 0;
        out_st.hpaddr   = in_st.laddr & 0x7FF000;
        printf("st hpaddr = %X\n", out_st.hpaddr);
        out_st.ppaddr   = in_st.laddr & 0x7000;
        printf("st ppaddr = %X\n", out_st.ppaddr);
        out_st_list.push_front(out_st);

        InputPacket_Prefetch in_pf;
        in_pf.l2     = rand() & 1;
        in_pf.laddr  = rand() & 0x7FFFFFFFFF;
        in_pf.sptbr  = rand() & 0x3FFFFFFFFF;
        in_pf_list.push_front(in_pf);

        OutputPacket out_pf;
        out_pf.coreid   = 0;
        out_pf.prefetch = 1;
        out_pf.hpaddr   = in_pf.laddr & 0x7FF000;
        printf("pf hpaddr = %X\n", out_pf.hpaddr);
        out_pf.ppaddr   = in_pf.laddr & 0x7000;
        printf("pf ppaddr = %X\n", out_pf.ppaddr);
        out_pf_list.push_front(out_pf);

      }
      //advance_clock(top,1);
    }
#endif
  }

  printf("performed %lld test in %lld cycles\n",ntests,(long long)global_time/2);

  sim_finish(true);
}


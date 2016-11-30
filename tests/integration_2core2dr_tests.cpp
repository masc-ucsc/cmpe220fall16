
#include "Vintegration_2core2dr.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <list>
#include <getopt.h>

#include <time.h>

#define DEBUG_TRACE 1

vluint64_t global_time = 0;
VerilatedVcdC* tfp = 0;


long ntests = 0;

struct DCacheLDReq {
  int ckpid;
  int coreid;
  int lop;
  int pnr;

  int pcsign; // hash of pc (random is fine)
  int poffset;
  int imm;

  int laddr; 
};

struct DCacheSTReq {
  int ckpid;
  int coreid;
  int mop;
  int pnr;

  int pcsign; // hash of pc (random is fine)
  int poffset;
  int imm;

  int laddr; 

  int data;
};

// responses from loads
struct DCResp {
  int coreid;
  int fault;
  unsigned int* data;
};

struct MemReq {
  int drid;
  int cmd;
  int paddr;
};

struct MemResp {
  int drid;
  int nid;
  int paddr;
  int ack;
  unsigned int line[16];
};

std::list<DCacheLDReq> c0s0_ld_req_queue;
std::list<DCacheLDReq> c0s1_ld_req_queue;
std::list<DCacheLDReq> c0s2_ld_req_queue;
std::list<DCacheLDReq> c0s3_ld_req_queue;


std::list<DCacheSTReq> c0s0_st_req_queue;
std::list<DCacheSTReq> c0s1_st_req_queue;
std::list<DCacheSTReq> c0s2_st_req_queue;
std::list<DCacheSTReq> c0s3_st_req_queue;

std::list<DCResp> c0s0_resp_queue;
std::list<DCResp> c0s1_resp_queue;
std::list<DCResp> c0s2_resp_queue;
std::list<DCResp> c0s3_resp_queue;

std::list<MemReq> dr0_reqs;
std::list<MemReq> dr1_reqs;

std::list<MemResp> dr0_resps;
std::list<MemResp> dr1_resps;

long mask(int bits) {
  return ((long)1 << bits)-1;
}

void advance_half_clock(Vintegration_2core2dr *top) {
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

void advance_clock(Vintegration_2core2dr *top, int nclocks=1) {

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

void error_found(Vintegration_2core2dr *top) {
  advance_clock(top,4);
  sim_finish(false);
}

void set_handshake(Vintegration_2core2dr* top, int value) {
  top->core0_coretoic_pc_valid                 = value < 0? rand() & 0x1 : value & 0x1;
  top->core0_slice0_coretodc_ld_valid          = value < 0? rand() & 0x1 : value & 0x1;
  top->core0_slice0_coretodc_std_valid         = value < 0? rand() & 0x1 : value & 0x1;
  top->c0_s0_coretodctlb_ld_valid              = value < 0? rand() & 0x1 : value & 0x1;
  top->c0_s0_coretodctlb_st_valid              = value < 0? rand() & 0x1 : value & 0x1;
  top->core0_slice1_coretodc_ld_valid          = value < 0? rand() & 0x1 : value & 0x1;
  top->core0_slice1_coretodc_std_valid         = value < 0? rand() & 0x1 : value & 0x1;
  top->c0_s1_coretodctlb_ld_valid              = value < 0? rand() & 0x1 : value & 0x1;
  top->c0_s1_coretodctlb_st_valid              = value < 0? rand() & 0x1 : value & 0x1;
  top->core0_ictocore_retry                    = value < 0? rand() & 0x1 : value & 0x1;
  top->core0_slice0_dctocore_ld_retry          = value < 0? rand() & 0x1 : value & 0x1;
  top->core0_slice0_dctocore_std_ack_retry     = value < 0? rand() & 0x1 : value & 0x1;
  top->core0_slice1_dctocore_ld_retry          = value < 0? rand() & 0x1 : value & 0x1;
  top->core0_slice1_dctocore_std_ack_retry     = value < 0? rand() & 0x1 : value & 0x1;


#ifdef SC_4PIPE
  top->core0_slice2_dctocore_ld_retry        = value < 0? rand() & 0x1 : value & 0x1;
  top->core0_slice2_dctocore_std_ack_retry   = value < 0? rand() & 0x1 : value & 0x1;
  top->core0_slice3_dctocore_ld_retry        = value < 0? rand() & 0x1 : value & 0x1;
  top->core0_slice3_dctocore_std_ack_retry   = value < 0? rand() & 0x1 : value & 0x1;
  top->core0_slice2_coretodc_ld_valid        = value < 0? rand() & 0x1 : value & 0x1;
  top->core0_slice2_coretodc_std_valid       = value < 0? rand() & 0x1 : value & 0x1;
  top->c0_s2_coretodctlb_ld_valid            = value < 0? rand() & 0x1 : value & 0x1;
  top->c0_s2_coretodctlb_st_valid            = value < 0? rand() & 0x1 : value & 0x1;
  top->core0_slice3_coretodc_ld_valid        = value < 0? rand() & 0x1 : value & 0x1;
  top->core0_slice3_coretodc_std_valid       = value < 0? rand() & 0x1 : value & 0x1;
  top->c0_s3_coretodctlb_ld_valid            = value < 0? rand() & 0x1 : value & 0x1;
  top->c0_s3_coretodctlb_st_valid            = value < 0? rand() & 0x1 : value & 0x1;

#endif
  top->core0_pfgtopfe_op_valid               = value < 0? rand() & 0x1 : value & 0x1;
  top->core1_coretoic_pc_valid               = value < 0? rand() & 0x1 : value & 0x1;
  top->core1_slice0_coretodc_ld_valid        = value < 0? rand() & 0x1 : value & 0x1;
  top->core1_slice0_coretodc_std_valid       = value < 0? rand() & 0x1 : value & 0x1;
  top->c1_s0_coretodctlb_ld_valid            = value < 0? rand() & 0x1 : value & 0x1;
  top->c1_s0_coretodctlb_st_valid            = value < 0? rand() & 0x1 : value & 0x1;
  top->core1_slice1_coretodc_ld_valid        = value < 0? rand() & 0x1 : value & 0x1;
  top->core1_slice1_coretodc_std_valid       = value < 0? rand() & 0x1 : value & 0x1;
  top->c1_s1_coretodctlb_ld_valid            = value < 0? rand() & 0x1 : value & 0x1;
  top->c1_s1_coretodctlb_st_valid            = value < 0? rand() & 0x1 : value & 0x1;
  top->core1_ictocore_retry                  = value < 0? rand() & 0x1 : value & 0x1;
  top->core1_slice0_dctocore_ld_retry        = value < 0? rand() & 0x1 : value & 0x1;
  top->core1_slice0_dctocore_std_ack_retry   = value < 0? rand() & 0x1 : value & 0x1;
  top->core1_slice1_dctocore_ld_retry        = value < 0? rand() & 0x1 : value & 0x1;
  top->core1_slice1_dctocore_std_ack_retry   = value < 0? rand() & 0x1 : value & 0x1;


#ifdef SC_4PIPE
  top->core1_slice2_dctocore_ld_retry         = value < 0? rand() & 0x1 : value & 0x1;
  top->core1_slice2_dctocore_std_ack_retry    = value < 0? rand() & 0x1 : value & 0x1;
  top->core1_slice3_dctocore_ld_retry         = value < 0? rand() & 0x1 : value & 0x1;
  top->core1_slice3_dctocore_std_ack_retry    = value < 0? rand() & 0x1 : value & 0x1;
  top->core1_slice2_coretodc_ld_valid         = value < 0? rand() & 0x1 : value & 0x1;
  top->core1_slice2_coretodc_std_valid        = value < 0? rand() & 0x1 : value & 0x1;
  top->c1_s2_coretodctlb_ld_valid             = value < 0? rand() & 0x1 : value & 0x1;
  top->c1_s2_coretodctlb_st_valid             = value < 0? rand() & 0x1 : value & 0x1;
  top->core1_slice3_coretodc_ld_valid         = value < 0? rand() & 0x1 : value & 0x1;
  top->core1_slice3_coretodc_std_valid        = value < 0? rand() & 0x1 : value & 0x1;
  top->c1_s3_coretodctlb_ld_valid             = value < 0? rand() & 0x1 : value & 0x1;
  top->c1_s3_coretodctlb_st_valid             = value < 0? rand() & 0x1 : value & 0x1;

#endif

  top->core1_pfgtopfe_op_valid  = value < 0? rand() & 0x1 : value & 0x1;
  top->dr0_memtodr_ack_valid    = value < 0? rand() & 0x1 : value & 0x1;
  top->dr1_memtodr_ack_valid    = value < 0? rand() & 0x1 : value & 0x1;
  top->dr0_drtomem_req_retry    = value < 0? rand() & 0x1 : value & 0x1;
  top->dr0_drtomem_wb_retry     = value < 0? rand() & 0x1 : value & 0x1;
  top->dr0_drtomem_pfreq_retry  = value < 0? rand() & 0x1 : value & 0x1;
  top->dr1_drtomem_req_retry    = value < 0? rand() & 0x1 : value & 0x1;
  top->dr1_drtomem_wb_retry     = value < 0? rand() & 0x1 : value & 0x1;
  top->dr1_drtomem_pfreq_retry  = value < 0? rand() & 0x1 : value & 0x1;
}

void set_array(int size, unsigned int* data, int value) {
  for(int i = 0; i < size; ++i){
    data[i] = (value < 0? rand() : value);
  }
}

void set_ports(Vintegration_2core2dr* top, int value) {

  //FIXME: we should have a different rand for each data camp.

  top->core0_coretoic_pc_coreid          = value < 0? rand() : value ;
  top->core0_coretoic_pc_poffset         = value < 0? rand() : value ;
  top->core0_slice0_coretodc_ld_ckpid    = value < 0? rand() : value ;
  top->core0_slice0_coretodc_ld_coreid   = value < 0? rand() : value ;
  top->core0_slice0_coretodc_ld_lop      = value < 0? rand() : value ;
  top->core0_slice0_coretodc_ld_pnr      = value < 0? rand() : value ;
  top->core0_slice0_coretodc_ld_pcsign   = value < 0? rand() : value ;
  top->core0_slice0_coretodc_ld_poffset  = value < 0? rand() : value ;
  top->core0_slice0_coretodc_ld_imm      = value < 0? rand() : value ;
  top->core0_slice0_coretodc_std_ckpid   = value < 0? rand() : value ;
  top->core0_slice0_coretodc_std_coreid  = value < 0? rand() : value ;
  top->core0_slice0_coretodc_std_mop     = value < 0? rand() : value ;
  top->core0_slice0_coretodc_std_pnr     = value < 0? rand() : value ;
  top->core0_slice0_coretodc_std_pcsign  = value < 0? rand() : value ;
  top->core0_slice0_coretodc_std_poffset = value < 0? rand() : value ;
  top->core0_slice0_coretodc_std_imm     = value < 0? rand() : value ;
  set_array(16,top->core0_slice0_coretodc_std_data,value);
  top->c0_s0_coretodctlb_ld_ckpid        = value < 0? rand() : value ;
  top->c0_s0_coretodctlb_ld_coreid       = value < 0? rand() : value ;
  top->c0_s0_coretodctlb_ld_lop          = value < 0? rand() : value ;
  top->c0_s0_coretodctlb_ld_pnr          = value < 0? rand() : value ;
  top->c0_s0_coretodctlb_ld_laddr        = value < 0? rand() : value ;
  top->c0_s0_coretodctlb_ld_imm          = value < 0? rand() : value ;
  top->c0_s0_coretodctlb_ld_sptbr        = value < 0? rand() : value ;
  top->c0_s0_coretodctlb_ld_user         = value < 0? rand() : value ;
  top->c0_s0_coretodctlb_st_ckpid        = value < 0? rand() : value ;
  top->c0_s0_coretodctlb_st_coreid       = value < 0? rand() : value ;
  top->c0_s0_coretodctlb_st_mop          = value < 0? rand() : value ;
  top->c0_s0_coretodctlb_st_pnr          = value < 0? rand() : value ;
  top->c0_s0_coretodctlb_st_laddr        = value < 0? rand() : value ;
  top->c0_s0_coretodctlb_st_imm          = value < 0? rand() : value ;
  top->c0_s0_coretodctlb_st_sptbr        = value < 0? rand() : value ;
  top->c0_s0_coretodctlb_st_user         = value < 0? rand() : value ;
  top->core0_slice1_coretodc_ld_ckpid    = value < 0? rand() : value ;
  top->core0_slice1_coretodc_ld_coreid   = value < 0? rand() : value ;
  top->core0_slice1_coretodc_ld_lop      = value < 0? rand() : value ;
  top->core0_slice1_coretodc_ld_pnr      = value < 0? rand() : value ;
  top->core0_slice1_coretodc_ld_pcsign   = value < 0? rand() : value ;
  top->core0_slice1_coretodc_ld_poffset  = value < 0? rand() : value ;
  top->core0_slice1_coretodc_ld_imm      = value < 0? rand() : value ;
  top->core0_slice1_coretodc_std_ckpid   = value < 0? rand() : value ;
  top->core0_slice1_coretodc_std_coreid  = value < 0? rand() : value ;
  top->core0_slice1_coretodc_std_mop     = value < 0? rand() : value ;
  top->core0_slice1_coretodc_std_pnr     = value < 0? rand() : value ;
  top->core0_slice1_coretodc_std_pcsign  = value < 0? rand() : value ;
  top->core0_slice1_coretodc_std_poffset = value < 0? rand() : value ;
  top->core0_slice1_coretodc_std_imm     = value < 0? rand() : value ;
  set_array(16,top->core0_slice1_coretodc_std_data,value);
  top->c0_s1_coretodctlb_ld_ckpid        = value < 0? rand() : value ;
  top->c0_s1_coretodctlb_ld_coreid       = value < 0? rand() : value ;
  top->c0_s1_coretodctlb_ld_lop          = value < 0? rand() : value ;
  top->c0_s1_coretodctlb_ld_pnr          = value < 0? rand() : value ;
  top->c0_s1_coretodctlb_ld_laddr        = value < 0? rand() : value ;
  top->c0_s1_coretodctlb_ld_imm          = value < 0? rand() : value ;
  top->c0_s1_coretodctlb_ld_sptbr        = value < 0? rand() : value ;
  top->c0_s1_coretodctlb_ld_user         = value < 0? rand() : value ;
  top->c0_s1_coretodctlb_st_ckpid        = value < 0? rand() : value ;
  top->c0_s1_coretodctlb_st_coreid       = value < 0? rand() : value ;
  top->c0_s1_coretodctlb_st_mop          = value < 0? rand() : value ;
  top->c0_s1_coretodctlb_st_pnr          = value < 0? rand() : value ;
  top->c0_s1_coretodctlb_st_laddr        = value < 0? rand() : value ;
  top->c0_s1_coretodctlb_st_imm          = value < 0? rand() : value ;
  top->c0_s1_coretodctlb_st_sptbr        = value < 0? rand() : value ;
  top->c0_s1_coretodctlb_st_user         = value < 0? rand() : value ;
#ifdef  SC_4PIPE
  top->core0_slice2_coretodc_ld_ckpid    = value < 0? rand() : value ;
  top->core0_slice2_coretodc_ld_coreid   = value < 0? rand() : value ;
  top->core0_slice2_coretodc_ld_lop      = value < 0? rand() : value ;
  top->core0_slice2_coretodc_ld_pnr      = value < 0? rand() : value ;
  top->core0_slice2_coretodc_ld_pcsign   = value < 0? rand() : value ;
  top->core0_slice2_coretodc_ld_poffset  = value < 0? rand() : value ;
  top->core0_slice2_coretodc_ld_imm      = value < 0? rand() : value ;
  top->core0_slice2_coretodc_std_ckpid   = value < 0? rand() : value ;
  top->core0_slice2_coretodc_std_coreid  = value < 0? rand() : value ;
  top->core0_slice2_coretodc_std_mop     = value < 0? rand() : value ;
  top->core0_slice2_coretodc_std_pnr     = value < 0? rand() : value ;
  top->core0_slice2_coretodc_std_pcsign  = value < 0? rand() : value ;
  top->core0_slice2_coretodc_std_poffset = value < 0? rand() : value ;
  top->core0_slice2_coretodc_std_imm     = value < 0? rand() : value ;
  set_array(16,top->core0_slice2_coretodc_std_data,value);
  top->c0_s2_coretodctlb_ld_ckpid        = value < 0? rand() : value ;
  top->c0_s2_coretodctlb_ld_coreid       = value < 0? rand() : value ;
  top->c0_s2_coretodctlb_ld_lop          = value < 0? rand() : value ;
  top->c0_s2_coretodctlb_ld_pnr          = value < 0? rand() : value ;
  top->c0_s2_coretodctlb_ld_laddr        = value < 0? rand() : value ;
  top->c0_s2_coretodctlb_ld_imm          = value < 0? rand() : value ;
  top->c0_s2_coretodctlb_ld_sptbr        = value < 0? rand() : value ;
  top->c0_s2_coretodctlb_ld_user         = value < 0? rand() : value ;
  top->c0_s2_coretodctlb_st_ckpid        = value < 0? rand() : value ;
  top->c0_s2_coretodctlb_st_coreid       = value < 0? rand() : value ;
  top->c0_s2_coretodctlb_st_mop          = value < 0? rand() : value ;
  top->c0_s2_coretodctlb_st_pnr          = value < 0? rand() : value ;
  top->c0_s2_coretodctlb_st_laddr        = value < 0? rand() : value ;
  top->c0_s2_coretodctlb_st_imm          = value < 0? rand() : value ;
  top->c0_s2_coretodctlb_st_sptbr        = value < 0? rand() : value ;
  top->c0_s2_coretodctlb_st_user         = value < 0? rand() : value ;
  top->core0_slice3_coretodc_ld_ckpid    = value < 0? rand() : value ;
  top->core0_slice3_coretodc_ld_coreid   = value < 0? rand() : value ;
  top->core0_slice3_coretodc_ld_lop      = value < 0? rand() : value ;
  top->core0_slice3_coretodc_ld_pnr      = value < 0? rand() : value ;
  top->core0_slice3_coretodc_ld_pcsign   = value < 0? rand() : value ;
  top->core0_slice3_coretodc_ld_poffset  = value < 0? rand() : value ;
  top->core0_slice3_coretodc_ld_imm      = value < 0? rand() : value ;
  top->core0_slice3_coretodc_std_ckpid   = value < 0? rand() : value ;
  top->core0_slice3_coretodc_std_coreid  = value < 0? rand() : value ;
  top->core0_slice3_coretodc_std_mop     = value < 0? rand() : value ;
  top->core0_slice3_coretodc_std_pnr     = value < 0? rand() : value ;
  top->core0_slice3_coretodc_std_pcsign  = value < 0? rand() : value ;
  top->core0_slice3_coretodc_std_poffset = value < 0? rand() : value ;
  top->core0_slice3_coretodc_std_imm     = value < 0? rand() : value ;
  set_array(16,top->core0_slice3_coretodc_std_data,value);
  top->c0_s3_coretodctlb_ld_ckpid        = value < 0? rand() : value ;
  top->c0_s3_coretodctlb_ld_coreid       = value < 0? rand() : value ;
  top->c0_s3_coretodctlb_ld_lop          = value < 0? rand() : value ;
  top->c0_s3_coretodctlb_ld_pnr          = value < 0? rand() : value ;
  top->c0_s3_coretodctlb_ld_laddr        = value < 0? rand() : value ;
  top->c0_s3_coretodctlb_ld_imm          = value < 0? rand() : value ;
  top->c0_s3_coretodctlb_ld_sptbr        = value < 0? rand() : value ;
  top->c0_s3_coretodctlb_ld_user         = value < 0? rand() : value ;
  top->c0_s3_coretodctlb_st_ckpid        = value < 0? rand() : value ;
  top->c0_s3_coretodctlb_st_coreid       = value < 0? rand() : value ;
  top->c0_s3_coretodctlb_st_mop          = value < 0? rand() : value ;
  top->c0_s3_coretodctlb_st_pnr          = value < 0? rand() : value ;
  top->c0_s3_coretodctlb_st_laddr        = value < 0? rand() : value ;
  top->c0_s3_coretodctlb_st_imm          = value < 0? rand() : value ;
  top->c0_s3_coretodctlb_st_sptbr        = value < 0? rand() : value ;
  top->c0_s3_coretodctlb_st_user         = value < 0? rand() : value ;
#endif
  top->core0_pfgtopfe_op_delta           = value < 0? rand() : value ;
  top->core0_pfgtopfe_op_w1              = value < 0? rand() : value ;
  top->core0_pfgtopfe_op_w2              = value < 0? rand() : value ;
  top->core0_pfgtopfe_op_pcsign          = value < 0? rand() : value ;
  top->core0_pfgtopfe_op_laddr           = value < 0? rand() : value ;
  top->core0_pfgtopfe_op_sptbr           = value < 0? rand() : value ;
  top->core1_coretoic_pc_coreid          = value < 0? rand() : value ;
  top->core1_coretoic_pc_poffset         = value < 0? rand() : value ;
  top->core1_slice0_coretodc_ld_ckpid    = value < 0? rand() : value ;
  top->core1_slice0_coretodc_ld_coreid   = value < 0? rand() : value ;
  top->core1_slice0_coretodc_ld_lop      = value < 0? rand() : value ;
  top->core1_slice0_coretodc_ld_pnr      = value < 0? rand() : value ;
  top->core1_slice0_coretodc_ld_pcsign   = value < 0? rand() : value ;
  top->core1_slice0_coretodc_ld_poffset  = value < 0? rand() : value ;
  top->core1_slice0_coretodc_ld_imm      = value < 0? rand() : value ;
  top->core1_slice0_coretodc_std_ckpid   = value < 0? rand() : value ;
  top->core1_slice0_coretodc_std_coreid  = value < 0? rand() : value ;
  top->core1_slice0_coretodc_std_mop     = value < 0? rand() : value ;
  top->core1_slice0_coretodc_std_pnr     = value < 0? rand() : value ;
  top->core1_slice0_coretodc_std_pcsign  = value < 0? rand() : value ;
  top->core1_slice0_coretodc_std_poffset = value < 0? rand() : value ;
  top->core1_slice0_coretodc_std_imm     = value < 0? rand() : value ;
  set_array(16,top->core1_slice0_coretodc_std_data,value);
  top->c1_s0_coretodctlb_ld_ckpid        = value < 0? rand() : value ;
  top->c1_s0_coretodctlb_ld_coreid       = value < 0? rand() : value ;
  top->c1_s0_coretodctlb_ld_lop          = value < 0? rand() : value ;
  top->c1_s0_coretodctlb_ld_pnr          = value < 0? rand() : value ;
  top->c1_s0_coretodctlb_ld_laddr        = value < 0? rand() : value ;
  top->c1_s0_coretodctlb_ld_imm          = value < 0? rand() : value ;
  top->c1_s0_coretodctlb_ld_sptbr        = value < 0? rand() : value ;
  top->c1_s0_coretodctlb_ld_user         = value < 0? rand() : value ;
  top->c1_s0_coretodctlb_st_ckpid        = value < 0? rand() : value ;
  top->c1_s0_coretodctlb_st_coreid       = value < 0? rand() : value ;
  top->c1_s0_coretodctlb_st_mop          = value < 0? rand() : value ;
  top->c1_s0_coretodctlb_st_pnr          = value < 0? rand() : value ;
  top->c1_s0_coretodctlb_st_laddr        = value < 0? rand() : value ;
  top->c1_s0_coretodctlb_st_imm          = value < 0? rand() : value ;
  top->c1_s0_coretodctlb_st_sptbr        = value < 0? rand() : value ;
  top->c1_s0_coretodctlb_st_user         = value < 0? rand() : value ;
  top->core1_slice1_coretodc_ld_ckpid    = value < 0? rand() : value ;
  top->core1_slice1_coretodc_ld_coreid   = value < 0? rand() : value ;
  top->core1_slice1_coretodc_ld_lop      = value < 0? rand() : value ;
  top->core1_slice1_coretodc_ld_pnr      = value < 0? rand() : value ;
  top->core1_slice1_coretodc_ld_pcsign   = value < 0? rand() : value ;
  top->core1_slice1_coretodc_ld_poffset  = value < 0? rand() : value ;
  top->core1_slice1_coretodc_ld_imm      = value < 0? rand() : value ;
  top->core1_slice1_coretodc_std_ckpid   = value < 0? rand() : value ;
  top->core1_slice1_coretodc_std_coreid  = value < 0? rand() : value ;
  top->core1_slice1_coretodc_std_mop     = value < 0? rand() : value ;
  top->core1_slice1_coretodc_std_pnr     = value < 0? rand() : value ;
  top->core1_slice1_coretodc_std_pcsign  = value < 0? rand() : value ;
  top->core1_slice1_coretodc_std_poffset = value < 0? rand() : value ;
  top->core1_slice1_coretodc_std_imm     = value < 0? rand() : value ;
  set_array(16,top->core1_slice1_coretodc_std_data,value);
  top->c1_s1_coretodctlb_ld_ckpid        = value < 0? rand() : value ;
  top->c1_s1_coretodctlb_ld_coreid       = value < 0? rand() : value ;
  top->c1_s1_coretodctlb_ld_lop          = value < 0? rand() : value ;
  top->c1_s1_coretodctlb_ld_pnr          = value < 0? rand() : value ;
  top->c1_s1_coretodctlb_ld_laddr        = value < 0? rand() : value ;
  top->c1_s1_coretodctlb_ld_imm          = value < 0? rand() : value ;
  top->c1_s1_coretodctlb_ld_sptbr        = value < 0? rand() : value ;
  top->c1_s1_coretodctlb_ld_user         = value < 0? rand() : value ;
  top->c1_s1_coretodctlb_st_ckpid        = value < 0? rand() : value ;
  top->c1_s1_coretodctlb_st_coreid       = value < 0? rand() : value ;
  top->c1_s1_coretodctlb_st_mop          = value < 0? rand() : value ;
  top->c1_s1_coretodctlb_st_pnr          = value < 0? rand() : value ;
  top->c1_s1_coretodctlb_st_laddr        = value < 0? rand() : value ;
  top->c1_s1_coretodctlb_st_imm          = value < 0? rand() : value ;
  top->c1_s1_coretodctlb_st_sptbr        = value < 0? rand() : value ;
  top->c1_s1_coretodctlb_st_user         = value < 0? rand() : value ;
#ifdef  SC_4PIPE
  top->core1_slice2_coretodc_ld_ckpid    = value < 0? rand() : value ;
  top->core1_slice2_coretodc_ld_coreid   = value < 0? rand() : value ;
  top->core1_slice2_coretodc_ld_lop      = value < 0? rand() : value ;
  top->core1_slice2_coretodc_ld_pnr      = value < 0? rand() : value ;
  top->core1_slice2_coretodc_ld_pcsign   = value < 0? rand() : value ;
  top->core1_slice2_coretodc_ld_poffset  = value < 0? rand() : value ;
  top->core1_slice2_coretodc_ld_imm      = value < 0? rand() : value ;
  top->core1_slice2_coretodc_std_ckpid   = value < 0? rand() : value ;
  top->core1_slice2_coretodc_std_coreid  = value < 0? rand() : value ;
  top->core1_slice2_coretodc_std_mop     = value < 0? rand() : value ;
  top->core1_slice2_coretodc_std_pnr     = value < 0? rand() : value ;
  top->core1_slice2_coretodc_std_pcsign  = value < 0? rand() : value ;
  top->core1_slice2_coretodc_std_poffset = value < 0? rand() : value ;
  top->core1_slice2_coretodc_std_imm     = value < 0? rand() : value ;
  set_array(16,top->core1_slice2_coretodc_std_data,value);
  top->c1_s2_coretodctlb_ld_ckpid        = value < 0? rand() : value ;
  top->c1_s2_coretodctlb_ld_coreid       = value < 0? rand() : value ;
  top->c1_s2_coretodctlb_ld_lop          = value < 0? rand() : value ;
  top->c1_s2_coretodctlb_ld_pnr          = value < 0? rand() : value ;
  top->c1_s2_coretodctlb_ld_laddr        = value < 0? rand() : value ;
  top->c1_s2_coretodctlb_ld_imm          = value < 0? rand() : value ;
  top->c1_s2_coretodctlb_ld_sptbr        = value < 0? rand() : value ;
  top->c1_s2_coretodctlb_ld_user         = value < 0? rand() : value ;
  top->c1_s2_coretodctlb_st_ckpid        = value < 0? rand() : value ;
  top->c1_s2_coretodctlb_st_coreid       = value < 0? rand() : value ;
  top->c1_s2_coretodctlb_st_mop          = value < 0? rand() : value ;
  top->c1_s2_coretodctlb_st_pnr          = value < 0? rand() : value ;
  top->c1_s2_coretodctlb_st_laddr        = value < 0? rand() : value ;
  top->c1_s2_coretodctlb_st_imm          = value < 0? rand() : value ;
  top->c1_s2_coretodctlb_st_sptbr        = value < 0? rand() : value ;
  top->c1_s2_coretodctlb_st_user         = value < 0? rand() : value ;
  top->core1_slice3_coretodc_ld_ckpid    = value < 0? rand() : value ;
  top->core1_slice3_coretodc_ld_coreid   = value < 0? rand() : value ;
  top->core1_slice3_coretodc_ld_lop      = value < 0? rand() : value ;
  top->core1_slice3_coretodc_ld_pnr      = value < 0? rand() : value ;
  top->core1_slice3_coretodc_ld_pcsign   = value < 0? rand() : value ;
  top->core1_slice3_coretodc_ld_poffset  = value < 0? rand() : value ;
  top->core1_slice3_coretodc_ld_imm      = value < 0? rand() : value ;
  top->core1_slice3_coretodc_std_ckpid   = value < 0? rand() : value ;
  top->core1_slice3_coretodc_std_coreid  = value < 0? rand() : value ;
  top->core1_slice3_coretodc_std_mop     = value < 0? rand() : value ;
  top->core1_slice3_coretodc_std_pnr     = value < 0? rand() : value ;
  top->core1_slice3_coretodc_std_pcsign  = value < 0? rand() : value ;
  top->core1_slice3_coretodc_std_poffset = value < 0? rand() : value ;
  top->core1_slice3_coretodc_std_imm     = value < 0? rand() : value ;
  set_array(16,top->core1_slice3_coretodc_std_data,value);
  top->c1_s3_coretodctlb_ld_ckpid        = value < 0? rand() : value ;
  top->c1_s3_coretodctlb_ld_coreid       = value < 0? rand() : value ;
  top->c1_s3_coretodctlb_ld_lop          = value < 0? rand() : value ;
  top->c1_s3_coretodctlb_ld_pnr          = value < 0? rand() : value ;
  top->c1_s3_coretodctlb_ld_laddr        = value < 0? rand() : value ;
  top->c1_s3_coretodctlb_ld_imm          = value < 0? rand() : value ;
  top->c1_s3_coretodctlb_ld_sptbr        = value < 0? rand() : value ;
  top->c1_s3_coretodctlb_ld_user         = value < 0? rand() : value ;
  top->c1_s3_coretodctlb_st_ckpid        = value < 0? rand() : value ;
  top->c1_s3_coretodctlb_st_coreid       = value < 0? rand() : value ;
  top->c1_s3_coretodctlb_st_mop          = value < 0? rand() : value ;
  top->c1_s3_coretodctlb_st_pnr          = value < 0? rand() : value ;
  top->c1_s3_coretodctlb_st_laddr        = value < 0? rand() : value ;
  top->c1_s3_coretodctlb_st_imm          = value < 0? rand() : value ;
  top->c1_s3_coretodctlb_st_sptbr        = value < 0? rand() : value ;
  top->c1_s3_coretodctlb_st_user         = value < 0? rand() : value ;
#endif
  top->core1_pfgtopfe_op_delta           = value < 0? rand() : value ;
  top->core1_pfgtopfe_op_w1              = value < 0? rand() : value ;
  top->core1_pfgtopfe_op_w2              = value < 0? rand() : value ;
  top->core1_pfgtopfe_op_pcsign          = value < 0? rand() : value ;
  top->core1_pfgtopfe_op_laddr           = value < 0? rand() : value ;
  top->core1_pfgtopfe_op_sptbr           = value < 0? rand() : value ;
  top->dr0_memtodr_ack_drid              = value < 0? rand() : value ;
  top->dr0_memtodr_ack_nid               = value < 0? rand() : value ;
  top->dr0_memtodr_ack_paddr             = value < 0? rand() : value ;
  top->dr0_memtodr_ack_ack               = value < 0? rand() : value ;
  set_array(16,top->dr0_memtodr_ack_line,value);
  top->dr1_memtodr_ack_drid              = value < 0? rand() : value ;
  top->dr1_memtodr_ack_nid               = value < 0? rand() : value ;
  top->dr1_memtodr_ack_paddr             = value < 0? rand() : value ;
  top->dr1_memtodr_ack_ack               = value < 0? rand() : value ;
  set_array(16,top->dr1_memtodr_ack_line,value);
}


void enqueue_resp_packet(int addr, int coreid, Vintegration_2core2dr *top) {
  MemResp resp;
  resp.drid                = 0;
  resp.nid                 = coreid & mask(sizeof(top->dr0_memtodr_ack_nid));
  resp.paddr               = addr & mask(sizeof(top->dr0_memtodr_ack_paddr));
  resp.ack                 = 0;
  set_array(16,resp.line, -1);
 
  dr0_resps.push_front(resp); 
}

void try_recv_packet(Vintegration_2core2dr *top) {

  if (top->dr0_drtomem_req_valid && dr0_reqs.empty()) {
    printf("ERROR: unexpected result on directory 0, paddr = %d\n",top->dr0_drtomem_req_paddr);
    error_found(top);
    return;
  }

  if (top->dr1_drtomem_req_valid && dr1_reqs.empty()) {
    printf("ERROR: unexpected result on directory 1, paddr = %d\n",top->dr1_drtomem_req_paddr);
    error_found(top);
    return;
  }

  if (top->core0_slice0_dctocore_ld_valid && c0s0_resp_queue.empty()) {
    printf("ERROR: unexpected result on c0s0, poffset %d\n",top->core0_slice0_coretodc_ld_poffset);
    error_found(top);
    return;
  }

  if (top->core0_slice1_dctocore_ld_valid && c0s1_resp_queue.empty()) {
    printf("ERROR: unexpected result on c0s1, poffset %d\n",top->core0_slice1_coretodc_ld_poffset);
    error_found(top);
    return;
  }

  if (top->core0_slice2_dctocore_ld_valid && c0s2_resp_queue.empty()) {
    printf("ERROR: unexpected result on c0s2, poffset %d\n",top->core0_slice2_coretodc_ld_poffset);
    error_found(top);
    return;
  }

  if (top->core0_slice3_dctocore_ld_valid && c0s3_resp_queue.empty()) {
    printf("ERROR: unexpected result on c0s3, poffset %d\n",top->core0_slice3_coretodc_ld_poffset);
    error_found(top);
    return;
  }

  if (top->dr0_drtomem_req_valid) {
#ifdef DEBUG_TRACE
    printf("@%lld paddr=%d\n",global_time, top->dr0_drtomem_req_paddr);
#endif
    MemReq o = dr0_reqs.back();
    if (top->dr0_drtomem_req_paddr != o.paddr) {
      printf("ERROR: expected %X but paddr is %X\n",o.paddr,top->dr0_drtomem_req_paddr);
      error_found(top);
    } else {
      //answer request

      //FIXME: need to get the proper id to send
      enqueue_resp_packet(o.paddr, 0, top);
    }

    dr0_reqs.pop_back();
    ntests++;
  }

  if (top->dr1_drtomem_req_valid) {
#ifdef DEBUG_TRACE
    printf("@%lld paddr=%d\n",global_time, top->dr1_drtomem_req_paddr);
#endif
    MemReq o = dr1_reqs.back();
    if (top->dr1_drtomem_req_paddr != o.paddr) {
      printf("ERROR: expected %X but paddr is %X\n",o.paddr,top->dr1_drtomem_req_paddr);
      error_found(top);
    } else {
      //answer request

      //FIXME: need to get the proper id to send
      enqueue_resp_packet(o.paddr, 0, top);
    }

    dr1_reqs.pop_back();
    ntests++;
  }

  // FIXME copy this code for each slice
  if(top->core0_slice0_dctocore_ld_valid) {
    DCResp resp = c0s0_resp_queue.back();
    if(top->core0_slice0_coretodc_ld_coreid != resp.coreid && top->core0_slice0_dctocore_ld_fault != resp.fault &&
        top->core0_slice0_dctocore_ld_data == resp.data) {
      printf("ERROR: expected %X but data[0] is %X\n",resp.data[0],top->core0_slice0_dctocore_ld_data[0]);
      error_found(top);
    }
    c0s0_resp_queue.pop_back();
    ntests++;
  }
}

void try_send_packet(Vintegration_2core2dr *top) {

  // zero out handshakes, assign randoms to inputs
  //set_handshake(top, 0);
  set_ports(top, -1);

  // FIXME: set retries every now and then


  // SEND DCACHE REQUEST
  // When sending a Dcache request, we also need to send a TLB request
  //
  if(!top->core0_slice0_coretodc_ld_retry && !top->c0_s0_coretodctlb_ld_retry) {
    if (!c0s0_ld_req_queue.empty()) { 

      DCacheLDReq c0s0_req = c0s0_ld_req_queue.back();
      if (c0s0_req.coreid == 0 && !top->core0_slice0_coretodc_ld_retry) {
        //dcache req
        top->core0_slice0_coretodc_ld_ckpid   = c0s0_req.ckpid;
        top->core0_slice0_coretodc_ld_coreid  = c0s0_req.coreid;
        top->core0_slice0_coretodc_ld_lop     = c0s0_req.lop;
        top->core0_slice0_coretodc_ld_pnr     = c0s0_req.pnr;
        top->core0_slice0_coretodc_ld_pcsign  = c0s0_req.pcsign;
        top->core0_slice0_coretodc_ld_poffset = c0s0_req.poffset;
        top->core0_slice0_coretodc_ld_imm     = c0s0_req.imm;

        top->core0_slice0_coretodc_ld_valid   = 1;

        //dctlb req
        top->c0_s0_coretodctlb_ld_ckpid     = c0s0_req.ckpid;
        top->c0_s0_coretodctlb_ld_coreid    = c0s0_req.coreid;
        top->c0_s0_coretodctlb_ld_lop       = c0s0_req.lop;
        top->c0_s0_coretodctlb_ld_pnr       = c0s0_req.pnr;
        top->c0_s0_coretodctlb_ld_laddr     = c0s0_req.laddr;
        top->c0_s0_coretodctlb_ld_imm       = c0s0_req.imm;
        top->c0_s0_coretodctlb_ld_sptbr     = 0;
        top->c0_s0_coretodctlb_ld_user      = 1;

        top->c0_s0_coretodctlb_ld_valid     = 1;


        c0s0_ld_req_queue.pop_back();
#ifdef DEBUG_TRACE
        printf("@%lld c0s0 ld coreid=%d, ckpid=%d, offset=%d, imm=%d, lop=%d, pnr=%d, pcsign=%d\n",42,c0s0_req.coreid, c0s0_req.ckpid, c0s0_req.poffset, c0s0_req.imm, c0s0_req.lop, c0s0_req.pnr, c0s0_req.pcsign);
#endif
      }
    } else {
      top->core0_slice0_coretodc_ld_valid = 0;
      top->c0_s0_coretodctlb_ld_valid     = 0;
    }
  }


  // SEND MEMORY RESP
  if(!top->dr0_memtodr_ack_retry) {
    if (!dr0_resps.empty()) { 
      MemResp resp               = dr0_resps.back();

      top->dr0_memtodr_ack_drid  = resp.drid;
      top->dr0_memtodr_ack_nid   = resp.nid;
      top->dr0_memtodr_ack_paddr = resp.paddr;
      top->dr0_memtodr_ack_ack   = resp.ack;
      std::memcpy(top->dr0_memtodr_ack_line,resp.line,16);

      top->dr0_memtodr_ack_valid = 1;

#ifdef DEBUG_TRACE
        printf("@%lld dr0 ack drid=%X, nid=%X, paddr=%X\n",46,resp.drid,resp.nid,resp.paddr);
#endif
    } else {
      top->dr0_memtodr_ack_valid = 0;
    }
  }
}



void run_single_core(int coreid) {
  // init top verilog instance;
  Vintegration_2core2dr* top = new Vintegration_2core2dr;

  int t = (int)time(0);
  srand(t);
  printf("My RAND Seed is %d\n",t);

#ifdef TRACE
  // init trace dump
  Verilated::traceEverOn(true);
  tfp = new VerilatedVcdC;

  top->trace(tfp, 99);
  tfp->open("single_core_integration_test.vcd");
#endif

  // initialize simulation inputs;
  top->clk = 1;
  top->reset = 1;

  advance_clock(top,100);  // Long reset to give time to the state machine;
  //-------------------------------------------------------;
  top->reset = 0;

  //for(int niters=0 ; niters < 50; niters++) {
  for(int niters=0 ; niters < 1; niters++) {
    //-------------------------------------------------------;

  /*
#ifdef DEBUG_TRACE
    printf("reset\n");
#endif
    top->reset = 1;

    c0s0_ld_req_queue.clear();
    c0s1_ld_req_queue.clear();
    c0s2_ld_req_queue.clear();
    c0s3_ld_req_queue.clear();
    dr0_reqs.clear();
    dr1_reqs.clear();


    int ncycles= rand() & 0xFF;
    ncycles++; // At least one cycle reset
    for(int i =0;i<ncycles;i++) {
      set_ports(top, -1);
      set_handshake(top,-1);
      advance_clock(top,1);
    }
   */
#ifdef DEBUG_TRACE
    printf("no reset\n");
#endif
    //-------------------------------------------------------
    set_handshake(top, 0);
    top->reset = 0;
    advance_clock(top,1);

    //for(int i =0;i<1024;i++) {
    for(int i =0;i<100;i++) {
      try_send_packet(top);
      advance_half_clock(top);
      try_recv_packet(top);
      advance_half_clock(top);

      // LOAD REQUESTS SLICE 0
      if (((rand() & 0x3)==0) && c0s0_ld_req_queue.size() < 3) {
        DCacheLDReq request;
        request.coreid  = coreid & mask(sizeof(top->core0_slice0_coretodc_ld_coreid));
        request.ckpid   = rand() & mask(sizeof(top->core0_slice0_coretodc_ld_ckpid));
        request.lop     = rand() & mask(sizeof(top->core0_slice0_coretodc_ld_lop));
        request.pnr     = rand() & mask(sizeof(top->core0_slice0_coretodc_ld_pnr));
        request.pcsign  = rand() & mask(sizeof(top->core0_slice0_coretodc_ld_pcsign));

        request.imm     = rand() & mask(sizeof(top->core0_slice0_coretodc_ld_imm));
        request.laddr   = rand() & mask(sizeof(top->c0_s0_coretodctlb_ld_laddr));

        // poffset = laddr[11:0]
        request.poffset = request.laddr & mask(sizeof(top->core0_slice0_coretodc_ld_poffset));

        c0s0_ld_req_queue.push_front(request);

        MemReq m_req;
        m_req.drid  = 0;
        m_req.paddr = (request.laddr >> 12) & mask(sizeof(top->dr0_drtomem_req_paddr));

        //directory choice defined by the 10th bit of paddr
        if((m_req.paddr >> 9) & 0x1 == 1)
          dr1_reqs.push_front(m_req);
        else
          dr0_reqs.push_front(m_req);
      }

      // ST REQUESTS SLICE 0
      if (((rand() & 0x3)==0) && c0s0_st_req_queue.size() < 3) {
        DCacheSTReq request;
        request.coreid  = coreid & mask(sizeof(top->core0_slice0_coretodc_std_coreid));
        request.ckpid   = rand() & mask(sizeof(top->core0_slice0_coretodc_std_ckpid));
        request.mop     = rand() & mask(sizeof(top->core0_slice0_coretodc_std_mop));
        request.pnr     = rand() & mask(sizeof(top->core0_slice0_coretodc_std_pnr));
        request.pcsign  = rand() & mask(sizeof(top->core0_slice0_coretodc_std_pcsign));
        request.data    = rand() & mask(sizeof(top->core0_slice0_coretodc_std_data));

        request.imm     = rand() & mask(sizeof(top->core0_slice0_coretodc_std_imm));
        request.laddr   = rand() & mask(sizeof(top->c0_s0_coretodctlb_st_laddr));

        // poffset = laddr[11:0]
        request.poffset = request.laddr & mask(sizeof(top->core0_slice0_coretodc_ld_poffset));

        //FIXME: stores not implemented in L1 PASSTHROUGH
        //c0s0_ld_req_queue.push_front(request);

        MemReq m_req;
        m_req.drid  = 0;
        m_req.paddr = (request.laddr >> 12) & mask(sizeof(top->dr0_drtomem_req_paddr));

        //directory choice defined by the 10th bit of paddr
        /*
        if((m_req.paddr >> 9) & 0x1 == 1)
          dr1_reqs.push_front(m_req);
        else
          dr0_reqs.push_front(m_req);
        */
      }

      // FIXME: for now, sending random responses through the hierarchy to test
      // passthroughs. Remove when the request paths are working and send data
      // for requested paths
      if (((rand() & 0x3)==0) && dr0_resps.size() < 3) {
        MemResp resp;
        resp.drid                = 0;
        // FIXME: send rand ids?
        resp.nid                 = 0 & mask(sizeof(top->dr0_memtodr_ack_nid));
        resp.paddr               = rand() & mask(sizeof(top->dr0_memtodr_ack_paddr));
        resp.ack                 = 0;
        set_array(16, resp.line, -1);

        dr0_resps.push_front(resp);

        DCResp dc_resp;
        dc_resp.coreid = 0;
        dc_resp.fault  = 0;
        std::memcpy(dc_resp.data, resp.line, 8*sizeof(int));
        //FIXME: need to check what the right queue is
        c0s0_resp_queue.push_front(dc_resp);
      }
    }

    for(int i =0;i<1000;i++) {
      try_recv_packet(top);
      advance_clock(top,1);
    }
  }
  if(!dr1_reqs.empty() || !dr0_reqs.empty() || 
      !c0s0_resp_queue.empty() || !c0s1_resp_queue.empty() || !c0s2_resp_queue.empty() || !c0s3_resp_queue.empty() ) {
    printf("ERROR: expecting outputs but got nothing\n"); 
    error_found(top);
  }
}

int run_all() {
  run_single_core(0);
}

enum TestType {
  SingleCore,
  MultiCore,
  CrossPage
};

int main(int argc, char **argv, char **env) {
  int i;
  int clk;
  Verilated::commandArgs(argc, argv);

  TestType test_case;
  bool all = false;

  if(argc < 1) {
    printf("No test case specified, using default test parameters (all)\n");
    printf("  for a list of available test cases use the --help option\n\n");
    test_case = SingleCore;
  }

  int opt;
  while ((opt = getopt (argc, argv, "smcha")) != -1)
  {
    switch (opt)
    {
      case 's':
        printf ("testcase: single: \n");
        test_case = SingleCore;
        break;
      case 'm':
        printf ("testcase multi \n");
        test_case = MultiCore;
        break;
      case 'c':
        printf ("testcase cross \n");
        test_case = CrossPage;
        break;
      case 'a':
        printf ("testcase all \n");
        all = true;
        break;
      case 'h':
        printf("Usage Vintegration_2core2dr [-s|m|c]\n");
        printf("    -s - Single Core test\n");
        printf("    -m - Multi Core test\n");
        printf("    -c - Cross Page test\n");
        printf("    -a - Run all tests\n");
    }
  }

  if(all) {
    run_all();
  } else {

    switch(test_case) {
      case SingleCore:;
        run_single_core(0);
        break;
      case MultiCore:;
        printf("MultiCore testing not supported yet\n");
        return 1;
      case CrossPage:;
        printf("CrossPage testing not supported yet\n");
        return 1;
      default:;
        printf("Unrecognized test type\n");
        return 1;
    }
  }

  printf("performed %lld test in %lld cycles\n",ntests,(long long)global_time/2);
  sim_finish(true);
  return 0;
}

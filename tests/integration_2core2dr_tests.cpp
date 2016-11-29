
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
}

struct MemReq {
  int drid;
  int cmd;
  int paddr;
}

std::list<DCacheLDReq> dcache_req;
std::list<MemReq> mem_req;

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

void error_found(Vjoin_fadd *top) {
  advance_clock(top,4);
  sim_finish(false);
}

void try_send_packet(Vintegration_2core2dr *top) {

  // no retries for now
  //top->sumRetry = (rand()&0xF)==0; // randomly, one every 8 packets

  // SEND DCACHE REQUEST
  if (!top->inp_aRetry) {
    if (inpa_list.empty() || (rand() & 0x3)) { // Once every 4
      top->inp_a = rand();
      top->inp_aValid = 0;
    } else{
      if (inpa_list.empty()) {
        fprintf(stderr,"ERROR: Internal error, could not be empty inpa\n");
        error_found(top);        
      }
      InputPacketA inp = inpa_list.back();
      top->inp_a = inp.inp_a;
      top->inp_aValid = 1;
      inpa_list.pop_back();
#ifdef DEBUG_TRACE
      printf("@%lld inp_a=%d\n",global_time, inp.inp_a);
#endif
    }
  }
}

void set_handshake(Vintegration_2core2dr* top, int value) {

  top->core0_coretoic_pc_valid             = value < 0? rand() & 0x1 : value & 0x1;
  top->core0_coretoic_pc_retry             =  value < 0? rand() & 0x1 : value & 0x1;
  top->core0_ictocore_valid                =  value < 0? rand() & 0x1 : value & 0x1;
  top->core0_ictocore_retry                =  value < 0? rand() & 0x1 : value & 0x1;
  top->core0_slice0_coretodc_ld_valid      =  value < 0? rand() & 0x1 : value & 0x1;
  top->core0_slice0_coretodc_ld_retry      =  value < 0? rand() & 0x1 : value & 0x1;
  top->core0_slice0_dctocore_ld_valid      =  value < 0? rand() & 0x1 : value & 0x1;
  top->core0_slice0_dctocore_ld_retry      =  value < 0? rand() & 0x1 : value & 0x1;
  top->core0_slice0_coretodc_std_valid     =  value < 0? rand() & 0x1 : value & 0x1;
  top->core0_slice0_coretodc_std_retry     =  value < 0? rand() & 0x1 : value & 0x1;
  top->core0_slice0_dctocore_std_ack_valid =  value < 0? rand() & 0x1 : value & 0x1;
  top->core0_slice0_dctocore_std_ack_retry =  value < 0? rand() & 0x1 : value & 0x1;

	top->c0_s0_coretodctlb_ld_valid          =  value < 0? rand() & 0x1 : value & 0x1;
	top->c0_s0_coretodctlb_st_valid          =  value < 0? rand() & 0x1 : value & 0x1;
	top->core0_slice1_coretodc_ld_valid      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core0_slice1_dctocore_ld_valid      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core0_slice1_coretodc_std_valid     =  value < 0? rand() & 0x1 : value & 0x1;
	top->core0_slice1_dctocore_std_ack_valid =  value < 0? rand() & 0x1 : value & 0x1;
	top->c0_s1_coretodctlb_ld_valid          =  value < 0? rand() & 0x1 : value & 0x1;
	top->c0_s1_coretodctlb_st_valid          =  value < 0? rand() & 0x1 : value & 0x1;

	top->c0_s0_coretodctlb_ld_retry          =  value < 0? rand() & 0x1 : value & 0x1;
	top->c0_s0_coretodctlb_st_retry          =  value < 0? rand() & 0x1 : value & 0x1;
	top->core0_slice1_coretodc_ld_retry      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core0_slice1_dctocore_ld_retry      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core0_slice1_coretodc_std_retry     =  value < 0? rand() & 0x1 : value & 0x1;
	top->core0_slice1_dctocore_std_ack_retry =  value < 0? rand() & 0x1 : value & 0x1;
	top->c0_s1_coretodctlb_ld_retry          =  value < 0? rand() & 0x1 : value & 0x1;
	top->c0_s1_coretodctlb_st_retry          =  value < 0? rand() & 0x1 : value & 0x1;

#ifdef SC_4PIPE
	top->core0_slice2_coretodc_ld_retry      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core0_slice2_dctocore_ld_retry      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core0_slice2_coretodc_std_retry     =  value < 0? rand() & 0x1 : value & 0x1;
	top->core0_slice2_dctocore_std_ack_retry =  value < 0? rand() & 0x1 : value & 0x1;
	top->c0_s2_coretodctlb_ld_retry          =  value < 0? rand() & 0x1 : value & 0x1;
	top->c0_s2_coretodctlb_st_retry          =  value < 0? rand() & 0x1 : value & 0x1;
	top->core0_slice3_coretodc_ld_retry      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core0_slice3_dctocore_ld_retry      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core0_slice3_coretodc_std_retry     =  value < 0? rand() & 0x1 : value & 0x1;
	top->core0_slice3_dctocore_std_ack_retry =  value < 0? rand() & 0x1 : value & 0x1;
	top->c0_s3_coretodctlb_ld_retry          =  value < 0? rand() & 0x1 : value & 0x1;
	top->c0_s3_coretodctlb_st_retry          =  value < 0? rand() & 0x1 : value & 0x1;
	top->core0_slice2_coretodc_ld_valid      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core0_slice2_dctocore_ld_valid      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core0_slice2_coretodc_std_valid     =  value < 0? rand() & 0x1 : value & 0x1;
	top->core0_slice2_dctocore_std_ack_valid =  value < 0? rand() & 0x1 : value & 0x1;
	top->c0_s2_coretodctlb_ld_valid          =  value < 0? rand() & 0x1 : value & 0x1;
	top->c0_s2_coretodctlb_st_valid          =  value < 0? rand() & 0x1 : value & 0x1;
	top->core0_slice3_coretodc_ld_valid      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core0_slice3_dctocore_ld_valid      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core0_slice3_coretodc_std_valid     =  value < 0? rand() & 0x1 : value & 0x1;
	top->core0_slice3_dctocore_std_ack_valid =  value < 0? rand() & 0x1 : value & 0x1;
	top->c0_s3_coretodctlb_ld_valid          =  value < 0? rand() & 0x1 : value & 0x1;
	top->c0_s3_coretodctlb_st_valid          =  value < 0? rand() & 0x1 : value & 0x1;
#endif

	top->core0_pfgtopfe_op_valid             = value < 0? rand() & 0x1 : value & 0x1;
	top->core1_coretoic_pc_valid             =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_ictocore_valid                =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice0_coretodc_ld_valid      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice0_dctocore_ld_valid      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice0_coretodc_std_valid     =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice0_dctocore_std_ack_valid =  value < 0? rand() & 0x1 : value & 0x1;
	top->c1_s0_coretodctlb_ld_valid          =  value < 0? rand() & 0x1 : value & 0x1;
	top->c1_s0_coretodctlb_st_valid          =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice1_coretodc_ld_valid      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice1_dctocore_ld_valid      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice1_coretodc_std_valid     =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice1_dctocore_std_ack_valid =  value < 0? rand() & 0x1 : value & 0x1;
	top->c1_s1_coretodctlb_ld_valid          =  value < 0? rand() & 0x1 : value & 0x1;
	top->c1_s1_coretodctlb_st_valid          =  value < 0? rand() & 0x1 : value & 0x1;
	top->core0_pfgtopfe_op_retry             =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_coretoic_pc_retry             =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_ictocore_retry                =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice0_coretodc_ld_retry      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice0_dctocore_ld_retry      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice0_coretodc_std_retry     =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice0_dctocore_std_ack_retry =  value < 0? rand() & 0x1 : value & 0x1;
	top->c1_s0_coretodctlb_ld_retry          =  value < 0? rand() & 0x1 : value & 0x1;
	top->c1_s0_coretodctlb_st_retry          =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice1_coretodc_ld_retry      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice1_dctocore_ld_retry      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice1_coretodc_std_retry     =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice1_dctocore_std_ack_retry =  value < 0? rand() & 0x1 : value & 0x1;
	top->c1_s1_coretodctlb_ld_retry          =  value < 0? rand() & 0x1 : value & 0x1;
	top->c1_s1_coretodctlb_st_retry          =  value < 0? rand() & 0x1 : value & 0x1;
                                             

#ifdef SC_4PIPE
	top->core1_slice2_coretodc_ld_retry      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice2_dctocore_ld_retry      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice2_coretodc_std_retry     =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice2_dctocore_std_ack_retry =  value < 0? rand() & 0x1 : value & 0x1;
	top->c1_s2_coretodctlb_ld_retry          =  value < 0? rand() & 0x1 : value & 0x1;
	top->c1_s2_coretodctlb_st_retry          =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice3_coretodc_ld_retry      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice3_dctocore_ld_retry      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice3_coretodc_std_retry     =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice3_dctocore_std_ack_retry =  value < 0? rand() & 0x1 : value & 0x1;
	top->c1_s3_coretodctlb_ld_retry          =  value < 0? rand() & 0x1 : value & 0x1;
	top->c1_s3_coretodctlb_st_retry          =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice2_coretodc_ld_valid      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice2_dctocore_ld_valid      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice2_coretodc_std_valid     =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice2_dctocore_std_ack_valid =  value < 0? rand() & 0x1 : value & 0x1;
	top->c1_s2_coretodctlb_ld_valid          =  value < 0? rand() & 0x1 : value & 0x1;
	top->c1_s2_coretodctlb_st_valid          =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice3_coretodc_ld_valid      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice3_dctocore_ld_valid      =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice3_coretodc_std_valid     =  value < 0? rand() & 0x1 : value & 0x1;
	top->core1_slice3_dctocore_std_ack_valid =  value < 0? rand() & 0x1 : value & 0x1;
	top->c1_s3_coretodctlb_ld_valid          =  value < 0? rand() & 0x1 : value & 0x1;
	top->c1_s3_coretodctlb_st_valid          =  value < 0? rand() & 0x1 : value & 0x1;
#endif

	top->core1_pfgtopfe_op_valid =  value < 0? rand() & 0x1 : value & 0x1;
	top->dr0_drtomem_req_valid   =   value < 0? rand() & 0x1 : value & 0x1;
	top->dr0_memtodr_ack_valid   =   value < 0? rand() & 0x1 : value & 0x1;
	top->dr0_drtomem_wb_valid    =   value < 0? rand() & 0x1 : value & 0x1;
	top->dr0_drtomem_pfreq_valid =   value < 0? rand() & 0x1 : value & 0x1;
	top->dr1_drtomem_req_valid   =   value < 0? rand() & 0x1 : value & 0x1;
	top->dr1_memtodr_ack_valid   =   value < 0? rand() & 0x1 : value & 0x1;
	top->dr1_drtomem_wb_valid    =   value < 0? rand() & 0x1 : value & 0x1;
	top->dr1_drtomem_pfreq_valid =   value < 0? rand() & 0x1 : value & 0x1;
	top->core1_pfgtopfe_op_retry =   value < 0? rand() & 0x1 : value & 0x1;
	top->dr0_drtomem_req_retry   =   value < 0? rand() & 0x1 : value & 0x1;
	top->dr0_memtodr_ack_retry   =   value < 0? rand() & 0x1 : value & 0x1;
	top->dr0_drtomem_wb_retry    =   value < 0? rand() & 0x1 : value & 0x1;
	top->dr0_drtomem_pfreq_retry =   value < 0? rand() & 0x1 : value & 0x1;
	top->dr1_drtomem_req_retry   =   value < 0? rand() & 0x1 : value & 0x1;
	top->dr1_memtodr_ack_retry   =   value < 0? rand() & 0x1 : value & 0x1;
	top->dr1_drtomem_wb_retry    =   value < 0? rand() & 0x1 : value & 0x1;
	top->dr1_drtomem_pfreq_retry =   value < 0? rand() & 0x1 : value & 0x1;
                                   
}

void set_ports(Vintegration_2core2dr* top, int value) {
 top->core0_coretoic_pc                            value < 0? rand() : value ; //   I_coretoic_pc_type     
 top->core0_ictocore_coreid                        value < 0? rand() : value ; //  CORE_reqid_type        
 top->core0_ictocore_fault                         value < 0? rand() : value ; //  SC_fault_type          
 top->core0_ictocore_data                          value < 0? rand() : value ; //  IC_fwidth_type         
 top->core0_slice0_coretodc_ld_ckpid               value < 0? rand() : value ; //  DC_ckpid_type          
 top->core0_slice0_coretodc_ld_coreid              value < 0? rand() : value ; //  CORE_reqid_type        
 top->core0_slice0_coretodc_ld_lop                 value < 0? rand() : value ; //  CORE_lop_type          
 top->core0_slice0_coretodc_ld_pnr                 value < 0? rand() : value ; //  logic                  
 top->core0_slice0_coretodc_ld_pcsign              value < 0? rand() : value ; //  SC_pcsign_type         
 top->core0_slice0_coretodc_ld_poffset             value < 0? rand() : value ; //  SC_poffset_type        
 top->core0_slice0_coretodc_ld_imm                 value < 0? rand() : value ; //  SC_imm_type            
 top->core0_slice0_dctocore_ld_coreid              value < 0? rand() : value ; //  CORE_reqid_type        
 top->core0_slice0_dctocore_ld_fault               value < 0? rand() : value ; //  SC_fault_type          
 top->core0_slice0_dctocore_ld_data                value < 0? rand() : value ; //  SC_line_type           
 top->core0_slice0_coretodc_std_ckpid              value < 0? rand() : value ; //  DC_ckpid_type          
 top->core0_slice0_coretodc_std_coreid             value < 0? rand() : value ; //  CORE_reqid_type        
 top->core0_slice0_coretodc_std_mop                value < 0? rand() : value ; //  CORE_mop_type          
 top->core0_slice0_coretodc_std_pnr                value < 0? rand() : value ; //  logic                  
 top->core0_slice0_coretodc_std_pcsign             value < 0? rand() : value ; //  SC_pcsign_type         
 top->core0_slice0_coretodc_std_poffset            value < 0? rand() : value ; //  SC_poffset_type        
 top->core0_slice0_coretodc_std_imm                value < 0? rand() : value ; //  SC_imm_type            
 top->core0_slice0_coretodc_std_data               value < 0? rand() : value ; //  SC_line_type           
 top->core0_slice0_dctocore_std_ack_fault          value < 0? rand() : value ; //  SC_fault_type          
 top->core0_slice0_dctocore_std_ack_coreid         value < 0? rand() : value ; //  CORE_reqid_type        
 top->c0_s0_coretodctlb_ld                         value < 0? rand() : value ; //  I_coretodctlb_ld_type  
 top->c0_s0_coretodctlb_st                         value < 0? rand() : value ; //  I_coretodctlb_st_type  
 top->core0_slice1_coretodc_ld_ckpid               value < 0? rand() : value ; //  DC_ckpid_type          
 top->core0_slice1_coretodc_ld_coreid              value < 0? rand() : value ; //  CORE_reqid_type        
 top->core0_slice1_coretodc_ld_lop                 value < 0? rand() : value ; //  CORE_lop_type          
 top->core0_slice1_coretodc_ld_pnr                 value < 0? rand() : value ; //  logic                  
 top->core0_slice1_coretodc_ld_pcsign              value < 0? rand() : value ; //  SC_pcsign_type         
 top->core0_slice1_coretodc_ld_poffset             value < 0? rand() : value ; //  SC_poffset_type        
 top->core0_slice1_coretodc_ld_imm                 value < 0? rand() : value ; //  SC_imm_type            
 top->core0_slice1_dctocore_ld_coreid              value < 0? rand() : value ; //  CORE_reqid_type        
 top->core0_slice1_dctocore_ld_fault               value < 0? rand() : value ; //  SC_fault_type          
 top->core0_slice1_dctocore_ld_data                value < 0? rand() : value ; //  SC_line_type           
 top->core0_slice1_coretodc_std_ckpid              value < 0? rand() : value ; //  DC_ckpid_type          
 top->core0_slice1_coretodc_std_coreid             value < 0? rand() : value ; //  CORE_reqid_type        
 top->core0_slice1_coretodc_std_mop                value < 0? rand() : value ; //  CORE_mop_type          
 top->core0_slice1_coretodc_std_pnr                value < 0? rand() : value ; //  logic                  
 top->core0_slice1_coretodc_std_pcsign             value < 0? rand() : value ; //  SC_pcsign_type         
 top->core0_slice1_coretodc_std_poffset            value < 0? rand() : value ; //  SC_poffset_type        
 top->core0_slice1_coretodc_std_imm                value < 0? rand() : value ; //  SC_imm_type            
 top->core0_slice1_coretodc_std_data               value < 0? rand() : value ; //  SC_line_type           
 top->core0_slice1_dctocore_std_ack_fault          value < 0? rand() : value ; //  SC_fault_type          
 top->core0_slice1_dctocore_std_ack_coreid         value < 0? rand() : value ; //  CORE_reqid_type        
 top->c0_s1_coretodctlb_ld                         value < 0? rand() : value ; //  I_coretodctlb_ld_type  
 top->c0_s1_coretodctlb_st                         value < 0? rand() : value ; //  I_coretodctlb_st_type  

#ifdef   SC_4PIPE
 top->core0_slice2_coretodc_ld_ckpid               value < 0? rand() : value ; //   DC_ckpid_type          
 top->core0_slice2_coretodc_ld_coreid              value < 0? rand() : value ; //  CORE_reqid_type        
 top->core0_slice2_coretodc_ld_lop                 value < 0? rand() : value ; //  CORE_lop_type          
 top->core0_slice2_coretodc_ld_pnr                 value < 0? rand() : value ; //  logic                  
 top->core0_slice2_coretodc_ld_pcsign              value < 0? rand() : value ; //  SC_pcsign_type         
 top->core0_slice2_coretodc_ld_poffset             value < 0? rand() : value ; //  SC_poffset_type        
 top->core0_slice2_coretodc_ld_imm                 value < 0? rand() : value ; //  SC_imm_type            
 top->core0_slice2_dctocore_ld_coreid              value < 0? rand() : value ; //  CORE_reqid_type        
 top->core0_slice2_dctocore_ld_fault               value < 0? rand() : value ; //  SC_fault_type          
 top->core0_slice2_dctocore_ld_data                value < 0? rand() : value ; //  SC_line_type           
 top->core0_slice2_coretodc_std_ckpid              value < 0? rand() : value ; //  DC_ckpid_type          
 top->core0_slice2_coretodc_std_coreid             value < 0? rand() : value ; //  CORE_reqid_type        
 top->core0_slice2_coretodc_std_mop                value < 0? rand() : value ; //  CORE_mop_type          
 top->core0_slice2_coretodc_std_pnr                value < 0? rand() : value ; //  logic                  
 top->core0_slice2_coretodc_std_pcsign             value < 0? rand() : value ; //  SC_pcsign_type         
 top->core0_slice2_coretodc_std_poffset            value < 0? rand() : value ; //  SC_poffset_type        
 top->core0_slice2_coretodc_std_imm                value < 0? rand() : value ; //  SC_imm_type            
 top->core0_slice2_coretodc_std_data               value < 0? rand() : value ; //  SC_line_type           
 top->core0_slice2_dctocore_std_ack_fault          value < 0? rand() : value ; //  SC_fault_type          
 top->core0_slice2_dctocore_std_ack_coreid         value < 0? rand() : value ; //  CORE_reqid_type        
 top->c0_s2_coretodctlb_ld                         value < 0? rand() : value ; //  I_coretodctlb_ld_type  
 top->c0_s2_coretodctlb_st                         value < 0? rand() : value ; //  I_coretodctlb_st_type  
 top->core0_slice3_coretodc_ld_ckpid               value < 0? rand() : value ; //  DC_ckpid_type          
 top->core0_slice3_coretodc_ld_coreid              value < 0? rand() : value ; //  CORE_reqid_type        
 top->core0_slice3_coretodc_ld_lop                 value < 0? rand() : value ; //  CORE_lop_type          
 top->core0_slice3_coretodc_ld_pnr                 value < 0? rand() : value ; //  logic                  
 top->core0_slice3_coretodc_ld_pcsign              value < 0? rand() : value ; //  SC_pcsign_type         
 top->core0_slice3_coretodc_ld_poffset             value < 0? rand() : value ; //  SC_poffset_type        
 top->core0_slice3_coretodc_ld_imm                 value < 0? rand() : value ; //  SC_imm_type            
 top->core0_slice3_dctocore_ld_coreid              value < 0? rand() : value ; //  CORE_reqid_type        
 top->core0_slice3_dctocore_ld_fault               value < 0? rand() : value ; //  SC_fault_type          
 top->core0_slice3_dctocore_ld_data                value < 0? rand() : value ; //  SC_line_type           
 top->core0_slice3_coretodc_std_ckpid              value < 0? rand() : value ; //  DC_ckpid_type          
 top->core0_slice3_coretodc_std_coreid             value < 0? rand() : value ; //  CORE_reqid_type        
 top->core0_slice3_coretodc_std_mop                value < 0? rand() : value ; //  CORE_mop_type          
 top->core0_slice3_coretodc_std_pnr                value < 0? rand() : value ; //  logic                  
 top->core0_slice3_coretodc_std_pcsign             value < 0? rand() : value ; //  SC_pcsign_type         
 top->core0_slice3_coretodc_std_poffset            value < 0? rand() : value ; //  SC_poffset_type        
 top->core0_slice3_coretodc_std_imm                value < 0? rand() : value ; //  SC_imm_type            
 top->core0_slice3_coretodc_std_data               value < 0? rand() : value ; //  SC_line_type           
 top->core0_slice3_dctocore_std_ack_fault          value < 0? rand() : value ; //  SC_fault_type          
 top->core0_slice3_dctocore_std_ack_coreid         value < 0? rand() : value ; //  CORE_reqid_type        
 top->c0_s3_coretodctlb_ld                         value < 0? rand() : value ; //  I_coretodctlb_ld_type  
 top->c0_s3_coretodctlb_st                         value < 0? rand() : value ; //  I_coretodctlb_st_type  
#endif                                              
                                                    
 top->core0_pfgtopfe_op_delta                      value < 0? rand() : value ; //    PF_delta_type          
 top->core0_pfgtopfe_op_w1                         value < 0? rand() : value ; //   PF_weigth_type         
 top->core0_pfgtopfe_op_w2                         value < 0? rand() : value ; //   PF_weigth_type         
 top->core0_pfgtopfe_op_pcsign                     value < 0? rand() : value ; //   SC_pcsign_type         
 top->core0_pfgtopfe_op_laddr                      value < 0? rand() : value ; //   SC_laddr_type          
 top->core0_pfgtopfe_op_sptbr                      value < 0? rand() : value ; //   SC_sptbr_type          
 top->core1_coretoic_pc                            value < 0? rand() : value ; //   I_coretoic_pc_type     
 top->core1_ictocore_coreid                        value < 0? rand() : value ; //   CORE_reqid_type        
 top->core1_ictocore_fault                         value < 0? rand() : value ; //   SC_fault_type          
 top->core1_ictocore_data                          value < 0? rand() : value ; //   IC_fwidth_type         
 top->core1_slice0_coretodc_ld_ckpid               value < 0? rand() : value ; //   DC_ckpid_type          
 top->core1_slice0_coretodc_ld_coreid              value < 0? rand() : value ; //   CORE_reqid_type        
 top->core1_slice0_coretodc_ld_lop                 value < 0? rand() : value ; //   CORE_lop_type          
 top->core1_slice0_coretodc_ld_pnr                 value < 0? rand() : value ; //   logic                  
 top->core1_slice0_coretodc_ld_pcsign              value < 0? rand() : value ; //   SC_pcsign_type         
 top->core1_slice0_coretodc_ld_poffset             value < 0? rand() : value ; //   SC_poffset_type        
 top->core1_slice0_coretodc_ld_imm                 value < 0? rand() : value ; //   SC_imm_type            
 top->core1_slice0_dctocore_ld_coreid              value < 0? rand() : value ; //   CORE_reqid_type        
 top->core1_slice0_dctocore_ld_fault               value < 0? rand() : value ; //   SC_fault_type          
 top->core1_slice0_dctocore_ld_data                value < 0? rand() : value ; //   SC_line_type           
 top->core1_slice0_coretodc_std_ckpid              value < 0? rand() : value ; //   DC_ckpid_type          
 top->core1_slice0_coretodc_std_coreid             value < 0? rand() : value ; //   CORE_reqid_type        
 top->core1_slice0_coretodc_std_mop                value < 0? rand() : value ; //   CORE_mop_type          
 top->core1_slice0_coretodc_std_pnr                value < 0? rand() : value ; //   logic                  
 top->core1_slice0_coretodc_std_pcsign             value < 0? rand() : value ; //   SC_pcsign_type         
 top->core1_slice0_coretodc_std_poffset            value < 0? rand() : value ; //   SC_poffset_type        
 top->core1_slice0_coretodc_std_imm                value < 0? rand() : value ; //   SC_imm_type            
 top->core1_slice0_coretodc_std_data               value < 0? rand() : value ; //   SC_line_type           
 top->core1_slice0_dctocore_std_ack_fault          value < 0? rand() : value ; //   SC_fault_type          
 top->core1_slice0_dctocore_std_ack_coreid         value < 0? rand() : value ; //   CORE_reqid_type        
 top->c1_s0_coretodctlb_ld                         value < 0? rand() : value ; //   I_coretodctlb_ld_type  
 top->c1_s0_coretodctlb_st                         value < 0? rand() : value ; //   I_coretodctlb_st_type  
 top->core1_slice1_coretodc_ld_ckpid               value < 0? rand() : value ; //   DC_ckpid_type          
 top->core1_slice1_coretodc_ld_coreid              value < 0? rand() : value ; //   CORE_reqid_type        
 top->core1_slice1_coretodc_ld_lop                 value < 0? rand() : value ; //   CORE_lop_type          
 top->core1_slice1_coretodc_ld_pnr                 value < 0? rand() : value ; //   logic                  
 top->core1_slice1_coretodc_ld_pcsign              value < 0? rand() : value ; //   SC_pcsign_type         
 top->core1_slice1_coretodc_ld_poffset             value < 0? rand() : value ; //   SC_poffset_type        
 top->core1_slice1_coretodc_ld_imm                 value < 0? rand() : value ; //   SC_imm_type            
 top->core1_slice1_dctocore_ld_coreid              value < 0? rand() : value ; //   CORE_reqid_type        
 top->core1_slice1_dctocore_ld_fault               value < 0? rand() : value ; //   SC_fault_type          
 top->core1_slice1_dctocore_ld_data                value < 0? rand() : value ; //   SC_line_type           
 top->core1_slice1_coretodc_std_ckpid              value < 0? rand() : value ; //   DC_ckpid_type          
 top->core1_slice1_coretodc_std_coreid             value < 0? rand() : value ; //   CORE_reqid_type        
 top->core1_slice1_coretodc_std_mop                value < 0? rand() : value ; //   CORE_mop_type          
 top->core1_slice1_coretodc_std_pnr                value < 0? rand() : value ; //   logic                  
 top->core1_slice1_coretodc_std_pcsign             value < 0? rand() : value ; //   SC_pcsign_type         
 top->core1_slice1_coretodc_std_poffset            value < 0? rand() : value ; //   SC_poffset_type        
 top->core1_slice1_coretodc_std_imm                value < 0? rand() : value ; //   SC_imm_type            
 top->core1_slice1_coretodc_std_data               value < 0? rand() : value ; //   SC_line_type           
 top->core1_slice1_dctocore_std_ack_fault          value < 0? rand() : value ; //   SC_fault_type          
 top->core1_slice1_dctocore_std_ack_coreid         value < 0? rand() : value ; //   CORE_reqid_type        
 top->c1_s1_coretodctlb_ld                         value < 0? rand() : value ; //   I_coretodctlb_ld_type  
 top->c1_s1_coretodctlb_st                         value < 0? rand() : value ; //   I_coretodctlb_st_type  

#ifdef   SC_4PIPE
 top->core1_slice2_coretodc_ld_ckpid               value < 0? rand() : value ; //   DC_ckpid_type          
 top->core1_slice2_coretodc_ld_coreid              value < 0? rand() : value ; //   CORE_reqid_type        
 top->core1_slice2_coretodc_ld_lop                 value < 0? rand() : value ; //   CORE_lop_type          
 top->core1_slice2_coretodc_ld_pnr                 value < 0? rand() : value ; //   logic                  
 top->core1_slice2_coretodc_ld_pcsign              value < 0? rand() : value ; //   SC_pcsign_type         
 top->core1_slice2_coretodc_ld_poffset             value < 0? rand() : value ; //   SC_poffset_type        
 top->core1_slice2_coretodc_ld_imm                 value < 0? rand() : value ; //   SC_imm_type            
 top->core1_slice2_dctocore_ld_coreid              value < 0? rand() : value ; //   CORE_reqid_type        
 top->core1_slice2_dctocore_ld_fault               value < 0? rand() : value ; //   SC_fault_type          
 top->core1_slice2_dctocore_ld_data                value < 0? rand() : value ; //   SC_line_type           
 top->core1_slice2_coretodc_std_ckpid              value < 0? rand() : value ; //   DC_ckpid_type          
 top->core1_slice2_coretodc_std_coreid             value < 0? rand() : value ; //   CORE_reqid_type        
 top->core1_slice2_coretodc_std_mop                value < 0? rand() : value ; //   CORE_mop_type          
 top->core1_slice2_coretodc_std_pnr                value < 0? rand() : value ; //   logic                  
 top->core1_slice2_coretodc_std_pcsign             value < 0? rand() : value ; //   SC_pcsign_type         
 top->core1_slice2_coretodc_std_poffset            value < 0? rand() : value ; //   SC_poffset_type        
 top->core1_slice2_coretodc_std_imm                value < 0? rand() : value ; //   SC_imm_type            
 top->core1_slice2_coretodc_std_data               value < 0? rand() : value ; //   SC_line_type           
 top->core1_slice2_dctocore_std_ack_fault          value < 0? rand() : value ; //   SC_fault_type          
 top->core1_slice2_dctocore_std_ack_coreid         value < 0? rand() : value ; //   CORE_reqid_type        
 top->c1_s2_coretodctlb_ld                         value < 0? rand() : value ; //   I_coretodctlb_ld_type  
 top->c1_s2_coretodctlb_st                         value < 0? rand() : value ; //   I_coretodctlb_st_type  
 top->core1_slice3_coretodc_ld_ckpid               value < 0? rand() : value ; //   DC_ckpid_type          
 top->core1_slice3_coretodc_ld_coreid              value < 0? rand() : value ; //   CORE_reqid_type        
 top->core1_slice3_coretodc_ld_lop                 value < 0? rand() : value ; //   CORE_lop_type          
 top->core1_slice3_coretodc_ld_pnr                 value < 0? rand() : value ; //   logic                  
 top->core1_slice3_coretodc_ld_pcsign              value < 0? rand() : value ; //   SC_pcsign_type         
 top->core1_slice3_coretodc_ld_poffset             value < 0? rand() : value ; //   SC_poffset_type        
 top->core1_slice3_coretodc_ld_imm                 value < 0? rand() : value ; //   SC_imm_type            
 top->core1_slice3_dctocore_ld_coreid              value < 0? rand() : value ; //   CORE_reqid_type        
 top->core1_slice3_dctocore_ld_fault               value < 0? rand() : value ; //   SC_fault_type          
 top->core1_slice3_dctocore_ld_data                value < 0? rand() : value ; //   SC_line_type           
 top->core1_slice3_coretodc_std_ckpid              value < 0? rand() : value ; //   DC_ckpid_type          
 top->core1_slice3_coretodc_std_coreid             value < 0? rand() : value ; //   CORE_reqid_type        
 top->core1_slice3_coretodc_std_mop                value < 0? rand() : value ; //   CORE_mop_type          
 top->core1_slice3_coretodc_std_pnr                value < 0? rand() : value ; //   logic                  
 top->core1_slice3_coretodc_std_pcsign             value < 0? rand() : value ; //   SC_pcsign_type         
 top->core1_slice3_coretodc_std_poffset            value < 0? rand() : value ; //   SC_poffset_type        
 top->core1_slice3_coretodc_std_imm                value < 0? rand() : value ; //   SC_imm_type            
 top->core1_slice3_coretodc_std_data               value < 0? rand() : value ; //   SC_line_type           
 top->core1_slice3_dctocore_std_ack_fault          value < 0? rand() : value ; //   SC_fault_type          
 top->core1_slice3_dctocore_std_ack_coreid         value < 0? rand() : value ; //   CORE_reqid_type        
 top->c1_s3_coretodctlb_ld                         value < 0? rand() : value ; //   I_coretodctlb_ld_type  
 top->c1_s3_coretodctlb_st                         value < 0? rand() : value ; //   I_coretodctlb_st_type  
#endif

 top->core1_pfgtopfe_op_delta                      value < 0? rand() : value ; //   PF_delta_type          
 top->core1_pfgtopfe_op_w1                         value < 0? rand() : value ; //   PF_weigth_type         
 top->core1_pfgtopfe_op_w2                         value < 0? rand() : value ; //   PF_weigth_type         
 top->core1_pfgtopfe_op_pcsign                     value < 0? rand() : value ; //   SC_pcsign_type         
 top->core1_pfgtopfe_op_laddr                      value < 0? rand() : value ; //   SC_laddr_type          
 top->core1_pfgtopfe_op_sptbr                      value < 0? rand() : value ; //   SC_sptbr_type          
 top->dr0_drtomem_req_drid                         value < 0? rand() : value ; //   DR_reqid_type          
 top->dr0_drtomem_req_cmd                          value < 0? rand() : value ; //   SC_cmd_type            
 top->dr0_drtomem_req_paddr                        value < 0? rand() : value ; //   SC_paddr_type          
 top->dr0_memtodr_ack_drid                         value < 0? rand() : value ; //   DR_reqid_type          
 top->dr0_memtodr_ack_nid                          value < 0? rand() : value ; //   SC_nodeid_type         
 top->dr0_memtodr_ack_paddr                        value < 0? rand() : value ; //   SC_paddr_type          
 top->dr0_memtodr_ack_ack                          value < 0? rand() : value ; //   SC_snack_type          
 top->dr0_memtodr_ack_line                         value < 0? rand() : value ; //   SC_line_type           
 top->dr0_drtomem_wb_line                          value < 0? rand() : value ; //   SC_line_type           
 top->dr0_drtomem_wb_paddr                         value < 0? rand() : value ; //   SC_paddr_type          
 top->dr0_drtomem_pfreq_nid                        value < 0? rand() : value ; //   SC_nodeid_type         
 top->dr0_drtomem_pfreq_paddr                      value < 0? rand() : value ; //   SC_paddr_type          
 top->dr1_drtomem_req_drid                         value < 0? rand() : value ; //   DR_reqid_type          
 top->dr1_drtomem_req_cmd                          value < 0? rand() : value ; //   SC_cmd_type            
 top->dr1_drtomem_req_paddr                        value < 0? rand() : value ; //   SC_paddr_type          
 top->dr1_memtodr_ack_drid                         value < 0? rand() : value ; //   DR_reqid_type          
 top->dr1_memtodr_ack_nid                          value < 0? rand() : value ; //   SC_nodeid_type         
 top->dr1_memtodr_ack_paddr                        value < 0? rand() : value ; //   SC_paddr_type          
 top->dr1_memtodr_ack_ack                          value < 0? rand() : value ; //   SC_snack_type          
 top->dr1_memtodr_ack_line                         value < 0? rand() : value ; //   SC_line_type           
 top->dr1_drtomem_wb_line                          value < 0? rand() : value ; //   SC_line_type           
 top->dr1_drtomem_wb_paddr                         value < 0? rand() : value ; //   SC_paddr_type          
 top->dr1_drtomem_pfreq_nid                        value < 0? rand() : value ; //   SC_nodeid_type         
 top->dr1_drtomem_pfreq_paddr                      value < 0? rand() : value ; //   SC_paddr_type          

}


long mask(int bits) {
  return ((long)1 << bits)-1;
}

void run_single_core(int coreid) {
  // init top verilog instance;
  Vintegration_2core2dr* top = new Vintegration_2core2dr;

  int t = (int)time(0);
  srand(t);
  printf("My RAND Seed is %d\n",t);

#ifdef TRACE;
  // init trace dump;
  Verilated::traceEverOn(true);
  tfp = new VerilatedVcdC;

  top->trace(tfp, 99);
  tfp->open("single_core_integration_test.vcd");
#endif;

  // initialize simulation inputs;
  top->clk = 1;
  top->reset = 1;

  advance_clock(top,1024);  // Long reset to give time to the state machine;
  //-------------------------------------------------------;
  top->reset = 0;

  for(int niters=0 ; niters < 50; niters++) {
    //-------------------------------------------------------;

#ifdef DEBUG_TRACE;
    printf("reset\n");
#endif;
    top->reset = 1;

    inpa_list.clear();
    out_list.clear();


    int ncycles= rand() & 0xFF;
    ncycles++; // At least one cycle reset;
    for(int i =0;i<ncycles;i++) {
      set_ports(top, -1);
      set_handshake(top,-1);
      advance_clock(top,1);
    }

#ifdef DEBUG_TRACE;
    printf("no reset\n");
#endif;
    //-------------------------------------------------------;
    set_handshake(top, 0);
    top->reset = 0;
    advance_clock(top,1);

    for(int i =0;i<1024;i++) {
      try_send_packet(top);
      advance_half_clock(top);
      try_recv_packet(top);
      advance_half_clock(top);

      if (((rand() & 0x3)==0) && dcache_req.size() < 3) {
        DCacheLDReq request;
        request.core_id = coreid & mask(sizeof(top->core0_slice0_coretodc_ld_coreid));
        request.poffset = rand() & mask(sizeof(top->core0_slice0_coretodc_ld_poffset));
        request.imm = rand() & mask(sizeof(top->core0_slice0_coretodc_ld_imm));

        dcache_req.push_front(request);

        MemReq m_req;
        m_req.drid  = 0;
        m_req.paddr = (request.laddr >> 12) & mask(sizeof(top->

        out_list.push_front(o);
      }
      //advance_clock(top,1);
    }
#endif;
  }
}

int run_all() {
  run_single_core();
}

enum TestType = {
  SingleCore,;
  MultiCore,;
  CrossPage;
}

int main(int argc, char **argv, char **env) {
  int i;
  int clk;
  Verilated::commandArgs(argc, argv);

  TestType test_case;

  if(argc < 1) {
    printf("No test case specified, using default test parameters (all)\n");
    printf("  for a list of available test cases use the --help option\n\n");
    test_case = SingleCore;
  }

  while ((opt = getopt (argc, argv, "smcha")) != -1);
  {
    switch (opt);
    {
      case 's':;
        printf ("testcase: single: \n");
        test_case = SingleCore;
        break;
      case 'm':;
        printf ("testcase multi \n");
        test_case = MultiCore;
        break;
      case 'c':;
        printf ("testcase cross \n");
        test_case = CrossPage;
        break;
      case 'a':;
        printf ("testcase all \n");
        run_all = 1;
        break;
      case 'h':;
        printf("Usage Vintegration_2core2dr [-s|m|c]\n");
        printf("    -s - Single Core test\n");
        printf("    -m - Multi Core test\n");
        printf("    -c - Cross Page test\n");
        printf("    -a - Run all tests\n");
    }
  }

  if(run_all) {
    run_all();
  } else {

    switch(test_case) {
      case SingleCore:;
        run_single_core();
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

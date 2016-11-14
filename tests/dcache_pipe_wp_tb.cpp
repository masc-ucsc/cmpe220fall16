// dcache pass-through testbench
// team: Nursultan, Nilufar

#include "Vdcache_pipe_wp.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <list>

#include <time.h>

#define DEBUG_TRACE 1

// turn on/off testbench
#define TEST_L2_TO_L1_SNACK   1
#define TEST_CORE_TO_DC       1
vluint64_t global_time = 0;
VerilatedVcdC* tfp = 0;

#define SC_CMD_REQ_S    0
#define SC_CMD_REQ_M    1
#define SC_CMD_REQ_NC   2
#define SC_CMD_DRAINI   6 
///////////////////////////////////////////////////////////
// pair #1
// l2tol1_snack_packet --> dctocore_ld_packet
///////////////////////////////////////////////////////////
struct l2tol1_snack_packet { // input
  uint8_t l1id;
  uint8_t l2id;   
  uint8_t snack;  
  uint64_t line7;
  uint64_t line6;
  uint64_t line5; 
  uint64_t line4;
  uint64_t line3;
  uint64_t line2;
  uint64_t line1;
  uint64_t line0;
  uint16_t poffset;
  uint16_t hpaddr;
};

struct dctocore_ld_packet { //output
  uint8_t coreid;
  uint8_t fault;
  uint64_t data7;
  uint64_t data6;
  uint64_t data5; 
  uint64_t data4;
  uint64_t data3;
  uint64_t data2;
  uint64_t data1;
  uint64_t data0;
};

///////////////////////////////////////////////////////////
// pair #2 
// coretodc_ld+l1tlbtol1_fwd0 --> l1tol2_req+l1tol2tlb_req
///////////////////////////////////////////////////////////
struct coretodc_ld_packet { //input to DUT
  uint8_t ckpid;
  uint8_t coreid;
  uint8_t lop;
  uint8_t pnr;
  uint16_t pcsign;
  uint16_t poffset;
  uint16_t imm;
};

struct l1tlbtol1_fwd_packet { //input to DUT
  uint8_t coreid;
  uint8_t prefetch;
  uint8_t l2_prefetch;
  uint8_t fault;
  uint16_t hpaddr;
  uint8_t ppaddr; 
};

struct l1tol2_req_packet { //output of DUT
  uint8_t l1id;
  uint8_t cmd;
  uint16_t pcsign;
  uint16_t poffset;
  uint8_t ppaddr;
};

struct l1tol2tlb_req_packet { //output of DUT
  uint8_t l1id;
  uint8_t prefetch;
  uint16_t hpaddr;
};

///////////////////////////////////////////////////////////
// TESTBENCH AUX FUNCTIONS
///////////////////////////////////////////////////////////
void advance_half_clock(Vdcache_pipe_wp *top) {
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

void advance_clock(Vdcache_pipe_wp *top, int nclocks=1) {

  for( int i=0;i<nclocks;i++) {
    for (int clk=0; clk<2; clk++) {
      advance_half_clock(top);
    }
  }
}
double sc_time_stamp() {
  return 0;
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

void error_found(Vdcache_pipe_wp *top) {
  advance_half_clock(top);
  advance_half_clock(top);
  sim_finish(false);
}

///////////////////////////////////////////////////////////
// TRY SEND AND TRY RECV FUNCTIONS
///////////////////////////////////////////////////////////
// PAIR #1 SEND-RECV FUNCTIONS
std::list<l2tol1_snack_packet>  l2tol1_snack_list;
std::list<dctocore_ld_packet> dctocore_ld_list;
// try send
void try_send_l2tol1_snack(Vdcache_pipe_wp *top) {
  if (!top->l2tol1_snack_retry) {
    top->l2tol1_snack_l1id = rand();
    top->l2tol1_snack_l2id = rand();
    top->l2tol1_snack_snack = rand();
    top->l2tol1_snack_line_7 = rand(); 
    top->l2tol1_snack_line_6 = rand(); 
    top->l2tol1_snack_line_5 = rand(); 
    top->l2tol1_snack_line_4 = rand(); 
    top->l2tol1_snack_line_3 = rand(); 
    top->l2tol1_snack_line_2 = rand(); 
    top->l2tol1_snack_line_1 = rand(); 
    top->l2tol1_snack_line_0 = rand();
    top->l2tol1_snack_poffset = rand();
    top->l2tol1_snack_hpaddr = rand(); 
    if (l2tol1_snack_list.empty() || (rand() & 0x3)) { // Once every 4
      top->l2tol1_snack_valid = 0;
    }else{
      top->l2tol1_snack_valid = 1;
    }
  }

  if (top->l2tol1_snack_valid && !top->l2tol1_snack_retry) {
    if (l2tol1_snack_list.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty inpa\n");
    }
    l2tol1_snack_packet inp = l2tol1_snack_list.back();
    top->l2tol1_snack_l1id = inp.l1id;
    top->l2tol1_snack_l2id = inp.l2id;
    top->l2tol1_snack_snack = inp.snack;
    top->l2tol1_snack_line_7 = inp.line7; 
    top->l2tol1_snack_line_6 = inp.line6; 
    top->l2tol1_snack_line_5 = inp.line5; 
    top->l2tol1_snack_line_4 = inp.line4; 
    top->l2tol1_snack_line_3 = inp.line3; 
    top->l2tol1_snack_line_2 = inp.line2; 
    top->l2tol1_snack_line_1 = inp.line1; 
    top->l2tol1_snack_line_0 = inp.line0;
    top->l2tol1_snack_poffset = inp.poffset;
    top->l2tol1_snack_hpaddr = inp.hpaddr; 
#ifdef DEBUG_TRACE
    printf("@%lld ",global_time);
    printf("l1id:%x ", inp.l1id);
    printf("l2id:%x ", inp.l2id);
    printf("snack:%x ", inp.snack);
    printf("line_7:%x ", inp.line7);
    printf("line_6:%x ", inp.line6);
    printf("line_5:%x ", inp.line5);
    printf("line_4:%x ", inp.line4);
    printf("line_3:%x ", inp.line3);
    printf("line_2:%x ", inp.line2);
    printf("line_1:%x ", inp.line1);
    printf("line_0:%x ", inp.line0);
    printf("poffset:%x ", inp.poffset);
    printf("hpaddr:%x\n", inp.hpaddr);
#endif
    // generate expected dctocore_ld output
    dctocore_ld_packet out;
    out.coreid = 0;
    out.fault = 0;
    out.data7 = inp.line7;
    out.data6 = inp.line6;
    out.data5 = inp.line5;
    out.data4 = inp.line4;
    out.data3 = inp.line3;
    out.data2 = inp.line2;
    out.data1 = inp.line1;
    out.data0 = inp.line0;
    dctocore_ld_list.push_front(out);

    l2tol1_snack_list.pop_back();
  }

}

//try recv
void try_recv_dctocore_ld(Vdcache_pipe_wp *top) {
  if (top->dctocore_ld_valid && dctocore_ld_list.empty()) {
    printf("ERROR: unexpected dctocore_ld\n");
    error_found(top);
    return;
  }

  if (top->dctocore_ld_retry) {
    printf("dctocore_ld_retry=1\n");
    return;
  }

  if (!top->dctocore_ld_valid) {
    printf("dctocore_ld_valid=0\n");
    return;
  }

  if (dctocore_ld_list.empty()) {
    printf("list empty\n");
    return;
  }

#ifdef DEBUG_TRACE
    printf("@%lld ",global_time);
    printf("coreid:%x ", top->dctocore_ld_coreid);
    printf("fault:%x ", top->dctocore_ld_fault);
    printf("data_7:%x ", top->dctocore_ld_data_7);
    printf("data_6:%x ", top->dctocore_ld_data_6);
    printf("data_5:%x ", top->dctocore_ld_data_5);
    printf("data_4:%x ", top->dctocore_ld_data_4);
    printf("data_3:%x ", top->dctocore_ld_data_3);
    printf("data_2:%x ", top->dctocore_ld_data_2);
    printf("data_1:%x ", top->dctocore_ld_data_1);
    printf("data_0:%x\n", top->dctocore_ld_data_0);
#endif
  bool f = false;
  dctocore_ld_packet out = dctocore_ld_list.back();
  printf("dctocore_ld_list_size=%d\n", dctocore_ld_list.size());
  if (top->dctocore_ld_coreid != out.coreid) {
    printf("ERROR: expected coreid:%x but coreid is %x\n",out.coreid,top->dctocore_ld_coreid);
    f=true;
  }

  if (top->dctocore_ld_fault  != out.fault) {
    printf("ERROR: expected fault:%x but fault is %x\n",out.fault,top->dctocore_ld_fault);
    f=true;
  }
  
  if (top->dctocore_ld_data_7 != out.data7) {
    printf("ERROR: expected data7:%x but data7 is %x\n",out.data7,top->dctocore_ld_data_7);
    f=true;
  }

  if (top->dctocore_ld_data_6 != out.data6) {
    printf("ERROR: expected data6:%x but data6 is %x\n",out.data6,top->dctocore_ld_data_6);
    f=true;
  }

  if (top->dctocore_ld_data_5 != out.data5) {
    printf("ERROR: expected data5:%x but data5 is %x\n",out.data5,top->dctocore_ld_data_5);
    f=true;
  }

  if (top->dctocore_ld_data_4 != out.data4) {
    printf("ERROR: expected data4:%x but data4 is %x\n",out.data7,top->dctocore_ld_data_4);
    f=true;
  }

  if (top->dctocore_ld_data_3 != out.data3) {
    printf("ERROR: expected data3:%x but data3 is %x\n",out.data3,top->dctocore_ld_data_3);
    f=true;
  }

  if (top->dctocore_ld_data_2 != out.data2) {
    printf("ERROR: expected data2:%x but data2 is %x\n",out.data7,top->dctocore_ld_data_2);
    f=true;
  }

  if (top->dctocore_ld_data_1 != out.data1) {
    printf("ERROR: expected data1:%x but data1 is %x\n",out.data1,top->dctocore_ld_data_1);
    f=true;
  }

  if (top->dctocore_ld_data_0 != out.data0) {
    printf("ERROR: expected data0:%x but data0 is %x\n",out.data0,top->dctocore_ld_data_0);
    f=true;
  }

  if (!f) {
    printf("dctocore_ld PASSED\n");
  } else {
    error_found(top);
  }
  printf("\n");
  dctocore_ld_list.pop_back();
}

// PAIR #2 SEND-RECV FUNCTIONS
std::list<coretodc_ld_packet>  coretodc_ld_list;
std::list<l1tlbtol1_fwd_packet> l1tlbtol1_fwd0_list;
std::list<l1tol2_req_packet> l1tol2_req_list;
std::list<l1tol2tlb_req_packet> l1tol2tlb_req_list;

// generate coretodc_ld packet with random values
coretodc_ld_packet generateRand_coretodc_ld_packet() {
  coretodc_ld_packet result;

  result.ckpid = 0;
  result.coreid = 0;
  result.lop = rand()&0x1f;
  result.pnr = rand()&0x1;
  result.pcsign = rand()&0x1fff;
  result.poffset = rand()&0xfff;
  result.imm = rand()&0xfff;

  return result;
}

// generate l1tlbtol1_fwd packet with random values
l1tlbtol1_fwd_packet generateRand_l1tlbtol1_fwd_packet() {
  l1tlbtol1_fwd_packet result;

  result.coreid = 0;
  result.prefetch = 0;
  result.l2_prefetch = 0;
  result.fault = rand()&0x7;
  result.hpaddr = rand()&0x03ff;
  result.ppaddr = rand()&0x7;

  return result; 
}

// try send
void try_send_coretodc_ld(Vdcache_pipe_wp *top) {
  //randomize validity of the packet
  if (!top->coretodc_ld_retry && !top->l1tlbtol1_fwd0_retry) {
    coretodc_ld_packet randPack0 = generateRand_coretodc_ld_packet();
    l1tlbtol1_fwd_packet randPack1 = generateRand_l1tlbtol1_fwd_packet();
    top->coretodc_ld_ckpid = randPack0.ckpid;
    top->coretodc_ld_coreid = randPack0.coreid;
    top->coretodc_ld_lop = randPack0.lop;
    top->coretodc_ld_pnr = randPack0.pnr;
    top->coretodc_ld_pcsign = randPack0.pcsign;
    top->coretodc_ld_poffset = randPack0.poffset;
    top->coretodc_ld_imm = randPack0.imm;

    top->l1tlbtol1_fwd0_coreid = randPack0.coreid;
    top->l1tlbtol1_fwd0_prefetch = randPack1.prefetch;
    top->l1tlbtol1_fwd0_l2_prefetch = randPack1.l2_prefetch;
    top->l1tlbtol1_fwd0_fault = randPack1.fault;
    top->l1tlbtol1_fwd0_hpaddr = randPack1.hpaddr;
    top->l1tlbtol1_fwd0_ppaddr = randPack1.ppaddr;
    if (coretodc_ld_list.empty() || (rand() & 0x3)) {
      top->coretodc_ld_valid = 0;
      top->l1tlbtol1_fwd0_valid = 0;
    } else {
      top->coretodc_ld_valid = 1;
      top->l1tlbtol1_fwd0_valid = 1;
    }
  }

  // try to send packet 
  if (top->coretodc_ld_valid && !top->coretodc_ld_retry
        && top->l1tlbtol1_fwd0_valid && !top->l1tlbtol1_fwd0_retry) {
    if (coretodc_ld_list.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty inp\n");
    }

    coretodc_ld_packet inpPack0 = coretodc_ld_list.back();
    l1tlbtol1_fwd_packet inpPack1 = l1tlbtol1_fwd0_list.back();
    top->coretodc_ld_ckpid = inpPack0.ckpid;
    top->coretodc_ld_coreid = inpPack0.coreid;
    top->coretodc_ld_lop = inpPack0.lop;
    top->coretodc_ld_pnr = inpPack0.pnr;
    top->coretodc_ld_pcsign = inpPack0.pcsign;
    top->coretodc_ld_poffset = inpPack0.poffset;
    top->coretodc_ld_imm = inpPack0.imm;

    top->l1tlbtol1_fwd0_coreid = inpPack1.coreid;
    top->l1tlbtol1_fwd0_prefetch = inpPack1.prefetch;
    top->l1tlbtol1_fwd0_l2_prefetch = inpPack1.l2_prefetch;
    top->l1tlbtol1_fwd0_fault = inpPack1.fault;
    top->l1tlbtol1_fwd0_hpaddr = inpPack1.hpaddr;
    top->l1tlbtol1_fwd0_ppaddr = inpPack1.ppaddr;
#ifdef DEBUG_TRACE
    printf("@%lld ",global_time);
    printf("ckpid:%x ", inpPack0.ckpid);
    printf("coreid:%x ", inpPack0.coreid);
    printf("lop:%x ", inpPack0.lop);
    printf("pcsign:%x ", inpPack0.pcsign);
    printf("poffset:%x ", inpPack0.poffset);
    printf("imm:%x\n", inpPack0.imm);
    printf("ppaddr:%x ", inpPack1.ppaddr);
    printf("hpaddr:%x\n", inpPack1.hpaddr);
#endif

    // generate expected l1tol2_req output
    l1tol2_req_packet out0;
    out0.l1id = 0;
    out0.cmd = SC_CMD_REQ_S;
    out0.pcsign = inpPack0.pcsign;
    out0.poffset = inpPack0.poffset;
    out0.ppaddr = inpPack1.ppaddr;
    l1tol2_req_list.push_front(out0);
    // generate expected l1tol2tlb_req output
    l1tol2tlb_req_packet out1;
    out1.l1id = 0;
    out1.prefetch = inpPack1.prefetch;
    out1.hpaddr = inpPack1.hpaddr;
    l1tol2tlb_req_list.push_front(out1);

    coretodc_ld_list.pop_back();
    l1tlbtol1_fwd0_list.pop_back();
  }
}

//try recv
void try_recv_l1tol2_req(Vdcache_pipe_wp *top) {
  if (top->l1tol2_req_valid && l1tol2_req_list.empty()) {
    printf("ERROR: unexpected l1tol2_req\n");
    error_found(top);
    return;       
  }

  if (top->l1tol2_req_retry) {
    printf("l1tol2_req_retry=1\n");
    return;
  }

  if (!top->l1tol2_req_valid) {
    printf("l1tol2_req_valid=0\n");
    return;
  }

  if (l1tol2_req_list.empty()) {
    printf("l1tol2_req_list is empty\n");
    return;
  }

#ifdef DEBUG_TRACE
    printf("@%lld ",global_time);
    printf("l1id:%x ", top->l1tol2_req_l1id);
    printf("cmd:%x ", top->l1tol2_req_cmd);
    printf("pcsign:%x ", top->l1tol2_req_pcsign);
    printf("poffset:%x ", top->l1tol2_req_poffset);
    printf("ppaddr:%x\n", top->l1tol2_req_ppaddr);
#endif

  bool f = false;//f for failed
  l1tol2_req_packet out = l1tol2_req_list.back();
 
  if (top->l1tol2_req_l1id != out.l1id) {
    printf("ERROR: expected l1id:%x but l1id is %x\n",out.l1id,top->l1tol2_req_l1id);
    f=true;
  }

  if (top->l1tol2_req_cmd != out.cmd) {
    printf("ERROR: expected cmd:%x but cmd is %x\n",out.cmd,top->l1tol2_req_cmd);
    f=true;
  }
  
  if (top->l1tol2_req_pcsign != out.pcsign) {
    printf("ERROR: expected pcsign:%x but pcsign is %x\n",out.pcsign,top->l1tol2_req_pcsign);
    f=true;
  }

  if (top->l1tol2_req_poffset != out.poffset) {
    printf("ERROR: expected poffset:%x but poffset is %x\n",out.poffset,top->l1tol2_req_poffset);
    f=true;
  }

  if (top->l1tol2_req_ppaddr != out.ppaddr) {
    printf("ERROR: expected ppaddr:%x but ppaddr is %x\n",out.ppaddr,top->l1tol2_req_ppaddr);
    f=true;
  }

  if (!f) {
    printf("l1tol2_req PASSED\n");
  } else {
    error_found(top);
  }
  printf("\n");
  l1tol2_req_list.pop_back();
}

//try recv
void try_recv_l1tol2tlb_req(Vdcache_pipe_wp *top) {
  if (top->l1tol2tlb_req_valid && l1tol2tlb_req_list.empty()) {
    printf("ERROR: unexpected l1tol2tlb_req\n");
    error_found(top);
    return;
  }

  if (top->l1tol2tlb_req_retry) {
    printf("l1tol2tlb_req_retry=1\n");
    return;
  }

  if (!top->l1tol2tlb_req_valid) {
    printf("l1tol2tlb_req_valid=0\n");
    return;
  }

  if (l1tol2tlb_req_list.empty()) {
    printf("l1tol2tlb_req_list is empty\n");
    return;
  }
           
#ifdef DEBUG_TRACE
    printf("@%lld ",global_time);
    printf("l1id:%x ", top->l1tol2tlb_req_l1id);
    printf("prefetch:%x ", top->l1tol2tlb_req_prefetch);
    printf("hpaddr:%x\n", top->l1tol2tlb_req_hpaddr);
#endif
 
  bool f = false; //f for failed
  l1tol2tlb_req_packet out = l1tol2tlb_req_list.back();

  if (top->l1tol2tlb_req_l1id != out.l1id) {
    printf("ERROR: expected l1id:%x but l1id is %x\n",out.l1id,top->l1tol2tlb_req_l1id);
    f=true;
  }

  if (top->l1tol2tlb_req_prefetch != out.prefetch) {
    printf("ERROR: expected prefetch:%x but prefetch is %x\n",out.prefetch,top->l1tol2tlb_req_prefetch);
    f=true;
  }

  if (top->l1tol2tlb_req_hpaddr != out.hpaddr) {
    printf("ERROR: expected hpaddr:%x but hpaddr is %x\n",out.hpaddr,top->l1tol2tlb_req_hpaddr);
    f=true;
  }

  if (!f) {
    printf("l1tol2tlb_req PASSED\n");
  } else {
    error_found(top);
  }
  printf("\n");
  l1tol2tlb_req_list.pop_back();
}

int main(int argc, char **argv, char **env) {
  int i;
  int clk;
  Verilated::commandArgs(argc, argv);
  // init top verilog instance
  Vdcache_pipe_wp* top = new Vdcache_pipe_wp;

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
  top->dctocore_ld_retry = 0;

  advance_clock(top,1);

#if TEST_L2_TO_L1_SNACK
  for(int i =0;i<1024;i++) {
    try_send_l2tol1_snack(top);
    advance_clock(top,3);
    try_recv_dctocore_ld(top);
    advance_clock(top,1);

    if (((rand() & 0x3)==0) && l2tol1_snack_list.size() < 3 ) {
      l2tol1_snack_packet in;
      in.l1id = rand();
      in.l2id = rand();
      in.snack = rand();
      in.line7 = rand(); 
      in.line6 = rand(); 
      in.line5 = rand(); 
      in.line4 = rand(); 
      in.line3 = rand(); 
      in.line2 = rand(); 
      in.line1 = rand(); 
      in.line0 = rand(); 
      l2tol1_snack_list.push_front(in);
    }
  }
#endif

#if TEST_CORE_TO_DC
  for (int i=0; i<1024; i++) {
    try_send_coretodc_ld(top);
    advance_clock(top, 2);
    try_recv_l1tol2_req(top);
    try_recv_l1tol2tlb_req(top);
    advance_clock(top, 1);

    if (((rand() & 0x3)==0) && coretodc_ld_list.size()<3) {
      coretodc_ld_packet in0 = generateRand_coretodc_ld_packet();
      coretodc_ld_list.push_front(in0);
      l1tlbtol1_fwd_packet in1 = generateRand_l1tlbtol1_fwd_packet();
      l1tlbtol1_fwd0_list.push_front(in1); 
    }
  }
#endif
  sim_finish(true);

}


#include "Vl2cache_pipe_wp.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <list>

#include <time.h>

#define DEBUG_TRACE 1

vluint64_t global_time = 0;
VerilatedVcdC* tfp = 0;

void advance_half_clock(Vl2cache_pipe_wp *top) {
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

void advance_clock(Vl2cache_pipe_wp *top, int nclocks=1) {

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

// Define stimulus struct
struct L1tol2ReqPacket {
    uint8_t dcid;
    uint8_t cmd;
    uint16_t pcsign;
    uint64_t laddr;
    uint64_t sptbr;
};

struct L2todrReqPacket {
    uint8_t nid;
    uint8_t l2id;
    uint8_t cmd;
    uint64_t paddr;
};

struct L2toL1SnackPacket {
    uint8_t dcid;
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
    uint64_t paddr;
    uint8_t dctlbe;
};

struct DrtoL2SnackPacket {
    uint8_t nid;
    uint8_t l2id;
    uint8_t drid;
    uint8_t snack;
    uint64_t line7;
    uint64_t line6;
    uint64_t line5;
    uint64_t line4;
    uint64_t line3;
    uint64_t line2;
    uint64_t line1;
    uint64_t line0;
    uint64_t paddr;
};

//

std::list<L1tol2ReqPacket> l1tol2_req_list;
std::list<L2todrReqPacket> l2todr_req_list;
std::list<L2toL1SnackPacket> l2tol1_snack_list;
std::list<DrtoL2SnackPacket> drtol2_snack_list;
int count_l1tol2_req = 0;
int count_l2todr_req = 0;
int count_l2tol1_snack = 0;
int count_drtol2_snack = 0;

void error_found(Vl2cache_pipe_wp *top) {
  advance_half_clock(top);
  advance_half_clock(top);
  sim_finish(false);
}

void try_send_l1_to_l2_req_packet (Vl2cache_pipe_wp *top) {
    top->l2todr_req_retry = (rand()&0xF)==0; // randomly,
    if ( !top-> l1tol2_req_retry ) {
        top->l1tol2_req_dcid = rand();
        top->l1tol2_req_cmd = rand();
        top->l1tol2_req_pcsign = rand();
        top->l1tol2_req_laddr = rand();
        top->l1tol2_req_sptbr = rand();
        if (l1tol2_req_list.empty() || (rand() & 0x3==0)) { // Once every 4
          top->l1tol2_req_valid = 0;
        }else{
          top->l1tol2_req_valid = 1;
        }
    }
    
    if (top->l1tol2_req_valid && !top->l1tol2_req_retry){
        if (l1tol2_req_list.empty()) {
            fprintf(stderr,"ERROR: Internal error, could not be empty l1tol2_req_list\n");
        }
        L1tol2ReqPacket l1tol2_reqp = l1tol2_req_list.back();
        count_l1tol2_req++;
        top->l1tol2_req_dcid = l1tol2_reqp.dcid;
        top->l1tol2_req_cmd = l1tol2_reqp.cmd;
        top->l1tol2_req_pcsign = l1tol2_reqp.pcsign;
        top->l1tol2_req_laddr = l1tol2_reqp.laddr;
        top->l1tol2_req_sptbr = l1tol2_reqp.sptbr;
#ifdef DEBUG_TRACE
        printf("@%lld l1tol2_req dcid:%x cmd:%x pcsign:%d laddr:%x sptbr:%x\n",global_time, l1tol2_reqp.dcid, 
            l1tol2_reqp.cmd, l1tol2_reqp.pcsign, l1tol2_reqp.laddr, l1tol2_reqp.sptbr);
#endif
        if (0) { // If it's write
                    // TODO
        }
        else{
          L2todrReqPacket l2todr_reqp;
          l2todr_reqp.nid = rand();
          l2todr_reqp.l2id = rand();
          l2todr_reqp.cmd = l1tol2_reqp.cmd;
          l2todr_reqp.paddr = l1tol2_reqp.laddr;
          l2todr_req_list.push_front(l2todr_reqp);
        }
        l1tol2_req_list.pop_back();
    }
}

void try_send_l2_to_l1_snack_packet (Vl2cache_pipe_wp *top) {
    top->drtol2_snack_retry = (rand()&0xF)==0; // randomly,
    if ( !top-> l2tol1_snack_retry ) {
        top->l2tol1_snack_dcid = rand();
        top->l2tol1_snack_l2id = rand();
        top->l2tol1_snack_snack = rand();
        top->l2tol1_snack_line7 = rand();
        top->l2tol1_snack_line6 = rand();
        top->l2tol1_snack_line5 = rand();
        top->l2tol1_snack_line4 = rand();
        top->l2tol1_snack_line3 = rand();
        top->l2tol1_snack_line2 = rand();
        top->l2tol1_snack_line1 = rand();
        top->l2tol1_snack_line0 = rand();
        top->l2tol1_snack_paddr = rand();
        top->l2tol1_snack_dctlbe = rand();
        if (l2tol1_snack_list.empty() || (rand() & 0x3==0)) { // Once every 4
          top->l2to12_snack_valid = 0;
        }else{
          top->l2tol1_snack_valid = 1;
        }
    }
    
    if (top->l2tol1_snack_valid && !top->l2tol1_snack_retry){
        if (l2tol1_snack_list.empty()) {
            fprintf(stderr,"ERROR: Internal error, could not be empty l2tol1_snack_list\n");
        }
        L2tol1SnackPacket l2tol1_snackp = l2tol1_snack_list.back();
        count_l2tol1_snack++;
        top->l2tol1_snack_dcid = l2tol1_snackp.dcid;
        top->l2tol1_snack_l2id = l2tol1_snackp.l2id;
        top->l2tol1_snack_snack = l2tol1_snackp.snack;
        top->l2tol1_snack_line7 = l2tol1_snackp.line7;
        top->l2tol1_snack_line6 = l2tol1_snackp.line6;
        top->l2tol1_snack_line5 = l2tol1_snackp.line5;
        top->l2tol1_snack_line4 = l2tol1_snackp.line4;
        top->l2tol1_snack_line3 = l2tol1_snackp.line3;
        top->l2tol1_snack_line2 = l2tol1_snackp.line2;
        top->l2tol1_snack_line1 = l2tol1_snackp.line1;
        top->l2tol1_snack_line0 = l2tol1_snackp.line0;
        top->l2tol1_snack_paddr = l2tol1_snackp.paddr;
        top->l2tol1_snack_dctlbe = l2tol1_snackp.dctlbe;
#ifdef DEBUG_TRACE
        printf("@%lld l2tol1_snack dcid:%x l2id:%x snack:%d line7:%x line6:%x line5:%x line4:%x line3:%x line2:%x line1:%x line0:%x paddr:%x dctlbe:%x\n",global_time, l2tol1_snackp.dcid, l2tol1_snackp.l2id, l2tol1_snackp.snack, l2tol1_snackp.line7, l2tol1_snackp.line6, l2tol1_snackp.line5, l2tol1_snackp.line4, l2tol1_snackp.line3, l2tol1_snackp.line2, l2tol1_snackp.line1, l2tol1_snackp.line0, l2tol1_snackp.paddr, l2tol1_snackp.dctlbe);
#endif
        if (0) { // If it's write
                    // TODO
        }
        else{
          DrtoL2SnackPacket drtol2_snackp;
          drtol2_snackp.nid = rand();
          drtol2_snackp.l2id = rand();
          drtol2_snackp.drid = rand();
          drtol2_snackp.snack = l2tol1_snackp.snack;
          drtol2_snackp.line7 = l2tol1_snackp.line7;
          drtol2_snackp.line6 = l2tol1_snackp.line6;
          drtol2_snackp.line5 = l2tol1_snackp.line5;
          drtol2_snackp.line4 = l2tol1_snackp.line4;
          drtol2_snackp.line3 = l2tol1_snackp.line3;
          drtol2_snackp.line2 = l2tol1_snackp.line2;
          drtol2_snackp.line1 = l2tol1_snackp.line1;
          drtol2_snackp.line0 = l2tol1_snackp.line0;
          drtol2_snackp.paddr = l2tol1_snackp.paddr;
          drtol2_snack_list.push_front(drtol2_snackp);
        }
        l2tol1_snack_list.pop_back();
    }
}

void try_receive_l2_to_dr_req_packet (Vl2cache_pipe_wp *top) {
    if(top->l2todr_req_valid && l2todr_req_list.empty()){
        printf("ERROR: unexpected l2todr_req nid:%x l2id:%x cmd:%x  paddr:%x\n",top->l2todr_req_nid, 
                top->l2todr_req_l2id, top->l2todr_req_cmd, top->l2todr_req_paddr);
        error_found(top);
        return;
    }

    if (top->l2todr_req_retry) {
        return;
    }

    if (!top->l2todr_req_valid) {
        return;
    }
    
    if (l2todr_req_list.empty())
        return;

    #ifdef DEBUG_TRACE
    printf("@%lld l2todr_req nid:%x l2id:%x cmd:%x  paddr:%x\n",global_time, top->l2todr_req_nid, top->l2todr_req_l2id, 
            top->l2todr_req_cmd, top->l2todr_req_paddr);

    #endif
    L2todrReqPacket l2todr_reqp = l2todr_req_list.back();
    if (top->l2todr_req_cmd != l2todr_reqp.cmd ||
          top->l2todr_req_paddr != l2todr_reqp.paddr) {
        printf("ERROR: expected l2todr_req_cmd:%x but actual l2todr_req_cmd is %x\n", l2todr_reqp.cmd,top->l2todr_req_cmd);
        printf("ERROR: expected l2todr_req_paddr:%x but actual l2todr_req_paddr is %x\n", l2todr_reqp.paddr,top->l2todr_req_paddr);
        error_found(top);
      }
    l2todr_req_list.pop_back();
    count_l2todr_req++;
}

void try_receive_dr_to_l2_snack_packet (Vl2cache_pipe_wp *top) {
    if(top->drtol2_snack_valid && drtol2_snack_list.empty()){
        printf("ERROR: unexpected drtol2_snack nid:%x l2id:%x drid:%x snack:%x line7:%x line6:%x line5:%x line4:%x line3:%x line2:%x line1:%x line0:%x paddr:%x\n",top->drtol2_snack_nid, top->drtol2_snack_l2id, top->drtol2_snack_drid, top->drtol2_snack_line7, top->drtol2_snack_line6, top->drtol2_snack_line5, top->drtol2_snack_line4, top->drtol2_snack_line3, top->drtol2_snack_line2, top->drtol2_snack_line1, top->drtol2_snack_line0, top->drtol2_snack_paddr);
        error_found(top);
        return;
    }

    if (top->drtol2_snack_retry) {
        return;
    }

    if (!top->drtol2_snack_valid) {
        return;
    }
    
    if (drtol2_snack_list.empty())
        return;

    #ifdef DEBUG_TRACE
    printf("@%lld drtol2_req nid:%x l2id:%x drid:%x snack:%x line7:%x line6:%x line5:%x line4:%x line3:%x line2:%x line1:%x line0:%x paddr:%x\n",global_time, top->drtol2_snack_nid, top->l2todr_req_l2id, top->drtol2_snack_drid, top->drtol2_snack_snack, top->drtol2_snack_line7, top->drtol2_snack_line6, top->drtol2_snack_line5, top->drtol2_snack_line4, top->drtol2_snack_line3, top->drtol2_snack_line2, top->drtol2_snack_line1, top->drtol2_snack_line0, top->l2todr_req_paddr);

    #endif
    DrtoL2SnackPacket drtol2_snackp = drtol2_snack_list.back();
    if (top->drtol2_snack_snack != drtol2_snackp.snack ||
        top->drtol2_snack_line7 != drtol2_snackp.line7 ||
        top->drtol2_snack_line6 != drtol2_snackp.line6 ||
        top->drtol2_snack_line5 != drtol2_snackp.line5 ||
        top->drtol2_snack_line4 != drtol2_snackp.line4 ||
        top->drtol2_snack_line3 != drtol2_snackp.line3 ||
        top->drtol2_snack_line2 != drtol2_snackp.line2 ||
        top->drtol2_snack_line1 != drtol2_snackp.line1 ||
        top->drtol2_snack_line0 != drtol2_snackp.line0 ||
        top->drtol2_snack_paddr != drtol2_snackp.paddr) {
        printf("ERROR: expected drtol2_snack_snack:%x but actual drtol2_snack_snack is %x\n", drtol2_snackp.snack,top->drtol2_snack_snack);
        printf("ERROR: expected drtol2_snack_line7:%x but actual drtol2_snack_line7 is %x\n", drtol2_snackp.line7,top->drtol2_snack_line7);
        printf("ERROR: expected drtol2_snack_line6:%x but actual drtol2_snack_line6 is %x\n", drtol2_snackp.line6,top->drtol2_snack_line6);
        printf("ERROR: expected drtol2_snack_line5:%x but actual drtol2_snack_line5 is %x\n", drtol2_snackp.line5,top->drtol2_snack_line5);
        printf("ERROR: expected drtol2_snack_line4:%x but actual drtol2_snack_line4 is %x\n", drtol2_snackp.line4,top->drtol2_snack_line4);
        printf("ERROR: expected drtol2_snack_line3:%x but actual drtol2_snack_line3 is %x\n", drtol2_snackp.line3,top->drtol2_snack_line3);
        printf("ERROR: expected drtol2_snack_line2:%x but actual drtol2_snack_line2 is %x\n", drtol2_snackp.line2,top->drtol2_snack_line2);
        printf("ERROR: expected drtol2_snack_line1:%x but actual drtol2_snack_line1 is %x\n", drtol2_snackp.line1,top->drtol2_snack_line1);
        printf("ERROR: expected drtol2_snack_line0:%x but actual drtol2_snack_line0 is %x\n", drtol2_snackp.line0,top->drtol2_snack_line0);
        printf("ERROR: expected drtol2_snack_paddr:%x but actual drtol2_snack_paddr is %x\n", drtol2_snackp.paddr,top->drtol2_snack_paddr);
        error_found(top);
      }
    drtol2_snack_list.pop_back();
    count_drtol2_snack++;
}

double sc_time_stamp() {
  return 0;
}

int main(int argc, char **argv, char **env) {
  int i;
  int clk;
  Verilated::commandArgs(argc, argv);
  // init top verilog instance
  Vl2cache_pipe_wp* top = new Vl2cache_pipe_wp;

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
  top->l2todr_req_retry = 1;
  top->drtol2_snack_retry = 1;

  advance_clock(top,1);

#if 1
  for(int i =0;i<50;i++) {
    try_send_l1_to_l2_req_packet(top);
    try_send_l2_to_l1_snack_packet(top);
    advance_half_clock(top);
    try_receive_l2_to_dr_req_packet(top);
    try_recieve_dr_to_l2_snack_packet(top);
    advance_half_clock(top);

    if (((rand() & 0x3)==0) && l1tol2_req_list.size() < 3 ) {
      //L1tol2ReqPacket l1tol2_reqp = L1tol2ReqPacket();
      L1tol2ReqPacket l1tol2_reqp;
      l1tol2_reqp.dcid = rand() & 0x1F;
      l1tol2_reqp.cmd = rand() & 0x7;
      l1tol2_reqp.pcsign = rand() & 0x7FF;
      l1tol2_reqp.laddr = rand() & 0x7FFFFFFFFF;
      l1tol2_reqp.sptbr = rand() & 0x3FFFFFFFFF;
      l1tol2_req_list.push_front(l1tol2_reqp);
    }

    if(((rand() & 0x3)==0) && l2tol1_snack_list.size(0 < 3 ) {
      //L2toL1SnackPacket l2tol1_snackp = L2toL1SnackPacket();
      L2toL1SnackPacket l2tol1_snackp;
      l2tol1_snackp.dcid = rand() & 0x1F;
      l2tol1_snackp.l2id = rand() & 0x3F;
      l2tol1_snackp.snack = rand() & 0x1F;
      l2tol1_snackp.line7 = rand() & 0xFFFFFFFFFFFFFFFF;
      l2tol1_snackp.line6 = rand() & 0xFFFFFFFFFFFFFFFF;
      l2tol1_snackp.line5 = rand() & 0xFFFFFFFFFFFFFFFF;
      l2tol1_snackp.line4 = rand() & 0xFFFFFFFFFFFFFFFF;
      l2tol1_snackp.line3 = rand() & 0xFFFFFFFFFFFFFFFF;
      l2tol1_snackp.line2 = rand() & 0xFFFFFFFFFFFFFFFF;
      l2tol1_snackp.line2 = rand() & 0xFFFFFFFFFFFFFFFF;
      l2tol1_snackp.line0 = rand() & 0xFFFFFFFFFFFFFFFF;
      l2tol1_snackp.paddr = rand() & 0x3FFFFFFFFFFFF;
      l2tol1_snackp.dctlbe = rand() & 0x1F;
    }
  }
#endif
  printf("Test Statistics: l1tol2_req count: %d\n l2todr_req count: %d\n l2tol1_snack count: %d\n drtol2_snack count: %d\n",count_l1tol2_req, count_l2todr_req, count_l2tol1_snack, count_drtol2_snack);
  sim_finish(true);

}

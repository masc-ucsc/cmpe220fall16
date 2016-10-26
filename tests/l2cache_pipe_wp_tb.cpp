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
struct L1toL2ReqPacket { // input
    uint8_t dcid;
    uint8_t cmd;
    uint16_t pcsign;
    uint64_t laddr;
    uint64_t sptbr;
};

struct L2toDrReqPacket { // output
    uint8_t nid;
    uint8_t l2id;
    uint8_t cmd;
    uint64_t paddr;
};

struct L2toL1SnackPacket { // output
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

struct DrtoL2SnackPacket { // input
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

struct L1toL2SnoopAckPacket { // input
    uint8_t l2id;
};

struct L2toDrSnoopAckPacket { // output
    uint8_t l2id;
};

struct L1toL2DispPacket { // input
    uint8_t l1id;
    uint8_t l2id;
    uint64_t mask;
    uint8_t dcmd;
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

struct L2toDrDispPacket { // output
    uint8_t nid;
    uint8_t l2id;
    uint8_t drid;
    uint64_t mask;
    uint8_t dcmd;
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

struct L2toL1DackPacket { // output
    uint8_t l1id;
};

struct DrtoL2DackPacket { // input
    uint8_t nid;
    uint8_t l2id;
};

//

std::list<L1toL2ReqPacket> l1tol2_req_list;
std::list<L2toDrReqPacket> l2todr_req_list;
std::list<L2toL1SnackPacket> l2tol1_snack_list;
std::list<DrtoL2SnackPacket> drtol2_snack_list;
std::list<L1toL2SnoopAckPacket> l1tol2_snoop_ack_list;
std::list<L2toDrSnoopAckPacket> l2todr_snoop_ack_list;
std::list<L1toL2DispPacket> l1tol2_disp_list;
std::list<L2toDrDispPacket> l2todr_disp_list;
std::list<L2toL1DackPacket> l2tol1_dack_list;
std::list<DrtoL2DackPacket> drtol2_dack_list;
int count_l1tol2_req = 0;
int count_l2todr_req = 0;
int count_l2tol1_snack = 0;
int count_drtol2_snack = 0;
int count_l1tol2_snoop_ack = 0;
int count_l2todr_snoop_ack = 0;
int count_l1tol2_disp = 0;
int count_l2todr_disp = 0;
int count_l2tol1_dack = 0;
int count_drtol2_dack = 0;

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
        L1toL2ReqPacket l1tol2_reqp = l1tol2_req_list.back();
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
          L2toDrReqPacket l2todr_reqp;
          l2todr_reqp.nid = rand();
          l2todr_reqp.l2id = rand();
          l2todr_reqp.cmd = l1tol2_reqp.cmd;
          l2todr_reqp.paddr = l1tol2_reqp.laddr;
          l2todr_req_list.push_front(l2todr_reqp);
        }
        l1tol2_req_list.pop_back();
    }
}

void try_send_dr_to_l2_snack_packet (Vl2cache_pipe_wp *top) {
    top->drtol2_snack_retry = (rand()&0xF)==0; // randomly,
    if ( !top-> l2tol1_snack_retry ) {
        top->drtol2_snack_nid = rand();
        top->drtol2_snack_l2id = rand();
        top->drtol2_snack_drid = rand();
        top->drtol2_snack_snack = rand();
        top->drtol2_snack_line7 = rand();
        top->drtol2_snack_line6 = rand();
        top->drtol2_snack_line5 = rand();
        top->drtol2_snack_line4 = rand();
        top->drtol2_snack_line3 = rand();
        top->drtol2_snack_line2 = rand();
        top->drtol2_snack_line1 = rand();
        top->drtol2_snack_line0 = rand();
        top->drtol2_snack_paddr = rand();
        if (drtol2_snack_list.empty() || (rand() & 0x3==0)) { // Once every 4
          top->drto12_snack_valid = 0;
        }else{
          top->drtol2_snack_valid = 1;
        }
    }
    
    if (top->drtol2_snack_valid && !top->drtol2_snack_retry){
        if (drtol2_snack_list.empty()) {
            fprintf(stderr,"ERROR: Internal error, could not be empty drtol2_snack_list\n");
        }
        DrtoL2SnackPacket drtol2_snackp = drtol2_snack_list.back();
        count_drtol2_snack++;
        top->drtol2_snack_nid = drtol2_snackp.nid;
        top->drtol2_snack_l2id = drtol2_snackp.l2id;
        top->drtol2_snack_drid = drtol2_snackp.drid;
        top->drtol2_snack_snack = drtol2_snackp.snack;
        top->drtol2_snack_line7 = drtol2_snackp.line7;
        top->drtol2_snack_line6 = drtol2_snackp.line6;
        top->drtol2_snack_line5 = drtol2_snackp.line5;
        top->drtol2_snack_line4 = drtol2_snackp.line4;
        top->drtol2_snack_line3 = drtol2_snackp.line3;
        top->drtol2_snack_line2 = drtol2_snackp.line2;
        top->drtol2_snack_line1 = drtol2_snackp.line1;
        top->drtol2_snack_line0 = drtol2_snackp.line0;
        top->drtol2_snack_paddr = drtol2_snackp.paddr;
#ifdef DEBUG_TRACE
        printf("@%lld drtol2_snack nid:%x l2id:%x drid:%x snack:%d line7:%x line6:%x line5:%x line4:%x line3:%x line2:%x line1:%x line0:%x paddr:%x\n",global_time, drtol2_snackp.nid, drtol2_snackp.l2id, drtol2_snack.drid, drtol2_snackp.snack, drtol2_snackp.line7, drtol2_snackp.line6, drtol2_snackp.line5, drtol2_snackp.line4, drtol2_snackp.line3, drtol2_snackp.line2, drtol2_snackp.line1, drtol2_snackp.line0, drtol2_snackp.paddr);
#endif
        if (0) { // If it's write
                    // TODO
        }
        else{
          L2toL1SnackPacket l2tol1_snackp;
          l2tol1_snackp.dcid = rand();
          l2tol1_snackp.l2id = rand();
          l2tol1_snackp.snack = drtol2_snackp.snack;
          l2tol1_snackp.line7 = drtol2_snackp.line7;
          l2tol1_snackp.line6 = drtol2_snackp.line6;
          l2tol1_snackp.line5 = drtol2_snackp.line5;
          l2tol1_snackp.line4 = drtol2_snackp.line4;
          l2tol1_snackp.line3 = drtol2_snackp.line3;
          l2tol1_snackp.line2 = drtol2_snackp.line2;
          l2tol1_snackp.line1 = drtol2_snackp.line1;
          l2tol1_snackp.line0 = drtol2_snackp.line0;
          l2tol1_snackp.paddr = drtol2_snackp.paddr;
          l2tol1_snack_list.push_front(l2tol1_snackp);
        }
        drtol2_snack_list.pop_back();
    }
}

void try_send_l1_to_l2_snoop_ack_packet (Vl2cache_pipe_wp *top) {
    top->l2todr_snoop_ack_retry = (rand()&0xF)==0; // randomly,
    if ( !top-> l1tol2_snoop_ack_retry ) {
        top->l1tol2_snoop_ack_l2id = rand();
        if (l1tol2_snoop_ack_list.empty() || (rand() & 0x3==0)) { // Once every 4
          top->l1tol2_snoop_ack_valid = 0;
        }else{
          top->l1tol2_snoop_ack_valid = 1;
        }
    }
    
    if (top->l1tol2_snoop_ack_valid && !top->l1tol2_snoop_ack_retry){
        if (l1tol2_snoop_ack_list.empty()) {
            fprintf(stderr,"ERROR: Internal error, could not be empty l1tol2_snoop_ack_list\n");
        }
        L1toL2SnoopAckPacket l1tol2_snoop_ackp = l1tol2_snoop_ack_list.back();
        count_l1tol2_snoop_ack++;
        top->l1tol2_snoop_ack_l2id = l1tol2_snoop_ackp.l2id;
#ifdef DEBUG_TRACE
        printf("@%lld l1tol2_snoop_ack l2id:%x\n",global_time, l1tol2_snoop_ackp.l2id);
#endif
        if (0) { // If it's write
                    // TODO
        }
        else{
          L2toDrSnoopAckPacket l2todr_snoop_ackp;
          l2todr_reqp.l2id = rand();
        }
        l1tol2_snoop_ack_list.pop_back();
    }
}

void try_send_l1_to_l2_disp_packet (Vl2cache_pipe_wp *top) {
    top->l1tol2_disp_retry = (rand()&0xF)==0; // randomly,
    if ( !top-> l2todr_disp_retry ) {
        top->l1tol2_disp_l1id = rand();
        top->l1tol2_disp_l2id = rand();
        top->l1tol2_disp_mask = rand();
        top->l1tol2_disp_dcmd = rand();
        top->l1tol2_disp_line7 = rand();
        top->l1tol2_disp_line6 = rand();
        top->l1tol2_disp_line5 = rand();
        top->l1tol2_disp_line4 = rand();
        top->l1tol2_disp_line3 = rand();
        top->l1tol2_disp_line2 = rand();
        top->l1tol2_disp_line1 = rand();
        top->l1tol2_disp_line0 = rand();
        top->l1tol2_sdisp_paddr = rand();
        if (l1tol2_disp_list.empty() || (rand() & 0x3==0)) { // Once every 4
          top->l1to12_disp_valid = 0;
        }else{
          top->l1tol2_disp_valid = 1;
        }
    }
    
    if (top->l1tol2_disp_valid && !top->l1tol2_disp_retry){
        if (l1tol2_disp_list.empty()) {
            fprintf(stderr,"ERROR: Internal error, could not be empty l1tol2_disp_list\n");
        }
        L1toL2DispPacket l1tol2_dispp = l1tol2_disp_list.back();
        count_l1tol2_disp++;
        top->l1tol2_disp_l1id = l1tol2_dispp.l1id;
        top->l1tol2_disp_l2id = l1tol2_dispp.l2id;
        top->l1tol2_disp_mask = l1tol2_dispp.mask;
        top->l1tol2_disp_dcmd = l1tol2_dispp.dcmd;
        top->l1tol2_disp_line7 = l1tol2_dispp.line7;
        top->l1tol2_disp_line6 = l1tol2_dispp.line6;
        top->l1tol2_disp_line5 = l1tol2_dispp.line5;
        top->l1tol2_disp_line4 = l1tol2_dispp.line4;
        top->l1tol2_disp_line3 = l1tol2_dispp.line3;
        top->l1tol2_disp_line2 = l1tol2_dispp.line2;
        top->l1tol2_disp_line1 = l1tol2_dispp.line1;
        top->l1tol2_disp_line0 = l1tol2_dispp.line0;
        top->l1tol2_disp_paddr = l1tol2_dispp.paddr;
#ifdef DEBUG_TRACE
        printf("@%lld l1tol2_disp l1id:%x l2id:%x mask:%x dcmd:%d line7:%x line6:%x line5:%x line4:%x line3:%x line2:%x line1:%x line0:%x paddr:%x\n",global_time, l1tol2_dispp.l1id, l1tol2_dispp.l2id, l1tol2_dispp.mask, l1tol2_dispp.dcmd, l1tol2_dispp.line7, l1tol2_dispp.line6, l1tol2_dispp.line5, l1tol2_dispp.line4, l1tol2_dispp.line3, l1tol2_dispp.line2, l1tol2_dispp.line1, l1tol2_dispp.line0, l1tol2_dispp.paddr);
#endif
        if (0) { // If it's write
                    // TODO
        }
        else{
          L2toDrDispPacket l2todr_dispp;
          l2todr_dispp.nid = rand();
          l2todr_dispp.l2id = rand();
          l2todr_dispp.drid = rand();
          l2todr_dispp.mask = l1tol2_dispp.mask;
          l2todr_dispp.dcmd = l1tol2_dispp.dcmd
          l2todr_dispp.line7 = l1tol2_dispp.line7;
          l2todr_dispp.line6 = l1tol2_dispp.line6;
          l2todr_dispp.line5 = l1tol2_dispp.line5;
          l2todr_dispp.line4 = l1tol2_dispp.line4;
          l2todr_dispp.line3 = l1tol2_dispp.line3;
          l2todr_dispp.line2 = l1tol2_dispp.line2;
          l2todr_dispp.line1 = l1tol2_dispp.line1;
          l2todr_dispp.line0 = l1tol2_dispp.line0;
          l2todr_dispp.paddr = l1tol2_dispp.paddr;
          l2todr_disp_list.push_front(l2todr_dispp);
        }
        l1tol2_disp_list.pop_back();
    }
}

void try_send_dr_to_l2_dack_packet (Vl2cache_pipe_wp *top) {
    top->l2tol1_dack_retry = (rand()&0xF)==0; // randomly,
    if ( !top-> drtol2_dack_retry ) {
        top->drtol2_dack_nid = rand();
        top->drtol2_dack_l2id = rand();
        if (drtol2_dack_list.empty() || (rand() & 0x3==0)) { // Once every 4
          top->drtol2_dack_valid = 0;
        }else{
          top->drtol2_dack_valid = 1;
        }
    }
    
    if (top->drtol2_dack_valid && !top->drtol2_dack_retry){
        if (drtol2_dack_list.empty()) {
            fprintf(stderr,"ERROR: Internal error, could not be empty drtol2_dack_list\n");
        }
        DrtoL2DackPacket drtol2_dackp = drtol2_dack_list.back();
        count_drtol2_dack++;
        top->drtol2_dack_nid = drtol2_dack.nid;
        top->drtol2_dack_l2id = drtol2_dack.l2id;
#ifdef DEBUG_TRACE
        printf("@%lld drtol2_dack nid:%x l2id:%x\n",global_time, drtol2_dackp.nid, drtol2_dack.l2id);
#endif
        if (0) { // If it's write
                    // TODO
        }
        else{
          L2toL1DackPacket l2tol1_dackp;
          l2tol1_reqp.l1id = rand();
        }
        drtol2_dack_list.pop_back();
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
    L2toDrReqPacket l2todr_reqp = l2todr_req_list.back();
    if (top->l2todr_req_cmd != l2todr_reqp.cmd ||
          top->l2todr_req_paddr != l2todr_reqp.paddr) {
        printf("ERROR: expected l2todr_req_cmd:%x but actual l2todr_req_cmd is %x\n", l2todr_reqp.cmd,top->l2todr_req_cmd);
        printf("ERROR: expected l2todr_req_paddr:%x but actual l2todr_req_paddr is %x\n", l2todr_reqp.paddr,top->l2todr_req_paddr);
        error_found(top);
      }
    l2todr_req_list.pop_back();
    count_l2todr_req++;
}

void try_receive_l2_to_l1_snack_packet (Vl2cache_pipe_wp *top) {
    if(top->l2tol1_snack_valid && l2tol1_snack_list.empty()){
        printf("ERROR: unexpected l2tol1_snack dcid:%x l2id:%x snack:%x line7:%x line6:%x line5:%x line4:%x line3:%x line2:%x line1:%x line0:%x paddr:%x dctlbe:%x\n",top->l2tol1_snack_dcid, top->l2tol1_snack_l2id, top->l2tol1_snack_snack, top->l2tol1_snack_line7, top->l2tol1_snack_line6, top->l2tol1_snack_line5, top->l2tol1_snack_line4, top->l2tol1_snack_line3, top->l2tol1_snack_line2, top->l2tol1_snack_line1, top->l2tol1_snack_line0, top->l2tol1_snack_paddr, top->l2tol1_snack_dctlbe);
        error_found(top);
        return;
    }

    if (top->l2tol1_snack_retry) {
        return;
    }

    if (!top->l2tol1_snack_valid) {
        return;
    }
    
    if (l2tol1_snack_list.empty())
        return;

    #ifdef DEBUG_TRACE
    printf("@%lld l2tol1_req dcid:%x l2id:%x snack:%x line7:%x line6:%x line5:%x line4:%x line3:%x line2:%x line1:%x line0:%x paddr:%x dctlbe:%x\n",global_time, top->l2tol1_snack_dcid, top->l2tol1_req_l2id, top->l2tol1_snack_snack, top->l2tol1_snack_line7, top->l2tol1_snack_line6, top->l2tol1_snack_line5, top->l2tol1_snack_line4, top->l2tol1_snack_line3, top->l2tol1_snack_line2, top->l2tol1_snack_line1, top->l2tol1_snack_line0, top->l2tol1_snack_paddr, l2tol1_snack_dctlbe);

    #endif
    L2toL1SnackPacket l2tol1_snackp = l2tol1_snack_list.back();
    if (top->l2tol1_snack_snack != l2tol1_snackp.snack ||
        top->l2tol1_snack_line7 != l2tol1_snackp.line7 ||
        top->l2tol1_snack_line6 != l2tol1_snackp.line6 ||
        top->l2tol1_snack_line5 != l2tol1_snackp.line5 ||
        top->l2tol1_snack_line4 != l2tol1_snackp.line4 ||
        top->l2tol1_snack_line3 != l2tol1_snackp.line3 ||
        top->l2tol1_snack_line2 != l2tol1_snackp.line2 ||
        top->l2tol1_snack_line1 != l2tol1_snackp.line1 ||
        top->l2tol1_snack_line0 != l2tol1_snackp.line0 ||
        top->l2tol1_snack_paddr != l2tol1_snackp.paddr ||
        top->l2tol1_snack_dctlbe != l2tol1_snackp.dctlbe) {
        printf("ERROR: expected l2tol1_snack_snack:%x but actual l2tol1_snack_snack is %x\n", l2tol1_snackp.snack,top->l2tol1_snack_snack);
        printf("ERROR: expected l2tol1_snack_line7:%x but actual l2tol1_snack_line7 is %x\n", l2tol1_snackp.line7,top->l2tol1_snack_line7);
        printf("ERROR: expected l2tol1_snack_line6:%x but actual l2tol1_snack_line6 is %x\n", l2tol1_snackp.line6,top->l2tol1_snack_line6);
        printf("ERROR: expected l2tol1_snack_line5:%x but actual l2tol1_snack_line5 is %x\n", l2tol1_snackp.line5,top->l2tol1_snack_line5);
        printf("ERROR: expected l2tol1_snack_line4:%x but actual l2tol1_snack_line4 is %x\n", l2tol1_snackp.line4,top->l2tol1_snack_line4);
        printf("ERROR: expected l2tol1_snack_line3:%x but actual l2tol1_snack_line3 is %x\n", l2tol1_snackp.line3,top->l2tol1_snack_line3);
        printf("ERROR: expected l2tol1_snack_line2:%x but actual l2tol1_snack_line2 is %x\n", l2tol1_snackp.line2,top->l2tol1_snack_line2);
        printf("ERROR: expected l2tol1_snack_line1:%x but actual l2tol1_snack_line1 is %x\n", l2tol1_snackp.line1,top->l2tol1_snack_line1);
        printf("ERROR: expected l2tol1_snack_line0:%x but actual l2tol1_snack_line0 is %x\n", l2tol1_snackp.line0,top->l2tol1_snack_line0);
        printf("ERROR: expected l2tol1_snack_paddr:%x but actual l2tol1_snack_paddr is %x\n", l2tol1_snackp.paddr,top->l2tol1_snack_paddr);
        printf("ERROR: expected l2tol1_snack_dctlbe:%x but actual l2tol1_snack_dctlbe is %x\n", l2tol1_snackp.dctlbe,top->l2tol1_snack_dctlbe);
        error_found(top);
      }
    l2tol1_snack_list.pop_back();
    count_l2tol1_snack++;
}

void try_receive_l2_to_dr_snoop_ack_packet (Vl2cache_pipe_wp *top) {
    if(top->l2todr_snoop_ack_valid && l2todr_snoop_ack_list.empty()){
        printf("ERROR: unexpected l2todr_snoop_ack l2id:%x\n",top->l2todr_snoop_ack_l2id);
        error_found(top);
        return;
    }

    if (top->l2todr_snoop_ack_retry) {
        return;
    }

    if (!top->l2todr_snoop_ack_valid) {
        return;
    }
    
    if (l2todr_snoop_ack_list.empty())
        return;

    #ifdef DEBUG_TRACE
    printf("@%lld l2todr_snoop_ack l2id:%x\n",global_time, top->l2todr_snoop_ack_l2id);

    #endif
    L2toDrSnoopAckPacket l2todr_snoop_ackp = l2todr_snoop_ack_list.back();

    l2todr_snoop_ack_list.pop_back();
    count_l2todr_snoop_ack++;
}

void try_receive_l2_to_dr_disp_packet (Vl2cache_pipe_wp *top) {
    if(top->l2todr_disp_valid && l2todr_disp_list.empty()){
        printf("ERROR: unexpected l2todr_disp nid:%x l2id:%x drid:%x mask:%x dcmd:%x line7:%x line6:%x line5:%x line4:%x line3:%x line2:%x line1:%x line0:%x paddr:%x\n",top->l2todr_disp_nid, top->l2todr_disp_l2id, top->l2todr_disp_drid, top->l2todr_disp_mask, top->l2todr_disp_dcmd, top->l2todr_disp_line7, top->l2todr_disp_line6, top->l2todr_disp_line5, top->l2todr_disp_line4, top->l2todr_disp_line3, top->l2todr_disp_line2, top->l2todr_disp_line1, top->l2todr_disp_line0, top->l2todr_disp_paddr);
        error_found(top);
        return;
    }

    if (top->l2todr_disp_retry) {
        return;
    }

    if (!top->l2todr_disp_valid) {
        return;
    }
    
    if (l2todr_disp_list.empty())
        return;

    #ifdef DEBUG_TRACE
    printf("@%lld l2todr_disp nid:%x l2id:%x drid:%x mask:%x dcmd:%x line7:%x line6:%x line5:%x line4:%x line3:%x line2:%x line1:%x line0:%x paddr:%x\n",global_time, top->l2todr_disp_nid, top->l2todr_disp_l2id, top->l2todr_disp_drid, top->l2todr_disp_mask, top->l2todr_disp_dcmd, top->l2todr_disp_line7, top->l2todr_disp_line6, top->l2todr_disp_line5, top->l2todr_disp_line4, top->l2todr_disp_line3, top->l2todr_disp_line2, top->l2todr_disp_line1, top->l2todr_disp_line0, top->l2todr_disp_paddr);

    #endif
    L2toDrDispPacket l2todr_dispp = l2todr_disp_list.back();
    if (top->l2todr_disp_mask != l2todr_dispp.mask   ||
        top->l2todr_disp_dcmd != l2todr_dispp.dcmd   ||
        top->l2todr_disp_line7 != l2todr_dispp.line7 ||
        top->l2todr_disp_line6 != l2todr_dispp.line6 ||
        top->l2todr_disp_line5 != l2todr_dispp.line5 ||
        top->l2todr_disp_line4 != l2todr_dispp.line4 ||
        top->l2todr_disp_line3 != l2todr_dispp.line3 ||
        top->l2todr_disp_line2 != l2todr_dispp.line2 ||
        top->l2todr_disp_line1 != l2todr_dispp.line1 ||
        top->l2todr_disp_line0 != l2todr_dispp.line0 ||
        top->l2todr_disp_paddr != l2todr_dispp.paddr ) {
        printf("ERROR: expected l2todr_disp_mask:%x but actual l2todr_disp_mask is %x\n", l2todr_dispp.mask,top->l2todr_disp_mask);
        printf("ERROR: expected l2todr_disp_dcmd:%x but actual l2todr_disp_dcmd is %x\n", l2todr_dispp.dcmd,top->l2todr_disp_dcmd);
        printf("ERROR: expected l2todr_disp_line7:%x but actual l2todr_disp_line7 is %x\n", l2todr_dispp.line7,top->l2todr_disp_line7);
        printf("ERROR: expected l2todr_disp_line6:%x but actual l2todr_disp_line6 is %x\n", l2todr_dispp.line6,top->l2tol1_snack_line6);
        printf("ERROR: expected l2todr_disp_line5:%x but actual l2todr_disp_line5 is %x\n", l2todr_dispp.line5,top->l2tol1_snack_line5);
        printf("ERROR: expected l2todr_disp_line4:%x but actual l2todr_disp_line4 is %x\n", l2todr_dispp.line4,top->l2tol1_snack_line4);
        printf("ERROR: expected l2todr_disp_line3:%x but actual l2todr_disp_line3 is %x\n", l2todr_dispp.line3,top->l2tol1_snack_line3);
        printf("ERROR: expected l2todr_disp_line2:%x but actual l2todr_disp_line2 is %x\n", l2todr_dispp.line2,top->l2tol1_snack_line2);
        printf("ERROR: expected l2todr_disp_line1:%x but actual l2todr_disp_line1 is %x\n", l2todr_dispp.line1,top->l2tol1_snack_line1);
        printf("ERROR: expected l2todr_disp_line0:%x but actual l2todr_disp_line0 is %x\n", l2todr_dispp.line0,top->l2tol1_snack_line0);
        printf("ERROR: expected l2todr_disp_paddr:%x but actual l2todr_disp_paddr is %x\n", l2todr_dispp.paddr,top->l2tol1_snack_paddr);
        error_found(top);
      }
    l2todr_disp_list.pop_back();
    count_l2todr_disp++;
}

void try_receive_l2_to_l1_dack_packet (Vl2cache_pipe_wp *top) {
    if(top->l2tol1_dack_valid && l2tol1_dack_list.empty()){
        printf("ERROR: unexpected l2tol1_dack l1id:%x\n",top->l2tol1_dack_l1id);
        error_found(top);
        return;
    }

    if (top->l2tol1_dack_retry) {
        return;
    }

    if (!top->l2tol1_dack_valid) {
        return;
    }
    
    if (l2tol1_dack_list.empty())
        return;

    #ifdef DEBUG_TRACE
    printf("@%lld l2tol1_dack l1id:%x\n",global_time, top->l2tol1_dack_l2id);

    #endif
    L2toL1DackPacket l2tol1_dackp = l2tol1_dack_list.back();

    l2tol1_dack_list.pop_back();
    count_l2tol1_dack++;
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
    try_send_dr_to_l2_snack_packet(top);
    try_send_l1_to_l2_snoop_ack_packet(top);
    advance_half_clock(top);
    try_receive_l2_to_dr_req_packet(top);
    try_receive_l2_to_l1_snack_packet(top);
    try_receive_l2_to_dr_snoop_ack_packet(top);
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

    if(((rand() & 0x3)==0) && drtol2_snack_list.size(0 < 3 ) {
      //DrtoL2SnackPacket drtol2_snackp = DrtoL2SnackPacket();
      DrtoL2SnackPacket drtol2_snackp;
      drtol2_snackp.nid = rand() & 0x1F;
      drtol2_snackp.l2id = rand() & 0x3F;
      drtol2_snackp.drid = rand() & 0x3F;
      drtol2_snackp.snack = rand() & 0x1F;
      drtol2_snackp.line7 = rand() & 0xFFFFFFFFFFFFFFFF;
      drtol2_snackp.line6 = rand() & 0xFFFFFFFFFFFFFFFF;
      drtol2_snackp.line5 = rand() & 0xFFFFFFFFFFFFFFFF;
      drtol2_snackp.line4 = rand() & 0xFFFFFFFFFFFFFFFF;
      drtol2_snackp.line3 = rand() & 0xFFFFFFFFFFFFFFFF;
      drtol2_snackp.line2 = rand() & 0xFFFFFFFFFFFFFFFF;
      drtol2_snackp.line2 = rand() & 0xFFFFFFFFFFFFFFFF;
      drtol2_snackp.line0 = rand() & 0xFFFFFFFFFFFFFFFF;
      drtol2_snackp.paddr = rand() & 0x3FFFFFFFFFFFF;
    }

    if (((rand() & 0x3)==0) && l1tol2_snoop_ack_list.size() < 3 ) {
      //L1tol2SnoopAckPacket l1tol2_snoop_ackp = L1tol2SnoopAckPacket();
      L1tol2SnoopAckPacket l1tol2_snoop_ackp;
      l1tol2_snoop_ackp.l2id = rand() & 0x3F;
      l1tol2_snoop_ack_list.push_front(l1tol2_snoop_ackp);
    }

    if(((rand() & 0x3)==0) && l1tol2_disp_list.size(0 < 3 ) {
      //L1toL2DispPacket l1tol2_dispp = L1toL2DispPacket();
      L1toL2DispPacket l1tol2_dispp;
      l1tol2_dispp.l1id = rand() & 0x1F;
      l1tol2_dispp.l2id = rand() & 0x3F;
      l1tol2_dispp.mask = rand() & 0xFFFFFFFFFFFFFFFF;
      l1tol2_dispp.dcmd = rand() & 0x7;
      l1tol2_dispp.line7 = rand() & 0xFFFFFFFFFFFFFFFF;
      l1tol2_dispp.line6 = rand() & 0xFFFFFFFFFFFFFFFF;
      l1tol2_dispp.line5 = rand() & 0xFFFFFFFFFFFFFFFF;
      l1tol2_dispp.line4 = rand() & 0xFFFFFFFFFFFFFFFF;
      l1tol2_dispp.line3 = rand() & 0xFFFFFFFFFFFFFFFF;
      l1tol2_dispp.line2 = rand() & 0xFFFFFFFFFFFFFFFF;
      l1tol2_dispp.line2 = rand() & 0xFFFFFFFFFFFFFFFF;
      l1tol2_dispp.line0 = rand() & 0xFFFFFFFFFFFFFFFF;
      l1tol2_dispp.paddr = rand() & 0x3FFFFFFFFFFFF;
    }

    if (((rand() & 0x3)==0) && drtol2_dack_list.size() < 3 ) {
      //Drtol2DackPacket drtol2_dackp = Drtol2DackPacket();
      Drtol2DackPacket drtol2_dackp;
      drtol2_dackp.nid = rand() & 0x1F;
      drtol2_dackp.l2id = rand() & 0x3F;
      drtol2_dack_list.push_front(drtol2_dackp);
    }
  }
#endif
  printf("Test Statistics: l1tol2_req count: %d\n l2todr_req count: %d\n l2tol1_snack count: %d\n drtol2_snack count: %d\n l1tol2_snoop_ack count: %d\n l2todr_snoop_ack count %d\n l1tol2_disp count: %d\n l2todr_disp count: %d\n l2tol1_dack count: %d\n drtol2_dack count: %d\n",count_l1tol2_req, count_l2todr_req, count_l2tol1_snack, count_drtol2_snack, count_l1tol2_snoop_ack, count_l2todr_snoop_ack, count_l1tol2_disp, count_l2todr_disp, count_l2tol1_dack, count_drtol2_dack);
  sim_finish(true);

}

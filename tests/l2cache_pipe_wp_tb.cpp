#include "Vl2cache_pipe_wp.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <list>

#include <time.h>
#include <math.h>

#define DEBUG_TRACE 1
#define L2_128KB

//#define PASS_THROUGH

vluint64_t global_time = 0;
VerilatedVcdC* tfp = 0;

// At each mem addr, a mem_element is stored
class MemElement {
public:
    // Cache line
    uint64_t line7;
    uint64_t line6;
    uint64_t line5;
    uint64_t line4;
    uint64_t line3;
    uint64_t line2;
    uint64_t line1;
    uint64_t line0;

    // Full Physical Address
    uint64_t full_paddr;

    // L1 hashed Tag
    // Directory hash
    // Current status: Invalid, Shared, Exclusive, ...
    // For write_req return only
    int if_eviction = 0;
};

class MemSet {
public:
    int num_ways = 16;
    MemElement * mem_elements;
    int way_access_count = 0;
    uint8_t * way_bitmap;
    uint8_t fifo_evict_pointer = 0;
    MemSet () {
        mem_elements = new MemElement [num_ways];
        way_bitmap = new uint8_t [num_ways];
        for (int i=0; i<=num_ways; i++) {
            way_bitmap[i] = 0;
        }
    }
};

class Mem {
#ifdef L2_128KB
    uint64_t mem_size_of_sets = pow(2,7); // calculate num of total sets
#endif
public:
    MemSet * mem_sets;
    Mem () {
        mem_sets = new MemSet [mem_size_of_sets];
    }

    // This is invoked when there is a drtol2_snack with data
    MemElement write_req (uint64_t paddr, MemElement mem_element) {
        printf("write_req invoked\n");
        printf("paddr is %llx\n", paddr);

        MemElement return_mem_element;
        uint16_t set_addr = (paddr >> 6) & 0x7F;
        mem_sets[set_addr].way_access_count++;
        printf("way_access_count is %d\n", mem_sets[set_addr].way_access_count);
        printf("set_addr is %x\n", set_addr);
        if (set_addr > this->mem_size_of_sets) {
            fprintf(stderr,"ERROR: set_addr (%x) > mem_size_of_sets (%x) \n", set_addr, mem_size_of_sets);            
        }
        else {
            /*
            const uint8_t one_bit[8];
            one_bit[0] = 0x1;
            one_bit[1] = 0x2;
            one_bit[2] = 0x4;
            one_bit[3] = 0x8;
            one_bit[4] = 0x1;
            one_bit[5] = 0x1;
            one_bit[6] = 0x1;
            one_bit[7] = 0x1;
            */
            int if_got_way = 0;
            for (int i=0; i<=(mem_sets[set_addr].num_ways); i++) {
                if ((mem_sets[set_addr].way_bitmap[i]) == 0x0) {
                // There is an empty way
                    mem_sets[set_addr].way_bitmap[i] = 0x1;
                    mem_sets[set_addr].mem_elements[i] = mem_element;
                    if_got_way = 1;
                    break;
                }
            }
            if (if_got_way == 0) {
                // Have to evict a way
                uint32_t fifo_evict_pointer = mem_sets[set_addr].fifo_evict_pointer;
                mem_sets[set_addr].way_bitmap[fifo_evict_pointer] = 0x1;
                // Evict First
                printf("Eviction Happens!\n");
                return_mem_element = mem_sets[set_addr].mem_elements[fifo_evict_pointer];
                return_mem_element.if_eviction = 1;
                if (mem_sets[set_addr].fifo_evict_pointer+1 <= 0x15) {
                    mem_sets[set_addr].fifo_evict_pointer++;
                }
                else {
                    mem_sets[set_addr].fifo_evict_pointer = 0;
                }

                // Then replace
                mem_sets[set_addr].mem_elements[fifo_evict_pointer] = mem_element;
            }
        }
        return return_mem_element;
    } // End of write_req
}; // End of class Mem

// Global
Mem mem;


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
    uint8_t l1id;
    uint8_t cmd;
    uint16_t pcsign;
    uint64_t ppaddr;
};

struct L2toDrReqPacket { // output
    uint8_t nid;
    uint8_t l2id;
    uint8_t cmd;
    uint64_t paddr;
};

struct L2toL1SnackPacket { // output
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

struct DrtoL2SnackPacket { // input
    uint8_t nid;
    uint8_t l2id;
    uint8_t drid;
    uint8_t directory_id;
    uint8_t snack;
    uint64_t line7;
    uint64_t line6;
    uint64_t line5;
    uint64_t line4;
    uint64_t line3;
    uint64_t line2;
    uint64_t line1;
    uint64_t line0;
    uint8_t hpaddr_base;
    uint8_t hpaddr_hash;
    uint64_t paddr;
};

struct L1toL2SnoopAckPacket { // input
    uint8_t l2id;
    uint8_t directory_id;
};

struct L2toDrSnoopAckPacket { // output
    uint8_t l2id;
    uint8_t directory_id;    
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
    uint8_t ppaddr;
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

struct L2tlbtoL2FwdPacket {
    uint8_t l1id;
    uint8_t prefetch;
    uint8_t fault;
    uint16_t hpaddr;
    uint64_t paddr;
};

struct L2toDrPfreqPacket {
    uint8_t nid;
    uint64_t paddr;
};

//

std::list<L1toL2ReqPacket> l1tol2_req_list;
std::list<L2toDrReqPacket> l2todr_req_list;

std::list<L2toL1SnackPacket> l2tol1_ack_only_list;
std::list<L2toL1SnackPacket> l2tol1_snoop_only_list;

std::list<DrtoL2SnackPacket> drtol2_ack_only_list;
std::list<DrtoL2SnackPacket> drtol2_snoop_only_list;

std::list<L1toL2SnoopAckPacket> l1tol2_snoop_ack_list;
std::list<L2toDrSnoopAckPacket> l2todr_snoop_ack_list;
std::list<L1toL2DispPacket> l1tol2_disp_list;
std::list<L2toDrDispPacket> l2todr_disp_list;
std::list<L2toL1DackPacket> l2tol1_dack_list;
std::list<DrtoL2DackPacket> drtol2_dack_list;
std::list<L2tlbtoL2FwdPacket> l2tlbtol2_fwd_list;
std::list<L2toDrPfreqPacket> l2todr_pfreq_list;
int count_l1tol2_req = 0;
int count_l2todr_req = 0;
int count_l2tol1_snoop_only = 0;
int count_l2tol1_ack_only = 0;

int count_drtol2_ack_only = 0;
int count_drtol2_snoop_only = 0;
int count_l1tol2_snoop_ack = 0;
int count_l2todr_snoop_ack = 0;
int count_l1tol2_disp = 0;
int count_l2todr_disp = 0;
int count_l2tol1_dack = 0;
int count_drtol2_dack = 0;
int count_l2tlbtol2_fwd = 0;
int count_l2todr_pfreq = 0;

void error_found(Vl2cache_pipe_wp *top) {
  advance_half_clock(top);
  advance_half_clock(top);
  sim_finish(false);
}

void try_send_l1_to_l2_req_packet (Vl2cache_pipe_wp *top) {
    //Try to add some noise when there is not drive
    top->l2todr_req_retry = (rand()&0xF)==0; // randomly,
    if ( !top-> l1tol2_req_retry ) {
        top->l1tol2_req_l1id = rand();
        top->l1tol2_req_cmd = rand();
        top->l1tol2_req_pcsign = rand();
        top->l1tol2_req_ppaddr = rand();
        if (l1tol2_req_list.empty() || (rand() & 0x3==0)) { // Once every 4
          top->l1tol2_req_valid = 0;
        }else{
          top->l1tol2_req_valid = 1;
        }
    }
    
    // Drive signals
    if (top->l1tol2_req_valid && !top->l1tol2_req_retry){
        if (l1tol2_req_list.empty()) {
            fprintf(stderr,"ERROR: Internal error, could not be empty l1tol2_req_list\n");
        }
        L1toL2ReqPacket l1tol2_reqp = l1tol2_req_list.back();
        count_l1tol2_req++;
        top->l1tol2_req_l1id = l1tol2_reqp.l1id;
        top->l1tol2_req_cmd = l1tol2_reqp.cmd;
        top->l1tol2_req_pcsign = l1tol2_reqp.pcsign;
        top->l1tol2_req_ppaddr = l1tol2_reqp.ppaddr;
#ifdef DEBUG_TRACE
        printf("@%lld l1tol2_req l1id:%x cmd:%x pcsign:%d ppaddr:%x\n",global_time, l1tol2_reqp.l1id, 
            l1tol2_reqp.cmd, l1tol2_reqp.pcsign, l1tol2_reqp.ppaddr);
#endif
        if (0) { // If it's write
                    // TODO
        }
        else{
          // Generated 1st reference result: l2todr_req
          L2toDrReqPacket l2todr_reqp;
          l2todr_reqp.nid = rand();
          l2todr_reqp.l2id = rand();
          l2todr_reqp.cmd = l1tol2_reqp.cmd;
          // l2todr_reqp.paddr = l1tol2_reqp.laddr;
          l2todr_req_list.push_front(l2todr_reqp);

          // Generated following response: drtol2_snack
        DrtoL2SnackPacket drtol2_snackp;
        drtol2_snackp.nid = l2todr_reqp.nid;
      drtol2_snackp.l2id = l2todr_reqp.l2id;
      drtol2_snackp.drid = rand() & 0x3F;
      drtol2_snackp.snack = rand() & 0x1F & 0x0F; // Make sure this is an ack
      drtol2_snackp.line7 = rand() & 0xFFFFFFFFFFFFFFFF;
      drtol2_snackp.line6 = rand() & 0xFFFFFFFFFFFFFFFF;
      drtol2_snackp.line5 = rand() & 0xFFFFFFFFFFFFFFFF;
      drtol2_snackp.line4 = rand() & 0xFFFFFFFFFFFFFFFF;
      drtol2_snackp.line3 = rand() & 0xFFFFFFFFFFFFFFFF;
      drtol2_snackp.line2 = rand() & 0xFFFFFFFFFFFFFFFF;
      drtol2_snackp.line2 = rand() & 0xFFFFFFFFFFFFFFFF;
      drtol2_snackp.line0 = rand() & 0xFFFFFFFFFFFFFFFF;
      drtol2_snackp.paddr = rand() & 0x3FFFFFFFFFFFF;
      drtol2_ack_only_list.push_front(drtol2_snackp);
#ifdef DEBUG_TRACE
        printf("@%lld drtol2_snack nid:%x l2id:%x drid:%x snack:%x line7:%x line6:%x line5:%x line4:%x line3:%x line2:%x line1:%x line0:%x paddr:%x\n",global_time, drtol2_snackp.nid, drtol2_snackp.l2id, drtol2_snackp.drid, drtol2_snackp.snack, drtol2_snackp.line7, drtol2_snackp.line6, drtol2_snackp.line5, drtol2_snackp.line4, drtol2_snackp.line3, drtol2_snackp.line2, drtol2_snackp.line1, drtol2_snackp.line0, drtol2_snackp.paddr);
#endif
        }
        l1tol2_req_list.pop_back();
    }
}

void try_send_dr_to_l2_snack_packet (Vl2cache_pipe_wp *top) {
    //Try to add some noise when there is not drive    
    top->l2tol1_snack_retry = (rand()&0xF)==0; // randomly,
    if ( !top-> drtol2_snack_retry ) {
        top->drtol2_snack_nid = rand();
        top->drtol2_snack_l2id = rand();
        top->drtol2_snack_drid = rand();
        top->drtol2_snack_directory_id = rand();
        top->drtol2_snack_snack = rand();
        top->drtol2_snack_line7 = rand();
        top->drtol2_snack_line6 = rand();
        top->drtol2_snack_line5 = rand();
        top->drtol2_snack_line4 = rand();
        top->drtol2_snack_line3 = rand();
        top->drtol2_snack_line2 = rand();
        top->drtol2_snack_line1 = rand();
        top->drtol2_snack_line0 = rand();
        top->drtol2_snack_hpaddr_base = rand();
        top->drtol2_snack_hpaddr_hash = rand();
        top->drtol2_snack_paddr = rand();
        if ((drtol2_snoop_only_list.empty() && drtol2_ack_only_list.empty()) || (rand() & 0x3==0)) { // Once every 4
          top->drtol2_snack_valid = 0;
        }else{
          top->drtol2_snack_valid = 1;
        }
    }
    
    if (top->drtol2_snack_valid && !top->drtol2_snack_retry){
        DrtoL2SnackPacket drtol2_snackp;
        int snoop_or_ack; // -1: snoop; +1: ack
        // Send packet from drtol2_ack_only_list first
        if (drtol2_ack_only_list.empty() == 0) {
            snoop_or_ack = 1;
            drtol2_snackp = drtol2_ack_only_list.back();
            count_drtol2_ack_only++;
#ifndef PASS_THROUGH
            MemElement mem_element;
            mem_element.line7 = drtol2_snackp.line7;
            mem_element.line6 = drtol2_snackp.line6;
            mem_element.line5 = drtol2_snackp.line5;
            mem_element.line4 = drtol2_snackp.line4;
            mem_element.line3 = drtol2_snackp.line3;
            mem_element.line2 = drtol2_snackp.line2;
            mem_element.line1 = drtol2_snackp.line1;
            mem_element.line0 = drtol2_snackp.line0;

            mem.write_req(drtol2_snackp.paddr, mem_element);
#endif
        }
        else if (drtol2_snoop_only_list.empty()) {
            fprintf(stderr,"ERROR: Internal error, could not be empty drtol2_snack_list\n");
        }
        // Then Send packet from drtol2_snoop_only_list
        else{
            snoop_or_ack = -1;
            drtol2_snackp = drtol2_snoop_only_list.back();
            count_drtol2_snoop_only++;
        }
        top->drtol2_snack_nid = drtol2_snackp.nid;
        top->drtol2_snack_l2id = drtol2_snackp.l2id;
        top->drtol2_snack_drid = drtol2_snackp.drid;
        top->drtol2_snack_directory_id = drtol2_snackp.directory_id;
        top->drtol2_snack_snack = drtol2_snackp.snack;
        top->drtol2_snack_line7 = drtol2_snackp.line7;
        top->drtol2_snack_line6 = drtol2_snackp.line6;
        top->drtol2_snack_line5 = drtol2_snackp.line5;
        top->drtol2_snack_line4 = drtol2_snackp.line4;
        top->drtol2_snack_line3 = drtol2_snackp.line3;
        top->drtol2_snack_line2 = drtol2_snackp.line2;
        top->drtol2_snack_line1 = drtol2_snackp.line1;
        top->drtol2_snack_line0 = drtol2_snackp.line0;
        top->drtol2_snack_hpaddr_base = drtol2_snackp.hpaddr_base;
        top->drtol2_snack_hpaddr_hash = drtol2_snackp.hpaddr_hash;
        top->drtol2_snack_paddr = drtol2_snackp.paddr;
#ifdef DEBUG_TRACE
        printf("@%lld drtol2_snack snoop_or_ack:%d nid:%x l2id:%x drid:%x snack:%x line7:%x line6:%x line5:%x line4:%x line3:%x line2:%x line1:%x line0:%x paddr:%x\n",global_time,snoop_or_ack, drtol2_snackp.nid, drtol2_snackp.l2id, drtol2_snackp.drid, drtol2_snackp.snack, drtol2_snackp.line7, drtol2_snackp.line6, drtol2_snackp.line5, drtol2_snackp.line4, drtol2_snackp.line3, drtol2_snackp.line2, drtol2_snackp.line1, drtol2_snackp.line0, drtol2_snackp.paddr);
#endif
        if (0) { // If it's write
                    // TODO
        }
        else{
          L2toL1SnackPacket l2tol1_snackp;
          l2tol1_snackp.l1id = rand();
          l2tol1_snackp.l2id = drtol2_snackp.l2id;
          l2tol1_snackp.snack = drtol2_snackp.snack;
          l2tol1_snackp.line7 = drtol2_snackp.line7;
          l2tol1_snackp.line6 = drtol2_snackp.line6;
          l2tol1_snackp.line5 = drtol2_snackp.line5;
          l2tol1_snackp.line4 = drtol2_snackp.line4;
          l2tol1_snackp.line3 = drtol2_snackp.line3;
          l2tol1_snackp.line2 = drtol2_snackp.line2;
          l2tol1_snackp.line1 = drtol2_snackp.line1;
          l2tol1_snackp.line0 = drtol2_snackp.line0;
          l2tol1_snackp.poffset = rand();
          l2tol1_snackp.hpaddr = rand();
          if (snoop_or_ack == 1) {
            l2tol1_ack_only_list.push_front(l2tol1_snackp);
          }
          else if (snoop_or_ack == -1) {
            l2tol1_snoop_only_list.push_front(l2tol1_snackp);              
          }
        }
        if (snoop_or_ack == 1) {
            drtol2_ack_only_list.pop_back();
        }
        else if (snoop_or_ack == -1){
            drtol2_snoop_only_list.pop_back();
        }
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
        top->l1tol2_snoop_ack_directory_id = l1tol2_snoop_ackp.directory_id;
#ifdef DEBUG_TRACE
        printf("@%lld l1tol2_snoop_ack l2id:%x\n",global_time, l1tol2_snoop_ackp.l2id);
#endif
        if (0) { // If it's write
                    // TODO
        }
        else{
          L2toDrSnoopAckPacket l2todr_snoop_ackp;
          l2todr_snoop_ackp.l2id = l1tol2_snoop_ackp.l2id;;
          l2todr_snoop_ackp.directory_id = l1tol2_snoop_ackp.directory_id;
          l2todr_snoop_ack_list.push_front(l2todr_snoop_ackp);
        }
        l1tol2_snoop_ack_list.pop_back();
    }
}

void try_send_l1_to_l2_disp_packet (Vl2cache_pipe_wp *top) {
    top->l2todr_disp_retry = (rand()&0xF)==0; // randomly,
    top->l2tol1_dack_retry = (rand()&0xF)==0; // randomly,
    if ( !top-> l1tol2_disp_retry ) {
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
        top->l1tol2_disp_ppaddr = rand();
        if (l1tol2_disp_list.empty() || (rand() & 0x3==0)) { // Once every 4
          top->l1tol2_disp_valid = 0;
        }else{
          top->l1tol2_disp_valid = 1;
        }
    }
    else {
    // This is very important to handle "fluid fork"
        top->l1tol2_disp_valid = !top-> l1tol2_disp_retry;
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
        top->l1tol2_disp_ppaddr = l1tol2_dispp.ppaddr;
#ifdef DEBUG_TRACE
        printf("@%lld l1tol2_disp l1id:%x l2id:%x mask:%x dcmd:%d line7:%x line6:%x line5:%x line4:%x line3:%x line2:%x line1:%x line0:%x ppaddr:%x\n",global_time, l1tol2_dispp.l1id, l1tol2_dispp.l2id, l1tol2_dispp.mask, l1tol2_dispp.dcmd, l1tol2_dispp.line7, l1tol2_dispp.line6, l1tol2_dispp.line5, l1tol2_dispp.line4, l1tol2_dispp.line3, l1tol2_dispp.line2, l1tol2_dispp.line1, l1tol2_dispp.line0, l1tol2_dispp.ppaddr);
#endif
        if (0) { // If it's write
                    // TODO
        }
        else{
          // Generate 1st ref result l2todr_disp
          L2toDrDispPacket l2todr_dispp;
          l2todr_dispp.nid = rand() & 0x1F;
          l2todr_dispp.l2id = l1tol2_dispp.l2id;
          l2todr_dispp.drid = rand() & 0x3F;
          l2todr_dispp.mask = l1tol2_dispp.mask;
          l2todr_dispp.dcmd = l1tol2_dispp.dcmd;
          l2todr_dispp.line7 = l1tol2_dispp.line7;
          l2todr_dispp.line6 = l1tol2_dispp.line6;
          l2todr_dispp.line5 = l1tol2_dispp.line5;
          l2todr_dispp.line4 = l1tol2_dispp.line4;
          l2todr_dispp.line3 = l1tol2_dispp.line3;
          l2todr_dispp.line2 = l1tol2_dispp.line2;
          l2todr_dispp.line1 = l1tol2_dispp.line1;
          l2todr_dispp.line0 = l1tol2_dispp.line0;
          l2todr_dispp.paddr = rand();
          //l2todr_dispp.paddr = l1tol2_dispp.ppaddr;
          l2todr_disp_list.push_front(l2todr_dispp);

          // Generate 2nd ref result 
          L2toL1DackPacket l2tol1_dackp;
          l2tol1_dackp.l1id = l1tol2_dispp.l1id;
          l2tol1_dack_list.push_front(l2tol1_dackp);
        }
        l1tol2_disp_list.pop_back();
    }
}

void try_send_dr_to_l2_dack_packet (Vl2cache_pipe_wp *top) {
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
        top->drtol2_dack_nid = drtol2_dackp.nid;
        top->drtol2_dack_l2id = drtol2_dackp.l2id;
#ifdef DEBUG_TRACE
        printf("@%lld drtol2_dack nid:%x l2id:%x\n",global_time, drtol2_dackp.nid, drtol2_dackp.l2id);
#endif
        if (0) { // If it's write
                    // TODO
        }
        else{
        }
        drtol2_dack_list.pop_back();
    }
}

void try_send_l2tlb_to_l2_fwd_packet (Vl2cache_pipe_wp *top) {
    top->l2todr_pfreq_retry = (rand()&0xF)==0; // randomly,
    if ( !top-> l2tlbtol2_fwd_retry ) {
        top->l2tlbtol2_fwd_l1id = rand();
        top->l2tlbtol2_fwd_prefetch = rand();
        top->l2tlbtol2_fwd_fault = rand();
        top->l2tlbtol2_fwd_hpaddr = rand();
        top->l2tlbtol2_fwd_paddr = rand();
        if (l2tlbtol2_fwd_list.empty() || (rand() & 0x3==0)) { // Once every 4
          top->l2tlbtol2_fwd_valid = 0;
        }else{
          top->l2tlbtol2_fwd_valid = 1;
        }
    }
    
    if (top->l2tlbtol2_fwd_valid && !top->l2tlbtol2_fwd_retry){
        if (l2tlbtol2_fwd_list.empty()) {
            fprintf(stderr,"ERROR: Internal error, could not be empty l2tlbtol2_fwd_list\n");
        }
        L2tlbtoL2FwdPacket l2tlbtol2_fwdp = l2tlbtol2_fwd_list.back();
        count_l2tlbtol2_fwd++;
        top->l2tlbtol2_fwd_l1id = l2tlbtol2_fwdp.l1id;
        top->l2tlbtol2_fwd_prefetch = l2tlbtol2_fwdp.prefetch;
        top->l2tlbtol2_fwd_fault = l2tlbtol2_fwdp.fault;
        top->l2tlbtol2_fwd_hpaddr = l2tlbtol2_fwdp.hpaddr;
        top->l2tlbtol2_fwd_paddr = l2tlbtol2_fwdp.paddr;
#ifdef DEBUG_TRACE
        printf("@%lld l2tlbtol2_fwd l1id:%x prefetch:%x fault:%x hpaddr:%d paddr:%x\n",global_time, l2tlbtol2_fwdp.l1id, 
            l2tlbtol2_fwdp.prefetch, l2tlbtol2_fwdp.fault, l2tlbtol2_fwdp.hpaddr, l2tlbtol2_fwdp.paddr);
#endif
        if (0) { // If it's write
                    // TODO
        }
        else{
            if (l2tlbtol2_fwdp.prefetch == 1) {
                L2toDrPfreqPacket l2todr_pfreqp;
                l2todr_pfreqp.nid = rand();
                l2todr_pfreqp.paddr = l2tlbtol2_fwdp.paddr;
                l2todr_pfreq_list.push_front(l2todr_pfreqp);
            }
        }
        l2tlbtol2_fwd_list.pop_back();
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
    if (top->l2todr_req_cmd != l2todr_reqp.cmd) {
            //||  top->l2todr_req_paddr != l2todr_reqp.paddr) {
        printf("ERROR: expected l2todr_req_cmd:%x but actual l2todr_req_cmd is %x\n", l2todr_reqp.cmd,top->l2todr_req_cmd);
        printf("ERROR: expected l2todr_req_paddr:%x but actual l2todr_req_paddr is %x\n", l2todr_reqp.paddr,top->l2todr_req_paddr);
        error_found(top);
      }
    l2todr_req_list.pop_back();
    count_l2todr_req++;
}

void try_receive_l2_to_l1_snack_packet (Vl2cache_pipe_wp *top) {
    if(top->l2tol1_snack_valid && l2tol1_snoop_only_list.empty() && l2tol1_ack_only_list.empty()){
        printf("ERROR: unexpected l2tol1_snack l1id:%x l2id:%x snack:%x line7:%x line6:%x line5:%x line4:%x line3:%x line2:%x line1:%x line0:%x poffset:%x hpaddr:%x\n",top->l2tol1_snack_l1id, top->l2tol1_snack_l2id, top->l2tol1_snack_snack, top->l2tol1_snack_line7, top->l2tol1_snack_line6, top->l2tol1_snack_line5, top->l2tol1_snack_line4, top->l2tol1_snack_line3, top->l2tol1_snack_line2, top->l2tol1_snack_line1, top->l2tol1_snack_line0, top->l2tol1_snack_poffset, top->l2tol1_snack_hpaddr);
        error_found(top);
        return;
    }

    if (top->l2tol1_snack_retry) {
        return;
    }

    if (!top->l2tol1_snack_valid) {
        return;
    }
    
    if (l2tol1_snoop_only_list.empty() && l2tol1_ack_only_list.empty())
        return;

    #ifdef DEBUG_TRACE
    printf("@%lld l2tol1_snack l1id:%x l2id:%x snack:%x line7:%x line6:%x line5:%x line4:%x line3:%x line2:%x line1:%x line0:%x poffset:%x hpaddr:%x\n",global_time, top->l2tol1_snack_l1id, top->l2tol1_snack_l2id, top->l2tol1_snack_snack, top->l2tol1_snack_line7, top->l2tol1_snack_line6, top->l2tol1_snack_line5, top->l2tol1_snack_line4, top->l2tol1_snack_line3, top->l2tol1_snack_line2, top->l2tol1_snack_line1, top->l2tol1_snack_line0, top->l2tol1_snack_poffset, top->l2tol1_snack_hpaddr);

    #endif
    L2toL1SnackPacket l2tol1_snackp;
    int snoop_or_ack;
    if (top->l2tol1_snack_snack >= 16) {
        // This is a snoop
        l2tol1_snackp = l2tol1_snoop_only_list.back();      
        snoop_or_ack = -1;
    }
    else {
        // This is an Ack
        l2tol1_snackp = l2tol1_ack_only_list.back();
        snoop_or_ack = 1;
    }
    if (top->l2tol1_snack_snack != l2tol1_snackp.snack ||
        top->l2tol1_snack_line7 != l2tol1_snackp.line7 ||
        top->l2tol1_snack_line6 != l2tol1_snackp.line6 ||
        top->l2tol1_snack_line5 != l2tol1_snackp.line5 ||
        top->l2tol1_snack_line4 != l2tol1_snackp.line4 ||
        top->l2tol1_snack_line3 != l2tol1_snackp.line3 ||
        top->l2tol1_snack_line2 != l2tol1_snackp.line2 ||
        top->l2tol1_snack_line1 != l2tol1_snackp.line1 ||
        top->l2tol1_snack_line0 != l2tol1_snackp.line0
       ){
        //|| top->l2tol1_snack_poffset != l2tol1_snackp.poffset ||
        //top->l2tol1_snack_hpaddr != l2tol1_snackp.hpaddr) {
        printf("ERROR: expected l2tol1_snack_snack:%x but actual l2tol1_snack_snack is %x\n", l2tol1_snackp.snack,top->l2tol1_snack_snack);
        printf("ERROR: expected l2tol1_snack_line7:%x but actual l2tol1_snack_line7 is %x\n", l2tol1_snackp.line7,top->l2tol1_snack_line7);
        printf("ERROR: expected l2tol1_snack_line6:%x but actual l2tol1_snack_line6 is %x\n", l2tol1_snackp.line6,top->l2tol1_snack_line6);
        printf("ERROR: expected l2tol1_snack_line5:%x but actual l2tol1_snack_line5 is %x\n", l2tol1_snackp.line5,top->l2tol1_snack_line5);
        printf("ERROR: expected l2tol1_snack_line4:%x but actual l2tol1_snack_line4 is %x\n", l2tol1_snackp.line4,top->l2tol1_snack_line4);
        printf("ERROR: expected l2tol1_snack_line3:%x but actual l2tol1_snack_line3 is %x\n", l2tol1_snackp.line3,top->l2tol1_snack_line3);
        printf("ERROR: expected l2tol1_snack_line2:%x but actual l2tol1_snack_line2 is %x\n", l2tol1_snackp.line2,top->l2tol1_snack_line2);
        printf("ERROR: expected l2tol1_snack_line1:%x but actual l2tol1_snack_line1 is %x\n", l2tol1_snackp.line1,top->l2tol1_snack_line1);
        printf("ERROR: expected l2tol1_snack_line0:%x but actual l2tol1_snack_line0 is %x\n", l2tol1_snackp.line0,top->l2tol1_snack_line0);
        printf("ERROR: expected l2tol1_snack_poffset:%x but actual l2tol1_snack_poffset is %x\n", l2tol1_snackp.poffset,top->l2tol1_snack_poffset);
        printf("ERROR: expected l2tol1_snack_hpaddr:%x but actual l2tol1_snack_hpaddr is %x\n", l2tol1_snackp.hpaddr,top->l2tol1_snack_hpaddr);
        error_found(top);
      }
    if (snoop_or_ack == -1) {
        l2tol1_snoop_only_list.pop_back();  
        count_l2tol1_snoop_only++;
        // Generated following response: l1tol2_snoop_ack
        L1toL2SnoopAckPacket l1tol2_snoop_ackp;
        l1tol2_snoop_ackp.l2id = l2tol1_snackp.l2id;
        l1tol2_snoop_ackp.directory_id = rand() & 0x03;
        l1tol2_snoop_ack_list.push_front(l1tol2_snoop_ackp);
    }
    else if (snoop_or_ack == 1) {
        l2tol1_ack_only_list.pop_back();    
        count_l2tol1_ack_only++;        
    }
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
    if (top->l2todr_disp_l2id != l2todr_dispp.l2id   ||
        top->l2todr_disp_mask != l2todr_dispp.mask   ||
        top->l2todr_disp_dcmd != l2todr_dispp.dcmd   ||
        top->l2todr_disp_line7 != l2todr_dispp.line7 ||
        top->l2todr_disp_line6 != l2todr_dispp.line6 ||
        top->l2todr_disp_line5 != l2todr_dispp.line5 ||
        top->l2todr_disp_line4 != l2todr_dispp.line4 ||
        top->l2todr_disp_line3 != l2todr_dispp.line3 ||
        top->l2todr_disp_line2 != l2todr_dispp.line2 ||
        top->l2todr_disp_line1 != l2todr_dispp.line1 ||
        top->l2todr_disp_line0 != l2todr_dispp.line0) {
        printf("ERROR: expected l2todr_disp_l2id:%x but actual l2todr_disp_l2id is %x\n", l2todr_dispp.l2id,top->l2todr_disp_l2id);        
        printf("ERROR: expected l2todr_disp_mask:%x but actual l2todr_disp_mask is %x\n", l2todr_dispp.mask,top->l2todr_disp_mask);
        printf("ERROR: expected l2todr_disp_dcmd:%x but actual l2todr_disp_dcmd is %x\n", l2todr_dispp.dcmd,top->l2todr_disp_dcmd);
        printf("ERROR: expected l2todr_disp_line7:%x but actual l2todr_disp_line7 is %x\n", l2todr_dispp.line7,top->l2todr_disp_line7);
        printf("ERROR: expected l2todr_disp_line6:%x but actual l2todr_disp_line6 is %x\n", l2todr_dispp.line6,top->l2todr_disp_line6);
        printf("ERROR: expected l2todr_disp_line5:%x but actual l2todr_disp_line5 is %x\n", l2todr_dispp.line5,top->l2todr_disp_line5);
        printf("ERROR: expected l2todr_disp_line4:%x but actual l2todr_disp_line4 is %x\n", l2todr_dispp.line4,top->l2todr_disp_line4);
        printf("ERROR: expected l2todr_disp_line3:%x but actual l2todr_disp_line3 is %x\n", l2todr_dispp.line3,top->l2todr_disp_line3);
        printf("ERROR: expected l2todr_disp_line2:%x but actual l2todr_disp_line2 is %x\n", l2todr_dispp.line2,top->l2todr_disp_line2);
        printf("ERROR: expected l2todr_disp_line1:%x but actual l2todr_disp_line1 is %x\n", l2todr_dispp.line1,top->l2todr_disp_line1);
        printf("ERROR: expected l2todr_disp_line0:%x but actual l2todr_disp_line0 is %x\n", l2todr_dispp.line0,top->l2todr_disp_line0);
        error_found(top);
      }
    l2todr_disp_list.pop_back();
    count_l2todr_disp++;

    // Generate response drtol2_dack
    DrtoL2DackPacket    drtol2_dackp;
    drtol2_dackp.nid = rand() & 0x1F;
    drtol2_dackp.l2id = l2todr_dispp.l2id;
    drtol2_dack_list.push_front(drtol2_dackp);
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
    printf("@%lld l2tol1_dack l1id:%x\n",global_time, top->l2tol1_dack_l1id);

    #endif
    L2toL1DackPacket l2tol1_dackp = l2tol1_dack_list.back();

    l2tol1_dack_list.pop_back();
    if (top->l2tol1_dack_l1id != l2tol1_dackp.l1id) {
        printf("ERROR: expected l2tol1_dack_l1id:%x but actual l2tol1_dack_l1id is %x\n", l2tol1_dackp.l1id,top->l2tol1_dack_l1id);
        error_found(top);
      }
    count_l2tol1_dack++;
}

void try_receive_l2_to_dr_pfreq_packet (Vl2cache_pipe_wp *top) {
    if(top->l2todr_pfreq_valid && l2todr_pfreq_list.empty()){
        printf("ERROR: unexpected l2todr_pfreq nid:%x paddr:%x\n",top->l2todr_pfreq_nid, 
                top->l2todr_pfreq_paddr);
        error_found(top);
        return;
    }

    if (top->l2todr_pfreq_retry) {
        return;
    }

    if (!top->l2todr_pfreq_valid) {
        return;
    }
    
    if (l2todr_pfreq_list.empty())
        return;

    #ifdef DEBUG_TRACE
    printf("@%lld l2todr_pfreq nid:%x paddr:%x\n",global_time, top->l2todr_pfreq_nid,
            top->l2todr_pfreq_paddr);

    #endif
    L2toDrPfreqPacket l2todr_pfreqp = l2todr_pfreq_list.back();
    if (top->l2todr_pfreq_paddr != l2todr_pfreqp.paddr) {
        printf("ERROR: expected l2todr_pfreq_paddr:%x but actual l2todr_pfreq_paddr is %x\n", l2todr_pfreqp.paddr,top->l2todr_pfreq_paddr);
        error_found(top);
      }
    l2todr_pfreq_list.pop_back();
    count_l2todr_pfreq++;
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
  for(int i =0;i<6000;i++) {
    try_send_l1_to_l2_req_packet(top);
    try_send_dr_to_l2_snack_packet(top);
    //try_send_l1_to_l2_snoop_ack_packet(top);
    //try_send_l2tlb_to_l2_fwd_packet(top);
    //try_send_l1_to_l2_disp_packet(top);
    //try_send_dr_to_l2_dack_packet(top);
    advance_half_clock(top);
    try_receive_l2_to_dr_req_packet(top);
    try_receive_l2_to_l1_snack_packet(top);
    try_receive_l2_to_dr_snoop_ack_packet(top);
    try_receive_l2_to_dr_pfreq_packet(top);
    try_receive_l2_to_dr_disp_packet(top);
    try_receive_l2_to_l1_dack_packet(top);
    advance_half_clock(top);

    if (((rand() & 0x3)==0) && l1tol2_req_list.size() < 3 ) {
      //L1toL2ReqPacket l1tol2_reqp = L1toL2ReqPacket();
      L1toL2ReqPacket l1tol2_reqp;
      l1tol2_reqp.l1id = rand() & 0x1F;
      l1tol2_reqp.cmd = rand() & 0x7;
      l1tol2_reqp.pcsign = rand() & 0x1FFF;
      l1tol2_reqp.ppaddr = rand() & 0x3FFFFFFFFFFFF;
      l1tol2_req_list.push_front(l1tol2_reqp);
    }

    if(((rand() & 0x3)==0) && drtol2_snoop_only_list.size() < 3 ) {
      //DrtoL2SnackPacket drtol2_snackp = DrtoL2SnackPacket();
      DrtoL2SnackPacket drtol2_snackp;
      drtol2_snackp.nid = rand() & 0x1F;
      drtol2_snackp.l2id = rand() & 0x3F;
      drtol2_snackp.drid = rand() & 0x3F;
      drtol2_snackp.directory_id = rand() & 0X3;
      drtol2_snackp.snack = rand() & 0x1F | 0x10; // Make sure this is a snoop
      drtol2_snackp.line7 = rand() & 0xFFFFFFFFFFFFFFFF;
      drtol2_snackp.line6 = rand() & 0xFFFFFFFFFFFFFFFF;
      drtol2_snackp.line5 = rand() & 0xFFFFFFFFFFFFFFFF;
      drtol2_snackp.line4 = rand() & 0xFFFFFFFFFFFFFFFF;
      drtol2_snackp.line3 = rand() & 0xFFFFFFFFFFFFFFFF;
      drtol2_snackp.line2 = rand() & 0xFFFFFFFFFFFFFFFF;
      drtol2_snackp.line2 = rand() & 0xFFFFFFFFFFFFFFFF;
      drtol2_snackp.line0 = rand() & 0xFFFFFFFFFFFFFFFF;
      drtol2_snackp.hpaddr_base = rand() & 0xFF;
      drtol2_snackp.hpaddr_hash = rand() & 0xFFFF; //buggy
      drtol2_snackp.paddr = rand() & 0x3FFFFFFFFFFFF;
      drtol2_snoop_only_list.push_front(drtol2_snackp);
    }

    if(((rand() & 0x3)==0) && l1tol2_disp_list.size() < 3 ) {
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
      l1tol2_dispp.ppaddr = rand() & 0x7;
      l1tol2_disp_list.push_front(l1tol2_dispp);
    }

    if (((rand() & 0x3)==0) && l2tlbtol2_fwd_list.size() < 3 ) {
      //L2tlbtoL2FwdPacket l2tlbtol2_fwdp = L2tlbtoL2FwdPacket();
      L2tlbtoL2FwdPacket l2tlbtol2_fwdp;
      l2tlbtol2_fwdp.l1id = rand() & 0x1F;
      l2tlbtol2_fwdp.prefetch = rand() & 0x1;
      l2tlbtol2_fwdp.fault = rand() & 0x7;
      l2tlbtol2_fwdp.hpaddr = rand() & 0x7FF;
      l2tlbtol2_fwdp.paddr = rand() & 0x3FFFFFFFFFFFF;
      l2tlbtol2_fwd_list.push_front(l2tlbtol2_fwdp);
    }
  }
#endif
  printf("Test Statistics:\n l1tol2_req count: %d\n l2todr_req count: %d\n l2tol1_snoop_only count: %d\n l2tol1_ack_only count: %d\n drtol2_snoop_only count: %d\n drtol2_ack_only count: %d\n l1tol2_snoop_ack count: %d\n l2todr_snoop_ack count %d\n l1tol2_disp count: %d\n l2todr_disp count: %d\n l2tol1_dack count: %d\n drtol2_dack count: %d\n l2tlbtol2_fwd count: %d\n l2todr_pfreq count: %d\n",
          count_l1tol2_req, count_l2todr_req, count_l2tol1_snoop_only, count_l2tol1_ack_only, count_drtol2_snoop_only, count_drtol2_ack_only,
          count_l1tol2_snoop_ack, count_l2todr_snoop_ack, count_l1tol2_disp, count_l2todr_disp, count_l2tol1_dack, count_drtol2_dack, count_l2tlbtol2_fwd, count_l2todr_pfreq);
  sim_finish(true);

}


#include "Vpfmonitor_wp.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include "DOLC.h"

#include <list>
#include <vector>

#include <time.h>

#define DEBUG_TRACE 1
//#define GENERATED_PREFETCH 1
#define VTAGE_TABLE 6
#define VTAGE_TABLE_ENTRIES 512
#define BIMODAL_TABLE_ENTRIES 512

vluint64_t global_time = 0;
VerilatedVcdC* tfp = 0;

void advance_half_clock(Vpfmonitor_wp *top) {
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

void advance_clock(Vpfmonitor_wp *top, int nclocks=1) {

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

struct InputPacket_coretopfm_dec {
  uint64_t  coretopfm_dec_pcsign; 
  uint16_t  coretopfm_dec_rid; 
  uint8_t   coretopfm_dec_decmask;  
};

struct InputPacket_coretopfm_retire {
  uint8_t  coretopfm_retire_pfentry;

  uint16_t coretopfm_retire_d0_rid;   
  uint8_t  coretopfm_retire_d0_val;
  uint16_t coretopfm_retire_d1_rid;
  uint8_t  coretopfm_retire_d1_val;

  uint16_t coretopfm_retire_d2_rid;
  uint8_t  coretopfm_retire_d2_val;
  uint16_t coretopfm_retire_d3_rid;
  uint8_t  coretopfm_retire_d3_val;
};

struct OutputPacket_pfmtocore {
  uint8_t  pfmtocore_pfentry;

  uint16_t pfmtocore_d0_rid;
  uint8_t  pfmtocore_d0_val;
  uint8_t  pfmtocore_d0_w;
  uint16_t pfmtocore_d1_rid;
  uint8_t  pfmtocore_d1_val;
  uint8_t  pfmtocore_d1_w;

  uint16_t pfmtocore_d2_rid;
  uint8_t  pfmtocore_d2_val;
  uint8_t  pfmtocore_d2_w;
  uint16_t pfmtocore_d3_rid;
  uint8_t  pfmtocore_d3_val;
  uint8_t  pfmtocore_d3_w;
};

struct pc_circular_buffer {
  uint64_t  cir_buffer_pcsign_idx0;
  uint64_t  cir_buffer_pcsign_idx1;
  uint64_t  cir_buffer_pcsign_idx2;
  uint64_t  cir_buffer_pcsign_idx3;
  uint8_t  cir_buffer_decmask;
};

struct vtage_components {
  uint16_t delta[VTAGE_TABLE_ENTRIES];
  uint16_t weight[VTAGE_TABLE_ENTRIES]; 
  uint16_t offset[VTAGE_TABLE_ENTRIES];
  uint8_t  sat_ctr[VTAGE_TABLE_ENTRIES];
  uint8_t  u[VTAGE_TABLE_ENTRIES];
  uint64_t tag[VTAGE_TABLE_ENTRIES];
};

double sc_time_stamp() {
  return 0;
}

uint16_t memory[256];
uint64_t key;
uint8_t doUpdate;       //flag for VTAGE update on miss
uint8_t misPredUpdate;  //flag for VTAGE update on misprediction
DOLC dolc(12,2,4,8);               //historySize = 12         //init DOLC pc based history
std::vector<uint64_t> l1_generated_prefetch;  //L1 can have max of 4 pretfetch generations
std::vector<uint64_t> l2_generated_prefetch;

std::list<InputPacket_coretopfm_dec>  inp_list_dec;
std::list<InputPacket_coretopfm_retire>  inp_list_retire;
std::list<OutputPacket_pfmtocore> out_list;


vtage_components bimodalTable;
vtage_components tables[VTAGE_TABLE];

uint64_t *histLength;
uint64_t *taggedTable_TagMask;
uint64_t *taggedTable_IdxMask;


void initialize_tables() {
  //initialize bimodal base table

  for (int jj = 0; jj<VTAGE_TABLE_ENTRIES; jj++) {
    bimodalTable.delta[jj]   = rand()%64;
    bimodalTable.weight[jj]  = rand()%4;
    bimodalTable.offset[jj]  = rand()%4;
    bimodalTable.sat_ctr[jj] = 0;
    bimodalTable.tag[jj]     = rand();
  }


  for (int i = 0; i<VTAGE_TABLE; i++) {
    for (int j = 0; j<VTAGE_TABLE_ENTRIES; j++) {
      tables[i].delta[j]   = 0;
      tables[i].weight[j]  = 0;
      tables[i].offset[j]  = 0;
      tables[i].sat_ctr[j] = 0;
      tables[i].u[j]       = 0;
      tables[i].tag[j]     = rand() & 0xFF;
    }
  }


}



void update_prefetch(uint64_t addr, uint64_t off, uint8_t doUpdate, uint8_t misPredUpdate) {

  if(doUpdate == 1 && misPredUpdate == 0) {   //insert entry at random table and random entry
    for (int a = 0; a<VTAGE_TABLE; a++) {
      for (int b = 0; b<VTAGE_TABLE_ENTRIES; b++) {
        int i, j;
        i = rand()%VTAGE_TABLE;
        j = rand()%VTAGE_TABLE_ENTRIES;
        if (tables[i].u[j] == 0) {          //allocate new entry only when u = 0 for current entry
          tables[i].delta[j]   = rand()%64;
          tables[i].weight[j]  = rand()%4;
          tables[i].offset[j]  = off;
          tables[i].sat_ctr[j] = 1;
          tables[i].u[j]       = 0;
          tables[i].tag[j]     = addr & 0xFF;
          doUpdate = 0;
          break;
        }
      }
    }
  }

  //prefetch update when "misPredUpdate = 1" is not yet done
  if(misPredUpdate == 1) {
    for (int i = 0; i<VTAGE_TABLE; i++) {
      for (int j = 0; j<VTAGE_TABLE_ENTRIES; j++) {
        if((tables[i].tag[j] == (addr & 0xFF)) && tables[i].sat_ctr[j] != 0) {
          tables[i].sat_ctr[j] = 0;
          tables[i].u[j]       = 0;        
        }
        else if((tables[i].tag[j] == (addr & 0xFF)) && tables[i].sat_ctr[j] == 0) { 
          //if ctr = 0 and u=0 on misprediction, then d and w values are updated. if u is not 0, then u is reset and no update is done
          if (tables[i].u[j] == 0) {
            tables[i].delta[j]  = rand()%64;
            tables[i].weight[j] = rand()%4;
            tables[i].sat_ctr[j] = 0;
            tables[i].u[j]       = 0;
          }
          else {
            tables[i].u[j] = 0;
          }
        
        }
      }
    }
  }
   
}



void prediction(uint64_t pc, uint64_t addr) { //addr is specific instr in the current PC bundle

  uint64_t off = pc - addr;
  OutputPacket_pfmtocore out;

  for (int i = 0; i<VTAGE_TABLE; i++) {
    for (int j = 0; j<VTAGE_TABLE_ENTRIES; j++) {
      if(tables[i].tag[j] == (addr & 0xFF) && (tables[i].sat_ctr[j] == 0 || tables[i].sat_ctr[j] == 7)) {
        out.pfmtocore_d0_val = tables[i].delta[j];
        out.pfmtocore_d0_w   = tables[i].weight[j];

#ifdef GENERATED_PREFETCH      
  printf("@%lld  req_addr:%x  delta:%x  w:%x \n",global_time, addr, out.pfmtocore_d0_val, out.pfmtocore_d0_w);
#endif

        out_list.push_front(out);

        //update 'u' and 'ctr'
        tables[i].sat_ctr[j] += 1;
        tables[i].u[j]        = 1;

        if(tables[i].sat_ctr[j] >= 8) { //saturate 3-bit ctr
          tables[i].sat_ctr[j] = 0;
        }
      }
      else if(bimodalTable.tag[j] == pc && (tables[i].sat_ctr[j] == 0 || tables[i].sat_ctr[j] == 7)) {
        out.pfmtocore_d0_val = bimodalTable.delta[j];
        out.pfmtocore_d0_w   = bimodalTable.weight[j];

#ifdef GENERATED_PREFETCH
          printf("@%lld  req_addr:%x  delta:%x  w:%x \n",global_time, addr, out.pfmtocore_d0_val, out.pfmtocore_d0_w);
#endif

        out_list.push_front(out);
        
        bimodalTable.sat_ctr[j] += 1;
        bimodalTable.u[j]        = 1;
        if(bimodalTable.sat_ctr[j] >= 8) {
          bimodalTable.sat_ctr[j] = 0; 
        }
      }
      else { //no prediction found for current addr on the vtage and bimodal tables 
        doUpdate = 1;
        misPredUpdate = 0;
        update_prefetch(addr, off, doUpdate, misPredUpdate);
      
      }
    }
  }

}



//input to pfengine (laddr, pcsign, sptbr, delta, weight and cache stats)
void try_send_input_packet_coretopfm_decode(Vpfmonitor_wp *top) {

  top->pfmtocore_pred_retry = (rand()&0xF)==0;

  if (!top->coretopfm_dec_retry) {
    top->coretopfm_dec_rid     = rand()%512;
    top->coretopfm_dec_pcsign  = rand();
    top->coretopfm_dec_decmask = rand()%16;       //4 bit decmask (0 to 15)
    if (inp_list_dec.empty() || (rand() & 0x3)) { // Once every 4 cycles
      top->coretopfm_dec_valid = 0;
    }else{
      top->coretopfm_dec_valid = 1;
    }
  }

  if (top->coretopfm_dec_valid && !top->coretopfm_dec_retry) {
    if (inp_list_dec.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty input\n");
    }

    InputPacket_coretopfm_dec inp_dec = inp_list_dec.back();
    top->coretopfm_dec_pcsign  = inp_dec.coretopfm_dec_pcsign;
    top->coretopfm_dec_rid     = inp_dec.coretopfm_dec_rid;
    top->coretopfm_dec_decmask = inp_dec.coretopfm_dec_decmask;
    
/*
    key = top->coretopfm_dec_pcsign >> 2;
    key = (key >> 17) ^ key;

    dolc->update(top->coretopfm_dec_pcsign);
    key ^= dolc->getSign(12,12);
*/


    pc_circular_buffer pc_buffer;
    pc_buffer.cir_buffer_pcsign_idx0 = top->coretopfm_dec_pcsign;
    pc_buffer.cir_buffer_pcsign_idx1 = top->coretopfm_dec_pcsign+1;
    pc_buffer.cir_buffer_pcsign_idx2 = top->coretopfm_dec_pcsign+2;
    pc_buffer.cir_buffer_pcsign_idx3 = top->coretopfm_dec_pcsign+3;
    pc_buffer.cir_buffer_decmask     = top->coretopfm_dec_decmask;
    //cir_buffer.push_front(pc_buffer);

    
    //check decmask of current pc bundle to decide the number of prefetches to be generated
    
    if (top->coretopfm_dec_decmask == 0) {                    //decmask = 0b0000
      printf("No prefetch generated for current PC bundle");
    }
    else if (top->coretopfm_dec_decmask == 1) {               //decmask = 0b0001
        prediction(top->coretopfm_dec_pcsign, pc_buffer.cir_buffer_pcsign_idx0);
    }
    

#ifdef DEBUG_TRACE
    printf("@%lld pcsign:%x rid:%x decmask:%x \n",global_time, inp_dec.coretopfm_dec_pcsign, inp_dec.coretopfm_dec_rid, inp_dec.coretopfm_dec_decmask);
#endif

/*
    OutputPacket_pfmtocore out;
    out.pfmtocore_d0_val = 32;
    out.pfmtocore_d0_w = 2;
    out_list.push_front(out);
*/

    inp_list_dec.pop_back();
  }

}


void error_found(Vpfmonitor_wp *top) {
  advance_half_clock(top);
  advance_half_clock(top);
  sim_finish(false);
}


void try_recv_output_packet_from_pfmtocore(Vpfmonitor_wp *top) {

  if (top->pfmtocore_pred_valid && out_list.empty()) {
    //printf("ERROR: unexpected prefetch:%x\n", top->pftodc_req0_laddr);
    printf("ERROR: unexpected prefetch \n");
    error_found(top);
    return;
  }


  if (top->pfmtocore_pred_retry)
    return;

  if (out_list.empty())
    return;

#ifdef DEBUG_TRACE
  
    OutputPacket_pfmtocore o = out_list.back();
    if (top->pfmtocore_pred_valid)
      printf("@%lld  prefetch_addr:%x  delta:%x  weight:%x\n",global_time, top->coretopfm_dec_pcsign, o.pfmtocore_d0_val, o.pfmtocore_d0_w);

#endif
  //OutputPacket o = out_list.back();

  out_list.pop_back();
}


int main(int argc, char **argv, char **env) {
  int i;
  int clk;
  Verilated::commandArgs(argc, argv);
  // init top verilog instance
  Vpfmonitor_wp* top = new Vpfmonitor_wp;

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
  top->pfmtocore_pred_retry = 1; 

  advance_clock(top,1);
  initialize_tables();

#if 1
  for(int i =0;i<1024;i++) {
    try_send_input_packet_coretopfm_decode(top);
    advance_half_clock(top);
    try_recv_output_packet_from_pfmtocore(top);
    advance_half_clock(top);

    if (((rand() & 0x3)==0) && inp_list_dec.size() < 3 ) {
      InputPacket_coretopfm_dec i;
      i.coretopfm_dec_pcsign  = rand();
      i.coretopfm_dec_rid     = rand()%512;
      i.coretopfm_dec_decmask = 1;
      inp_list_dec.push_front(i);
    }
  }
#endif

  sim_finish(true);

}



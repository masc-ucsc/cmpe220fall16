#include "Vl2tlb_wp.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <list>

#include <time.h>

#define DEBUG_TRACE 1

vluint64_t global_time = 0;
VerilatedVcdC* tfp = 0;

long ntests = 0;

void advance_half_clock(Vjoin_fadd *top) {
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

void advance_clock(Vjoin_fadd *top, int nclocks=1) {

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

// Input structs ----------------------------------------------------
struct In_l1tol2tlb_req {
	uint8_t		1lid
	uint8_t		prefetch
	uint16_t	poffset
	uint16_t	hpaddr
};

struct In_l1tlbtol2tlb_req {
	uint8_t		rid
	uint8_t		disp_req
	uint8_t		disp_A
	uint8_t		disp_B
	uint16_t	disp_hpaddr
	uint64_t	laddr
	uint64_t	sptbr
};

struct In_l1tlbtol2tlb_sack {
	uint8_t		l1tlbtol2tlb_sack_rid
};
  
struct In_drtol2_snack {
	uint8_t		nid
	uint8_t		l2id
	uint8_t		drid
	uint8_t		snack
	uint64_t	line0
	uint64_t	line1
	uint64_t	line2
	uint64_t	line3
	uint64_t	line4
	uint64_t	line5
	uint64_t	line6
	uint64_t	line7
	uint64_t	paddr
};

struct In_drtol2_dack {
	uint8_t		nid
	uint8_t		l2id
};

// Output structs ----------------------------------------------------
struct Out_l2tlbtol2_fwd {
	uint8_t		1lid
	uint8_t		prefetch
	uint8_t		fault
	uint16_t	hpaddr
	uint64_t	paddr
};

struct Out_l2tlbtol1tlb_snoop {
	uint8_t		rid
	uint16_t	hpaddr
};

struct Out_l2tlbtol1tlb_ack {
	uint8_t		rid
	uint16_t	hpaddr
	uint8_t		ppaddr
	uint16_t	dctlbe
};

struct Out_l2todr_req {
	uint8_t		nid
	uint8_t		l2id
	uint8_t		cmd
	uint64_t	paddr
};

struct Out_l2todr_snoop_ack {
	uint8_t		l2id
};

struct Out_l2todr_disp {
	uint8_t		nid
	uint8_t		l2id
	uint8_t		drid
	uint64_t	mask
	uint8_t		dcmd
	uint64_t	line0
	uint64_t	line1
	uint64_t	line2
	uint64_t	line3
	uint64_t	line4
	uint64_t	line5
	uint64_t	line6
	uint64_t	line7
	uint64_t	paddr
};


double sc_time_stamp() {
  return 0;
}

std::list<In_l1tol2tlb_req> 		l1_l2tlb_req_list;
std::list<In_l1tlbtol2tlb_req>		l1tlb_l2tlb_req_list;
std::list<In_l1tlbtol2tlb_sack> 	l1tlb_l2tlb_sack_list;
std::list<In_drtol2_snack> 			dr_l2_snack_list;
std::list<In_drtol2_dack>  			dr_l2_dack_list;

std::list<Out_l2tlbtol2_fwd> 		l2tlb_l2_fwd_list;
std::list<Out_l2tlbtol1tlb_snoop>	l2tlb_l1tlb_snoop_list;
std::list<Out_l2tlbtol1tlb_ack>		l2tlb_l1tlb_ack_list;
std::list<Out_l2todr_req> 			l2_dr_req_list;
std::list<Out_l2todr_snoop_ack> 	l2_dr_snoop_list;
std::list<Out_l2todr_disp> 			l2_dr_disp_list;

void try_send_packet(Vjoin_fadd *top) {
  static int set_retry_for = 0;
  if ((rand()&0xF)==0 && set_retry_for == 0) {
    set_retry_for = rand()&0x1F;
  }
  if (set_retry_for) {
    set_retry_for--;
    top->l2tlbtol2_fwd_retry	 	= 1;
	top->l2tlbtol1tlb_snoop_retry 	= 1;
	top->l2tlbtol1tlb_ack_retry 	= 1;
	top->l2todr_req_retry 			= 1;
	top->l2todr_snoop_ack_retry 	= 1;
	top->l2todr_disp_retry 			= 1;
  }else{
    top->l2tlbtol2_fwd_retry 		= (rand()&0xF)==0; // randomly, one every 8 packets
	top->l2tlbtol1tlb_snoop_retry	= (rand()&0xF)==0; // randomly, one every 8 packets
	top->l2tlbtol1tlb_ack_retry 	= (rand()&0xF)==0; // randomly, one every 8 packets
	top->l2todr_req_retry 			= (rand()&0xF)==0; // randomly, one every 8 packets
	top->l2todr_snoop_ack_retry 	= (rand()&0xF)==0; // randomly, one every 8 packets
	top->l2todr_disp_retry 			= (rand()&0xF)==0; // randomly, one every 8 packets
  }

  if (!top->l1tol2tlb_req_retry) {
    top->l1_l2tlb_req_1lid 		= rand() & 0x1f;
	top->l1_l2tlb_req_poffset 	= rand() & 0x0fff;
	top->l1_l2tlb_req_hpaddr 	= rand() & 0x08ff;
	
    if (l1_l2tlb_req_list.empty() || (rand() & 0x3)) { // Once every 4
      top->l1tol2tlb_req_valid = 0;
    }else{
      top->l1tol2tlb_req_valid = 1;
    }
  }
  
  if (!top->l1tlbtol2tlb_req_retry) {
    top->l1tlb_l2tlb_req_rid 	= rand() & 0x03;
	top->l1tlb_l2tlb_req_hpaddr = rand() & 0x08ff;
	top->l1tlb_l2tlb_req_laddr 	= rand() & 0x0000008fffffffff;
	
    if (l1tlb_l2tlb_req_list.empty() || (rand() & 0x3)) { // Once every 4
      top->l1tlbtol2tlb_req_valid = 0;
    }else{
      top->l1tlbtol2tlb_req_valid = 1;
    }
  }
  
  if (!top->l1tlbtol2tlb_sack_retry) {
    top->l1tlb_l2tlb_sack_rid = rand() & 0x03;
	
    if (l1tlb_l2tlb_sack_list.empty() || (rand() & 0x3)) { // Once every 4
      top->l1tlbtol2tlb_sack_valid = 0;
    }else{
      top->l1tlbtol2tlb_sack_valid = 1;
    }
  }
  
  if (!top->drtol2_snack_retry) {
    top->dr_l2_snack_nid   = rand() & 0x1f;
	top->dr_l2_snack_l2id  = rand() & 0x3f;
	top->dr_l2_snack_drid  = rand() & 0x3f;
	top->dr_l2_snack_line0 = rand() & 0xffffffffffffffff;
	top->dr_l2_snack_line1 = rand() & 0xffffffffffffffff;
	top->dr_l2_snack_line2 = rand() & 0xffffffffffffffff;
	top->dr_l2_snack_line3 = rand() & 0xffffffffffffffff;
	top->dr_l2_snack_line4 = rand() & 0xffffffffffffffff;
	top->dr_l2_snack_line5 = rand() & 0xffffffffffffffff;
	top->dr_l2_snack_line6 = rand() & 0xffffffffffffffff;
	top->dr_l2_snack_line7 = rand() & 0xffffffffffffffff;
	top->dr_l2_snack_paddr = rand() & 0x0002ffffffffffff;
	
    if (dr_l2_snack_list.empty() || (rand() & 0x3)) { // Once every 4
      top->drtol2_snack_valid = 0;
    }else{
      top->drtol2_snack_valid = 1;
    }
  }

  if (!top->drtol2_dack_retry) {
    top->dr_l2_dack_nid  = rand() & 0x1f;
	top->dr_l2_dack_l2id = rand() & 0x3f
	
    if (dr_l2_dack_list.empty() || (rand() & 0x3)) { // Once every 4
      top->drtol2_dack_valid = 0;
    }else{
      top->drtol2_dack_valid = 1;
    }
  }

  /*if (top->inp_aValid && !top->inp_aRetry) {
    if (inpa_list.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty inpa\n");
    }
    InputPacketA inp = inpa_list.back();
    top->inp_a = inp.inp_a;
#ifdef DEBUG_TRACE
    printf("@%lld inp_a=%d\n",global_time, inp.inp_a);
#endif
    inpa_list.pop_back();
  }

  if (top->inp_bValid && !top->inp_bRetry) {
    if (inpb_list.empty()) {
      fprintf(stderr,"ERROR: Internal error, could not be empty inpb\n");
    }
    InputPacketB inp = inpb_list.back();
    top->inp_b = inp.inp_b;
#ifdef DEBUG_TRACE
    printf("@%lld inp_b=%d\n",global_time, inp.inp_b);
#endif
    inpb_list.pop_back();
  }*/

}

void error_found(Vjoin_fadd *top) {
  advance_half_clock(top);
  advance_half_clock(top);
  sim_finish(false);
}

void try_recv_packet(Vjoin_fadd *top) {

  /*if (top->sumValid && out_list.empty()) {
    printf("ERROR: unexpected result %d\n",top->sum);
    error_found(top);
    return;
  }

  if (top->sumRetry)
    return;

  if (!top->sumValid)
    return;

  if (out_list.empty())
    return;

#ifdef DEBUG_TRACE
    printf("@%lld sum=%d\n",global_time, top->sum);
#endif
  OutputPacket o = out_list.back();
  if (top->sum != o.sum) {
    printf("ERROR: expected %d but sum is %d (%d+%d)\n",o.sum,top->sum,o.inp_a,o.inp_b);
    error_found(top);
  }

  out_list.pop_back();*/
}


int main(int argc, char **argv, char **env) {
  int i;
  int clk;
  Verilated::commandArgs(argc, argv);
  // init top verilog instance
  Vl2tlb_wp* top = new Vl2tlb_wp;

  int t = (int)time(0);
#if 0
  srand(1477403302);
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
  top->reset = 1;

  advance_clock(top,4); // May be larger as required by reset state machines
  //-------------------------------------------------------
  top->reset = 0;
  /*top->inp_a = 1;
  top->inp_aValid = 0;
  top->sumRetry = 1;*/

  advance_clock(top,1);

#if 1
  for(int i =0;i<10240;i++) {
    try_send_packet(top);
    advance_half_clock(top);
    try_recv_packet(top);
    advance_half_clock(top);

    if (((rand() & 0x3)==0) && l1_l2tlb_req_list.size() < 3) {
	  In_l1tol2tlb_req			l1_l2tlb_req_o;
	  In_l1tlbtol2tlb_req		l1tlb_l2tlb_req_o;
	  In_l1tlbtol2tlb_sack 		l1tlb_l2tlb_sack_o;
	  In_drtol2_snack 			dr_l2_snack_o;
	  In_drtol2_dack  			dr_l2_dack_o;
      
	  l1_l2tlb_req_o.1lid = rand() & 0x1f;
	  l1_l2tlb_req_o.poffset = rand() & 0x0fff;
	  l1_l2tlb_req_o.hpaddr = rand() & 0x08ff;
	  
	  l1tlb_l2tlb_req_o.rid = rand() & 0x03;
	  l1tlb_l2tlb_req_o.hpaddr = rand() & 0x08ff;
	  l1tlb_l2tlb_req_o.laddr = rand() & 0x0000008fffffffff;
	  
	  l1tlb_l2tlb_sack_o.rid = rand() & 0x03;
	  
	  dr_l2_snack_o.nid = rand() & 0x1f;
	  dr_l2_snack_o.l2id = rand() & 0x3f;
	  dr_l2_snack_o.drid = rand() & 0x3f;
	  dr_l2_snack_o.line0 = rand() & 0xffffffffffffffff;
	  dr_l2_snack_o.line1 = rand() & 0xffffffffffffffff;
	  dr_l2_snack_o.line2 = rand() & 0xffffffffffffffff;
	  dr_l2_snack_o.line3 = rand() & 0xffffffffffffffff;
	  dr_l2_snack_o.line4 = rand() & 0xffffffffffffffff;
	  dr_l2_snack_o.line5 = rand() & 0xffffffffffffffff;
	  dr_l2_snack_o.line6 = rand() & 0xffffffffffffffff;
	  dr_l2_snack_o.line7 = rand() & 0xffffffffffffffff;
	  dr_l2_snack_o.paddr = rand() & 0x0002ffffffffffff;
	  
	  dr_l2_dack_o.nid = rand() & 0x1f;
	  dr_l2_dack_o.l2id = rand() & 0x3f;
	  
	  l1_l2tlb_req_list.push_front(l1_l2tlb_req_o);
	  l1tlb_l2tlb_req_list.push_front(l1tlb_l2tlb_req_o);
	  l1tlb_l2tlb_sack_list.push_front(l1tlb_l2tlb_sack_o);
	  dr_l2_snack_list.push_front(dr_l2_snack_o);
	  dr_l2_dack_list.push_front(dr_l2_dack_o);

	  
	  Out_l2tlbtol2_fwd 		l2tlb_l2_fwd_o;
	  Out_l2tlbtol1tlb_snoop	l2tlb_l1tlb_snoop_o;
	  Out_l2tlbtol1tlb_ack		l2tlb_l1tlb_ack_o;
	  Out_l2todr_req 			l2_dr_req_o;
	  Out_l2todr_snoop_ack 		l2_dr_snoop_o;
	  Out_l2todr_disp 			l2_dr_disp_o;
	  
	  l2tlb_l2_fwd_o.1lid = l1_l2tlb_req_o.1lid;
	  l2tlb_l2_fwd_o.prefetch = l1_l2tlb_req_o.prefetch;
	  l2tlb_l2_fwd_o.hpaddr = l1_l2tlb_req_o.hpaddr;
	  l2tlb_l2_fwd_o.paddr = 0x0000000000000000 | (l1_l2tlb_req_o.poffset & 0x0fff) | ((l1_l2tlb_req_o.hpaddr & 0x08ff) << 12);
	  
	  l2tlb_l1tlb_snoop_o.rid = l1tlb_l2tlb_req_o.rid;
	  l2tlb_l1tlb_snoop_o.hpaddr = l1tlb_l2tlb_req_o.disp_hpaddr;
	  
	  l2tlb_l1tlb_ack_o.rid = l1tlb_l2tlb_req_o.rid;
	  l2tlb_l1tlb_ack_o.hpaddr = l1tlb_l2tlb_req_o.disp_hpaddr;
	  l2tlb_l1tlb_ack_o.ppaddr = l1tlb_l2tlb_req_o.disp_hpaddr & 0x03;
	  
	  l2_dr_req_o.nid = dr_l2_snack_o.nid;
	  l2_dr_req_o.l2id = dr_l2_snack_o.l2id;
	  l2_dr_req_o.paddr = dr_l2_snack_o.paddr;
	  
	  l2_dr_snoop_o.l2id = dr_l2_snack_o.l2id;
	  
	  l2_dr_disp_o.nid = dr_l2_snack_o.nid;
	  l2_dr_disp_o.l2id = dr_l2_snack_o.l2id;
	  l2_dr_disp_o.drid = dr_l2_snack_o.drid;
	  l2_dr_disp_o.line0 = dr_l2_snack_o.line0;
	  l2_dr_disp_o.line1 = dr_l2_snack_o.line1;
	  l2_dr_disp_o.line2 = dr_l2_snack_o.line2;
	  l2_dr_disp_o.line3 = dr_l2_snack_o.line3;
	  l2_dr_disp_o.line4 = dr_l2_snack_o.line4;
	  l2_dr_disp_o.line5 = dr_l2_snack_o.line5;
	  l2_dr_disp_o.line6 = dr_l2_snack_o.line6;
	  l2_dr_disp_o.line7 = dr_l2_snack_o.line7;
	  l2_dr_disp_o.paddr = dr_l2_snack_o.paddr;

	  l2tlb_l2_fwd_list.push_front(l2tlb_l2_fwd_o);
	  l2tlb_l1tlb_snoop_list.push_front(l2tlb_l1tlb_snoop_o);
	  l2tlb_l1tlb_ack_list.push_front(l2tlb_l1tlb_ack_o);
	  l2_dr_req_list.push_front(l2_dr_req_o);
	  l2_dr_snoop_list.push_front(l2_dr_snoop_o);
	  l2_dr_disp_list.push_front(l2_dr_disp_o);
    }
    //advance_clock(top,1);
  }
#endif

  printf("performed %lld test in %lld cycles\n",ntests,(long long)global_time/2);
	
  sim_finish(true);
}
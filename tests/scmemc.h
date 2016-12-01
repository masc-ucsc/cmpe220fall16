
// MQ to DC request (LD/STs)
#define CORE_LOPBITS         5
#define CORE_LOP_L08S        0b00001
#define CORE_LOP_L08U        0b00000
#define CORE_LOP_L16S        0b00011
#define CORE_LOP_L16U        0b00010
#define CORE_LOP_L32S        0b00101
#define CORE_LOP_L32U        0b00100
#define CORE_LOP_L64U        0b00110
#define CORE_LOP_L128U       0b01000
#define CORE_LOP_L256U       0b01010
#define CORE_LOP_L512U       0b01100

// Load with line pindown/lock. LOP_XL can be speculative wrong, an
// CORE_MOP_XS00 (no store) must be sent to release the lock for the same
// address. Multiple XL can go to the same line. A abort_retry can be
// generated which will generate the load again later in time (random delay
// but at least 8 cycles)
#define CORE_LOP_XL08S       0b10001
#define CORE_LOP_XL08U       0b10000
#define CORE_LOP_XL16S       0b10011
#define CORE_LOP_XL16U       0b10010
#define CORE_LOP_XL32S       0b10101
#define CORE_LOP_XL32U       0b10100
#define CORE_LOP_XL64U       0b10110
#define CORE_LOP_XL128U      0b11000
#define CORE_LOP_XL256U      0b11010
#define CORE_LOP_XL512U      0b11100

#define CORE_MOPBITS 	7          

#define CORE_MOP_S08           0b0000000
#define CORE_MOP_S16              0b0000010
#define CORE_MOP_S32                0b0000100
#define CORE_MOP_S64           0b0000110
#define CORE_MOP_S128          0b0001000
#define CORE_MOP_S256                 0b0001010
#define CORE_MOP_S512             0b0001100

// Store with line unclock
#define CORE_MOP_XS00          0b1111111
#define CORE_MOP_XS08          0b1000000
#define CORE_MOP_XS16             0b1000010
#define CORE_MOP_XS32               0b1000100
#define CORE_MOP_XS64          0b1000110
#define CORE_MOP_XS128         0b1001000
#define CORE_MOP_XS256                0b1001010
#define CORE_MOP_XS512            0b1001100

// atomic ops also perform a MOP_BEGIN before executed (must have a new
// ckpid)

#define CORE_MOP_BEGIN         0b100000  // Called at decode
#define CORE_MOP_BEGIN_S       0b100010  // Called at decode
#define CORE_MOP_COMMIT        0b100100  // Just Commit. Called at retirement. May be implicit from a new BEGIN*
#define CORE_MOP_CSYNC         0b101000  // Commit & Sync/memfence. Called at retirement
#define CORE_MOP_KILL          0b101100  // Called at retirement or when there was a reflow/misspredict
#define CORE_MOP_RESTART       0b101101  // Called at retirement

// All the WB and TLB commands also force a commit for the current checkpoint,
// and starts a MOP_BEGIN. TLB commands must be called with pnr flag set to
// proceed.
#define CORE_MOP_DWBA          0b110100 // Writeback DC only specific address (no dctlb or L   )
#define CORE_MOP_DWBIA         0b110101 // Writeback/invalidate DC only specific address (no dctlb or L   )
#define CORE_MOP_WBA           0b110110 // Writeback specific address DC & L   
#define CORE_MOP_WBIA          0b110111 // Writeback/Invalidate specific address DC & L    
#define CORE_MOP_DWBC          0b111000 // Writeback            DC only (no dctlb or L    or maintlb)
#define CORE_MOP_DWBIC         0b111001 // Writeback/invalidate DC only (no dctlb or L    or maintlb)
#define CORE_MOP_WBC           0b111010 // Writeback            DC & L   
#define CORE_MOP_WBIC          0b111011 // Writeback/Invalidate DC & dctlb & L    & maintlb
#define CORE_MOP_UTLBIC        0b111100 // invalidate           dctlb (no maintlb)
#define CORE_MOP_TLBI          0b111101 // Invalidate whole TLB (dctlb and maintlb)

// DC -> L    and L    -> DR request
#define SC_CMD_REQBITS         3
#define SC_CMD_REQ_S           0b000  // Get line Shared/Exclusive State
#define SC_CMD_REQ_M           0b001  // get line Modified state, bring data
#define SC_CMD_REQ_NC          0b010  // non-cacheable read
#define SC_CMD_DRAINI          0b110  // writeback invalidate the whole L   /DR. 

// L    -> DC and DR -> L    ack

// snoop and ack command L    -> DC and DR -> L   
#define SC_SCMDBITS          5
#define SC_SCMD_ACK_S        0b00000 // ack with line in Shared State (REQ_S response)
#define SC_SCMD_ACK_E        0b00001 // ack with line in Excluse state (REQ_S response)
#define SC_SCMD_ACK_M        0b00011 // ack with line in Modified state (REQ_M response)
#define SC_SCMD_ACK_PS       0b00100 // ack with line in Shared State (ACK triggered by a prefetch)
#define SC_SCMD_ACK_PE       0b00101 // ack with line in Excluse state (ACK triggered by a prefetch)
#define SC_SCMD_ACK_OTHERI   0b01000 // ack for NC and DRAINI

#define SC_SCMD_PUSH_E       0b10000 // Push line (no req response) with E state. Must cache it
#define SC_SCMD_PUSH_S       0b10001 // Push line (no req response) with S state. Must cache it
#define SC_SCMD_WI           0b10100 // Write back invalidate (ack either snoop_ack or disp with data)
#define SC_SCMD_WS           0b11000 // Write back (even clean) but can keep as shared (ack either snoop_ack or disp with data)
#define SC_SCMD_TS           0b11001 // toggle to share, but not writeback unless dirty
#define SC_SCMD_PE           0b11010 // prefetch triggered cache line push with E state
#define SC_SCMD_PS           0b11011 // prefetch triggered cache line push with S state

// Displace command DC -> L    and L    -> DR 
#define SC_DCMDBITS        2
#define SC_DCMD_WI         0b000 // Line got write-back & invalidated
#define SC_DCMD_WS         0b001 // Line got write-back & kept shared
#define SC_DCMD_I          0b010 // Line got invalidated (no disp)
#define SC_DCMD_NC         0b100 // non-cacheable write going down

#define SC_FAULTBITS         3
#define SC_FAULT_NONE        0b000  // No FAULT generated
#define SC_FAULT_DEV         0b001  // Device memory accessed
#define SC_FAULT_TLBX        0b010  // TLB permission error (More TLB faults may be added)
#define SC_FAULT_OVERFLOW    0b011  // Not performed due to lack of buffering space
#define SC_FAULT_RETRY8      0b100  // retry again in at least 8 cycles
#define SC_FAULT_NCFWD       0b101  // Non-Cacheable Load hit on a "cached" store (Only in TM-WB)
// TODO: Add abort conditions as needed by the core to notify the OS
// accordingly

// Prefetch stats
#define PF_ACKBITS           2
#define PF_ACK_HITMISSD      0b00 // Hit on a pending request
#define PF_ACK_HITMISSP      0b01 // Hit on a pending prefetch
#define PF_ACK_HITHIT        0b10 // Hit on a line already present
#define PF_ACK_MISS          0b11 // MISS in the cache


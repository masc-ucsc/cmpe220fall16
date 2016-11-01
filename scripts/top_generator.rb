
#####################################################################
##  Script that creates a top module for the memory hierarchy      ##
##                                                                 ##
## this script will create a top module and connect blocks,        ##
## based on an input configuration that includes:                  ##
## - number of cores                                               ##
## - number of cache slices per core (fixed to 2, with 2 in ifdef) ##
## - number of directories in the network                          ##
#####################################################################

require 'optparse'

options = {}
optparse = OptionParser.new do |opts|

  opts.banner = "Usage: top_generator.rb [options]"

  opts.on("-v", "--verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end

  opts.on("-c#Cores", "--cores=#Cores", "Number of cores to generate") do |c|
    begin
      options[:cores] = c.to_i
    rescue
      puts "expecting an integer number of cores"
    end
  end

  #opts.on("-t#slices", "--slices=#slices", "Number of dcache slices per core") do |t|
  #  begin
  #    options[:slices] = t.to_i
  #  rescue
  #    puts "expecting an integer number of slices"
  #  end
  #end

  opts.on("-d#Directory", "--dir=#Directory", "Number of directories in the network") do |d|
    begin
      options[:directory] = d.to_i
    rescue
      puts "expecting an integer number of directories"
    end
  end

  opts.on("-h", "--help", "Prints this help menu") do 
    puts opts
    exit
  end
end

optparse.parse!
options[:slices] = 4

if options[:cores] == nil or options[:slices] == nil or options[:directory] == nil
  p optparse.display
  exit 1
end


$icache_core_interface = [
  ["coretoic_pc_valid        ",  "input ", "                   "], 
  ["coretoic_pc_retry        ",  "output", "                   "], 
  ["coretoic_pc              ",  "input ", "I_coretoic_pc_type "], 

  ["ictocore_valid        ",  "output", "                    "], 
  ["ictocore_retry        ",  "input ", "                    "], 
  ["ictocore              ",  "output", "I_ictocore_type     "]
]

$icache_tlb_interface = [
  ["l1tlbtol1_fwd_valid", "input ", "                     "],
  ["l1tlbtol1_fwd_retry", "output", "                     "],
  ["l1tlbtol1_fwd      ", "input ", " I_l1tlbtol1_fwd_type"],

  ["l1tlbtol1_cmd_valid", "input ", "                     "],
  ["l1tlbtol1_cmd_retry", "output", "                     "],
  ["l1tlbtol1_cmd      ", "input ", " I_l1tlbtol1_cmd_type"],
]

$icache_l2tlb_interface = [
  ["l1tol2tlb_req_valid" ,"output", "                     "],
  ["l1tol2tlb_req_retry" ,"input ", "                     "],
  ["l1tol2tlb_req      " ,"output", " I_l1tol2tlb_req_type"],
]

$icache_l2_interface = [
  ["l1tol2_req_valid      ",  "output", "                    "], 
  ["l1tol2_req_retry      ",  "input ", "                    "], 
  ["l1tol2_req            ",  "output", "I_l1tol2_req_type   "], 

  ["l2tol1_snack_valid    ",  "input ", "                    "], 
  ["l2tol1_snack_retry    ",  "output", "                    "], 
  ["l2tol1_snack          ",  "input ", "I_l2tol1_snack_type "], 

  ["l1tol2_snoop_ack_valid",  "output", "                    "], 
  ["l1tol2_snoop_ack_retry",  "input ", "                    "], 
  ["l1tol2_snoop_ack      ",  "output", "I_l2snoop_ack_type  "], 

  #["l1tol2_pfreq_valid    ",  "output", "                    "], 
  #["l1tol2_pfreq_retry    ",  "input ", "                    "], 
  #["l1tol2_pfreq          ",  "output", "I_pftocache_req_type"]
]

$icache_pf_interface = [
  ["cachetopf_stats", "output", "PF_cache_stats_type", "pf_dcstats"]
]

$missing_icache_l2_interface = [
  ["l1tol2_disp_valid", "input ", "                   ", "1'b0"],
  ["l1tol2_disp      ", "input ", " I_l1tol2_disp_type", "{$bits(I_l1tol2_disp_type) {1'b0}}"],

  ["l2tol1_dack_retry", "input ", "                   ", "1'b0"],

  #["l1tol2_pfreq_valid", "input ", "                     ", "1'b0"], 
  #["l1tol2_pfreq      ", "input ", " I_pftocache_req_type", "{$bits(I_pftocache_req_type) {1'b0}}"]
]

$unconnected_icache_l2_interface = [
  ["l1tol2_disp_retry ", "output", "                   "],
  ["l2tol1_dack_valid ", "output", "                   "],
  ["l2tol1_dack       ", "output", "I_l2tol1_dack_type "],
  #["l1tol2_pfreq_retry", "output", "                   "], 
]

$dcache_core_interface = [
  ["coretodc_ld_valid     ", "input ", "                        "],
  ["coretodc_ld_retry     ", "output", "                        "],
  ["coretodc_ld           ", "input ", " I_coretodc_ld_type     "],

  ["dctocore_ld_valid     ", "output", "                        "],
  ["dctocore_ld_retry     ", "input ", "                        "],
  ["dctocore_ld           ", "output", " I_dctocore_ld_type     "],

  ["coretodc_std_valid    ", "input ", "                        "],
  ["coretodc_std_retry    ", "output", "                        "],
  ["coretodc_std          ", "input ", " I_coretodc_std_type    "],

  ["dctocore_std_ack_valid", "output", "                        "],
  ["dctocore_std_ack_retry", "input ", "                        "],
  ["dctocore_std_ack      ", "output", " I_dctocore_std_ack_type"]
]

$dcache_tlb_interface = [
  ["l1tlbtol1_fwd0_valid", "input ", "                    "],
  ["l1tlbtol1_fwd0_retry", "output", "                    "],
  ["l1tlbtol1_fwd0      ", "input ", "I_l1tlbtol1_fwd_type"],

  ["l1tlbtol1_fwd1_valid", "input ", "                    "],
  ["l1tlbtol1_fwd1_retry", "output", "                    "],
  ["l1tlbtol1_fwd1      ", "input ", "I_l1tlbtol1_fwd_type"],

  ["l1tlbtol1_cmd_valid ", "input ", "                    "],
  ["l1tlbtol1_cmd_retry ", "output", "                    "],
  ["l1tlbtol1_cmd       ", "input ", "I_l1tlbtol1_cmd_type"],
]

$dcache_l2_interface = [
  ["l1tol2_req_valid      ", "output", "                        "],
  ["l1tol2_req_retry      ", "input ", "                        "],
  ["l1tol2_req            ", "output", " I_l1tol2_req_type      "],

  ["l2tol1_snack_valid    ", "input ", "                        "],
  ["l2tol1_snack_retry    ", "output", "                        "],
  ["l2tol1_snack          ", "input ", " I_l2tol1_snack_type    "],

  ["l1tol2_snoop_ack_valid", "output", "                        "],
  ["l1tol2_snoop_ack_retry", "input ", "                        "],
  ["l1tol2_snoop_ack      ", "output", " I_l2snoop_ack_type     "],

  ["l1tol2_disp_valid     ", "output", "                        "],
  ["l1tol2_disp_retry     ", "input ", "                        "],
  ["l1tol2_disp           ", "output", " I_l1tol2_disp_type     "],

  ["l2tol1_dack_valid     ", "input ", "                        "],
  ["l2tol1_dack_retry     ", "output", "                        "],
  ["l2tol1_dack           ", "input ", " I_l2tol1_dack_type     "],

]

$dcache_l2tlb_interface = [
  ["l1tol2tlb_req_valid",  "output", "                    "],     
  ["l1tol2tlb_req_retry",  "input ", "                    "],     
  ["l1tol2tlb_req      ",  "output", "I_l1tol2tlb_req_type"],     
]

$l2_directory_pfreq = [
  ["l2todr_pfreq_valid    ", "input ", "                     ", "l2##todr_pfreq_valid    "],
  ["l2todr_pfreq_retry    ", "output", "                     ", "l2##todr_pfreq_retry    "],
  ["l2todr_pfreq          ", "input ", " I_l2todr_pfreq_type ", "l2##todr_pfreq          "],
]

$directory_l2_interface = [
  ["l2todr_req_valid      ", "input ", "                     ", "l2##todr_req_valid      "],
  ["l2todr_req_retry      ", "output", "                     ", "l2##todr_req_retry      "],
  ["l2todr_req            ", "input ", " I_l2todr_req_type   ", "l2##todr_req            "],

  ["drtol2_snack_valid    ", "output", "                     ", "drtol2##_snack_valid    "],
  ["drtol2_snack_retry    ", "input ", "                     ", "drtol2##_snack_retry    "],
  ["drtol2_snack          ", "output", " I_drtol2_snack_type ", "drtol2##_snack          "],

  ["l2todr_disp_valid     ", "input ", "                     ", "l2##todr_disp_valid     "],
  ["l2todr_disp_retry     ", "output", "                     ", "l2##todr_disp_retry     "],
  ["l2todr_disp           ", "input ", " I_l2todr_disp_type  ", "l2##todr_disp           "],

  ["drtol2_dack_valid     ", "output", "                     ", "drtol2##_dack_valid     "],
  ["drtol2_dack_retry     ", "input ", "                     ", "drtol2##_dack_retry     "],
  ["drtol2_dack           ", "output", " I_drtol2_dack_type  ", "drtol2##_dack           "],

  ["l2todr_snoop_ack_valid", "output", "                     ", "l2##todr_snoop_ack_valid"],
  ["l2todr_snoop_ack_retry", "input ", "                     ", "l2##todr_snoop_ack_retry"],
  ["l2todr_snoop_ack      ", "output", " I_drsnoop_ack_type  ", "l2##todr_snoop_ack      "]
]

$directory_memory_interface = [
  ["drtomem_req_valid     ", "output", "                     "],
  ["drtomem_req_retry     ", "input ", "                     "],
  ["drtomem_req           ", "output", " I_drtomem_req_type  "],

  ["memtodr_ack_valid     ", "input ", "                     "],
  ["memtodr_ack_retry     ", "output", "                     "],
  ["memtodr_ack           ", "input ", " I_memtodr_ack_type  "],

  ["drtomem_wb_valid      ", "output", "                     "],
  ["drtomem_wb_retry      ", "input ", "                     "],
  ["drtomem_wb            ", "output", " I_drtomem_wb_type   "],

  ["drtomem_pfreq_valid   ", "output", " logic               "],
  ["drtomem_pfreq_retry   ", "input ", " logic               "],
  ["drtomem_pfreq         ", "output", " I_drtomem_pfreq_type"]
]

$prefetch_core_interface = [
  ["pfgtopfe_op_valid", "input ", "logic               "],
  ["pfgtopfe_op_retry", "output", "logic               "],
  ["pfgtopfe_op      ", "input ", "I_pfgtopfe_op_type  "]
]

$dctlb_prefetch_interface = [
  ["pfetol1tlb_req_valid   ", "input ", "                        ", "pftodc_req##_valid"],
  ["pfetol1tlb_req_retry   ", "output", "                        ", "pftodc_req##_retry"],
  ["pfetol1tlb_req         ", "input ", "I_pfetol1tlb_req_type   ", "pftodc_req##      "],
]

#FIXME: check whether those buses are supposed to go back to the core
$other_prefecther = [
  ["pf_dcstats       ", "output", "PF_cache_stats_type "],
  ["pf_l2stats       ", "output", "PF_cache_stats_type "],
]


$dcache_prefetch_interface = [
  ["cachetopf_stats       ", "output", "PF_cache_stats_type    ", "pf##_dcstats      "]
]


$prefetch_l2cache_interface = [
  #["pftol2_req##_valid", "output", "logic               ", "pftol2_pfreq_valid"],
  #["pftol2_req##_retry", "input ", "logic               ", "pftol2_pfreq_retry"],
  #["pftol2_req##      ", "output", "I_pftocache_req_type", "pftol2_pfreq      "],

  ["pf##_l2stats      ", "input ", "PF_cache_stats_type ", "cachetopf_stats   "]
]

$dctlb_core_interface = [
  ["coretodctlb_ld_valid", "input ", "                      "],
  ["coretodctlb_ld_retry", "output", "                      "],
  ["coretodctlb_ld      ", "input ", " I_coretodctlb_ld_type"],

  ["coretodctlb_st_valid", "input ", "                      "],
  ["coretodctlb_st_retry", "output", "                      "],
  ["coretodctlb_st      ", "input ", " I_coretodctlb_st_type"],
]

$l1tlb_l2tlb_interface = [
  ["l2tlbtol1tlb_snoop_valid" ,"input " ,"                         "],
  ["l2tlbtol1tlb_snoop_retry" ,"output" ,"                         "],
  ["l2tlbtol1tlb_snoop      " ,"input " ,"I_l2tlbtol1tlb_snoop_type"],

  ["l2tlbtol1tlb_ack_valid  " ,"input " ,"                         "],
  ["l2tlbtol1tlb_ack_retry  " ,"output" ,"                         "],
  ["l2tlbtol1tlb_ack        " ,"input " ,"I_l2tlbtol1tlb_ack_type  "],

  ["l1tlbtol2tlb_req_valid  " ,"output" ,"                         "],
  ["l1tlbtol2tlb_req_retry  " ,"input " ,"                         "],
  ["l1tlbtol2tlb_req        " ,"output" ," I_l1tlbtol2tlb_req_type "],

  ["l1tlbtol2tlb_sack_valid " ,"output" ,"                         "],
  ["l1tlbtol2tlb_sack_retry " ,"input " ,"                         "],
  ["l1tlbtol2tlb_sack       " ,"output" ," I_l1tlbtol2tlb_sack_type"],
]

$ictlb_core_interface = [
  ["coretoictlb_pc_valid" ,"input ", "                      "],
  ["coretoictlb_pc_retry" ,"output", "                      "],
  ["coretoictlb_pc      " ,"input ", " I_coretoictlb_pc_type"],
]

$l2tlb_l2_interface = [
  ["l2tlbtol2_fwd_valid", "output", "                     "],
  ["l2tlbtol2_fwd_retry", "input ", "                     "],
  ["l2tlbtol2_fwd      ", "output", " I_l2tlbtol2_fwd_type"],
]

  #["l1tol2_pfreq_valid    ", "output", "                        "],
  #["l1tol2_pfreq_retry    ", "input ", "                        "],
  #["l1tol2_pfreq          ", "output", " I_pftocache_req_type   "]



def icache_ios core_id, f

  f.puts "   // icache core #{core_id}"
  $icache_core_interface.each do |name, direction, type|
    f.puts "  ,#{direction} #{type} core#{core_id}_#{name}"
  end
  f.puts 
end

def slice_ios core_id, slice_id, f

  f.puts "   // dcache core #{core_id}, slice #{slice_id}"
  $dcache_core_interface.each do |name, direction, type|
    f.puts "  ,#{direction} #{type} core#{core_id}_slice#{slice_id}_#{name}"
  end
  $dctlb_core_interface.each do |name,dir,type|
    f.puts "    ,#{dir} #{type} c#{core_id}_s#{slice_id}_#{name}"
  end
  f.puts
end

def core_ios core_id, slice_ids, f
  f.puts "   //******************************************"
  f.puts "   //*  CORE #{core_id}                       *"
  f.puts "   //******************************************//"
  icache_ios core_id, f
  slice_ios core_id, 0, f
  slice_ios core_id, 1, f

  f.puts
  f.puts "`ifdef SC_4PIPE"
  slice_ios core_id, 2, f
  slice_ios core_id, 3, f
  f.puts "`endif"

=begin
  slice_ids.times do |slice|
    slice_ios core_id, 2, f
  end
=end

  f.puts
  f.puts
end


def dr_ios dr_id, f
  f.puts "   //******************************************"
  f.puts "   //*  Directory #{dr_id}                    *"
  f.puts "   //******************************************//"
  $directory_memory_interface.each do |name, direction, type|
    f.puts "  ,#{direction} #{type} dr#{dr_id}_#{name}"
  end 
  f.puts 
end

def pf_ios core_id, f

  f.puts "    // core #{core_id} prefetch "
  $prefetch_core_interface.each do |name, direction, type|
    f.puts "  ,#{direction} #{type} core#{core_id}_#{name}"
  end 
  f.puts 
end


def dctlb_instance core_id, slice_id, f
  f.puts
  f.puts

  $dcache_tlb_interface.each do |name,dir,type_|
    type = (type_ =~ /^\s*$/)? "wire" : type_
    f.puts "  #{type} core#{core_id}_slice#{slice_id}_#{name};"
  end
  f.puts 
  $l1tlb_l2tlb_interface.each do |name,dir,type_|
    type = (type_ =~ /^\s*$/)? "wire" : type_
    f.puts "  #{type} core#{core_id}_slice#{slice_id}_#{name};"
  end
  f.puts 

  $dctlb_prefetch_interface.each do |name,dir,type_,_net_name|
    type = (type_ =~ /^\s*$/)? "wire" : type_
    net_name = _net_name.gsub("##","#{slice_id}")
    f.puts "  #{type} core#{core_id}_slice#{slice_id}_#{net_name};"
  end
  f.puts 

  f.puts "  dctlb dcltb_c#{core_id}s#{slice_id}("
  f.puts "     .clk(clk)"
  f.puts "    ,.reset(reset)"

  $dctlb_core_interface.each do |name,dir,type|
    f.puts "    ,.#{name}(c#{core_id}_s#{slice_id}_#{name})"
  end

  $dctlb_prefetch_interface.each do |name,dir,type,_net_name|
    net_name = _net_name.gsub("##","#{slice_id}")
    f.puts "    ,.#{name}(core#{core_id}_slice#{slice_id}_#{net_name})"
  end

  $dcache_tlb_interface.each do |name,dir,type|
    f.puts "    ,.#{name}(core#{core_id}_slice#{slice_id}_#{name})"
  end

  $l1tlb_l2tlb_interface.each do |name,dir,type|
    f.puts "    ,.#{name}(core#{core_id}_slice#{slice_id}_#{name})"
  end

  f.puts
  f.puts "  );"
  
end

def dcache_instance core_id, slice_id, f
  f.puts
  f.puts
  $dcache_l2_interface.each do |name,dir,type_|
    type = (type_ =~ /^\s*$/)? "wire" : type_
    f.puts "  #{type} core#{core_id}_slice#{slice_id}_#{name};"
  end

  $dcache_prefetch_interface.each do |name,dir,type_, pf_name_|
    pf_name = pf_name_.gsub("##",slice_id.to_s)
    type = (type_ =~ /^\s*$/)? "wire" : type_
    f.puts "  #{type} core#{core_id}_slice#{slice_id}_#{pf_name};"
  end
  f.puts 

  $dcache_l2tlb_interface.each do |name,dir,type_|
    type = (type_ =~ /^\s*$/)? "wire" : type_
    f.puts "  #{type} core#{core_id}_slice#{slice_id}_#{name};"
  end
  f.puts

  f.puts
  f.puts
  f.puts "  dcache_pipe core#{core_id}_slice#{slice_id}_dcache("
  f.puts "     .clk(clk)"
  f.puts "    ,.reset(reset)"

  f.puts

  $dcache_l2_interface.each do |name,dir,type|
    f.puts "    ,.#{name}(core#{core_id}_slice#{slice_id}_#{name})"
  end

  f.puts
  $dcache_l2tlb_interface.each do |name,dir,type|
    f.puts "    ,.#{name}(core#{core_id}_slice#{slice_id}_#{name})"
  end
  f.puts

  $dcache_core_interface.each do |name,dir,type|
    f.puts "    ,.#{name}(core#{core_id}_slice#{slice_id}_#{name})"
  end

  f.puts
  $dcache_prefetch_interface.each do |name,dir,type, pf_name_|
    pf_name = pf_name_.gsub("##",slice_id.to_s)
    f.puts "    ,.#{name}(core#{core_id}_slice#{slice_id}_#{pf_name})"
  end

  f.puts
  $dcache_tlb_interface.each do |name,dir,type|
    f.puts "    ,.#{name}(core#{core_id}_slice#{slice_id}_#{name})"
  end

  f.puts "  );"
  f.puts
end

def l2_arbiter_connections core_id, slice_id, f
  f.puts
  $directory_l2_interface.each do |name,dir,type,net_name_|
    net_name = "#{net_name_.gsub("##","d_#{slice_id}")}"
    f.puts "    ,.#{net_name}(core#{core_id}_slice#{slice_id}_#{name})"
  end
  f.puts
  $l2_directory_pfreq.each do |name,dir,type,net_name_|
    net_name = "#{net_name_.gsub("##","d_#{slice_id}")}"
    f.puts "    ,.#{net_name}(core#{core_id}_slice#{slice_id}_#{name})"
  end
  f.puts 
end

def l2arbiter core_id, slices, f
  f.puts
  f.puts
  $directory_l2_interface.each do |name,dir,type_,net_name_|
    type = (type_ =~ /^\s*$/)? "wire" : type_
    f.puts "  #{type} core#{core_id}_#{name};"
  end
  f.puts
  $l2_directory_pfreq.each do |name,dir,type_,net_name_|
    type = (type_ =~ /^\s*$/)? "wire" : type_
    f.puts "  #{type} core#{core_id}_#{name};"
  end
  f.puts
  f.puts "  arbl2 l2arbiter_core#{core_id}("
  f.puts "     .clk(clk)"
  f.puts "    ,.reset(reset)"
  f.puts

  l2_arbiter_connections core_id, 0, f
  l2_arbiter_connections core_id, 1, f

  f.puts "`ifdef SC_4PIPE"
  l2_arbiter_connections core_id, 2, f
  l2_arbiter_connections core_id, 3, f
  f.puts "`endif"

  f.puts
  $directory_l2_interface.each do |name,dir,type,net_name_|
    f.puts "    ,.#{name}(core#{core_id}_#{name})"
  end
  f.puts
  $l2_directory_pfreq.each do |name,dir,type,net_name_|
    f.puts "    ,.#{name}(core#{core_id}_#{name})"
  end
  f.puts 
  f.puts ");"
  f.puts

end

def l2tlb_connections core_id, slice_id, f
  f.puts
  $directory_l2_interface.each do |name,dir,type,net_name_|
    net_name = net_name_.gsub("##","d_#{slice_id}")
    f.puts "    ,.#{net_name}(core#{core_id}_slice#{slice_id}_l2tlb_#{name})"
  end
  f.puts
  #$l2_directory_pfreq.each do |name,dir,type,net_name_|
  #  net_name = "#{net_name_.gsub("##","d_#{slice_id}")}"
  #  f.puts "    ,.#{net_name}(core#{core_id}_slice#{slice_id}_l2tlb_#{name})"
  #end
  #f.puts
  
end

def l2tlbarbiter core_id, n_slices, f
  f.puts
  f.puts
  $directory_l2_interface.each do |name,dir,type_,net_name_|
    type = (type_ =~ /^\s*$/)? "wire" : type_
    f.puts "  #{type} core#{core_id}_l2tlb_#{name};"
  end
  #$l2_directory_pfreq.each do |name,dir,type_,net_name_|
  #  type = (type_ =~ /^\s*$/)? "wire" : type_
  #  f.puts "  #{type} core#{core_id}_l2tlb_#{name};"
  #end
  f.puts
  f.puts "  arbl2tlb l2tlbarbiter_core#{core_id}("
  f.puts "     .clk(clk)"
  f.puts "    ,.reset(reset)"
  f.puts

  l2tlb_connections core_id, 0, f
  l2tlb_connections core_id, 1, f

  f.puts
  f.puts "`ifdef SC_4PIPE"
  l2tlb_connections core_id, 2, f
  l2tlb_connections core_id, 3, f
  f.puts "`endif"

  $directory_l2_interface.each do |name,dir,type,net_name_|
    f.puts "    ,.#{name}(core#{core_id}_l2tlb_#{name})"
  end
  #$l2_directory_pfreq.each do |name,dir,type,net_name_|
  #  f.puts "    ,.#{name}(core#{core_id}_l2tlb_#{name})"
  #end
  f.puts
  f.puts "  );"
end

def arbiters_instances core, slices, f
  l2arbiter core, slices, f
  l2tlbarbiter core, slices, f
end


def l1cache_all core_id, slices, f
  dcache_instance core_id, 0, f
  dctlb_instance core_id, 0, f

  dcache_instance core_id, 1, f
  dctlb_instance core_id, 1, f

  f.puts
  f.puts "`ifdef SC_4PIPE"
  dcache_instance core_id, 2, f
  dctlb_instance core_id, 2, f

  dcache_instance core_id, 3, f
  dctlb_instance core_id, 3, f
  f.puts "`endif"

  icache_instance core_id, f
end

def l2tlb_instance core_id, slice_id, f
  f.puts
  f.puts
  $directory_l2_interface.each do |name,dir,type_,net_name_|
    type = (type_ =~ /^\s*$/)? "wire" : type_
    #net_name = "c#{core_id}_#{net_name_.gsub("##","dtlb_#{slice_id}")}"
    f.puts "  #{type} core#{core_id}_slice#{slice_id}_l2tlb_#{name};"
  end

  f.puts "  l2tlb l2tlb_core#{core_id}_slice#{slice_id}("
  f.puts "     .clk(clk)"
  f.puts "    ,.reset(reset)"

  f.puts
  
  $l1tlb_l2tlb_interface.each do |name,dir,type|
    f.puts "    ,.#{name}(core#{core_id}_slice#{slice_id}_#{name})"
  end
  f.puts 

  $dcache_l2tlb_interface.each do |name,dir,type|
    f.puts "    ,.#{name}(core#{core_id}_slice#{slice_id}_#{name})"
  end
  f.puts

  $l2tlb_l2_interface.each do |name,dir,type|
    f.puts "    ,.#{name}(core#{core_id}_slice#{slice_id}_#{name})"
  end

  f.puts
  $directory_l2_interface.each do |name,dir,type,net_name_|
    #net_name = "c#{core_id}_#{net_name_.gsub("##","dtlb_#{slice_id}")}"
    f.puts "    ,.#{name}(core#{core_id}_slice#{slice_id}_l2tlb_#{name})"
  end
  f.puts
  f.puts "  );"
end


def l2cache_all core_id, slices, f
  l2d_instance core_id, 0, f
  l2tlb_instance core_id, 0, f

  l2d_instance core_id, 1, f
  l2tlb_instance core_id, 1, f

  f.puts
  f.puts "`ifdef SC_4PIPE"
  l2d_instance core_id, 2, f
  l2tlb_instance core_id, 2, f

  l2d_instance core_id, 3, f
  l2tlb_instance core_id, 3, f
  f.puts "`endif"

  l2i_instance core_id, f
end

def icache_instance core_id, f
  f.puts
  f.puts
  $icache_l2_interface.each do |name,dir,type_|
    type = (type_ =~ /^\s*$/)? "wire" : type_
    f.puts "  #{type} core#{core_id}_#{name};"
  end
  f.puts
  $icache_tlb_interface.each do |name,dir,type_|
    type = (type_ =~ /^\s*$/)? "wire" : type_
    f.puts "  #{type} core#{core_id}_#{name};"
  end
  f.puts
  $icache_l2tlb_interface.each do |name,dir,type_|
    type = (type_ =~ /^\s*$/)? "wire" : type_
    f.puts "  #{type} core#{core_id}_#{name};"
  end
  f.puts
  $icache_pf_interface.each do |name,dir,type_,pf_name|
    type = (type_ =~ /^\s*$/)? "wire" : type_
    f.puts "  #{type} core#{core_id}_#{name};"
  end

  f.puts
  f.puts "  icache core#{core_id}_icache("
  f.puts "     .clk(clk)"
  f.puts "    ,.reset(reset)"

  f.puts

  $icache_l2_interface.each do |name,dir,type|
    f.puts "    ,.#{name}(core#{core_id}_#{name})"
  end

  f.puts

  $icache_tlb_interface.each do |name,dir,type|
    f.puts "    ,.#{name}(core#{core_id}_#{name})"
  end

  f.puts
  $icache_l2tlb_interface.each do |name,dir,type|
    f.puts "    ,.#{name}(core#{core_id}_#{name})"
  end

  f.puts
  $icache_pf_interface.each do |name,dir,type,pf_name|
    f.puts "    ,.#{name}(core#{core_id}_#{name})"
  end
  f.puts

  $icache_core_interface.each do |name,dir,type|
    f.puts "    ,.#{name}(core#{core_id}_#{name})"
  end

  f.puts "  );"
  f.puts
end

def l2d_instance core_id, slice_id, f

  f.puts
  f.puts
  $prefetch_l2cache_interface.each do |pf_name_,dir,type_,name|
    pf_name = pf_name_.gsub("##",slice_id.to_s)
    type = (type_ =~ /^\s*$/)? "wire" : type_
    f.puts "  #{type} core#{core_id}_slice#{slice_id}_#{pf_name};"
  end

  $directory_l2_interface.each do |name,dir,type_|
    type = (type_ =~ /^\s*$/)? "wire" : type_
    f.puts "  #{type} core#{core_id}_slice#{slice_id}_#{name};"
  end
  f.puts
  $dcache_prefetch_interface.each do |name,dir,type_, pf_name_|
    pf_name = pf_name_.gsub("##",slice_id.to_s)
    type = (type_ =~ /^\s*$/)? "wire" : type_
    f.puts "  #{type} core#{core_id}_l2d_slice#{slice_id}_#{pf_name};"
  end
  f.puts
  $l2_directory_pfreq.each do |name,dir,type_|
    type = (type_ =~ /^\s*$/)? "wire" : type_
    f.puts "  #{type} core#{core_id}_slice#{slice_id}_#{name};"
  end
  f.puts
  $l2tlb_l2_interface.each do |name,dir,type_|
    type = (type_ =~ /^\s*$/)? "wire" : type_
    f.puts "  #{type} core#{core_id}_slice#{slice_id}_#{name};"
  end

  f.puts
  f.puts "  l2cache_pipe core#{core_id}_l2d_slice#{slice_id}("
  f.puts "     .clk(clk)"
  f.puts "    ,.reset(reset)"

  f.puts

  $dcache_l2_interface.each do |name,dir,type|
    f.puts "    ,.#{name}(core#{core_id}_slice#{slice_id}_#{name})"
  end

  f.puts

  $l2_directory_pfreq.each do |name,dir,type|
    f.puts "    ,.#{name}(core#{core_id}_slice#{slice_id}_#{name})"
  end

  f.puts

  $l2tlb_l2_interface.each do |name,dir,type|
    f.puts "    ,.#{name}(core#{core_id}_slice#{slice_id}_#{name})"
  end

  f.puts
  $directory_l2_interface.each do |name,dir,type|
    f.puts "    ,.#{name}(core#{core_id}_slice#{slice_id}_#{name})"
  end

  $prefetch_l2cache_interface.each do |pf_name_,dir,type,name|
    pf_name = pf_name_.gsub("##",slice_id.to_s)
    f.puts "    ,.#{name}(core#{core_id}_slice#{slice_id}_#{pf_name})"
  end

  f.puts "  );"
  f.puts
end

def l2i_instance core_id, f

  f.puts
  f.puts
  $prefetch_l2cache_interface.each do |pf_name_,dir,type_,name|
    pf_name = pf_name_.gsub("##","icache")
    type = (type_ =~ /^\s*$/)? "wire" : type_
    f.puts "  #{type} core#{core_id}_icache_#{pf_name};"
  end
  $l2tlb_l2_interface.each do |name,dir,type_|
    type = (type_ =~ /^\s*$/)? "wire" : type_
    f.puts "  #{type} core#{core_id}_icache_#{name};"
  end
  $l2_directory_pfreq.each do |name,dir,type_|
    type = (type_ =~ /^\s*$/)? "wire" : type_
    f.puts "  #{type} core#{core_id}_icache_#{name};"
  end

  $unconnected_icache_l2_interface.each do |name,dir,type_|
    type = (type_ =~ /^\s*$/)? "wire" : type_
    f.puts "  #{type} unconnected_#{core_id}_icache_#{name};"
  end

  $directory_l2_interface.each do |name,dir,type_|
    type = (type_ =~ /^\s*$/)? "wire" : type_
    f.puts "  #{type} core#{core_id}_icache_#{name};"
  end
  f.puts

  f.puts "  l2cache_pipe core#{core_id}_l2icache("
  f.puts "     .clk(clk)"
  f.puts "    ,.reset(reset)"

  f.puts

  $icache_l2_interface.each do |name,dir,type|
    f.puts "    ,.#{name}(core#{core_id}_#{name})"
  end

  f.puts

  $missing_icache_l2_interface.each do |name,dir,type,value|
    f.puts "    ,.#{name}(#{value})"
  end
  f.puts

  $directory_l2_interface.each do |name,dir,type|
    f.puts "    ,.#{name}(core#{core_id}_icache_#{name})"
  end
  f.puts
  $l2tlb_l2_interface.each do |name,dir,type|
    f.puts "    ,.#{name}(core#{core_id}_icache_#{name})"
  end

  f.puts
  $l2_directory_pfreq.each do |name,dir,type|
    f.puts "    ,.#{name}(core#{core_id}_icache_#{name})"
  end

  f.puts

  $prefetch_l2cache_interface.each do |pf_name_,dir,type,name|
    pf_name = pf_name_.gsub("##","icache")
    f.puts "    ,.#{name}(core#{core_id}_icache_#{pf_name})"
  end

  $unconnected_icache_l2_interface.each do |name,dir,type|
    f.puts "    ,.#{name}(unconnected_#{core_id}_icache_#{name})"
  end

  f.puts "  );"
  f.puts
end

def prefetch_instance core_id, f
  f.puts

  $other_prefecther.each do |name,dir,type_|
    type = (type_ =~ /^\s*$/)? "wire" : type_
    f.puts "  #{type} unconnected_pfe#{core_id}_#{name};"
  end

  f.puts 
  f.puts "  pfengine core#{core_id}_pfe("
  f.puts "     .clk(clk)"
  f.puts "    ,.reset(reset)"

  f.puts

  $prefetch_core_interface.each do |name,dir,type|
    f.puts "    ,.#{name}(core#{core_id}_#{name})"
  end

  #f.puts
  #$icache_pf_interface.each do |name,dir,type,pf_name|
  #  f.puts "    ,.#{pf_name}(core#{core_id}_#{name})"
  #end
  f.puts

  2.times do |slice_id|
    $prefetch_l2cache_interface.each do |pf_name_,dir,type,name|
      pf_name = pf_name_.gsub("##",slice_id.to_s)
      f.puts "    ,.#{pf_name}(core#{core_id}_slice#{slice_id}_#{pf_name})"
    end

    f.puts
    #$dcache_prefetch_interface.each do |name,dir,type, pf_name_|
    $dctlb_prefetch_interface.each do |name,dir,type,_pf_name|
      pf_name = _pf_name.gsub("##",slice_id.to_s)
      f.puts "    ,.#{pf_name}(core#{core_id}_slice#{slice_id}_#{pf_name})"
    end
    f.puts

    $dcache_prefetch_interface.each do |name,dir,type,_pf_name|
      pf_name = _pf_name.gsub("##",slice_id.to_s)
      f.puts "    ,.#{pf_name}(core#{core_id}_slice#{slice_id}_#{pf_name})"
    end
    f.puts

  end

  f.puts "`ifdef SC_4PIPE"
  (2..3).each do |slice_id|
    $prefetch_l2cache_interface.each do |pf_name_,dir,type,name|
      pf_name = pf_name_.gsub("##",slice_id.to_s)
      f.puts "    ,.#{pf_name}(core#{core_id}_slice#{slice_id}_#{pf_name})"
    end
    f.puts

    #$dcache_prefetch_interface.each do |name,dir,type, pf_name_|
    $dctlb_prefetch_interface.each do |name,dir,type,_pf_name|
      pf_name = _pf_name.gsub("##",slice_id.to_s)
      f.puts "    ,.#{pf_name}(core#{core_id}_slice#{slice_id}_#{pf_name})"
    end
    f.puts

    $dcache_prefetch_interface.each do |name,dir,type,_pf_name|
      pf_name = _pf_name.gsub("##",slice_id.to_s)
      f.puts "    ,.#{pf_name}(core#{core_id}_slice#{slice_id}_#{pf_name})"
    end
    f.puts

  end
  f.puts "`endif"

  f.puts 
  $other_prefecther.each do |name,dir,type|
    f.puts "    ,.#{name}(unconnected_pfe#{core_id}_#{name})"
  end

  f.puts "  );"
end

def network_instance n_cores, n_drs, f

  n_drs.times do |dr_id|
    $directory_l2_interface.each do |name,dir,type_,net_name_|
      type = (type_ =~ /^\s*$/)? "wire" : type_
      f.puts "  #{type} dr#{dr_id}_#{name};"
    end

    $l2_directory_pfreq.each do |name,dir,type_,net_name_|
      type = (type_ =~ /^\s*$/)? "wire" : type_
      f.puts "  #{type} dr#{dr_id}_tlb_#{name};"
    end
  end

  f.puts
  f.puts "  net_#{n_cores}core#{n_drs}dr network("
  f.puts "     .clk(clk)"
  f.puts "    ,.reset(reset)"
  f.puts

  n_cores.times do |core_id|
    f.puts "    // core #{core_id} l2i and l2d"

    $directory_l2_interface.each do |name,dir,type,net_name_|
      net_name = "c#{core_id}_#{net_name_.gsub("##","i")}"
      f.puts "    ,.#{net_name}(core#{core_id}_icache_#{name})"
    end

    f.puts

    $directory_l2_interface.each do |name,dir,type,net_name_|
      net_name = "c#{core_id}_#{net_name_.gsub("##","it")}"
      f.puts "    ,.#{net_name}(core#{core_id}_icache_#{name})"
    end

    f.puts

    $l2_directory_pfreq.each do |name,dir,type,net_name_|
      net_name = "c#{core_id}_#{net_name_.gsub("##","i")}"
      f.puts "    ,.#{net_name}(core#{core_id}_icache_#{name})"
    end


    #l2 connections from arbiter
    f.puts
    $directory_l2_interface.each do |name,dir,type,net_name_|
      #net_name = "c#{core_id}_#{net_name_.gsub("##","d_#{slice_id}")}"
      net_name = "c#{core_id}_#{net_name_.gsub("##","d_0")}"
      f.puts "    ,.#{net_name}(core#{core_id}_#{name})"
    end
    $l2_directory_pfreq.each do |name,dir,type,net_name_|
      net_name = "c#{core_id}_#{net_name_.gsub("##","d_0")}"
      f.puts "    ,.#{net_name}(core#{core_id}_#{name})"
    end

    #l2tlb connections from arbiter
    f.puts
    $directory_l2_interface.each do |name,dir,type,net_name_|
      #net_name = "c#{core_id}_#{net_name_.gsub("##","d_#{slice_id}")}"
      net_name = "c#{core_id}_#{net_name_.gsub("##","dt_0")}"
      f.puts "    ,.#{net_name}(core#{core_id}_l2tlb_#{name})"
    end
    #$l2_directory_pfreq.each do |name,dir,type,net_name_|
    #  net_name = "c#{core_id}_#{net_name_.gsub("##","dt_0")}"
    #  f.puts "    ,.#{net_name}(core#{core_id}_l2tlb_#{name})"
    #end
=begin
    2.times do |slice_id|
      f.puts "    //L2D_#{slice_id}"
      $directory_l2_interface.each do |name,dir,type,net_name_|
        net_name = "c#{core_id}_#{net_name_.gsub("##","d_#{slice_id}")}"
        f.puts "    ,.#{net_name}(core#{core_id}_slice#{slice_id}_#{name})"
      end
      f.puts
    end

    f.puts
    f.puts "`ifdef SC_4PIPE"
    (2..3).each do |slice_id|
      f.puts "    //L2D_#{slice_id}"
      $directory_l2_interface.each do |name,dir,type,net_name_|
        net_name = "c#{core_id}_#{net_name_.gsub("##","d_#{slice_id}")}"
        f.puts "    ,.#{net_name}(core#{core_id}_slice#{slice_id}_#{name})"
      end
      f.puts
    end
    f.puts "`endif"
=end
  end

  f.puts
  n_drs.times do |dr_id|
    f.puts "    // Directory #{dr_id} interface"
    $directory_l2_interface.each do |name_,dir,type,net_name_|
      name = name_.gsub("drtol2","dr#{dr_id}tol2").gsub("l2todr","l2todr#{dr_id}")
      f.puts "    ,.#{name}(dr#{dr_id}_#{name_})"
    end

    f.puts
    $l2_directory_pfreq.each do |name_,dir,type,net_name_|
      name = name_.gsub("drtol2","dr#{dr_id}tol2").gsub("l2todr","l2todr#{dr_id}")
      f.puts "    ,.#{name}(dr#{dr_id}_tlb_#{name_})"
    end
    f.puts
  end

  f.puts "  );"
  f.puts
end

def dr_instance dr_id, f
  f.puts
  f.puts "  directory_bank dr_#{dr_id}("
  f.puts "     .clk(clk)"
  f.puts "    ,.reset(reset)"
  f.puts

  $directory_l2_interface.each do |name,dir,type,net_name_|
    f.puts "    ,.#{name}(dr#{dr_id}_#{name})"
  end

  $l2_directory_pfreq.each do |name,dir,type,net_name_|
    f.puts "    ,.#{name}(dr#{dr_id}_tlb_#{name})"
  end

  $directory_memory_interface.each do |name, direction, type|
    f.puts "    ,.#{name}(dr#{dr_id}_#{name})"
  end 
  f.puts "  );"
  f.puts
end

def dr_all n_drs, f
  n_drs.times do |dr_id|
    dr_instance dr_id, f
    f.puts
  end
end

f = STDOUT

f.puts "// file automatically generated by top_generator script"
f.puts "// this is a memory hierarchy done as a class project for CMPE220 at UCSC"
f.puts "// this specific file was generated for:"
f.puts "// #{options[:cores]} core(s), "
f.puts "// #{options[:slices]} data cache slice(s) per core, and"
f.puts "// #{options[:directory]} directory(ies)"
2.times { f.puts }

f.puts '`include "scmem.vh"'

f.puts "module top_#{options[:cores]}core#{options[:directory]}dr("
f.puts "  /* verilator lint_off UNUSED */"
f.puts "  /* verilator lint_off UNDRIVEN */"

f.puts "   input clk"
f.puts "  ,input reset"
f.puts

  options[:cores].times do |core|
    core_ios core, options[:slices], f
    pf_ios core, f
  end

  options[:directory].times do |dir|
    dr_ios dir, f
  end

f.puts ");"

options[:cores].times do |core|
  l1cache_all core, options[:slices], f
  l2cache_all core, options[:slices], f
  arbiters_instances core, options[:slices], f

  prefetch_instance core, f
end

dr_all options[:directory], f
network_instance options[:cores], options[:directory], f

f.puts "  /* verilator lint_on UNUSED */"
f.puts "  /* verilator lint_on UNDRIVEN */"
f.puts "endmodule"


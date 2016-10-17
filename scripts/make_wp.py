# makes a wrapper module (no wires) for the net_2core2dr.v file by breaking
# the structs and using the types for each component of the struct to make a
# serialized interface


# TO USE: $ python2 make_wp.py filename.v > filename_wp.v
# dont forget to rename the module in the generated .v file
# if the struct you need is not here, add to dict


import sys

dict = {'I_drtol2_snack_type': [
            ('SC_nodeid_type\t', 'nid'),
            ('L2_reqid_type\t', 'l2id'),
            ('DR_reqid_type\t', 'drid'),
            ('SC_snack_type\t', 'snack'),
            ('SC_line_type\t', 'line'),
            ('SC_paddr_type\t', 'paddr')],
        'I_l2todr_disp_type':[
            ('SC_nodeid_type\t', 'nid'),
            ('L2_reqid_type\t','l2id'),
            ('DR_reqid_type\t', 'drid'),
            ('SC_disp_mask_type', 'mask'),
            ('SC_dcmd_type\t', 'dcmd'),
            ('SC_line_type\t', 'line'),
            ('SC_paddr_type\t', 'paddr')],
        'I_drtol2_dack_type':[
            ('SC_nodeid_type\t', 'nid'),
            ('L2_reqid_type\t', 'l2id')],
        'I_l2snoop_ack_type':[
            ('L2_reqid_type\t', 'l2id')],
        'I_drsnoop_ack_type':[
            ('DR_reqid_type\t', 'drid')],
        'I_l2todr_req_type':[
            ('SC_nodeid_type\t', 'nid'),
            ('L2_reqid_type\t','l2id'),
            ('SC_cmd_type\t\t', 'cmd'),
            ('SC_paddr_type\t', 'paddr')],
        'I_drtomem_wb_type':[
            ('SC_line_type\t', 'line'),
            ('SC_paddr_type\t', 'paddr')],
        'I_drtomem_req_type':[
            ('DR_reqid_type\t', 'drid'),
            ('SC_cmd_type\t\t', 'cmd'),
            ('SC_paddr_type\t', 'paddr')],
        'I_drtomem_pfreq_type':[
            ('SC_paddr_type\t', 'paddr')],
        'I_coretodc_ld_type':[
            ('DC_ckpid_type\t', 'ckpid'),
            ('CORE_reqid_type\t', 'coreid'),
            ('CORE_lop_type\t', 'lop'),
            ('logic\t\t\t', 'pnr'),
            ('SC_pcsign_type\t', 'pcsign'),
            ('SC_laddr_type\t', 'laddr'),
            ('SC_sptbr_type\t', 'sptbr')],
        'I_pfgtopfe_op_type':[
            ('PF_delta_type\t', 'd'),
            ('PF_weigth_type\t', 'w'),
            ('SC_pcsign_type\t', 'pcsign'),
            ('SC_laddr_type\t', 'laddr'),
            ('SC_sptbr_type\t', 'sptbr')],
        'I_memtodr_ack_type':[
            ('DR_reqid_type\t', 'drid'),
            ('SC_snack_type\t', 'ack'),
            ('SC_line_type\t', 'line')],
        'I_dctocore_std_ack_type':[
            ('SC_abort_type\t', 'aborted'),
            ('CORE_reqid_type\t', 'coreid')],
        'I_ictocore_type':[
            ('SC_abort_type\t', 'aborted'),
            ('IC_fwidth_type\t', 'data')],
        'I_coretodc_std_type':[
            ('DC_ckpid_type\t', 'ckpid'),
            ('CORE_reqid_type\t', 'coreid'),
            ('CORE_mop_type\t', 'mop'),
            ('logic\t\t\t', 'pnr'),
            ('SC_pcsign_type\t', 'pcsign'),
            ('SC_laddr_type\t', 'laddr'),
            ('SC_sptbr_type\t', 'sptbr'),
            ('SC_line_type\t', 'data')]
        }

content = []
new_content = []

with open(sys.argv[1]) as f:
    content = f.readlines()


for line in content:
    words = line.split()
    if len(words) > 0 and (words[0] == ',input' or words[0] == ',output' or words[0] == 'input'):
        if words[1] in dict.keys():
            types = dict.get(words[1])
            print "\t//" + line,
            for type in types:
                print '\t' + words[0] + '\t'+ type[0] +'\t' + words[2] + '_' + type[1]
                #this should generate the assign statements that are needed for breaking the structs
                #not tested at all. Uncomment line below to see if it works for you.

                #new_content.append('\tassign ' + words[2] + '_' + type[1] + ' = ' + words[2] + '.' + type[1] + ';')
        elif words[1] == 'logic':
            print '\t' + words[0] + '\tlogic\t\t\t\t' +  words[2]
        else:
            print '\t' + words[0] + '\tlogic\t\t\t\t' +  words[1]
    else:
        if len(words) > 0 and words[0] == 'endmodule':
            #this should print out all the "assigns" that are needed from breaking the structs
            for new_line in new_content:
                print new_line
            print line,
        else:
            print line,

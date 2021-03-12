function [flowEntry, flowSrcIp, flowDstIp]  = setFlowEntry(pl, flowEntry, flowTraceTable, i)
    sip = strsplit(flowTraceTable{i, 'SrcIp'}{1}, '.');
    sip = cellfun(@(x) str2num(x), sip);
    sip = dec2bin(sip, 8);
    sip = sip';
    
    dip = strsplit(flowTraceTable{i, 'DstIp'}{1}, '.');
    dip = cellfun(@(x) str2num(x), dip);
    dip = dec2bin(dip, 8);
    dip = dip';
    
    % 32-bit IP address
    flowSrcIp = sip(1:32);
    flowDstIp = dip(1:32);
    
    flowEntry.srcIp = sip(1:pl);
    flowEntry.dstIp = dip(1:pl);
end
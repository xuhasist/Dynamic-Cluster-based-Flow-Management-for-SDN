function [srcNodeName, dstNodeName, flowRate, flowTraceTable, flowEntry] = ...
    setFlowInfo_perFlow(i, flowStartDatetime, flowEndDatetime, linkBwdUnit, hostIpTable, flowTraceTable)
            
    rows = strcmp(hostIpTable.IP, flowTraceTable{i,'SrcIp'}{1});
    srcNodeName = hostIpTable{rows, {'Host'}}{1};
    
    rows = strcmp(hostIpTable.IP, flowTraceTable{i,'DstIp'}{1});
    dstNodeName = hostIpTable{rows, {'Host'}}{1};
    
    flowRate = (10 * linkBwdUnit) / 8; % Byte/s
    flowTraceTable.Rate_bps(i) = flowRate * 8;

    flowEntry = struct();
    flowEntry.startTime = datestr(flowStartDatetime, 'yyyy-mm-dd HH:MM:ss.FFF');
    flowEntry.endTime = datestr(flowEndDatetime + seconds(60), 'yyyy-mm-dd HH:MM:ss.FFF');
    flowEntry.vlan = -1;
end
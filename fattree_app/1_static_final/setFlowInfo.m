function [srcNodeName, dstNodeName, flowRate, flowTraceTable, flowEntry] = ...
    setFlowInfo(i, flowStartDatetime, flowEndDatetime, linkBwdUnit, hostIpTable, flowTraceTable)
            
    % get flow src/dst host
    rows = strcmp(hostIpTable.IP, flowTraceTable{i,'SrcIp'}{1});
    srcNodeName = hostIpTable{rows, {'Host'}}{1};
    
    rows = strcmp(hostIpTable.IP, flowTraceTable{i,'DstIp'}{1});
    dstNodeName = hostIpTable{rows, {'Host'}}{1};
    %
    
    % set flow load
    flowRate = (10 * linkBwdUnit) / 8; % 10Kbps / 8 = 10KB/s
    flowTraceTable.Rate_bps(i) = flowRate * 8; % 10Kbps

    % initial flow entry
    flowEntry = struct();
    flowEntry.startTime = datestr(flowStartDatetime, 'yyyy-mm-dd HH:MM:ss.FFF');
    flowEntry.endTime = datestr(flowEndDatetime + seconds(60), 'yyyy-mm-dd HH:MM:ss.FFF');
    flowEntry.vlan = flowTraceTable{i, 'Vlan'};
end
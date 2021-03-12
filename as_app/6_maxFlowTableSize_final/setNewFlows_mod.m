function flowTraceTable = setNewFlows_mod(flowNum, pickFlowTrace, flow_srcIp, flow_dstIp, timeout)
    allFlowTrace = textread('pktTrace_5min.txt', '%s', 'delimiter', '\n', 'bufsize', 2147483647);
    flowTraceTable = table();
    
    for i = 1:flowNum
        flowTrace = allFlowTrace{pickFlowTrace(i)};
        flowTrace = jsondecode(flowTrace);
        
        flowDatetime = datetime({flowTrace.send.time}, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
        
        % pick src & dst ip randomly
        srcIp = flow_srcIp{i};
        dstIp = flow_dstIp{i};
        
        % flow timeout is 60 seconds
        rows = seconds(flowDatetime - circshift(flowDatetime, 1)) > timeout;
        if any(rows)
            s = 1;
            newFlowId = find(rows);
            for j = 1:length(newFlowId)
                e = newFlowId(j) - 1;
                
                startDatetime = flowTrace.send(s).time;
                endDatetime = flowTrace.send(e).time;
                
                flowTraceTable = [flowTraceTable; {startDatetime, endDatetime, srcIp, dstIp}];
                
                s = newFlowId(j);
            end
            
            startDatetime = flowTrace.send(s).time;
            endDatetime = flowTrace.end_date_time;

            flowTraceTable = [flowTraceTable; {startDatetime, endDatetime, srcIp, dstIp}];

        else
            startDatetime = flowTrace.start_date_time;
            endDatetime = flowTrace.end_date_time;

            flowTraceTable = [flowTraceTable; {startDatetime, endDatetime, srcIp, dstIp}];
        end
    end
    
    flowTraceTable.Properties.VariableNames = {'StartDatetime', 'EndDatetime', 'SrcIp', 'DstIp'};
    flowTraceTable = sortrows(flowTraceTable, 'StartDatetime');
    
    clearvars allPktTrace
end
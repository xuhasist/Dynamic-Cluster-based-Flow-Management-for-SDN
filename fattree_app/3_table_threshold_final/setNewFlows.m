function flowTraceTable = setNewFlows(flowNum, IP)
    allFlowTrace = textread('pktTrace_5min.txt', '%s', 'delimiter', '\n', 'bufsize', 2147483647);
    flowTraceNum = length(allFlowTrace);
    pickFlowTrace = randi(flowTraceNum, 1, flowNum);
    
    flowTraceTable = table();
    
    for i = 1:flowNum
        flowTrace = allFlowTrace{pickFlowTrace(i)};
        flowTrace = jsondecode(flowTrace);
        
        flowDatetime = datetime({flowTrace.send.time}, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
        
        % pick src & dst ip randomly
        node = randperm(length(IP), 2);
        srcIp = IP{node(1)};
        dstIp = IP{node(2)};
        
        % flow timeout is 60 seconds
        rows = seconds(flowDatetime - circshift(flowDatetime, 1)) > 60;
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
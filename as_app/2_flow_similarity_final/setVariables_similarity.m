function [swInfTable, swFlowEntryStruct, hostIpTable, linkTable, linkThputStruct, flowTraceTable, flowSequence] = ...
    setVariables_similarity(swNum, srcNode, dstNode, srcInf, dstInf, g, hostNum, IP, flowNum)

    swInfTable = table(srcNode, dstNode, srcInf, dstInf);
    swInfTable.Properties.VariableNames = {'SrcNode', 'DstNode', 'SrcInf', 'DstInf'};
    
    hostIpTable = table(g.Nodes.Name(1+swNum:swNum+hostNum), IP');
    hostIpTable.Properties.VariableNames = {'Host', 'IP'};

    swFlowEntryStruct = struct([]);
    for i = 1:swNum
       swFlowEntryStruct(i).entry = struct([]);
    end

    linkTable = g.Edges;

    linkThputStruct = struct([]);
    for i = 1:size(linkTable, 1)
        linkThputStruct(i).entry = struct([]);
    end
    
    allFlowTrace = textread('pktTrace_5min.txt', '%s', 'delimiter', '\n', 'bufsize', 2147483647);
    flowTraceNum = length(allFlowTrace);
    pickFlowTrace = randi(flowTraceNum, 1, flowNum);
    
    start_time = datetime('2009-12-18 00:32:26.775', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    end_time = datetime('2009-12-18 00:38:26.775', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    slot_num = seconds(end_time - start_time) / 3;
    
    flowSequence = [];
    flowTraceTable = table();
    
    for i = 1:flowNum
        flowTrace = allFlowTrace{pickFlowTrace(i)};
        flowTrace = jsondecode(flowTrace);
        
        flowDatetime = datetime({flowTrace.send.time}, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
        
        loc = floor(seconds(flowDatetime - start_time) / 3) + 1;
        loc = [loc, (loc(end):loc(end)+60/3)];
        
        % pick src & dst ip randomly
        node = randperm(length(IP), 2);
        srcIp = IP{node(1)};
        dstIp = IP{node(2)};
        
        vlan = -1;

        % flow timeout is 60 seconds
        rows = seconds(flowDatetime - circshift(flowDatetime, 1)) > 60/3;
        if any(rows)
            s = 1;
            newFlowId = find(rows);
            for j = 1:length(newFlowId)
                e = newFlowId(j) - 1;
                loc = [loc, (loc(e):loc(e)+60/3)];
                
                startDatetime = flowTrace.send(s).time;
                endDatetime = flowTrace.send(e).time;
                
                flowTraceTable = [flowTraceTable; {i, startDatetime, endDatetime, srcIp, dstIp, vlan}];
                
                s = newFlowId(j);
            end
            
                startDatetime = flowTrace.send(s).time;
                endDatetime = flowTrace.end_date_time;

                flowTraceTable = [flowTraceTable; {i, startDatetime, endDatetime, srcIp, dstIp, vlan}];

            else
                startDatetime = flowTrace.start_date_time;
                endDatetime = flowTrace.end_date_time;

                flowTraceTable = [flowTraceTable; {i, startDatetime, endDatetime, srcIp, dstIp, vlan}];
        end
        flowSequence(i,:) = zeros(slot_num, 1);
        flowSequence(i, loc) = 1;
    end

    flowTraceTable.Properties.VariableNames = {'Index', 'StartDatetime', 'EndDatetime', 'SrcIp', 'DstIp', 'Vlan'};
    flowTraceTable = sortrows(flowTraceTable, 'StartDatetime');
    
    clearvars allFlowTrace
end
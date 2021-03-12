function [swInfTable, swFlowEntryStruct, hostIpTable, linkTable, linkThputStruct, initialClusterTable, flowSequence] = ...
    setVariables(swNum, srcNode, dstNode, srcInf, dstInf, g, hostNum, IP)

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
    
    allFlowTrace = textread('pktTrace_3min.txt', '%s', 'delimiter', '\n', 'bufsize', 2147483647);
    flowTraceNum = length(allFlowTrace);
    
    start_time = datetime('2009-12-18 00:26:04.398', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    end_time = datetime('2009-12-18 00:30:04.398', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    slot_num = seconds(end_time - start_time) / 3;
    
    flowSequence = [];
    initialClusterTable = table();
    
    for i = 1:flowTraceNum
        flowTrace = allFlowTrace{i};
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
            newFlowId = find(rows);
            for j = 1:length(newFlowId)
                e = newFlowId(j) - 1;
                loc = [loc, (loc(e):loc(e)+60/3)];
            end
        end
        flowSequence(i,:) = zeros(slot_num, 1);
        flowSequence(i, loc) = 1;
        
        initialClusterTable = [initialClusterTable; {srcIp, dstIp, vlan}];
    end

    initialClusterTable.Properties.VariableNames = {'SrcIp', 'DstIp', 'Vlan'};
    
    clearvars allFlowTrace
end
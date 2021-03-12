clearvars

global currentFlowTime

hostAvg = 50;
hostSd = 5;

flowNum = 5000;

linkBwdUnit = 10^3; %10Kbps

x_axis = 24; % prefix length
x_axis_tableThreshold = [50, 100];


% fat tree
%k = 4;
%[swNum, srcNode, dstNode, srcInf, dstInf, g, hostNum, IP] = ...
    %createFatTreeTopo(k, hostAvg, hostSd);

% AS topo
eachAsEdgeSwNum = 2;
[swNum, srcNode, dstNode, srcInf, dstInf, g, asNum, nodeTable, hostNum, IP] = ...
    createAsTopo_random(eachAsEdgeSwNum, hostAvg, hostSd);

swDistanceVector = distances(g, 'Method', 'unweighted');
swDistanceVector = swDistanceVector(1:swNum, 1:swNum);

% for as topo
rows = strcmp(nodeTable.Type, 'RT_NODE');
swDistanceVector(rows, rows) = 0;

[swInfTable, swFlowEntryStruct, hostIpTable, linkTable, linkThputStruct, initialClusterTable, flowSequence] = ...
    setVariables(swNum, srcNode, dstNode, srcInf, dstInf, g, hostNum, IP);

swFlowEntryStruct_empty = swFlowEntryStruct;
linkTable_empty = linkTable;
linkThputStruct_empty = linkThputStruct;

initialClusterTable.EdgeId = repmat(-1, size(initialClusterTable, 1), 1);
initialClusterTable.Group = repmat(-1, size(initialClusterTable, 1), 1);
initialClusterTable.Prefix = repmat(24, size(initialClusterTable, 1), 1);

initialClusterTable_original = initialClustering_static(initialClusterTable, flowSequence);

% flow info
allFlowTrace = textread('pktTrace_5min.txt', '%s', 'delimiter', '\n', 'bufsize', 2147483647);
flowTraceNum = length(allFlowTrace);
pickFlowTrace = randi(flowTraceNum, 1, flowNum);

flow_srcIp = {};
flow_dstIp = {};
for i = 1:flowNum
    % pick src & dst ip randomly
    node = randperm(length(IP), 2);
    srcIp = IP{node(1)};
    dstIp = IP{node(2)};
    
    flow_srcIp = [flow_srcIp, srcIp];
    flow_dstIp = [flow_dstIp, dstIp];
end

for timeout = [10, 60]

    flowTraceTable = setNewFlows_mod(flowNum, pickFlowTrace, flow_srcIp, flow_dstIp, timeout);

    % remove mice flow
    flowStartDatetime = datetime(flowTraceTable.StartDatetime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    flowEndDatetime = datetime(flowTraceTable.EndDatetime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');

    rows = (flowEndDatetime - flowStartDatetime < seconds(1));
    flowTraceTable(rows, :) = [];

    flowStartDatetime(rows) = [];
    flowEndDatetime(rows) = [];  

    result_prefix = cell(1, 1);

    count = 0;
    for pl = x_axis % static
        count = count + 1;

        swFlowEntryStruct = swFlowEntryStruct_empty;
        linkTable = linkTable_empty;
        linkThputStruct = linkThputStruct_empty;

        eachFlowFinalPath = {};
        linkPreLower = [];

        allSwTableSize_list = {};
        for i = 1:swNum
           allSwTableSize_list(i).flowNum = [];
        end

        initialClusterTable = initialClusterTable_original;
        initialClusterTable.NewGroup = initialClusterTable.Group;

        if pl < 24
            initialClusterTable = staticMerging(pl, initialClusterTable);
        end

        initialClusterTable = table(initialClusterTable.NewGroup, initialClusterTable.SrcIp, initialClusterTable.DstIp, initialClusterTable.SrcSubnet, initialClusterTable.DstSubnet, initialClusterTable.Vlan);
        initialClusterTable = unique(initialClusterTable);
        initialClusterTable.Properties.VariableNames = {'Group', 'SrcIp', 'DstIp', 'SrcSubnet', 'DstSubnet', 'Vlan'};

        initialClusterTable.MiddleSrcSw = repmat({{}}, size(initialClusterTable, 1), 1);
        initialClusterTable.MiddleDstSw = repmat({{}}, size(initialClusterTable, 1), 1);

        for i = 1:size(flowTraceTable, 1)
            i

            flowTraceTable = clusterNewFlow(i, flowTraceTable, initialClusterTable, pl);

            [srcNodeName, dstNodeName, flowRate, flowTraceTable, flowEntry] = ...
                setFlowInfo_mod(i, flowStartDatetime(i), flowEndDatetime(i), linkBwdUnit, hostIpTable, flowTraceTable, timeout);

            currentFlowTime = flowStartDatetime(i);

            rows = strcmp(swInfTable.SrcNode, srcNodeName);
            srcEdgeSw = swInfTable{rows, {'DstNode'}}{1};

            rows = strcmp(swInfTable.SrcNode, dstNodeName);
            dstEdgeSw = swInfTable{rows, {'DstNode'}}{1};

            finalPath = findnode(g, srcNodeName);

            if pl < 24 
                if isempty(flowTraceTable.MiddleSrcSw{i}) && isempty(flowTraceTable.MiddleDstSw{i})
                    rows = initialClusterTable.Group == flowTraceTable.Group(i);

                    srcip_filter = initialClusterTable{rows, {'SrcIp'}};
                    dstip_filter = initialClusterTable{rows, {'DstIp'}};

                    srcHost = cellfun(@(x) hostIpTable{strcmp(hostIpTable.IP, x), {'Host'}}, srcip_filter);
                    srcEdgeSw_filter = cellfun(@(x) swInfTable{strcmp(swInfTable.SrcNode, x), {'DstNode'}}, srcHost);
                    uniqueSrcEdgeSw = unique(srcEdgeSw_filter);

                    dstHost = cellfun(@(x) hostIpTable{strcmp(hostIpTable.IP, x), {'Host'}}, dstip_filter);
                    dstEdgeSw_filter = cellfun(@(x) swInfTable{strcmp(swInfTable.SrcNode, x), {'DstNode'}}, dstHost);
                    uniqueDstEdgeSw = unique(dstEdgeSw_filter);

                    if length(uniqueSrcEdgeSw) == 1 && length(uniqueDstEdgeSw) == 1
                        middleSrcSw = uniqueSrcEdgeSw;
                        middleDstSw = uniqueDstEdgeSw;
                    else
                        if length(uniqueSrcEdgeSw) == 1
                            middleSrcSw = uniqueSrcEdgeSw;
                        else
                            middleSrcSw = findRendezvousSw(uniqueSrcEdgeSw, g, swDistanceVector, linkBwdUnit, linkTable, linkPreLower, linkThputStruct, flowStartDatetime(i));
                            middleSrcSw = {middleSrcSw};
                        end

                        if length(uniqueDstEdgeSw) == 1
                            middleDstSw = uniqueDstEdgeSw;
                        else
                            middleDstSw = findRendezvousSw(uniqueDstEdgeSw, g, swDistanceVector, linkBwdUnit, linkTable, linkPreLower, linkThputStruct, flowStartDatetime(i));
                            middleDstSw = {middleDstSw};
                        end
                    end

                    initialClusterTable.MiddleSrcSw(rows) = middleSrcSw;
                    initialClusterTable.MiddleDstSw(rows) = middleDstSw;

                    flowTraceTable.MiddleSrcSw(i) = middleSrcSw;
                    flowTraceTable.MiddleDstSw(i) = middleDstSw;
                end

                middleSrcSw = flowTraceTable.MiddleSrcSw{i};
                middleDstSw = flowTraceTable.MiddleDstSw{i};

                swList = {srcEdgeSw, middleSrcSw, middleDstSw, dstEdgeSw};
                prefixList = [24, pl, 24];

                for j = 1:length(swList) - 1
                    firstSw = swList{j};
                    secondSw = swList{j+1};

                    [flowEntry_temp, flowSrcIp, flowDstIp] = setFlowEntry(prefixList(j), flowEntry, flowTraceTable, i);

                    if strcmp(firstSw, srcEdgeSw)
                        rows = strcmp(swInfTable.SrcNode, srcNodeName);
                        flowEntry_temp.input = swInfTable{rows, {'DstInf'}};
                    else
                        rows = strcmp(swInfTable.SrcNode, g.Nodes.Name{finalPath(end-1)}) & strcmp(swInfTable.DstNode, g.Nodes.Name{finalPath(end)});
                        flowEntry_temp.input = swInfTable{rows, {'DstInf'}};
                    end

                    round = j;
                    finalPath_temp = [];

                    [finalPath_temp, swFlowEntryStruct, linkTable, finish] = ...
                        processPkt_mod(g, linkTable, linkBwdUnit, swInfTable, hostIpTable, ...
                        swFlowEntryStruct, linkPreLower, linkThputStruct, flowEntry_temp, finalPath_temp, ...
                        flowStartDatetime(i), firstSw, secondSw, round, dstNodeName, flowSrcIp, flowDstIp, i);

                    finalPath = [finalPath, finalPath_temp];

                    if finish
                        break;
                    end
                end
            else
                [flowEntry, flowSrcIp, flowDstIp]  = setFlowEntry(pl, flowEntry, flowTraceTable, i);

                rows = strcmp(swInfTable.SrcNode, srcNodeName);
                flowEntry.input = swInfTable{rows, {'DstInf'}};

                round = 3;

                [finalPath, swFlowEntryStruct, linkTable, ~] = ...
                    processPkt_mod(g, linkTable, linkBwdUnit, swInfTable, hostIpTable, ...
                    swFlowEntryStruct, linkPreLower, linkThputStruct, flowEntry, finalPath, ...
                    flowStartDatetime(i), srcEdgeSw, dstEdgeSw, round, dstNodeName, flowSrcIp, flowDstIp, i);
            end

            finalPath = [finalPath, findnode(g, dstNodeName)];
            finalPath(diff(finalPath)==0) = [];
            eachFlowFinalPath = [eachFlowFinalPath; finalPath];

            allSwTableSize_list = recordSwTableSize(swFlowEntryStruct, finalPath, allSwTableSize_list);

            [linkThputStruct, linkPreLower] = ...
                updateLinkStruct(finalPath, g, linkThputStruct, ...
                flowStartDatetime(i), flowEndDatetime(i), linkPreLower, flowEntry, flowRate);
        end

        result_prefix{count} = calculate_max_tableSize(swFlowEntryStruct);
    end


    flowTraceTable = setNewFlows_mod(flowNum, pickFlowTrace, flow_srcIp, flow_dstIp, timeout);

    % remove mice flow
    flowStartDatetime = datetime(flowTraceTable.StartDatetime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    flowEndDatetime = datetime(flowTraceTable.EndDatetime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');

    rows = (flowEndDatetime - flowStartDatetime < seconds(1));
    flowTraceTable(rows, :) = [];

    flowStartDatetime(rows) = [];
    flowEndDatetime(rows) = [];

    result_threshold = cell(2, 1);

    count = 0;
    for tableThreshold = x_axis_tableThreshold % dynamic
        count = count + 1;

        swFlowEntryStruct = swFlowEntryStruct_empty;
        linkTable = linkTable_empty;
        linkThputStruct = linkThputStruct_empty;

        eachFlowFinalPath = {};
        linkPreLower = [];
        needDohierarchy = false;
        doHierarchyCount = 0;

        allSwTableSize_list = {};
        for i = 1:swNum
           allSwTableSize_list(i).flowNum = [];
        end

        clusterSize_list = [];
        clusterNumber_list = [];

        initialClusterTable = initialClusterTable_original;
        initialClusterTable = table(initialClusterTable.Group, initialClusterTable.SrcIp, initialClusterTable.DstIp, initialClusterTable.SrcSubnet, initialClusterTable.DstSubnet, initialClusterTable.Prefix, initialClusterTable.Vlan);
        initialClusterTable = unique(initialClusterTable);
        initialClusterTable.Properties.VariableNames = {'Group', 'SrcIp', 'DstIp', 'SrcSubnet', 'DstSubnet', 'Prefix', 'Vlan'};

        initialClusterTable.HierarchicalGroup = zeros(size(initialClusterTable, 1), 1);
        initialClusterTable.HierarchicalPrefix = zeros(size(initialClusterTable, 1), 1);
        initialClusterTable.MiddleSrcSw = repmat({{}}, size(initialClusterTable, 1), 1);
        initialClusterTable.MiddleDstSw = repmat({{}}, size(initialClusterTable, 1), 1);

        flowTraceTable.Group = zeros(size(flowTraceTable, 1), 1);

        for i = 1:size(flowTraceTable, 1)
            i

            flowTraceTable = clusterNewFlow_dynamic(i, flowTraceTable, initialClusterTable);

            [srcNodeName, dstNodeName, flowRate, flowTraceTable, flowEntry] = ...
                setFlowInfo_mod(i, flowStartDatetime(i), flowEndDatetime(i), linkBwdUnit, hostIpTable, flowTraceTable, timeout);

            currentFlowTime = flowStartDatetime(i);

            rows = strcmp(swInfTable.SrcNode, srcNodeName);
            srcEdgeSw = swInfTable{rows, {'DstNode'}}{1};

            rows = strcmp(swInfTable.SrcNode, dstNodeName);
            dstEdgeSw = swInfTable{rows, {'DstNode'}}{1};

            finalPath = findnode(g, srcNodeName);

            if flowTraceTable.HierarchicalGroup(i) > 0
                middleSrcSw = flowTraceTable.MiddleSrcSw{i};
                middleDstSw = flowTraceTable.MiddleDstSw{i};

                swList = {srcEdgeSw, middleSrcSw, middleDstSw, dstEdgeSw};

                prefixLength = flowTraceTable.Prefix(i);
                hie_prefixLength = flowTraceTable.HierarchicalPrefix(i);

                prefixList = [prefixLength, hie_prefixLength, prefixLength];

                for j = 1:length(swList) - 1
                    firstSw = swList{j};
                    secondSw = swList{j+1};

                    [flowEntry_temp, flowSrcIp, flowDstIp] = setFlowEntry(prefixList(j), flowEntry, flowTraceTable, i);

                    if strcmp(firstSw, srcEdgeSw)
                        rows = strcmp(swInfTable.SrcNode, srcNodeName);
                        flowEntry_temp.input = swInfTable{rows, {'DstInf'}};
                    else
                        rows = strcmp(swInfTable.SrcNode, g.Nodes.Name{finalPath(end-1)}) & strcmp(swInfTable.DstNode, g.Nodes.Name{finalPath(end)});
                        flowEntry_temp.input = swInfTable{rows, {'DstInf'}};
                    end

                    round = j;
                    finalPath_temp = [];

                    [finalPath_temp, swFlowEntryStruct, linkTable, finish] = ...
                        processPkt_mod(g, linkTable, linkBwdUnit, swInfTable, hostIpTable, ...
                        swFlowEntryStruct, linkPreLower, linkThputStruct, flowEntry_temp, finalPath_temp, ...
                        flowStartDatetime(i), firstSw, secondSw, round, dstNodeName, flowSrcIp, flowDstIp, i);

                    finalPath = [finalPath, finalPath_temp];

                    if finish
                        break;
                    end
                end
            else
                prefixLength = flowTraceTable.Prefix(i);

                [flowEntry, flowSrcIp, flowDstIp]  = setFlowEntry(prefixLength, flowEntry, flowTraceTable, i);

                rows = strcmp(swInfTable.SrcNode, srcNodeName);
                flowEntry.input = swInfTable{rows, {'DstInf'}};

                round = 3;

                [finalPath, swFlowEntryStruct, linkTable, ~] = ...
                    processPkt_mod(g, linkTable, linkBwdUnit, swInfTable, hostIpTable, ...
                    swFlowEntryStruct, linkPreLower, linkThputStruct, flowEntry, finalPath, ...
                    flowStartDatetime(i), srcEdgeSw, dstEdgeSw, round, dstNodeName, flowSrcIp, flowDstIp, i);
            end

            finalPath = [finalPath, findnode(g, dstNodeName)];
            finalPath(diff(finalPath)==0) = [];
            eachFlowFinalPath = [eachFlowFinalPath; finalPath];

            [needDohierarchy, swWithTooManyFlowEntry, allSwTableSize_list] = ...
                    checkFlowTable(tableThreshold, swFlowEntryStruct, needDohierarchy, finalPath, allSwTableSize_list);

            if needDohierarchy
                [flowTraceTable, doHierarchyCount, initialClusterTable, mergedFlow] = dynamicMerging_mod(tableThreshold, swWithTooManyFlowEntry, ...
                    g, swDistanceVector, hostIpTable, swInfTable, eachFlowFinalPath, flowTraceTable, doHierarchyCount, ...
                    linkBwdUnit, linkTable, linkPreLower, linkThputStruct, flowStartDatetime(i), initialClusterTable);

                needDohierarchy = false;
                swFlowEntryStruct = removeAllFlowEntry_mod(swFlowEntryStruct, flowStartDatetime(i), mergedFlow);

                [meanClusterSize, clusterNumber] = calculateClusterSizeAndNumber(flowTraceTable);

                clusterSize_list = [clusterSize_list, meanClusterSize];
                clusterNumber_list = [clusterNumber_list, clusterNumber];
            end

            [linkThputStruct, linkPreLower] = ...
                updateLinkStruct(finalPath, g, linkThputStruct, ...
                flowStartDatetime(i), flowEndDatetime(i), linkPreLower, flowEntry, flowRate);
        end

        result_threshold{count} = calculate_max_tableSize(swFlowEntryStruct);
    end

    fileName = ['timeout_', num2str(timeout)];
    save(fileName)
end


function [needDohierarchy, swWithTooManyFlowEntry, allSwTableSize_list] = ...
    checkFlowTable(tableThreshold, swFlowEntryStruct, needDohierarchy, finalPath, allSwTableSize_list)

    checkedSwitch = finalPath(2:end-1);
    
    flowEntryNum = arrayfun(@swFlowEntryNumber, swFlowEntryStruct(checkedSwitch));
    
    for i = 1:length(checkedSwitch)
        allSwTableSize_list(checkedSwitch(i)).flowNum = [allSwTableSize_list(checkedSwitch(i)).flowNum, flowEntryNum(i)];
    end
    
    rows = (flowEntryNum > tableThreshold);

    if any(rows)
        swWithTooManyFlowEntry = checkedSwitch(rows);
        needDohierarchy = true;
    else
        swWithTooManyFlowEntry = [];
    end
end

function allSwTableSize_list = recordSwTableSize(swFlowEntryStruct, finalPath, allSwTableSize_list)
    checkedSwitch = finalPath(2:end-1);
    
    flowEntryNum = arrayfun(@swFlowEntryNumber, swFlowEntryStruct(checkedSwitch));
    
    for i = 1:length(checkedSwitch)
        allSwTableSize_list(checkedSwitch(i)).flowNum = [allSwTableSize_list(checkedSwitch(i)).flowNum, flowEntryNum(i)];
    end
end

function flowEntryNum = swFlowEntryNumber(x)
    global currentFlowTime
    
    if isempty(x.entry)
        flowEntryNum = 0;
    else
        flowEntryNum = length(find(datetime({x.entry.endTime}, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS') >= currentFlowTime));
    end
end
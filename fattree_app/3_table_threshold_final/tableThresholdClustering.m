function tableThresholdClustering(roundNumber)
    t1 = datetime('now');

    global currentFlowTime

    hostAvg = 50;
    hostSd = 5;

    flowNum = 5000;

    linkBwdUnit = 10^3;
    
    % different table size threshold
    startTableThreshold = 50;
    endTableThreshold = 200;

    x_axis = startTableThreshold:50:endTableThreshold;
    x_label = 'Flow Table Size Threshold';

    allRound_y_axis_flowTableSize = [];
    allRound_y_axis_flowTableSize_90 = []; % for errorbar
    allRound_y_axis_flowTableSize_10 = [];
    allRound_y_axis_flowTableSize_perFlow = [];
    allRound_y_axis_flowTableSize_perFlow_90 = [];
    allRound_y_axis_flowTableSize_perFlow_10 = [];

    % record network throughput result
    allRound_y_axis_networkThroughput = [];
    allRound_y_axis_networkThroughput_perFlow = [];
    
    % record flow path length result
    allRound_y_axis_pathLength = [];
    allRound_y_axis_pathLength_perFlow = [];
    
    % record number of merging
    allRound_y_axis_doHierarchyCount = [];
    
    allRound_y_axis_clusterSize = [];
    allRound_y_axis_clusterNumber = [];

    for frequency = 1:roundNumber
        % fat tree
        k = 4;
        [swNum, srcNode, dstNode, srcInf, dstInf, g, hostNum, IP] = ...
            createFatTreeTopo(k, hostAvg, hostSd);

        % AS topo
        %eachAsEdgeSwNum = 2;
        %[swNum, srcNode, dstNode, srcInf, dstInf, g, asNum, nodeTable, hostNum, IP] = ...
            %createAsTopo_random(eachAsEdgeSwNum, hostAvg, hostSd);
            
        swDistanceVector = distances(g, 'Method', 'unweighted');
        swDistanceVector = swDistanceVector(1:swNum, 1:swNum);

        % for as topo
        %rows = strcmp(nodeTable.Type, 'RT_NODE');
        %swDistanceVector(rows, rows) = 0;
            
        [swInfTable, swFlowEntryStruct, hostIpTable, linkTable, linkThputStruct, initialClusterTable, flowSequence] = ...
            setVariables(swNum, srcNode, dstNode, srcInf, dstInf, g, hostNum, IP);

        initialClusterTable.EdgeId = repmat(-1, size(initialClusterTable, 1), 1);
        initialClusterTable.Group = repmat(-1, size(initialClusterTable, 1), 1);
        initialClusterTable.Prefix = repmat(24, size(initialClusterTable, 1), 1);
        
        initialClusterTable_original = initialClustering_dynamic(initialClusterTable, flowSequence);
        
        flowTraceTable = setNewFlows(flowNum, IP);

        % remove mice flow
        flowStartDatetime = datetime(flowTraceTable.StartDatetime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
        flowEndDatetime = datetime(flowTraceTable.EndDatetime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');

        rows = (flowEndDatetime - flowStartDatetime < seconds(1));
        flowTraceTable(rows, :) = [];
        
        flowTraceTable_original = flowTraceTable;

        flowStartDatetime(rows) = [];
        flowEndDatetime(rows) = [];

        swFlowEntryStruct_empty = swFlowEntryStruct;
        linkTable_empty = linkTable;
        linkThputStruct_empty = linkThputStruct;
        
        y_axis_flowTableSize = [];
        y_axis_flowTableSize_90 = [];
        y_axis_flowTableSize_10 = [];
        y_axis_flowTableSize_perFlow = [];
        y_axis_flowTableSize_perFlow_90 = [];
        y_axis_flowTableSize_perFlow_10 = [];

        y_axis_networkThroughput = [];
        y_axis_networkThroughput_perFlow = [];
        
        y_axis_pathLength = [];
        y_axis_pathLength_perFlow = [];

        doHierarchyCount_list = [];
        
        y_axis_clusterSize = [];
        y_axis_clusterNumber = [];

        [meanFlowTableSize_perFlow, meanFlowTableSize_perFlow_90, meanFlowTableSize_perFlow_10, meanNetworkThrouput_perFlow, meanPathLength_perFlow] = ...
            perFlowClustering(swNum, flowStartDatetime, flowEndDatetime, linkBwdUnit, ...
            hostIpTable, flowTraceTable, swFlowEntryStruct, g, swInfTable, linkTable, linkThputStruct);

        cdfFigureCount = 0;

        for tableThreshold = startTableThreshold:50:endTableThreshold
            cdfFigureCount = cdfFigureCount + 1;

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
            
            flowTraceTable = flowTraceTable_original;
            flowTraceTable.Group = zeros(size(flowTraceTable, 1), 1);
            
            for i = 1:size(flowTraceTable, 1)
                i

                flowTraceTable = clusterNewFlow_dynamic(i, flowTraceTable, initialClusterTable);

                [srcNodeName, dstNodeName, flowRate, flowTraceTable, flowEntry] = ...
                    setFlowInfo(i, flowStartDatetime(i), flowEndDatetime(i), linkBwdUnit, hostIpTable, flowTraceTable);
                
                currentFlowTime = flowStartDatetime(i);

                rows = strcmp(swInfTable.SrcNode, srcNodeName);
                srcEdgeSw = swInfTable{rows, {'DstNode'}}{1};

                rows = strcmp(swInfTable.SrcNode, dstNodeName);
                dstEdgeSw = swInfTable{rows, {'DstNode'}}{1};

                finalPath = findnode(g, srcNodeName);

                % cluster has been merged -> three-segment routing
                if flowTraceTable.HierarchicalGroup(i) > 0
                    % get rendezvous switch of merged clusters
                    middleSrcSw = flowTraceTable.MiddleSrcSw{i};
                    middleDstSw = flowTraceTable.MiddleDstSw{i};

                    swList = {srcEdgeSw, middleSrcSw, middleDstSw, dstEdgeSw};

                    % the prefix length of ingress sub-path and egress sub-path
                    prefixLength = flowTraceTable.Prefix(i);
                    
                    % the prefix length of shared sub-path
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
                            processPkt(g, linkTable, linkBwdUnit, swInfTable, hostIpTable, ...
                            swFlowEntryStruct, linkPreLower, linkThputStruct, flowEntry_temp, finalPath_temp, ...
                            flowStartDatetime(i), firstSw, secondSw, round, dstNodeName, flowSrcIp, flowDstIp);

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
                        processPkt(g, linkTable, linkBwdUnit, swInfTable, hostIpTable, ...
                        swFlowEntryStruct, linkPreLower, linkThputStruct, flowEntry, finalPath, ...
                        flowStartDatetime(i), srcEdgeSw, dstEdgeSw, round, dstNodeName, flowSrcIp, flowDstIp);
                end

                finalPath = [finalPath, findnode(g, dstNodeName)];
                finalPath(diff(finalPath)==0) = [];
                eachFlowFinalPath = [eachFlowFinalPath; finalPath];

                % switch exceeds threshold?
                [needDohierarchy, swWithTooManyFlowEntry, allSwTableSize_list] = ...
                        checkFlowTable(tableThreshold, swFlowEntryStruct, needDohierarchy, finalPath, allSwTableSize_list);

                if needDohierarchy % exceed threshold
                    [flowTraceTable, doHierarchyCount, initialClusterTable] = dynamicMerging(tableThreshold, swWithTooManyFlowEntry, ...
                        g, swDistanceVector, hostIpTable, swInfTable, eachFlowFinalPath, flowTraceTable, doHierarchyCount, ...
                        linkBwdUnit, linkTable, linkPreLower, linkThputStruct, flowStartDatetime(i), initialClusterTable);

                    needDohierarchy = false;
                    swFlowEntryStruct = removeAllFlowEntry(swFlowEntryStruct, flowStartDatetime(i));

                    [meanClusterSize, clusterNumber] = calculateClusterSizeAndNumber(flowTraceTable);

                    clusterSize_list = [clusterSize_list, meanClusterSize];
                    clusterNumber_list = [clusterNumber_list, clusterNumber];
                end

                [linkThputStruct, linkPreLower] = ...
                    updateLinkStruct(finalPath, g, linkThputStruct, ...
                    flowStartDatetime(i), flowEndDatetime(i), linkPreLower, flowEntry, flowRate);
            end

            [meanFlowTableSize, meanFlowTableSize_90, meanFlowTableSize_10, ~] = calculateFlowTableSize_errorbar(allSwTableSize_list);

            y_axis_flowTableSize = [y_axis_flowTableSize, meanFlowTableSize];
            y_axis_flowTableSize_90 = [y_axis_flowTableSize_90, meanFlowTableSize_90];
            y_axis_flowTableSize_10 = [y_axis_flowTableSize_10, meanFlowTableSize_10];

            meanNetworkThrouput = calculateNetworkThrouput(g, linkBwdUnit, ...
                linkThputStruct, eachFlowFinalPath, flowTraceTable, flowStartDatetime, flowEndDatetime);

            y_axis_networkThroughput = [y_axis_networkThroughput, meanNetworkThrouput];
            
            y_axis_pathLength = [y_axis_pathLength, mean(cellfun(@(x) length(x), eachFlowFinalPath))];

            y_axis_flowTableSize_perFlow = [y_axis_flowTableSize_perFlow, meanFlowTableSize_perFlow];
            y_axis_flowTableSize_perFlow_90 = [y_axis_flowTableSize_perFlow_90, meanFlowTableSize_perFlow_90];
            y_axis_flowTableSize_perFlow_10 = [y_axis_flowTableSize_perFlow_10, meanFlowTableSize_perFlow_10];
            
            y_axis_networkThroughput_perFlow = [y_axis_networkThroughput_perFlow, meanNetworkThrouput_perFlow];
            y_axis_pathLength_perFlow = [y_axis_pathLength_perFlow, meanPathLength_perFlow];

            doHierarchyCount_list = [doHierarchyCount_list, doHierarchyCount];

            y_axis_clusterSize = [y_axis_clusterSize, mean(clusterSize_list)];
            y_axis_clusterNumber = [y_axis_clusterNumber, mean(clusterNumber_list)];

            filename = ['memory/memory_', int2str(frequency), '_', int2str(tableThreshold)];
            save(filename)
        end

        allRound_y_axis_flowTableSize = [allRound_y_axis_flowTableSize; y_axis_flowTableSize];
        allRound_y_axis_flowTableSize_90 = [allRound_y_axis_flowTableSize_90; y_axis_flowTableSize_90];
        allRound_y_axis_flowTableSize_10 = [allRound_y_axis_flowTableSize_10; y_axis_flowTableSize_10];
        
        allRound_y_axis_networkThroughput = [allRound_y_axis_networkThroughput; y_axis_networkThroughput];
        allRound_y_axis_pathLength = [allRound_y_axis_pathLength; y_axis_pathLength];

        allRound_y_axis_flowTableSize_perFlow = [allRound_y_axis_flowTableSize_perFlow; y_axis_flowTableSize_perFlow];
        allRound_y_axis_flowTableSize_perFlow_90 = [allRound_y_axis_flowTableSize_perFlow_90; y_axis_flowTableSize_perFlow_90];
        allRound_y_axis_flowTableSize_perFlow_10 = [allRound_y_axis_flowTableSize_perFlow_10; y_axis_flowTableSize_perFlow_10];
        
        allRound_y_axis_networkThroughput_perFlow = [allRound_y_axis_networkThroughput_perFlow; y_axis_networkThroughput_perFlow];
        allRound_y_axis_pathLength_perFlow = [allRound_y_axis_pathLength_perFlow; y_axis_pathLength_perFlow];
        
        allRound_y_axis_doHierarchyCount = [allRound_y_axis_doHierarchyCount; doHierarchyCount_list];

        allRound_y_axis_clusterSize = [allRound_y_axis_clusterSize; y_axis_clusterSize];
        allRound_y_axis_clusterNumber = [allRound_y_axis_clusterNumber; y_axis_clusterNumber];
        
        %{
        if frequency == 1
            drawFlowTableSizeFigure(x_axis, allRound_y_axis_flowTableSize, allRound_y_axis_flowTableSize_perFlow, 1, frequency, x_label)
            drawFlowTableSizeFigure(x_axis, allRound_y_axis_flowTableSize_90, allRound_y_axis_flowTableSize_perFlow, 2, frequency, x_label)
            drawFlowTableSizeFigure(x_axis, allRound_y_axis_flowTableSize_10, allRound_y_axis_flowTableSize_perFlow, 3, frequency, x_label)
            
            drawNetworkThroughputFigure(x_axis, allRound_y_axis_networkThroughput, allRound_y_axis_networkThroughput_perFlow, frequency, x_label)
            drawPathLengthFigure(x_axis, allRound_y_axis_pathLength, allRound_y_axis_pathLength_perFlow, frequency, x_label)
            drawFlowMergingFigure(x_axis, allRound_y_axis_doHierarchyCount, frequency, x_label)

            drawClusterSize(x_axis, allRound_y_axis_clusterSize, frequency, x_label)
            drawClusterNumber(x_axis, allRound_y_axis_clusterNumber, frequency, x_label)
        else
            drawFlowTableSizeFigure(x_axis, mean(allRound_y_axis_flowTableSize), mean(allRound_y_axis_flowTableSize_perFlow), 1, frequency, x_label)
            drawFlowTableSizeFigure(x_axis, mean(allRound_y_axis_flowTableSize_90), mean(allRound_y_axis_flowTableSize_perFlow), 2, frequency, x_label)
            drawFlowTableSizeFigure(x_axis, mean(allRound_y_axis_flowTableSize_10), mean(allRound_y_axis_flowTableSize_perFlow), 3, frequency, x_label)
            
            drawNetworkThroughputFigure(x_axis, mean(allRound_y_axis_networkThroughput), mean(allRound_y_axis_networkThroughput_perFlow), frequency, x_label)
            drawPathLengthFigure(x_axis, mean(allRound_y_axis_pathLength), mean(allRound_y_axis_pathLength_perFlow), frequency, x_label)
            drawFlowMergingFigure(x_axis, mean(allRound_y_axis_doHierarchyCount), frequency, x_label)

            drawClusterSize(x_axis, mean(allRound_y_axis_clusterSize), frequency, x_label)
            drawClusterNumber(x_axis, mean(allRound_y_axis_clusterNumber), frequency, x_label)
        end
        %}
        
        filename = ['memory/memory_', int2str(frequency)];
        save(filename)
    end

    t2 = datetime('now');
    disp(t2 - t1)

    save('memory/final')
end

function [needDohierarchy, swWithTooManyFlowEntry, allSwTableSize_list] = ...
    checkFlowTable(tableThreshold, swFlowEntryStruct, needDohierarchy, finalPath, allSwTableSize_list)

    checkedSwitch = finalPath(2:end-1);
    
    flowEntryNum = arrayfun(@swFlowEntryNumber, swFlowEntryStruct(checkedSwitch));
    
    for i = 1:length(checkedSwitch)
        allSwTableSize_list(checkedSwitch(i)).flowNum = [allSwTableSize_list(checkedSwitch(i)).flowNum, flowEntryNum(i)];
    end
    
    rows = (flowEntryNum > tableThreshold);

    if any(rows) % exceed threshold
        swWithTooManyFlowEntry = checkedSwitch(rows);
        needDohierarchy = true;
    else
        swWithTooManyFlowEntry = [];
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
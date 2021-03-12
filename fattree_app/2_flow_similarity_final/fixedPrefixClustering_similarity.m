function fixedPrefixClustering_similarity(roundNumber)
    t1 = datetime('now');
    
    global currentFlowTime

    hostAvg = 50;
    hostSd = 5;

    flowNum = 5000;

    linkBwdUnit = 10^3; %10Kbps
    
    startPrefixLength = 18;
    endPrefixLength = 24;

    x_axis = startPrefixLength:2:endPrefixLength;
    x_label = 'Prefix Length (bits)';
    
    % different flow similarity
    startFlowSimilarity = 1000;
    endFlowSimilarity = 5000;
    
    x_axis_similarity = startFlowSimilarity:1000:endFlowSimilarity;

    allRound_y_axis_flowTableSize_1 = cell(length(x_axis_similarity), 1);
    allRound_y_axis_flowTableSize_2 = cell(length(x_axis_similarity), 1);
    allRound_y_axis_flowTableSize_3 = cell(length(x_axis_similarity), 1);
    allRound_y_axis_flowTableSize_4 = cell(length(x_axis_similarity), 1);
    
    % record number of clusters
    allRound_y_axis_clusterNum = cell(length(x_axis_similarity), 1);

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
            
        [swInfTable, swFlowEntryStruct, hostIpTable, linkTable, linkThputStruct, flowTraceTable, flowSequence] = ...
            setVariables_similarity(swNum, srcNode, dstNode, srcInf, dstInf, g, hostNum, IP, flowNum);
        
        % remove mice flow
        flowStartDatetime = datetime(flowTraceTable.StartDatetime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
        flowEndDatetime = datetime(flowTraceTable.EndDatetime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');

        rows = (flowEndDatetime - flowStartDatetime < seconds(1));
        flowTraceTable(rows, :) = [];

        %flowStartDatetime(rows) = [];
        %flowEndDatetime(rows) = [];
        
        swFlowEntryStruct_empty = swFlowEntryStruct;
        linkTable_empty = linkTable;
        linkThputStruct_empty = linkThputStruct;
        
        % edge cluster
        flowTraceTable.EdgeId = repmat(-1, size(flowTraceTable, 1), 1);
        flowTraceTable.Group = repmat(-1, size(flowTraceTable, 1), 1);
        flowTraceTable.Prefix = repmat(24, size(flowTraceTable, 1), 1);

        [flowTraceTable, sequenceToCentroid_distance] = initialClustering_similarity(flowTraceTable, flowSequence);

        similarity_y_axis_flowTableSize_1 = cell(length(x_axis_similarity), 1);
        similarity_y_axis_flowTableSize_2 = cell(length(x_axis_similarity), 1);
        similarity_y_axis_flowTableSize_3 = cell(length(x_axis_similarity), 1);
        similarity_y_axis_flowTableSize_4 = cell(length(x_axis_similarity), 1);

        similarity_y_axis_clusterNum = cell(length(x_axis_similarity), 1);
        
        figureCount_similarity = 0;
        flowTraceTable_original = flowTraceTable;
        
        for flowSimilarity = startFlowSimilarity:1000:endFlowSimilarity
            figureCount_similarity = figureCount_similarity + 1;
            
            flowTraceTable = computeSimilarity(flowTraceTable_original, sequenceToCentroid_distance, flowSimilarity, flowNum);
            flowStartDatetime = datetime(flowTraceTable.StartDatetime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
            flowEndDatetime = datetime(flowTraceTable.EndDatetime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
            
            unique_idx = unique(flowTraceTable.Group);
            y_kmeans = cell(length(unique_idx), 1);

            % record cluster number over time
            for i = 1:length(unique_idx)
                rows = (flowTraceTable.Group == unique_idx(i));
                flowSequenceId = flowTraceTable.Index(rows);

                y_kmeans{i} = sum(flowSequence(flowSequenceId, :), 1);
            end
            
            y_kmeans_clusterNum = [];
            for i = 1:length(unique_idx)
                y_kmeans_clusterNum = [y_kmeans_clusterNum; (y_kmeans{i} > 0)];
            end
            
            similarity_y_axis_clusterNum{figureCount_similarity} = sum(y_kmeans_clusterNum, 1);
            allRound_y_axis_clusterNum{figureCount_similarity} = [allRound_y_axis_clusterNum{figureCount_similarity}; similarity_y_axis_clusterNum{figureCount_similarity}];
            %
            
            y_axis_flowTableSize_1 = [];
            y_axis_flowTableSize_2 = [];
            y_axis_flowTableSize_3 = [];
            y_axis_flowTableSize_4 = [];

            flowTraceTable_temp = flowTraceTable;
            
            for pl = startPrefixLength:2:endPrefixLength
                swFlowEntryStruct = swFlowEntryStruct_empty;
                linkTable = linkTable_empty;
                linkThputStruct = linkThputStruct_empty;

                eachFlowFinalPath = {};
                linkPreLower = [];

                allSwTableSize_list = {};
                for i = 1:swNum
                   allSwTableSize_list(i).flowNum = [];
                end
                
                flowTraceTable = flowTraceTable_temp;
                flowTraceTable.NewGroup = flowTraceTable.Group;

                if pl < 24
                    flowTraceTable = staticMerging(pl, flowTraceTable);
                end

                initialClusterTable = table(flowTraceTable.NewGroup, flowTraceTable.SrcIp, flowTraceTable.DstIp, flowTraceTable.SrcSubnet, flowTraceTable.DstSubnet, flowTraceTable.Vlan);
                initialClusterTable = unique(initialClusterTable);
                initialClusterTable.Properties.VariableNames = {'Group', 'SrcIp', 'DstIp', 'SrcSubnet', 'DstSubnet', 'Vlan'};

                initialClusterTable.MiddleSrcSw = repmat({{}}, size(initialClusterTable, 1), 1);
                initialClusterTable.MiddleDstSw = repmat({{}}, size(initialClusterTable, 1), 1);

                for i = 1:size(flowTraceTable, 1)
                    i
                    
                    flowTraceTable = clusterNewFlow_similarity(i, flowTraceTable, initialClusterTable, pl);

                    [srcNodeName, dstNodeName, flowRate, flowTraceTable, flowEntry] = ...
                        setFlowInfo(i, flowStartDatetime(i), flowEndDatetime(i), linkBwdUnit, hostIpTable, flowTraceTable);

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
                                processPkt(g, linkTable, linkBwdUnit, swInfTable, hostIpTable, ...
                                swFlowEntryStruct, linkPreLower, linkThputStruct, flowEntry_temp, finalPath_temp, ...
                                flowStartDatetime(i), firstSw, secondSw, round, dstNodeName, flowSrcIp, flowDstIp);

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
                            processPkt(g, linkTable, linkBwdUnit, swInfTable, hostIpTable, ...
                            swFlowEntryStruct, linkPreLower, linkThputStruct, flowEntry, finalPath, ...
                            flowStartDatetime(i), srcEdgeSw, dstEdgeSw, round, dstNodeName, flowSrcIp, flowDstIp);
                    end

                    finalPath = [finalPath, findnode(g, dstNodeName)];
                    finalPath(diff(finalPath)==0) = [];
                    eachFlowFinalPath = [eachFlowFinalPath; finalPath];

                    allSwTableSize_list = recordSwTableSize(swFlowEntryStruct, finalPath, allSwTableSize_list);

                    [linkThputStruct, linkPreLower] = ...
                        updateLinkStruct(finalPath, g, linkThputStruct, ...
                        flowStartDatetime(i), flowEndDatetime(i), linkPreLower, flowEntry, flowRate);
                end

                [meanFlowTableSize_1, meanFlowTableSize_2, meanFlowTableSize_3, meanFlowTableSize_4, allSwMeanFlowTableSize] = calculateFlowTableSize(allSwTableSize_list);

                y_axis_flowTableSize_1 = [y_axis_flowTableSize_1, meanFlowTableSize_1];
                y_axis_flowTableSize_2 = [y_axis_flowTableSize_2, meanFlowTableSize_2];
                y_axis_flowTableSize_3 = [y_axis_flowTableSize_3, meanFlowTableSize_3];
                y_axis_flowTableSize_4 = [y_axis_flowTableSize_4, meanFlowTableSize_4];

                filename = ['memory/memory_', int2str(frequency), '_', int2str(flowSimilarity), '_', int2str(pl)];

                save(filename)
            end
            
            similarity_y_axis_flowTableSize_1{figureCount_similarity} = y_axis_flowTableSize_1;
            similarity_y_axis_flowTableSize_2{figureCount_similarity} = y_axis_flowTableSize_2;
            similarity_y_axis_flowTableSize_3{figureCount_similarity} = y_axis_flowTableSize_3;
            similarity_y_axis_flowTableSize_4{figureCount_similarity} = y_axis_flowTableSize_4;

            allRound_y_axis_flowTableSize_1{figureCount_similarity} = [allRound_y_axis_flowTableSize_1{figureCount_similarity}; similarity_y_axis_flowTableSize_1{figureCount_similarity}];
            allRound_y_axis_flowTableSize_2{figureCount_similarity} = [allRound_y_axis_flowTableSize_2{figureCount_similarity}; similarity_y_axis_flowTableSize_2{figureCount_similarity}];
            allRound_y_axis_flowTableSize_3{figureCount_similarity} = [allRound_y_axis_flowTableSize_3{figureCount_similarity}; similarity_y_axis_flowTableSize_3{figureCount_similarity}];
            allRound_y_axis_flowTableSize_4{figureCount_similarity} = [allRound_y_axis_flowTableSize_4{figureCount_similarity}; similarity_y_axis_flowTableSize_4{figureCount_similarity}];
            
            filename = ['memory/memory_', int2str(frequency), '_', int2str(flowSimilarity)];
            save(filename)
            
        end
        
        %{
        drawFlowTableSizeFigure_similarity(x_axis, allRound_y_axis_flowTableSize_1, 1, frequency, x_label, x_axis_similarity)
        drawFlowTableSizeFigure_similarity(x_axis, allRound_y_axis_flowTableSize_2, 2, frequency, x_label, x_axis_similarity)
        drawFlowTableSizeFigure_similarity(x_axis, allRound_y_axis_flowTableSize_3, 3, frequency, x_label, x_axis_similarity)
        drawFlowTableSizeFigure_similarity(x_axis, allRound_y_axis_flowTableSize_4, 4, frequency, x_label, x_axis_similarity)

        drawClusterNum_similarity(allRound_y_axis_clusterNum, frequency, x_axis_similarity)
        %}
        
        filename = ['memory/memory_', int2str(frequency)];
        save(filename)
    end

    t2 = datetime('now');
    disp(t2 - t1)
    
    save('memory/final')
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
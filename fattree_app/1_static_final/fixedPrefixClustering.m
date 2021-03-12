function fixedPrefixClustering(roundNumber)
    t1 = datetime('now');
    
    global currentFlowTime

    % number of host under each edge switch
    hostAvg = 50;
    hostSd = 5;

    % randomly select 5000 flows from all flow traces
    flowNum = 5000;

    % capacity of each link
    linkBwdUnit = 10^3; %Kbps
    
    % different merging prefix length
    startPrefixLength = 18;
    endPrefixLength = 28;

    x_axis = startPrefixLength:2:endPrefixLength;
    x_label = 'Prefix Length (bits)';

    % record flow table size result
    allRound_y_axis_flowTableSize_1 = [];
    allRound_y_axis_flowTableSize_2 = [];
    allRound_y_axis_flowTableSize_3 = [];
    allRound_y_axis_flowTableSize_4 = [];

    allRound_y_axis_cdf = cell(length(x_axis), 1);

    for frequency = 1:roundNumber
        % fat tree
        k = 4;
        [swNum, srcNode, dstNode, srcInf, dstInf, g, hostNum, IP] = ...
            createFatTreeTopo(k, hostAvg, hostSd);

        % AS topo
        %eachAsEdgeSwNum = 2;
        %[swNum, srcNode, dstNode, srcInf, dstInf, g, asNum, nodeTable, hostNum, IP] = ...
            %createAsTopo_random(eachAsEdgeSwNum, hostAvg, hostSd);
            
        % distance between any two switch
        swDistanceVector = distances(g, 'Method', 'unweighted');
        swDistanceVector = swDistanceVector(1:swNum, 1:swNum);

        % for AS topo
        %rows = strcmp(nodeTable.Type, 'RT_NODE');
        %swDistanceVector(rows, rows) = 0;
            
        [swInfTable, swFlowEntryStruct, hostIpTable, linkTable, linkThputStruct, initialClusterTable, flowSequence] = ...
            setVariables(swNum, srcNode, dstNode, srcInf, dstInf, g, hostNum, IP);

        % initial some flow info
        initialClusterTable.EdgeId = repmat(-1, size(initialClusterTable, 1), 1);
        initialClusterTable.Group = repmat(-1, size(initialClusterTable, 1), 1);
        initialClusterTable.Prefix = repmat(24, size(initialClusterTable, 1), 1);
        
        % do initial clustering
        initialClusterTable_original = initialClustering_static(initialClusterTable, flowSequence);
        
        flowTraceTable = setNewFlows(flowNum, IP);

        % remove mice flow
        flowStartDatetime = datetime(flowTraceTable.StartDatetime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
        flowEndDatetime = datetime(flowTraceTable.EndDatetime, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');

        rows = (flowEndDatetime - flowStartDatetime < seconds(1));
        flowTraceTable(rows, :) = [];

        flowStartDatetime(rows) = [];
        flowEndDatetime(rows) = [];
        %
        
        swFlowEntryStruct_empty = swFlowEntryStruct;
        linkTable_empty = linkTable;
        linkThputStruct_empty = linkThputStruct;

        % record flow table size result in each round
        y_axis_flowTableSize_1 = [];
        y_axis_flowTableSize_2 = [];
        y_axis_flowTableSize_3 = [];
        y_axis_flowTableSize_4 = [];

        cdfFigureCount = 0;

        for pl = startPrefixLength:2:endPrefixLength
            cdfFigureCount = cdfFigureCount + 1;

            swFlowEntryStruct = swFlowEntryStruct_empty;
            linkTable = linkTable_empty;
            linkThputStruct = linkThputStruct_empty;

            eachFlowFinalPath = {};
            linkPreLower = [];
            
            % record switch table size when table size changes
            allSwTableSize_list = {};
            for i = 1:swNum
               allSwTableSize_list(i).flowNum = [];
            end

            initialClusterTable = initialClusterTable_original;
            initialClusterTable.NewGroup = initialClusterTable.Group;
            
            % corss edge switches
            if pl < 24 
                initialClusterTable = staticMerging(pl, initialClusterTable);
            end
            
            initialClusterTable = table(initialClusterTable.NewGroup, initialClusterTable.SrcIp, initialClusterTable.DstIp, initialClusterTable.SrcSubnet, initialClusterTable.DstSubnet, initialClusterTable.Vlan);
            initialClusterTable = unique(initialClusterTable);
            initialClusterTable.Properties.VariableNames = {'Group', 'SrcIp', 'DstIp', 'SrcSubnet', 'DstSubnet', 'Vlan'};
            
            % initial rendezvous switches
            initialClusterTable.MiddleSrcSw = repmat({{}}, size(initialClusterTable, 1), 1);
            initialClusterTable.MiddleDstSw = repmat({{}}, size(initialClusterTable, 1), 1);
            
            % run 5000 flows
            for i = 1:size(flowTraceTable, 1)
                i
                
                flowTraceTable = clusterNewFlow(i, flowTraceTable, initialClusterTable, pl);

                [srcNodeName, dstNodeName, flowRate, flowTraceTable, flowEntry] = ...
                    setFlowInfo(i, flowStartDatetime(i), flowEndDatetime(i), linkBwdUnit, hostIpTable, flowTraceTable);
                
                currentFlowTime = flowStartDatetime(i);

                % get flow src/dst edge switches
                rows = strcmp(swInfTable.SrcNode, srcNodeName);
                srcEdgeSw = swInfTable{rows, {'DstNode'}}{1};

                rows = strcmp(swInfTable.SrcNode, dstNodeName);
                dstEdgeSw = swInfTable{rows, {'DstNode'}}{1};
                %
                
                % record flow path
                finalPath = findnode(g, srcNodeName);

                if pl < 24 
                    % Haven't found rendezvous switch yet
                    if isempty(flowTraceTable.MiddleSrcSw{i}) && isempty(flowTraceTable.MiddleDstSw{i})
                        % all flow in this group
                        rows = initialClusterTable.Group == flowTraceTable.Group(i);
                        
                        % get src/dst IP
                        srcip_filter = initialClusterTable{rows, {'SrcIp'}};
                        dstip_filter = initialClusterTable{rows, {'DstIp'}};

                        % get src/dst switche
                        srcHost = cellfun(@(x) hostIpTable{strcmp(hostIpTable.IP, x), {'Host'}}, srcip_filter);
                        srcEdgeSw_filter = cellfun(@(x) swInfTable{strcmp(swInfTable.SrcNode, x), {'DstNode'}}, srcHost);
                        uniqueSrcEdgeSw = unique(srcEdgeSw_filter);

                        dstHost = cellfun(@(x) hostIpTable{strcmp(hostIpTable.IP, x), {'Host'}}, dstip_filter);
                        dstEdgeSw_filter = cellfun(@(x) swInfTable{strcmp(swInfTable.SrcNode, x), {'DstNode'}}, dstHost);
                        uniqueDstEdgeSw = unique(dstEdgeSw_filter);
                        %
                        
                        % find rendezvous switches
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
                    %
                    
                    swList = {srcEdgeSw, middleSrcSw, middleDstSw, dstEdgeSw};
                    prefixList = [24, pl, 24];

                    for j = 1:length(swList) - 1
                        firstSw = swList{j};
                        secondSw = swList{j+1};

                        [flowEntry_temp, flowSrcIp, flowDstIp] = setFlowEntry(prefixList(j), flowEntry, flowTraceTable, i);

                        % find switch input port of flow entry
                        if strcmp(firstSw, srcEdgeSw)
                            rows = strcmp(swInfTable.SrcNode, srcNodeName);
                            flowEntry_temp.input = swInfTable{rows, {'DstInf'}};
                        else
                            rows = strcmp(swInfTable.SrcNode, g.Nodes.Name{finalPath(end-1)}) & strcmp(swInfTable.DstNode, g.Nodes.Name{finalPath(end)});
                            flowEntry_temp.input = swInfTable{rows, {'DstInf'}};
                        end
                        %
                        
                        % Hierarchical routing after cluster merging (3 rounds)
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
                
                % record new table size along this path
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

            allRound_y_axis_cdf{cdfFigureCount} = [allRound_y_axis_cdf{cdfFigureCount}; allSwMeanFlowTableSize];

            filename = ['memory/memory_', int2str(frequency), '_', int2str(pl)];
            save(filename)
        end

        allRound_y_axis_flowTableSize_1 = [allRound_y_axis_flowTableSize_1; y_axis_flowTableSize_1];
        allRound_y_axis_flowTableSize_2 = [allRound_y_axis_flowTableSize_2; y_axis_flowTableSize_2];
        allRound_y_axis_flowTableSize_3 = [allRound_y_axis_flowTableSize_3; y_axis_flowTableSize_3];
        allRound_y_axis_flowTableSize_4 = [allRound_y_axis_flowTableSize_4; y_axis_flowTableSize_4];

        %{
        if frequency == 1
            drawFlowTableSizeFigure_fixedPrefix(x_axis, allRound_y_axis_flowTableSize_1, 1, frequency, x_label)
            drawFlowTableSizeFigure_fixedPrefix(x_axis, allRound_y_axis_flowTableSize_2, 2, frequency, x_label)
            drawFlowTableSizeFigure_fixedPrefix(x_axis, allRound_y_axis_flowTableSize_3, 3, frequency, x_label)
            drawFlowTableSizeFigure_fixedPrefix(x_axis, allRound_y_axis_flowTableSize_4, 4, frequency, x_label)
        else
            drawFlowTableSizeFigure_fixedPrefix(x_axis, mean(allRound_y_axis_flowTableSize_1), 1, frequency, x_label)
            drawFlowTableSizeFigure_fixedPrefix(x_axis, mean(allRound_y_axis_flowTableSize_2), 2, frequency, x_label)
            drawFlowTableSizeFigure_fixedPrefix(x_axis, mean(allRound_y_axis_flowTableSize_3), 3, frequency, x_label)
            drawFlowTableSizeFigure_fixedPrefix(x_axis, mean(allRound_y_axis_flowTableSize_4), 4, frequency, x_label)
        end

        drawCdf_fixedPrefix(x_axis, allRound_y_axis_cdf, frequency)
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
    
    % record flow rule number
    for i = 1:length(checkedSwitch)
        allSwTableSize_list(checkedSwitch(i)).flowNum = [allSwTableSize_list(checkedSwitch(i)).flowNum, flowEntryNum(i)];
    end
end

function flowEntryNum = swFlowEntryNumber(x)
    global currentFlowTime
    
    % calculate number of flow number at this time
    if isempty(x.entry)
        flowEntryNum = 0;
    else
        flowEntryNum = length(find(datetime({x.entry.endTime}, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS') >= currentFlowTime));
    end
end
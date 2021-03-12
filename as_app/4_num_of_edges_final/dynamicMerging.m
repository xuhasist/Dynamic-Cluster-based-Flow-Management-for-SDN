function [flowTraceTable, doHierarchyCount, initialClusterTable] = dynamicMerging(tableThreshold, swWithTooManyFlowEntry, ...
    g, swDistanceVector, hostIpTable, swInfTable, eachFlowFinalPath, flowTraceTable, doHierarchyCount, ...
    linkBwdUnit, linkTable, linkPreLower, linkThputStruct, flowStartDatetime, initialClusterTable)

    for i = 1:length(swWithTooManyFlowEntry)
        passFlow = cellfun(@(x) any(ismember(x, swWithTooManyFlowEntry(i))), eachFlowFinalPath, 'UniformOutput', false);
        passFlow = cell2mat(passFlow)';
        
        groupId = flowTraceTable{passFlow, {'Group'}};
        groupId = unique(groupId);
        
        groupNumber = length(groupId);
        doMerging = -1;
        
        while groupNumber >= tableThreshold || doMerging == -1
            doMerging = 1;
            
            groupSize = repmat(-1, length(groupId), 1);
            hierarchicalGroup = zeros(length(groupId), 1);
            
            if length(groupId) <= 1
                break;
            end
            
            for j = 1:length(groupId)
                rows = (flowTraceTable.Group == groupId(j));
                flowhierarchicalGroup = unique(flowTraceTable.HierarchicalGroup(rows));
                
                if length(flowhierarchicalGroup) >= 2
                    'QQ'
                end
                
                hierarchicalGroup(j) = flowhierarchicalGroup;
                
                if flowhierarchicalGroup == 0
                    %groupSize(j) = sum(flowTraceTable{rows, {'Bytes'}});
                    groupSize(j) = length(find(rows));
                else
                    rows = (flowTraceTable.HierarchicalGroup == flowhierarchicalGroup);
                    %groupSize(j) = sum(flowTraceTable{rows, {'Bytes'}});
                    groupSize(j) = length(find(rows));
                end
            end
            
            zero_hierarchicalGroup_rows = (hierarchicalGroup == 0);
            hierarchicalGroupSize = groupSize(~zero_hierarchicalGroup_rows);
            [~, loc] = unique(hierarchicalGroup(~zero_hierarchicalGroup_rows));
            
            sortGroupSize = sort([groupSize(zero_hierarchicalGroup_rows); hierarchicalGroupSize(loc)]);
            
            if length(sortGroupSize) < 2
                break;
            end
            
            rows = ismember(groupSize, sortGroupSize(1:2));
            
            if length(find(rows)) > 2
                finish = false;
                
                while ~finish && length(find(rows)) > 2
                    index = randperm(length(find(rows)), 2);
                    temp = find(rows);
                    loc = temp(index);

                    temp_rows = rows & 0;
                    temp_rows(loc) = 1;

                    temp_hierarchicalGroup = hierarchicalGroup(temp_rows);
                    none_hierarchicalGroup = temp_hierarchicalGroup == 0;
                    if length(unique(temp_hierarchicalGroup(~none_hierarchicalGroup))) == length(temp_hierarchicalGroup(~none_hierarchicalGroup))
                        finish = true;
                    end
                end
            end
            
            mergeGroup = groupId(rows);
            mergeGroup_hierarchicalId = hierarchicalGroup(rows);
            
            doHierarchyCount = doHierarchyCount + 1;
            
            a = hierarchicalGroup(~rows);
            groupNumber = length(find(a == 0)) + length(unique(a(a ~= 0))) + 1; % group + hie_group + now
            
            if unique(mergeGroup_hierarchicalId) == 0
                flow_rows = ismember(flowTraceTable.Group, mergeGroup);
                initial_flow_rows = ismember(initialClusterTable.Group, mergeGroup);
            else
                rows = (mergeGroup_hierarchicalId == 0);
                flow_rows = ismember(flowTraceTable.Group, mergeGroup(rows)) ...
                    | ismember(flowTraceTable.HierarchicalGroup, mergeGroup_hierarchicalId(~rows));
                
                initial_flow_rows = ismember(initialClusterTable.Group, mergeGroup(rows)) ...
                    | ismember(initialClusterTable.HierarchicalGroup, mergeGroup_hierarchicalId(~rows));
            end
            
            srcip_filter = flowTraceTable{flow_rows, {'SrcIp'}};
            dstip_filter = flowTraceTable{flow_rows, {'DstIp'}};
            
            srcHost = cellfun(@(x) hostIpTable{strcmp(hostIpTable.IP, x), {'Host'}}, srcip_filter);
            edge_sw_filter = cellfun(@(x) swInfTable{strcmp(swInfTable.SrcNode, x), {'DstNode'}}, srcHost);
            uniqueSrcEdgeSw = unique(edge_sw_filter);

            dstHost = cellfun(@(x) hostIpTable{strcmp(hostIpTable.IP, x), {'Host'}}, dstip_filter);
            edge_sw_filter = cellfun(@(x) swInfTable{strcmp(swInfTable.SrcNode, x), {'DstNode'}}, dstHost);
            uniqueDstEdgeSw = unique(edge_sw_filter);
            
            if length(uniqueSrcEdgeSw) == 1 && length(uniqueDstEdgeSw) == 1
                middleSrcSw = uniqueSrcEdgeSw;
                middleDstSw = uniqueDstEdgeSw;
            else
                if length(uniqueSrcEdgeSw) == 1
                    middleSrcSw = uniqueSrcEdgeSw;
                else
                    middleSrcSw = findRendezvousSw_dynamic(uniqueSrcEdgeSw, g, swDistanceVector, linkBwdUnit, linkTable, linkPreLower, linkThputStruct, flowStartDatetime, swWithTooManyFlowEntry);
                    middleSrcSw = {middleSrcSw};
                end

                if length(uniqueDstEdgeSw) == 1
                    middleDstSw = uniqueDstEdgeSw;
                else
                    middleDstSw = findRendezvousSw_dynamic(uniqueDstEdgeSw, g, swDistanceVector, linkBwdUnit, linkTable, linkPreLower, linkThputStruct, flowStartDatetime, swWithTooManyFlowEntry);
                    middleDstSw = {middleDstSw};
                end
            end
            
            flowTraceTable.MiddleSrcSw(flow_rows) = {middleSrcSw};
            flowTraceTable.MiddleDstSw(flow_rows) = {middleDstSw};
            
            initialClusterTable.MiddleSrcSw(initial_flow_rows) = {middleSrcSw};
            initialClusterTable.MiddleDstSw(initial_flow_rows) = {middleDstSw};
            
            srcip_filter = cellfun(@(x) strsplit(x, '.'), srcip_filter, 'UniformOutput', false);
            srcSubnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8), dec2bin(str2num(x{3}), 8)), srcip_filter, 'UniformOutput', false);
            uniqueSrcSubnet = unique(srcSubnet);
            
            dstip_filter = cellfun(@(x) strsplit(x, '.'), dstip_filter, 'UniformOutput', false);
            dstSubnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8), dec2bin(str2num(x{3}), 8)), dstip_filter, 'UniformOutput', false);
            uniqueDstSubnet = unique(dstSubnet);
            
            if length(uniqueSrcSubnet) == 1
                resultSrcSubnet = ~xor(logical(uniqueSrcSubnet{1}-'0'), logical(uniqueSrcSubnet{1}-'0'));
            else
                resultSrcSubnet = ~xor(logical(uniqueSrcSubnet{1}-'0'), logical(uniqueSrcSubnet{2}-'0'));
            end

            srcFirstZero = find(resultSrcSubnet == 0, 1);

            if isempty(srcFirstZero)
                srcFirstZero = length(resultSrcSubnet) + 1;
            end

            if length(uniqueDstSubnet) == 1
                resultDstSubnet = ~xor(logical(uniqueDstSubnet{1}-'0'), logical(uniqueDstSubnet{1}-'0'));
            else
                resultDstSubnet = ~xor(logical(uniqueDstSubnet{1}-'0'), logical(uniqueDstSubnet{2}-'0'));
            end

            dstFirstZero = find(resultDstSubnet == 0, 1);

            if isempty(dstFirstZero)
                dstFirstZero = length(resultDstSubnet) + 1;
            end
            
            flowTraceTable.HierarchicalPrefix(flow_rows) = min(srcFirstZero, dstFirstZero) - 1;
            initialClusterTable.HierarchicalPrefix(initial_flow_rows) = min(srcFirstZero, dstFirstZero) - 1;

            hie_groupId = max(flowTraceTable.HierarchicalGroup) + 1;
            flowTraceTable.HierarchicalGroup(flow_rows) = hie_groupId;
            initialClusterTable.HierarchicalGroup(initial_flow_rows) = hie_groupId;
        end
    end
    
    % assign vlan
    hieGroupId = unique(flowTraceTable.HierarchicalGroup);
    rows = (hieGroupId == 0);
    hieGroupId = hieGroupId(~rows);
    
    if isempty(hieGroupId)
        return
    end
    
    subnetSet = [];
    
    for i = 1:length(hieGroupId)
        rows = (flowTraceTable.HierarchicalGroup == hieGroupId(i));

        srcip_filter = flowTraceTable{find(rows, 1), {'SrcIp'}};
        dstip_filter = flowTraceTable{find(rows, 1), {'DstIp'}};

        srcSubnet = strsplit(srcip_filter{1}, '.');
        srcSubnet = strcat(dec2bin(str2num(srcSubnet{1}), 8), dec2bin(str2num(srcSubnet{2}), 8), dec2bin(str2num(srcSubnet{3}), 8));

        dstSubnet = strsplit(dstip_filter{1}, '.');
        dstSubnet = strcat(dec2bin(str2num(dstSubnet{1}), 8), dec2bin(str2num(dstSubnet{2}), 8), dec2bin(str2num(dstSubnet{3}), 8));

        pl = flowTraceTable{find(rows, 1), {'HierarchicalPrefix'}};
        subnetSet = [subnetSet; {srcSubnet(1:pl)}, {dstSubnet(1:pl)}];
    end
    
    subnetSet_table = cell2table(subnetSet);
    subnetSet_table = unique(subnetSet_table);
    subnetSet_table.pl = cellfun(@(x) length(x), subnetSet_table.subnetSet1);
    subnetSet_table = sortrows(subnetSet_table, 'pl');
    uniqueSubnetSet = table2cell(subnetSet_table);

    finish_rows = zeros(size(subnetSet, 1), 1);
    for i = 1:size(uniqueSubnetSet, 1)
        rows = (startsWith(subnetSet(:, 1), uniqueSubnetSet{i, 1}) & startsWith(subnetSet(:, 2), uniqueSubnetSet{i, 2})) & ~finish_rows;
        
        if ~any(rows)
            break
        end
        
        groupId = hieGroupId(rows);
        
        finish_rows = finish_rows | rows;

        randVlan = randperm(4097, length(groupId));

        for j = 1:length(groupId)
            rows = (flowTraceTable.HierarchicalGroup == groupId(j));
            flowTraceTable.Vlan(rows) = randVlan(j);
            
            rows = (initialClusterTable.HierarchicalGroup == groupId(j));
            initialClusterTable.Vlan(rows) = randVlan(j);
        end
    end
end
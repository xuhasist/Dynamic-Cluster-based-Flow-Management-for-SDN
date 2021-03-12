function flowTraceTable = clusterNewFlow_similarity(i, flowTraceTable, initialClusterTable, pl)
    % get new flow subnet
    srcSubnet = flowTraceTable{i, {'SrcSubnet'}};
    dstSubnet = flowTraceTable{i, {'DstSubnet'}};
    
    subnetSet = cellfun(@(x) x(1:pl), srcSubnet, 'UniformOutput', false);
    subnetSet = [subnetSet, cellfun(@(x) x(1:pl), dstSubnet, 'UniformOutput', false)];
    
    row_1 = cellfun(@(x) startsWith(subnetSet{1, 1}, x), initialClusterTable.SrcSubnet);
    row_2 = cellfun(@(x) startsWith(subnetSet{1, 2}, x), initialClusterTable.DstSubnet);
    rows = row_1 & row_2;
    
    if any(rows)
        index = randi(length(find(rows)));
        temp = find(rows);
        loc = temp(index);

        flowTraceTable.Group(i) = initialClusterTable{loc, 'Group'};
        flowTraceTable.Vlan(i) = initialClusterTable{loc, 'Vlan'};
        flowTraceTable.MiddleSrcSw(i) = initialClusterTable{loc, 'MiddleSrcSw'};
        flowTraceTable.MiddleDstSw(i) = initialClusterTable{loc, 'MiddleDstSw'};
    else
        flowTraceTable.Group(i) = max(initialClusterTable.Group) + 1;
        flowTraceTable.Vlan(i) = 1;
        flowTraceTable.MiddleSrcSw(i) = {{}};
        flowTraceTable.MiddleDstSw(i) = {{}};
    end
end
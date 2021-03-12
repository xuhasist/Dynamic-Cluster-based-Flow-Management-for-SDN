function flowTraceTable = clusterNewFlow_dynamic(i, flowTraceTable, initialClusterTable)
    srcip = flowTraceTable{i, {'SrcIp'}};
    dstip = flowTraceTable{i, {'DstIp'}};
    
    srcSubnet = cellfun(@(x) strsplit(x, '.'), srcip, 'UniformOutput', false);
    srcSubnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8), dec2bin(str2num(x{3}), 8), dec2bin(str2num(x{4}), 8)), srcSubnet, 'UniformOutput', false);

    dstSubnet = cellfun(@(x) strsplit(x, '.'), dstip, 'UniformOutput', false);
    dstSubnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8), dec2bin(str2num(x{3}), 8), dec2bin(str2num(x{4}), 8)), dstSubnet, 'UniformOutput', false);
    
    subnetSet = cellfun(@(x) x, srcSubnet, 'UniformOutput', false);
    subnetSet = [subnetSet, cellfun(@(x) x, dstSubnet, 'UniformOutput', false)];
    
    row_1 = cellfun(@(x) startsWith(subnetSet{1, 1}, x), initialClusterTable.SrcSubnet);
    row_2 = cellfun(@(x) startsWith(subnetSet{1, 2}, x), initialClusterTable.DstSubnet);
    rows = row_1 & row_2;
    
    if any(rows)
        index = randi(length(find(rows)));
        temp = find(rows);
        loc = temp(index);
        
        flowTraceTable.Group(i) = initialClusterTable{loc, 'Group'};
        flowTraceTable.Prefix(i) = initialClusterTable{loc, 'Prefix'};
        flowTraceTable.Vlan(i) = initialClusterTable{loc, 'Vlan'};
        flowTraceTable.HierarchicalGroup(i) = initialClusterTable{loc, 'HierarchicalGroup'};
        flowTraceTable.HierarchicalPrefix(i) = initialClusterTable{loc, 'HierarchicalPrefix'};
        flowTraceTable.MiddleSrcSw(i) = initialClusterTable{loc, 'MiddleSrcSw'};
        flowTraceTable.MiddleDstSw(i) = initialClusterTable{loc, 'MiddleDstSw'};
    else
        flowTraceTable.Group(i) = max(flowTraceTable.Group) + 1;
        flowTraceTable.Prefix(i) = 32;
        flowTraceTable.Vlan(i) = 1;
        flowTraceTable.HierarchicalGroup(i) = 0;
        flowTraceTable.HierarchicalPrefix(i) = 0;
        flowTraceTable.MiddleSrcSw(i) = {{}};
        flowTraceTable.MiddleDstSw(i) = {{}};
    end
end
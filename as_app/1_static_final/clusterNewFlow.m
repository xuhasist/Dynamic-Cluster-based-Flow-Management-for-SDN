function flowTraceTable = clusterNewFlow(i, flowTraceTable, initialClusterTable, pl)
    srcip = flowTraceTable{i, {'SrcIp'}};
    dstip = flowTraceTable{i, {'DstIp'}};
    
    srcSubnet = cellfun(@(x) strsplit(x, '.'), srcip, 'UniformOutput', false);
    srcSubnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8), dec2bin(str2num(x{3}), 8)), srcSubnet, 'UniformOutput', false);

    dstSubnet = cellfun(@(x) strsplit(x, '.'), dstip, 'UniformOutput', false);
    dstSubnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8), dec2bin(str2num(x{3}), 8)), dstSubnet, 'UniformOutput', false);
    
    if pl > 24
        pl = 24;
    end
    
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
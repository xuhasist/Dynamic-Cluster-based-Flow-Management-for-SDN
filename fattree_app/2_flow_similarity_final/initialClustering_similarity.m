function [flowTraceTable, sequenceToCentroid_distance] = initialClustering_similarity(flowTraceTable, flowSequence)
    srcip = flowTraceTable.SrcIp;
    dstip = flowTraceTable.DstIp;
    
    srcSubnet = cellfun(@(x) strsplit(x, '.'), srcip, 'UniformOutput', false);
    srcSubnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8), dec2bin(str2num(x{3}), 8), dec2bin(str2num(x{4}), 8)), srcSubnet, 'UniformOutput', false);

    dstSubnet = cellfun(@(x) strsplit(x, '.'), dstip, 'UniformOutput', false);
    dstSubnet = cellfun(@(x) strcat(dec2bin(str2num(x{1}), 8), dec2bin(str2num(x{2}), 8), dec2bin(str2num(x{3}), 8), dec2bin(str2num(x{4}), 8)), dstSubnet, 'UniformOutput', false);
    
    subnetSet = cellfun(@(x) x(1:24), srcSubnet, 'UniformOutput', false);
    subnetSet = [subnetSet, cellfun(@(x) x(1:24), dstSubnet, 'UniformOutput', false)];
    [~, id] = unique(cell2mat(subnetSet), 'rows');
    subnetSet = subnetSet(id,:);
    
    edgeId = 1;
    for j = 1:size(subnetSet, 1)
        rows = startsWith(srcSubnet, subnetSet{j, 1}) & startsWith(dstSubnet, subnetSet{j, 2});
        flowTraceTable.EdgeId(rows) = edgeId;
        edgeId = edgeId + 1;
    end
    
    edgeGroup = unique(flowTraceTable.EdgeId);
    kmeans_preIdx = 0;
    
    % record the distance between binary sequence and centroid
    sequenceToCentroid_distance = table();
    
    for i = 1:length(edgeGroup)
        rows = (flowTraceTable.EdgeId == edgeGroup(i));
        flowSequenceId = flowTraceTable.Index(rows);
        
        [idx, ~, ~, D] = doKmeans(flowSequence(flowSequenceId, :));
        flowTraceTable.Group(rows) = idx + kmeans_preIdx;
        
        kmeans_preIdx = kmeans_preIdx + max(idx);
        
        % record the distance between binary sequence and centroid
        distance = [];
        for j = 1:length(idx)
            distance = [distance; D(j, idx(j))];
        end
        
        T = table(repmat(edgeGroup(i), length(idx), 1), idx, flowSequenceId, distance);
        sequenceToCentroid_distance = [sequenceToCentroid_distance; T];
        %
    end
    
    sequenceToCentroid_distance.Properties.VariableNames = {'EdgeSw', 'Index', 'SequenceNum', 'Distance'};
    sequenceToCentroid_distance = sortrows(sequenceToCentroid_distance, {'EdgeSw', 'Distance'});
    
    initial_groupId = unique(flowTraceTable.Group);
    subnetSet = [];
    pl = 24;
    
    % record which subnet the flow belong to
    for i = 1:length(initial_groupId)
        rows = (flowTraceTable.Group == initial_groupId(i));
        
        %pl = flowTraceTable{find(rows, 1), {'Prefix'}};
        srcSubnet_temp = srcSubnet(rows);
        dstSubnet_temp = dstSubnet(rows);
        subnetSet = [subnetSet; {srcSubnet_temp{1}(1:pl)}, {dstSubnet_temp{1}(1:pl)}];
        
        flowTraceTable.SrcSubnet(rows) = {srcSubnet_temp{1}(1:pl)};
        flowTraceTable.DstSubnet(rows) = {dstSubnet_temp{1}(1:pl)};
    end
    
    subnetSet_table = cell2table(subnetSet);
    subnetSet_table = unique(subnetSet_table);
    subnetSet_table.pl = cellfun(@(x) length(x), subnetSet_table.subnetSet1);
    subnetSet_table = sortrows(subnetSet_table, 'pl');
    uniqueSubnetSet = table2cell(subnetSet_table);
    
    % assign vlan to cluster with the same prefix
    max_vlan = 4097;
    finish_rows = zeros(size(subnetSet, 1), 1);
    for i = 1:size(uniqueSubnetSet, 1)
        rows = (startsWith(subnetSet(:, 1), uniqueSubnetSet{i, 1}) & startsWith(subnetSet(:, 2), uniqueSubnetSet{i, 2})) & ~finish_rows;
        
        if ~any(rows)
            break
        end
        
        groupId = initial_groupId(rows);

        finish_rows = finish_rows | rows;

        randVlan = (max_vlan+1 : max_vlan+1+length(groupId)-1);
        %randVlan = randperm(4097, length(groupId)) - 1;
        
        max_vlan = randVlan(end);

        for j = 1:length(groupId)
            rows = (flowTraceTable.Group == groupId(j));
            flowTraceTable.Vlan(rows) = randVlan(j);
        end
    end
end

function [idx, k, C, D] = doKmeans(flowSequence)
    k = 0;
    pre_avgDistance = -1;
    avgDistance = -1;
    
    while (pre_avgDistance == -1 || ~(avgDistance >= pre_avgDistance * (90/100) && avgDistance <= pre_avgDistance)) && size(flowSequence, 1) > k
        k = k + 1;
        pre_avgDistance = avgDistance;
        
        [idx, C, sumd, D] = kmeans(flowSequence, k);
        
        avg_sumd = [];
        for i = 1:length(sumd)
            avg_sumd(i) = (sumd(i) / length(find(idx == i)));
        end
        avgDistance = mean(avg_sumd);
    end
end
function initialClusterTable = initialClustering_static(initialClusterTable, flowSequence)
    srcip = initialClusterTable.SrcIp;
    dstip = initialClusterTable.DstIp;
    
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
        initialClusterTable.EdgeId(rows) = edgeId;
        edgeId = edgeId + 1;
    end
    
    edgeGroup = unique(initialClusterTable.EdgeId);
    kmeans_preIdx = 0;
    
    for i = 1:length(edgeGroup)
        rows = (initialClusterTable.EdgeId == edgeGroup(i));
        
        [idx, ~, ~, ~] = doKmeans(flowSequence(rows, :));
        initialClusterTable.Group(rows) = idx + kmeans_preIdx;
        
        kmeans_preIdx = kmeans_preIdx + max(idx);
    end
    
    %{
    % calculate longest prefix length
    for i = 1:length(initial_groupId)
        rows = (initialClusterTable.Group == initial_groupId(i));
        
        if length(find(rows)) == 1
            initialClusterTable.Prefix(rows) = 32;
        else
            srcSubnet_temp = srcSubnet(rows);
            
            pl_temp = 32;
            for k = 2:length(srcSubnet_temp)
                resultSrcSubnet = ~xor(logical(srcSubnet_temp{k-1}(1:pl_temp)-'0'), logical(srcSubnet_temp{k}(1:pl_temp)-'0'));
                srcFirstZero = find(resultSrcSubnet == 0, 1);

                if srcFirstZero == 25
                    break;
                elseif isempty(srcFirstZero)
                    srcFirstZero = length(resultSrcSubnet) + 1;
                    continue;
                else
                    pl_temp = srcFirstZero - 1;
                end
            end
            
            if srcFirstZero == 25
                continue;
            end
            
            dstSubnet_temp = dstSubnet(rows);
            
            pl_temp = 32;
            for k = 2:length(dstSubnet_temp)
                resultDstSubnet = ~xor(logical(dstSubnet_temp{k-1}(1:pl_temp)-'0'), logical(dstSubnet_temp{k}(1:pl_temp)-'0'));
                dstFirstZero = find(resultDstSubnet == 0, 1);

                if dstFirstZero == 25
                    break;
                elseif isempty(dstFirstZero)
                    dstFirstZero = length(resultDstSubnet) + 1;
                    continue;
                else
                    pl_temp = dstFirstZero - 1;
                end
            end

            if dstFirstZero == 25
                continue;
            else
                initialClusterTable.Prefix(rows) = min(srcFirstZero, dstFirstZero) - 1;
            end
        end
    end
    %}
    
    % assign vlan
    initial_groupId = unique(initialClusterTable.Group);
    subnetSet = [];
    pl = 24;
    
    for i = 1:length(initial_groupId)
        rows = (initialClusterTable.Group == initial_groupId(i));
        
        %pl = initialClusterTable{find(rows, 1), {'Prefix'}};
        srcSubnet_temp = srcSubnet(rows);
        dstSubnet_temp = dstSubnet(rows);
        subnetSet = [subnetSet; {srcSubnet_temp{1}(1:pl)}, {dstSubnet_temp{1}(1:pl)}];
        
        initialClusterTable.SrcSubnet(rows) = {srcSubnet_temp{1}(1:pl)};
        initialClusterTable.DstSubnet(rows) = {dstSubnet_temp{1}(1:pl)};
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
        
        groupId = initial_groupId(rows);

        finish_rows = finish_rows | rows;

        randVlan = randperm(4097, length(groupId)) - 1;

        for j = 1:length(groupId)
            rows = (initialClusterTable.Group == groupId(j));
            initialClusterTable.Vlan(rows) = randVlan(j);
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
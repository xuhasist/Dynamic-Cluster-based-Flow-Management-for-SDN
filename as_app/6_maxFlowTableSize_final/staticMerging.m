function initialClusterTable = staticMerging(pl, initialClusterTable)
    all_group = unique(initialClusterTable.Group);

    all_group_subnetSet = {};
    groupSubnetTable = table();
    
    for i = 1:length(all_group)
        group_flow = (initialClusterTable.Group == all_group(i));
        
        srcSubnet = initialClusterTable{group_flow, {'SrcSubnet'}};
        dstSubnet = initialClusterTable{group_flow, {'DstSubnet'}};
        
        subnetSet = cellfun(@(x) x(1:pl), srcSubnet, 'UniformOutput', false);
        subnetSet = [subnetSet, cellfun(@(x) x(1:pl), dstSubnet, 'UniformOutput', false)];

        groupSubnetTable = [groupSubnetTable; {all_group(i), subnetSet{1, 1}, subnetSet{1, 2}}];

        all_group_subnetSet = [all_group_subnetSet; subnetSet];
    end
    
    groupSubnetTable.Properties.VariableNames = {'GroupId', 'SrcSubnet', 'DstSubnet'};

    [~, id] = unique(cell2mat(all_group_subnetSet), 'rows');
    all_group_subnetSet = all_group_subnetSet(id,:);
    
    group_index = 1;
    
    for j = 1:size(all_group_subnetSet, 1)
        rows = startsWith(groupSubnetTable.SrcSubnet, all_group_subnetSet{j, 1}) & startsWith(groupSubnetTable.DstSubnet, all_group_subnetSet{j, 2});
        merged_group_index = groupSubnetTable.GroupId(rows);
        
        rows = ismember(initialClusterTable.Group, merged_group_index);

        initialClusterTable.NewGroup(rows) = group_index;
        
        old_srcSubnet = initialClusterTable.SrcSubnet(rows);
        new_srcSubnet = cellfun(@(x) x(1:pl), old_srcSubnet, 'UniformOutput', false);
        
        old_dstSubnet = initialClusterTable.DstSubnet(rows);
        new_dstSubnet = cellfun(@(x) x(1:pl), old_dstSubnet, 'UniformOutput', false);
        
        initialClusterTable.SrcSubnet(rows) = new_srcSubnet;
        initialClusterTable.DstSubnet(rows) = new_dstSubnet;
        
        group_index = group_index + 1;
    end
    
    % assign vlan
    initial_groupId = unique(initialClusterTable.NewGroup);
    subnetSet = [];
    for i = 1:length(initial_groupId)
        rows = (initialClusterTable.NewGroup == initial_groupId(i));
        
        srcSubnet = initialClusterTable{rows, {'SrcSubnet'}};
        dstSubnet = initialClusterTable{rows, {'DstSubnet'}};
        subnetSet = [subnetSet; {srcSubnet{1}}, {dstSubnet{1}}];
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
            rows = (initialClusterTable.NewGroup == groupId(j));
            initialClusterTable.Vlan(rows) = randVlan(j);
        end
    end
end
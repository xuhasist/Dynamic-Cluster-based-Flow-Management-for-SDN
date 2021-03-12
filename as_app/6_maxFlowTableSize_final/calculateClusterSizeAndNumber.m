function [meanClusterSize, clusterNumber] = calculateClusterSizeAndNumber(flowTraceTable)
    rows = (flowTraceTable.HierarchicalGroup == 0);
    uniqueGroupId = unique(flowTraceTable{rows, {'Group'}});
    group_count = length(uniqueGroupId);

    rows = (flowTraceTable.HierarchicalGroup ~= 0);
    uniqueHieGroupId = unique(flowTraceTable{rows, {'HierarchicalGroup'}});
    hieGroup_count = length(uniqueHieGroupId);

    clusterNumber = group_count + hieGroup_count;

    clusterSize = [];
    for c = 1:hieGroup_count
        clusterSize = [clusterSize, length(find(flowTraceTable.HierarchicalGroup == uniqueHieGroupId(c)))];
    end

    for c = 1:group_count
        clusterSize = [clusterSize, length(find(flowTraceTable.Group == uniqueGroupId(c)))];
    end

    meanClusterSize = mean(clusterSize);
end
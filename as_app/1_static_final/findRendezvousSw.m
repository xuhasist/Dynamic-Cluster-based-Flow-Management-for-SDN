function middleSw = findRendezvousSw(edgeSw, g, swDistanceVector, linkBwdUnit, linkTable, linkPreLower, linkThputStruct, flowStartDatetime)
    middleSw = -1;
    distance = 1;
    
    nodeNum = findnode(g, edgeSw);
    
    while middleSw == -1
        for k = 1:length(nodeNum)
            tmp_list{k} = find(ismember(swDistanceVector(nodeNum(k), :), (1:distance)));
        end
        
        merge_node = intersect(tmp_list{1}, tmp_list{2});
        for k = 3:length(tmp_list)
            merge_node = intersect(merge_node, tmp_list{k});
        end
        
        if ~isempty(merge_node)
            utility = [];
            
            for i = 1:length(merge_node)
                throughput = [];
                
                for j = 1:length(edgeSw)
                    path = shortestpath(g, merge_node(i), nodeNum(j));
                   
                    bottleneckLinkLoad = -1;
                    bottleneckLinkWeight = 0;
                    congestion = -1;
                    pathIndex = [];
                    for k = 1:length(path)-1
                        pathIndex = [pathIndex, findedge(g, path(k), path(k+1))];
                    end

                    linkTable.Load = zeros(size(linkTable, 1), 1);
                    linkTable = updateLinkLoad(linkTable, linkPreLower, linkThputStruct, flowStartDatetime, pathIndex);

                    [val, loc] = min(linkTable{pathIndex,'Load'});
                    if val < bottleneckLinkLoad || bottleneckLinkLoad == -1
                        bottleneckLinkLoad = val; %Bytes
                        bottleneckLinkLoad = bottleneckLinkLoad * 8; %bits

                        bottleneckLinkWeight = linkTable.Weight(pathIndex(loc));
                        bottleneckLinkWeight = bottleneckLinkWeight * linkBwdUnit; %10Kbps
                    end

                    congest = bottleneckLinkLoad / bottleneckLinkWeight;
                    if congest < congestion || congestion == -1
                       congestion = congest;
                    end
                    
                    throughput = [throughput, -congestion];
                end
                
                utility = [utility, sum(throughput)];
            end
            
            [~, loc] = max(utility);
            middleSw = g.Nodes.Name{merge_node(loc)};
        end
        
        distance = distance + 1;
    end
end

% find current link load
function linkTable = updateLinkLoad(linkTable, linkPreLower, linkThputStruct, flowStartDatetime, pathIndex)  
    for i = 1:length(pathIndex)
        % No flow through this link yet
        if isempty(linkThputStruct(pathIndex(i)).entry)
            continue
        end

        rows = (flowStartDatetime >= datetime({linkThputStruct(pathIndex(i)).entry(linkPreLower(pathIndex(i)):end).startTime}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS')) ...
            & (flowStartDatetime < datetime({linkThputStruct(pathIndex(i)).entry(linkPreLower(pathIndex(i)):end).endTime}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));

        if any(rows)
            linkTable(pathIndex(i), {'Load'}) = {linkThputStruct(pathIndex(i)).entry(find(rows) + linkPreLower(pathIndex(i)) - 1).load};
        end
    end
end
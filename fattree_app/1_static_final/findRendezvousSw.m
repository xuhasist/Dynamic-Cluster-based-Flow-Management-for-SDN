function middleSw = findRendezvousSw(edgeSw, g, swDistanceVector, linkBwdUnit, linkTable, linkPreLower, linkThputStruct, flowStartDatetime)
    middleSw = -1;
    distance = 1;
    
    nodeNum = findnode(g, edgeSw);
    
    while middleSw == -1
        % find all candidate rendezvous switches are x hops distant from the src (dst) switch
        for k = 1:length(nodeNum)
            tmp_list{k} = find(ismember(swDistanceVector(nodeNum(k), :), (1:distance)));
        end
        
        % Find the intersection of all candidate rendezvous switches
        merge_node = intersect(tmp_list{1}, tmp_list{2});
        for k = 3:length(tmp_list)
            merge_node = intersect(merge_node, tmp_list{k});
        end
        
        if ~isempty(merge_node)
            utility = [];
            
            % find maximum throuthput
            for i = 1:length(merge_node)
                throughput = [];
                
                for j = 1:length(edgeSw)
                    % find shortestpath between rendezvous switch and clusters
                    path = shortestpath(g, merge_node(i), nodeNum(j));
                   
                    bottleneckLinkLoad = -1;
                    bottleneckLinkWeight = 0;
                    congestion = -1;
                    pathIndex = [];
                    for k = 1:length(path)-1
                        pathIndex = [pathIndex, findedge(g, path(k), path(k+1))];
                    end

                    % find all link load along this path
                    linkTable.Load = zeros(size(linkTable, 1), 1);
                    linkTable = updateLinkLoad(linkTable, linkPreLower, linkThputStruct, flowStartDatetime, pathIndex);

                    % find bottle neck link
                    [val, loc] = min(linkTable{pathIndex,'Load'});
                    if val < bottleneckLinkLoad || bottleneckLinkLoad == -1
                        bottleneckLinkLoad = val; %Bytes
                        bottleneckLinkLoad = bottleneckLinkLoad * 8; %bits

                        bottleneckLinkWeight = linkTable.Weight(pathIndex(loc));
                        bottleneckLinkWeight = bottleneckLinkWeight * linkBwdUnit; %10Kbps
                    end

                    % path congestion
                    congest = bottleneckLinkLoad / bottleneckLinkWeight;
                    if congest < congestion || congestion == -1
                       congestion = congest;
                    end
                    
                    throughput = [throughput, -congestion];
                end
                
                % utility value of all candidate rendezvous switches
                utility = [utility, sum(throughput)];
            end
            
            % find the max utility
            [~, loc] = max(utility);
            middleSw = g.Nodes.Name{merge_node(loc)};
        end
        
        % no intersection, increase distance
        distance = distance + 1;
    end
end

% find all link load along this path
function linkTable = updateLinkLoad(linkTable, linkPreLower, linkThputStruct, flowStartDatetime, pathIndex)  
    for i = 1:length(pathIndex)
        % No flow through this link yet
        if isempty(linkThputStruct(pathIndex(i)).entry)
            continue
        end

        % find the link load at this time
        rows = (flowStartDatetime >= datetime({linkThputStruct(pathIndex(i)).entry(linkPreLower(pathIndex(i)):end).startTime}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS')) ...
            & (flowStartDatetime < datetime({linkThputStruct(pathIndex(i)).entry(linkPreLower(pathIndex(i)):end).endTime}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));

        if any(rows)
            linkTable(pathIndex(i), {'Load'}) = {linkThputStruct(pathIndex(i)).entry(find(rows) + linkPreLower(pathIndex(i)) - 1).load};
        end
        %
    end
end
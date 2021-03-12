function meanNetworkThrouput = calculateNetworkThrouput(g, linkBwdUnit, ...
	linkThputStruct, eachFlowFinalPath, flowTraceTable, flowStartDatetime, flowEndDatetime)
        
    networkThroughput = byFlowSaturation(g, linkBwdUnit, linkThputStruct, ...
        eachFlowFinalPath, flowTraceTable, flowStartDatetime, flowEndDatetime);
    
    meanNetworkThrouput = mean(networkThroughput);
end

function networkThroughput = byFlowSaturation(g, linkBwdUnit, linkThputStruct, ...
	eachFlowFinalPath, flowTraceTable, flowStartDatetime, flowEndDatetime)
        
    for i = 1:length(linkThputStruct)
        if isempty(linkThputStruct(i).entry)
            continue
        else
            rows = cellfun(@strcmp, {linkThputStruct(i).entry.startTime}, {linkThputStruct(i).entry.endTime});
            linkThputStruct(i).entry(rows) = [];

            x = num2cell((10*linkBwdUnit)./ [linkThputStruct(i).entry.flowNum]);
            [linkThputStruct(i).entry.limit] = deal(x{:});

            x = num2cell(datetime({linkThputStruct(i).entry.startTime}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
            [linkThputStruct(i).entry.startTime] = deal(x{:});

            x = num2cell(datetime({linkThputStruct(i).entry.endTime}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
            [linkThputStruct(i).entry.endTime] = deal(x{:});
        end
    end

    networkThroughput = [];

    begin_time = datetime('2009-12-18 00:32:26.775', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    end_time = datetime('2009-12-18 00:37:26.775', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');

    preEnd_tmp = ones(1, length(linkThputStruct));
    while begin_time ~= end_time
        begin_time

        preEnd = preEnd_tmp;
        link_entry_cluster = {};
        
        rows = ((flowStartDatetime >= begin_time) & (flowStartDatetime < begin_time + minutes(1))) ...
            | ((flowEndDatetime >= begin_time) & (flowEndDatetime <= begin_time + minutes(1)));

        if any(rows)
            flow_index = find(rows);
            flowRateArray = flowTraceTable{flow_index, {'Rate_bps'}};

            for i = 1:length(flow_index)
                path = eachFlowFinalPath{flow_index(i)};
                edge = findedge(g, path, circshift(path, -1));

                for j = 1:length(edge)-1
                    if isempty(link_entry_cluster) || length(link_entry_cluster) < edge(j) || isempty(link_entry_cluster{edge(j)}) 
                        rows = (([linkThputStruct(edge(j)).entry(preEnd(edge(j)):end).startTime] >= begin_time) ...
                            & ([linkThputStruct(edge(j)).entry(preEnd(edge(j)):end).startTime] < begin_time + minutes(1))) ...
                            | (([linkThputStruct(edge(j)).entry(preEnd(edge(j)):end).endTime] >= begin_time) ...
                            & ([linkThputStruct(edge(j)).entry(preEnd(edge(j)):end).endTime] <= begin_time + minutes(1)));
                        
                        link_entry_cluster{edge(j)} = rows;
                    else
                        rows = link_entry_cluster{edge(j)};
                    end
                    
                    rows_index = find(rows) + preEnd(edge(j)) - 1;

                    s_time = [linkThputStruct(edge(j)).entry(rows_index).startTime];
                    e_time = [linkThputStruct(edge(j)).entry(rows_index).endTime];
                    rateLimitArray = [linkThputStruct(edge(j)).entry(rows_index).limit];

                    preEnd_tmp(edge(j)) = rows_index(end);

                    rows = s_time < begin_time;
                    s_time(rows) = begin_time;

                    rows = e_time > begin_time + minutes(1);
                    e_time(rows) = begin_time + minutes(1);

                    ration = minutes(e_time - s_time);
                    ration = ration / sum(ration);
                    
                    flowThput = rateLimitArray.* ration;
                    flowThput_sum = sum(flowThput);

                    if flowThput_sum < flowRateArray(i)
                        flowRateArray(i) = flowThput_sum;
                    end
                end
            end

            networkThroughput = [networkThroughput, sum(flowRateArray)];
        else
            networkThroughput = [networkThroughput, 0];
        end

        begin_time = begin_time + minutes(1);
    end
end
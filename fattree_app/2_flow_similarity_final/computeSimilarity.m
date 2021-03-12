function flowTraceTable = computeSimilarity(flowTraceTable, sequenceToCentroid_distance, flowSimilarity, flowNum)
    % get all edge switch
    edgeSwNum = unique(flowTraceTable.EdgeId);
    
    allFlowNum = size(flowTraceTable, 1);
    valid_sequence = [];
    
    for i = 1:length(edgeSwNum)
       rows = (sequenceToCentroid_distance.EdgeSw == edgeSwNum(i));
       
       % flow binary sequence under this edge switch 
       unique_sequence = unique(sequenceToCentroid_distance.SequenceNum(rows), 'stable');

       % how many flows will be extracted under this switch
       similarity_filter = ceil(flowSimilarity * (length(unique_sequence) / allFlowNum));
       
       % the most similar n flows
       valid_sequence = [valid_sequence, unique_sequence(1:similarity_filter)'];
    end

    valid_sequence = unique(valid_sequence);
    
    pickFlowTrace = [];
    
    % Replicate x flows to 5,000 flows
    while length(pickFlowTrace) < flowNum
        if flowNum - length(pickFlowTrace) > length(valid_sequence)
            pickFlowTrace = [pickFlowTrace, randperm(length(valid_sequence), length(valid_sequence))];
        else
            pickFlowTrace = [pickFlowTrace, randperm(length(valid_sequence), flowNum - length(pickFlowTrace))];
        end
    end

    flowTraceTable_temp = table();
    for i = 1:flowNum
       rows = (flowTraceTable.Index == valid_sequence(pickFlowTrace(i)));
       flowTraceTable_temp = [flowTraceTable_temp; flowTraceTable(rows, :)];
    end
    %

    flowTraceTable_temp = sortrows(flowTraceTable_temp, 'StartDatetime');
    flowTraceTable = flowTraceTable_temp;
end
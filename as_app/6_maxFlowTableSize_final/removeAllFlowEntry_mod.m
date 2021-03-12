function swFlowEntryStruct = removeAllFlowEntry_mod(swFlowEntryStruct, flowStartDatetime, mergedFlow)
    mergedFlow = unique(mergedFlow);
    
    for i = 1:length(swFlowEntryStruct)
        if isempty(swFlowEntryStruct(i).entry)
            continue;
        end
        
        rows = arrayfun(@(x) any(ismember(mergedFlow, x.flowId)), swFlowEntryStruct(i).entry) & datetime({swFlowEntryStruct(i).entry.endTime}, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS') >= flowStartDatetime;
        
        resetEntryEndTime = cell(1, length(find(rows)));
        resetEntryEndTime(1:end) = {datestr(flowStartDatetime - seconds(0.001), 'yyyy-mm-dd HH:MM:ss.FFF')};
        [swFlowEntryStruct(i).entry(rows).endTime] = deal(resetEntryEndTime{:});
    end
    
    %{
    for i = 1:length(swFlowEntryStruct)
        if isempty(swFlowEntryStruct(i).entry)
            continue;
        end
        
        rows = datetime({swFlowEntryStruct(i).entry.endTime}, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS') >= flowStartDatetime;
        
        resetEntryEndTime = cell(1, length(find(rows)));
        resetEntryEndTime(1:end) = {datestr(flowStartDatetime - seconds(0.001), 'yyyy-mm-dd HH:MM:ss.FFF')};
        [swFlowEntryStruct(i).entry(rows).endTime] = deal(resetEntryEndTime{:});
    end
    %}
end
function result = calculate_max_tableSize(swFlowEntryStruct)
    all_sw_table_size = [];
    for i = 1:size(swFlowEntryStruct, 2)
        begin_time = datetime('2009-12-18 00:32:26.775', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
        end_time = datetime('2009-12-18 00:38:26.775', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS');
    
        table_size = [];
        
        if isempty(swFlowEntryStruct(i).entry)
            continue
        end
        
        x = num2cell(datetime({swFlowEntryStruct(i).entry.startTime}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
        [swFlowEntryStruct(i).entry.startTime] = deal(x{:});
        
        x = num2cell(datetime({swFlowEntryStruct(i).entry.endTime}', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS'));
        [swFlowEntryStruct(i).entry.endTime] = deal(x{:});
            
        while begin_time ~= end_time
            rows = ([swFlowEntryStruct(i).entry.startTime] <= begin_time) & ([swFlowEntryStruct(i).entry.endTime] >= begin_time);
            
            table_size = [table_size, length(find(rows))];
            
            begin_time = begin_time + seconds(1);
        end
        
        all_sw_table_size = [all_sw_table_size; table_size];
    end
    
    result = max(all_sw_table_size);
    %result = median(all_sw_table_size);
end
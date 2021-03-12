function [meanFlowTableSize_1, meanFlowTableSize_2, meanFlowTableSize_3, meanFlowTableSize_4, allSwMeanFlowTableSize] = calculateFlowTableSize(allSwTableSize_list)
    
    % calculate average table size of each switch
    meanFlowTableSize = [];
    for i = 1:length(allSwTableSize_list)
        if isempty(allSwTableSize_list(i).flowNum)
            meanFlowTableSize = [meanFlowTableSize, 0];
        else
            meanFlowTableSize = [meanFlowTableSize, mean(allSwTableSize_list(i).flowNum)];
        end
    end
    
    meanFlowTableSize = sort(meanFlowTableSize, 'descend');
    
    meanFlowTableSize_1 = mean(meanFlowTableSize); % mean of all switches
    
    % number of switch in different percent
    first_n_sw_10percent = ceil(length(allSwTableSize_list) * 0.1); 
    first_n_sw_25percent = ceil(length(allSwTableSize_list) * 0.25); 
    first_n_sw_50percent = ceil(length(allSwTableSize_list) * 0.5); 
    
    meanFlowTableSize_2 = mean(meanFlowTableSize(1:first_n_sw_10percent)); % 90%-100%
    meanFlowTableSize_3 = mean(meanFlowTableSize(1:first_n_sw_25percent)); % 75%-100%
    meanFlowTableSize_4 = mean(meanFlowTableSize(1:first_n_sw_50percent)); % 50%-100%

    % for CDF figure
    allSwMeanFlowTableSize = sort(meanFlowTableSize);
end
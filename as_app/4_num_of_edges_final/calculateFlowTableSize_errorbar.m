function [meanFlowTableSize, meanFlowTableSize_90, meanFlowTableSize_10, allSwMeanFlowTableSize] = ...
    calculateFlowTableSize_errorbar(allSwTableSize_list)
    
    meanFlowTableSize = [];
    for i = 1:length(allSwTableSize_list)
        if isempty(allSwTableSize_list(i).flowNum)
            meanFlowTableSize = [meanFlowTableSize, 0];
        else
            meanFlowTableSize = [meanFlowTableSize, mean(allSwTableSize_list(i).flowNum)];
        end
    end
    
    meanFlowTableSize = sort(meanFlowTableSize, 'descend');
    
    meanFlowTableSize_1 = mean(meanFlowTableSize);
    
    first_n_sw_10percent = ceil(length(allSwTableSize_list) * 0.1);
    
    meanFlowTableSize_90 = mean(meanFlowTableSize(1:first_n_sw_10percent));
    meanFlowTableSize_10 = mean(meanFlowTableSize(end-first_n_sw_10percent+1:end));

    allSwMeanFlowTableSize = sort(meanFlowTableSize);
    
    meanFlowTableSize = meanFlowTableSize_1;
end
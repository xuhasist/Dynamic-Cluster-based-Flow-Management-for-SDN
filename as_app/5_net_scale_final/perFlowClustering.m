function [meanFlowTableSize_perFlow, meanFlowTableSize_perFlow_90, meanFlowTableSize_perFlow_10, meanNetworkThrouput_perFlow, meanPathLength_perFlow] =  ...
    perFlowClustering(swNum, flowStartDatetime, flowEndDatetime, linkBwdUnit, ...
    hostIpTable, flowTraceTable, swFlowEntryStruct, g, swInfTable, linkTable, linkThputStruct)
        
    global currentFlowTime
    
    eachFlowFinalPath = {};
    linkPreLower = [];
    
    allSwTableSize_list = {};
    for i = 1:swNum
       allSwTableSize_list(i).flowNum = [];
    end
        
    for i = 1:size(flowTraceTable, 1)
        ['per-flow ', int2str(i)]
        
        [srcNodeName, dstNodeName, flowRate, flowTraceTable, flowEntry] = ...
            setFlowInfo_perFlow(i, flowStartDatetime(i), flowEndDatetime(i), linkBwdUnit, hostIpTable, flowTraceTable);
        
        currentFlowTime = flowStartDatetime(i);

        rows = strcmp(swInfTable.SrcNode, srcNodeName);
        srcEdgeSw = swInfTable{rows, {'DstNode'}}{1};

        rows = strcmp(swInfTable.SrcNode, dstNodeName);
        dstEdgeSw = swInfTable{rows, {'DstNode'}}{1};

        finalPath = findnode(g, srcNodeName);
        
        prefixLength = 32;
        [flowEntry, flowSrcIp, flowDstIp]  = setFlowEntry(prefixLength, flowEntry, flowTraceTable, i);
                    
        rows = strcmp(swInfTable.SrcNode, srcNodeName);
        flowEntry.input = swInfTable{rows, {'DstInf'}};

        round = 3;

        [finalPath, swFlowEntryStruct, linkTable, ~] = ...
            processPkt(g, linkTable, linkBwdUnit, swInfTable, hostIpTable, ...
            swFlowEntryStruct, linkPreLower, linkThputStruct, flowEntry, finalPath, ...
            flowStartDatetime(i), srcEdgeSw, dstEdgeSw, round, dstNodeName, flowSrcIp, flowDstIp);
        
        finalPath = [finalPath, findnode(g, dstNodeName)];
        finalPath(diff(finalPath)==0) = [];
        eachFlowFinalPath = [eachFlowFinalPath; finalPath];
        
        allSwTableSize_list = recordSwTableSize(swFlowEntryStruct, finalPath, allSwTableSize_list);

        [linkThputStruct, linkPreLower] = ...
            updateLinkStruct(finalPath, g, linkThputStruct, ...
            flowStartDatetime(i), flowEndDatetime(i), linkPreLower, flowEntry, flowRate);
    end
    
    [meanFlowTableSize, meanFlowTableSize_90, meanFlowTableSize_10, ~] = calculateFlowTableSize_errorbar(allSwTableSize_list);
    
    meanFlowTableSize_perFlow = meanFlowTableSize;
    meanFlowTableSize_perFlow_90 = meanFlowTableSize_90;
    meanFlowTableSize_perFlow_10 = meanFlowTableSize_10;
    
    meanNetworkThrouput = calculateNetworkThrouput(g, linkBwdUnit, ...
        linkThputStruct, eachFlowFinalPath, flowTraceTable, flowStartDatetime, flowEndDatetime);
    
    meanNetworkThrouput_perFlow = meanNetworkThrouput;
    meanPathLength_perFlow = mean(cellfun(@(x) length(x), eachFlowFinalPath));
end

function allSwTableSize_list = recordSwTableSize(swFlowEntryStruct, finalPath, allSwTableSize_list)
    checkedSwitch = finalPath(2:end-1);
    
    flowEntryNum = arrayfun(@swFlowEntryNumber, swFlowEntryStruct(checkedSwitch));
    
    for i = 1:length(checkedSwitch)
        allSwTableSize_list(checkedSwitch(i)).flowNum = [allSwTableSize_list(checkedSwitch(i)).flowNum, flowEntryNum(i)];
    end
end

function flowEntryNum = swFlowEntryNumber(x)
    global currentFlowTime
    
    if isempty(x.entry)
        flowEntryNum = 0;
    else
        flowEntryNum = length(find(datetime({x.entry.endTime}, 'Format', 'yyyy-MM-dd HH:mm:ss.SSS') >= currentFlowTime));
    end
end
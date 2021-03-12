clearvars
close all;

load('../memory_0512/final')

x_label = 'Flow Table Utilization Threshold';
x_axis = x_axis / 250;

y_axis_flowTableSize = [mean(allRound_y_axis_flowTableSize); mean(allRound_y_axis_flowTableSize_90); mean(allRound_y_axis_flowTableSize_10)];
y_axis_flowTableSize_perFlow = [mean(allRound_y_axis_flowTableSize_perFlow); mean(allRound_y_axis_flowTableSize_perFlow_90); mean(allRound_y_axis_flowTableSize_perFlow_10)];
drawFlowTableSizeFigure(x_axis, y_axis_flowTableSize, y_axis_flowTableSize_perFlow, x_label)

drawNetworkThroughputFigure(x_axis, mean(allRound_y_axis_networkThroughput), mean(allRound_y_axis_networkThroughput_perFlow), x_label)
drawPathLengthFigure(x_axis, mean(allRound_y_axis_pathLength), mean(allRound_y_axis_pathLength_perFlow), x_label)
drawFlowMergingFigure(x_axis, mean(allRound_y_axis_doHierarchyCount), x_label)

drawClusterSize(x_axis, mean(allRound_y_axis_clusterSize), x_label)
drawClusterNumber(x_axis, mean(allRound_y_axis_clusterNumber), x_label)
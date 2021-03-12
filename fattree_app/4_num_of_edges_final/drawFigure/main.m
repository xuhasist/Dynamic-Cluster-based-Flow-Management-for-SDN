clearvars
close all;

load('../memory_0513/final')

x_label = 'Number of Edge Switches';

y_axis_flowTableSize = [mean(allRound_y_axis_flowTableSize); mean(allRound_y_axis_flowTableSize_90); mean(allRound_y_axis_flowTableSize_10)];
y_axis_flowTableSize_perFlow = [mean(allRound_y_axis_flowTableSize_perFlow); mean(allRound_y_axis_flowTableSize_perFlow_90); mean(allRound_y_axis_flowTableSize_perFlow_10)];
drawFlowTableSizeFigure(x_axis, y_axis_flowTableSize, y_axis_flowTableSize_perFlow, x_label)

drawNetworkThroughputFigure(x_axis, mean(allRound_y_axis_networkThroughput), mean(allRound_y_axis_networkThroughput_perFlow), x_label)
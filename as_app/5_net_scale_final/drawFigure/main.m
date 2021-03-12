clearvars
close all;

load('../memory_0516/final')

y_axis_flowTableSize = [mean(allRound_y_axis_flowTableSize); mean(allRound_y_axis_flowTableSize_90); mean(allRound_y_axis_flowTableSize_10)];
drawFlowTableSizeFigure(x_axis, y_axis_flowTableSize, mean(allRound_y_axis_flowTableSize_perFlow), x_label)

drawNetworkThroughputFigure(x_axis, mean(allRound_y_axis_networkThroughput), mean(allRound_y_axis_networkThroughput_perFlow), x_label)

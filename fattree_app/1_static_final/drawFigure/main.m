clearvars
close all;
load('../memory_0508/final')

y_axis_flowTableSize = [mean(allRound_y_axis_flowTableSize_1); mean(allRound_y_axis_flowTableSize_2); mean(allRound_y_axis_flowTableSize_3); mean(allRound_y_axis_flowTableSize_4)];
drawFlowTableSizeFigure_fixedPrefix(x_axis, y_axis_flowTableSize, x_label)

drawCdf_fixedPrefix(x_axis, allRound_y_axis_cdf)
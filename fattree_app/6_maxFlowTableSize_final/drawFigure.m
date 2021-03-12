clearvars

load('timeout_60')

h_figure = figure;
marker = {'-o', '-v', '-x', '-s', '-d'}';
marker_id = 1;

legend_words = {};    
for j = size(result_prefix, 1):-1:1
    plot((1:5:300), result_prefix{j}(1:5:300), 'LineWidth', 1)
    hold on
end

legend_words = [legend_words; 'Timeout = 60s, PL = 24'];

for j = size(result_threshold, 1):-1:1
    plot((1:5:300), result_threshold{j}(1:5:300), marker{marker_id}, 'MarkerSize', 3, 'LineWidth', 1)
    legend_words = [legend_words; ['Timeout = 60s, Threshold = ', num2str(x_axis_tableThreshold(j)/250)]];
    
    marker_id = marker_id + 1;
end

load('timeout_10')

for j = size(result_prefix, 1):-1:1
    plot((1:5:300), result_prefix{j}(1:5:300), marker{marker_id}, 'MarkerSize', 3, 'LineWidth', 1)
    marker_id = marker_id + 1;
end

legend_words = [legend_words; 'Timeout = 10s, PL = 24'];

for j = size(result_threshold, 1):-1:1
    plot((1:5:300), result_threshold{j}(1:5:300), marker{marker_id}, 'MarkerSize', 3, 'LineWidth', 1)
    legend_words = [legend_words; ['Timeout = 10s, Threshold = ', num2str(x_axis_tableThreshold(j)/250)]];
    
    marker_id = marker_id + 1;
end

hold off
    
hl = legend(legend_words, 'Location', 'NorthEast', 'FontSize', 8);

legend boxoff;
box off;

xlabel('Seconds')
ylabel('Maximum Flow Table Size')

xlim([0 300]);
ylim([0 700]);

set(h_figure, 'PaperPositionMode', 'manual');
set(h_figure, 'PaperUnits', 'inches');
set(h_figure, 'Units', 'inches');
set(h_figure, 'PaperPosition', [0, 0, 4.5, 3]); % control eps size
set(h_figure, 'Position', [0, 0, 4.5, 3]); 
print(h_figure, '-depsc', 'maxFlowTableSize_fattree.eps');
function drawFlowTableSizeFigure_fixedPrefix(x_axis, y_axis_flowTableSize, x_label)
    x = x_axis;
    y = y_axis_flowTableSize;
    
    h_figure = figure;
    hold on;
    
    plot(x, y(2,:), '--o', 'LineWidth', 2)
    plot(x, y(3,:), '-.x', 'LineWidth', 2)
    plot(x, y(4,:), ':v', 'LineWidth', 2)
    plot(x, y(1,:), '-s', 'LineWidth', 2)
    
    hold off;
    
    hl = legend('mean of 90% - 100%', 'mean of 75% - 100%', 'mean of 50% - 100%', 'mean', 'Location', 'NorthWest');
    %pos = get(hl, 'position');
    %set(hl, 'position', [pos(1)+0.001 pos(2)+0.08 pos(3) pos(4)]);
    
    legend boxoff;
    
    xlabel(x_label)
    ylabel('Number of Flow Rules');
    
    set(gca, 'XTick', (18:2:28));
    
    xlim([18 28]);
    ylim([0 500]);

    set(h_figure, 'PaperPositionMode', 'manual');
    set(h_figure, 'PaperUnits', 'inches');
    set(h_figure, 'Units', 'inches');
    set(h_figure, 'PaperPosition', [0, 0, 4.5, 3]); % control eps size
    set(h_figure, 'Position', [0, 0, 4.5, 3]); 
    print(h_figure, '-depsc', 'static_flowTableSize_as.eps');
end
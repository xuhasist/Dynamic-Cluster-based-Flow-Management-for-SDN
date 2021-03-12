function drawPathLengthFigure(x_axis, y_axis_pathLength, y_axis_pathLength_perFlow, x_label)
    x = 1:length(x_axis);
    y = y_axis_pathLength_perFlow;
    a = y';
    
    h_figure = figure;
    %hold on
    
    %plot(x, y, '--o', 'LineWidth', 2)
    
    y = y_axis_pathLength;
    a = [a, y'];
    
    %plot(x, y, '-.x', 'LineWidth', 2)
    b = bar(x, a);
    b(2).FaceColor = 'y';
    
    %hold off
    
    hl = legend('per-flow', 'cluster-based', 'Location', 'NorthEast');
    %pos = get(hl, 'position');
    %set(hl, 'position', [pos(1)+0.001 pos(2)+0.08 pos(3) pos(4)]);
    
    legend boxoff;
    
    xlabel(x_label)
    ylabel('Length of Flow Path')

    set(gca, 'XTick', x);
    xticklabels({num2str(x_axis(1)), num2str(x_axis(2)), num2str(x_axis(3)), num2str(x_axis(4))})
    
    %xlim([x(1) x(end)]);
    ylim([0 10]);

    set(h_figure, 'PaperPositionMode', 'manual');
    set(h_figure, 'PaperUnits', 'inches');
    set(h_figure, 'Units', 'inches');
    set(h_figure, 'PaperPosition', [0, 0, 4.5, 3]); % control eps size
    set(h_figure, 'Position', [0, 0, 4.5, 3]); 
    print(h_figure, '-depsc', 'dynamic_pathLength_as.eps');
end
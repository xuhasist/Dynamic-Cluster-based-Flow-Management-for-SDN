function drawNetworkThroughputFigure(x_axis, y_axis_networkThroughput, y_axis_networkThroughput_perFlow, x_label)
    %x = x_axis;
    x = (1:3);
    y_perflow = y_axis_networkThroughput_perFlow;
    y_perflow = y_perflow/(10^3);
    a = y_perflow';

    h_figure = figure;
    %hold on
    
    %plot(x, y, '--o', 'LineWidth', 2)
    
    y = y_axis_networkThroughput;
    y = y/(10^3);
    a = [a, y'];
    
    %plot(x, y, '-.x', 'LineWidth', 2)
    b = bar(x, a);
    b(2).FaceColor = 'y';
    
    %hold off
    
    labels = {};
    for i = 1:length(y)
        percentage = (1-(y(i)/y_perflow(i))) * 100;
        
        labels = [labels, [num2str(round(percentage)), '%']];
    end
    
    hl = legend('per-flow', 'cluster-based', 'Location', 'NorthWest');
    %pos = get(hl, 'position');
    %set(hl, 'position', [pos(1)+0.001 pos(2)+0.08 pos(3) pos(4)]);
    
    legend boxoff;

    xlabel(x_label)
    ylabel('Network Throuput (Mbps)')
    
    set(gca, 'XTick', x);
    xticklabels({num2str(x_axis(1)), num2str(x_axis(2)), num2str(x_axis(3))})
    
    %xlim([x(1) x(end)]);
    ylim([0 5000]);

    set(h_figure, 'PaperPositionMode', 'manual');
    set(h_figure, 'PaperUnits', 'inches');
    set(h_figure, 'Units', 'inches');
    set(h_figure, 'PaperPosition', [0, 0, 4.5, 3]); % control eps size
    set(h_figure, 'Position', [0, 0, 4.5, 3]); 
    print(h_figure, '-depsc', 'netScale_networkThroughput_fatTree.eps');
end
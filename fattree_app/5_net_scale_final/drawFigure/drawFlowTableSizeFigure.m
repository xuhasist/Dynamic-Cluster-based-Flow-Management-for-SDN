function drawFlowTableSizeFigure(x_axis, y_axis_flowTableSize, y_axis_flowTableSize_perFlow, x_label)
    %x = x_axis;
    x = (1:3);
    y_perflow = y_axis_flowTableSize_perFlow;
    a = y_perflow';
    
    h_figure = figure;
    %hold on;
    
    %plot(x, y, '--d', 'LineWidth', 2)
    
    y = y_axis_flowTableSize;
    a = [a, y(1,:)'];
    
    %{
    plot(x, y(2,:), '--o', 'LineWidth', 2)
    plot(x, y(3,:), '-.x', 'LineWidth', 2)
    plot(x, y(4,:), ':v', 'LineWidth', 2)
    plot(x, y(1,:), '-s', 'LineWidth', 2)
    %}
    b = bar(x, a);
    b(2).FaceColor = 'y';
    
    hold on;
    
    yneg = y(1,:) - y(3,:);
    ypos = y(2,:) - y(1,:);
    
    %width = b(2).BarWidth/2 + b(2).XOffset;
    width = 0.15;
    %errorbar(x + width, y(1,:), yneg, ypos, 'LineWidth', 2, 'LineStyle', 'none')
    
    labels = {};
    for i = 1:length(y_perflow)
        percentage = (1-(y(1,i)/y_perflow(i))) * 100;
        
        labels = [labels, [num2str(round(percentage)), '%']];
    end

    hold off;
    
    hl = legend('per-flow', 'cluster-based', 'Location', 'NorthEast');
    %pos = get(hl, 'position');
    %set(hl, 'position', [pos(1)+0.001 pos(2)+0.08 pos(3) pos(4)]);
    
    legend boxoff;
    
    xlabel(x_label)
    ylabel('Number of Flow Rules');
    
    set(gca, 'XTick', x);
    xticklabels({num2str(x_axis(1)), num2str(x_axis(2)), num2str(x_axis(3))})
    
    %xlim([x(1) x(end)]);
    ylim([0 250]);
    
    set(h_figure, 'PaperPositionMode', 'manual');
    set(h_figure, 'PaperUnits', 'inches');
    set(h_figure, 'Units', 'inches');
    set(h_figure, 'PaperPosition', [0, 0, 4.5, 3]); % control eps size
    set(h_figure, 'Position', [0, 0, 4.5, 3]); 
    print(h_figure, '-depsc', 'netScale_flowTableSize_fatTree.eps');
end
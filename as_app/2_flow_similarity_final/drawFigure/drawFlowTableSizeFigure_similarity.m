function drawFlowTableSizeFigure_similarity(x_axis, y_axis_flowTableSize, i, x_label, x_axis_similarity)
    x = x_axis;
    y = y_axis_flowTableSize;
    
    h_figure = figure;
    
    legend_words = {};
    marker = {'--o', '-.x', ':v', '-s', '--d'};
    for j = size(y, 1):-1:1
        plot(x, mean(y{j}, 1), marker{j}, 'LineWidth', 2)
        legend_words = [legend_words; ['x = ', num2str(x_axis_similarity(j))]];
        
        hold on
    end
    
    hold off
    
    hl = legend(legend_words, 'Location', 'NorthWest');
    %pos = get(hl, 'position');
    %set(hl, 'position', [pos(1)+0.001 pos(2)+0.08 pos(3) pos(4)]);
    
    legend boxoff;
    box off;
    
    xlabel(x_label)
    ylabel('Number of Flow Rules');

    set(gca, 'XTick', x);
    
    xlim([x(1) x(end)]);
    ylim([0 250]);

    set(h_figure, 'PaperPositionMode', 'manual');
    set(h_figure, 'PaperUnits', 'inches');
    set(h_figure, 'Units', 'inches');
    set(h_figure, 'PaperPosition', [0, 0, 4.5, 3]); % control eps size
    set(h_figure, 'Position', [0, 0, 4.5, 3]); 
    print(h_figure, '-depsc', 'similarity_flowTableSize_as.eps');
end
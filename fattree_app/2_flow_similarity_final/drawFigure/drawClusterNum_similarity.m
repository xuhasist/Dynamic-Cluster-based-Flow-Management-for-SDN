function drawClusterNum_similarity(allRound_y_axis_clusterNum, x_axis_similarity)
    y = allRound_y_axis_clusterNum;
    
    h_figure = figure;
    
    legend_words = {};
    %marker = {'-', '-.', ':', '-.', '-'};
    marker = {'o', 'x', 'v', 's', 'd'};
    for j = size(y, 1):-1:1
        x_temp = mean(y{j}, 1);
        h(j) = plot((1:1:120), x_temp(1:1:end), marker{j});
        legend_words = [legend_words; ['x = ', num2str(x_axis_similarity(j))]];
        
        hold on
    end
    
    hl = legend(legend_words, 'Location', 'NorthEast');
    %pos = get(hl, 'position');
    %set(hl, 'position', [pos(1)+0.001 pos(2)+0.08 pos(3) pos(4)]);
    
    legend boxoff;
    box off;
    
    xlabel('Seconds')
    ylabel('Number of Clusters')

    set(gca, 'XTick', (0:20:120));
    set(h, 'MarkerSize', 3);
    %set(h(4), 'MarkerSize', 3);
    %set(h(3), 'Color', [0.4940 0.1840 0.5560]);
    %set(h(2), 'Color', 'g');
    %set(h(1), 'Color', [0.3010 0.7450 0.9330]);
    
    xlim([1 120]);
    ylim([0 400]);

    set(h_figure, 'PaperPositionMode', 'manual');
    set(h_figure, 'PaperUnits', 'inches');
    set(h_figure, 'Units', 'inches');
    set(h_figure, 'PaperPosition', [0, 0, 4.5, 3]); % control eps size
    set(h_figure, 'Position', [0, 0, 4.5, 3]); 
    print(h_figure, '-depsc', 'similarity_clusterNumber_fatTree.eps');
end
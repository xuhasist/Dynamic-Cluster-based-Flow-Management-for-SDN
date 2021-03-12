function drawCdf_fixedPrefix(x_axis, allRound_y_axis_cdf)
    x = x_axis;
    
    h_figure = figure;

    legend_words = {};
    for i = 1:length(x)
        y = mean(allRound_y_axis_cdf{i}, 1);
        h(i) = cdfplot(y);
        legend_words = [legend_words; ['PL = ', num2str(x_axis(i))]];

        hold on
    end

    hold off

    %set(h, 'LineWidth', 2);
    
    %NameArray = {'LineStyle'};
    %ValueArray = {'-','-.','--',':'}';
    %set(h(1:4), NameArray, ValueArray);
    
    NameArray = {'Marker'};
    %ValueArray = {'x','.'}';
    ValueArray = {'o', 'v', 'x', 's', 'd'}';
    set(h(2:6), NameArray, ValueArray);
    set(h(2:6), 'MarkerSize', 3);
    set(h(4), 'MarkerSize', 5);
    
    hl = legend(legend_words, 'Location', 'SouthEast');
    %pos = get(hl, 'position');
    %set(hl, 'position', [pos(1)+0.001 pos(2)+0.08 pos(3) pos(4)]);
    
    legend boxoff;
    
    title('');
    box off;
    grid off;
    
    xlabel('Number of Flow Rules')
    ylabel ('CDFs');
    xlim([0 500]);
    
    set(h_figure, 'PaperPositionMode', 'manual');
    set(h_figure, 'PaperUnits', 'inches');
    set(h_figure, 'Units', 'inches');
    set(h_figure, 'PaperPosition', [0, 0, 4.5, 3]); % control eps size
    set(h_figure, 'Position', [0, 0, 4.5, 3]); 

    print(h_figure, '-depsc', 'static_cdf_as.eps');
end
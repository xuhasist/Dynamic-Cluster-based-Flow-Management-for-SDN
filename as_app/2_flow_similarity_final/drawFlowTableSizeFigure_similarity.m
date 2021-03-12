function drawFlowTableSizeFigure_similarity(x_axis, y_axis_flowTableSize, i, frequency, x_label, x_axis_similarity)
    x = x_axis;
    y = y_axis_flowTableSize;
    
    legend_words = {};
    for j = 1:size(y, 1)
        plot(x, mean(y{j}, 1), 'Marker', 's')
        legend_words = [legend_words; ['Similarity = ', num2str(x_axis_similarity(j))]];
        
        hold on
    end
    
    hold off
    
    legend(legend_words, 'Location', 'southeast')
    
    xlabel(x_label)
    ylabel('Average Number of Flow Rules')

    xticks(x)
    
    print(['figure/flowTableSize/flowTableSizeFigure_', int2str(frequency), '_', int2str(i)], '-dpng')
end
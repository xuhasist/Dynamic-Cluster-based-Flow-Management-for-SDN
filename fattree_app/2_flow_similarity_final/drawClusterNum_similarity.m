function drawClusterNum_similarity(allRound_y_axis_clusterNum, frequency, x_axis_similarity)
    y = allRound_y_axis_clusterNum;
    
    legend_words = {};
    for j = 1:size(y, 1)
        plot(mean(y{j}, 1))
        legend_words = [legend_words; ['Similarity = ', num2str(x_axis_similarity(j))]];
        
        hold on
    end
    
    hold off

    legend(legend_words, 'Location', 'south')
    
    xlabel('Seconds')
    ylabel('Number of Clusters')

    xlim([1 360])

    print(['figure/clusterNum_similarity/clusterNum_similarity_', int2str(frequency)], '-dpng')
end
function drawCdf_fixedPrefix(x_axis, allRound_y_axis_cdf, frequency)
    x = x_axis;

    legend_words = {};
    for i = 1:length(x)
        y = mean(allRound_y_axis_cdf{i}, 1);
        h(i) = cdfplot(y);
        legend_words = [legend_words; ['PL = ', num2str(x_axis(i))]];

        hold on
    end

    hold off

    set(h(8:end), 'LineStyle', '--');
    legend(legend_words, 'Location', 'southeast')
    
    xlabel('Number of Flow Rules')
    
    print(['figure/cdf/cdf_', int2str(frequency)], '-dpng')
end
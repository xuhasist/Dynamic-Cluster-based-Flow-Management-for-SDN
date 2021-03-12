function drawNetworkThroughputFigure_changeNetworkScale_as(x_axis, y_axis_networkThroughput, y_axis_networkThroughput_perFlow, frequency, x_label, swNumInEachAs)
    x = x_axis;
    y = y_axis_networkThroughput;
    y = y/(10^3);

    plot(x, y, 'Marker', 's')
    
    hold on
    
    y = y_axis_networkThroughput_perFlow;
    y = y/(10^3);
    
    plot(x, y, '--', 'Marker', 'o')
    
    hold off
    
    legend('clustering', 'per-flow', 'Location', 'southeast')

    xlabel(x_label)
    ylabel('Average Network Throuput (Mbps)')

    xticks(x)
    xticklabels({[num2str(x_axis(1)), '(', num2str(swNumInEachAs(1)), ')'], ...
        [num2str(x_axis(2)), '(', num2str(swNumInEachAs(2)), ')'], ...
        [num2str(x_axis(3)), '(', num2str(swNumInEachAs(3)), ')']})
    
    print(['figure/networkThroughput/networkThroughputFigure_', int2str(frequency)], '-dpng')
end
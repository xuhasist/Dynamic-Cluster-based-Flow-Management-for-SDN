function drawFlowTableSizeFigure_changeNetworkScale_as(x_axis, y_axis_flowTableSize, y_axis_flowTableSize_perFlow, i, frequency, x_label, swNumInEachAs)
    x = x_axis;
    y = y_axis_flowTableSize;
    
    plot(x, y, 'Marker', 's')
    
    hold on
    
    y = y_axis_flowTableSize_perFlow;
    
    plot(x, y, '--', 'Marker', 'o')
    
    hold off
    
    legend('clustering', 'per-flow', 'Location', 'southeast')
    
    xlabel(x_label)
    ylabel('Average Number of Flow Rules')

    xticks(x)
    xticklabels({[num2str(x_axis(1)), '(', num2str(swNumInEachAs(1)), ')'], ...
        [num2str(x_axis(2)), '(', num2str(swNumInEachAs(2)), ')'], ...
        [num2str(x_axis(3)), '(', num2str(swNumInEachAs(3)), ')']})
    
    print(['figure/flowTableSize/flowTableSizeFigure_', int2str(frequency), '_', int2str(i)], '-dpng')
end
function drawClusterSize(x_axis, y_axis_pathLength, frequency, x_label)
    x = x_axis;
    y = y_axis_pathLength;
    
    plot(x, y, 'Marker', 's')
    
    xlabel(x_label)
    ylabel('Average Size of Cluster')

    xticks(x)
    
    print(['figure/clusterSize/clusterSize_', int2str(frequency)], '-dpng')
end

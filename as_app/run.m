clearvars -except

roundNumber = 10;

cd('1_static_final')
fixedPrefixClustering(roundNumber)

cd('../2_flow_similarity_final')
fixedPrefixClustering_similarity(roundNumber)

cd('../3_table_threshold_final')
tableThresholdClustering(roundNumber)

cd('../4_num_of_edges_final')
tableThresholdClustering_changeFlowNum(roundNumber)

cd('../5_net_scale_final')
tableThresholdClustering_changeNetworkScale_as(roundNumber)

cd('../6_maxFlowTableSize_final')
maxFlowTableSize

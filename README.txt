packet trace: http://pages.cs.wisc.edu/~tbenson/IMC10_Data.html

pktTrace_3min.txt for initial clustering: 26:04:398500 ~ 29:04:397877, 1228 flows
pktTrace_5min.txt for evaluation: 32:26:775940 ~ 37:26:774441, 2316 flows

create flow trace in pcap vm:
	cd ~/Flow-Analysis/
	python extractElephantFlow_2.py univ1/univ1_pt1_pt2

	merge pcap file: mergecap -F pcap -w univ1_pt1_pt2 univ1_pt1 univ1_pt2

	python library installation:
		numpy: sudo apt-get install python-numpy
		pandas: sudo apt-get install python-pandas
	

create AS topology info in ns3 vm:
	cd ~/bake/source/ns-3.26/
	python myScript.py (store in './myTopologyInfo' directory)

	software:
		ns3 installation: https://www.nsnam.org/wiki/Installation
		BRITE usage: https://www.nsnam.org/wiki/BRITE_integration_with_ns-3
					 https://www.nsnam.org/docs/models/html/brite.html



1_static_final:
	run fixedPrefixClustering.m


	createFatTreeTopo.m:
		create fat-tree topology

	createAsTopo_random.m:
		create AS topology
			randomly select one topology from 'myTopologyInfo' directory

	setVariables.m:
		initial some network info structure
		preprocessing for initial clustering

	initialClustering_static.m:
		do initial clustering
			do k-means under each edge switch

	setNewFlows.m:
		randomly select 5000 flows from flow traces for evaluation

	staticMerging.m:
		merge clusters with the same IP prefix length
		assign vlan to cluster with IP prefix conflicting

	clusterNewFlow.m:
		process new flows
			match current cluster (with the same prefix)
			create a individual cluster

	setFlowInfo.m:
		Preliminary flow entry settings

	findRendezvousSw.m:
		find rendezvous switches for merged clusters
			step1: minimum total length between ingress (egress) rendezvous switch and source (destinaiton) switch
			step2: maximum total throughput between ingress (egress) rendezvous switch and source (destinaiton) switch

	setFlowEntry.m:
		set src/dst IP of flow entry

	processPkt.m:
		process packet
			find least congested shortest path
			install flow rules

	firstFitFlowScheduling.m:
		return least congested shortest path

	updateLinkStruct.m:
		update link throughput for 
			network throughput calculation 
			least congested shortest path lookup

	calculateFlowTableSize.m:
		calculate the average table size of the over x-th percentile switches


	draw figures:
		run drawFigure/main.m



2_flow_similarity_final:
	run fixedPrefixClustering_similarity.m


	setVariables_similarity.m:
		initial some network info structure
		＊randomly select 5000 flows for initial clustering and evaluation

	initialClustering_similarity.m:
		do initial clustering
			＊record the distance between the binary sequence and the centroid
			do k-means under each edge switch

	computeSimilarity.m:
		Sample the most similar x flows from 5,000 flows
		Replicate x flows to 5,000 flows


	draw figures:
		run drawFigure/main.m



3_table_threshold_final:
	run tableThresholdClustering.m


	perFlowClustering.m:
		do per-flow simulation
		each flow will occupy one flow rule in the switch table

	dynamicMerging.m:
		merge clusters through the overloaded switch 
			merge two smallest clusters until cluster size < table threshold

	removeAllFlowEntry.m:
		remove all flow entry in all switches

	calculateClusterSizeAndNumber.m:
		calculate size and number of clusters after dynamic merging

	calculateNetworkThrouput.m:
		calculate average network throughput per-minute


	draw figures:
		run drawFigure/main.m



4_num_of_edges_final:
	run tableThresholdClustering_changeEdgeSwNum.m

	draw figures:
		run drawFigure/main.m



5_net_scale_final:
	fat-tree:
		run tableThresholdClustering_changeNetworkScale_fattree.m

	as:
		run tableThresholdClustering_changeNetworkScale_as

	draw figures:
		run drawFigure/main.m



6_maxFlowTableSize_final:
	run maxFlowTableSize.m


	calculate_max_tableSize.m:
		calculate the max table size per second


	draw figures:
		run drawFigure.m



Important Variables:
	allSwTableSize_list: record the flow table size of all switches when the flow table size changes
	doHierarchyCount: number of merging
	eachFlowFinalPath: path of all flows
	flowSequence: binary sequence of all flows
	flowTraceTable: 5mins flows info for evaluation
	initialClusterTable: 3mins flow info after initial clustering
	linkThputStruct: throughput of all links
	swDistanceVector: distance between any two switch
	swFlowEntryStruct: flow rule info of all switches
	swInfTable: switch, interface, link info







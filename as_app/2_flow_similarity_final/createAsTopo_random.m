function [swNum, srcNode, dstNode, srcInf, dstInf, g, asNum, nodeTable, hostNum, IP] = ...
    createAsTopo_random(eachAsEdgeSwNum, hostAvg, hostSd)

    allFile = dir('myTopologyInfo');

    allFile = {allFile.name};
    rows = contains(allFile, 'myTopo');
    allFile = allFile(rows);
    
    pickTopoFileIndex = randi(length(allFile));
    
    topoInfo = textread(['myTopologyInfo/', allFile{pickTopoFileIndex}], '%s', 'delimiter', '\n');
        
    token = strsplit(topoInfo{1}, ' ');
    swNum = str2double(token{3});

    token = strsplit(topoInfo{2}, ' ');
    edgeNum = str2double(token{3});

    nodeCount = zeros(swNum);
    nodeName = {};

    for i = 1:swNum
        nodeName{i} = strcat('sw-', int2str(i));
    end

    g = graph(nodeCount, nodeName);
    
    as = [];
    type = {};
    for i = 4:4+(swNum-1)
        token = strsplit(topoInfo{i}, ' ');

        as = [as; str2double(token{2})+1];
        type = [type; 'RT_NODE'];
    end
    
    nodeTable = table(nodeName(1:swNum)', as, type);
    nodeTable.Properties.VariableNames = {'Node', 'AS', 'Type'};

    srcNode = {};
    dstNode = {};
    srcInf = [];
    dstInf = [];

    if_temp = ones(1,swNum);
    for i = 2+(swNum+3):2+(swNum+3)+(edgeNum-1)
        token = strsplit(topoInfo{i}, ' ');

        node1 = str2double(token{1})+1;
        node2 = str2double(token{2})+1;

        g = addedge(g, node1, node2, 10);

        srcNode = [srcNode; strcat('sw-', int2str(node1))];
        dstNode = [dstNode; strcat('sw-', int2str(node2))];
        srcInf = [srcInf; if_temp(node1)];
        dstInf = [dstInf; if_temp(node2)];

        srcNode = [srcNode; strcat('sw-', int2str(node2))];
        dstNode = [dstNode; strcat('sw-', int2str(node1))];
        srcInf = [srcInf; if_temp(node2)];
        dstInf = [dstInf; if_temp(node1)];

        if_temp(node1) = if_temp(node1) + 1;
        if_temp(node2) = if_temp(node2) + 1;
        
        if ~strcmp(token{3}, token{4})
            rows = strcmp(nodeTable.Node, strcat('sw-', int2str(node1))) | strcmp(nodeTable.Node, strcat('sw-', int2str(node2)));
            nodeTable.Type(rows) = {'RT_BORDER'};
        end
    end

    asNum = length(unique(nodeTable.AS));
    hostRange = [hostAvg-hostSd, hostAvg+hostSd];
        
    edgeSwNode = [];
    IP = {};
    edgeSwOrder = [];
    for i = 1:asNum
        rows = (nodeTable.AS == i) & strcmp(nodeTable.Type, 'RT_NODE');
        edgeSw = find(rows);
        edgeSw = edgeSw(randperm(numel(edgeSw), eachAsEdgeSwNum));
        edgeSwOrder = [edgeSwOrder, edgeSw'];
        
        hostAtSw(edgeSw) = randi(hostRange, eachAsEdgeSwNum, 1);
        
        edgeSwNode = [edgeSwNode, edgeSw'];
                
        ipSet = (randperm(32, eachAsEdgeSwNum)-1) + (32*(i-1));
        
        for j = 1:length(edgeSw)
            a = randperm(254, hostAtSw(edgeSw(j)));

            IP = [IP, cellstr(strcat('140.', '113.', int2str(ipSet(j)), '.', int2str(a')))'];
        end
    end
    
    hostNum = sum(hostAtSw);
    
    for i = 1:hostNum
        hostName{i} = strcat('h-', int2str(i));
    end
    
    g = addnode(g, hostName);
    
    host_c = 1;
    for i = 1:length(edgeSwOrder)
        for n = host_c:(host_c + hostAtSw(edgeSwOrder(i))) - 1            
            g = addedge(g, strcat('sw-', int2str(edgeSwOrder(i))), strcat('h-', int2str(n)), 10);  

            srcNode = [srcNode; strcat('sw-', int2str(edgeSwOrder(i)))];
            dstNode = [dstNode; strcat('h-', int2str(n))];
            srcInf = [srcInf; if_temp(edgeSwOrder(i))];
            dstInf = [dstInf; 1];

            srcNode = [srcNode; strcat('h-', int2str(n))];
            dstNode = [dstNode; strcat('sw-', int2str(edgeSwOrder(i)))];
            srcInf = [srcInf; 1];
            dstInf = [dstInf; if_temp(edgeSwOrder(i))];

            if_temp(edgeSwOrder(i)) = if_temp(edgeSwOrder(i)) + 1;
        end

        host_c = host_c + hostAtSw(edgeSwOrder(i));
    end
    
    for i = 1:length(edgeSwNode)
        g.Nodes.Name{edgeSwNode(i)} = ['ed-', int2str(i)];
        nodeTable.Node{edgeSwNode(i)} = ['ed-', int2str(i)];

        rows = strcmp(srcNode, nodeName{edgeSwNode(i)});
        srcNode(rows) = {['ed-', int2str(i)]};

        rows = strcmp(dstNode, nodeName{edgeSwNode(i)});
        dstNode(rows) = {['ed-', int2str(i)]};
    end
end
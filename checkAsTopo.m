clearvars
    
eachAsEdgeSwNum = 2;
dirName = 'myTopologyInfo_4_degree/';

allFile = dir(dirName);

allFile = {allFile.name};
rows = contains(allFile, 'myTopo');
allFile = allFile(rows);

for i = 1:length(allFile)
    topoInfo = textread([dirName, allFile{i}], '%s', 'delimiter', '\n');

    token = strsplit(topoInfo{1}, ' ');
    swNum = str2double(token{3});

    token = strsplit(topoInfo{2}, ' ');
    edgeNum = str2double(token{3});

    as = [];
    type = {};
    for j = 4:4+(swNum-1)
        token = strsplit(topoInfo{j}, ' ');

        as = [as; str2double(token{2})+1];
        type = [type; 'RT_NODE'];
    end

    nodeTable = table((1:swNum)', as, type);
    nodeTable.Properties.VariableNames = {'Node', 'AS', 'Type'};

    for j = 2+(swNum+3):2+(swNum+3)+(edgeNum-1)
        token = strsplit(topoInfo{j}, ' ');

        node1 = str2double(token{1})+1;
        node2 = str2double(token{2})+1;

        if ~strcmp(token{3}, token{4})
            rows = (nodeTable.Node == node1 | nodeTable.Node == node2);
            nodeTable.Type(rows) = {'RT_BORDER'};
        end
    end

    asNum = length(unique(nodeTable.AS));

    for j = 1:asNum
        rows = (nodeTable.AS == j) & strcmp(nodeTable.Type, 'RT_NODE');
        edgeSw = find(rows);

        if length(edgeSw) < eachAsEdgeSwNum
            delete([dirName, allFile{i}])
            break;
        end
    end
end
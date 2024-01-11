function [G,G_j, Release_planned] = createGraphFromDataset(datasetFile)
    % Funzione per leggere un file excel contenente le informazioni sui job
    % e costruire le variabili necessarie: G, G_j, Release_planned, etc..
    % Il File excel deve essere fatto così: Colonna 1 Job ID, Colonna 2
    % Sequenza di operazioni tra parentesi graffe, separate dalla virgola
    % tra un'operazione e l'altra e separate da uno spazio per indicare le
    % diverse macchine che possono svolgere l'operazione, Colonna 3 il
    % tempo di release pianificato, Colonna 4 la due date
    G = [];
    G_j = [];
    dataTable = readtable(datasetFile, 'ReadVariableNames', false);
    jobId = dataTable(:,1);
    operations = dataTable(:,2);
    Release_planned = table2array(dataTable(:,3));
    row = 1;
    for i = 1:length(operations{:,1}) % loop through each row
        % Extract the sequence of numbers inside the parenthesis
        numbersCell = regexp(operations{i,:}{1}, '\{([^}]*)\}', 'tokens');
        
        % Remove ' '
        numbersCell = cellfun(@(x) strrep(x{1}, '''', ''), numbersCell, 'UniformOutput', false);
        
        % Find all possible paths for the job
        allPaths = generatePaths(numbersCell, 1, []);
        % Update the flow-shop graph and its auxiliary graph
        for j=1:length(allPaths)
            for k=1:length(allPaths{j})
               G(row,k) = allPaths{j}(k);
            end
        G_j(row) = i;
        row = row + 1;
        end  
    end
end 
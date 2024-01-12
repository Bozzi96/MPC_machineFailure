function [G,G_j, Release_planned] = createGraphFromDataset(datasetFile)
% Function to read an Excel file containing information about jobs
% and construct the necessary variables: G, G_j, Release_planned, etc.
% The Excel file should be structured as follows: Column 1 for Job ID,
% Column 2 for the sequence of operations within curly braces, separated
% by commas and spaces to indicate different machines for each operation,
% Column 3 for the planned release time, and Column 4 for the due date.
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
        
        % Remove the quotes ''
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
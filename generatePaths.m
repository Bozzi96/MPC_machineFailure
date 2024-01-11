function allPaths = generatePaths(operations, currentIndex, currentPath)
    allPaths = {};
    
    % Se siamo all'ultimo elemento, aggiungi il percorso corrente alla lista
    if currentIndex == numel(operations)
        numbersCell = regexp(operations{currentIndex}, '\d+', 'match');
        numbers = cellfun(@str2num, numbersCell);
        
        for i = 1:numel(numbers)
            allPaths{end+1} = [currentPath, numbers(i)];
        end
    else
        % Altrimenti, per ogni numero nella cella corrente, richiama ricorsivamente la funzione
        numbersCell = regexp(operations{currentIndex}, '\d+', 'match');
        numbers = cellfun(@str2num, numbersCell);
        
        for i = 1:numel(numbers)
            recursivePaths = generatePaths(operations, currentIndex + 1, [currentPath, numbers(i)]);
            allPaths = [allPaths, recursivePaths];
        end
    end
end
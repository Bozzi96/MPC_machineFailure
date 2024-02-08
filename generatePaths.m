function allPaths = generatePaths(operations, currentIndex, currentPath)
    allPaths = {};
    
    % If it is the last element, add the current path to the list
    if currentIndex == numel(operations)
        numbersCell = regexp(operations{currentIndex}, '\d+', 'match');
        numbers = cellfun(@str2num, numbersCell);
        
        for i = 1:numel(numbers)
            allPaths{end+1} = [currentPath, numbers(i)];
        end
    else
        % Otherwise, for each number in the current cell, call the function
        % recursively
        numbersCell = regexp(operations{currentIndex}, '\d+', 'match');
        numbers = cellfun(@str2num, numbersCell);
        
        for i = 1:numel(numbers)
            recursivePaths = generatePaths(operations, currentIndex + 1, [currentPath, numbers(i)]);
            allPaths = [allPaths, recursivePaths];
        end
    end
end
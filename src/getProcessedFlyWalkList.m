function FileExist = getProcessedFlyWalkList(pathlist)
% returns a logical list for the given pathlist. If the file is processed
% and save d as an flywalk object returns 1, otherwise returns 0.

FileExist = zeros(size(pathlist));

for i = 1:numel(pathlist)
    if exist([pathlist{i}(1:end-4),'.flywalk'],'file')
        FileExist(i) = 1;
    end
end

FileExist = logical(FileExist);
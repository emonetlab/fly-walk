function pathlist = win2Unix(pathlist)
% converts the path list compatible to unix

% is a cell array of paths or a single path given
if iscell(pathlist)
    fullpath = cell(size(pathlist)); % initiate output cell array
else
    pathlist ={pathlist};
    fullpath = cell(size(pathlist));
end


for k = 1:length(pathlist)
    fp = strsplit(pathlist{k},filesep);
    fullpath(k) = {strjoin(fp,'/')};
end

if ~iscell(pathlist)
    fullpath = char(fullpath);
end

pathlist = fullpath;
function pathlist = Unix2Win(pathlist)
% converts the unix path list compatible to windows

% is a cell array of paths or a single path given
if iscell(pathlist)
    fullpath = cell(size(pathlist)); % initiate output cell array
else
    pathlist ={pathlist};
    fullpath = cell(size(pathlist));
end


for k = 1:length(pathlist)
    fp = strsplit(pathlist{k},'/');
    fullpath(k) = {strjoin(fp,filesep)};
end

if ~iscell(pathlist)
    fullpath = char(fullpath);
end

pathlist = fullpath;
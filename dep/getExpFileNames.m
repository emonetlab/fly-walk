function expFileNames = getExpFileNames(savePathList)
%getExpFileNames
% expFileNames = getExpFileNames(savePathList)
% finds and loads the experimental file names in the current directory. If
% there is not a pre-saved file, searches for video files with
% '-frames.mat' extension and returns the list of the file names. Saves
% that list as the 'expmat.names.nat' with a variable name 'pathlist'.
%
if nargin==0
    savePathList = 1;
end
if exist('expmat.names.mat','file')
    expFileNames = load('expmat.names.mat');
    expFileNames = expFileNames.pathlist;
elseif exist('expvid.names.mat','file')
    expFileNames = load('expvid.names.mat');
    expFileNames = expFileNames.expvidnames;
else % try to contruct yourself from frames files
    filesearch=dir('*frames.mat'); % search video files
    filenames={filesearch.name}'; % get file names
    % if there are files go over them and construct exp mat names
    if isempty(filenames)
        disp(' there are no files containing frames')
        expFileNames = [];
    else
        pathlist =  cell(size(filenames));
        for i = 1:numel(filenames)
            pathlist(i) = {[filenames{i}(1:end-11),'.mat']};
        end
        if savePathList
            save('expmat.names.mat','pathlist')
        end
        expFileNames = pathlist;
    end
end

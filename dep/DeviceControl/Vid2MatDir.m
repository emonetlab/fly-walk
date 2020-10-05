function Vid2MatDir(pathstr)

% finds all videos (avi and mj2) in given directory and creates mat files
% containing frames

switch nargin
    case 1
    case 0
        pathstr = pwd;
end

% check if there is vidnameslist or work on all videos
if exist([pathstr,filesep,'expvid.names.mat'],'file')
    load([pathstr,filesep,'expvid.names.mat']);
    fileNames = expvidnames;
else
    filelist = dir([pathstr,filesep,'*.avi']);
    fileNames1 = {filelist.name}';
    filelist = dir([pathstr,filesep,'*.mj2']);
    fileNames = [fileNames1;{filelist.name}'];
end

%% check handling files
cntr = 1;
thesefiles = [];
for i = 1:length(fileNames)
    if ~exist([pathstr,filesep,fileNames{i}(1:end-4),'.mat'],'file')
        thesefiles(cntr).name = fileNames{i};
        cntr = cntr + 1;
    end
end

%% extract and save the metadata text file if not saved
if ~exist('metaData.txt','file')
    saveMetaDataTextFile(fileNames);
else
    disp('metaData.txt seems to be already saved')
end

%% check handling file, if does not exist call handling function
if ~isempty(thesefiles)
    disp('Handling video is not found. Execution will end.')
    disp('Re-run the code after handling.')
    HandleFlyWalkVideo(pathstr,thesefiles)
else
    for i = 1:length(fileNames)
        Vid2Mat([pathstr,filesep,fileNames{i}])
    end
end



% copies all the files necessary to run fly-walk from the cluster data
% transfer folder F:\Data2Transfer.
%   Usage:
%   status = copyFilestoOrigin(pathlistFile_cluster,archiveOldFiles)
%   pathlistFile_cluster: filename containing the clusters paths
%   archiveOldFiles: 1> archive previous flywalk files. 0> overwrite
%
function status = copyFilestoOrigin(pathlistFile_cluster,archiveOldFiles)

switch nargin
    case 1
        archiveOldFiles = false;
end

% load the cluster pathlist
assert(logical(exist(pathlistFile_cluster,'file')),[pathlistFile_cluster,' does not exist'])
assert(logical(exist([pathlistFile_cluster(1:end-12),'_origin.mat'],'file')),[pathlistFile_cluster(1:end-12),'_origin.mat does not exist'])

% load these pathlists
% load the new path list file
npl = load(pathlistFile_cluster,'new_pathlist');
npl = npl.new_pathlist;
% save the origin pathlist
pl = load([pathlistFile_cluster(1:end-12),'_origin.mat'],'fullpath');
pl = pl.fullpath;

if archiveOldFiles
    renameFlyWalk_Files(pl); % archive old flywalk files by renaming with an index
end

status = false(numel(pl),1);

for i = 1:numel(pl)
    disp(npl{i})
    try
        copyfile([npl{i}(1:end-4),'.flywalk'],[pl{i}(1:end-4),'.flywalk'])
        disp(['copied ', [npl{i}(1:end-4),'.flywalk'], ' to origin']);
        %         % copy other files
        %         copyfile(npl{i},pl{i}); % experimental parameter file
        %         copyfile([npl{i}(1:end-4),'-frames.mat'],[npl{i}(1:end-4),'-frames.mat']); % video file
        %         disp('copied the video and parameter file');
        status(i) = true;
    catch ME
        disp('error!')
        disp(ME.message);
    end
end


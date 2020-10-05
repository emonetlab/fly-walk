% copies all the files necessary to run fly-walk in to the cluster data
% transfer folder F:\Data2Transfer
function [new_pathlist,fullpath,status] = copyFilestoData2Transfer(pathlist,pathlist_save_name,subfolder,copy_ext,destfolder)

switch nargin
    case 4
        destfolder = 'F:\Data2Transfer';
    case 3
        copy_ext = '*'; % copy all files
    case 2
        copy_ext = '*'; % copy all files
        subfolder = []; % in Data2Transfer, no subfolder
    case 1
        copy_ext = '*'; % copy all files
        subfolder = []; % in Data2Transfer, no subfolder
        pathlist_save_name = []; % do not save it
end


status = false(numel(pathlist),1);
new_pathlist = cell(size(pathlist));
dest_fldr_origin = destfolder;
if isempty(subfolder)
    dest_fldr = dest_fldr_origin;
else
    dest_fldr = [dest_fldr_origin,filesep,subfolder];
    if ~exist(dest_fldr,'dir')
        mkdir(dest_fldr)
    end
end

for i = 1:numel(pathlist)
    disp(pathlist{i})
    [~,nm,ext]=fileparts(pathlist{i});
    if isempty(subfolder)
        new_pathlist(i) = {[nm,ext]};
    else
        new_pathlist(i) = {[subfolder,filesep,nm,ext]};
    end
    try
        if strcmp(copy_ext,'*')
            if exist([pathlist{i}(1:end-4),'.flywalk'],'file')
                disp('there is a saved file');
                % move all thre files into the transfer folder
                % first check if that is already copied
                if exist([dest_fldr,filesep,nm,'.flywalk'],'file')
                    disp('FlyWalk file exists in the destination folder. Check the file size...');
                else
                    copyfile([pathlist{i}(1:end-4),'.flywalk'],[dest_fldr,filesep,nm,'.flywalk'])
                    disp('copied existing flywalk file');
                end
            end
            % copy other files
            if exist([dest_fldr,filesep,nm,ext],'file')
                disp('Experimental Parameter file exists in the destination folder. Check the file size...');
            else
                copyfile(pathlist{i},[dest_fldr,filesep,nm,ext]); % experimental parameter file
                disp('copied the experimental parameer file')
            end
            if exist([dest_fldr,filesep,nm,'-frames.mat'],'file')
                disp('Video file exists in the destination folder. Check the file size...');
            else
                copyfile([pathlist{i}(1:end-4),'-frames.mat'],[dest_fldr,filesep,nm,'-frames.mat']); % video file
                disp('copied the video file');
            end
        elseif any([strcmp(copy_ext,'flywalk'),strcmp(copy_ext,'.flywalk'),strcmp(copy_ext,'flyWalk'),strcmp(copy_ext,'.flyWalk')])
            if exist([pathlist{i}(1:end-4),'.flywalk'],'file')
                disp('there is a saved file');
                % move all thre files into the transfer folder
                % first check if that is already copied
                if exist([dest_fldr,filesep,nm,'.flywalk'],'file')
                    disp('FlyWalk file exists in the destination folder. Check the file size...');
                else
                    copyfile([pathlist{i}(1:end-4),'.flywalk'],[dest_fldr,filesep,nm,'.flywalk'])
                    disp('copied existing flywalk file');
                end
            end
        elseif any([strcmp(copy_ext,'mat'),strcmp(copy_ext,'.mat')])
            if exist([dest_fldr,filesep,nm,ext],'file')
                disp('Experimental Parameter file exists in the destination folder. Check the file size...');
            else
                copyfile(pathlist{i},[dest_fldr,filesep,nm,ext]); % experimental parameter file
                disp('copied the experimental parameer file')
            end
        elseif any([strcmp(copy_ext,'frames'),strcmp(copy_ext,'-frames.mat'),strcmp(copy_ext,'frames.mat')])
            if exist([dest_fldr,filesep,nm,'-frames.mat'],'file')
                disp('Video file exists in the destination folder. Check the file size...');
            else
                copyfile([pathlist{i}(1:end-4),'-frames.mat'],[dest_fldr,filesep,nm,'-frames.mat']); % video file
                disp('copied the video file');
            end
        end
        
        status(i) = true;
    catch ME
        disp('error!')
        disp(ME.message);
    end
end

if any(status)
    disp('Finished copying files')
    disp([num2str(sum(status)),'/',num2str(numel(pathlist)),' files were copied to Data2Transfer'])
    disp('here is the list of the copied files')
    pathlist(status)
else
    disp('None of the files are copied')
end

% convert paths to unix
new_pathlist = win2Unix(new_pathlist);

if ~isempty(pathlist_save_name)
    % save the new path list file
    save([dest_fldr_origin,filesep,pathlist_save_name,'_cluster.mat'],'new_pathlist')
end
% save the origin pathlist
fullpath = getFullPath(pathlist); %get full path list
% convert paths to unix
fullpath = win2Unix(fullpath);
if ~isempty(pathlist_save_name)
    save([dest_fldr_origin,filesep,pathlist_save_name,'_origin.mat'],'fullpath')
end


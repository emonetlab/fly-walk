function Vid2Mat(pathname)

% loads the video and saves in mat file without cropping along with the
% background image

%% check handling file, if does not exist call handling function
if ~exist([pathname(1:end-4),'.mat'],'file')
    disp('Handling video is not found. Execution will end.')
    disp('Re-run the code after handling.')
    [path_name,fname,ext] = fileparts(pathname);
    thesefiles(1).name = [fname,ext];
    HandleFlyWalkVideo(path_name,thesefiles)
else

    % first check if the file exist
    if exist([pathname(1:end-4),'-frames.mat'],'file')
        %% load the video if not already saved  
        if isempty(who('frames','-file',[pathname(1:end-4),'-frames.mat']))
            % load the video and save as mat file without cropping
            [~] = ImpVidMatCropSave(pathname);
            disp([pathname,' is done'])
        else
            disp([pathname(1:end-4),'-frames.mat already has frames'])
        end
    else
         % load the video and save as mat file without cropping
        [~] = ImpVidMatCropSave(pathname);
        disp([pathname,' is done'])
        disp('------------------------------------------------------------------------------------')
    end
end
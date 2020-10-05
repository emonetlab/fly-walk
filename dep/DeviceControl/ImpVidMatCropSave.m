function [p,frames] = ImpVidMatCropSave(vid_name,appendtomatfile,crop)
%function [p,frames] = ImpVidMatCropSave(vid_name,appendtomatfile,crop)
%   imports the given video, crops it according to the parameters saved
%   with the same name (.mat) as an output of function HandleFlyWalkVideo
%   and appends the croppes frames matrix in the same mat file. Tries to
%   load the background file, crop and average it. The background image
%   will be saved in the parameter space p. If the background file does not
%   exist it will average first half seconds of the orginal video.

switch nargin
    case 3
    case 2
        crop = 0;   % do not crop
    case 1
        crop = 0;   % do not crop
        appendtomatfile = 1; % by default save it
    case 0
        help ImpVidMatCropSave
        error('gimme a video')
end

% load the video
disp(['Loading ',vid_name])
[~,frames,flag] = ImportVidMat(vid_name);
if isempty(flag)
    disp([vid_name,' is loaded'])
    moviefile = vid_name;
elseif flag.mj2
    disp([vid_name,' is saved in -frames.mat file'])
    moviefile = vid_name;
end


%% load parameters and filename
% m=matfile([vidobj.path, oss, strcat(vid_name(1:end-3),'mat')]);
m=matfile([strcat(vid_name(1:end-3)),'mat']);
p = m.p;

%% get background image
% bkg_img = GetBkgImg(frames,moviefile,p);
bkg_img = GetBkgImg(frames,vid_name,p);

if isempty(flag)
    %% crop and update frames
    if crop
        [frames,p] = CropFrames(frames,p);
        [bkg_img,p] = CropFrames(bkg_img,p);
    end
end

%% set background image in p
p.bkg_img = bkg_img;

%% save
if isempty(flag) % this is the case for avi movies
    if appendtomatfile==1
        disp(['Saving frames to ',strcat(vid_name(1:end-4),'-frames.mat')])
        SaveFastApp(strcat(vid_name(1:end-4),'-frames.mat'),'frames')
        % check file
        if exist(strcat(vid_name(1:end-3),'mat'),'file')
            save(strcat(vid_name(1:end-3),'mat'),'p','moviefile','-append');
        else
            save(strcat(vid_name(1:end-3),'mat'),'p','moviefile');
        end
        % check the kontroller files
        if exist(strcat(vid_name(1:end-3),'kontroller'),'file')
            ld = load(strcat(vid_name(1:end-3),'kontroller'),'-mat');
            % handle metadata variable
            ld.metadataKontroller = ld.metadata;
            ld = rmfield(ld,'metadata');
            save(strcat(vid_name(1:end-3),'mat'),'-struct','ld','-append');
        end
        % check the grasshopper files
        if exist('Grasshopper.Cam_Settings.mat','file') == 2
            Grasshopper = load('Grasshopper.Cam_Settings.mat');
            save(strcat(vid_name(1:end-3),'mat'),'Grasshopper','-append');
        end
        
        disp([strcat(vid_name(1:end-4),'-frames.mat'),' is saved'])
        disp([strcat(vid_name(1:end-3),'mat'),' is updated'])
    end
elseif flag.mj2
    % check file
    if exist(strcat(vid_name(1:end-3),'mat'),'file')
        save(strcat(vid_name(1:end-3),'mat'),'p','moviefile','-append');
    else
        save(strcat(vid_name(1:end-3),'mat'),'p','moviefile');
    end
    % check the kontroller files
    if exist(strcat(vid_name(1:end-3),'kontroller'),'file')
        ld = load(strcat(vid_name(1:end-3),'kontroller'),'-mat');
        % handle metadata variable
        ld.metadataKontroller = ld.metadata;
        ld = rmfield(ld,'metadata');
        save(strcat(vid_name(1:end-3),'mat'),'-struct','ld','-append');
    end
    % check the grasshopper files
    if exist('Grasshopper.Cam_Settings.mat','file') == 2
        Grasshopper = load('Grasshopper.Cam_Settings.mat');
        save(strcat(vid_name(1:end-3),'mat'),'Grasshopper','-append');
    end
    
    disp([strcat(vid_name(1:end-4),'-frames.mat'),' is saved'])
    disp([strcat(vid_name(1:end-3),'mat'),' is updated'])
end



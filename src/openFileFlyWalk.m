function f=openFileFlyWalk(pathlist,gui_on,options)
% tracks and saves all files given in pathlist

% first figure out the pathlist
% if .avi is given make it mat file
[filePath,fileName,~] = fileparts(pathlist);
pathlist = fullfile(filePath,[fileName,'.mat']);
if ~exist(pathlist,'file')
    disp([pathlist, ' is not in the path will try to locate it'])
    fns = getFullPath(pathlist);
    if exist(fns,'file')
        disp(['Located here: ',fns])
        pathlist = fns;
    else
        disp(['unable to find: ',pathlist])
    end
end


switch nargin
    case 2
        options = [];
    case 1
        options = [];
        gui_on = 1;
end

% set the fly walk
f = flyWalk;
% set and fix options
% set defaults
defOptions = {  ...
    'track_movie',                  true;       ... % Tracks the video
    'ft_debug',                     true;       ... % shows debug progress
    'show_split',                   false;      ... % does not show splitted flies
    'label_flies',                  true;       ... % labels (number) flies on the video
    'show_orientations',            false;      ... % shows the orientation of flies with a triangle
    'show_antenna',                 false;      ... % shows the antenna as a pink ellips
    'show_trajectories',            true;       ... % shiws the trajectory a a trailer
    'trajectory_vis_length',        5;          ... % sec
    'show_annotation',              true;       ... % annotate video
    'fly_body_threshold',           150;        ... % threshold to binarize flies
    'min_fly_area',                 1;          ... % mm^2
    'run_signal_modules',           false;      ... % do not run signal modules
    'track_reverse',                0;          ... % do not tracks reverse
    'max_num_of_interacting_flies', 4;          ... % do not attemp to resolve interaction more than this number
    'look_for_lost_flies_length',   1;          ... %sec
    'subtract_prestim_median_frame',true;       ... % subract prestimulus median frame
    'correct_illumination',         false;      ... % set to true or 1 if smoke intensity is needed to be measured
    'maxAllowedTurnAngle',          30/180*pi;  ... % 30 degrees between frames max
    'max_lost_time',                2;          ... % flies lost longer than this will be labedled lost
    'show_flowfield',               false;      ... % do not show wind flow field
    'show_winddir',                 false;      ... % do not show wind direction of the fly
    'show_windSpeed',               false;      ... % do not show wind speed of the fly
    'show_pivmask',                 false;      ... % do not show PIV masks around flies
    'fillNmeasure',                 true;       ... % fill the frame and measur ethe reflection
    'ref_thresh',                   21;         ... % threshold for reflection assignment
    'nframes_ref',                  'all';      ... % measure reflections on all frames
    'show_ref_overlaps',            false;      ... % show reflection overlaps
    'show_reflections',             false;      ... % do not show reflection
    'subtract_median',              false;      ... % do not subtract median frame
    'subtract_background_frame',    true;       ... % subrtact background frame
    'apply_mask',                   true};         % apply the image mask on the frame
    

% check if the paramters are already set
if isempty(options)||(options==0) % no parameter is set
    givenFields = [];
    
else % there are some parameters supplied
    % replace them with the defaults
    givenFields = fieldnames(options);
end

for i = 1:numel(defOptions(:,1))
    if ~any(strcmp(defOptions(i,1),givenFields))
        f.(defOptions{i,1}) = defOptions{i,2};
    else
        f.(defOptions{i,1}) = options.(defOptions{i,1});
    end
end

% close all
filename = pathlist;
% f.fwPath = filePath;
f.fwName = [filename(1:end-4),'.flywalk'];
if exist([filename(1:end-4),'-frames.mat'],'file')
    f.videoType = 'mat';
    f.path_name  = [filename(1:end-4),'-frames.mat'];
    f.variable_name = 'frames';
elseif exist([filename(1:end-4),'.avi'],'file')
    f.videoType = 'avi';
    f.path_name  = [filename(1:end-4),'.avi'];
elseif exist([filename(1:end-4),'.mj2'],'file')
    f.videoType = 'mj2';
    f.path_name  = [filename(1:end-4),'.mj2'];
end
f = f.initialise;

% incase there was a saved file re-assign the input options
for i = 1:numel(defOptions(:,1))
    if any(strcmp(defOptions(i,1),givenFields))
        f.(defOptions{i,1}) = options.(defOptions{i,1});
    end
end

if gui_on
    f.createGUI;
    % update the displayed frame
    if ~isempty(f.ui_handles)
        if ~isempty(f.ui_handles.fig)
            if f.show_annotation
                % show tracking annotation
                showTrackingAnnotation(f)
            end
        end
    end
else
    f.show_annotation = false;
end


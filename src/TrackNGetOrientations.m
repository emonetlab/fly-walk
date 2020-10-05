% loads the given file, tracks if not tracked, fixes orientations
%
% file is saved at the end of each section so that if a later sections
% fails rest of the data is not lost
%
function TrackNGetOrientations(filepath,GuiOn)

switch nargin
    case 1
        GuiOn = 0; % do not pop up the gui
end


% open filewalk file without gui
f=openFileFlyWalk(filepath,GuiOn,0);
f.subtract_prestim_median_frame = 1; % subtract prestimulus median frame
if ~exist([filepath(1:end-4),'.flywalk'],'file')
    disp('there is NOT a saved file. Will track');
    f.track;  % if tracking for all moduels on is needed
    
    % set tracking to off
    f.track_movie = false;    % trun off tracking
    f.show_annotation = false;
    
    % save the data at this point
    f.save;
end



% set the orientation detection parameters
f.tracking_info.speedSmthlen = smooth(.2*f.ExpParam.fps);
f.tracking_info.angle_flip_threshold = 120;
f.heading_allignment_factor = 13;
f.antenna_opt_method = 'overlap'; % signal: minimizes the measured signal, overlap: minimizes the overlap with the dilated fly
f.length_aos_mat = 10; % use 10 points to optimize antenna offset
f.antenna_opt_dil_n = 7; % number of poinst to dilate fly for antenna optimization



if ~isfield(f.tracking_info,'coligzone')
    f = getCIZoneStatus(f);
    % fix CIZ, periphery, and perimeter
    disp('handling CIZStatus...');
end

if ~isfield(f.tracking_info,'periphery')
    f = getPeripheryStatus(f);
    disp('handling Periphery values...');
end

if ~isfield(f.tracking_info,'perimeter')
    f = getPerimeterNEccent(f);
    disp('handling Perimeter values...');
end

% save the data at this point
f.save;

% set antenna optimization, orientation and signal measurement
% parameters
ormethl = {'M','M1'};
% ormethl = {'M1'};


for ormeth = 1:numel(ormethl)
    % fix orientations if not already fixed
    orientation_method = ormethl{ormeth};
    if ~isfield(f.tracking_info,['orientation_',orientation_method])
        disp(['fixing orientations... method ',ormethl{ormeth}]);
        if strcmp(ormethl{ormeth},'M1')
            % orientation method 1
            f = PostProcessOrientations1(f);
        elseif strcmp(ormethl{ormeth},'M')
            f = PostProcessOrientations(f);
        end
    else
        disp(['Orientations for method ',ormethl{ormeth},' is already fixed']);
    end
    
    % save this method
    
    f.tracking_info.(['orientation_',orientation_method]) = f.tracking_info.orientation;
    
    
end

% set the defaults signal and orientation settings
% set signal type
orientation_method = 'M1';

assert(ismember(orientation_method,{'M','M1'}),['orientation method "',orientation_method,'" is not valid. Options: M, M1'])
f.tracking_info.orientation  = f.tracking_info.(['orientation_',orientation_method]);

% save the file
f.save;
disp('flywalk file is saved');


end

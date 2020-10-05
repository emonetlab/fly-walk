% loads the given file, tracks if not tracked, fixes orientations by two
% different methods. The file path is a cell array of relative paths
function trackNGetOrntsOfTheseFiles(filepath)
    % open filewalk file without gui
    f=openFileFlyWalk(filepath,0,0);
    f.subtract_prestim_median_frame = 1; % subtract prestimulus median frame
    if ~exist([filepath(1:end-4),'.flywalk'],'file')
        disp('there is NOT a saved file. Will track');
        f.track_movie = 0;
        f.trackNgetOrientations;
    end
    f.track_movie=0;    % turn off tracking
    f.show_annotation = false;
    
    f.tracking_info.speedSmthlen = smooth(.2*f.ExpParam.fps);
    f.tracking_info.angle_flip_threshold = 120;
    
    % fix CIZ, periphery, and perimeter
    disp('handling CIZStatus, Periphery and Perimeter values...');
    
    if ~isfield(f.tracking_info,'coligzone')
        f = getCIZoneStatus(f);
    end
    
    if ~isfield(f.tracking_info,'periphery')
        f = getPeripheryStatus(f);
    end
    
    if ~isfield(f.tracking_info,'perimeter')
        f = getPerimeterNEccent(f);
    end
    
    ormethl = {'M','M1'};
    
    
    for ormeth = 1:numel(ormethl)
        % fix orientations
        disp(['fixing orientations... method: ',ormethl{ormeth}]);
        if strcmp(ormethl{ormeth},'M1')
            % orientation method 1
            f = PostProcessOrientations1(f);
        elseif strcmp(ormethl{ormeth},'M')
            f = PostProcessOrientations(f);
        end
    end
    
    % save the file
    f.save;
    disp('flywalk file is saved');

end

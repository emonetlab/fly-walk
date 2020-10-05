% loads the given file, tracks if not tracked, fixes orientations by two
% different methods, optimizes antenna for these two methods, then measures
% the signal for both ellipse and circle antenna using both mean and median
% methods
% now only extracts fixed antenna, ellips shape and m1 orientation
% correction. By default the flywalk is set to these settings
%
% file is saved at the end of each section so that if a later sections
% fails rest of the sata is not lost
%
function f = ExtractBoxVirtAntennaSignal(filepath,gui_on,test)

switch nargin
    case 2
        test = false;
    case 1
        test = false;
        gui_on = false;
end

if test
    fidtest = fopen([filepath(1:end-4),'_dataout.txt'],'w');
    
    fwrite(fidtest,['filename is ', filepath, '. This is a test run']);
    
    fclose(fidtest);
    return
end


% open filewalk file without gui
f=openFileFlyWalk(filepath,gui_on,0);
f.subtract_prestim_median_frame = 1; % subtract prestimulus median frame
if ~exist([filepath(1:end-4),'.flywalk'],'file')
    disp('there is NOT a saved file. Will track');
    f.track_movie = true;
    f.track;
    
    % set tracking to off
    f.track_movie = false;    % trun off tracking
    f.show_annotation = false;
    
    % save the data at this point
    disp('Tracking is done. Saving the .flywalk file...');
    f.save;
    if gui_on
        
        f.track_movie=0;
        f.show_annotation=1;
        f.show_reflections=0;
        f.show_trajectories=1;
        f.createGUI;
        disp('Opening the Gui...');
        
    end
end
if gui_on
    
    f.track_movie = false;
    f.show_annotation = true;
    f.show_reflections = false;
    f.show_trajectories = true;
    
end



% set the orientation detection parameters
f.tracking_info.speedSmthlen = smooth(.2*f.ExpParam.fps);
f.tracking_info.angle_flip_threshold = 120;
f.heading_allignment_factor = 13;
f.antenna_opt_method = 'overlap'; % signal: minimizes the measured signal, overlap: minimizes the overlap with the dilated fly
f.length_aos_mat = 10; % use 10 points to optimize antenna offset
f.antenna_opt_dil_n = 7; % number of poinst to dilate fly for antenna optimization

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

% save the data at this point
disp('CIZ, Periphery and Perimeter extraction is done. Saving the .flywalk file...');
f.save;
if gui_on
    disp('Opening the Gui...');
    f.createGUI;
end


% set antenna optimization, orientation and signal measurement
% parameters
atypel = {'fixed'};
ashapel = {'box'};
%     ormethl = {'M','M1'};
ormethl = {'M1'};


f.tracking_info.signal_mean = f.tracking_info.signal; % save both mean and median
f.signal_meas_method = 'median';  % get median intensity value in the virtual antenna

for ormeth = 1:numel(ormethl)
    % fix orientations
    %     disp(['fixing orientations... method: ',ormethl{ormeth}]);
    %     if strcmp(ormethl{ormeth},'M1')
    %         % orientation method 1
    %         f = PostProcessOrientations1(f);
    %     elseif strcmp(ormethl{ormeth},'M')
    %         f = PostProcessOrientations(f);
    %     end
    
    for atypenum = 1:numel(atypel)
        for ashapenum = 1:numel(ashapel)
            antenna_shape = ashapel{ashapenum};
            antenna_type = atypel{atypenum};
            orientation_method = ormethl{ormeth};
            
            f.antenna_type = antenna_type;   % fixed: distance to fly center is fixed, dynamic: moved away if overlaps with secondary reflection
            f.antenna_shape = antenna_shape;
            
            disp(['optimizing antenna... type: ',antenna_type,' - shape: ',antenna_shape]);
            
            % optimize antenna offset
            f = PostOptAntOffset(f);
            
            if strcmp(f.antenna_shape,'box')
                % determine number of flies
                nFlies = find(f.tracking_info.fly_status(:,end)~=0,1,'last');
                % get segment numbers list
                AntBoxSignalSegmentNum = round(1.2*nanmean(f.tracking_info.minax(:,:),2));
                AntBoxSignalSegmentNum(mod(AntBoxSignalSegmentNum,2)~=0) = AntBoxSignalSegmentNum(mod(AntBoxSignalSegmentNum,2)~=0) + 1;
                AntBoxSignalSegmentNum = AntBoxSignalSegmentNum(1:nFlies);
                % figure out the allocation size for box signal
                maxSegNum = max(AntBoxSignalSegmentNum);
                % allocate box signal matrix
                f.tracking_info.AntBoxSignal = nan(maxSegNum,nFlies,f.nframes); % allocate space bor virtual box signal
                f.tracking_info.AntBoxSignalSegmentNum = AntBoxSignalSegmentNum; % virtual antenna box signal segment numbers
                f.tracking_info.AntBoxSignalSlope = nan(size(f.tracking_info.signal)); % the slope of the antenna box signal
                disp('Segment-numbers calculated and registered. Antenna Box Signal space is allocated.')
                disp(['There are ',num2str(nFlies),' flies and Max segment number is ',num2str(maxSegNum)])
            end
            
            disp(['measuring... type: ',antenna_type,' - shape: ',antenna_shape]);
            % extract signal
            f = extractSignal(f);
            
            f = saveSignalType(f,antenna_shape,antenna_type,orientation_method);
        end
    end
end

% set the defaults signal and orientation settings
% set signal type
orientation_method = 'M1';
measure_method = 'mean';
antenna_type = 'fixed';
antenna_shape = 'ellipse';

% sets the values to requested signal measurement method
f = setSignalType(f,antenna_shape,antenna_type,measure_method,orientation_method);
f = getBinarizedSignalDetection(f);

% save the file
f.save;
disp('flywalk file is saved');
if gui_on
    disp('Opening the Gui...');
    f.createGUI;
end

if nargout==0
end


end



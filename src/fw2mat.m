function [varmat,properties] = fw2mat(filepath)

% constructs the matrix with column names specified by TableHeaders below.
[~,fname] = fileparts(filepath);

% if you need to add a new column definition, do it left of
% 'ant_signaL_grad' since the code extends the varmat at the end to
% accomodate the antenna gradient measurement values

TableHeaders = {'trjNumVideo','t','x','y','vx','vy',...
    'speed','theta','a','b','area','signal','dtheta',...
    'frameNum','waldir','dwaldir','fps','mm_per_px','sx','sy',...
    'nofflies','starve_day','age_day','room_Temp','room_Hum',...
    'reflection','reflection_meas','collision','overpass',...
    'jump','fly_status','refOverLap1','refOverLap2',...
    'excent','perimeter','coligzone','periphery','signal_mask',...
    'onset_num','peak_num','offset_num',...
    'signal_threshold','mu','sigma','nfac',...
    'wind_dir','wind_speed','ant_signal_grad','num_ant_seg'};

% contruct the column definitions
% get the column outputs to sturcture inputs
for i = 1:numel(TableHeaders)
    col.(TableHeaders{i}) = i;
end

% try the simplest method first and then switch to more complicated one
datatemp = load([filepath(1:end-4),'.flywalk'],'-mat');
f = datatemp.fly_walk_obj;

clear datatemp
datatemp = load([filepath(1:end-4),'.mat']);

nof_flies = mode(sum(f.tracking_info.fly_status==1,1));
noftracks = find(f.tracking_info.fly_status(:,end)~=0,1,'last');
% start constructing the variable matrix
% determine the size of the matrix
matrix_length  = 0;

for i = 1:noftracks
    matrix_length  = matrix_length + find(f.tracking_info.fly_status(i,:)==1,1,'last')-find(f.tracking_info.fly_status(i,:)==1,1)+1;
end

% initiate varmat
varmat  = zeros(matrix_length,length(TableHeaders));

% fill the matrix
ei = 0; % start index
for i = 1:noftracks                                                                               % set start index
    si_this_fly = find(f.tracking_info.fly_status(i,:)==1,1);                                       % start index of track
    ei_this_fly = find(f.tracking_info.fly_status(i,:)==1,1,'last');                                % end index of track
    if isempty(si_this_fly)||isempty(ei_this_fly)
        continue
    end
    si = ei + 1; 
    ei = si + ei_this_fly - si_this_fly;                                                            % set end index
    varmat(si:ei,col.trjNumVideo) = i;                                                                            % trj number (index)
    varmat(si:ei,col.t)  = ((si_this_fly:ei_this_fly)-1)/f.ExpParam.fps;                                % time
    varmat(si:ei,col.x)  = f.tracking_info.x(i,si_this_fly:ei_this_fly);                                % x
    varmat(si:ei,col.y)  = f.tracking_info.y(i,si_this_fly:ei_this_fly);                                % y
    
    % do the derivatives
    if length(si:ei)<4
        varmat(si+1:ei,col.vx)  = diff(f.tracking_info.x(i,si_this_fly:ei_this_fly)).*f.ExpParam.fps;   % vx calculated as central derivative of x
        varmat(si+1:ei,col.vy)  = diff(f.tracking_info.y(i,si_this_fly:ei_this_fly)).*f.ExpParam.fps;   % vy calculated as central derivative of x
        varmat(si+1:ei,col.dtheta) = angleDiffVec(f.tracking_info.orientation(i,si_this_fly:ei_this_fly)).*f.ExpParam.fps;      % rotational speed
        varmat(si+1:ei,col.dwaldir) = angleDiffVec(f.tracking_info.heading(i,si_this_fly:ei_this_fly)).*f.ExpParam.fps;      % derivative of walking direction
    else
        varmat(si:ei,col.vx)  = diffCentral(f.tracking_info.x(i,si_this_fly:ei_this_fly)).*f.ExpParam.fps;   % vx calculated as central derivative of x
        varmat(si:ei,col.vy)  = diffCentral(f.tracking_info.y(i,si_this_fly:ei_this_fly)).*f.ExpParam.fps;   % vy calculated as central derivative of x
        varmat(si:ei,col.dtheta) = anglediffCentral(f.tracking_info.orientation(i,si_this_fly:ei_this_fly)).*f.ExpParam.fps;      % rotational speed
        varmat(si:ei,col.dwaldir) = anglediffCentral(f.tracking_info.heading(i,si_this_fly:ei_this_fly)).*f.ExpParam.fps;      % derivative of walking direction
    end
    
    varmat(si:ei,col.speed)  = sqrt(varmat(si:ei,col.vx).^2+varmat(si:ei,col.vy).^2);                                 % speed
    varmat(si:ei,col.theta)  = f.tracking_info.orientation(i,si_this_fly:ei_this_fly);                      % theta
    varmat(si:ei,col.a)  = f.tracking_info.majax(i,si_this_fly:ei_this_fly);                            % a (major axis)
    varmat(si:ei,col.b) = f.tracking_info.minax(i,si_this_fly:ei_this_fly);                            % b (minor axis)
    varmat(si:ei,col.area) = f.tracking_info.area(i,si_this_fly:ei_this_fly);                             % area
    varmat(si:ei,col.signal) = f.tracking_info.signal(i,si_this_fly:ei_this_fly);                           % signal
    varmat(si:ei,col.frameNum) = si_this_fly:ei_this_fly;                                                     % frame index in the video
    varmat(si:ei,col.waldir) = f.tracking_info.heading(i,si_this_fly:ei_this_fly);                          % walking direction
    varmat(si:ei,col.reflection) = f.reflection_status(i,si_this_fly:ei_this_fly);                              % reflection assignment (1: top surface, 0: bottom)
    varmat(si:ei,col.reflection_meas) = f.reflection_meas(i,si_this_fly:ei_this_fly);                              % reflection measurement
    varmat(si:ei,col.collision) = f.tracking_info.collision(i,si_this_fly:ei_this_fly);                        % collision, id of the colliding fly, negative: index to CollS container
    varmat(si:ei,col.overpass) = f.tracking_info.overpassing(i,si_this_fly:ei_this_fly);                      % overpass, id of the overpassing fly, negative: index to CollS container
    if  isfield(f.tracking_info,'jump_status')
        varmat(si:ei,col.jump) = f.tracking_info.jump_status(i,si_this_fly:ei_this_fly);                      % jumping status: 1:yes, 0: no
    else
        varmat(si:ei,col.jump) = nan;
    end
    varmat(si:ei,col.fly_status) = f.tracking_info.fly_status(i,si_this_fly:ei_this_fly);
    % fly_status: 1: assigned active, 2: lost, 3: left the arena
    if  isfield(f.tracking_info,'excent')
        varmat(si:ei,col.excent) = f.tracking_info.excent(i,si_this_fly:ei_this_fly);  
        % excentricity
    else
        varmat(si:ei,col.excent) = nan;
    end
    if  isfield(f.tracking_info,'perimeter')
        varmat(si:ei,col.perimeter) = f.tracking_info.perimeter(i,si_this_fly:ei_this_fly);                        % perimeter
    else
        varmat(si:ei,col.perimeter) = nan;
    end
    if  isfield(f.tracking_info,'coligzone')    
        varmat(si:ei,col.coligzone) = f.tracking_info.coligzone(i,si_this_fly:ei_this_fly);                        % collision ignore zone status
    else
        varmat(si:ei,col.coligzone) = nan;
    end
    if  isfield(f.tracking_info,'periphery') 
        varmat(si:ei,col.periphery) = f.tracking_info.periphery(i,si_this_fly:ei_this_fly);                        % periphery status
    else
        varmat(si:ei,col.periphery) = nan;
    end
        
    % if reflection is not measured
    if  isfield(f.tracking_info,'refOverLap1')
        varmat(si:ei,col.refOverLap1) = f.tracking_info.refOverLap1(i,si_this_fly:ei_this_fly);                        % reflection overlaps order 1
    end
    if  isfield(f.tracking_info,'refOverLap2')
        varmat(si:ei,col.refOverLap2) = f.tracking_info.refOverLap2(i,si_this_fly:ei_this_fly);                        % reflection overlaps order 2
    end

    
    if isfield(f.tracking_info,'mask_of_signal')
        varmat(si:ei,col.signal_mask) = f.tracking_info.mask_of_signal(i,si_this_fly:ei_this_fly);
    end% mask of the signal
    if isfield(f.tracking_info,'meanWindDir')
        varmat(si:ei,col.wind_dir) = f.tracking_info.meanWindDir(i,si_this_fly:ei_this_fly);                  % mean wind direction in the virtual antena, by PIVlab
        varmat(si:ei,col.wind_speed) = f.tracking_info.meanWindSpeed(i,si_this_fly:ei_this_fly).*f.ExpParam.fps;            % mean wind speed in the virtual antena, by PIVlab
    else
        
    end
    % get virtual antenna dradient )slope of the intensity profile) if
    % calculated
    if isfield(f.tracking_info,'AntBoxSignalSlope')
        varmat(si:ei,col.ant_signal_grad) = f.tracking_info.AntBoxSignalSlope(i,si_this_fly:ei_this_fly);
        segnumthis = f.tracking_info.AntBoxSignalSegmentNum(i);
        varmat(si:ei,col.num_ant_seg) = segnumthis;
        varmat(si:ei,col.num_ant_seg+1:col.num_ant_seg+segnumthis) = squeeze(f.tracking_info.AntBoxSignal(1:segnumthis,i,si_this_fly:ei_this_fly))';
    else
        varmat(si:ei,col.ant_signal_grad) = nan;
        varmat(si:ei,col.num_ant_seg) = nan;
        varmat(si:ei,col.num_ant_seg+1:end) = nan;
    end
    
    % encounter points
    if isfield(f.tracking_info,'signal_onset')
        
        if isfield(f.tracking_info,'SignalBinPar')
            varmat(si:ei,col.signal_threshold) = f.tracking_info.SignalBinPar.signal_threshold;          % signal threshold
            varmat(si:ei,col.mu) = f.tracking_info.SignalBinPar.mu;                        % background signal value
            varmat(si:ei,col.sigma) = f.tracking_info.SignalBinPar.sigma;                     % background signal standar deviation
            varmat(si:ei,col.nfac) = f.tracking_info.SignalBinPar.nfac;                      % threshold = mu + nfac*sigma
            
        else
            varmat(si:ei,col.signal_threshold) = f.tracking_info.signal_threshold;                        % signal threshold
            varmat(si:ei,col.mu) = nan;                        % background signal value
            varmat(si:ei,col.sigma) = nan;                     % background signal standar deviation
            varmat(si:ei,col.nfac) = nan;                      % threshold = mu + nfac*sigma
        end% mask of the signal
        
        if size(f.tracking_info.signal_onset,1)>=i
            on_frms = nonzeros(f.tracking_info.signal_onset(i,:));
            pk_frms = nonzeros(f.tracking_info.signal_peak(i,:));
            off_frms = nonzeros(f.tracking_info.signal_offset(i,:));
            
            if ~isempty(on_frms)
                all_frms = si_this_fly:ei_this_fly;
                % modify start and end points
                if on_frms(1)<all_frms(1)
                    on_frms(1) = all_frms(1);
                end
                if off_frms(end)>all_frms(end)
                    off_frms(end) = all_frms(end);
                end
                varmat(find(sum(all_frms==on_frms,1))+si-1,col.onset_num) = (1:length(on_frms))';
                varmat(find(sum(all_frms==pk_frms,1))+si-1,col.peak_num) = (1:length(on_frms))';
                varmat(find(sum(all_frms==off_frms,1))+si-1,col.offset_num) = (1:length(on_frms))';
            end
        end
        
    else
        varmat(si:ei,col.onset_num) = NaN;
        varmat(si:ei,col.peak_num) = NaN;
        varmat(si:ei,col.offset_num) = NaN;
        varmat(si:ei,col.signal_threshold) = NaN;                        % signal threshold
    end
end

% fill the constants and PIV parameters
% if PIV data is missing set the field to nan
if ~isfield(f.tracking_info,'meanWindDir')
    varmat(:,col.wind_dir) = nan;                    % mean wind direction in the virtual antena, by PIVlab
    varmat(:,col.wind_speed) = nan;                    % mean wind speed in the virtual antena, by PIVlab
end

% write the constants
varmat(:,col.fps) = f.ExpParam.fps;                  % frames per second
varmat(:,col.mm_per_px) = f.ExpParam.mm_per_px;            % calibration
varmat(:,col.sx) = f.ExpParam.source.x;             % Source x
varmat(:,col.sy) = f.ExpParam.source.y;             % Source y
varmat(:,col.nofflies) = nof_flies;                       % mode of flies counts over the frames

if isfield(datatemp,'metadata')
    disp([fname,' : MetaData available.'])
    varmat(:,col.starve_day) = datatemp.metadata.days_starved;          % # days starved
    varmat(:,col.age_day) = datatemp.metadata.age;                   % # age days
    varmat(:,col.room_Temp) = datatemp.metadata.Temp;                  % # room temperature
    varmat(:,col.room_Hum) = datatemp.metadata.humidity;              % # room temperature
else
    % try to use the filename
    try
        [~,p] = getExpTrl(filepath);
        varmat(:,col.starve_day) = p.s.starve;          % # days starved
        varmat(:,col.age_day) = p.s.age;             % # age days
    catch
        disp([fname,' seems not to have the proper name format. Assuming Normal Conditions'])
        % fix this now it assumes only fixed values
        varmat(:,col.starve_day) = 3;   % # days starved
        varmat(:,col.age_day) = 7;   % # age days
    end
    varmat(:,col.room_Temp) = 23;   % # room temperature
    varmat(:,col.room_Hum) = 40;   % # room temperature
end

% convert all dimensions to mm
Convert2MM = {'x','y','vx','vy','speed','a','b','area','sx','sy','wind_speed'};
for dci = 1:numel(Convert2MM)
    varmat(:,col.(Convert2MM{dci}))  = varmat(:,col.(Convert2MM{dci})).*f.ExpParam.mm_per_px;
end

properties.TableHeaders = TableHeaders;
properties.filepath = filepath;
properties.nof_flies = nof_flies;
properties.noftracks = noftracks;
properties.col = col;
% this function operates on a flyTrack object
% and generates some tracking info if needed

function f = makeTrackingInfoPlaceholders(f)

% % check if we already have some tracking info save
% [dir_name,file_name]=fileparts(f.path_name.Properties.Source);
% try
% 	saved_f = load([dir_name oss file_name ,'_fly_track.mat'],'f');
% 	f = saved_f.f;
% 	f.start_frame = f.current_frame_index;
% 	return
% catch
	
% end


% unpack
r = f.current_objects;
nframes = f.nframes;
if isempty(r)||(length(r)<20)
    lengthr = 30;
else
    lengthr = length(r);
end

% placeholders
tracking_info.x = NaN(lengthr*f.track_per_fly_max,nframes); % we budget for extra flies we might run into
tracking_info.y = NaN(lengthr*f.track_per_fly_max,nframes);
tracking_info.heading = NaN(lengthr*f.track_per_fly_max,nframes);
tracking_info.orientation = NaN(lengthr*f.track_per_fly_max,nframes);
tracking_info.area = NaN(lengthr*f.track_per_fly_max,nframes);
tracking_info.collision = NaN(lengthr*f.track_per_fly_max,nframes); % id of the fly collided with
tracking_info.IgnoredInteractions = NaN(lengthr*f.track_per_fly_max,nframes); % ignored interactions
tracking_info.overpassing = NaN(lengthr*f.track_per_fly_max,nframes); % id of the fly collided with
tracking_info.fly_status = zeros(lengthr*f.track_per_fly_max,nframes); % fly status, assigned or not, etc
tracking_info.periphery = zeros(lengthr*f.track_per_fly_max,nframes); % whether or not the fly is in the periphery
tracking_info.error_code = zeros(lengthr*f.track_per_fly_max,nframes,'int8');   % error code info
tracking_info.majax = NaN(lengthr*f.track_per_fly_max,nframes); % major axis
tracking_info.minax = NaN(lengthr*f.track_per_fly_max,nframes); % major axis
tracking_info.signal = NaN(lengthr*f.track_per_fly_max,nframes); % signal measurement over the virtual antenna
tracking_info.BoxSignalPxl = NaN(f.signalBoxSegmentNum,f.nframes,length(f.antoffset)); % box signal measurement over the fly
tracking_info.antoffsetAF = ones(lengthr*f.track_per_fly_max,nframes)*f.antenna_offset_default;
tracking_info.grador = zeros(lengthr*f.track_per_fly_max,f.nFramesforGradOrient); % container for orientations obtained by intensity gradient
tracking_info.OrientFlipind = zeros(lengthr*f.track_per_fly_max,1); % index container for orientation flips
tracking_info.OrientLocked = zeros(lengthr*f.track_per_fly_max,1); % logical for orientation lock to one particular direction
tracking_info.OrientVerify = zeros(lengthr*f.track_per_fly_max,f.HeadingAllignPointsNum+1); % container for orientation - walking direction verification
                                                                                          % extra point is for checking the end of verification              
tracking_info.perimeter = NaN(lengthr*f.track_per_fly_max,nframes); % major axis
tracking_info.excent = NaN(lengthr*f.track_per_fly_max,nframes); % major axis

% set segment edges and centers
len = f.signalBoxSize(1)/f.ExpParam.mm_per_px;
segment_edges = linspace(1,ceil(len/f.signalBoxSegmentNum)*f.signalBoxSegmentNum+1,f.signalBoxSegmentNum+1)-1;
segment_edges = segment_edges/max(segment_edges)*f.signalBoxSize(1);
segment_center = segment_edges + circshift(segment_edges,-1);
segment_center = ((segment_center(1:end-1))/2)-f.signalBoxSize(1)/2;
tracking_info.segment_edges = segment_edges;
tracking_info.segment_center = segment_center;

tracking_info.jump_status = false(lengthr*f.track_per_fly_max,nframes); % no reflections assumed in the beginning
tracking_info.antenna_overlap = zeros(lengthr*f.track_per_fly_max,nframes); % virtual antenna overlap with another fly or primary reflection
tracking_info.antenna2R_overlap = zeros(lengthr*f.track_per_fly_max,nframes); % virtual antenna overlap with secondary reflection;
tracking_info.antenna1R_overlap = zeros(lengthr*f.track_per_fly_max,nframes); % virtual antenna overlap with secondary reflection;
% 0 -- unassigned, 
% 1 -- asssigned, visible
% 2 -- assigned, missing
% 3 -- assigned, missing at the border, terminate the tracks
% 4 -- lost in the interaction, dropped after a certain time
% -1 -- assigned, possibly colliding with one object
% -2 -- assigned, possibly colliding with two objects
% -11 -- assigned, missing in the frame probably overpassing


% reflection variables
reflection_status = false(lengthr*f.track_per_fly_max,nframes); % no reflections assumed in the beginning
reflection_meas = NaN(lengthr*f.track_per_fly_max,nframes); %store reflection measurements
reflection_overlap = zeros(lengthr*f.track_per_fly_max,nframes); %store reflection overlaps
HeadNOrientAllign  = zeros(lengthr*f.track_per_fly_max,1); % is heading and orientration alligned
antoffset  = ones(lengthr*f.track_per_fly_max,1)*f.antenna_offset_default; % antenna ofset parameter (default value)
antoffset_opt_mat = NaN(lengthr*f.track_per_fly_max,f.length_aos_mat); % antenna ofset parameter             
antoffset_status = zeros(lengthr*f.track_per_fly_max,1); % antenna ofset parameter




f.tracking_info = tracking_info;
f.reflection_status = reflection_status;
f.reflection_meas = reflection_meas;
f.reflection_overlap = reflection_overlap;
f.HeadNOrientAllign = HeadNOrientAllign;                 
f.antoffset = antoffset;
f.antoffset_opt_mat = antoffset_opt_mat;
f.antoffset_status = antoffset_status;

%% wipeAllTrackingInfoAfterCurrentFrame
% 
function f = wipeAllTrackingInfoAfterCurrentFrame(f)

cf = f.current_frame;
fn_nan = {'x','y','heading','orientation','area','collision','overpassing',...
    'majax','minax','signal','BoxSignalPxl'};

fn_zero = {'fly_status','error_code','antenna_overlap','periphery'};
                               


for i = 1:length(fn_nan)
	f.tracking_info.(fn_nan{i})(:,cf:end) = NaN;
end


for i = 1:length(fn_zero)
	f.tracking_info.(fn_zero{i})(:,cf:end) = 0;
end


f.reflection_meas(:,cf:end) = NaN; %store reflection measurements
f.antoffset_opt_mat(:,cf:end) = NaN; % antenna ofset parameter   
f.reflection_overlap(:,cf:end) = 0; %store reflection overlaps
f.HeadNOrientAllign(:)  = 0; % is heading and orientration alligned
f.reflection_status(:,cf:end) = 0; % no reflections assumed in the beginning

          





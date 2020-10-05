function f = getBoxSignalMeasPxl(f)
%getBoxSignalMeasPxl
% creates a box around the fly defined by signalBoxSize and measures the
% profiles by segmenting the box and measuring the mean of the pixel values.
%

% which flies are currently assigned
current_flies = find(f.tracking_info.fly_status(:,f.current_frame)==1);
if isempty(current_flies)
    return
end

% go over these flies and measure the signal
for flynum = 1:length(current_flies)
     this_fly = current_flies(flynum);
     f.tracking_info.BoxSignalPxl(:,f.current_frame,this_fly) = getBoxSignalPxl(f,this_fly);
end

        


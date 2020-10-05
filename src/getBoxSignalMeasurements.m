function f = getBoxSignalMeasurements(f)
%getBoxSignalMeasurements 
% creates a box around the fly defined by signalBoxSize and measures the
% profiles as lines along the long axis. registers the median value of a
% defined segment.
%

% which flies are currently assigned
current_flies = find(f.tracking_info.fly_status(:,f.current_frame)==1);
if isempty(current_flies)
    return
end

% go over these flies and measure the signal
for flynum = 1:length(current_flies)
     this_fly = current_flies(flynum);
     boxsignal = getBoxSignal(f,this_fly);
     for segnum = 1:f.signalBoxSegmentNum
         segsig = boxsignal(f.tracking_info.segment_edges(segnum):f.tracking_info.segment_edges(segnum+1),:);
         segsig = segsig(:);
         f.tracking_info.BoxSignal(segnum,f.current_frame,this_fly) = mean(segsig);
     end
end

        


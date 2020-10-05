function [ant_off_param,aoplist] = OptAntonTheseFrames(f,thisFly,these_frames)
% optimizes the antenna ofset of given fly on given frames

aoplist = zeros(size(these_frames));

f.previous_frame = f.current_frame;
f.current_frame = these_frames(1);
% follow the fly for better visualization of antenna optimization
f.followThisFlyNumber = thisFly;
f.followBoxSize = 60;
f.operateOnFrame;

for aoind = 1:length(these_frames)
    thisFrame = these_frames(aoind);
    
    f.previous_frame = f.current_frame;
    f.current_frame = thisFrame;
    
    f.operateOnFrame;
    pxllist = fillFliesNReflections(f,[],f.antenna_opt_dil_n); % dilate n times
    if ~isempty(pxllist)
        val = optAntOffSet(f,thisFly,pxllist);
        if ~isnan(val)
            aoplist(aoind) = val;
        else
            disp('nan registered during antenna optimization.  check this')
        end
    else
        disp('Registered fly is not found in the frame after thresholding.')
        disp('Skipping this frame')
    end
end

% cancel fly following
% follow the fly for better visualization of antenna optimization
f.followThisFlyNumber = nan;
f.operateOnFrame;

aolt = aoplist;
aolt(aolt==0) = [];
aolt(isnan(aolt)) = [];
if length(aolt)<length(aoplist)/2
    disp('more than half of the frames are useless')
end
ant_off_param = nanmean(aolt);
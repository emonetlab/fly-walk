function f = optimizeAntOffsetatAllFrames(f)
%optimizeAntOffsetatAllFrames
% for all given frames, in each frame estimates the optimized antenna
% offset by:
% overlap: minimizing the overlap and distance, then averages all
% optimized offset values over all requested frames. For flies with antenna
% completely overlapping with another fly, and interacting flies the
% previous offset value is used.

if ~strcmp(f.antenna_type,'dynamic')
    return
end


% which flies are currently assigned
current_flies = find(f.tracking_info.fly_status(:,f.current_frame)==1);

% which of these are interacting
current_interacting_flies = [find(~isnan(f.tracking_info.collision(:,f.current_frame)));...
    find(~isnan(f.tracking_info.overpassing(:,f.current_frame)))];

% remove interacting flies
current_flies(logical(sum(current_flies==current_interacting_flies',2))) = [];

% remove jumpers
current_jumpers = find(f.tracking_info.jump_status(:,f.current_frame)==1);
if ~isempty(current_jumpers)
    current_flies(logical(sum(current_flies==current_jumpers',2))) = [];
end

% get flies with reflections
only_these_refs = []; % do not consider primary reflections

if isempty(current_flies)
    return
else
    % get the pxl list for dilated flies
    pxllist = fillFliesNReflections(f,only_these_refs,f.antenna_opt_dil_n); % dilate n times

    % go over these objects and get optimized offset value
    for flynum = 1:length(current_flies)
        % get fly seconday antenna pixels
        a2pxls = PredRefGeomFly(f,current_flies(flynum),2,f.R2Resize); % last parameter is resize, replace 1.1 in order to enlarge reflection by 10%
        val = optAntOffSet(f,current_flies(flynum),[pxllist;a2pxls]);
        if isnan(val)
            if f.current_frame==1
               f.tracking_info.antoffsetAF(current_flies(flynum),f.current_frame) = f.antenna_offset_default;
            else
                f.tracking_info.antoffsetAF(current_flies(flynum),f.current_frame) = f.tracking_info.antoffsetAF(current_flies(flynum),f.current_frame-1);
            end
        else
            f.tracking_info.antoffsetAF(current_flies(flynum),f.current_frame) = val;
        end
    end
    
end

allothers = unique([current_interacting_flies;current_jumpers]);

% set interacting guys to previous
if ~isempty(allothers)
        % go over these objects and get optimized offset value
    for flynum = 1:length(allothers)
            f.tracking_info.antoffsetAF(allothers(flynum),f.current_frame) = f.tracking_info.antoffsetAF(allothers(flynum),f.current_frame-1);
    end
end

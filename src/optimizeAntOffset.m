function f = optimizeAntOffset(f)
%optimizeAntOffset
% for all given frames, in each frame estimates the optimized antenna
% offset by:
% overlap: minimizing the overlap and distance, then averages all
% optimized offset values over all requested frames. For flies with antenna
% completely overlapping with another fly, and interacting flies the
% average value of other flies is set.
% signal: virtual antenna is moved back and forth until getting the closet
% distance to fly and minimum median signal in the virtual antenna

% which flies are not optimized
flies_not_optimized = find(f.antoffset_status==0);
% which flies are currently assigned
current_flies = find(f.tracking_info.fly_status(:,f.current_frame)==1);

% which of these are interacting
current_interacting_flies = [find(~isnan(f.tracking_info.collision(:,f.current_frame)));...
    find(~isnan(f.tracking_info.overpassing(:,f.current_frame)))];

% remove interacting flies
current_flies(logical(sum(current_flies==current_interacting_flies',2))) = [];

% refine the list
flies_not_optimized = intersect(flies_not_optimized,current_flies);

% which one of these has alligned direction
flies_not_optimized = intersect(flies_not_optimized,find(f.HeadNOrientAllign==1));

% remove jumpers
current_jumpers = find(f.tracking_info.jump_status(:,f.current_frame)==1);
if ~isempty(current_jumpers)
    flies_not_optimized(logical(sum(flies_not_optimized==current_jumpers',2))) = [];
end

% get flies with reflections
only_these_refs = []; % do not consider reflections

if isempty(flies_not_optimized)
    return
else
    % get the pxl list for dilated flies
    pxllist = fillFliesNReflections(f,only_these_refs,f.antenna_opt_dil_n); % dilate n times

    % go over these objects and get optimized offset value
    for flynum = 1:length(flies_not_optimized)
        valind = find(isnan(f.antoffset_opt_mat(flies_not_optimized(flynum),:)),1);
        val = optAntOffSet(f,flies_not_optimized(flynum),pxllist);
        if isnan(val)
            continue
        else
            f.antoffset_opt_mat(flies_not_optimized(flynum),valind) = val;
            f.antoffset(flies_not_optimized(flynum)) = nanmean(f.antoffset_opt_mat(flies_not_optimized(flynum),:));
            if valind == f.length_aos_mat
                f.antoffset_status(flies_not_optimized(flynum)) = 1;
            end
        end
    end
    
end

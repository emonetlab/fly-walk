function f = reEstimate1Roverlap(f)
%reEstimate1Roverlap
% calculates the overlap of the virtual antenna with the primary
% reflections and flies too
f.track_movie=0;

f.current_frame=1;
f.operateOnFrame;

for thisframe = 1:f.nframes
    f.previous_frame = f.current_frame;
    f.current_frame = thisframe;
    f.operateOnFrame;

    % which flies are currently assigned
    current_flies = find(f.tracking_info.fly_status(:,f.current_frame)==1);
    if isempty(current_flies)
        continue
    end

    % which of these are interacting
    current_interacting_flies = [find(~isnan(f.tracking_info.collision(:,f.current_frame)));...
        find(~isnan(f.tracking_info.overpassing(:,f.current_frame)))];

    % remove interacting flies
    current_flies(logical(sum(current_flies==current_interacting_flies',2))) = [];


    % get pxl list with all possible flies
    pxllistAll = fillFliesNReflections(f);

    if strcmp(f.antenna_type,'fixed')
        % go over these flies and measure the signal
        for flynum = 1:length(current_flies)
            this_fly = current_flies(flynum);
            xymat_antenna = getAntPxlList(f,this_fly,'fixed');
            if ~isempty(pxllistAll)
                % how much antenna overlaps with all possible reflections
                f.tracking_info.antenna1R_overlap(current_flies(flynum),f.current_frame) =  size(intersect(xymat_antenna,pxllistAll,'rows'),1)/size(xymat_antenna,1);
            end
        end


    elseif strcmp(f.antenna_type,'dynamic')
        % go over these flies and measure the signal
        for flynum = 1:length(current_flies)
            this_fly = current_flies(flynum);
            xymat_antenna = getAntPxlList(f,this_fly,'dynamic');
            if ~isempty(xymat_antenna)
                if ~isempty(pxllistAll)
                    % how much antenna overlaps with all possible reflections
                    f.tracking_info.antenna1R_overlap(current_flies(flynum),f.current_frame) =  size(intersect(xymat_antenna,pxllistAll,'rows'),1)/size(xymat_antenna,1);
                end
            end
        end

    end
    
end



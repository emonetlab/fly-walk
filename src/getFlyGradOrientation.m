function theta = getFlyGradOrientation(f,S)
% measure the gradient along the flies and return the orientation of the
% fly

if isstruct(S)
    % fix orientation between 0 and 180
    S.Orientation = mod(S.Orientation,360)*pi/180; %radians
    
    
    % obtain center position of the fly
    xc= S.Centroid(1);
    yc= S.Centroid(2);
    
    % convert angle into radian
    theta = S.Orientation;
    
    % form the rotation matrix
    R = [ cos(theta) sin(theta);...
        -sin(theta) cos(theta)];
    
    % for the inverse rotation matrix
    invR = [ cos(theta) -sin(theta);...
        sin(theta)  cos(theta)];
    
    %use the pixel list from fly props
    pxllist = S.PixelList;
    
    if isempty(pxllist)
        theta = [];
        disp('no pixels found for this object')
        return
    end
    
    
    % pre-allocate memory for zero centered fly
    pxllist0 = zeros(size(pxllist));
    
    
    % take the fly to origin, prepare for inverse rotation
    pxllist0(:,1) = pxllist(:,1) - round(xc);
    pxllist0(:,2) = pxllist(:,2) - round(yc);
    
    % inverse rotate the centroid. make its major axis paralel to x
    % axis
    pxll_invR = invR*pxllist0';
    pxll_invR = pxll_invR';
    
    % determine the unique x indexes
    C = unique(pxll_invR(:,1)); %C = A(ia) and A = C(ic).
    
    % get segment indices
    segmentx = round(linspace(min(C),max(C),f.n_of_segments+1));
    
    
    % initiate segment, fluorescence, and xlocation matrics and cell arrays
    xymatseg = cell(f.n_of_segments,1);
    fluoseg = zeros(f.n_of_segments,1);
    xseg = zeros(f.n_of_segments,1);
    
    % go over segments and measure the mean fluoresces
    for i= 1: f.n_of_segments
        
        % get pixel matrix to temporary memory
        tempmat = pxll_invR;
        
        % delete the pixels falling out of the segment
        tempmat(tempmat(:,1)<segmentx(i),:)=[];
        tempmat(tempmat(:,1)>segmentx(i+1),:)=[];
        
        % re-rotate the segment and orient it with fly
        temprot = R*tempmat';
        
        % add the offset so that the segment falls on the fly
        tempmatrot = zeros(size(temprot))';
        tempmatrot(:,1) = round(temprot(1,:) + xc)';
        tempmatrot(:,2) = round(temprot(2,:) + yc)';
        
        % store segment pixel list
        xymatseg{i} = tempmatrot;
        if (sum(tempmatrot(:,1)==0)>0)||sum(tempmatrot(:,2)==0)>0
            if f.ft_debug
                disp(['zero index calculated. Segment: ', num2str(i),'. Xbar: ', num2str(mean(tempmatrot(:,1))), '. Ybar: ', num2str(num2str(mean(tempmatrot(:,2))))])
            end
            tempmatrot(tempmatrot(:,2)==0,:)=[];
            tempmatrot(tempmatrot(:,1)==0,:)=[];
            if f.ft_debug
                disp('cleaned zeros')
            end
        end
        
        
        % measure the mean fluorescence on the segment
        fluoseg(i) = fluo_of_ellips_mask(tempmatrot,f.current_raw_frame);
        
        % what is the center x location of the segment
        xseg(i) = mean(tempmatrot(:,1));
        
        
    end
    
    
    
    % now calculate and assign the fly orientation
    segnum = find(fluoseg==min(fluoseg));
    if numel(segnum)==1
        pnt = [xc-mean(xymatseg{segnum}(:,1)),yc-mean(xymatseg{segnum}(:,2))];
        [theta,~] = cart2pol(pnt(1),pnt(2)); % radians
        
        theta = mod(theta/pi*180,360);
    else
        disp('There is not gradient on fly intensity')
        theta = [];
    end
    
elseif isnumeric(S)
    % reconstruct current objects
    if isempty(f.current_objects)
        f = reConstructCurrentObjetcs(f);
    end
    this_fly = S;
    if ismember(this_fly,f.current_object_status)
        S = f.current_objects;
        Stemp = S(f.current_object_status==this_fly);
        theta = getFlyGradOrientation(f,Stemp);
    else
        disp(['Could not find an object associated with fly: ',mat2str(this_fly)])
        theta = [];
    end
else
    disp('unknown case')
    keyboard
end
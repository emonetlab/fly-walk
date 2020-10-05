function f = getMedianFramePreStimulus(f,stimOntime)
% calculates the median frame as requested and saves as f.
% computed frame is median of the background subtracted frames before
% stimulus turns on

% is it saved previously?
if isfield(f.ExpParam,'MedianFramePreStimulus')
    disp('Pre-Stimulus Median frame is calculated previously. Using that one.')
    f.median_frame_prestim = f.ExpParam.MedianFramePreStimulus;
    return
end

if nargin ==1
    stimOntime = 1; % sec
end
a = 1;
z = round(stimOntime*f.ExpParam.fps);

% figure out the class of the matrix
if strcmp(f.videoType,'mat')
    dets = whos(f.path_name);
    M = zeros(size(f.path_name,f.variable_name,1),size(f.path_name,f.variable_name,2),...
        length(a:z),dets(strcmp(f.variable_name, {dets.name})).class);
    
    % read frames
    read_these_frames = a:z;
    for i = 1:length(read_these_frames)
        cf = read_these_frames(i);
        M(:,:,i) = f.path_name.(f.variable_name)(:,:,cf); % this is 10X faster than a direct assignation;
                                                          % don't drink from the for-loops-are-bad-kool-aid font
    end
    
    if f.subtract_background_frame && ~isempty(f.ExpParam.bkg_img)
        if f.apply_mask
            M = (M - f.ExpParam.bkg_img).*uint8(f.ExpParam.mask);
        else
            M = M - f.ExpParam.bkg_img;
        end
    end
    
    f.median_frame_prestim = median(M,3);
    
    % fill flies in the median frame
    n_dilate = 5;
    thresh = .2;
    f.median_frame_prestim = fillFlies(f.median_frame_prestim,n_dilate,thresh,f.min_fly_area);
    % save it into p
    
else
    M = zeros(f.path_name.Height,f.path_name.Width,length(a:z),'uint8');
    
    % read frames
    read_these_frames = a:z;
    if length(read_these_frames)>300
        read_these_frames = round(linspace(a,z,300));
    end
    hwb = waitbar(0,'Please wait while I am getting the median frame...');
    for i = 1:length(read_these_frames)
        cf = read_these_frames(i);
        f.path_name.CurrentTime = cf/f.path_name.FrameRate;
        M(:,:,i) = readFrame(f.path_name); % this is 10X faster than a direct assignation; 
                                         % don't drink from the for-loops-are-bad-kool-aid font
        waitbar(i / length(read_these_frames))
    end
    close(hwb)
    f.median_frame_prestim = median(M,3);
    % fill flies in the median frame
    n_dilate = 5;
    thresh = .2;
    f.median_frame_prestim = fillFlies(f.median_frame_prestim,n_dilate,thresh,f.min_fly_area);
end

% save the median frame to p
p = f.ExpParam;
p.MedianFramePreStimulus = f.median_frame_prestim;
if strcmp(f.videoType,'mat')
    if exist([f.path_name.Properties.Source(1:end-11),'.mat'],'file')
        save([f.path_name.Properties.Source(1:end-11),'.mat'],'p','-append');
    end
elseif strcmp(f.videoType,'avi')||strcmp(f.videoType,'mj2')
    if exist([f.path_name.Path,filesep,f.path_name.Name(1:end-4),'.mat'],'file')
        save([f.path_name.Path,filesep,f.path_name.Name(1:end-4),'.mat'],'p','-append');
    end
end
disp('Pre-Stimulus MedianFrame is saved into the original mat file');


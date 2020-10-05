function varargout = PIVFlyWalkFileClusterPar(filename,option)
% calculates the flow field by correlating the two consecutive frames.
% PIVlab (by William Thielicke) is utilized which is availabel at:
% https://www.mathworks.com/matlabcentral/fileexchange/27659-pivlab-time-resolved-particle-image-velocimetry--piv--tool
% On each frame shot noise is removed by applying a 15 pint 2D meadian
% filter. Flies are masked by thresholding and dilating by 35 points in
% order to avoid contibution of fly movement to flow field. After the flow
% field is estimated the points in the fly masks are interpolated using the
% estimated values. Finally, the mean flow direction and magnitude is
% estimated on the virtual antenna whcih is close to the fly head where
% Johnston's organ lives and measures the wind speed for the fly.
%
% written for Grace daily run. When re-reuncontinues from the last saved
% position
%
switch nargin
    case 2
        defOpts = {'PIV','PP','CFWS','STh'};
        assert(isstruct(option),['option has to be a structure with at least a field such as: ',strjoin(defOpts,'|')])
        match = zeros(numel(defOpts),length(fieldnames(option)));
        for i =1:numel(defOpts)
            match(i,:) = strcmp(defOpts{i},fieldnames(option));
        end
        if any(sum(match,1)) % there are matching fields,
            % which field is not matching
            fieldMissing = find(~sum(match,2));
            if isempty(fieldMissing)
                % all fields are suplied. do nothing
            else
                for j = 1:length(fieldMissing)
                    option.(defOpts{fieldMissing(j)}) = 0; % do not evaluate that option
                end
            end
        else
            error(['Option has non-relevant fields: ',strjoin(fieldnames(option),','),'. Please provide at least a field such as: ',strjoin(defOpts,'|')])
        end
    case 1
        option.PIV = 1; % do piv
        option.PP = 1; % post process
        option.CFWS = 1; % calculate wind speed at fly antenna
        option.STh = 1; % threshold the median filtered smoke for mask purposes
end

%% create the mat files and load the flywalk object
if exist([filename(1:end-4),'.flywalk'],'file')
    f = openFileFlyWalk(filename,0,0); % no gui, no random median frame subtraction
    f.subtract_prestim_median_frame = 1; % subtract prestimulus median frame
    m = f.path_name; % video matfile
else % start a flywalk file and set tracking to zero
    f = openFileFlyWalk(filename,0,0); % no gui, no random median frame subtraction
    f.subtract_prestim_median_frame = 1; % subtract prestimulus median frame
    f.track_movie = 0;
    m = f.path_name; % video matfile
end

%% Analyze the image with piv_FFTmulti
%
if option.PIV
    % Standard PIV Settings
    s = cell(10,2); % To make it more readable, let's create a "settings table"
    %Parameter                       %Setting           %Options
    s{1,1}= 'Int. area 1';           s{1,2}=64;         % window size of first pass
    s{2,1}= 'Step size 1';           s{2,2}=16;         % step of first pass
    s{3,1}= 'Subpix. finder';        s{3,2}=1;          % 1 = 3point Gauss, 2 = 2D Gauss
    s{4,1}= 'Mask';                  s{4,2}=[];         % If needed, generate via: imagesc(image); [temp,Mask{1,1},Mask{1,2}]=roipoly;
    s{5,1}= 'ROI';                   s{5,2}=[];         % Region of interest: [x,y,width,height] in pixels, may be left empty
    s{6,1}= 'Nr. of passes';         s{6,2}=3;          % 1-4 nr. of passes
    s{7,1}= 'Int. area 2';           s{7,2}=32;         % second pass window size
    s{8,1}= 'Int. area 3';           s{8,2}=16;         % third pass window size
    s{9,1}= 'Int. area 4';           s{9,2}=8;         % fourth pass window size
    s{10,1}='Window deformation';    s{10,2}='*spline'; % '*spline' is more accurate, but slower
    
    % Standard image preprocessing settings
    p = cell(8,1);
    %Parameter                       %Setting           %Options
    p{1,1}= 'ROI';                   p{1,2}=s{5,2};     % same as in PIV settings
    p{2,1}= 'CLAHE';                 p{2,2}=0;          % 1 = enable CLAHE (contrast enhancement), 0 = disable
    p{3,1}= 'CLAHE size';            p{3,2}=20;         % CLAHE window size
    p{4,1}= 'Highpass';              p{4,2}=0;          % 1 = enable highpass, 0 = disable
    p{5,1}= 'Highpass size';         p{5,2}=15;         % highpass size
    p{6,1}= 'Clipping';              p{6,2}=0;          % 1 = enable clipping, 0 = disable
    p{7,1}= 'Wiener';                p{7,2}=0;          % 1 = enable Wiener2 adaptive denaoise filter, 0 = disable
    p{8,1}= 'Wiener size';           p{8,2}=3;          % Wiener2 window size
    
    
    
    % set parameters for PIV
    parameters.median_filterA = 1;   % apply median filter to frame use B as A and save time
    parameters.median_filterB = 1;   % apply median filter to frame A
    parameters.medfiltsize = 15;    % 2d median filter size
    parameters.diln = 30;           % dilation number for generating fly mak
    parameters.thresh = 0.3;        % threshold percentage for generating fly mak
    parameters.minObjSize = 50;     % minimum object size for generating fly mak
    parameters.setFliestoZero = 0;  % set intensity in the fly mask to zero
    camera = f.ExpParam.camera;     % camera location
    parameters.camera = camera;     % put the camera in to the parameters as well
    parameters.s = s;               % setting for PIV process
    parameters.p = p;               % image pre-process parameters
    parameters.UseMask = 0;         % apply mask to images
    parameters.MaskType = 'binary'; % binary: use binary mask, else use cell of polygon points
    parameters.PostProcess = 1;     % remove speeds above and below the limits, interpolates missing vectors
    spdlim = 1000/f.ExpParam.fps/f.ExpParam.mm_per_px; % pxl/frm (calculated from mm/sec)
    parameters.PP.umin = -spdlim;   % minimum allowed u velocity
    parameters.PP.umax = spdlim;    % maximum allowed u velocity
    parameters.PP.vmin = -spdlim;   % minimum allowed v velocity
    parameters.PP.vmax = spdlim;    % maximum allowed v velocity
    parameters.PP.stdthresh=6;      % threshold for standard deviation check
    parameters.PP.epsilon=0.15;     % epsilon for normalized median test
    parameters.PP.thresh=3;         % threshold for normalized median test
    parameters.SmokeThreshold = 1;  % threshold for smoke reliability mask
    
    %% save the current parameters
    f.tracking_info.PIV.parameters = parameters;
    
else
    parameters = f.tracking_info.PIV.parameters;
    if option.STh
        parameters.SmokeThreshold = 1;  % threshold for smoke reliability mask
        f.tracking_info.PIV.parameters = parameters;
    end
end

%% first apply to frame 1 and 2 to get the matrix size
if option.PIV
    % get images, subtract background, mask and correct for the illumination
    A = ones(size(f.ExpParam.FlatNormImage));
    B = ones(size(f.ExpParam.FlatNormImage));
    [x,y,u,~,~,~,~] = pivImages(A,B,parameters);
    
    % initiate matrixes
    uMatrix = zeros([size(u),f.nframes]);
    
    % register the values to tracing info
    f.tracking_info.PIV.x = x;
    f.tracking_info.PIV.y = y;
    
    % initiate other variables
    vMatrix = uMatrix;
    uMatrix_filt = uMatrix; % filtered version
    vMatrix_filt = uMatrix; % filtered version
    
    % set initial flow to laminar flow
    uMatrix(:,:,1) = 160/f.ExpParam.fps/f.ExpParam.mm_per_px;  % pxl/frame
    
    % initiate mean wind direction and wind speed on tracking info
    f.tracking_info.meanWindDir = zeros(size(f.tracking_info.x));
    f.tracking_info.meanWindSpeed = zeros(size(f.tracking_info.x));
    
    % initiate the mask matrix
    SmokeThrMask = zeros(size(uMatrix),'uint8');
    
end

loopend = f.nframes;
bkgim = f.ExpParam.bkg_img;
maskim = uint8(f.ExpParam.mask);
medfrmps = f.median_frame_prestim;
imnorm = f.ExpParam.FlatNormImage;
dodebug = f.ft_debug;


%%
if option.PIV
    doPP = option.PP;
    doTh = option.STh;
    xv = f.tracking_info.PIV.x(1,:); % x positions
    yv = f.tracking_info.PIV.y(:,1); % x positions
    
    parfor frameNum = 2:loopend
        
        frm2 = frameNum;
        frm1 = frm2-1;
        if dodebug
            disp(['frame#:',num2str(frm2)])
        end
        
        A = double((m.frames(:,:,frm1)-bkgim).*maskim-medfrmps)./imnorm;
        B = double((m.frames(:,:,frm2)-bkgim).*maskim-medfrmps)./imnorm;
        
        
        if dodebug
            disp(['Estimating PIV on this frame#: ',num2str(frm2)])
        end
        [~,~,u,v,typevector,~,~] = pivImages(A,B,parameters);
        
        uMatrix(:,:,frameNum) = u;
        vMatrix(:,:,frameNum) = v;
        
        if doPP
            if dodebug
                disp('Validating and interpolatinng the spurious vectors...')
            end
            if parameters.PostProcess
                [u_filtered,v_filtered,~] = PostProcessPivResults(u,v,typevector,parameters);
            end
            uMatrix_filt(:,:,frameNum) = u_filtered;
            vMatrix_filt(:,:,frameNum) = v_filtered;
        end
        
        
        if doTh
            if dodebug
                disp('Estimating the smokeThreshMask for PIV on this frame')
            end
            
            BTh = ThreshImages4PIV(A,B,parameters);
            SmokeThrMask(:,:,frameNum) = getthismak(xv,yv,BTh);
        end
        
        if dodebug
            disp('----------------------------------------------------------------')
        end
    end
    
    % assign the variables to f
    f.tracking_info.PIV.uMatrix = uMatrix;
    f.tracking_info.PIV.vMatrix = vMatrix;
    if doPP
        f.tracking_info.PIV.uMatrix_filt = uMatrix_filt;
        f.tracking_info.PIV.vMatrix_filt = vMatrix_filt;
    end
    if doTh
        f.tracking_info.PIV.SmokeThrMask = SmokeThrMask;
    end
    
elseif option.PP
    
    uMatrix = f.tracking_info.PIV.uMatrix;
    vMatrix = f.tracking_info.PIV.vMatrix;
    uMatrix_filt = uMatrix; % filtered version
    vMatrix_filt = uMatrix; % filtered version
    
    doTh = option.STh;
    if doTh
        xv = f.tracking_info.PIV.x(1,:); % x positions
        yv = f.tracking_info.PIV.y(:,1); % y positions
        % initiate the mask matrix
        SmokeThrMask = zeros(size(uMatrix),'uint8');
    end
    
    parfor frameNum = 2:loopend
        
        u = uMatrix(:,:,frameNum);
        v = vMatrix(:,:,frameNum);
        
        frm2 = frameNum;
        frm1 = frm2-1;
        if dodebug
            disp(['frame#:',num2str(frm2)])
        end
        
        A = double((m.frames(:,:,frm1)-bkgim).*maskim-medfrmps)./imnorm;
        B = double((m.frames(:,:,frm2)-bkgim).*maskim-medfrmps)./imnorm;
        
        if dodebug
            disp('Validating and interpolating the spurious vectors...')
        end
        typevectorPP = getTypeVectorPIV(A,B,parameters);
        [u_filtered,v_filtered,~] = PostProcessPivResults(u,v,typevectorPP,parameters);
        
        uMatrix_filt(:,:,frameNum) = u_filtered;
        vMatrix_filt(:,:,frameNum) = v_filtered;
        
        if doTh
            if dodebug
                disp('Estimating the smokeThreshMask for PIV on this frame')
            end
            
            BTh = ThreshImages4PIV(A,B,parameters);
            SmokeThrMask(:,:,frameNum) = getthismak(xv,yv,BTh);
        end
        
        if dodebug
            disp('----------------------------------------------------------------')
        end
    end
    
    % assign the variables to f
    f.tracking_info.PIV.uMatrix_filt = uMatrix_filt;
    f.tracking_info.PIV.vMatrix_filt = vMatrix_filt;
    if doTh
        f.tracking_info.PIV.SmokeThrMask = SmokeThrMask;
    end
    
elseif option.STh
    xv = f.tracking_info.PIV.x(1,:); % x positions
    yv = f.tracking_info.PIV.y(:,1); % y positions
    SmokeThrMask = zeros(size(f.tracking_info.PIV.uMatrix),'uint8');
    
    parfor frameNum = 2:loopend
        
        frm2 = frameNum;
        frm1 = frm2-1;
        if dodebug
            disp(['frame#:',num2str(frm2)])
        end
        
        A = double((m.frames(:,:,frm1)-bkgim).*maskim-medfrmps)./imnorm;
        B = double((m.frames(:,:,frm2)-bkgim).*maskim-medfrmps)./imnorm;
        
        
        if dodebug
            disp('Estimating the smokeThreshMask for PIV on this frame')
        end
        
        BTh = ThreshImages4PIV(A,B,parameters);
        SmokeThrMask(:,:,frameNum) = getthismak(xv,yv,BTh);
        
        if dodebug
            disp('----------------------------------------------------------------')
        end
    end
    
    % assign the variables to f
    f.tracking_info.PIV.SmokeThrMask = SmokeThrMask;
    
end

if option.CFWS
    % measure wind speed in the virtual antenna
    for frameNum = 2:loopend
        if dodebug
            disp(['frame#:',num2str(frameNum)])
        end
        if dodebug
            disp('Interpolating the velocity around the antenna of each fly')
        end
        f = getMeanWindDirectionsOnThisFrame(f,frameNum);
    end
end


%% save the file
if f.ft_debug
    disp('Saving the flywalk file ...')
end
f.save;     % save the file

if nargout
    varargout = {f};
end

% ppool.delete;

end

function thismask = getthismak(x,y,BTh)
thismask = zeros(length(y),length(x));
for i = 1:length(x)
    for j = 1:length(y)
        thismask(j,i) = BTh(y(j),x(i));
    end
end

end







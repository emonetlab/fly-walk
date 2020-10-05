function varargout = PIVFlyWalkFileClusterDay(filename)
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

%% create the mat files and load the flywalk object
m = matfile([filename(1:end-4),'-frames.mat']);
% f = load([filename(1:end-4),'.flywalk'],'-mat');
f = openFileFlyWalk(filename,0,0); % no gui, no random median frame subtraction
%% go over the frames and get the flow fields


% was this file processed and saved previously
if isfield(f.tracking_info,'PIV') % yes it was processed and saved
    % continue from the frame where it was left off
    startframe = f.current_frame + 1;
    % take out the parameters from the structure
    parameters = f.tracking_info.PIV.parameters;
    
    if f.current_frame == f.nframes
        return
    end
    
else
%% Analyze the image with piv_FFTmulti
% 
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
parameters.diln = 17;           % dilation number for generating fly mak
parameters.thresh = 0.3;        % threshold percentage for generating fly mak
parameters.minObjSize = 50;     % minimum object size for generating fly mak
parameters.setFliestoZero = 0;  % set intensity in the fly mask to zero
camera = f.ExpParam.camera;     % camera location
parameters.camera = camera;     % put the camera in to the parameters as well
parameters.s = s;               % setting for PIV process
parameters.p = p;               % image pre-process parameters
parameters.UseMask = 1;         % apply mask to images
parameters.MaskType = 'binary'; % binary: use binary mask, else use cell of polygon points
parameters.PostProcess = 1;     % remove speeds above and below the limits, interpolates missing vectors
spdlim = 1000/f.ExpParam.fps/f.ExpParam.mm_per_px; % pxl/frm (calculated from mm/sec)
parameters.PP.umin = 0;         % minimum allowed u velocity
parameters.PP.umax = spdlim;    % maximum allowed u velocity
parameters.PP.vmin = -spdlim;   % minimum allowed v velocity
parameters.PP.vmax = spdlim;    % maximum allowed v velocity
parameters.PP.stdthresh=6;      % threshold for standard deviation check
parameters.PP.epsilon=0.15;     % epsilon for normalized median test
parameters.PP.thresh=3;         % threshold for normalized median test

%% save the current parameters
f.tracking_info.PIV.parameters = parameters;

%% first apply to frame 1 and 2 to get the matrix size
frm1 = 1;
frm2 = 2;

% get images, subtract background, mask and correct for the illumination
A = double((m.frames(:,:,frm1)-f.ExpParam.bkg_img).*uint8(f.ExpParam.mask)-f.median_frame_prestim)./f.ExpParam.FlatNormImage;
B = double((m.frames(:,:,frm2)-f.ExpParam.bkg_img).*uint8(f.ExpParam.mask)-f.median_frame_prestim)./f.ExpParam.FlatNormImage;



if f.ft_debug
    disp(['Estimating PIV on frame#:',num2str(frm2)])
end
[x,y,u,~,~,A,~] = pivImages(A,B,parameters);
parameters.median_filterA = 0;   % apply median filter to frame use B as A and save time
f.tracking_info.PIV.parameters.median_filterA = 0;   % apply median filter to frame use B as A and save time

% save A for reuse
f.tracking_info.PIV.A = A;

% initiate matrixes
uMatrix = zeros([size(u),f.nframes]);

% register the values to tracing info
f.tracking_info.PIV.x = x;
f.tracking_info.PIV.y = y;

% set initial flow to laminar flow
uMatrix(:,:,1) = 160/f.ExpParam.fps/f.ExpParam.mm_per_px;  % pxl/frame

% put the matrices into f
f.tracking_info.PIV.uMatrix = uMatrix;
f.tracking_info.PIV.vMatrix = uMatrix;
f.tracking_info.PIV.uMatrix_filt = uMatrix; % filtered version
f.tracking_info.PIV.vMatrix_filt = uMatrix; % filtered version


% initiate mean wind direction and wind speed on tracking info
f.tracking_info.meanWindDir = zeros(size(f.tracking_info.x));
f.tracking_info.meanWindSpeed = zeros(size(f.tracking_info.x));

% start frame will be from beginning
startframe = 2;

end

%% save the flywalk file at every given period
saveiter = 100;  % save it at every saveiter iterations

%%
tpframesum = 0;
iternum = 1;
totelaptime = 0;
for frameNum = startframe:f.nframes
    tic
%     frm1 = frameNum-1;
    frm2 = frameNum;
    if f.ft_debug
        disp(['frame#:',num2str(frm2)])
    end
    % set current frame to frm2
    f.current_frame = frm2;
    % get images, subtract background, mask and correct for the illumination
%     A =
%     double((m.frames(:,:,frm1)-f.ExpParam.bkg_img).*uint8(f.ExpParam.mask)-f.median_frame_prestim)./f.ExpParam.FlatNormImage;
%     it is already done
    % use the saved one
    A = f.tracking_info.PIV.A;
    B = double((m.frames(:,:,frm2)-f.ExpParam.bkg_img).*uint8(f.ExpParam.mask)-f.median_frame_prestim)./f.ExpParam.FlatNormImage;
    

    if f.ft_debug
        disp('Estimating PIV on this frame')
    end
    [~,~,u,v,typevector,~,B] = pivImages(A,B,parameters);
    
    % save B to be used as A
    % save B as A for the next frame
    f.tracking_info.PIV.A = B;
    
    if f.ft_debug
        disp('Validating and interpolatinng the spurious vectors...')
    end
    if parameters.PostProcess
        [u_filtered,v_filtered,~] = PostProcessPivResults(u,v,typevector,parameters);
    end
    
    f.tracking_info.PIV.uMatrix(:,:,frameNum) = u;
    f.tracking_info.PIV.vMatrix(:,:,frameNum) = v;
    f.tracking_info.PIV.uMatrix_filt(:,:,frameNum) = u_filtered;
    f.tracking_info.PIV.vMatrix_filt(:,:,frameNum) = v_filtered;
    
    if f.ft_debug
        disp('Interpolating the velocity around the antenna of each fly')
    end
    
    f = getMeanWindDirectionsOnThisFrame(f,frameNum);
    tpassed = toc;
    tpframesum = tpframesum + tpassed;
    tpframe = tpframesum/iternum;
    iternum = iternum+1;
    estremtime = (f.nframes-frameNum)*tpframe;
    totelaptime = totelaptime + tpassed;
    if f.ft_debug
        disp(['Total elapsed Time: ',t2str(totelaptime),' - Estimated remaining Time: ',t2str(estremtime)])
    end
     
    if mod(frameNum,saveiter)==0
        if f.ft_debug
            disp('Saving the flywalk file....')
        end
        f.save;     % save the file
    end
    
    if f.ft_debug
        disp('----------------------------------------------------------------')
    end
end


%% save the file
if f.ft_debug
    disp('Saving the flywalk file one last time...')
end
f.save;     % save the file

if nargout
    varargout = {f};
end



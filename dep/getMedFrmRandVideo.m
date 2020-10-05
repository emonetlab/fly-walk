function MedFrmRand = getMedFrmRandVideo(videofileName,n,rem_bkg_img,options)
%getMedFrmRandVideo
% MedFrmRand = getMedFrmRand(frames,n,rem_bkg_img,options)
% Retuns the median frame of n randomly drawn frames.
% By default background is subtracted
% If number of frame to be randomly drawn is not specified, it calculates
% 1/40 of total number of frames
% Input frames can be a path to the frames file or actual 3D frames matrix
% Pass options with field 'skipEndSeconds' defining the seconds to be
% omitted at the beginning and end of the video. This option can only
% be used with file path inputs.
% This function uses the video file instead of -frames.mat file.
%

% is it a filename or a matrix of frames
switch nargin
    case 3
        options = [];   % no extra conntsraints
    case 2
        options = [];   % no extra conntsraints
        rem_bkg_img = 1;% remove bkg_img
    case 1
        options = [];   % no extra conntsraints
        rem_bkg_img = 1;% remove bkg_img
end


% create the video object
assert(exist(videofileName,'file') == 2,'Expected a file path!')
m = VideoReader(videofileName);
nFrames = round(m.Duration*m.FrameRate);
% is this the correct file
load([videofileName(1:end-4),'.mat'],'p');

% if saved before just return it
if isfield(p,'MedianFrameRandom')
    disp('Ramdom median frame is saved before. Using the saved one...')
    MedFrmRand = p.MedianFrameRandom;
    return
end

videoHeight = m.Height;
videoWidth = m.Width;
if nargin==1
    n = round(nFrames/40); % draw n random frames
    if n>300
        n = 300;
    end
    if n ==0
        n = ceil(nFrames/3);
    end
end

if isfield(options,'skipEndSeconds')
    skipsec = options.skipEndSeconds;
    nFramesskip = round(skipsec*p.fps);
    medfrmind = randi([nFramesskip nFrames-nFramesskip],1,n);
else
    medfrmind = randi(nFrames,1,n);
end
medframe = zeros(videoHeight,videoWidth,n,'uint8');
fc=1;
hwb = waitbar(0,'Please wait while I am getting the randomized median frame...');
for ii = medfrmind
    m.CurrentTime = (ii-1)/m.FrameRate;
    medframe(:,:,fc) = readFrame(m);
    fc = fc+1;
    waitbar(fc / length(medfrmind))
end
close(hwb)

if rem_bkg_img
    medframe = medframe - uint8(p.bkg_img);
end

MedFrmRand = median(medframe,3);

% save the median frame to p
p.MedianFrameRandom = MedFrmRand;
save([videofileName(1:end-4),'.mat'],'p','-append');
disp('MedianFrameRandom is saved to p')


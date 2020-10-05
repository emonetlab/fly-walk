function MedFrmRand = getMedFrmRand(frames,n,rem_bkg_img,options)
%getMedFrmRand
% MedFrmRand = getMedFrmRand(frames,n,rem_bkg_img,options)
% Retuns the median frame of n randomly drawn frames.
% By default background is subtracted
% If number of frame to be randomly drawn is not specified, it calculates
% 1/40 of total number of frames
% Input frames can be a path to the frames file or actual 3D frames matrix
% Pass options with field 'skipEndSeconds' defining the seconds to be
% omitted at the beginning and end of the video. This option can only
% be used with file path inputs
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

if ischar(frames)
    % create the matfile
    % is this the correct file
    if isempty(who('-file',frames,'frames'))
        % create matfile by appending -frames
        m = matfile([frames(1:end-4),'-frames.mat']);
        p = load(frames,'p');
        p = p.p;
    else
        % create matfile directl
        m =  matfile(frames);
        p = load([frames(1:end-11),'.mat'],'p');
        p = p.p;
    end
    
    % if saved before just return it
    if isfield(p,'MedianFrameRandom')
        disp('Ramdom median frame is saved before. Using the saved one...')
        MedFrmRand = p.MedianFrameRandom;
        return
    end
    
    [r,c,nfrm] = size(m,'frames');
    if nargin==1
        n = round(nfrm/40); % draw n random frames
        if n>300
            n = 300;
        end
        if n ==0
            n = ceil(nfrm/3);
        end
    end
    
    if isfield(options,'skipEndSeconds')
        skipsec = options.skipEndSeconds;
        nfrmskip = round(skipsec*p.fps);
        medfrmind = randi([nfrmskip nfrm-nfrmskip],1,n);
    else
        medfrmind = randi(nfrm,1,n);
    end
    medframe = zeros(r,c,n,'uint8');
    fc=1;
    for ii = medfrmind
        medframe(:,:,fc)=m.frames(:,:,ii);
        fc = fc+1;
    end
    if rem_bkg_img
        medframe = medframe - uint8(p.bkg_img);
    end
else
    nfrm = size(frames,3);
    if nargin==1
        n = round(nfrm/40); % draw n random frames
        if n ==0
            n = ceil(nfrm/3);
        end
    end
    
    medfrmind = randi(size(frames,3),1,n);
    medframe = frames(:,:,medfrmind);
end

MedFrmRand = median(medframe,3);

% save the median frame to p
p.MedianFrameRandom = MedFrmRand;
if isempty(who('-file',frames,'frames'))
    save(frames,'p','-append');
else
    save([frames(1:end-11),'.mat'],'p','-append');
end
disp('MedianFrameRandom is saved to p')


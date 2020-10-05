function bkg_img = GetBkgImg(frames,moviefile,p,fillFlies)
%% check for background video and load if exist
if nargin==3
    fillFlies = true; % fill flies in the backgorund image
end
[pathstr,fname,ext] = fileparts(moviefile);
expname = strsplit(fname,'_');
if length(expname)<6
    expname =strjoin(expname(:),'_');
else
    expname = strjoin(expname(1:6),'_');
end
expbckname = fullfile(pathstr,[expname,'*bck',ext]);
bckfile = dir(expbckname);

%check if there is only one
if numel(bckfile)>1
    error(['there are more than 1 bck video for ',expname])
end
if ~isempty(bckfile)
    disp('Loading background video');
    [~,bckframes] = ImportVidMat([pathstr,filesep,bckfile.name]);
    disp('Background video is loaded');
end

%% average a few seconds for background image
% average images
if ~isempty(bckfile)
    bkg_img = zeros(size(bckframes(:,:,1)));
    for ii = 1:size(bckframes,3)
        bkg_img = bkg_img + double(uint8(bckframes(:,:,ii)));
    end
    bkg_img = uint8(bkg_img/size(bckframes,3));
    disp('averaged bck video for subtraction');
    
    
else
    if ~isempty(frames)
        bkg_img = zeros(size(frames(:,:,1:round(p.fps):end)));
        fc=1;
        for ii = 1:round(p.fps):size(frames,3)
            bkg_img(:,:,fc)=frames(:,:,ii);
            fc = fc+1;
        end
        bkg_img = median(bkg_img,3);
    else
        % open video read frames at every second and get the meadian
        %check the file extension
        [~,~,ext] = fileparts(moviefile);
        if strcmp(ext,'.avi')|| strcmp(ext,'.mj2')
            
            vidobj = VideoReader(moviefile);
            nFrames = vidobj.Duration*vidobj.FrameRate;
            theseFrames = 1:round(p.fps):nFrames;
            if length(theseFrames)>300
                disp(['Video is ',num2str(length(1:round(p.fps):nFrames)), ' sec long'])
                disp('will get 300 regular points instead')
                theseFrames = round(linspace(1,nFrames,300));
            end
                
            bkg_img = zeros(vidobj.height,vidobj.width,length(theseFrames),'uint8');
            fc=1;
            for ii = theseFrames
                disp(['reading frame:', num2str(fc), '/' ,num2str(length(theseFrames))])
                bkg_img(:,:,fc) = read(vidobj,ii);
                fc = fc+1;
            end
            bkg_img = median(bkg_img,3);
            
            if  fillFlies
                % now threshold flies and fill them by inward interpolation
                if exist('regionfill','builtin')
                    threshold_fl = 0.5;
                    Ifliesav = im2bw(bkg_img,threshold_fl); % Thresholding flies from the frame.
                    Ifliesav = imdilate(Ifliesav,strel('disk',10));
                    bkg_img = regionfill(bkg_img,Ifliesav);
                    disp('Flies are thresholded (0.5) and filled by interpolation');
                end
            end
            disp('median pixel value at each second is registered ad background');
            
        end
    end
end



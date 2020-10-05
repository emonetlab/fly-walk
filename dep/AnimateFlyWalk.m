function AnimateFlyWalk(filepath,trjnum,frmnum,dispw,savename,tail_len,showtracks,resmag,RecFrmRate,SmthLen,BoxSize)

%AnimateFlyWalk   Animate the fly trajectory.
%   AnimateFlyWalk(filepath) generates the video with colored trajectories
%
%   AnimateFlyWalk(filepath,trjnum) generates a video in which the fly whose
%   trajectory number is given as trjnum. The video displays the arena and
%   selected fly with its trajector, and the speed, signal and rotational
%   speed in separate plots. Zoomed up fly is also shown in a subpanel.
%
%   AnimateFlyWalk(filepath,trjnum,frmnum,dispw,savename,showtracks,resmag,RecFrmRate,BckRem,SmthLen,BoxSize)
%
%   AnimateFlyWalk(filepath,5,50:333) animates the trajectory 5 in filepath
%   between frames of 50 and 333.
%
%   AnimateFlyWalk(filepath,'all') animates all trajectories on the main
%   frame. Generates only the walking arena. No other property (speed,
%   signal, orientation) will be showed.
%
%   AnimateFlyWalk(filepath,5,'5:.01:10',3) animates the trajectory 5 in filepath
%   between 5 and 10 seconds with a step size of 0.1 sec. Display window
%   size is set to 3 seconds. Accepts time range as '5:10sec', or '5:1:20s'.
%
%   AnimateFlyWalk(filepath,'all',1:155,0,'myvdieo') animates all trajectories
%   between frames 1 and 155 and saves the generated video in the current
%   working directory with name 'myvideo.avi'
%
%   resmag defines the resolution of the saved video. default is 2x native
%   resolution. give a positive real number to increase or decrease the
%   saved video resolution.
%
%   RecFrameRate defines the frame rate of the saved video. Default is the
%   input (exprimental) frame rate given in filepath.
%
%   BckRem = 1: removes the background image given as bkg_img in filepath. ):
%   showes the original image without the background substraction
%
%   Smthlen: is the boxcar smoothing length used to plot speed, signal and
%   rotational speed curves. Default is 3
%
%   Boxsize: cropping box size for fly of interest. Default is 100 pxls.
%
%   Written by Mahmut Demir, March 1st 2016
%

switch nargin
    case 10
        BoxSize= 100; % default box size for cropped fly
    case 9
        BoxSize= 100; % default box size for cropped fly
        SmthLen = 3;   % default smooth length for displying data
    case 8
        BoxSize= 100; % default box size for cropped fly
        SmthLen = 3;   % default smooth length for displying data
        RecFrmRate = [];    % use video frame rate
    case 7
        BoxSize= 100; % default box size for cropped fly
        SmthLen = 3;   % default smooth length for displying data
        RecFrmRate = [];    % use video frame rate
        resmag = 2;     % capture images with 2x native resolution
    case 6
        BoxSize= 100; % default box size for cropped fly
        SmthLen = 3;   % default smooth length for displying data
        RecFrmRate = [];    % use video frame rate
        resmag = 2;     % capture images with 2x native resolution
        showtracks = 1; %show tracks by default
    case 5
        BoxSize= 100; % default box size for cropped fly
        SmthLen = 3;   % default smooth length for displying data
        RecFrmRate = [];    % use video frame rate
        resmag = 2;     % capture images with 2x native resolution
        showtracks = 1; %show tracks by default
        tail_len = 'Inf';   % plot the whole track
    case 4
        BoxSize= 100; % default box size for cropped fly
        SmthLen = 3;   % default smooth length for displying data
        RecFrmRate = [];    % use video frame rate
        resmag = 2;     % capture images with 2x native resolution
        showtracks = 1; %show tracks by default
        tail_len = 'Inf';   % plot the whole track
        savename = '';  % do not save the video (default)
    case 3
        BoxSize= 100; % default box size for cropped fly
        SmthLen = 3;   % default smooth length for displying data
        RecFrmRate = [];    % use video frame rate
        resmag = 2;     % capture images with 2x native resolution
        showtracks = 1; %show tracks by default
        tail_len = 'Inf';   % plot the whole track
        savename = '';  % do not save the video (default)
        dispw = '';  % (sec) do not slide and move the display window
    case 2
        BoxSize= 100; % default box size for cropped fly
        SmthLen = 3;   % default smooth length for displying data
        RecFrmRate = [];    % use video frame rate
        resmag = 2;     % capture images with 2x native resolution
        showtracks = 1; %show tracks by default
        tail_len = 'Inf';   % plot the whole track
        savename = '';  %(default) do not save the video
        dispw = '';  % (sec) do not slide and move the display window
        frmnum = 'all'; %(default) display all frames as a video
    case 1
        BoxSize= 100; % default box size for cropped fly
        SmthLen = 3;   % default smooth length for displying data
        RecFrmRate = [];    % use video frame rate
        resmag = 2;     % capture images with 2x native resolution
        showtracks = 1; %show tracks by default
        tail_len = 'Inf';   % plot the whole track
        savename = '';  %(default) do not save the video
        dispw = '';  % (sec) do not slide and move the display window
        frmnum = 'all'; %(default) display all frames as a video
        trjnum = 'all'; %(default) display all trajectories in the main
        % arena window. Spped, signal etc will not be shown
    otherwise
        help AnimateFlyWalk
        disp('Not enough input arguments. Please specify the video data...');
end

% buffer window set for sliding plot window
bufwset = 3;

if ischar(filepath)
    % parse filpath for title
    [~,fntitle,~] = fileparts(filepath);
    
    % load the flywalk file
    %     f = openFlyWalkFile([filepath(1:end-4),'.flywalk'],0,0);
    f = openFileFlyWalk(filepath,0,0);
elseif isa(filepath,'flyWalk')
    f = filepath;
    % get the filename
    [~,flnm,~]=fileparts(f.path_name.Properties.Source);
    fntitle = flnm(1:end-7);
else
    error('either the path is wrong or a filewalk objest is not given')
end
p = f.ExpParam;



% pull out the first frame and look at the boundaries
f.current_frame = 1;
f.operateOnFrame;
I = f.current_raw_frame;
[ybound, xbound] = size(I);

% how many tracks are there in total
ntracks = find(f.tracking_info.fly_status(:,end)>0,1,'last');

% determine figure resolution
if resmag<0 % magnification cannot be negative
    resmag = 2; % use the default value
end
figres = ['-m',num2str(resmag)];

if strcmp(trjnum,'all')
    % determine min and max trajectory times
    max_t = f.nframes/p.fps;
    min_t = 1/p.fps;
    
end

% determine the looprange
% if all trajectories are requested skip this
if ~strcmp(trjnum,'all')
    framef = find(f.tracking_info.fly_status(trjnum,:)==1,1,'first');
    framel = find(f.tracking_info.fly_status(trjnum,:)==1,1,'last');
    if ischar(frmnum)
        % play all frames
        if strcmp(frmnum,'all')
            frmnum = framef:framel;
        elseif strcmp(frmnum,'end')
            frmnum = framel;
        elseif strcmp(frmnum(end-2:end),'sec')
            frmnum = frmnum(1:end-3);
            frmnum = round(str2num(frmnum)*p.fps);
        elseif strcmp(frmnum(end),'s')
            frmnum = frmnum(1:end-1);
            frmnum = round(str2num(frmnum)*p.fps);
        else
            frmnum = round(str2num(frmnum)*p.fps);
        end
        % correct for over fine time step
        frmnum = nonzeros(unique(frmnum));
    else
        % adjust the frame start
        frmnum = nonzeros(framef + frmnum - 1);
    end
    % now heck whether longer than track length is requested
    if isnumeric(trjnum)&&(frmnum(end)>framel)
        if (frmnum(1)>framel) % plot only the last point
            looprange = framel;
        else
            frmind=find(frmnum<=framel,1,'last');
            if isempty(frmind)
                looprange = frmnum(1):framel;
            else % set the last value to length limit
                looprange = frmnum(1:frmind);
            end
        end
    elseif isnumeric(trjnum)&&(frmnum(1)<framef)
        if (frmnum(end)<framef) % plot only the first
            looprange = framef;
        else
            frmind=find(frmnum>=framef,1,'first');
            if isempty(frmind)
                looprange = framef:framel;
            else % set the last value to length limit
                looprange = frmnum(frmind:end);
            end
        end
    else
        looprange = frmnum;
    end
else
    framef = min_t*p.fps;
    framel = max_t*p.fps;
    if ischar(frmnum)
        % play all frames
        if strcmp(frmnum,'all')
            frmnum = framef:framel;
        elseif strcmp(frmnum,'end')
            frmnum = framel;
        elseif strcmp(frmnum(end-2:end),'sec')
            frmnum = frmnum(1:end-3);
            frmnum = round(str2num(frmnum)*p.fps);
        elseif strcmp(frmnum(end),'s')
            frmnum = frmnum(1:end-1);
            frmnum = round(str2num(frmnum)*p.fps);
        else
            frmnum = round(str2num(frmnum)*p.fps);
        end
    else
        % adjust the frame start
        frmnum = framef + frmnum - 1;
    end
    % now heck whether longer than track length is requested
    if isnumeric(trjnum)&&(frmnum(end)>framel)
        if (frmnum(1)>framel) % plot only the last point
            looprange = framel;
        else
            frmind=find(frmnum<=framel,1,'last');
            if isempty(frmind)
                looprange = frmnum(1):framel;
            else % set the last value to length limit
                looprange = frmnum(1:frmind);
            end
        end
    elseif isnumeric(trjnum)&&(frmnum(1)<framef)
        if (frmnum(end)<framef) % plot only the first
            looprange = framef;
        else
            frmind=find(frmnum>=framef,1,'first');
            if isempty(frmind)
                looprange = framef:framel;
            else % set the last value to length limit
                looprange = frmnum(frmind:end);
            end
        end
    else
        looprange = frmnum;
    end
    
end

% if looprange is column make it row
if iscolumn(looprange)
    looprange = looprange';
end


% open the figure
h = figure('units','normalized','outerposition',[0 0 .7 .8]);
% initiate video recording
if ~isempty(savename)
    writerObj = VideoWriter([savename, ' - Traj# ', num2str(trjnum),'.avi']);
    if isempty(RecFrmRate)
        writerObj.FrameRate = p.fps;
    else
        writerObj.FrameRate = RecFrmRate;
    end
    open(writerObj);
end

% determine if all trajectory mode is called
if strcmp(trjnum,'all')
    % is not coded properly work on that
    
    if showtracks==1
        % construct trajectory matrix
        trajx_mat = (f.tracking_info.x-p.source.x)*p.mm_per_px;
        trajy_mat = (f.tracking_info.y-p.source.y)*p.mm_per_px;
    end
    
    for i = looprange
        f.current_frame = i;
        f.operateOnFrame;
        img_now = f.current_raw_frame;
        figure(h)
        % full image and trajectory
        imagesc([1 xbound]*p.mm_per_px-p.source.x*p.mm_per_px,[1 ybound]*p.mm_per_px-p.source.y*p.mm_per_px,img_now)
        %                                 imagesc([1 xbound]*p.mm_per_px-p.source.x*p.mm_per_px,[1 ybound]*p.mm_per_px-p.source.y*p.mm_per_px,adapthisteq(img_now))
        colormap(buildcmap('wkkcccb'));
        
        if ~showtracks
            xlabel('mm')
            ylabel('mm')
            set(gca,'YDir','reverse');
            title([fntitle,'      t: ',num2str(i/p.fps,'%5.2f') ' sec'],'Interpret','None')
        end
        
        if showtracks==1
            hold on
            
            if length(looprange)==1
                hold on
                
                for k = 1:ntracks
                    plot(trajx_mat(1:i,k),trajy_mat(1:i,k),'Linewidth',2);
                end
            else
                if isnumeric(tail_len)
                    if (i-looprange(1))<=tail_len
                        for k = 1:ntracks
                            plot(trajx_mat(looprange(1):i,k),trajy_mat(looprange(1):i,k),'Linewidth',2);
                        end
                    elseif (i-looprange(1))>tail_len
                        for k = 1:ntracks
                            plot(trajx_mat(i-tail_len:i,k),trajy_mat(i-tail_len:i,k),'Linewidth',2);
                        end
                    end
                else
                    for k = 1:ntracks
                        plot(trajx_mat(looprange(1):i,k),trajy_mat(looprange(1):i,k),'Linewidth',2);
                    end
                end
            end
            
            axis equal
            xlabel('mm')
            ylabel('mm')
            set(gca,'YDir','reverse');
            title([fntitle,'      t: ',num2str(i/p.fps,'%5.2f') ' sec'],'Interpret','None')
            xlim([1 xbound]*p.mm_per_px-p.source.x*p.mm_per_px)
            ylim([1 ybound]*p.mm_per_px-p.source.y*p.mm_per_px)
            hold off
        end
        
        pause(.001)
        if ~isempty(savename)
            %                 frame = getframe(h);
            [frame,~] = export_fig(h,'-nocrop',figres);
            %                 fimg = getimage(h);
            %                 map = colormap(getimage(h));
            %                 frame = im2frame(fimg,map);
            writeVideo(writerObj,frame);
        end
    end
    
    
    
    
else
    % animate a single trajectory
    for k = trjnum
        framef = find(f.tracking_info.fly_status(k,:)==1,1,'first');
        framel = find(f.tracking_info.fly_status(k,:)==1,1,'last');
        signal = smooth(f.tracking_info.signal(k,:),SmthLen);
%         dtheta = angleDiffVec(smooth(f.tracking_info.orientation(k,:),SmthLen))';
%         dtheta = [0,dtheta];
        thetavec = smoothOrientation(f.tracking_info.orientation(k,:),SmthLen);
        dtheta = anglediffCentral(thetavec)';
        dx = diffCentral(f.tracking_info.x(k,:));
        dy = diffCentral(f.tracking_info.y(k,:));
        speed = sqrt(dx.^2+dy.^2);
        rotspeed = smooth(dtheta,SmthLen)*p.fps;
        speed = smooth(speed,SmthLen)*p.mm_per_px*p.fps;
        
        
        for i = looprange
            
            f.current_frame = i;
            f.operateOnFrame;
            img_now = f.current_raw_frame;
            figure(h)
            % full image and trajectory
            subtightplot(9,11,[1:5,12:16,23:27,34:38,45:49],[0.01 0.01], [0.1 0.1], [0.01 0.01])
            %                 imagesc([1 xbound]*p.mm_per_px-p.source.x*p.mm_per_px,[1 ybound]*p.mm_per_px-p.source.y*p.mm_per_px,adapthisteq(img_now))
            imagesc([1 xbound]*p.mm_per_px-p.source.x*p.mm_per_px,[1 ybound]*p.mm_per_px-p.source.y*p.mm_per_px,img_now)
            colormap(buildcmap('wkkcccb'));
            hold on
            
            if length(looprange)==1
                plot((f.tracking_info.x(k,1:i)-p.source.x)*p.mm_per_px,(f.tracking_info.y(k,1:i)-p.source.y)*p.mm_per_px,'r','LineWidth',2);
            else
                plot((f.tracking_info.x(k,looprange(1):i)-p.source.x)*p.mm_per_px,(f.tracking_info.y(k,looprange(1):i)-p.source.y)*p.mm_per_px,'r','LineWidth',2);
            end
            
            THETA = f.tracking_info.orientation(k,i)/180*pi;
            RHO = f.tracking_info.majax(k,i)/2;
            [X,Y] = pol2cart(THETA,RHO);
            xpair = ([f.tracking_info.x(k,i),f.tracking_info.x(k,i)+X]-p.source.x)*p.mm_per_px;
            ypair = ([f.tracking_info.y(k,i),f.tracking_info.y(k,i)+Y]-p.source.y)*p.mm_per_px;
            arrowhead(xpair,ypair,'r',[.1 .1],2);
            THETA = f.tracking_info.orientation(k,framef)/180*pi;
            RHO = f.tracking_info.majax(k,framef)/2;
            [X,Y] = pol2cart(THETA,RHO);
            xpair = ([f.tracking_info.x(k,framef),f.tracking_info.x(k,framef)+X]-p.source.x)*p.mm_per_px;
            ypair = ([f.tracking_info.y(k,framef),f.tracking_info.y(k,framef)+Y]-p.source.y)*p.mm_per_px;
            arrowhead(xpair,ypair,'b',[.1 .1],2);
            axis equal
            set(gca,'YDir','reverse');
            title([fntitle,'      trj#: ' num2str(k)],'Interpret','None')
            
            xlim([1 xbound]*p.mm_per_px-p.source.x*p.mm_per_px)
            ylim([1 ybound]*p.mm_per_px-p.source.y*p.mm_per_px)
            hold off
            
            
            % orinetation histogram
            figure(h)
            subtightplot(9,11,[17:19,28:30,39:41],[0.01 0.01], [0.1 0.1], [0.01 0.01])
            if length(looprange)==1
                [T,R] = rose(-f.tracking_info.orientation(k,1:i)/180*pi,72);% returns the vectors T and R such that
            else
                [T,R] = rose(-f.tracking_info.orientation(k,looprange(1):i)/180*pi,72);% returns the vectors T and R such that
            end
            
            polar(T,R)
            title('Orientation')
            
            
            % cropped fly with arrow and antenna pixels
            figure(h)
            subtightplot(9,11,[20:22,31:33,42:44],[0.01 0.01], [0.1 0.1], [0.01 0.01])
            flypos = [f.tracking_info.x(k,i),f.tracking_info.y(k,i)];
            [bymin,bymax,bxmin,bxmax] = getFlyBox(BoxSize,img_now,flypos);
            imagesc([bxmin bxmax]*p.mm_per_px-p.source.x*p.mm_per_px,[bymin bymax]*p.mm_per_px-p.source.y*p.mm_per_px,(img_now(bymin:bymax,bxmin:bxmax)))
            %                                 imagesc([bxmin bxmax]*p.mm_per_px-p.source.x*p.mm_per_px,[bymin bymax]*p.mm_per_px-p.source.y*p.mm_per_px,adapthisteq(img_now(bymin:bymax,bxmin:bxmax)))
            colormap(buildcmap('wkkcccb'));
            hold on
            
            THETA = f.tracking_info.orientation(k,i)/180*pi;
            RHO = f.tracking_info.majax(k,i)/2;
            [X,Y] = pol2cart(THETA,RHO);
            xpair = ([f.tracking_info.x(k,i),f.tracking_info.x(k,i)+X]-p.source.x)*p.mm_per_px;
            ypair = ([f.tracking_info.y(k,i),f.tracking_info.y(k,i)+Y]-p.source.y)*p.mm_per_px;
            arrowhead(xpair,ypair,'r',[2.5 2.5],1);
            
            axis equal
            set(gca,'YDir','reverse');
            title([num2str(i/p.fps,'%5.2f') ' sec'])
            xlim([bxmin bxmax]*p.mm_per_px-p.source.x*p.mm_per_px)
            ylim([bymin bymax]*p.mm_per_px-p.source.y*p.mm_per_px)
            xlabel('mm')
            ylabel('mm')
            
            %%%%%%% ANTENNA PARAMETERS
            
            xymat_antenna = getAntPxlList(f,k,'fixed',i);
            if ~isempty(xymat_antenna)
                plot((xymat_antenna(:,1)-p.source.x)*p.mm_per_px,(xymat_antenna(:,2)-p.source.y)*p.mm_per_px,'om')
            end
            
            %                  %%%%%%% PLOT REFLECTION
            %                  % put fly variables in a format that reflection generation
            %                  % function can understand
            %                  % x,y,a,b,theta,camx,camy;
            %                  sfr = [vtracks(k).x(i,1)./p.mm_per_px,vtracks(k).x(i,2)./p.mm_per_px,...
            %                      vtracks(k).ab(i,1)./p.mm_per_px,vtracks(k).ab(i,2)./p.mm_per_px,...
            %                      vtracks(k).theta(i)*180/pi,p.camera.x,p.camera.y];
            %                  %generate coordinates for reflection
            %                  ref = PredRefGeom(sfr,p);
            %                  % make the reflection ellipsoid
            %                  phi = linspace(0,2*pi,50);
            %                  cosphi=cos(phi);
            %                  sinphi=sin(phi);
            %                  xb = ref(1);
            %                  yb = ref(2);
            %                  a  = ref(3);
            %                  b  = ref(4);
            %                  theta = -vtracks(k).theta(i);
            %                  R  = [cos(theta) sin(theta); -sin(theta) cos(theta)];
            %                  xy = [a*cosphi; b*sinphi];
            %                  xy = R*xy;
            %                  x  = xy(1,:)+xb;
            %                  y  = xy(2,:)+yb;
            %                  plot(x.*p.mm_per_px-p.source.x*p.mm_per_px,y.*p.mm_per_px-p.source.y*p.mm_per_px,'g--','LineWidth',2);
            
            hold off
            
            
            
            % Panel 1
            % SPEED
            subtightplot(9,11,[67:69,78:79,89:91],[0.01 0.01], [0.1 0.1], [0.07 0.1])
            
            if length(looprange)==1
                plot((framef:i)/p.fps,speed(framef:i),'k')
            else
                plot((looprange(1):i)/p.fps,speed(looprange(1):i),'k')
            end
            
            xlabel('sec')
            ylabel('speed (mm/sec)')
            title('Speed')
            setylim = [-.5 25];
            if length(looprange)==1
                xlim([framef i]/p.fps)
                ylim(setylim)
            else
                setLimit(looprange,framef,framel,p,setylim,dispw,bufwset,i)
            end
            
            % Panel 2
            % SIGNAL panel
            figure(h)
            subtightplot(9,11,[71:73,82:84,93:95],[0.01 0.01], [0.1 0.1], [0.01 0.01])
            
            if length(looprange)==1
                plot((framef:i)/p.fps,signal(framef:i),'m')
            else
                plot((looprange(1):i)/p.fps,signal(looprange(1):i),'m')
            end
            
            xlabel('sec')
            ylabel('Smoke Int. (a.u.)')
            title('Signal','Color','m')
            
            setylim = [-.2 25];
            if length(looprange)==1
                xlim([framef i]/p.fps)
                ylim(setylim)
            else
                setLimit(looprange,framef,framel,p,setylim,dispw,bufwset,i)
            end
            
            
            % Panel 3
            % plot angular speed
            %                 rotspeed = reffluo;
            resclrfluo = 1; % rescale y axis
            figure(h)
            subtightplot(9,11,[75:77,86:88,97:99],[0.01 0.01], [0.1 0.1], [0.01 0.01])
            
            if length(looprange)==1
                plot((framef:i)/p.fps,rotspeed(framef:i),'r')
            else
                plot((looprange(1):i)/p.fps,rotspeed(looprange(1):i),'r')
            end
            
            
            xlabel('sec')
            ylabel('(degree/sec)')
            title('Rotational Speed','Color','r')
            setylim = [-450 450];
            if length(looprange)==1
                xlim([framef i]/p.fps)
                ylim(setylim)
            else
                setLimit(looprange,framef,framel,p,setylim,dispw,bufwset,i)
            end
            
            
            pause(.001)
            if ~isempty(savename)
                %                 frame = getframe(h);
                [frame,~] = export_fig(h,'-nocrop',figres);
                %                 fimg = getimage(h);
                %                 map = colormap(getimage(h));
                %                 frame = im2frame(fimg,map);
                writeVideo(writerObj,frame);
            end
        end
        
    end
    if ~isempty(savename)
        close(writerObj);
        close all
    end
    
end
end

function setLimit(looprange,framef,framel,p,setylim,dispw,bufwset,i)
if length(looprange)==1
    xlim([framef framel]/p.fps)
    ylim(setylim)
else
    if ischar(dispw)
        xlim([looprange(1) framel]/p.fps)
        ylim(setylim)
    else
        if dispw<3 % sec then use buffer as 0.5 sec. Make min 1 sec
            if dispw<1, dispw = 1; end
            bufw = 0.5;
        elseif dispw==3 % sec then use buffer as 0.5 sec. Make min 1 sec
            bufw = 1;
        elseif dispw<8 % sec then use buffer as 0.5 sec. Make min 1 sec
            bufw = dispw/4;
        else
            bufw = bufwset;
        end
        chlen = round((dispw-bufw)*p.fps); % length to be shown
        dispwlen = round((dispw)*p.fps);   % length of total window
        bufwinlen = round(bufw*p.fps);     % empty length at the end
        if (i-looprange(1))<chlen
            xlim([looprange(1)/p.fps looprange(1)/p.fps+dispw])
            ylim(setylim)
            dispwind = i;
        elseif (looprange(end)-i-1)<bufwinlen
            xlim([looprange(end)/p.fps-dispw looprange(end)/p.fps])
            ylim(setylim)
        else
            %                             xlim([(looprange(1)-dispwind+i)/p.fps (looprange(1)-dispwind+i)/p.fps+dispw])
            xlim([(i-chlen)/p.fps (i+bufwinlen)/p.fps])
            ylim(setylim)
        end
        
    end
end
end

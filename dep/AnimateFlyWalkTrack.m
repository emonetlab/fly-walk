function AnimateFlyWalkTrack(filepath,Parameters)

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
    case 1
        Parameters = [];
    case 0
        help AnimateFlyWalk
        disp('Not enough input arguments. Please specify the video data...');
end

%% determine if flywalk or path is supplied
if ischar(filepath)
    % parse filpath for title
    [~,fntitle,~] = fileparts(filepath);
    
    % load the flywalk file
    f = openFileFlyWalk(filepath,0,0);
elseif isa(filepath,'flyWalk')
    f = filepath;
    % get the filename
    [~,flnm,~]=fileparts(f.path_name.Properties.Source);
    fntitle = flnm(1:end-7);
else
    error('either the path is wrong or a filewalk objest is not given')
end
%%
p = f.ExpParam;
%% replace default parameters with given ones
Param.makeIntroOnly = 0;    % record the whole video, not the intro only
Param.BoxSize = 10; % mm
Param.SmthLen = .1;   % default smooth length for displying data (sec)
Param.SignalSmthLen = .03;   % default smooth length for displying data (sec)
Param.SmthLenOrntDisp = .03; % for only display purposes
Param.RecFrmRate = p.fps;    % use video frame rate
Param.Resolution = '-r300';   % record with 300 dpi
Param.ShowTracks = 1; %show tracks by default
Param.TailLength = 'Inf';   % plot the whole track
Param.SaveName = '';  %(default) do not save the video
Param.DispWindLength = '';  % (sec) do not slide and move the display window
Param.FrameNum = 'all'; %(default) display all frames as a video
Param.TrjNum = 'all'; %(default) display all trajectories in the main
Param.ColorMap = 'wkkcccb'; %(default) colormap
Param.BufWSet = 3; % window buffer
Param.FigurePosition = [100 150 1000 670];
fnpl = strsplit(fntitle,'_');
if (numel(fnpl)==9)&&isnumeric(str2num(fnpl{1}))
    Param.annotTitle= {fntitle,[fnpl{4},' flies in experiment: ',fnpl{8}]};
    Param.annotText = {[(fnpl{6}(1:end-2)),' days starved ',(fnpl{7}(1:end-2)),' days old females'],'Laminar flow speed: 150 mm/sec'};
else
    Param.annotTitle= {fntitle};
    Param.annotText = {''};
end
Param.annotFontName = 'Arial';
Param.annotTitleFontsize =  23;
Param.annotTextFontsize  = 15;
Param.capLen = 3; % sec for initial caption display
Param.crop = '-nocrop'; % do mot crop or define [top,right,bottom,left]
Param.TrackLineWidth = 2;
Param.setSpeedYlim = [-.5 25];
Param.setSignalYlim = [-.2 25];
Param.setAngVelYlim = [-450 450];
Param.TitleFontSize = 11;
Param.PlotLineWidth = 1;
Param.VideoTitleText = fntitle;
Param.TickLength = .025; % normalized units
Param.resizeFullIm = [1.5 1 1 1];
Param.resizeCropIm = [1 1 1.3 1.3];
Param.resizeOrntHist = [1 .95 1 1];
Param.SetUpWindOrnt2Zero = 1;
Param.PolarTickLabels = '';  %(default) use values set by the function itself
Param.nThetaBins = 72;  % bin size for orientatio histogram


%%
setFields = fieldnames(Param);
if ~isempty(Parameters)
    for i = 1:numel(setFields)
        if isfield(Parameters,setFields{i})
            Param.(setFields{i}) = Parameters.(setFields{i});
        end
    end
end


% pull out the first frame and look at the boundaries
f.current_frame = 1;
f.operateOnFrame;
I = f.current_raw_frame;
[ybound, xbound] = size(I);

% how many tracks are there in total
ntracks = find(f.tracking_info.fly_status(:,end)>0,1,'last');

if strcmp(Param.TrjNum,'all')
    % determine min and max trajectory times
    max_t = f.nframes/p.fps;
    min_t = 1/p.fps;
end

%% determine the looprange
% if all trajectories are requested skip this
if ~strcmp(Param.TrjNum,'all')
    framef = find(f.tracking_info.fly_status(Param.TrjNum,:)==1,1,'first');
    framel = find(f.tracking_info.fly_status(Param.TrjNum,:)==1,1,'last');
    if ischar(Param.FrameNum)
        % play all frames
        if strcmp(Param.FrameNum,'all')
            Param.FrameNum = framef:framel;
        elseif strcmp(Param.FrameNum,'end')
            Param.FrameNum = framel;
        elseif strcmp(Param.FrameNum(end-2:end),'sec')
            Param.FrameNum = Param.FrameNum(1:end-3);
            Param.FrameNum = round(str2num(Param.FrameNum)*p.fps);
        elseif strcmp(Param.FrameNum(end),'s')
            Param.FrameNum = Param.FrameNum(1:end-1);
            Param.FrameNum = round(str2num(Param.FrameNum)*p.fps);
        else
            Param.FrameNum = round(str2num(Param.FrameNum)*p.fps);
        end
        % correct for over fine time step
        Param.FrameNum = nonzeros(unique(Param.FrameNum));
    else
        % adjust the frame start
        Param.FrameNum = nonzeros(framef + Param.FrameNum - 1);
    end
    % now check whether longer than track length is requested
    if isnumeric(Param.TrjNum)&&(Param.FrameNum(end)>framel)
        if (Param.FrameNum(1)>framel) % plot only the last point
            looprange = framel;
        else
            frmind=find(Param.FrameNum<=framel,1,'last');
            if isempty(frmind)
                looprange = Param.FrameNum(1):framel;
            else % set the last value to length limit
                looprange = Param.FrameNum(1:frmind);
            end
        end
    elseif isnumeric(Param.TrjNum)&&(Param.FrameNum(1)<framef)
        if (Param.FrameNum(end)<framef) % plot only the first
            looprange = framef;
        else
            frmind=find(Param.FrameNum>=framef,1,'first');
            if isempty(frmind)
                looprange = framef:framel;
            else % set the last value to length limit
                looprange = Param.FrameNum(frmind:end);
            end
        end
    else
        looprange = Param.FrameNum;
    end
else
    framef = min_t*p.fps;
    framel = max_t*p.fps;
    if ischar(Param.FrameNum)
        % play all frames
        if strcmp(Param.FrameNum,'all')
            Param.FrameNum = framef:framel;
        elseif strcmp(Param.FrameNum,'end')
            Param.FrameNum = framel;
        elseif strcmp(Param.FrameNum(end-2:end),'sec')
            Param.FrameNum = Param.FrameNum(1:end-3);
            Param.FrameNum = round(str2num(Param.FrameNum)*p.fps);
        elseif strcmp(Param.FrameNum(end),'s')
            Param.FrameNum = Param.FrameNum(1:end-1);
            Param.FrameNum = round(str2num(Param.FrameNum)*p.fps);
        else
            Param.FrameNum = round(str2num(Param.FrameNum)*p.fps);
        end
    else
        % adjust the frame start
        Param.FrameNum = framef + Param.FrameNum - 1;
    end
    % now heck whether longer than track length is requested
    if isnumeric(Param.TrjNum)&&(Param.FrameNum(end)>framel)
        if (Param.FrameNum(1)>framel) % plot only the last point
            looprange = framel;
        else
            frmind=find(Param.FrameNum<=framel,1,'last');
            if isempty(frmind)
                looprange = Param.FrameNum(1):framel;
            else % set the last value to length limit
                looprange = Param.FrameNum(1:frmind);
            end
        end
    elseif isnumeric(Param.TrjNum)&&(Param.FrameNum(1)<framef)
        if (Param.FrameNum(end)<framef) % plot only the first
            looprange = framef;
        else
            frmind=find(Param.FrameNum>=framef,1,'first');
            if isempty(frmind)
                looprange = framef:framel;
            else % set the last value to length limit
                looprange = Param.FrameNum(frmind:end);
            end
        end
    else
        looprange = Param.FrameNum;
    end
    
end

% if looprange is column make it row
if iscolumn(looprange)
    looprange = looprange';
end

%%
% open the figure
h = setFigure(Param.FigurePosition,'pixels');
% initiate video recording
if ~isempty(Param.SaveName)
    writerObj = VideoWriter(Param.SaveName);
    writerObj.FrameRate = Param.RecFrmRate;
    open(writerObj);
end

%% do the caption insertion
if Param.capLen > 0
    annotation('textbox', [.2, .8, .7, 0], 'string', Param.annotTitle,'FontName',Param.annotFontName,'FontSize',Param.annotTitleFontsize,'FontWeight','bold','EdgeColor','w','Interpreter','none');
    annotation('textbox', [.2, .55, .7, 0], 'string', Param.annotText,'FontName',Param.annotFontName,'FontSize',Param.annotTextFontsize);
    %
    % [vidframe,~] = export_fig(f.plot_handles.ax,'-nocrop',VidPar.resolution);

    [vidframe,~] = export_fig(h,Param.crop,Param.Resolution);
    for n = 1:round(Param.capLen*Param.RecFrmRate)
        if ~isempty(Param.SaveName)
            writeVideo(writerObj,vidframe);
        end
        pause(.0001)
    end

    % after caption is shown clear the figure
    clf
end


%% determine if all trajectory mode is called
if ~Param.makeIntroOnly
    if strcmp(Param.TrjNum,'all')
        % is not coded properly work on that
        
        if Param.ShowTracks ==1
            % construct trajectory matrix
            trajx_mat = (f.tracking_info.x-p.source.x)*p.mm_per_px;
            trajy_mat = (f.tracking_info.y-p.source.y)*p.mm_per_px;
        end
        
        % set the figure plot handles
        figure(h)
        hold on
        img_now = nan(size(f.current_raw_frame));
        imh = imagesc([1 xbound]*p.mm_per_px-p.source.x*p.mm_per_px,[1 ybound]*p.mm_per_px-p.source.y*p.mm_per_px,img_now);
        colormap(buildcmap(Param.ColorMap));
        xlabel('mm')
        ylabel('mm')
        set(gca,'YDir','reverse');
        imt = title('','Interpret','None');
        axis image
        xlim([1 xbound]*p.mm_per_px-p.source.x*p.mm_per_px)
        ylim([1 ybound]*p.mm_per_px-p.source.y*p.mm_per_px)
        for k = 1:ntracks
            imph(k) = plot(nan,nan,'Linewidth',Param.TrackLineWidth);
        end
        if ~Param.ShowTracks
            for k = 1:ntracks
                imph(k).Visible = 'off';
            end
        end
        
        for i = looprange
            img_now = getCurrentFrameFlyWalk(f,i);
            imh.CData = img_now;
            imt.String = [fntitle,'      frame: ',num2str(i),'     t: ',num2str(i/p.fps,'%5.2f') ' sec'];
            
            if Param.ShowTracks
                
                if length(looprange)==1
                    for k = 1:ntracks
                        imph(k).XData = trajx_mat(k,1:i);
                        imph(k).YData = trajy_mat(k,1:i);
                    end
                else
                    if isnumeric(Param.TailLength )
                        if (i-looprange(1))<=Param.TailLength
                            for k = 1:ntracks
                                imph(k).XData = trajx_mat(k,looprange(1):i);
                                imph(k).YData = trajy_mat(k,looprange(1):i);
                            end
                        elseif (i-looprange(1))>Param.TailLength
                            for k = 1:ntracks
                                imph(k).XData = trajx_mat(k,i-Param.TailLength :i);
                                imph(k).YData = trajy_mat(k,i-Param.TailLength :i);
                            end
                        end
                    else
                        for k = 1:ntracks
                            imph(k).XData = trajx_mat(k,looprange(1):i);
                            imph(k).YData = trajy_mat(k,looprange(1):i);
                        end
                    end
                end
            end
            
            
            pause(.0001)
            if ~isempty(Param.SaveName)
                [vidframe,~] = export_fig(h,Param.crop,Param.Resolution);
                writeVideo(writerObj,vidframe);
            end
        end
        
        
        
        
    else
        % animate a single trajectory
        framef = find(f.tracking_info.fly_status(Param.TrjNum,:)==1,1,'first');
        framel = find(f.tracking_info.fly_status(Param.TrjNum,:)==1,1,'last');
        signal = smooth(f.tracking_info.signal(Param.TrjNum,:),round(Param.SignalSmthLen*p.fps));
        %     signal = fillgaps((f.tracking_info.signal(Param.TrjNum,:)));
        
        
        if Param.SetUpWindOrnt2Zero
            % set upwind orientation to 0
            thetavec = smooth(fillgaps(f.tracking_info.orientation(Param.TrjNum,:))-180,round(Param.SmthLen*p.fps));
        else
            % upwind orientation 360
            thetavec = mod(180-fillgaps(smoothOrientation(f.tracking_info.orientation(Param.TrjNum,:),...
            round(Param.SmthLen*p.fps))),360);
            Param.setAngVelYlim = [0 360];
        end
    
        
        
        
        dtheta = anglediffCentral(thetavec)';
        dx = diffCentral(f.tracking_info.x(Param.TrjNum,:));
        dy = diffCentral(f.tracking_info.y(Param.TrjNum,:));
        speed = sqrt(dx.^2+dy.^2);
        rotspeed = smooth(dtheta,round(Param.SmthLen*p.fps))*p.fps;
        speed = fillgaps(smooth(speed,round(Param.SmthLen*p.fps))*p.mm_per_px*p.fps);
        % smooth the orientation for plotting purposes
        f.tracking_info.orientation(Param.TrjNum,:) = mod(fillgaps(smoothOrientation(f.tracking_info.orientation(Param.TrjNum,:),round(Param.SmthLenOrntDisp*p.fps))),360);
        
        % set current frame to start frame
        f.current_frame = framef;
        f.operateOnFrame;
        
        %Contruct the figure
        figure(h)
        % main figure and red track
        FI = subtightplot(9,11,[1:5,12:16,23:27,34:38,45:49],[0.01 0.01], [0.1 0.1], [0.01 0.01]);
        hold on
        imh = imagesc([1 xbound]*p.mm_per_px-p.source.x*p.mm_per_px,[1 ybound]*p.mm_per_px-p.source.y*p.mm_per_px,nan(size(f.current_raw_frame)));
        colormap(FI,buildcmap(Param.ColorMap));
        trkpl = plot(nan,nan,'r','LineWidth',Param.TrackLineWidth);
        axis image
        set(gca,'YDir','reverse','XTick',[],'YTick',[],'box','on');
        FIttl = title([Param.VideoTitleText,'      t: ',num2str(0/p.fps,'%5.2f') ' sec'],'Interpret','None','FontSize',Param.TitleFontSize);
        xlim([1 xbound]*p.mm_per_px-p.source.x*p.mm_per_px)
        ylim([1 ybound]*p.mm_per_px-p.source.y*p.mm_per_px)
        % add scale barr and make the axis off
        sbary0 = 70;
        sbarx0 = 20;
        sbardx = 30;
        sbarplt = plot(round([sbarx0 sbarx0+sbardx]),ones(2,1)*sbary0,'k','LineWidth',2);
        sbartxt = text(sum([sbarx0 sbarx0+sbardx])/2,sbary0, [num2str(diff([sbarx0 sbarx0+sbardx])),' mm'], 'horiz','center','vert','top','fontsize',9);
        
        FI.Position = FI.Position.*Param.resizeFullIm;
        
        
        % orientation histogram plot
        OP = subplot(9,11,[17:19,28:30,39:41],polaraxes);
        polarplot(OP,nan(Param.nThetaBins,1),nan(Param.nThetaBins,1));
        title({'Orientation','histogram'})
        OP.ThetaZeroLocation = 'left';
        OP.Position = OP.Position.*Param.resizeOrntHist;
        if ~isempty(Param.PolarTickLabels)
            OP.ThetaTickLabel = Param.PolarTickLabels;
            OP.ThetaTick = 0:360/numel(Param.PolarTickLabels):360;
        end
        
        
        % cropped fly with arrow and antenna pixels
        CI = subtightplot(9,11,[20:22,31:33,42:44],[0.01 0.01], [0.1 0.1], [0.01 0.01]);
        hold on
        img_now = f.current_raw_frame;
        flypos = [f.tracking_info.x(Param.TrjNum,framef),f.tracking_info.y(Param.TrjNum,framef)];
        [bymin,bymax,bxmin,bxmax] = getFlyBox(Param.BoxSize/p.mm_per_px,img_now,flypos);
        cih = imagesc([bxmin bxmax]*p.mm_per_px-p.source.x*p.mm_per_px,[bymin bymax]*p.mm_per_px-p.source.y*p.mm_per_px,(img_now(bymin:bymax,bxmin:bxmax)));
        colormap(CI,buildcmap(Param.ColorMap));
        
        axis image
        set(gca,'YDir','reverse','XTick',[],'YTick',[],'box','on');
        xlim([bxmin bxmax]*p.mm_per_px-p.source.x*p.mm_per_px)
        ylim([bymin bymax]*p.mm_per_px-p.source.y*p.mm_per_px)
        
        XY = getTriangleFlyOrient(f,Param.TrjNum);
        ciah = plot((XY(:,1)-p.source.x)*p.mm_per_px, (XY(:,2)-p.source.y)*p.mm_per_px,'r','LineWidth',2);
        
        %plot the antenna
        vaplt = plot(nan,nan,'om');
        
        % add scale barr and make the axis off
        sbary0 = (bymax-p.source.y)*p.mm_per_px-1.5;
        sbarx0 = (bxmin-p.source.x)*p.mm_per_px+1;
        sbardx = 3;
        sbarplt = plot(([sbarx0 sbarx0+sbardx]),ones(2,1)*sbary0,'k','LineWidth',2);
        sbartxt = text(sum([sbarx0 sbarx0+sbardx])/2,sbary0, [num2str(diff([sbarx0 sbarx0+sbardx])),' mm'], 'horiz','center','vert','top','fontsize',9);
        CI.Position = CI.Position.*Param.resizeCropIm;
        
        % SPEED
        SpeedAx = subtightplot(9,11,[67:69,78:79,89:91],[0.01 0.01], [0.1 0.1], [0.07 0.1]);
        speedplt = plot(nan,nan,'k','LineWidth',Param.PlotLineWidth);
        ylim(Param.setSpeedYlim)
        xlabel('Time (sec)')
        ylabel('Speed (mm/s)')
        title('Speed','FontWeight','normal')
        
        
        % Panel 2
        % plot orientation
        OrntAx =  subtightplot(9,11,[71:73,82:84,93:95],[0.01 0.01], [0.1 0.1], [0.01 0.01]);
        hold on
        plot(OrntAx,[framef,framel]/p.fps,ones(2,1)*90,'b--','LineWidth',1)
        plot(OrntAx,[framef,framel]/p.fps,ones(2,1)*-90,'b--','LineWidth',1)
        plot(OrntAx,[framef,framel]/p.fps,zeros(2,1),'g--','LineWidth',1)
        angvelplt = plot(OrntAx,nan,nan,'r','LineWidth',Param.PlotLineWidth);
        xlabel('Time (sec)')
        ylabel('(degree)')
        title('Orientation','Color','r','FontWeight','normal')
        ylim(Param.setAngVelYlim)
        OrntAx.Box = 'on'

        
        % Panel 3
        % SIGNAL panel
        SignalAx = subtightplot(9,11,[75:77,86:88,97:99],[0.01 0.01], [0.1 0.1], [0.01 0.01]);
        signalplt = plot(nan,nan,'m','LineWidth',Param.PlotLineWidth);
        xlabel('Time (sec)')
        ylabel('Smoke Int. (a.u.)')
        title('Signal','Color','m','FontWeight','normal')
        ylim(Param.setSignalYlim)
        
        % set general properties
        set(findobj(h,'type','axes'),'FontName','Arial', 'LineWidth', .5, 'TickLength', ones(1,2)*Param.TickLength,'layer','top');
        
        
        for i = looprange
            
            f.current_frame = i;
            f.operateOnFrame;
            img_now = f.current_raw_frame;
            % full image and trajectory
            imh.CData = img_now;
            
            if length(looprange)==1
                trkpl.XData = (f.tracking_info.x(Param.TrjNum,1:i)-p.source.x)*p.mm_per_px;
                trkpl.YData = (f.tracking_info.y(Param.TrjNum,1:i)-p.source.y)*p.mm_per_px;
            else
                trkpl.XData = (f.tracking_info.x(Param.TrjNum,looprange(1):i)-p.source.x)*p.mm_per_px;
                trkpl.YData = (f.tracking_info.y(Param.TrjNum,looprange(1):i)-p.source.y)*p.mm_per_px;
            end
            
            FIttl.String = [Param.VideoTitleText,'      t: ',num2str(i/p.fps,'%5.2f') ' sec'];
            
            % orinetation histogram
            if length(looprange)==1
%                 HOH = polarhistogram(-thetavec(1:i)/180*pi,72);% returns the vectors T and R such that
                [tout,rout] = rose(-thetavec(1:i)/180*pi,Param.nThetaBins);
            else
%                 HOH = polarhistogram(-thetavec(looprange(1):i)/180*pi,72);% returns the vectors T and R such that
                [tout,rout] = rose(-thetavec(looprange(1):i)/180*pi,Param.nThetaBins);
            end
            
%             OP.Children.ThetaData = (HOH.BinEdges(1:end-1)+HOH.BinEdges(2:end))/2;
            OP.Children.ThetaData = tout;
            
            if Param.SetUpWindOrnt2Zero
%                 OP.Children.RData = HOH.Values;
                OP.Children.RData = rout;
            else
%                 OP.Children.RData = mode(-HOH.Values,360);
                OP.Children.RData = mode(-rout,360);
            end
            
            
            % cropped fly with arrow and antenna pixels
            flypos = [f.tracking_info.x(Param.TrjNum,i),f.tracking_info.y(Param.TrjNum,i)];
            [bymin,bymax,bxmin,bxmax] = getFlyBox(Param.BoxSize/p.mm_per_px,img_now,flypos);
            cih.XData = [bxmin bxmax]*p.mm_per_px-p.source.x*p.mm_per_px;
            cih.YData = [bymin bymax]*p.mm_per_px-p.source.y*p.mm_per_px;
            cih.CData = img_now(bymin:bymax,bxmin:bxmax);
            CI.XLim = cih.XData;
            CI.YLim = cih.YData;
            
            XY = getTriangleFlyOrient(f,Param.TrjNum);
            ciah.XData = (XY(:,1)-p.source.x)*p.mm_per_px;
            ciah.YData = (XY(:,2)-p.source.y)*p.mm_per_px;
            
            xymat_antenna = getAntPxlList(f,Param.TrjNum,'fixed',i);
            if ~isempty(xymat_antenna)
                vaplt.XData = (xymat_antenna(:,1)-p.source.x)*p.mm_per_px;
                vaplt.YData = (xymat_antenna(:,2)-p.source.y)*p.mm_per_px;
            else
                vaplt.XData = nan;
                vaplt.YData = nan;
            end
            
            sbary0 = (bymax-p.source.y)*p.mm_per_px-1.5;
            sbarx0 = (bxmin-p.source.x)*p.mm_per_px+1;
            sbarplt.XData = ([sbarx0 sbarx0+sbardx]);
            sbarplt.YData = ones(2,1)*sbary0;
            sbartxt.Position = [sum([sbarx0 sbarx0+sbardx])/2,sbary0];
            
            
            % Panel 1
            % SPEED
            if length(looprange)==1
                speedplt.XData = (framef:i)/p.fps;
                speedplt.YData = speed(framef:i);
            else
                speedplt.XData = (looprange(1):i)/p.fps;
                speedplt.YData = speed(looprange(1):i);
            end
            
            if length(looprange)==1
                xlim([framef i]/p.fps)
            else
                setLimit(SpeedAx,looprange,framef,framel,p,Param.DispWindLength,Param.BufWSet,i)
            end
            
            % Panel 3
            % SIGNAL panel
            if length(looprange)==1
                signalplt.XData = (framef:i)/p.fps;
                signalplt.YData = signal(framef:i);
            else
                signalplt.XData = (looprange(1):i)/p.fps;
                signalplt.YData = signal(looprange(1):i);
            end
            
            if length(looprange)==1
                xlim([framef i]/p.fps)
            else
                setLimit(SignalAx,looprange,framef,framel,p,Param.DispWindLength,Param.BufWSet,i)
            end
            
            
            % Panel 2
            % plot orientation
            if length(looprange)==1
                angvelplt.XData = (framef:i)/p.fps;
                angvelplt.YData = thetavec(framef:i);
            else
                angvelplt.XData = (looprange(1):i)/p.fps;
                angvelplt.YData = thetavec(looprange(1):i);
            end
            
            
            if length(looprange)==1
                xlim([framef i]/p.fps)
            else
                setLimit(OrntAx,looprange,framef,framel,p,Param.DispWindLength,Param.BufWSet,i)
            end
            
            
            pause(.001)
            if ~isempty(Param.SaveName)
                [vidframe,~] = export_fig(h,Param.crop,Param.Resolution);
                writeVideo(writerObj,vidframe);
            end
        end
        
        
    end
end
if ~isempty(Param.SaveName)
    close(writerObj);
    close all
end
end

function setLimit(ax,looprange,framef,framel,p,DispWindLength,BufWSet,ind)
if length(looprange)==1
    ax.XLim = ([framef framel]/p.fps);
else
    if ischar(DispWindLength)
        ax.XLim = ([looprange(1) framel]/p.fps);
    else
        if DispWindLength<3 % sec then use buffer as 0.5 sec. Make min 1 sec
            if DispWindLength<1, DispWindLength = 1; end
            bufw = 0.5;
        elseif DispWindLength==3 % sec then use buffer as 0.5 sec. Make min 1 sec
            bufw = 1;
        elseif DispWindLength<8 % sec then use buffer as 0.5 sec. Make min 1 sec
            bufw = DispWindLength/4;
        else
            bufw = BufWSet;
        end
        chlen = round((DispWindLength-bufw)*p.fps); % length to be shown
        %         DispWindLength = round((DispWindLength)*p.fps);   % length of total window
        bufwinlen = round(bufw*p.fps);     % empty length at the end
        if (ind-looprange(1))<chlen % initially we need to fill the length to be shown
            ax.XLim = ([looprange(1)/p.fps looprange(1)/p.fps+DispWindLength]);
        elseif (looprange(end)-ind-1)<bufwinlen
            ax.XLim = ([looprange(end)/p.fps-DispWindLength looprange(end)/p.fps]);
        else
            ax.XLim = ([(ind-chlen)/p.fps (ind+bufwinlen)/p.fps]);
        end
        
    end
end
end

function crf = getCurrentFrameFlyWalk(f,frameNum)
% read frame
if nargin<2
    frameNum = f.current_frame;
end
crf = f.path_name.(f.variable_name)(:,:,frameNum);
% subtract background if necessary
if f.subtract_background_frame && ~isempty(f.ExpParam.bkg_img)
    if f.apply_mask
        crf = (crf - f.ExpParam.bkg_img).*uint8(f.ExpParam.mask);
    else
        crf = (crf - f.ExpParam.bkg_img);
    end
end

% subtract median if necessary
if f.subtract_median && ~isempty(f.median_frame)
    if f.apply_mask
        crf = crf - f.median_frame_rand.*uint8(f.ExpParam.mask);
    else
        crf = crf - f.median_frame_rand;
    end
end
if f.subtract_prestim_median_frame
    crf = crf - f.median_frame_prestim - f.median_frame_rand;
end

if f.correct_illumination
    % save original frame for now
    crfsave = crf;
    % correct illumination
    crf = double(crf)./f.ExpParam.FlatNormImage;
    % reset the thresholded area to ariginal
    crf(crfsave>=f.fly_body_threshold) = crfsave(crfsave>=f.fly_body_threshold);
    clear crfsave
end
end

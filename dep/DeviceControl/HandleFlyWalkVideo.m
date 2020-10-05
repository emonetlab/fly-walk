% HandleFlyWalkVideo.m
% HandleFlyWalkVideo.m is a GUI which is used to set following parameters
% on a Fly Walk experiment video:
%   copbox: pixels to crop from left, right, top, and bottom (pxl)
%   mm_per_px: pxl to mm conversion is returned and can be set
%   source: x,y, position od the port that odor comes out os marked (pxl)
%   camerapos: position of the camera is returned (pxl) for reflection analysis
%
% modified from annotateVideo.m created by Srinivas Gorur-Shandilya

function []  = HandleFlyWalkVideo(path_name,thesefiles)

%% parameters
startframe = 300;
frame = 300; % current frame

% working variables
if nargin==0
    path_name = '';
end
nframes=  [];
h = [];
movie = [];
mi = [];
moviefile= [];
p = [];

% figure and object handles
moviefigure = [];
f1 =  [];
framecontrol = [];
framecontrol2= [];
nextfilebutton = [];
movie_axis = [];
crop_radio = [];
lcrp_edit = [];
rcrp_edit = [];
tcrp_edit = [];
bcrp_edit = [];
sourcex_edit = [];
sourcey_edit = [];
sdiam_edit = [];
threshold_edit = [];
show_source_radio = [];
camera_radio = [];
FindCamButton = [];
yw = [];
xw = [];
scalefac = [];
donebutton = [];
histeq_radio = [];
source_histeq_radio = [];
apply2all = [];
skipthisbutton = [];
mask = [];
camera = [];
crop_box = [];
source = []; % pxl
mm_per_px = []; % calibration value
timecontrol = [];
calibrate_radio = [];
head = [0,0];
tail = [0,0];
ImHandle = [];
pl = [];
kdist_edit = [];
mm_per_px_edit = [];
mm_per_pxl_Calib = [];
%% choose files
if nargin == 0
    [allfiles,path_name] = uigetfile({'*.avi';'*.mj2';'*.mat'},'MultiSelect','on'); % makes sure only avi files are chosen
    if ~ischar(allfiles)
        % convert this into a useful format
        thesefiles = [];
        for fi = 1:length(allfiles)
            thesefiles = [thesefiles dir(strcat(path_name,filesep,cell2mat(allfiles(fi))))];
        end
    else
        thesefiles(1).name = allfiles;
    end
else
end


mi=1;
% get matlab folder path, assume it is the first one in the search path
defpath = getMatDirPath;
% first check if the file is already saved
moviefile = thesefiles(mi).name;
filename = thesefiles(mi).name;
% check if the file itself is a mat file
if strcmp(filename(end-9:end),'frames.mat')
    ftype = 'sfrms'; % standard frames.mat file
    % verify frames
    if isempty(who('frames','-file',[path_name, filesep, filename]))
        error([filename,' does not contain frames!'])
    end
    % now check for saved parameters
    if exist([path_name, filesep, strcat(filename(1:end-11),'.mat')],'file')
        m= matfile([path_name, filesep, strcat(filename(1:end-11),'.mat')]);
        % check if there is a field p
        fs=who('p','-file',[path_name, filesep, strcat(filename(1:end-11),'.mat')]);
        if exist([defpath,filesep,'HandleFlyWalkVideo.Defaults.mat'],'file') == 2
            dp = load([defpath,filesep,'HandleFlyWalkVideo.Defaults.mat']);
            crop_box = dp.crop_box;
            source = dp.source;
            mm_per_px = dp.mm_per_px;
            camera = dp.camera;
        end
        if ~isempty(fs)
            p = m.p;
            % replace defaultswith saved
            crop_box = p.crop_box;
            source = p.source; % pxl
            mm_per_px = p.mm_per_px; % calibration value
            camera = p.camera; % pxl
        end
    elseif exist([defpath,filesep,'HandleFlyWalkVideo.Defaults.mat'],'file') == 2
        dp = load([defpath,filesep,'HandleFlyWalkVideo.Defaults.mat']);
        crop_box = dp.crop_box;
        source = dp.source;
        mm_per_px = dp.mm_per_px;
        camera = dp.camera;
    else
        crop_box.lcrp = 50; % pxl, left crop
        crop_box.rcrp = 90; % pxl, right crop
        crop_box.tcrp = 50; % pxl, top crop
        crop_box.bcrp = 50; % pxl, bottom crop
        source.x = 60; % pxl
        source.y = 527; % pxl
        mm_per_px = 0.1540; % calibration value
        camera.x = 1003; % pxl
        camera.y = 537; % pxl
        camera.rad = 56.5; % pxl
        camera.threshold = .2;
    end
    
elseif strcmp(filename(end-2:end),'mat')
    ftype = 'rmat'; % regular .mat file
    % verify frames
    if isempty(who('frames','-file',[path_name, filesep, filename]))
        error([filename,' does not contain frames!'])
    end
    % now check for saved parameters
    if exist([path_name, filesep, filename],'file')
        m= matfile([path_name, filesep, filename]);
        % check if there is a field p
        fs=who('p','-file',[path_name, filesep, filename]);
        if exist([defpath,filesep,'HandleFlyWalkVideo.Defaults.mat'],'file') == 2
            dp = load([defpath,filesep,'HandleFlyWalkVideo.Defaults.mat']);
            crop_box = dp.crop_box;
            source = dp.source;
            mm_per_px = dp.mm_per_px;
            camera = dp.camera;
        end
        if ~isempty(fs)
            p = m.p;
            % replace defaultswith saved
            crop_box = p.crop_box;
            source = p.source; % pxl
            mm_per_px = p.mm_per_px; % calibration value
            camera = p.camera; % pxl
        end
    elseif exist([defpath,filesep,'HandleFlyWalkVideo.Defaults.mat'],'file') == 2
        dp = load([defpath,filesep,'HandleFlyWalkVideo.Defaults.mat']);
        crop_box = dp.crop_box;
        source = dp.source;
        mm_per_px = dp.mm_per_px;
        camera = dp.camera;
    else
        crop_box.lcrp = 50; % pxl, left crop
        crop_box.rcrp = 90; % pxl, right crop
        crop_box.tcrp = 50; % pxl, top crop
        crop_box.bcrp = 50; % pxl, bottom crop
        source.x = 60; % pxl
        source.y = 527; % pxl
        mm_per_px = 0.1540; % calibration value
        camera.x = 1003; % pxl
        camera.y = 537; % pxl
        camera.rad = 56.5; % pxl
        camera.threshold = .2;
    end
    
else
    ftype = 'vid'; % video file
    if exist([path_name, filesep, strcat(filename(1:end-3),'mat')],'file')
        m= matfile([path_name, filesep, strcat(filename(1:end-3),'mat')]);
        % check if there is a field p
        fs=who('p','-file',[path_name, filesep, strcat(filename(1:end-3),'mat')]);
        if exist([defpath,filesep,'HandleFlyWalkVideo.Defaults.mat'],'file') == 2
            dp = load([defpath,filesep,'HandleFlyWalkVideo.Defaults.mat']);
            crop_box = dp.crop_box;
            source = dp.source;
            mm_per_px = dp.mm_per_px;
            camera = dp.camera;
        end
        if ~isempty(fs)
            p = m.p;
            % replace defaultswith saved
            crop_box = p.crop_box;
            source = p.source; % pxl
            mm_per_px = p.mm_per_px; % calibration value
            camera = p.camera; % pxl
        end
    elseif exist([defpath,filesep,'HandleFlyWalkVideo.Defaults.mat'],'file') == 2
        dp = load([defpath,filesep,'HandleFlyWalkVideo.Defaults.mat']);
        crop_box = dp.crop_box;
        source = dp.source;
        mm_per_px = dp.mm_per_px;
        camera = dp.camera;
    else
        crop_box.lcrp = 50; % pxl, left crop
        crop_box.rcrp = 90; % pxl, right crop
        crop_box.tcrp = 50; % pxl, top crop
        crop_box.bcrp = 50; % pxl, bottom crop
        source.x = 60; % pxl
        source.y = 527; % pxl
        mm_per_px = 0.1540; % calibration value
        camera.x = 1003; % pxl
        camera.y = 537; % pxl
        camera.rad = 56.5; % pxl
        camera.threshold = .2;
    end
end
% check for calibration file and load if exist
if exist([pwd,filesep,'calibration.mat'],'file') == 2
    tc = load([pwd,filesep,'calibration.mat']);
    mm_per_px = tc.mm_per_px;
end
initialiseAnnotate(mi);
skip=0;


%% make GUI function

    function [] = createGUI(~,~)
        
        titletext = thesefiles(mi).name;
        scsz = get(0,'ScreenSize');
        yw = 5*scsz(4)/7;
        xw = 3*scsz(3)/5;
        scalefac = 1300/scsz(3);
        if scalefac<.7
            scalefac = 1;
        end
        if xw<1070
            xw = 1070;
        end
        moviefigure = figure('Position',[100 yw/4+130 xw .9*yw]*scalefac,'Name',titletext,'Toolbar',...
            'figure','Menubar','none','NumberTitle','off','Resize','on'...
            ,'HandleVisibility','on','CloseRequestFcn',@QuitCallback);
        movie_axis = gca;
        
        
        f1 = figure('Position',[70 70 1.5*xw 1.1*yw/4]*scalefac,'Toolbar','none','Menubar','none',...
            'NumberTitle','off','Resize','on','HandleVisibility','on','CloseRequestFcn',@QuitCallback);
        
        
        if nframes>300
            startframe = 300;
            frame = 300; % current frame
        else
            startframe = round(nframes/2);
            frame = round(nframes/2); % current frame
        end
        framecontrol = uicontrol(f1,'fontunits', 'normalized','FontSize',2,'units','normalized',...
            'position',[53/xw 200/yw 500/xw 100/yw]*scalefac,'Style','slider','Value',startframe,...
            'Min',1,'Max',nframes,'SliderStep',[1/nframes , 10/nframes],'Callback',@framecallback);
        
        try    % R2013b and older
            addlistener(framecontrol,'ActionEvent',@framecallback);
        catch  % R2014a and newer
            addlistener(framecontrol,'ContinuousValueChange',@framecallback);
        end
        
        th(1)=uicontrol(f1,'fontunits', 'normalized','FontSize',.9,'units','normalized',...
            'position',[60/xw 500/yw 80/xw 100/yw]*scalefac,'Style','text','String','frame #');
        %         th(1)=uicontrol(f1,'position',[1 45 50 20],'Style','text','String','frame #');
        
        framecontrol2 = uicontrol(f1,'fontunits', 'normalized','FontSize',.9,'units','normalized',...
            'Position',[55/xw 350/yw 100/xw 150/yw]*scalefac,'Style','edit','String',mat2str(frame),'Callback',@frame2callback);
        framecontrol2txt = uicontrol(f1,'fontunits', 'normalized','FontSize',.7,'units','normalized',...
            'position',[155/xw 350/yw 300/xw 150/yw]*scalefac,'Style','text','String',[' / ',mat2str(nframes)],...
            'HorizontalAlign','left','fontweight','bold','foregroundcolor','b');
        
        % frame control in seconds
        th(2)=uicontrol(f1,'fontunits', 'normalized','FontSize',.9,'units','normalized',...
            'position',[250/xw 500/yw 80/xw 100/yw]*scalefac,'Style','text','String','sec');
        %         th(1)=uicontrol(f1,'position',[1 45 50 20],'Style','text','String','frame #');
        
        timecontrol = uicontrol(f1,'fontunits', 'normalized','FontSize',.9,'units','normalized',...
            'Position',[250/xw 350/yw 100/xw 150/yw]*scalefac,'Style','edit','String',num2str(frame/p.fps,'%5.2f'),'Callback',@time2callback);
        timecontoltxt = uicontrol(f1,'fontunits', 'normalized','FontSize',.7,'units','normalized',...
            'position',[350/xw 350/yw 300/xw 150/yw]*scalefac,'Style','text','String',[' / ',num2str(nframes/p.fps,'%5.2f')],...
            'HorizontalAlign','left','fontweight','bold','foregroundcolor','b');
        
        nextfilebutton = uicontrol(f1,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
            'Position',[50/xw 30/yw 80/xw 120/yw]*scalefac,'Style','pushbutton','String','NextFile','Enable','on','Callback',@nextcallback);
        
        skipthisbutton = uicontrol(f1,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
            'Position',[150/xw 30/yw 80/xw 120/yw]*scalefac,'Style','pushbutton','String','Skip This','Enable','on','Callback',@cannotanalysecallback);
        
        donebutton = uicontrol(f1,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
            'Position',[250/xw 30/yw 80/xw 120/yw]*scalefac,'Style','pushbutton','String','done!','Enable','on','Callback',@donecallback);
        
        apply2all = uicontrol(f1,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
            'Position',[350/xw 30/yw 80/xw 120/yw]*scalefac,'Style','pushbutton','String','Apply to All','Enable','on','Callback',@apply2allcallback);
        
        %%%%% Crop Panel
        CropPanel = uipanel('parent', f1,'fontunits', 'normalized','FontSize',.1,'units','normalized','Title','Crop (pxl)','pos',[570/xw 50/yw 130/xw 700/yw]*scalefac);
        crop_radio = uicontrol(f1,'fontunits', 'normalized','FontSize',1,'units','normalized','Style','rad',...
            'position',[640/xw 670/yw 60/xw 60/yw]*scalefac,'fontweight','bold','Value',1,'Callback', @crop_radio_call);
        lcrp_text = uicontrol(CropPanel,'fontunits', 'normalized','FontSize',.8,'units','normalized','Style','text',...
            'position',[70/xw 430/yw 200/xw 70/yw]*scalefac,'String','left','fontweight','bold');
        lcrp_edit = uicontrol(CropPanel,'fontunits', 'normalized','FontSize',.8,'units','normalized','style','edit',...
            'position',[65/xw 330/yw 300/xw 100/yw]*scalefac,'string',mat2str(crop_box.lcrp),'callback',@cropboxcall);
        rcrp_text = uicontrol(CropPanel,'fontunits', 'normalized','FontSize',.8,'units','normalized','Style','text',...
            'position',[730/xw 430/yw 250/xw 70/yw]*scalefac,'String','right','fontweight','bold');
        rcrp_edit = uicontrol(CropPanel,'fontunits', 'normalized','FontSize',.8,'units','normalized','style','edit',...
            'position',[700/xw 330/yw 300/xw 100/yw]*scalefac,'string',mat2str(crop_box.rcrp),'callback',@cropboxcall);
        % top crop is in image space which actually lower y values
        tcrp_text = uicontrol(CropPanel,'fontunits', 'normalized','FontSize',.8,'units','normalized','Style','text',...
            'position',[400/xw 630/yw 200/xw 70/yw]*scalefac,'String','top','fontweight','bold');
        tcrp_edit = uicontrol(CropPanel,'fontunits', 'normalized','FontSize',.8,'units','normalized','style','edit',...
            'position',[370/xw 520/yw 300/xw 100/yw]*scalefac,'string',mat2str(crop_box.tcrp),'callback',@cropboxcall);
        bcrp_text = uicontrol(CropPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
            'position',[370/xw 30/yw 350/xw 100/yw]*scalefac,'String','bottom','fontweight','bold');
        bcrp_edit = uicontrol(CropPanel,'fontunits', 'normalized','FontSize',.8,'units','normalized','style','edit',...
            'position',[370/xw 150/yw 300/xw 100/yw]*scalefac,'string',mat2str(crop_box.bcrp),'callback',@cropboxcall);
        
        
        %%%%% Calibration Panel
        CalibratePanel = uipanel('parent', f1,'fontunits', 'normalized','FontSize',.1,'units','normalized','Title','Calibrate','pos',[710/xw 50/yw 130/xw 700/yw]*scalefac);
        calibrate_radio = uicontrol(f1,'fontunits', 'normalized','FontSize',1,'units','normalized','Style','rad',...
            'position',[775/xw 670/yw 60/xw 60/yw]*scalefac,'fontweight','bold','Value',0,'Callback', @calibrate_call);
        kdist_text = uicontrol(CalibratePanel,'fontunits', 'normalized','FontSize',.7,'units','normalized','Style','text',...
            'position',[100/xw 600/yw 900/xw 100/yw]*scalefac,'String','Known Dist. (mm)','fontweight','bold');
        kdist_edit = uicontrol(CalibratePanel,'fontunits', 'normalized','FontSize',.8,'units','normalized','style','edit',...
            'position',[300/xw 480/yw 500/xw 100/yw]*scalefac,'string','0','callback',@calibrate_call);
        mm_per_px_text = uicontrol(CalibratePanel,'fontunits', 'normalized','FontSize',.7,'units','normalized','Style','text',...
            'position',[100/xw 320/yw 800/xw 100/yw]*scalefac,'String','mm_per_px','fontweight','bold');
        
        mm_per_pxl_Calib = mm_per_px;
        mm_per_px_edit = uicontrol(CalibratePanel,'fontunits', 'normalized','FontSize',.8,'units','normalized','style','edit',...
            'position',[300/xw 210/yw 500/xw 100/yw]*scalefac,'string',num2str(mm_per_pxl_Calib),'Enable','off');
        SaveCalButton = uicontrol(CalibratePanel,'fontunits', 'normalized','FontSize',.8,'units','normalized',...
            'Position',[300/xw 50/yw 500/xw 100/yw]*scalefac,'Style','pushbutton','Enable','on','String','Save','Callback',@SaveCalib_call);
        
        %%%%% Source Panel
        SourcePanel = uipanel('parent', f1,'fontunits', 'normalized','FontSize',.1,'units','normalized','Title','Source','pos',[850/xw 50/yw 130/xw 700/yw]*scalefac);
        show_source_radio = uicontrol(f1,'fontunits', 'normalized','FontSize',1,'units','normalized','Style','rad',...
            'position',[905/xw 670/yw 60/xw 60/yw]*scalefac,'fontweight','bold','Value',0,'Callback', @source_call);
        sdiam_text = uicontrol(SourcePanel,'fontunits', 'normalized','FontSize',.7,'units','normalized','Style','text',...
            'position',[100/xw 600/yw 1000/xw 100/yw]*scalefac,'String','Source Diam. (mm)','fontweight','bold');
        sdiam_edit = uicontrol(SourcePanel,'fontunits', 'normalized','FontSize',.8,'units','normalized','style','edit',...
            'position',[500/xw 480/yw 300/xw 100/yw]*scalefac,'string','3','callback',@source_call);
        sourcex_text = uicontrol(SourcePanel,'fontunits', 'normalized','FontSize',.7,'units','normalized','Style','text',...
            'position',[50/xw 300/yw 400/xw 100/yw]*scalefac,'String','Sx (pxl)','fontweight','bold');
        sourcex_edit = uicontrol(SourcePanel,'fontunits', 'normalized','FontSize',.8,'units','normalized','style','edit',...
            'position',[490/xw 300/yw 500/xw 100/yw]*scalefac,'string',num2str(source.x),'callback',@source_call);
        sourcey_text = uicontrol(SourcePanel,'fontunits', 'normalized','FontSize',.7,'units','normalized','Style','text',...
            'position',[50/xw 180/yw 400/xw 100/yw]*scalefac,'String','Sy (pxl)','fontweight','bold');
        sourcey_edit = uicontrol(SourcePanel,'fontunits', 'normalized','FontSize',.8,'units','normalized','style','edit',...
            'position',[490/xw 180/yw 500/xw 100/yw]*scalefac,'string',num2str(source.y),'callback',@source_call);
        source_histeq_radio = uicontrol(SourcePanel,'fontunits', 'normalized','FontSize',1,'units','normalized','Style','rad',...
            'position',[150/xw 50/yw 500/xw 60/yw]*scalefac,'String','histeq?','fontweight','bold','Value',0);
        
        %%%%% Camera Position Panel
        CameraPanel = uipanel('parent', f1,'fontunits', 'normalized','FontSize',.1,'units','normalized','Title','Camera','pos',[990/xw 50/yw 130/xw 700/yw]*scalefac);
        camera_radio = uicontrol(f1,'fontunits', 'normalized','FontSize',1,'units','normalized','Style','rad',...
            'position',[1050/xw 670/yw 60/xw 60/yw]*scalefac,'fontweight','bold','Value',1,'Callback', @DrawCam_call);
        FindCamButton = uicontrol(CameraPanel,'fontunits', 'normalized','FontSize',.8,'units','normalized',...
            'Position',[100/xw 550/yw 1000/xw 150/yw]*scalefac,'Style','pushbutton','Enable','on','String','Find Cam.','Callback',@FindCam_call);
        threshold_text = uicontrol(CameraPanel,'fontunits', 'normalized','FontSize',.8,'units','normalized','Style','text',...
            'position',[220/xw 220/yw 800/xw 100/yw]*scalefac,'String','threshold','fontweight','bold');
        threshold_edit = uicontrol(CameraPanel,'fontunits', 'normalized','FontSize',.8,'units','normalized','style','edit',...
            'position',[380/xw 70/yw 500/xw 100/yw]*scalefac,'string',num2str(camera.threshold));
        histeq_radio = uicontrol(CameraPanel,'fontunits', 'normalized','FontSize',1,'units','normalized','Style','rad',...
            'position',[150/xw 400/yw 500/xw 80/yw]*scalefac,'String','histeq?','fontweight','bold','Value',0);
        
        
        
        
    end


%%
% source call, drow lines at the borders of the ribbon and a vertical line
% at the source
    function [] = source_call(~,~)
        % check who is called
        % define lines
        if get(show_source_radio,'val')==1 % radio called
            % get set values first
            source.x = str2double(get(sourcex_edit,'string'));
            source.y = str2double(get(sourcey_edit,'string'));
            dia = str2double(get(sdiam_edit,'string'));
            
            if strcmp(ftype,'vid')
                ff = read(movie,frame);
            else
                ff = movie.frames(:,:,frame);
            end
            figure(moviefigure)
            clf
            crpx = 1+crop_box.lcrp:size(ff,2)-crop_box.rcrp;
            crpy = 1+crop_box.tcrp:size(ff,1)-crop_box.bcrp;
            if get(crop_radio,'val')==1
                ffmask = ones(size(ff))./2;
                ffmask(crpy,crpx) = 1;
                ff = uint8(double(ff).*ffmask);
            end
            ff = ff(source.y-100:source.y+100,1:source.x+300);
            if get(source_histeq_radio,'val')==1
                ImHandle = imagesc(histeq(ff)); %colormap(gray)
            else
                ImHandle = imagesc(adapthisteq(ff)); %colormap(gray)
            end
            
            axis equal
            axis tight
            title([mat2str(frame),' - ',num2str(frame/p.fps,'%5.2f'),' sec']);
            
            
            hold all
            
            % bottom line
            %         bly = [source.y+crop_box.tcrp-dia/2/mm_per_px,source.y+crop_box.tcrp-dia/2/mm_per_px];
            %         blx = [source.x+crop_box.lcrp-50,source.x+crop_box.lcrp+50];
            bly = [100-dia/2/mm_per_px,100-dia/2/mm_per_px];
            blx = [1,source.x+100];
            plot(blx,bly,'r');
            
            
            % top line
            %         tly = [source.y+crop_box.tcrp+dia/2/mm_per_px,source.y+crop_box.tcrp+dia/2/mm_per_px];
            %         tlx = [source.x+crop_box.lcrp-50,source.x+crop_box.lcrp+50];
            tly = [100+dia/2/mm_per_px,100+dia/2/mm_per_px];
            tlx = [1,source.x+100];
            plot(tlx,tly,'r');
            
            
            % center line
            %         cly = [source.y+crop_box.tcrp-50,source.y+crop_box.tcrp+50];
            %         clx = [source.x+crop_box.lcrp,source.x+crop_box.lcrp];
            cly = [1,200];
            clx = [source.x,source.x];
            plot(clx,cly,'r');
            xlim([1 source.x+100])
            ylim([source.y-100 source.y+100])
            axis image
            hold off
            saveTrackData;
        elseif get(show_source_radio,'val')==0 % radio disabled
            showImage;
            DrawCam_call;
        end
        
    end

% find camera

    function [] = DrawCam_call(~,~)
        
        % check who is called
        if get(camera_radio,'val')==1 % radio called
            % draw the default camera detection
            if strcmp(ftype,'vid')
                ff = read(movie,frame);
            else
                ff = movie.frames(:,:,frame);
            end
            crpx = 1+crop_box.lcrp:size(ff,2)-crop_box.rcrp;
            crpy = 1+crop_box.tcrp:size(ff,1)-crop_box.bcrp;
            if get(crop_radio,'val')==1
                ffmask = ones(size(ff))./8;
                ffmask(crpy,crpx) = 1;
                ff = uint8(double(ff).*ffmask);
            end
            figure(moviefigure)
            clf
            ImHandle =  imagesc(adapthisteq(ff)); %colormap(gray)
            % %             viscircles(centers,radii);
            centers(1,1) = camera.x;
            centers(1,2) = camera.y;
            radii = camera.rad;
            viscircles(centers,radii,'LineStyle',':');
            axis equal
            axis tight
            title([mat2str(frame),' - ',num2str(frame/p.fps,'%5.2f'),' sec']);
            
        elseif get(camera_radio,'val')==0 % radio called
            if strcmp(ftype,'vid')
                ff = read(movie,frame);
            else
                ff = movie.frames(:,:,frame);
            end
            figure(moviefigure), axis image
            crpx = 1+crop_box.lcrp:size(ff,2)-crop_box.rcrp;
            crpy = 1+crop_box.tcrp:size(ff,1)-crop_box.bcrp;
            if get(crop_radio,'val')==1
                ffmask = ones(size(ff))./8;
                ffmask(crpy,crpx) = 1;
                ff = uint8(double(ff).*ffmask);
            end
            ImHandle = imagesc(adapthisteq(ff)); %colormap(gray)
            axis equal
            axis tight
            title([mat2str(frame),' - ',num2str(frame/p.fps,'%5.2f'),' sec']);
        end
        
    end

    function [] = FindCam_call(~,~)
        
        % check who is called
        set(FindCamButton,'Enable','off');
        % find camera center
        if strcmp(ftype,'vid')
            ff = read(movie,frame);
        else
            ff = movie.frames(:,:,frame);
        end
        % call the function for finding the camera location
        usehisteq = get(histeq_radio,'val');
        camera.threshold = str2double(get(threshold_edit,'string'));
        % radrange is hardcoded here. make it user controlled if necessary
        radrange = [30,70]; % pxl
        cam = findCam(ff,1,usehisteq,camera.threshold,radrange,crop_box);
        crpx = 1+crop_box.lcrp:size(ff,2)-crop_box.rcrp;
        crpy = 1+crop_box.tcrp:size(ff,1)-crop_box.bcrp;
        
        if ~isempty(cam)
            
            if get(crop_radio,'val')==1
                ffmask = ones(size(ff))./2;
                ffmask(crpy,crpx) = 1;
                ff = uint8(double(ff).*ffmask);
            end
            figure(moviefigure)
            clf
            ImHandle = imagesc(adapthisteq(ff)); %colormap(gray)
            %             viscircles(centers,radii);
            viscircles([cam.x,cam.y],cam.rad,'LineStyle',':');
            
            camera.x = cam.x;
            camera.y = cam.y;
            camera.rad = cam.rad;
            axis equal
            axis tight
            title([mat2str(frame),' - ',num2str(frame/p.fps,'%5.2f'),' sec']);
            %             saveTrackData;
        end
        set(FindCamButton,'Enable','on');
        
    end


    function [] = donecallback(~,~)
        saveTrackData;
        QuitCallback;
    end

% apply to all
    function [] = apply2allcallback(~,~)
        
        set(FindCamButton,'Enable','off');
        set(framecontrol2,'Enable','off');
        set(nextfilebutton ,'Enable','off')
        set(skipthisbutton,'Enable','off');
        set(donebutton,'Enable','off')
        set(apply2all,'Enable','off');
        set(crop_radio ,'Enable','off')
        set(framecontrol,'Enable','off');
        set(lcrp_edit,'Enable','off')
        set(rcrp_edit,'Enable','off');
        set(tcrp_edit ,'Enable','off')
        set(bcrp_edit,'Enable','off');
        set(sourcex_edit,'Enable','off')
        set(sourcey_edit,'Enable','off');
        set(sdiam_edit ,'Enable','off')
        set(threshold_edit,'Enable','off');
        set(show_source_radio,'Enable','off');
        set(camera_radio ,'Enable','off')
        set(FindCamButton,'Enable','off');
        set(histeq_radio ,'Enable','off');
        set(source_histeq_radio ,'Enable','off')
        
        
        for li = 1:length(thesefiles)
            
            if strcmp(ftype,'vid')
                try
                    moviefile = thesefiles(li).name;
                    filename = thesefiles(li).name;
                    % first check if p is saved
                    if exist([path_name, filesep, strcat(filename(1:end-3),'mat')],'file')
                        fs=who('p','-file',[path_name, filesep, strcat(filename(1:end-3),'mat')]);
                        if ~isempty(fs)
                            m= matfile([path_name, filesep, strcat(filename(1:end-3),'mat')]);
                            % load p
                            p = m.p;
                        end
                    end
                    p.fps = get(VideoReader([path_name,filesep,moviefile]),'FrameRate');
                    % construct parameter space
                    p.crop_box = crop_box;
                    p.source = source;
                    p.mm_per_px = mm_per_px;
                    p.camera = camera;
                    ff = read(movie,frame);
                    crpx = 1+crop_box.lcrp:size(ff,2)-crop_box.rcrp;
                    crpy = 1+crop_box.tcrp:size(ff,1)-crop_box.bcrp;
                    mask = zeros(size(ff));
                    mask(crpy,crpx) = 1;
                    p.mask = mask;
                    if exist([path_name, filesep, strcat(filename(1:end-3),'mat')],'file')
                        save([path_name, filesep, strcat(filename(1:end-3),'mat')],'p','moviefile','-append');
                    else
                        save([path_name, filesep, strcat(filename(1:end-3),'mat')],'p','moviefile');
                    end
                catch ME
                    disp(thesefiles(li).name)
                    disp(ME.message)
                    if strcmp('Failed to initialize internal resources.',ME.message)||strcmp('Unable to determine the codec required.',ME.message)
                        %                     cannotanalysecallback
                        % move this to cannot-analyse
                        sharepath = [getSharePath,'CorruptVideos'];
                        if exist(sharepath,'dir') == 7
                            
                        else
                            % make it
                            mkdir(sharepath)
                        end
                        % move this file there
                        %                 copyfile([pwd,filesep,fileNames{i}],[dest_fldr,filesep,fileNames{i}])
                        disp('Will ty to move it...')
                        movefile([path_name, filesep,thesefiles(li).name],strcat(sharepath,filesep,thesefiles(li).name))
                        disp(['moved it to ',sharepath])
                        % delete the .mat if exist
                        thisfile = thesefiles(li).name;
                        if exist(strcat(thisfile(1:end-3),'mat'),'file')
                            delete(strcat(thisfile(1:end-3),'mat'))
                            disp([thesefiles(li).name,' is deleted from the current directory.'])
                        end
                    end
                end
            elseif strcmp(ftype,'sfrms')
                try
                    moviefile = thesefiles(li).name;
                    filename = thesefiles(li).name;
                    % first check if p is saved
                    if exist([path_name, filesep, strcat(filename(1:end-11),'.mat')],'file')
                        fs=who('p','-file',[path_name, filesep, strcat(filename(1:end-11),'.mat')]);
                        if ~isempty(fs)
                            m= matfile([path_name, filesep, strcat(filename(1:end-11),'.mat')]);
                            % load p
                            p = m.p;
                        end
                    end
                    % construct parameter space
                    p.crop_box = crop_box;
                    p.source = source;
                    p.mm_per_px = mm_per_px;
                    p.camera = camera;
                    ff = movie.farmes(:,:,frame);
                    crpx = 1+crop_box.lcrp:size(ff,2)-crop_box.rcrp;
                    crpy = 1+crop_box.tcrp:size(ff,1)-crop_box.bcrp;
                    mask = zeros(size(ff));
                    mask(crpy,crpx) = 1;
                    p.mask = mask;
                    if exist([path_name, filesep, strcat(filename(1:end-11),'.mat')],'file')
                        save([path_name, filesep, strcat(filename(1:end-11),'.mat')],'p','moviefile','-append');
                    else
                        save([path_name, filesep, strcat(filename(1:end-11),'.mat')],'p','moviefile');
                    end
                catch ME
                    disp(thesefiles(li).name)
                    disp(ME.message)
                    if strcmp('Failed to initialize internal resources.',ME.message)||strcmp('Unable to determine the codec required.',ME.message)
                        %                     cannotanalysecallback
                        % move this to cannot-analyse
                        sharepath = [getSharePath,'CorruptVideos'];
                        if exist(sharepath,'dir') == 7
                            
                        else
                            % make it
                            mkdir(sharepath)
                        end
                        % move this file there
                        %                 copyfile([pwd,filesep,fileNames{i}],[dest_fldr,filesep,fileNames{i}])
                        disp('Will ty to move it...')
                        movefile([path_name, filesep,thesefiles(li).name],strcat(sharepath,filesep,thesefiles(li).name))
                        disp(['moved it to ',sharepath])
                        % delete the .mat if exist
                        thisfile = thesefiles(li).name;
                        if exist(strcat(thisfile(1:end-11),'.mat'),'file')
                            delete(strcat(thisfile(1:end-11),'.mat'))
                            disp([thesefiles(li).name,' is deleted from the current directory.'])
                        end
                    end
                end
            elseif strcmp(ftype,'rmat')
                try
                    moviefile = thesefiles(li).name;
                    filename = thesefiles(li).name;
                    % first check if p is saved
                    if exist([path_name, filesep, filename],'file')
                        fs=who('p','-file',[path_name, filesep, filename]);
                        if ~isempty(fs)
                            m= matfile([path_name, filesep, filename]);
                            % load p
                            p = m.p;
                        end
                    end
                    % construct parameter space
                    p.crop_box = crop_box;
                    p.source = source;
                    p.mm_per_px = mm_per_px;
                    p.camera = camera;
                    ff = movie.farmes(:,:,frame);
                    crpx = 1+crop_box.lcrp:size(ff,2)-crop_box.rcrp;
                    crpy = 1+crop_box.tcrp:size(ff,1)-crop_box.bcrp;
                    mask = zeros(size(ff));
                    mask(crpy,crpx) = 1;
                    p.mask = mask;
                    if exist([path_name, filesep, filename],'file')
                        save([path_name, filesep, filename],'p','moviefile','-append');
                    else
                        save([path_name, filesep, filename],'p','moviefile');
                    end
                catch ME
                    disp(thesefiles(li).name)
                    disp(ME.message)
                    if strcmp('Failed to initialize internal resources.',ME.message)||strcmp('Unable to determine the codec required.',ME.message)
                        %                     cannotanalysecallback
                        % move this to cannot-analyse
                        sharepath = [getSharePath,'CorruptVideos'];
                        if exist(sharepath,'dir') == 7
                            
                        else
                            % make it
                            mkdir(sharepath)
                        end
                        % move this file there
                        %                 copyfile([pwd,filesep,fileNames{i}],[dest_fldr,filesep,fileNames{i}])
                        disp('Will ty to move it...')
                        movefile([path_name, filesep,thesefiles(li).name],strcat(sharepath,filesep,thesefiles(li).name))
                        disp(['moved it to ',sharepath])
                        % delete the .mat if exist
                        thisfile = thesefiles(li).name;
                        if exist(strcat(thisfile(1:end-11),'.mat'),'file')
                            delete(strcat(thisfile(1:end-11),'.mat'))
                            disp([thesefiles(li).name,' is deleted from the current directory.'])
                        end
                    end
                end
            end
            
            
        end
        save([defpath,filesep,'HandleFlyWalkVideo.Defaults.mat'],'crop_box','source','mm_per_px','camera');
        
        set(FindCamButton,'Enable','on');
        set(framecontrol2,'Enable','on');
        set(nextfilebutton ,'Enable','on')
        set(skipthisbutton,'Enable','on');
        set(donebutton,'Enable','on')
        set(apply2all,'Enable','on');
        set(crop_radio ,'Enable','on')
        set(framecontrol,'Enable','on');
        set(lcrp_edit,'Enable','on')
        set(rcrp_edit,'Enable','on');
        set(tcrp_edit ,'Enable','on')
        set(bcrp_edit,'Enable','on');
        set(sourcex_edit,'Enable','on')
        set(sourcey_edit,'Enable','on');
        set(sdiam_edit ,'Enable','on')
        set(threshold_edit,'Enable','on');
        set(show_source_radio,'Enable','on');
        set(camera_radio ,'Enable','on')
        set(FindCamButton,'Enable','on');
        set(histeq_radio ,'Enable','on');
        set(source_histeq_radio ,'Enable','on')
        
    end


    function [] = calibrate_call(~,~)
        
        if get(calibrate_radio,'Value')==1
            set(ImHandle,'ButtonDownFcn',@ax_bdfcn);
        else
            set(ImHandle,'ButtonDownFcn',[]);
            pl.Visible = 'off';
        end
        known_dist = str2num(get(kdist_edit,'string'));
        px = pdist([head;tail],'Euclidean');
        mm_per_pxl_Calib = known_dist/px; %bc default case is segment of 1 cm
        set(mm_per_px_edit,'string',num2str(mm_per_pxl_Calib))  % Set GUI_24 editbox string.
    end

    function [] = ax_bdfcn(ImHandle, ~)
        axesHandle = get(ImHandle,'Parent');
        coordinates = get(axesHandle,'CurrentPoint');
        coordinates = coordinates(1,1:2);
        
        points = get(gca,'Children');
        
        hold off;
        if numel(points)==2
            delete(points(1));
        end
        
        head = tail;
        tail = coordinates;
        
        hold on;
        pl = plot([head(1) tail(1)],[head(2) tail(2)],'r','LineWidth',2);
        
    end




    function [] = SaveCalib_call(~,~)
        % save this in the calibration file
        mm_per_px = mm_per_pxl_Calib;
        p.mm_per_px = mm_per_pxl_Calib;
        % check for calibration file and load if exist
        if exist([pwd,filesep,'calibration.mat'],'file') == 2
            save([pwd,filesep,'calibration.mat'],'mm_per_px');
        end
        saveTrackData;
    end



    function [] = markCrop(~,~)
        %         h = imrect(movie_axis);
        %         crop_box = wait(h);
        %         disp('Crop box saved!')
        %         saveTrackData;
    end

    function [] = cannotanalysecallback(eo,ed)
        % move this to cannot-analyse
        sharepath = 'Y:\mahmut_demir\Walking Assay\CorruptVideos';
        if exist(sharepath,'dir') == 7
            
        else
            % make it
            mkdir(sharepath)
        end
        % move this file there
        movefile([path_name, filesep,thesefiles(mi).name],strcat(sharepath,filesep,thesefiles(mi).name))
        disp(['moved it to ',sharepath])
        % delete the .mat
        thisfile = thesefiles(mi).name;
        if exist(strcat(thisfile(1:end-3),'mat'),'file')
            delete(strcat(thisfile(1:end-3),'mat'))
        end
        %         % go to the next file
        skip=1;
        nextcallback;
        skip=0;
        
    end


    function [] = nextcallback(~,~)
        if mi == length(thesefiles)
            %             disp('This was the final file')
            saveTrackData;
            delete(moviefigure)
            delete(f1)
        else
            % clear all old variables
            %             disp('OK. Next file.')
            saveTrackData;
            
            
            % delete all GUI elements
            delete(framecontrol)
            delete(framecontrol2)
            delete(nextfilebutton)
            delete(moviefigure);
            delete(f1)
            
            
            % redraw entire GUI
            createGUI;
            
            nframes=  [];
            h = [];
            moviefile= [];
            
            
            mi = mi+1;
            if strcmp(ftype,'vid')
                try
                    movie = VideoReader([path_name,filesep,thesefiles(mi).name]);
                    h =  get(movie,'Height');
                    p.fps = get(movie,'FrameRate');
                    
                    % working variables
                    nframes = get(movie,'NumberOfFrames');
                    
                    % clear variables
                    if ~skip
                        frame=300;
                        %                 markroi; % clears ROIs
                        %                 markstart;
                        %                 markstop;
                        %                 markleft;
                        %                 markright;
                    end
                    
                    if nframes>300
                        startframe = 300;
                        frame = 300; % current frame
                    else
                        startframe = round(nframes/2);
                        frame = round(nframes/2); % current frame
                    end
                    
                    delete(framecontrol)
                    
                    framecontrol = uicontrol(f1,'fontunits', 'normalized','FontSize',2,'units','normalized',...
                        'position',[53/xw 200/yw 500/xw 100/yw]*scalefac,'Style','slider','Value',startframe,'Min',...
                        1,'Max',nframes,'SliderStep',[.1 .9],'Callback',@framecallback);
                    
                    
                    % update GUI
                    titletext = thesefiles(mi).name;
                    set(moviefigure,'Name',titletext);
                    set(framecontrol,'Value',frame);
                    set(framecontrol2,'String',num2str(frame))
                    
                    showImage;
                catch ME
                    disp(thesefiles(mi).name)
                    disp(ME.message)
                    if strcmp('Failed to initialize internal resources.',ME.message)||strcmp('Unable to determine the codec required.',ME.message)
                        %                     cannotanalysecallback
                        % move this to cannot-analyse
                        sharepath = 'Y:\mahmut_demir\Walking Assay\CorruptVideos';
                        if exist(sharepath,'dir') == 7
                            
                        else
                            % make it
                            mkdir(sharepath)
                        end
                        % move this file there
                        %                 copyfile([pwd,filesep,fileNames{i}],[dest_fldr,filesep,fileNames{i}])
                        disp('Will ty to move it...')
                        movefile([path_name, filesep,thesefiles(mi).name],strcat(sharepath,filesep,thesefiles(mi).name))
                        disp(['moved it to ',sharepath])
                        thisfile = thesefiles(mi).name;
                        % delete the .mat if exist
                        if exist(strcat(thisfile(1:end-3),'mat'),'file')
                            delete(strcat(thisfile(1:end-3),'mat'))
                            disp([thesefiles(mi).name,' is deleted from the current directory.'])
                        end
                    end
                end
            elseif strcmp(ftype,'sfrms')
                try
                    movie = matfile([path_name,filesep,thesefiles(mi).name]);
                    filename = thesefiles(mi).name;
                    m= matfile([path_name, filesep, strcat(filename(1:end-11),'.mat')]);
                    h =  size(movie.frames(:,:,1),1);
                    p = m.p;
                    
                    % working variables
                    nframes = size(movie,'frames',3);
                    
                    % clear variables
                    if ~skip
                        frame=300;
                        %                 markroi; % clears ROIs
                        %                 markstart;
                        %                 markstop;
                        %                 markleft;
                        %                 markright;
                    end
                    
                    if nframes>300
                        startframe = 300;
                        frame = 300; % current frame
                    else
                        startframe = round(nframes/2);
                        frame = round(nframes/2); % current frame
                    end
                    
                    delete(framecontrol)
                    
                    framecontrol = uicontrol(f1,'fontunits', 'normalized','FontSize',2,'units','normalized',...
                        'position',[53/xw 200/yw 500/xw 100/yw]*scalefac,'Style','slider','Value',startframe,'Min',...
                        1,'Max',nframes,'SliderStep',[.1 .9],'Callback',@framecallback);
                    
                    
                    % update GUI
                    titletext = thesefiles(mi).name;
                    set(moviefigure,'Name',titletext);
                    set(framecontrol,'Value',frame);
                    set(framecontrol2,'String',num2str(frame))
                    
                    showImage;
                catch ME
                    disp(thesefiles(mi).name)
                    disp(ME.message)
                    if strcmp('Failed to initialize internal resources.',ME.message)||strcmp('Unable to determine the codec required.',ME.message)
                        %                     cannotanalysecallback
                        % move this to cannot-analyse
                        sharepath = 'Y:\mahmut_demir\Walking Assay\CorruptVideos';
                        if exist(sharepath,'dir') == 7
                            
                        else
                            % make it
                            mkdir(sharepath)
                        end
                        % move this file there
                        %                 copyfile([pwd,filesep,fileNames{i}],[dest_fldr,filesep,fileNames{i}])
                        disp('Will ty to move it...')
                        movefile([path_name, filesep,thesefiles(mi).name],strcat(sharepath,filesep,thesefiles(mi).name))
                        disp(['moved it to ',sharepath])
                        thisfile = thesefiles(mi).name;
                        % delete the .mat if exist
                        if exist(strcat(thisfile(1:end-3),'mat'),'file')
                            delete(strcat(thisfile(1:end-3),'mat'))
                            disp([thesefiles(mi).name,' is deleted from the current directory.'])
                        end
                    end
                end
            elseif strcmp(ftype,'rmat')
                try
                    movie = matfile([path_name,filesep,thesefiles(mi).name]);
                    h =  size(movie.frames(:,:,1),1);
                    p = movie.p;
                    
                    % working variables
                    nframes = size(movie,'frames',3);
                    
                    % clear variables
                    if ~skip
                        frame=300;
                        %                 markroi; % clears ROIs
                        %                 markstart;
                        %                 markstop;
                        %                 markleft;
                        %                 markright;
                    end
                    
                    if nframes>300
                        startframe = 300;
                        frame = 300; % current frame
                    else
                        startframe = round(nframes/2);
                        frame = round(nframes/2); % current frame
                    end
                    
                    delete(framecontrol)
                    
                    framecontrol = uicontrol(f1,'fontunits', 'normalized','FontSize',2,'units','normalized',...
                        'position',[53/xw 200/yw 500/xw 100/yw]*scalefac,'Style','slider','Value',startframe,'Min',...
                        1,'Max',nframes,'SliderStep',[.1 .9],'Callback',@framecallback);
                    
                    
                    % update GUI
                    titletext = thesefiles(mi).name;
                    set(moviefigure,'Name',titletext);
                    set(framecontrol,'Value',frame);
                    set(framecontrol2,'String',num2str(frame))
                    
                    showImage;
                catch ME
                    disp(thesefiles(mi).name)
                    disp(ME.message)
                    if strcmp('Failed to initialize internal resources.',ME.message)||strcmp('Unable to determine the codec required.',ME.message)
                        %                     cannotanalysecallback
                        % move this to cannot-analyse
                        sharepath = 'Y:\mahmut_demir\Walking Assay\CorruptVideos';
                        if exist(sharepath,'dir') == 7
                            
                        else
                            % make it
                            mkdir(sharepath)
                        end
                        % move this file there
                        %                 copyfile([pwd,filesep,fileNames{i}],[dest_fldr,filesep,fileNames{i}])
                        disp('Will ty to move it...')
                        movefile([path_name, filesep,thesefiles(mi).name],strcat(sharepath,filesep,thesefiles(mi).name))
                        disp(['moved it to ',sharepath])
                        thisfile = thesefiles(mi).name;
                        % delete the .mat if exist
                        if exist(strcat(thisfile(1:end-3),'mat'),'file')
                            delete(strcat(thisfile(1:end-3),'mat'))
                            disp([thesefiles(mi).name,' is deleted from the current directory.'])
                        end
                    end
                end
            end
            
        end
    end


%% intialise function
    function [] = initialiseAnnotate(mi)
        if strcmp(ftype,'vid')
            try
                movie = VideoReader([path_name, filesep, thesefiles(mi).name]);
                h =  get(movie,'Height');
                p.fps = get(movie,'FrameRate');
                
                % working variables
                nframes = get(movie,'NumberOfFrames');
                
                createGUI;
                showImage;
            catch ME
                
                if mi<=numel(thesefiles)
                    disp(['filename: ',thesefiles(mi).name])
                    disp('Error in execution. quitting the GUI')
                    QuitCallback
                    disp(ME.message)
                    if strcmp('Failed to initialize internal resources.',ME.message)||strcmp('Unable to determine the codec required.',ME.message)
                        disp(thesefiles(mi).name)
                        disp(ME.message)
                        if strcmp('Failed to initialize internal resources.',ME.message)||strcmp('Unable to determine the codec required.',ME.message)
                            %                     cannotanalysecallback
                            % move this to cannot-analyse
                            sharepath = 'Y:\mahmut_demir\Walking Assay\CorruptVideos';
                            if exist(sharepath,'dir') == 7
                                
                            else
                                % make it
                                mkdir(sharepath)
                            end
                            % move this file there
                            %                 copyfile([pwd,filesep,fileNames{i}],[dest_fldr,filesep,fileNames{i}])
                            disp('Will ty to move it...')
                            movefile([path_name, filesep,thesefiles(mi).name],strcat(sharepath,filesep,thesefiles(mi).name))
                            disp(['moved it to ',sharepath])
                            thisfile = thesefiles(mi).name;
                            % delete the .mat if exist
                            if exist(strcat(thisfile(1:end-3),'mat'),'file')
                                delete(strcat(thisfile(1:end-3),'mat'))
                                disp([thesefiles(mi).name,' is deleted from the current directory.'])
                            end
                        end
                    end
                else
                    disp(['filename: ',thesefiles(mi).name])
                    disp(ME.message)
                    if strcmp('Failed to initialize internal resources.',ME.message)||strcmp('Unable to determine the codec required.',ME.message)
                        disp(thesefiles(mi).name)
                        disp(ME.message)
                        if strcmp('Failed to initialize internal resources.',ME.message)||strcmp('Unable to determine the codec required.',ME.message)
                            %                     cannotanalysecallback
                            % move this to cannot-analyse
                            sharepath = 'Y:\mahmut_demir\Walking Assay\CorruptVideos';
                            if exist(sharepath,'dir') == 7
                                
                            else
                                % make it
                                mkdir(sharepath)
                            end
                            % move this file there
                            %                 copyfile([pwd,filesep,fileNames{i}],[dest_fldr,filesep,fileNames{i}])
                            disp('Will ty to move it...')
                            movefile([path_name, filesep,thesefiles(mi).name],strcat(sharepath,filesep,thesefiles(mi).name))
                            disp(['moved it to ',sharepath])
                            thisfile = thesefiles(mi).name;
                            % delete the .mat if exist
                            if exist(strcat(thisfile(1:end-3),'mat'),'file')
                                delete(strcat(thisfile(1:end-3),'mat'))
                                disp([thesefiles(mi).name,' is deleted from the current directory.'])
                            end
                        end
                        disp('Error in execution. moving to the next file')
                    end
                    skip=1;
                    nextcallback;
                    skip=0;
                    
                end
            end
        elseif strcmp(ftype,'sfrms')
            try
                movie = matfile([path_name,thesefiles(mi).name]);
                filename = thesefiles(mi).name;
                if exist([path_name, strcat(filename(1:end-11),'.mat')],'file')
                    m= matfile([path_name, strcat(filename(1:end-11),'.mat')]);
                    p = m.p;
                else
                    p.fps = 30; % default
                end
                h =  size(movie.frames(:,:,1),1);
                
                
                % working variables
                nframes = size(movie,'frames',3);
                
                createGUI;
                showImage;
            catch ME
                
                if mi<=numel(thesefiles)
                    disp(['filename: ',thesefiles(mi).name])
                    disp('Error in execution. quitting the GUI')
                    QuitCallback
                    disp(ME.message)
                    if strcmp('Failed to initialize internal resources.',ME.message)||strcmp('Unable to determine the codec required.',ME.message)
                        disp(thesefiles(mi).name)
                        disp(ME.message)
                        if strcmp('Failed to initialize internal resources.',ME.message)||strcmp('Unable to determine the codec required.',ME.message)
                            %                     cannotanalysecallback
                            % move this to cannot-analyse
                            sharepath = 'Y:\mahmut_demir\Walking Assay\CorruptVideos';
                            if exist(sharepath,'dir') == 7
                                
                            else
                                % make it
                                mkdir(sharepath)
                            end
                            % move this file there
                            %                 copyfile([pwd,filesep,fileNames{i}],[dest_fldr,filesep,fileNames{i}])
                            disp('Will ty to move it...')
                            movefile([path_name, filesep,thesefiles(mi).name],strcat(sharepath,filesep,thesefiles(mi).name))
                            disp(['moved it to ',sharepath])
                            thisfile = thesefiles(mi).name;
                            % delete the .mat if exist
                            if exist(strcat(thisfile(1:end-3),'mat'),'file')
                                delete(strcat(thisfile(1:end-3),'mat'))
                                disp([thesefiles(mi).name,' is deleted from the current directory.'])
                            end
                        end
                    end
                else
                    disp(['filename: ',thesefiles(mi).name])
                    disp(ME.message)
                    if strcmp('Failed to initialize internal resources.',ME.message)||strcmp('Unable to determine the codec required.',ME.message)
                        disp(thesefiles(mi).name)
                        disp(ME.message)
                        if strcmp('Failed to initialize internal resources.',ME.message)||strcmp('Unable to determine the codec required.',ME.message)
                            %                     cannotanalysecallback
                            % move this to cannot-analyse
                            sharepath = 'Y:\mahmut_demir\Walking Assay\CorruptVideos';
                            if exist(sharepath,'dir') == 7
                                
                            else
                                % make it
                                mkdir(sharepath)
                            end
                            % move this file there
                            %                 copyfile([pwd,filesep,fileNames{i}],[dest_fldr,filesep,fileNames{i}])
                            disp('Will ty to move it...')
                            movefile([path_name, filesep,thesefiles(mi).name],strcat(sharepath,filesep,thesefiles(mi).name))
                            disp(['moved it to ',sharepath])
                            thisfile = thesefiles(mi).name;
                            % delete the .mat if exist
                            if exist(strcat(thisfile(1:end-11),'.mat'),'file')
                                delete(strcat(thisfile(1:end-11),'.mat'))
                                disp([thesefiles(mi).name,' is deleted from the current directory.'])
                            end
                        end
                        disp('Error in execution. moving to the next file')
                    end
                    skip=1;
                    nextcallback;
                    skip=0;
                    
                end
            end
        elseif  strcmp(ftype,'rmat')
            try
                movie = matfile([path_name,filesep,thesefiles(mi).name]);
                h =  size(movie.frames(:,:,1),1);
                try
                    p = movie.p;
                catch
                    p.fps = 30; % default
                end
                
                
                % working variables
                nframes = size(movie,'frames',3);
                
                
                createGUI;
                showImage;
            catch ME
                
                if mi<=numel(thesefiles)
                    disp(['filename: ',thesefiles(mi).name])
                    disp('Error in execution. quitting the GUI')
                    QuitCallback
                    disp(ME.message)
                    if strcmp('Failed to initialize internal resources.',ME.message)||strcmp('Unable to determine the codec required.',ME.message)
                        disp(thesefiles(mi).name)
                        disp(ME.message)
                        if strcmp('Failed to initialize internal resources.',ME.message)||strcmp('Unable to determine the codec required.',ME.message)
                            %                     cannotanalysecallback
                            % move this to cannot-analyse
                            sharepath = 'Y:\mahmut_demir\Walking Assay\CorruptVideos';
                            if exist(sharepath,'dir') == 7
                                
                            else
                                % make it
                                mkdir(sharepath)
                            end
                            % move this file there
                            %                 copyfile([pwd,filesep,fileNames{i}],[dest_fldr,filesep,fileNames{i}])
                            disp('Will ty to move it...')
                            movefile([path_name, filesep,thesefiles(mi).name],strcat(sharepath,filesep,thesefiles(mi).name))
                            disp(['moved it to ',sharepath])
                            thisfile = thesefiles(mi).name;
                            % delete the .mat if exist
                            if exist(strcat(thisfile(1:end-3),'mat'),'file')
                                delete(strcat(thisfile(1:end-3),'mat'))
                                disp([thesefiles(mi).name,' is deleted from the current directory.'])
                            end
                        end
                    end
                else
                    disp(['filename: ',thesefiles(mi).name])
                    disp(ME.message)
                    if strcmp('Failed to initialize internal resources.',ME.message)||strcmp('Unable to determine the codec required.',ME.message)
                        disp(thesefiles(mi).name)
                        disp(ME.message)
                        if strcmp('Failed to initialize internal resources.',ME.message)||strcmp('Unable to determine the codec required.',ME.message)
                            %                     cannotanalysecallback
                            % move this to cannot-analyse
                            sharepath = 'Y:\mahmut_demir\Walking Assay\CorruptVideos';
                            if exist(sharepath,'dir') == 7
                                
                            else
                                % make it
                                mkdir(sharepath)
                            end
                            % move this file there
                            %                 copyfile([pwd,filesep,fileNames{i}],[dest_fldr,filesep,fileNames{i}])
                            disp('Will ty to move it...')
                            movefile([path_name, filesep,thesefiles(mi).name],strcat(sharepath,filesep,thesefiles(mi).name))
                            disp(['moved it to ',sharepath])
                            thisfile = thesefiles(mi).name;
                            % delete the .mat if exist
                            if exist(strcat(thisfile(1:end-3),'mat'),'file')
                                delete(strcat(thisfile(1:end-3),'mat'))
                                disp([thesefiles(mi).name,' is deleted from the current directory.'])
                            end
                        end
                        disp('Error in execution. moving to the next file')
                    end
                    skip=1;
                    nextcallback;
                    skip=0;
                    
                end
            end
        end
        
    end

%% crop radio call
    function [] = crop_radio_call(~,~)
        % if selected crop if not do not crop
        showImage;
        saveTrackData;
    end

%% callback functions
    function [] = cropboxcall(~,~)
        crop_box.lcrp = str2double(get(lcrp_edit,'string'));
        crop_box.rcrp = str2double(get(rcrp_edit,'string'));
        crop_box.tcrp = str2double(get(tcrp_edit,'string'));
        crop_box.bcrp = str2double(get(bcrp_edit,'string'));
        
        saveTrackData;
        showImage;
        
    end

    function [] = framecallback(~,~)
        frame = ceil((get(framecontrol,'Value')));
        if frame<1
            frame = 1;
        elseif frame>nframes
            frame= nframes;
        end
        showImage();
        set(framecontrol2,'String',mat2str(frame));
        set(timecontrol,'String',num2str(frame/p.fps,'%5.2f'));
    end


    function [] = frame2callback(~,~)
        frame = ceil(str2double(get(framecontrol2,'String')));
        if frame<1
            frame = 1;
        elseif frame>nframes
            frame= nframes;
        end
        showImage();
        set(framecontrol,'Value',(frame));
        set(timecontrol,'String',num2str(frame/p.fps,'%5.2f'));
    end

    function [] = time2callback(~,~)
        frame = round((str2double(get(timecontrol,'String')))*p.fps);
        if frame<1
            frame = 1;
        elseif frame>nframes
            frame= nframes;
        end
        showImage();
        set(framecontrol,'Value',(frame));
        set(framecontrol2,'String',mat2str(frame));
        set(timecontrol,'String',num2str(frame/p.fps,'%5.2f'));
    end

    function [] = showImage(~,~)
        % check which module is selected
        if get(show_source_radio,'val')==1 % source radio called
            source_call;
        else
            if strcmp(ftype,'vid')
                ff = read(movie,frame);
            else
                ff = movie.frames(:,:,frame);
            end
            crpx = 1+crop_box.lcrp:size(ff,2)-crop_box.rcrp;
            crpy = 1+crop_box.tcrp:size(ff,1)-crop_box.bcrp;
            figure(moviefigure), axis image
            if get(crop_radio,'val')==1
                ffmask = ones(size(ff))./2;
                ffmask(crpy,crpx) = 1;
                ff = uint8(double(ff).*ffmask);
            end
            ImHandle = imagesc(adapthisteq(ff)); %colormap(gray)
            axis equal
            axis tight
            title([mat2str(frame),' - ',num2str(frame/p.fps,'%5.2f'),' sec']);
            DrawCam_call;
        end
    end



    function  [] = saveTrackData(~,~)
        moviefile = thesefiles(mi).name;
        filename = thesefiles(mi).name;
        % construct parameter space
        p.crop_box = crop_box;
        p.source = source;
        p.mm_per_px = mm_per_px;
        p.camera = camera;
        if strcmp(ftype,'vid')
            ff = read(movie,frame);
        else
            ff = movie.frames(:,:,frame);
        end
        crpx = 1+crop_box.lcrp:size(ff,2)-crop_box.rcrp;
        crpy = 1+crop_box.tcrp:size(ff,1)-crop_box.bcrp;
        mask = zeros(size(ff));
        mask(crpy,crpx) = 1;
        p.mask = mask;
        % check the file and create or append
        if strcmp(ftype,'vid')
            if exist([path_name, filesep, strcat(filename(1:end-3),'mat')],'file')
                save([path_name, filesep, strcat(filename(1:end-3),'mat')],'p','moviefile','-append');
            else
                save([path_name, filesep, strcat(filename(1:end-3),'mat')],'p','moviefile');
            end
            save([defpath,filesep,'HandleFlyWalkVideo.Defaults.mat'],'crop_box','source','mm_per_px','camera');
        elseif strcmp(ftype,'sfrms')
            if exist([path_name, filesep, strcat(filename(1:end-11),'.mat')],'file')
                save([path_name, filesep, strcat(filename(1:end-11),'.mat')],'p','moviefile','-append');
            else
                save([path_name, filesep, strcat(filename(1:end-11),'.mat')],'p','moviefile');
            end
            save([defpath,filesep,'HandleFlyWalkVideo.Defaults.mat'],'crop_box','source','mm_per_px','camera');
        elseif strcmp(ftype,'rmat')
            if exist([path_name, filesep, filename],'file')
                save([path_name, filesep, filename],'p','moviefile','-append');
            else
                save([path_name, filesep, filename],'p','moviefile');
            end
            save([defpath,filesep,'HandleFlyWalkVideo.Defaults.mat'],'crop_box','source','mm_per_px','camera');
        end
        
        
    end

    function [] = QuitCallback(~,~)
        %    selection = questdlg('Are you sure you want to quit HandleFlyWalkVideo?','Confirm quit.','Yes','No','Yes');
        selection = 'Yes';
        switch selection
            case 'Yes'
                delete(moviefigure);
                delete(f1)
                
                try
                    delete(moviefigure);
                    delete(f1)
                catch
                end
            case 'No'
                return
        end
    end

end
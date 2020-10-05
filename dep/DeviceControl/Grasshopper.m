
%% initialize the camera window
function [] = Grasshopper()
% check if the camera is connected
imaqreset;
imaf = imaqhwinfo;
if isempty(ismember(imaf.InstalledAdaptors,{'pointgrey'})) || any(ismember(imaf.InstalledAdaptors,{'pointgrey'}))==0 % adaptor is not installed. Stop
    error('Adaptor is not installed. Install pointgrey adaptor first.');
elseif any(ismember(imaf.InstalledAdaptors,{'pointgrey'})) % adaptor is installed. Now check if camera is connected
    iadinf = imaqhwinfo('pointgrey');
    if isempty(iadinf.DeviceIDs)
        camstate = 'off';
        % camera is not connected
        disp('No camera found. Check camera connection.')

    else
        scsz = get(0,'ScreenSize');
        yw = 5*scsz(4)/7;
        xw = 3*scsz(3)/5;
        if xw<1070
            xw = 1070;
        end
        fcam = figure('Position',[scsz(3)/7 scsz(4)/7 xw 5*scsz(4)/7],'NumberTitle','off','Visible','on','Name', 'Grasshopper','Menubar', 'none',...
            'Toolbar','figure','resize', 'on' ,'CloseRequestFcn',@QuitGrasshopperCallback); 

        % uicontrol('String', 'Close', 'Callback', 'close(gcf)');

        if exist('Grasshopper.Cam_Settings.mat','file') == 2
            load('Grasshopper.Cam_Settings.mat');
        else
            % default
            ROI_Matrix = [0 0 2048 2048];    % Region of interest matrix for the camera
            frame_rate_perc = 10;   % frame rate percentage for the camera
            gain = 3;  % gain for the camera
            shutter = 5; % shutter duration of the camera
            vidmode = 'F7_Mono8_2048x2048_Mode0'; % default video input mode
            logformat = 'Motion JPEG 2000';           % image logging mode
            logmode = 'disk&memory';                 % image data logging location
            lastexpname = 'CS_1_3ds_7do_EXP_1';      % file name for the last experiment
        end

%%%%% Settings Panel
        CamSettingsPanel = uipanel('parent', fcam,'Title','Settings', 'fontunits', 'normalized','FontSize',.1,'units','normalized','pos',[25/xw 25/yw 250/xw 100/yw]);

        
        camPercenttext = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.4,'units','normalized','Style','text',...
            'position',[100/xw 62/yw 40/xw 30/yw],'String','%','fontweight','bold');
        camFrameRatetext = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.4,'units','normalized','Style','text',...
            'position',[70/xw 85/yw 40/xw 30/yw],'String','F.R.','fontweight','bold');
        camFrameRateedit = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.4,'units','normalized','style','edit',...
            'position',[70/xw 70/yw 40/xw 30/yw],'string',num2str(frame_rate_perc),'callback',@FrameRate_call);



        camGaintext = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.4,'units','normalized','Style','text',...
            'position',[130/xw 85/yw 60/xw 30/yw],'String','Gain','fontweight','bold');
        camGainedit = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.4,'units','normalized','style','edit',...
            'position',[140/xw 70/yw 40/xw 30/yw],'string',num2str(gain),'callback',@Gain_call);


        camShuttertext = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.4,'units','normalized','Style','text',...
            'position',[195/xw 85/yw 50/xw 30/yw],'String','Shutter','fontweight','bold');
        cammstext = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.4,'units','normalized','Style','text',...
            'position',[240/xw 65/yw 30/xw 30/yw],'String','ms','fontweight','bold');
        camShutteredit = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.4,'units','normalized','style','edit',...
            'position',[200/xw 70/yw 40/xw 30/yw],'string',num2str(shutter),'callback',@Shutter_call);
        
        camROItext = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.4,'units','normalized','Style','text','String','ROI (pxl)','fontweight','bold',...
            'pos',[29/xw 32/yw 30/xw 30/yw]);
%         camPxltext = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.4,'units','normalized','Style','text','position',[215/xw 30/yw 60/xw 30/yw],...
%             'String','pxl','fontweight','bold');
        ROIeditStr = num2str(ROI_Matrix);
        camROIedit = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.4,'units','normalized','style','edit',...
            'position',[60/xw 30/yw 200/xw 35/yw],'string',ROIeditStr,'callback',@ROI_call);
        
%%%%% Frame Rate Panel
        CamFrameDelayPanel = uipanel('parent', fcam,'fontunits', 'normalized','FontSize',.1,'units','normalized','Title','Frame Rate','pos',[280/xw 25/yw 110/xw 100/yw]);
        GetFrameRateButton = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
            'Position',[285/xw 30/yw 100/xw 40/yw],'Style','pushbutton','Enable','on','String','Get F.R.','Callback',@GetFrameRate_call);
        camFRunittext = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.5,'units','normalized','Style','text',...
            'position',[345/xw 70/yw 40/xw 30/yw],'String','fps','fontweight','bold');
        camFRtext = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.5,'units','normalized','Style','text',...
            'position',[285/xw 70/yw 50/xw 30/yw],'String','NA','backgroundc',get(fcam,'color'),'fontweight','bold','foregroundcolor',[.9 .1 .1]);

        
%%%%% Options Panel
        % acquire button
         OptionsPanel = uipanel('parent', fcam,'fontunits', 'normalized','FontSize',.1,'units','normalized','Title','Options','pos',[395/xw 25/yw 340/xw 100/yw]);
         
         vidformat_text = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.8,'units','normalized','Style','text',...
            'position',[400/xw 34/yw 50/xw 15/yw],'String','input','fontweight','bold');
        % get supported formats
        caminf = imaqhwinfo('pointgrey',1);
        camformats = caminf.SupportedFormats;
        [~,vm_value] = ismember({vidmode},camformats);
         vidformat_popup = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.45,'units','normalized','Style', 'popup',...
                       'String',camformats ,'Position', [452/xw 30/yw 175/xw 20/yw],'Value',vm_value,'Callback',@vidformat_popup_call); 
                   
         logformat_text = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.8,'units','normalized','Style','text',...
            'position',[400/xw 55/yw 50/xw 15/yw],'String','log as','fontweight','bold');
        logformats = {'Motion JPEG 2000','Archival','Motion JPEG AVI','Uncompressed AVI','MPEG-4','Grayscale AVI','mat file','tiff'};
        [~,lm_value] = ismember({logformat},logformats);
        logformat = logformats{lm_value};
        logformat_popup = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.45,'units','normalized','Style', 'popup',...
                       'String', logformats,'Position', [452/xw 51/yw 175/xw 20/yw],'Value',lm_value,'Callback',@logformat_popup_call); 
        
        MetaButton = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
            'Position',[650/xw 93/yw 80/xw 23/yw],'Style','pushbutton','Enable','on','String','metadata','Callback',@meta_call);
                   
                   % determine the extension type and constraint
        switch lm_value
            case 1  %'Motion JPEG 2000'
                logext = '.mj2';
                logconst = 'diskLogger.LosslessCompression = true;';
            case 2  %'Archival'
                logext = '.mj2';
                logconst = '';
            case 3  %'Motion JPEG AVI'
                logext = '.avi';
                logconst ='diskLogger.Quality = 100;';
            case 4  %'Uncompressed AVI'
                logext = '.avi';
                logconst ='';
            case 5  %'MPEG-4'
                logext = '.mp4';
                logconst ='diskLogger.Quality = 100;';
            case 6  %'Grayscale AVI'
                logext = '.avi';
                logconst ='';
            case 7  %'mat file'
                logext = '.mat';
                logconst ='';
            case 8  %'tiff'
                logext = '.tif';
                logconst ='';
            otherwise
                error('check the code for logging format')
        end

        
%%%%% Recording Panel
        % acquire button
         RecordPanel = uipanel('parent', fcam,'fontunits', 'normalized','FontSize',.1,'units','normalized','Title','Record','pos',[740/xw 25/yw 300/xw 100/yw]);



%         cam.TriggerFrameDelay = 0;


        frm_num_radio = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.4,'units','normalized','Style','rad',...
            'position',[930/xw 65/yw 50/xw 30/yw],'String','frm','fontweight','bold','Value',0,'Callback', @frm_num_rad_call);
        frm_sec_radio = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.4,'units','normalized','Style','rad',...
            'position',[980/xw 65/yw 50/xw 30/yw],'String','sec','fontweight','bold','Value',1,'Callback', @frm_sec_rad_call);
        
        
%         sp=propinfo(cam,'LoggingMode');
%         logging_popup = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.45,'units','normalized','Style', 'popup',...
%                        'String', sp.ConstraintValue,'Position', [835/xw 72/yw 85/xw 20/yw],'Value',3,'Callback',@popupCallback);
       if (strcmp(logformat,'mat file'))||(strcmp(logformat,'tiff'));
           logmodelist = {'memory'};
       else
           logmodelist = {'disk','disk&memory'};
       end
       [~,ll_value] = ismember({logmode},logmodelist);
       logging_popup = uicontrol('parent',fcam,'fontunits', 'normalized','FontSize',.45,'units','normalized','Style', 'popup',...
                       'String',logmodelist,'Position', [835/xw 72/yw 85/xw 20/yw],'Value',ll_value,'Callback',@logging_popup_call);  
                   
                   
      

    %     num_of_frames_Titletext = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.4,'units','normalized','Style','text',...
    %         'position',[925/xw 62/yw 40/xw 30/yw],'String','frm #','fontweight','bold');
        num_of_frames_edit = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.5,'units','normalized','style','edit',...
            'position',[925/xw 30/yw 105/xw 40/yw],'string','0','callback',@num_of_frames_call);
        camDelayTitletext = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.3,'units','normalized','Style','text',...
            'position',[855/xw 38/yw 50/xw 30/yw],'String','Delay','fontweight','bold');
        camDelayedit = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.5,'units','normalized','style','edit',...
            'position',[865/xw 30/yw 35/xw 27/yw],'string','0','callback',@FrameDelay_call);
        AcquireButton = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
            'Position',[750/xw 30/yw 100/xw 40/yw],'Style','pushbutton','Enable','on','String','Acquire','Callback',@Acquire_call);

        Aviname_edit = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.5,'units','normalized','style','edit',...
            'position',[750/xw 95/yw 285/xw 17/yw],'string','sample.avi','callback',@aviname_call);

        if exist('C:','dir')==7
            if exist(strcat('C:\Data\',datestr(now,'yyyy_mm_dd')),'dir')==0
                mkdir(strcat('C:\Data\',datestr(now,'yyyy_mm_dd')));
            end
            savepath = ['C:\Data\',datestr(now,'yyyy_mm_dd')];
            savestr=strcat(datestr(now,'yyyy_mm_dd'),'_',lastexpname);
    %       savestr=uiputfile(strcat('C:\Data\',datestr(now,'yyyy_mm_dd'),'\',datestr(now,'yyyy_mm_dd'),'_vid.mat'));
        else
            savepath = pwd;
            savestr=strcat(datestr(now,'yyyy_mm_dd'),'_',lastexpname);
    %       camsavefile=uiputfile(strcat(pwd,'\',datestr(now,'yyyy_mm_dd'),'_vid.mat'));
        end

        set(Aviname_edit,'string',savestr);

        SaveToButton = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.45,'units','normalized',...
            'Position',[750/xw 73/yw 73/xw 20/yw],'Style','pushbutton','Enable','on','String','SaveTo','Callback',@saveto_call);

        RefreshButton = uicontrol('parent', fcam,'fontunits', 'normalized','FontSize',.3,'units','normalized',...
            'Position',[20/xw 570/yw 60/xw 40/yw],'Style','pushbutton','Enable','on','String','Refresh','Callback',@refresh_call);

    %     campreviewaxes = axes('units','pixels','position',[25 200 scsz(3)/2-65 scsz(4)-90],'Visible','off','nextplot','replacechildren');
%         cam = videoinput('pointgrey', 1, 'F7_Mono8_2048x2048_Mode0');
        cam = videoinput('pointgrey', 1, vidmode);
        src_cam = getselectedsource(cam);
        cam.ROIPosition = ROI_Matrix; % set ROI[0 290 2048 1400];
        src_cam.Gain = gain;
        % set shutter
        set(camShutteredit,'string',shutter');
        src_cam.Shutter = shutter;
        src_cam.ExposureMode = 'Off';
        cam.FramesPerTrigger = Inf; % Capture frames until we manually stop it
%         src_cam.FrameRatePercentage = frame_rate_perc; % previous version
        src_cam.FrameRate = frame_rate_perc;
        vidRes = cam.VideoResolution; 
        imWidth = vidRes(1);
        imHeight = vidRes(2);
        nBands = cam.NumberOfBands;
        hImage = image( zeros(imHeight, imWidth, nBands) );
        preview(cam, hImage);
        axis image

        % get frame rate
        GetFrameRate_call
    end
end

function [] = vidformat_popup_call(~,~)
    vm_value= get(vidformat_popup,'Value');  % Get the users choice.
    vidmode = camformats{vm_value};
    stoppreview(cam)
    cam = videoinput('pointgrey', 1, vidmode);
    src_cam = getselectedsource(cam);
    cam.ROIPosition = ROI_Matrix; % set ROI[0 290 2048 1400];
    src_cam.Gain = gain;
    src_cam.Shutter = shutter;
    src_cam.ExposureMode = 'Off';
    cam.FramesPerTrigger = Inf; % Capture frames until we manually stop it
    src_cam.FrameRate = frame_rate_perc;
    cam.LoggingMode = logmode;
    vidRes = cam.VideoResolution; 
    imWidth = vidRes(1);
    imHeight = vidRes(2);
    nBands = cam.NumberOfBands;
    hImage = image( zeros(imHeight, imWidth, nBands) );
    preview(cam, hImage);
    axis image
    save('Grasshopper.Cam_Settings.mat','ROI_Matrix','frame_rate_perc','gain','shutter','vidmode','logformat','logmode','lastexpname');
    GetFrameRate_call
end

function [] = logformat_popup_call(~,~)
    lm_value = get(logformat_popup,'Value');  % Get the users choice.
    logformat = logformats{lm_value};
    switch lm_value
        case 1  %'Motion JPEG 2000'
            logext = '.mj2';
            logconst = 'diskLogger.LosslessCompression = true;';
            if strcmp(logmode,'memory')
                logmodelist = {'disk','disk&memory'};
                [~,ll_value] = ismember({'disk'},logmodelist);
                set(logging_popup,'String',logmodelist,'Value',ll_value)
                logging_popup_call
            end
        case 2  %'Archival'
            logext = '.mj2';
            logconst = '';
            if strcmp(logmode,'memory')
                logmodelist = {'disk','disk&memory'};
                [~,ll_value] = ismember({'disk'},logmodelist);
                set(logging_popup,'String',logmodelist,'Value',ll_value)
                logging_popup_call
            end
        case 3  %'Motion JPEG AVI'
            logext = '.avi';
            logconst ='diskLogger.Quality = 100';
            if strcmp(logmode,'memory')
                logmodelist = {'disk','disk&memory'};
                [~,ll_value] = ismember({'disk'},logmodelist);
                set(logging_popup,'String',logmodelist,'Value',ll_value)
                logging_popup_call
            end
        case 4  %'Uncompressed AVI'
            logext = '.avi';
            logconst ='';
            if strcmp(logmode,'memory')
                logmodelist = {'disk','disk&memory'};
                [~,ll_value] = ismember({'disk'},logmodelist);
                set(logging_popup,'String',logmodelist,'Value',ll_value)
                logging_popup_call
            end
        case 5  %'MPEG-4'
            logext = '.mp4';
            logconst ='diskLogger.Quality = 100';
            if strcmp(logmode,'memory')
                logmodelist = {'disk','disk&memory'};
                [~,ll_value] = ismember({'disk'},logmodelist);
                set(logging_popup,'String',logmodelist,'Value',ll_value)
                logging_popup_call              
            end
        case 6  %'Grayscale AVI'
            logext = '.avi';
            logconst ='';
            if strcmp(logmode,'memory')
                logmodelist = {'disk','disk&memory'};
                [~,ll_value] = ismember({'disk'},logmodelist);
                set(logging_popup,'String',logmodelist,'Value',ll_value)
                logging_popup_call
            end

        case 7  %'mat file'
            logext = '.mat';
            logconst ='';
            if ~strcmp(logmode,'memory')
                logmodelist = {'memory'};
                [~,ll_value] = ismember({'memory'},logmodelist);
                set(logging_popup,'String',logmodelist,'Value',ll_value)
                logging_popup_call
            end
        case 8  %'tiff'
            logext = '.tif';
            logconst ='';
            if ~strcmp(logmode,'memory')
                logmodelist = {'memory'};
                [~,ll_value] = ismember({'memory'},logmodelist);
                set(logging_popup,'String',logmodelist,'Value',ll_value)
                logging_popup_call
            end
        otherwise
            error('check the code for logging format')
    end
    save('Grasshopper.Cam_Settings.mat','ROI_Matrix','frame_rate_perc','gain','shutter','vidmode','logformat','logmode','lastexpname');
end


function [] = logging_popup_call(~,~)
    ll_value= get(logging_popup,'Value');  % Get the users choice.
    logmode = logmodelist{ll_value};
    cam.LoggingMode = logmode;
    save('Grasshopper.Cam_Settings.mat','ROI_Matrix','frame_rate_perc','gain','shutter','vidmode','logformat','logmode','lastexpname');
end
        

function [] = refresh_call(~,~)
    stoppreview(cam);
    preview(cam, hImage);
    axis image
    GetFrameRate_call
end

function [] = meta_call(~,~)
    metaGui(strcat(savepath,'\',get(Aviname_edit,'String'),'.mat'))
end

function [] = frm_num_rad_call(~,~)
    R = [get(frm_num_radio,'val'), get(frm_sec_radio,'val')];  % Get state of radios.

    if R(1)==1 % frm selected unselect sec
        set(frm_sec_radio,'val',0);
    else % select sec
        set(frm_sec_radio,'val',1);
    end
end

function [] = frm_sec_rad_call(~,~)
    R = [get(frm_num_radio,'val'), get(frm_sec_radio,'val')];  % Get state of radios.

    if R(2)==1 % frm selected unselect sec
        set(frm_num_radio,'val',0);
    else % select sec
        set(frm_num_radio,'val',1);
    end
end



%% get frame rate callback
function [] = GetFrameRate_call(~,~)
    % Callback for measuring current frame rate.
        cam.FramesPerTrigger = round(frame_rate_perc*3);    % capture 30 frames
        set(AcquireButton,'Enable','off');
        set(GetFrameRateButton,'Enable','off');
        set(camROIedit,'Enable','off');
        set(camFrameRateedit,'Enable','off');
        set(camGainedit,'Enable','off');
        set(camShutteredit,'Enable','off');
        set(frm_num_radio,'Enable','off');
        set(frm_sec_radio,'Enable','off');   
        set(num_of_frames_edit,'Enable','off');
        set(camDelayedit,'Enable','off');
        set(Aviname_edit,'Enable','off');
        set(SaveToButton,'Enable','off');   
        set(RefreshButton,'Enable','off');
        set(vidformat_popup,'Enable','off');
        set(logformat_popup,'Enable','off'); 
        set(logging_popup,'Enable','off');
        set(MetaButton,'Enable','off');
      
        cam.LoggingMode = 'disk&memory';
        diskLoggerfr = VideoWriter([savepath,'\','frmrate.mj2'],'Motion JPEG 2000');
        cam.DiskLogger = diskLoggerfr;
        start(cam)
        % Wait for data logging to end before retrieving data.  
        wait(cam,30);
        % Retrieve the timestamps.
        [~,timeStamp] = getdata(cam);
        % calculate frame rate 
        FrameRate = 1/mean(diff(timeStamp));
        % stop the camera 
        stop(cam)
        close(diskLoggerfr)
        cam.LoggingMode = logmode;
        set(camFRtext,'string',num2str(FrameRate,'%5.2f'));
        set(AcquireButton,'Enable','on');
        set(GetFrameRateButton,'Enable','on');
        set(camROIedit,'Enable','on');
        set(camFrameRateedit,'Enable','on');
        set(camGainedit,'Enable','on');
        set(camShutteredit,'Enable','on');
        set(frm_num_radio,'Enable','on');
        set(frm_sec_radio,'Enable','on');   
        set(num_of_frames_edit,'Enable','on');
        set(camDelayedit,'Enable','on');
        set(Aviname_edit,'Enable','on');
        set(SaveToButton,'Enable','on');   
        set(RefreshButton,'Enable','on');
        set(vidformat_popup,'Enable','on');
        set(logformat_popup,'Enable','on'); 
        set(logging_popup,'Enable','on');
        set(MetaButton,'Enable','on');
        preview(cam, hImage);
        axis image
end

% record call
function [] = Acquire_call(~,~)
    
    if strcmp(get(AcquireButton,'String'),'Acquire'); % starts acquiring
        
%         if exist(strcat(savepath,'\',savestr,'.avi'),'file') % for grayscale avi
        if exist(strcat(savepath,'\',savestr,logext),'file') % for motion jpeg 2000
            % file already exists,get another name
            saveto_call
        end  
        
        FrameRate = str2double(get(camFRtext,'string'));
        R = [get(frm_num_radio,'val'), get(frm_sec_radio,'val')];  % Get state of radios.
        if R(1)==1 % frame # selected
            num_of_frames = round(str2double(get(num_of_frames_edit,'string')));
        else
            num_of_frames = round(str2double(get(num_of_frames_edit,'string'))*FrameRate);
        end
        if num_of_frames == 0
            cam.FramesPerTrigger = Inf;   % capture until stopped
            % set recording to memory and disk
            if ~strcmp(logmode,'memory')
                diskLogger = VideoWriter([savepath,'\',savestr,logext],logformat);
                eval(logconst);
                diskLogger.FrameRate = FrameRate;
                cam.DiskLogger = diskLogger;

            else
                cam.DiskLogger = [];
            end
            set(AcquireButton,'String','STOP','BackgroundColor','red');
            set(GetFrameRateButton,'Enable','off');
            set(camROIedit,'Enable','off');
            set(camFrameRateedit,'Enable','off');
            set(camGainedit,'Enable','off');
            set(camShutteredit,'Enable','off');
            set(frm_num_radio,'Enable','off');
            set(frm_sec_radio,'Enable','off');   
            set(num_of_frames_edit,'Enable','off');
            set(camDelayedit,'Enable','off');
            set(Aviname_edit,'Enable','off');
            set(SaveToButton,'Enable','off');   
            set(RefreshButton,'Enable','off');
            set(vidformat_popup,'Enable','off');
            set(logformat_popup,'Enable','off'); 
            set(logging_popup,'Enable','off');
            set(MetaButton,'Enable','off');
            start(cam)
            
        else
            % record definite number of frames           
            %Now start acquisition
            cam.FramesPerTrigger = num_of_frames;   % capture definete number of frames
            set(AcquireButton,'String','REC','BackgroundColor','red','Enable','off');
            set(GetFrameRateButton,'Enable','off');
            set(camROIedit,'Enable','off');
            set(camFrameRateedit,'Enable','off');
            set(camGainedit,'Enable','off');
            set(camShutteredit,'Enable','off');
            set(frm_num_radio,'Enable','off');
            set(frm_sec_radio,'Enable','off');   
            set(num_of_frames_edit,'Enable','off');
            set(camDelayedit,'Enable','off');
            set(Aviname_edit,'Enable','off');
            set(SaveToButton,'Enable','off');   
            set(RefreshButton,'Enable','off');
            set(vidformat_popup,'Enable','off');
            set(logformat_popup,'Enable','off'); 
            set(logging_popup,'Enable','off');
            set(MetaButton,'Enable','off');
            
            % set recording to memory and disk
            if ~strcmp(logmode,'memory')
                diskLogger = VideoWriter([savepath,'\',savestr,logext],logformat);
                eval(logconst);
                diskLogger.FrameRate = FrameRate;
                cam.DiskLogger = diskLogger;
            else
                cam.DiskLogger = [];
            end
            start(cam)
            % Wait for data logging to end before retrieving data.  
            wait(cam,round(num_of_frames/FrameRate)+30);
            
            % Retrieve the timestamps.
            
            set(AcquireButton,'String','Busy','BackgroundColor','y');
            if strcmp(logmode,'memory')
               [videodata,timestampscam,~] = getdata(cam);
            elseif strcmp(logmode,'disk&memory')
                [~,timestampscam,~] = getdata(cam);
            end
            % select place to save
            
            %When logging large amounts of data to disk, disk writing occasionally 
            %lags behind the acquisition. To determine whether all frames are written to disk
            %you can optionally use the DiskLoggerFrameCount property.
            if ~strcmp(logmode,'memory')
                while (cam.FramesAcquired ~= cam.DiskLoggerFrameCount) 
                    pause(.1)
                end
                disp(['All acquired frames are logged. ', num2str(cam.FramesAcquired),' frames']);
            end


            stop(cam)
            % save timestapms
            if strcmp(logmode,'disk&memory')
                save(strcat(savepath,'\',savestr,'_timestamps.mat'), 'timestampscam');
                disp(['Data saved to file: ', strcat(savepath,'\',savestr,logext)]);
                close(diskLogger)
            elseif strcmp(logmode,'memory')
                save(strcat(savepath,'\',savestr,logext), 'videodata', 'timestampscam');
                disp(['Data saved to file: ', strcat(savepath,'\',savestr,logext)]);
            else
%                 close(diskLogger)
            end


            set(AcquireButton,'String','Acquire');
            clr=get(fcam,'color');
            set(AcquireButton,'Enable','on','BackgroundColor',clr);
            set(GetFrameRateButton,'Enable','on');
            set(camROIedit,'Enable','on');
            set(camFrameRateedit,'Enable','on');
            set(camGainedit,'Enable','on');
            set(camShutteredit,'Enable','on');
            set(frm_num_radio,'Enable','on');
            set(frm_sec_radio,'Enable','on');   
            set(num_of_frames_edit,'Enable','on');
            set(camDelayedit,'Enable','on');
            set(Aviname_edit,'Enable','on');
            set(SaveToButton,'Enable','on');   
            set(RefreshButton,'Enable','on');
            set(vidformat_popup,'Enable','on');
            set(logformat_popup,'Enable','on'); 
            set(logging_popup,'Enable','on');
            set(MetaButton,'Enable','on');
            preview(cam, hImage);
            axis image
        end       
    elseif strcmp(get(AcquireButton,'String'),'STOP'); % already started acquisition. Now stop and save the data
            set(AcquireButton,'String','Busy','BackgroundColor','y');
            stop(cam)
            %When logging large amounts of data to disk, disk writing occasionally 
            %lags behind the acquisition. To determine whether all frames are written to disk
            %you can optionally use the DiskLoggerFrameCount property.

            if ~strcmp(logmode,'memory')
                while (cam.FramesAcquired ~= cam.DiskLoggerFrameCount) 
                    pause(.1)
                end
                disp(['All acquired frames are logged. ', num2str(cam.FramesAcquired),' frames']);
            end
            % Wait for data logging to end before retrieving data.  
            wait(cam);
            if strcmp(logmode,'memory')
               [videodata,timestampscam,~] = getdata(cam);
            elseif strcmp(logmode,'disk&memory')
                [~,timestampscam,~] = getdata(cam);
            end
            
            % select place to save
            if strcmp(logmode,'disk&memory')
                save(strcat(savepath,'\',savestr,'_timestamps.mat'), 'timestampscam');
                disp(['Data saved to file: ', strcat(savepath,'\',savestr,logext)]);
%                 close(diskLogger)
            elseif strcmp(logmode,'memory')
                save(strcat(savepath,'\',savestr,logext), 'videodata', 'timestampscam');
                disp(['Data saved to file: ', strcat(savepath,'\',savestr,logext)]);
            else
%                 close(diskLogger)
            end
            
            clr=get(fcam,'color');
            set(AcquireButton,'Enable','on','BackgroundColor',clr);
            set(GetFrameRateButton,'Enable','on');
            set(camROIedit,'Enable','on');
            set(camFrameRateedit,'Enable','on');
            set(camGainedit,'Enable','on');
            set(camShutteredit,'Enable','on');
            set(frm_num_radio,'Enable','on');
            set(frm_sec_radio,'Enable','on');   
            set(num_of_frames_edit,'Enable','on');
            set(camDelayedit,'Enable','on');
            set(Aviname_edit,'Enable','on');
            set(SaveToButton,'Enable','on');   
            set(RefreshButton,'Enable','on');
            set(vidformat_popup,'Enable','on');
            set(logformat_popup,'Enable','on'); 
            set(logging_popup,'Enable','on');
            set(MetaButton,'Enable','on');
            set(AcquireButton,'String','Acquire');
            preview(cam, hImage);
            axis image
            

    end
    % check save name
    aviname_call
        
end



%% get delay callback
function [] = FrameDelay_call(~,~)
    % Callback for setting the number of frames to be skipped after
    % recording starts
        cam.TriggerFrameDelay = round(str2double(get(camDelayedit,'string')));
end

%% number of frames call
function [] = num_of_frames_call(~,~)
    
end

    %% roi callback
function [] = ROI_call(~,~)
    % Callback for ROI editbox.
    ROIeditStr  = get(camROIedit,'string');
    ROI_Matrix = str2num(ROIeditStr);
    sp=propinfo(cam);
    % get default frame size
    roixw = sp.ROIPosition.DefaultValue(3);
    roiyw = sp.ROIPosition.DefaultValue(4);
    % check input and adjust
    if (ROI_Matrix(1)<0)||(ROI_Matrix(1)>=roixw)
        ROI_Matrix(1) = 0;
    end
    if (ROI_Matrix(1)+ROI_Matrix(3))>roixw
        ROI_Matrix(3) = roixw - ROI_Matrix(1);
    end
    if (ROI_Matrix(2)<0)||(ROI_Matrix(2)>=roiyw)
        ROI_Matrix(2) = 0;
    end
    if (ROI_Matrix(2)+ROI_Matrix(4))>roiyw
        ROI_Matrix(4) = roiyw - ROI_Matrix(2);
    end
    waitnum = 0;
    while strcmp(cam.Running,'on')
        wait(.1)
        waitnum = waitnum+.1;
        if waitnum >10
            error('camera is running.')
        end
    end
    cam.ROIPosition = ROI_Matrix; % set ROI matrix
    ROI_Matrix = cam.ROIPosition;
    set(camROIedit,'string',num2str(ROI_Matrix));
    % save new camera settings
    save('Grasshopper.Cam_Settings.mat','ROI_Matrix','frame_rate_perc','gain','shutter','vidmode','logformat','logmode','lastexpname');
    GetFrameRate_call

end

%% frame rate percentage call back
function [] = FrameRate_call(~,~)
    % Callback for Frame Rate editbox.
    frame_rate_perc  = str2double(get(camFrameRateedit,'string'));
    % check if the input is whitin the limits
    sp=propinfo(getselectedsource(cam));
    if frame_rate_perc<=sp.FrameRate.ConstraintValue(1)
        frame_rate_perc = floor(sp.FrameRate.ConstraintValue(1));
    elseif frame_rate_perc>sp.FrameRate.ConstraintValue(2)
        frame_rate_perc = floor(sp.FrameRate.ConstraintValue(2));
    end
    set(camFrameRateedit,'string',num2str(frame_rate_perc));
    waitnum = 0;
    while strcmp(cam.Running,'on')
        wait(.1)
        waitnum = waitnum+.1;
        if waitnum >10
            error('camera is running.')
        end
    end
    src_cam.FrameRate = frame_rate_perc; % set frame rate percentage
    % save new camera settings
    save('Grasshopper.Cam_Settings.mat','ROI_Matrix','frame_rate_perc','gain','shutter','vidmode','logformat','logmode','lastexpname');
    GetFrameRate_call
end

%% gain call back
function [] = Gain_call(~,~)
    % Callback for Gain editbox.
    gain  = str2double(get(camGainedit,'string'));
    % check if the input is whitin the limits
    sp=propinfo(getselectedsource(cam));
    if gain<=sp.Gain.ConstraintValue(1)
        gain = sp.Gain.ConstraintValue(1);
    elseif gain>sp.Gain.ConstraintValue(2)
        gain = sp.Gain.ConstraintValue(2);
    end
    set(camGainedit,'string',num2str(gain));
    waitnum = 0;
    while strcmp(cam.Running,'on')
        wait(.1)
        waitnum = waitnum+.1;
        if waitnum >10
            error('camera is running.')
        end
    end
    src_cam.Gain = gain; % set gain
    % save new camera settings
    save('Grasshopper.Cam_Settings.mat','ROI_Matrix','frame_rate_perc','gain','shutter','vidmode','logformat','logmode','lastexpname');
    GetFrameRate_call

end

%% gain call back
function [] = Shutter_call(~,~)
    % Callback for Shutter editbox.
    shutter  = str2double(get(camShutteredit,'string'));
    % check if the input is whitin the limits
    sp=propinfo(getselectedsource(cam));
    if shutter<=sp.Shutter.ConstraintValue(1)
        shutter = sp.Shutter.ConstraintValue(1);
    elseif shutter>sp.Shutter.ConstraintValue(2)
        shutter = sp.Shutter.ConstraintValue(2);
    end
    set(camShutteredit,'string',num2str(shutter));
    waitnum = 0;
    while strcmp(cam.Running,'on')
        wait(.1)
        waitnum = waitnum+.1;
        if waitnum >10
            error('camera is running.')
        end
    end
    src_cam.Shutter = shutter; % set shutter
    % save new camera settings
    save('Grasshopper.Cam_Settings.mat','ROI_Matrix','frame_rate_perc','gain','shutter','vidmode','logformat','logmode','lastexpname');
    GetFrameRate_call

end

function [] = QuitGrasshopperCallback(~,~)
   selection = questdlg('Are you sure you want to quit Grasshopper?','Confirm quit.','Yes','No','Yes'); 
   switch selection, 
      case 'Yes',
                delete(fcam);
                delete(cam)
                clear cam
                delete([savepath,'\','frmrate.mj2']);

          try
                delete(fcam);
                delete(cam)
                clear cam
                delete([savepath,'\','frmrate.mj2']);
          catch
          end
      case 'No'
      return 
   end
end

function [] = aviname_call(~,~)
    
    savestr = get(Aviname_edit,'String');
    if exist(strcat(savepath,'\',get(Aviname_edit,'String'),logext),'file')
        % file already exists, will overwrite
        set(Aviname_edit,'ForegroundColor','r')
        set(AcquireButton,'Enable','off') % set acquire to off
    else
        set(Aviname_edit,'ForegroundColor','k')
        set(AcquireButton,'Enable','on') % set acquire to on
        % new file
        metaGui(strcat(savepath,'\',get(Aviname_edit,'String'),'.mat'))
        lenstr = get(Aviname_edit,'String');
        lenstr = strsplit(lenstr,'_');
        lastexpname = strjoin(lenstr(4:end),'_');
        save('Grasshopper.Cam_Settings.mat','ROI_Matrix','frame_rate_perc','gain','shutter','vidmode','logformat','logmode','lastexpname');
    end
end

function [] = saveto_call(~,~)

    savestrt=uiputfile(strcat(savepath,'\',savestr));
    if isequal(savestrt,0)
    else
        [~,savestr,~] = fileparts(savestrt);
        set(Aviname_edit,'String',savestr);
    end
end

end





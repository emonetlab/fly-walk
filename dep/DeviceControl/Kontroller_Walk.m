% kontroller.m
% wrapper for MATLAB DAQ that makes it easy to acquire data and perform experiemnts
% kontroller is at http://github.com/sg-s/kontroller/
% 
% created by Srinivas Gorur-Shandilya. Contact me at http://srinivas.gs/contact/
% 
% This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License. 
% To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
%
% === 1. Basic Use ===
% 
% 1. run kontroller by typing "kontroller"
% 2. kontroller will automatically detect NI hardware and determine
% which channels you can use
% 3. Click on "configure inputs". To configure analogue inputs, call
% the channel you want to use something in the text field. Specify the input range as a number in
% the smaller edit field.
% (default is +/-10V)
% 4. Click on "configure outputs".If you want to use an output channel, call
% it something in the text field. Analogue on left, digital on right.
% 5. click on "configure controls". you should have vectors corresponding
% to the control singals you want to write in your workspace. choose which
% vector is written to which channel. Call the entire set (a ControlParadigm) with a certain
% name, and click "DONE". Close the window if you're done adding control
% paradigms. 
% 6. Set an appropriate sampling rate. default is 1kHz. 
% 7. Choose the file you want to output data to. Data will be stored as a
% .mat file
% 8. Choose the input channels you want to look at, and press "start
% scopes" to look at your input live. 
% 9. If you want to run a trial, choose a control paradigm from the paradigm list
% and press "run"
% 10. kontroller will save all data as .mat files in c:\data\
%
% === 2. Advanced Use: ControlParadigms ===
%
% 1. You can create your own ControlParadigms and save them to file, such
% that the name contains the string "*_kontroller_paradigm*". Make sure
% this file contains a structure called ControlParadigm, where each element
% of the structure has a MxN array called Outputs, where M is the number of
% channels you want to write to, and N is the number of samples. Each
% element of ControlParadigm should also have a field called "Name" that is
% the name of the ControlParadigm. 
% 
% === 3.  Expert Use: Scripting kontroller=
%
% kontroller can be called as a function from your own script. 
% 
% Example Usage:
% 
% data = kontroller('ControlParadigm',ControlParadigm,'RunTheseParadigms',[1 3],'w',1000);
%
% will run paradigms 1 and 3 in the ControlParadiagm Structure at 1000Hz
% and return the recorded data to a structure called data. 
%
% Note that you will have to use the GUI to configure inputs and outputs.
% Remember that the number of output channels must match the
% ControlParadigm! 
% 
% 
% ===Help, bug reports, contact and suggestions===
% 
% you should write to me at kontroller@srinivas.gs
%
% See also:
% http://github.com/sg-s/kontroller


function [data] = Kontroller_Walk(varargin)
VersionName = 'kontroller v_134_';
%% validate inputs
gui = 0;
demo_mode = 0;
RunTheseParadigms = [];
ControlParadigm = []; % stores the actual control signals for the different control paradigm
w = 1000; % 1kHz sampling
roimat = [0 0 2048 2048];   % full resolution
frp = 30;   % frame rate percentage
gain_v = 9; % gain for acamera
shutter_v  = 5; % shutter value
if nargin == 0 
    % fine.
    gui = 1; % default to showing the GUI
elseif iseven(nargin)
    for ii = 1:nargin
        temp = varargin{ii};
        if ischar(temp)
            eval(strcat(temp,'=varargin{ii+1};'));
        end
    end
    clear ii
else
    error('Inputs need to be name value pairs')
end



if ~gui
    if isempty(RunTheseParadigms) || isempty(ControlParadigm)
        error('kontroller does not know what control paradigms to run.')
    end
end


%% check for MATLAB dependencies
v = ver;
v = struct2cell(v);
j = find(strcmp('Data Acquisition Toolbox', v), 1);
if ~isempty(j)
else
    % No DAQ toolbox
    warning('kontroller needs the <a href="http://www.mathworks.com/products/daq/">DAQ toolbox</a> to run, which was not detected. kontroller will now run in demo mode')
    demo_mode = 1;
end
clear j


% check for internal dependencies
dependencies = {'oval','strkat','prettyFig','checkForNewestVersionOnGitHub'};
for ii = 1:length(dependencies)
    if exist(dependencies{ii}) ~= 2
        error('kontroller is missing an external function that it needs to run. You can download it <a href="https://github.com/sg-s/srinivas.gs_mtools">here.</a>')
    end
end
clear ii

% check for new version of kontroller
if gui
    wh = SplashScreen( 'kontroller', 'title.png','ProgressBar', 'on','ProgressPosition', 5, 'ProgressRatio', 0.1 );
    wh.addText( 30, 50, 'kontroller is starting...', 'FontSize', 20, 'Color', 'k' );
%     if online
%         wh.ProgressRatio  =0.2;
%         if checkForNewestVersionOnGitHub('kontroller',mfilename,VersionName);
%             disp('You can update kontroller using "install -f kontroller"')
%         end
%     else
%         disp('Could not check for updates.')
%     end
%     
    % see if wecam support exists
    if verLessThan('matlab','8.3')
        warning('No support for webcam image acquisition on this version of MATLAB.')
    end
end



% check if data directory exists
if exist('c:\data\','dir') == 7
else
    if gui && ~demo_mode
        disp('kontroller will default to storing recorded data in c:\data. This directory will now be created...')
        mkdir('c:\data\')
    end
    
end

%% persistent internal variables
 
% session handles
s=[]; % this is the session ID
cam = []; % this is the object of the webcam

% listeners
lh = []; % generic listener ID
lhMC = []; % listener for manual control

%  figure handles
handles.main_figure = []; handles.configure_input_channels_figure=[]; handles.configure_output_channels_figure = []; handles.configure_digital_output_channels_figure = [];
handles.configure_control_signals_figure=[];
handles.metadata_editor_figure = []; % figure for metadata editor
handles.view_paradigm_figure = [];
handles.manual_control_figure  = []; % figure handles for manual control UI
fMCD = [];

% uicontrol handles
li = []; ri = []; lir = []; rir= [ ]; % analogue input handles
lo = []; ro = [];  % analogue outputs handles
dlo = []; dro = []; % digital outputs handles
MetadataTextControl= []; % handle for metadata control
MetadataTextDisplay = []; % handle for metadata display
handles.scope_handles = [];
handles.plot_handles = []; % plotHandles is used by EpochPlot to plot; useful because we reset data instead of actually replotting
ControlHandles= [];
ParadigmNameUI = [];
MCoi = []; 
MCNumoi = []; % this is for manually entering a specific set point via a edit field
plot_only_control = [];
MCDhandle = [];

% used by kontroller in demo mode
ParadigmHandles= [];
TrialHandles = [];
ThisParadigm = [];
SamplingRate = [];
ROI_Matrix = [];    % Region of interest matrix for the camera
frame_rate_perc = [];   % frame rate percentage for the camera
gain = [];  % gain for the camera
shutter = [];   % shutter  for the camera

% internal control variables
MCOutputData = [];
metadatatext = []; % stores metadata in a cell array so that we can display it.
ScopeThese = [];
scopes_running = 0; % are the scopes running right now?
trial_running = 0; % when nonzero, this is the number of scans left. when zero, this means it's done
sequence = []; % this stores the sequence of trials to be done in this programme
sequence_step = []; % stores where in the sequence the programme is
programme_running = [];
pause_programme = 0;

% internal data variables
UseThisDevice = 1; % this decides which NI device to use, if more than one is plugged in
DeviceName = 'Dev1';
thisdata = []; % stores data from current trial; needs to be combined with data
data = [];
scope_plot_data = [];
time =[];
VarNames = [];
SaveToFile= [];
Trials = []; % this keeps track of how many trials have been done with each paradigm
metadata = [];  % stores metadata associated with the whole file. 
timestamps = []; % first column stores the paradigm #, the second the trial #, and the third the timestamp
Epochs = [];
CustomSequence = [];
webcam_buffer = []; % this is a structure used to properly pack images into data

%% initlaise some metadata
if gui
    wh.ProgressRatio  =0.3;
    % waitbar(0.3,wh,'Talking to NI DAQ. This may take time...'); figure(wh)
end
metadata.DateTime = datestr(now);
if ~demo_mode
    d = daq.getDevices;
else
    d.ID = 'Demo DAQ';
    d.Model = 'kontroller Demo';
end
if length(d) > 1
    UseThisDevice = SelectNIDevice(d);
elseif length(d) == 0
    error('You do not have any NI DAQ devices connected.')
end
DeviceName = d(UseThisDevice).ID;
metadata.daqName = d(UseThisDevice).Model;
metadata.kontrollerVersion = VersionName;
if ispc
    metadata.ComputerName = getenv('COMPUTERNAME');
else
    [~,metadata.ComputerName] = system('hostname');
end
metadata.SessionName = randomString(10);
fn = fieldnames(metadata);
for i = 1:length(fn)
    metadatatext{i} = strcat(fn{i},' : ',mat2str(getfield(metadata,fn{i}))); %#ok<AGROW>
end
clear i
set(MetadataTextDisplay,'String',metadatatext);
set(MetadataTextControl,'String','');

% check to see if sampling rate is stored. 
if exist('kontroller.SamplingRate.mat','file') == 2
    load('kontroller.SamplingRate.mat');
else
    % default
    w = 1000;
end


%% make the GUI
if gui
    
    %% initialize the camera window
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%    START OF CAMERA Window   %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check if the camera is connected

imaqreset;
imaf = imaqhwinfo;
if isempty(ismember(imaf.InstalledAdaptors,{'pointgrey'})) % adaptor is not installed. Stop
    error('Adaptor is not installed. Install pointgrey adaptor first.');
elseif ismember(imaf.InstalledAdaptors,{'pointgrey'}) % adaptor is installed. Now check if camera is connected
    iadinf = imaqhwinfo('pointgrey');
    if isempty(iadinf.DeviceIDs)
        camstate = 'off';
        % camera is not connected
        disp('No camera found. Check camera connection.')

    else
        camstate = 'on';
        scsz = get(0,'ScreenSize');
        yw = 5*scsz(4)/7;
        xw = 3*scsz(3)/5;
        if xw<1070
            xw = 1070;
        end
        fcam = figure('Position',[scsz(3)/7 scsz(4)/7 xw 5*scsz(4)/7],'NumberTitle','off','Visible','on','Name', 'Grasshopper','Menubar', 'none',...
            'Toolbar','figure','resize', 'on' ,'CloseRequestFcn',@QuitkontrollerCallback); 

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
    %       savestr=uiputfile(strcat('E:\Data\',datestr(now,'yyyy_mm_dd'),'\',datestr(now,'yyyy_mm_dd'),'_vid.mat'));
        
        elseif exist('E:','dir')==7
            if exist(strcat('E:\Data\',datestr(now,'yyyy_mm_dd')),'dir')==0
                mkdir(strcat('E:\Data\',datestr(now,'yyyy_mm_dd')));
            end
            savepath = ['E:\Data\',datestr(now,'yyyy_mm_dd')];
            savestr=strcat(datestr(now,'yyyy_mm_dd'),'_',lastexpname);
    %       savestr=uiputfile(strcat('E:\Data\',datestr(now,'yyyy_mm_dd'),'\',datestr(now,'yyyy_mm_dd'),'_vid.mat'));
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
        src_cam.Shutter = shutter;
        src_cam.ExposureMode = 'Off';
        cam.FramesPerTrigger = Inf; % Capture frames until we manually stop it
%         src_cam.FrameRatePercentage = frame_rate_perc;
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%    END OF CAMERA WINDOW   %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    handles.main_figure = figure('Position',[20 60 450 700],'Toolbar','none','Menubar','none','Name',strrep(VersionName,'_',''),'NumberTitle','off','Resize','off','HandleVisibility','on','CloseRequestFcn',@QuitkontrollerCallback);
    WebcamMenu = uimenu(handles.main_figure,'Label','Webcam','Enable','off');
    PreviewWebcamItem = uimenu(WebcamMenu,'Label','Preview','Callback',@PreviewWebcam);
    wh.ProgressRatio  =0.4;
    AnnotateWebcamItem = uimenu(WebcamMenu,'Label','Annotate...','Callback',@LaunchImageAnnotator);
    % waitbar(0.4,wh,'Generating UI...'); figure(wh)
    Konsole = uicontrol('Position',[15 600 425 90],'Style','text','String','kontroller is starting...','FontName','Courier','HorizontalAlignment','left');
    ConfigureInputChannelButton = uicontrol('Position',[15 540 140 50],'Style','pushbutton','Enable','off','String','Configure Inputs','FontSize',10,'Callback',@ConfigureInputChannels);
    ConfigureOutputChannelButton = uicontrol('Position',[160 540 140 50],'Style','pushbutton','Enable','off','String','Configure Outputs','FontSize',10,'Callback',@ConfigureOutputChannels);
    ConfigureControlSignalsButton = uicontrol('Position',[305 540 140 50],'Style','pushbutton','Enable','off','String','Configure Control','FontSize',10,'Callback',@ConfigureControlSignals);
    InputChannelsPanel = uipanel('Title','Input Channels','FontSize',12,'units','pixels','pos',[15 330 240 200]);
    PlotInputsList = {};
    PlotOutputsList = {};
    PlotInputs = uicontrol(InputChannelsPanel,'Position',[3 3 230 170],'Style','listbox','Min',0,'Max',2,'String',PlotInputsList,'FontSize',11);
    OutputChannelsPanel = uipanel('Title','Output Channels','FontSize',12,'units','pixels','pos',[265 330 170 130]);
    PlotOutputs = uicontrol(OutputChannelsPanel,'Position',[3 3 165 100],'Style','listbox','Min',0,'Max',2,'String',PlotOutputsList,'FontSize',11);

    % paradigm panel
    ControlParadigmList = {}; % stores a list of different control paradigm names. e.g., control, test, odour1, etc.
    ParadigmPanel = uipanel('Title','Control Paradigms','FontSize',12,'units','pixels','pos',[15 30 170 200]);
    ParadigmListDisplay = uicontrol(ParadigmPanel,'Position',[3 3 155 105],'Style','listbox','Enable','on','String',ControlParadigmList,'FontSize',12,'Min',0,'Max',2,'Callback',@ControlParadigmListCallback);
    SaveControlParadigmsButton = uicontrol(ParadigmPanel,'Position',[3,120,45,30],'Style','pushbutton','String','Save','Callback',@SaveControlParadigms);
    ViewControlParadigmButton = uicontrol(ParadigmPanel,'Position',[52,120,45,30],'Style','pushbutton','String','View','Callback',@ViewControlParadigm);
    RemoveControlParadigmsButton = uicontrol(ParadigmPanel,'Position',[100,120,60,30],'Style','pushbutton','String','Remove','Callback',@RemoveControlParadigms);
    ParadigmNameDisplay = uicontrol(ParadigmPanel,'Position',[3,150,150,25],'Style','text','String','No Controls configured');


    SamplingRateControl = uicontrol(handles.main_figure,'Position',[133 5 50 20],'Style','edit','String',mat2str(w),'Callback',@SamplingRateCallback);
    uicontrol(handles.main_figure,'Position',[20 5 100 20],'Style','text','String','Sampling Rate');
    RunTrialButton = uicontrol(handles.main_figure,'Position',[320 5 110 50],'Enable','off','BackgroundColor',[0.8 0.9 0.8],'Style','pushbutton','String','RUN w/o saving','FontWeight','bold','Callback',@RunTrial);

    FileNameDisplay = uicontrol(handles.main_figure,'Position',[200,60,230,50],'Style','edit','String','No destination file selected','Callback',@SaveToFileTextEdit);
    if ~demo_mode
        FileNameSelect = uicontrol(handles.main_figure,'Position',[200,5,100,50],'Style','pushbutton','String','Write to...','Callback',@SelectDestinationCallback);
    else
        FileNameSelect = uicontrol(handles.main_figure,'Position',[200,5,100,50],'Style','pushbutton','String','Load data...','Callback',@LoadkontrollerData);
    end

    AutomatePanel = uipanel('Title','Automate','FontSize',12,'units','pixels','pos',[205 120 230 200]);
    uicontrol(AutomatePanel,'Style','text','FontSize',8,'String','Repeat selected paradigms','Position',[1 120 100 50])
    uicontrol(AutomatePanel,'Style','text','FontSize',8,'String','times','Position',[150 110 50 50])
    RepeatNTimesControl = uicontrol(AutomatePanel,'Style','edit','FontSize',8,'String','1','Position',[110 140 30 30]);
    RunProgramButton = uicontrol(AutomatePanel,'Position',[4 5 110 30],'Enable','off','Style','pushbutton','String','RUN PROGRAM','Callback',@RunProgram);
    PauseProgramButton = uicontrol(AutomatePanel,'Position',[124 5 80 30],'Enable','off','Style','togglebutton','String','PAUSE','Callback',@PauseProgram);
    AbortProgramButton = uicontrol(AutomatePanel,'Position',[124 40 80 30],'Enable','off','Style','pushbutton','String','ABORT','Callback',@AbortTrial);

    uicontrol(AutomatePanel,'Style','text','FontSize',8,'String','Do this between trials:','Position',[1 70 100 50])
    InterTrialIntervalControl = uicontrol(AutomatePanel,'Style','edit','FontSize',8,'String','pause(20)','Position',[110 100 100 30]);
    RandomizeControl = uicontrol(AutomatePanel,'Style','popupmenu','String',{'Randomise','Interleave','Block','Reverse Block','Custom'},'Value',2,'FontSize',8,'Position',[5 50 100 20],'Callback',@RandomiseControlCallback);


    ManualControlButton = uicontrol(handles.main_figure,'Position',[12 240 170 30],'Enable','on','Style','pushbutton','String','Manual Control','Callback',@ManualControlCallback);
    MetadataButton = uicontrol(handles.main_figure,'Position',[12 280 170 30],'Enable','on','Style','pushbutton','String','Add Metadata...','Callback',@MetadataCallback,'BackgroundColor',[1 .5 .5]);

    wh.ProgressRatio  =0.5;
    % waitbar(0.5,wh,'Generating global variables...'); figure(wh)
    if demo_mode
        StartScopes = uicontrol(handles.main_figure,'Position',[260 465 150 50],'Style','pushbutton','Enable','off','String','Clear Scopes','FontSize',12,'Callback',@ClearScopes);
    else
        StartScopes = uicontrol(handles.main_figure,'Position',[260 465 150 50],'Style','pushbutton','Enable','off','String','Start Scopes','FontSize',12,'Callback',@ScopeCallback);
    end
    
    scsz = get(0,'ScreenSize');
%     handles.scope_fig = figure('Position',[500 100 scsz(3)-500 scsz(4)-200],'Toolbar','none','Name','Oscilloscope','NumberTitle','off','Resize','on','Visible','off','CloseRequestFcn',@QuitkontrollerCallback); hold on; 
    handles.scope_fig = figure('Position',[6*scsz(3)/7 scsz(4)/7 scsz(3)/8 scsz(4)/8],'Toolbar','none','Name','Oscilloscope','NumberTitle','off','Resize','on','Visible','off','CloseRequestFcn',@QuitKontrollerCallback); hold on; 

    
    
    % scope figure controls
    ParadigmMenu = uimenu(handles.scope_fig,'Label','Paradigm','Enable','off');
    TrialMenu = uimenu(handles.scope_fig,'Label','Trial #','Enable','off');
    uicontrol(handles.scope_fig,'Style','text','FontSize',8,'String','Plot only last','Position',[100 scsz(4)-220 100 20])
    plot_only_control=uicontrol(handles.scope_fig,'Style','edit','FontSize',8,'String','Inf','Position',[200 scsz(4)-220 70 22]);
    uicontrol(handles.scope_fig,'Style','text','FontSize',8,'String','samples','Position',[270 scsz(4)-220 100 20])
    
end

%% figure out DAQ characteristics and initialise

if ~gui
    disp('Scanning hardware...')
end
if ~demo_mode 
    d = daq.getDevices(); % this line takes a long time when you run it for the first time...
end

if ~demo_mode
    try
        OutputChannels =  d(UseThisDevice).Subsystems(2).ChannelNames;
    catch
        error('Something went wrong when trying to talk to the NI device. This is probably because it is not plugged in properly. Try restarting the DAQ, and restart kontroller.')
    end
else
    OutputChannels = {'ao0','ao1','ao2','ao3'};
    d.Subsystems(1).ChannelNames = {'ai0','ai1','ai2','ai3','ai4','ai5','ai6','ai7','ai8','ai9','ai10','ai11'};
    d.Subsystems(2).ChannelNames = {'di0','di1'};
    d.Subsystems(3).ChannelNames = {'do0','do1','do2','do3','do4','do5','do6','do7'};
    d.Vendor.FullName = 'kontroller Demo';
end
nOutputChannels = length(OutputChannels);
InputChannels =  d(UseThisDevice).Subsystems(1).ChannelNames;
nInputChannels = length(InputChannels);
InputChannelRanges = 10*ones(1,nInputChannels);
DigitalOutputChannels=d(UseThisDevice).Subsystems(3).ChannelNames;
nDigitalOutputChannels = length(DigitalOutputChannels);
UsedInputChannels = [];
InputChannelNames = {}; % this is the user defined names
UsedDigitalOutputChannels = [];
DigitalOutputChannelNames = {}; % this is the user defined names
UsedOutputChannels = [];
OutputChannelNames = {}; % this is the user defined names
FilterState = zeros(100,1);

if gui
    wh.ProgressRatio  =0.7;
    % waitbar(0.7,wh,'Checking for input config...'); figure(wh)
end
% load saved configs...inputs
if ~isempty(dir('kontroller.Config.Input.mat'))
    
    load('kontroller.Config.Input.mat','UsedInputChannels','InputChannelNames','InputChannelRanges')
    if gui
        disp('Loading saved input config files...')
        PlotInputsList = InputChannelNames(UsedInputChannels);
         set(PlotInputs,'String',PlotInputsList)
         if ~isempty(UsedInputChannels)
             set(StartScopes,'Enable','on')
         else 
             set(StartScopes,'Enable','off')
         end
         disp('DONE')
    end
    
end

% load sampling rate
if ~isempty(dir('kontroller.Config.SamplingRate.mat'))
    
    load('kontroller.Config.SamplingRate.mat','w')
    if gui
        disp('Loading saved sampling rate...')

         set(SamplingRateControl,'String',mat2str(w))
    end
    
end

if gui
    wh.ProgressRatio  =0.8;
    % waitbar(0.8,wh,'Checking for output config...'); figure(wh)
end
% load saved configs..outputs
if gui
    set(ConfigureControlSignalsButton,'Enable','off')
end
if ~isempty(dir('kontroller.Config.Output.mat'))
    
    load('kontroller.Config.Output.mat','UsedOutputChannels','OutputChannelNames')
    if gui
        disp('Loading saved output config files...')
         if ~isempty(UsedOutputChannels)
             set(ConfigureControlSignalsButton,'Enable','on')
         end
         % update PlotOutputsList
         PlotOutputsList = [OutputChannelNames(UsedOutputChannels) DigitalOutputChannelNames(UsedDigitalOutputChannels)];
         set(PlotOutputs,'String',PlotOutputsList);
        disp('DONE')
    end
     
end
% load saved digital output configs
if ~isempty(dir('kontroller.Config.Output.Digital.mat'))
    
    load('kontroller.Config.Output.Digital.mat','UsedDigitalOutputChannels','DigitalOutputChannelNames')
    if gui
        disp('Loading saved output config files...')
         if ~isempty(UsedDigitalOutputChannels)
             set(ConfigureControlSignalsButton,'Enable','on')        
         end
         % update PlotOutputsList
         PlotOutputsList = [OutputChannelNames(UsedOutputChannels) DigitalOutputChannelNames(UsedDigitalOutputChannels)];
         set(PlotOutputs,'String',PlotOutputsList);
        disp('DONE')
    end
    
end
if gui
    wh.ProgressRatio  =0.9;
    % waitbar(0.9,wh,'Looking for webcams...'); figure(wh)

    set(ConfigureInputChannelButton,'Enable','on')
    set(ConfigureOutputChannelButton,'Enable','on')
    if verLessThan('matlab','8.3')
        set(Konsole,'String',strkat('kontroller is ready to use. \n','DAQ detected: \n',d(UseThisDevice).Vendor.FullName,'-',d(UseThisDevice).Model))
    else
        if exist('webcamlist')
            try 
                webcamlist 
                if isempty(webcamlist)
                    disp('No webcams detected.')
                    set(Konsole,'String',strkat('kontroller is ready to use. \n','DAQ detected: \n',d(UseThisDevice).Vendor.FullName,'-',d(UseThisDevice).Model))
                
                else
                    cam=webcam(1);
                    set(Konsole,'String',strkat('kontroller is ready to use. \n','DAQ detected: \n',d(UseThisDevice).Vendor.FullName,'-',d(UseThisDevice).Model,'\nWebcam detected: ',cam.Name))
                    set(WebcamMenu,'Enable','on')
                end
            catch
                disp('No webcams detected.')
                set(Konsole,'String',strkat('kontroller is ready to use. \n','DAQ detected: \n',d(UseThisDevice).Vendor.FullName,'-',d(UseThisDevice).Model))
            end
            
        else
            disp('No webcams detected.')
            set(Konsole,'String',strkat('kontroller is ready to use. \n','DAQ detected: \n',d(UseThisDevice).Vendor.FullName,'-',d(UseThisDevice).Model))
        end
        
    end
    
    delete(wh);
    %close(wh)
    set(handles.scope_fig,'Visible','on')
    
%    waitbar(0.9,wh,'Looking for cams...'); figure(wh)

    set(ConfigureInputChannelButton,'Enable','on')
    set(ConfigureOutputChannelButton,'Enable','on')
    if verLessThan('matlab','8.3')
        set(Konsole,'String',strkat('Kontroller is ready to use. \n','DAQ detected: \n',d(UseThisDevice).Vendor.FullName,'-',d(UseThisDevice).Model))
    else
        
        if exist('imaqhwinfo','file')
            try 
%                 imaqreset;
                iadinf = imaqhwinfo('pointgrey');
                if isempty(iadinf.DeviceIDs)
                    disp('No cams detected.')
                    set(Konsole,'String',strkat('Kontroller is ready to use. \n','DAQ detected: \n',d(UseThisDevice).Vendor.FullName,'-',d(UseThisDevice).Model))
                
                else
%                     cam=videoinput('pointgrey', 1, 'F7_Mono16_2048x2048_Mode0');
                    set(Konsole,'String',strkat('Kontroller is ready to use. \n','DAQ detected: \n',d(UseThisDevice).Vendor.FullName,'-',d(UseThisDevice).Model,'\nCam detected: ',iadinf.DeviceInfo.DeviceName))
%                     set(WebcamMenu,'Enable','off')
                end
            catch
                disp('No cams detected.')
                set(Konsole,'String',strkat('Kontroller is ready to use. \n','DAQ detected: \n',d(UseThisDevice).Vendor.FullName,'-',d(UseThisDevice).Model))
            end
            
        else
            disp('No cams detected.')
            set(Konsole,'String',strkat('Kontroller is ready to use. \n','DAQ detected: \n',d(UseThisDevice).Vendor.FullName,'-',d(UseThisDevice).Model))
        end
        
    end
    
%     close(wh)
    set(handles.scope_fig,'Visible','on')
    
    
end

%% the following section applies only when kontroller is run in non-interactive mode.
if ~gui
    disp('kontroller is starting from the command line...')
    for gi = 1:length(RunTheseParadigms)
        % prep the data acqusition session
        clear s
        s = daq.createSession('ni');
        % figure out T
        T = length(ControlParadigm(RunTheseParadigms(gi)).Outputs)/w;
        s.DurationInSeconds = T;
        s.Rate = w; % sampling rate, user defined.
        % add the analogue input channels
        TheseChannels=InputChannels(UsedInputChannels);
        for ii = 1:length(TheseChannels)
            s.addAnalogInputChannel(DeviceName,InputChannels{UsedInputChannels(ii)}, 'Voltage');
        end
        % add the analogue output channels
        TheseChannels=OutputChannels(UsedOutputChannels);
        for ii = 1:length(TheseChannels)
             s.addAnalogOutputChannel(DeviceName,OutputChannels{UsedOutputChannels(ii)}, 'Voltage');
        end
        % add the digital output channels
        TheseChannels=DigitalOutputChannels(UsedDigitalOutputChannels);
        for ii = 1:length(TheseChannels)
             s.addDigitalChannel(DeviceName,DigitalOutputChannels{UsedDigitalOutputChannels(ii)}, 'OutputOnly');
        end
        
        % queue data        
        s.queueOutputData(ControlParadigm(RunTheseParadigms(gi)).Outputs');
        
        % configure listener to plot data on the scopes 
        lh = s.addlistener('DataAvailable',@PlotCallback);
        scope_plot_data = NaN(length(UsedInputChannels),T*w);
        
        % run trial
        disp('Running trial...')
        
        
        s.startForeground();
        disp('DONE')
        
        ThisParadigm = RunTheseParadigms(gi);
        ProcessTrialData;
        
    end
end


%% abort trial
    function [] = AbortTrial(~,~)
        s.stop;
    end

%% clear scopes
    function [] = ClearScopes(~,~)
        % find handles of all subplots in the scope figure
        temp=get(handles.scope_fig,'Children');
        temp2 = [];
        for i = 1:length(temp)
            if isempty(strfind(class(temp(i)),'Axes'))
                temp2 = [temp2 i];
            end
        end
        temp(temp2) = [];

        % delete them
        for i = 1:length(temp)
            delete(temp(i))
        end
    end


%% load saved data
    function [] = LoadkontrollerData(~,~)
        [FileName,PathName] = uigetfile('.mat');
        if ~FileName
            return
        end
        load_waitbar = waitbar(0.2, 'Loading data...');
        temp=load(strcat(PathName,FileName));
        ControlParadigm = temp.ControlParadigm;
        data = temp.data;
        SamplingRate = temp.SamplingRate;
        OutputChannelNames = temp.OutputChannelNames;
        try
            metadata = temp.metadata;
            timestamps = temp.timestamps;
        catch
        end
        clear temp

        waitbar(0.4, load_waitbar,'Setting i/o channels...');
        % update input and output channels
        set(PlotInputs,'String',fieldnames(data))
        PlotInputsList = fieldnames(data);

        set(PlotOutputs,'String',OutputChannelNames)
        PlotOutputsList = OutputChannelNames;

        % enable paradigm and trial menus
        set(ParadigmMenu,'Enable','on')
        set(TrialMenu,'Enable','on')

        CPNames = {ControlParadigm.Name};
        ParadigmHandles = zeros(1,length(CPNames));
        for i = 1:length(CPNames)
            ParadigmHandles(i) = uimenu(ParadigmMenu,'Label',CPNames{i},'Callback',@SetParadigm);
        end
        close(load_waitbar)


    end

%%  set paradigm
    function [] = SetParadigm(SelectedParadigm,~)
        % figure out how many images are in this paradigm
        ThisParadigm = find(ParadigmHandles == SelectedParadigm);
        
        % programmatically generate a menu with trials in this paradigm
        temp = kontroller_ntrials(data);
        nTrials = temp(ThisParadigm);

        TrialNames = {};
        for i = 1:nTrials
            TrialNames{i} = strkat('Trial ',mat2str(i));
        end
        
        % clear the trial menu
        if length(get(TrialMenu,'Children'))
            temp =  get(TrialMenu,'Children');
            for i = 1:length(temp)
                delete(temp(i));
            end
        end
        TrialHandles = zeros(1,length(TrialNames));
        for i = 1:length(TrialNames)
            TrialHandles(i) = uimenu(TrialMenu,'Label',TrialNames{i},'Callback',@ShowData);
        end
        
    end

    function [] = ShowData(SelectedTrial,~)
        ThisTrial = find(TrialHandles == SelectedTrial);

        nplots=length(get(PlotInputs,'Value')) + length(get(PlotOutputs,'Value'));
        plot_these = [get(PlotOutputs,'Value')  get(PlotInputs,'Value')];
        nrows = 2;
        ncols = ceil(nplots/nrows);
        c=1;
        sph = [];
        for i = 1:nrows
            for j = 1:ncols
                figure(handles.scope_fig)
                sph(c) = subplot(nrows,ncols,c); hold on
                if c > length(get(PlotOutputs,'Value'))
                    % plot inputs
                    temp = get(PlotInputs,'String');
                    temp = temp(plot_these(c));
                    title(temp)
                    temp = temp{1};
                    eval(strcat('temp=data(ThisParadigm).',temp,'(ThisTrial,:);'));
                    plot(temp)

                    

                else
                    % plot outputs
                    plot(ControlParadigm(ThisParadigm).Outputs(plot_these(c),:),'k');
                    title(OutputChannelNames(plot_these(c)))
                end
                c = c+1;
                if c > nplots
                    linkaxes(sph,'x');
                    prettyFig;
                    return
                end
            end
        end
    end



%% launch Image Annotator
    function [] = LaunchImageAnnotator(~,~)
        data=ImageAnnotator(strcat('C:\data\',SaveToFile));
    end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%    START OF CAMERA FUNCTIONS   %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%refresh call
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
            logconst ='diskLogger.Quality = 100;';
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
            logconst ='diskLogger.Quality = 100;';
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

function [] = meta_call(~,~)
    metaGui(strcat(savepath,'\',get(Aviname_edit,'String'),'.mat'))
end
        

function [] = refresh_call(~,~)
    stoppreview(cam);
    preview(cam, hImage);
    axis image
    GetFrameRate_call
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
        cam.FramesPerTrigger = round(frame_rate_perc*3);   % capture 100 frames
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
               frames = squeeze(videodata);
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
%                 save(strcat(savepath,'\',savestr,'_timestamps.mat'), 'timestampscam');
                SaveFastApp(strcat(savepath,'\',savestr,'_timestamps.mat'), 'timestampscam');
                disp(['Data saved to file: ', strcat(savepath,'\',savestr,logext)]);
                close(diskLogger)
            elseif strcmp(logmode,'memory')
%                 save(strcat(savepath,'\',savestr,logext), 'videodata', 'timestampscam');
                SaveFastApp(strcat(savepath,'\',savestr,'-frames',logext), 'frames', 'timestampscam');
                disp(['Data saved to file: ', strcat(savepath,'\',savestr,'-frames',logext)]);
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
               frames = squeeze(videodata);
            elseif strcmp(logmode,'disk&memory')
                [~,timestampscam,~] = getdata(cam);
            end
            
            % select place to save
            if strcmp(logmode,'disk&memory')
%                 save(strcat(savepath,'\',savestr,'_timestamps.mat'), 'timestampscam');
                SaveFastApp(strcat(savepath,'\',savestr,'_timestamps.mat'), 'timestampscam');
                disp(['Data saved to file: ', strcat(savepath,'\',savestr,logext)]);
%                 close(diskLogger)
            elseif strcmp(logmode,'memory')
%                 save(strcat(savepath,'\',savestr,logext), 'videodata', 'timestampscam');
                SaveFastApp(strcat(savepath,'\',savestr,'-frames',logext), 'frames', 'timestampscam');
                disp(['Data saved to file: ', strcat(savepath,'\',savestr,'-frames',logext)]);
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
%     if frame_rate_perc<=sp.FrameRatePercentage.ConstraintValue(1)
%         frame_rate_perc = sp.FrameRatePercentage.ConstraintValue(1);
%     elseif frame_rate_perc>sp.FrameRatePercentage.ConstraintValue(2)
%         frame_rate_perc = sp.FrameRatePercentage.ConstraintValue(2);
%     end
%     set(camFrameRateedit,'string',num2str(frame_rate_perc));
%     waitnum = 0;
%     while strcmp(cam.Running,'on')
%         wait(.1)
%         waitnum = waitnum+.1;
%         if waitnum >10
%             error('camera is running.')
%         end
%     end
%     src_cam.FrameRatePercentage = frame_rate_perc; % set frame rate percentage
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
    ssave('Grasshopper.Cam_Settings.mat','ROI_Matrix','frame_rate_perc','gain','shutter','vidmode','logformat','logmode','lastexpname');
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



function [] = aviname_call(~,~)
    
    savestr = get(Aviname_edit,'String');
    if exist(strcat(savepath,'\',get(Aviname_edit,'String'),logext),'file')
        % file already exists, will overwrite
        set(Aviname_edit,'ForegroundColor','r')
    else
        % new file
        set(Aviname_edit,'ForegroundColor','k')
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
        aviname_call;
    end
end





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%    END OF CAMERA FUNCTIONS   %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%





%% configure inputs
    function [] =ConfigureInputChannels(~,~)
        % load saved configs      
        n = nInputChannels;
        Height = 600;
        handles.configure_input_channels_figure = figure('Position',[80 80 450 Height+50],'Toolbar','none','Menubar','none','resize','off','Name','Configure Analogue Input Channels','NumberTitle','off');
        uicontrol(handles.configure_input_channels_figure,'Position',[25 600 400 40],'style','text','String','To reduce channel cross-talk, label shorted channels as "Ground". These will not be recorded from.','FontSize',8);
        a = axes; hold on
        set(a,'Visible','off');
        if floor(n/2)*2 == n
            % even n
            nspacing = Height/(n/2);
            % generate UIcontrol edit boxes
            for i = 1:n/2  % left side
                if ismember(i,UsedInputChannels)
                    li(i) = uicontrol(handles.configure_input_channels_figure,'Position',[40 10+Height-i*nspacing 100 20],'Style', 'edit','String',InputChannelNames{i},'FontSize',12,'Callback',@InputConfigCallback);
                    lir(i) = uicontrol(handles.configure_input_channels_figure,'Position',[7 10+Height-i*nspacing 25 20],'Style', 'edit','String',mat2str(InputChannelRanges(i)),'FontSize',10,'Callback',@InputConfigCallback);
                    % check if it is a ground channel
                      if strmatch(get(li(i),'String'),'Ground')
                          set(li(i),'ForegroundColor','g')
                      else
                          set(li(i),'ForegroundColor','k')
                      end
                else
                    li(i) = uicontrol(handles.configure_input_channels_figure,'Position',[40 10+Height-i*nspacing 100 20],'Style', 'edit','FontSize',12,'Callback',@InputConfigCallback);
                    lir(i) = uicontrol(handles.configure_input_channels_figure,'Position',[7 10+Height-i*nspacing 25 20],'Style', 'edit','String',mat2str(InputChannelRanges(i)),'FontSize',10,'Callback',@InputConfigCallback);
                end
                uicontrol(handles.configure_input_channels_figure,'Position',[160 10+Height-i*nspacing 50 20],'Style', 'text','String',InputChannels{i},'FontSize',12);
            end
            clear i
            for i = 1:n/2  % right side
                if ismember(n/2+i,UsedInputChannels)
                    ri(i) = uicontrol(handles.configure_input_channels_figure,'Position',[300 10+Height-i*nspacing 100 20],'Style', 'edit','String',InputChannelNames{n/2+i},'FontSize',12,'Callback',@InputConfigCallback);
                    rir(i) = uicontrol(handles.configure_input_channels_figure,'Position',[407 10+Height-i*nspacing 25 20],'Style', 'edit','String',mat2str(InputChannelRanges(n/2+i)),'FontSize',10,'Callback',@InputConfigCallback);
                    % check if it is a ground channel
                      if strmatch(get(ri(i),'String'),'Ground')
                          set(ri(i),'ForegroundColor','g')
                      else
                          set(ri(i),'ForegroundColor','k')
                      end
                else
                    ri(i) = uicontrol(handles.configure_input_channels_figure,'Position',[300 10+Height-i*nspacing 100 20],'Style', 'edit','FontSize',12,'Callback',@InputConfigCallback);
                    rir(i) = uicontrol(handles.configure_input_channels_figure,'Position',[407 10+Height-i*nspacing 25 20],'Style', 'edit','String',mat2str(InputChannelRanges(n/2+i)),'FontSize',10,'Callback',@InputConfigCallback);
                end
                uicontrol(handles.configure_input_channels_figure,'Position',[220 10+Height-i*nspacing 50 20],'Style', 'text','String',InputChannels{n/2+i},'FontSize',12);
            end
            clear i
            
        else
            error('kontroller error 676: Odd number of channels, cannot handle this')
        end
    
    end

%% preview webcam
    function [] = PreviewWebcam(~,~)
        % choose the maximum resolution
        ar=get(cam,'AvailableResolutions');
        set(cam,'Resolution',ar{end});
        preview(cam);
    end


%% take a picture with the webcam
    function [pic, webcam_metadata] = TakePicture(~,~)
        % choose the maximum resolution
        ar=get(cam,'AvailableResolutions');
        set(cam,'Resolution',ar{end});
        webcam_metadata=get(cam);
        pic = snapshot(cam);
        wf=figure; hold on;
        imagesc(pic); axis ij
        pause(2);
        close(wf);
        
    end

%% configure outputs
    function [] =ConfigureOutputChannels(~,~)
        % make the analogue outputs
        n = nOutputChannels;
        Height = 300;
        handles.configure_output_channels_figure = figure('Position',[50 150 450 Height],'Toolbar','none','Menubar','none','Name','Configure Analogue Output Channels','NumberTitle','off','CloseRequestFcn',@QuitConfigOutputsCallback);
        a = axes; hold on
        set(a,'Visible','off');
        if floor(n/2)*2 == n
            % even n
            nspacing = Height/(n/2+1);
            % generate UIcontrol edit boxes
            for i = 1:n/2  % left side
                if ismember(i,UsedOutputChannels)
                    lo(i) = uicontrol(handles.configure_output_channels_figure,'Position',[40 Height-i*nspacing 100 20],'Style', 'edit','String',OutputChannelNames{i},'FontSize',12,'Callback',@OutputConfigCallback);
                else
                    lo(i) = uicontrol(handles.configure_output_channels_figure,'Position',[40 Height-i*nspacing 100 20],'Style', 'edit','FontSize',12,'Callback',@OutputConfigCallback);
                end
                uicontrol(handles.configure_output_channels_figure,'Position',[160 Height-i*nspacing 50 20],'Style', 'text','String',OutputChannels{i},'FontSize',12);
            end
            clear i
            for i = 1:n/2  % right side
                if ismember(n/2+i,UsedOutputChannels)
                    
                    ro(i) = uicontrol(handles.configure_output_channels_figure,'Position',[300 Height-i*nspacing 100 20],'Style', 'edit','String',OutputChannelNames{n/2+i},'FontSize',12,'Callback',@OutputConfigCallback);
                else
                    ro(i) = uicontrol(handles.configure_output_channels_figure,'Position',[300 Height-i*nspacing 100 20],'Style', 'edit','FontSize',12,'Callback',@OutputConfigCallback);
                end
                uicontrol(handles.configure_output_channels_figure,'Position',[220 Height-i*nspacing 50 20],'Style', 'text','String',OutputChannels{n/2+i},'FontSize',12);
            end
            clear i
            
        else
            error('Odd number of channels, cannot handle this')
        end
        
        % make the digital outputs
        n = nDigitalOutputChannels;
        Height = 700;
        handles.configure_digital_output_channels_figure = figure('Position',[550 150 550 Height],'Resize','off','Toolbar','none','Menubar','none','Name','Configure Digital Output Channels','NumberTitle','off','CloseRequestFcn',@QuitConfigOutputsCallback);
        a = axes; hold on
        set(a,'Visible','off');
        if floor(n/2)*2 == n
            % even n
            nspacing = Height/(n/2+1);
            % generate UIcontrol edit boxes
            for i = 1:n/2  % left side
                if ismember(i,UsedDigitalOutputChannels)
                    dlo(i) = uicontrol(handles.configure_digital_output_channels_figure,'Position',[40 Height-i*nspacing 100 20],'Style', 'edit','String',DigitalOutputChannelNames{i},'FontSize',10,'Callback',@OutputConfigCallback);
                else
                    dlo(i) = uicontrol(handles.configure_digital_output_channels_figure,'Position',[40 Height-i*nspacing 100 20],'Style', 'edit','FontSize',10,'Callback',@OutputConfigCallback);
                end
                uicontrol(handles.configure_digital_output_channels_figure,'Position',[160 Height-i*nspacing 100 20],'Style', 'text','String',DigitalOutputChannels{i},'FontSize',10);
            end
            clear i
            for i = 1:n/2  % right side
                if ismember(n/2+i,UsedOutputChannels)
                    
                    dro(i) = uicontrol(handles.configure_digital_output_channels_figure,'Position',[390 Height-i*nspacing 100 20],'Style', 'edit','String',DigitalOutputChannelNames{n/2+i},'FontSize',10,'Callback',@OutputConfigCallback);
                else
                    dro(i) = uicontrol(handles.configure_digital_output_channels_figure,'Position',[390 Height-i*nspacing 100 20],'Style', 'edit','FontSize',10,'Callback',@OutputConfigCallback);
                end
                uicontrol(handles.configure_digital_output_channels_figure,'Position',[280 Height-i*nspacing 100 20],'Style', 'text','String',DigitalOutputChannels{n/2+i},'FontSize',10);
            end
            clear i
            
        else
            error('Odd number of channels, cannot handle this')
        end
    
    end

%% manual control callback
function [] =ManualControlCallback(~,~)
        % make UI for analogue outputss
        n = nOutputChannels;
        Height = 300;
        handles.manual_control_figure = figure('Position',[60 50 650 Height],'Toolbar','none','Menubar','none','Name','Manual Control','NumberTitle','off','CloseRequestFcn',@QuitManualControlCallback);
        a = axes; hold on
        set(a,'Visible','off');
        if floor(n/2)*2 == n
            % even n
            nspacing = Height/(n/2+1);
            % generate UIcontrol edit boxes
            oi=1; % this is the index of each used ouput channel
            for i = 1:n/2  % left side
                if ismember(i,UsedOutputChannels)
                    MCoi(oi) = uicontrol(handles.manual_control_figure,'Position',[90 Height-i*nspacing 100 20],'Style', 'slider','Min',0,'Max',5,'Value',0,'String',OutputChannelNames{i},'FontSize',16,'Callback',@ManualControlSliderCallback);
                    try    % R2013b and older
                       addlistener(MCoi(oi),'ActionEvent',@ManualControlSliderCallback);
                    catch  % R2014a and newer
                       addlistener(MCoi(oi),'ContinuousValueChange',@ManualControlSliderCallback);
                    end
                    uicontrol(handles.manual_control_figure,'Position',[220 Height-i*nspacing 50 20],'Style', 'text','String',OutputChannels{i},'FontSize',12);
                    MCNumoi(oi) = uicontrol(handles.manual_control_figure,'Position',[20 Height-i*nspacing 60 20],'Style', 'edit','String','0','FontSize',12,'Callback',@ManualControlSliderCallback);
                    oi = oi +1; 
                end
            end
            clear i
            for i = 1:n/2  % right side  
                if ismember(i+n/2,UsedOutputChannels)
                    MCoi(oi) = uicontrol(handles.manual_control_figure,'Position',[390 Height-i*nspacing 100 20],'Style', 'slider','Min',0,'Max',5,'Value',0,'String',OutputChannelNames{n/2+i},'FontSize',16,'Callback',@ManualControlSliderCallback);
                    try    % R2013b and older
                       addlistener(MCoi(oi),'ActionEvent',@ManualControlSliderCallback);
                    catch  % R2014a and newer
                       addlistener(MCoi(oi),'ContinuousValueChange',@ManualControlSliderCallback);
                    end
                    uicontrol(handles.manual_control_figure,'Position',[320 Height-i*nspacing 50 20],'Style', 'text','String',OutputChannels{(n/2+i)},'FontSize',12);
                    MCNumoi(oi) = uicontrol(handles.manual_control_figure,'Position',[520 Height-i*nspacing 60 20],'Style', 'edit','String','0','FontSize',12,'Callback',@ManualControlSliderCallback);
                    oi = oi +1;
                end
            end
            clear i
            
        else
            % odd number of channels
            error('Odd number of channels. Cant handle this')
        end
        
        
        % make UI for digital outputss
        
        n = length(UsedDigitalOutputChannels);

        base_height = 70;
        Height = n*(base_height+1);
        fMCD = figure('Position',[60 450 350 Height],'Toolbar','none','Menubar','none','Name','Manual Control: Digital Outputs','NumberTitle','off','CloseRequestFcn',@QuitManualControlCallback);
        a = axes; hold on
        set(a,'Visible','off');
            
        
        for k = 1:n
            MCDhandle(k)=uicontrol(fMCD,'Position',[20 Height-k*base_height+10 100 20],'String',DigitalOutputChannelNames(UsedDigitalOutputChannels(k)),'Style','togglebutton','Callback',@ManualControlSliderCallback);
        end
        clear k
        
        
       
        
        
        if isempty(PlotInputsList)
        else
            
            if scopes_running
                % stop scopes
                s.stop;
                delete(lh);
                % relabel scopes button
                set(StartScopes,'String','Start Scopes');
                scopes_running = 0;
            end
            
            % start scopes
            figure(handles.scope_fig)   
            % create session
            clear s
            s = daq.createSession('ni');
            s.IsContinuous = true;
            s.NotifyWhenDataAvailableExceeds = w/10; % 10Hz



            % update scope_plot_data
            scope_plot_data = NaN(length(get(PlotInputs,'Value')),5*w); % 5 s of  data in each channel
            time = (1/w):(1/w):5;
            handles.scope_handles = []; % axis handles for each sub plot in scope
            rows = ceil(length(get(PlotInputs,'Value'))/2);
            ScopeThese = get(PlotInputs,'Value');
            handles.plot_handles = [];
            for k = 1:length(get(PlotInputs,'Value'))
                handles.scope_handles(k) = subplot(2,rows,k);
                
                handles.plot_handles(k) = plot(handles.scope_handles(k),NaN,NaN);
                set(handles.scope_handles(k),'ButtonDownFcn',@ToggleFilterState);
                %set(handles.scope_handles(k),'XLim',[0 5*w],'YLim',[0 5])
                ylabel( strcat(InputChannels{UsedInputChannels(ScopeThese(k))},' -- ',InputChannelNames{UsedInputChannels(ScopeThese(k))}))
                s.addAnalogInputChannel(DeviceName,InputChannels{UsedInputChannels(ScopeThese(k))}, 'Voltage'); % add channel
            end
            clear k

            % MCOutputData = zeros(length(time),length(UsedOutputChannels)+length(UsedDigitalOutputChannels)); 
            MCOutputData = zeros(w/10,length(UsedOutputChannels)+length(UsedDigitalOutputChannels)); 

            % add analogue channels
            TheseChannels=OutputChannels(UsedOutputChannels);
            for k = 1:length(TheseChannels)
                s.addAnalogOutputChannel(DeviceName,OutputChannels{UsedOutputChannels(k)}, 'Voltage');
            end
            clear k

            % add digital channels
            TheseChannels=DigitalOutputChannels(UsedDigitalOutputChannels);
            for k = 1:length(TheseChannels)
                 s.addDigitalChannel(DeviceName,DigitalOutputChannels{UsedDigitalOutputChannels(k)}, 'OutputOnly');
            end
            clear k

            % queue data
            s.NotifyWhenScansQueuedBelow = w/10;
            s.queueOutputData(MCOutputData);


            s.Rate = w; 
            lh = s.addlistener('DataAvailable',@ScopePlotCallback);
            lhMC = s.addlistener('DataRequired',@PollManualControl);



            % fix scope labels
            ScopeThese = 1:length(get(PlotInputs,'Value'));

            % relabel scopes button
            set(StartScopes,'String','Stop Scopes');

            
            s.startBackground();
            scopes_running = 1;

            
       
        end


        
        

        
    
end



%% Poll Manual Control
% this is an experimental function that will be called every time data is
% needed. it polls the UI for the manual control, constructs data on the
% fly, and passes it back. 
    function PollManualControl(src,~)
        % datestr(clock)
        % poll the digital outputs
        for k = 1:length(MCDhandle)
            a = MCDhandle(k);
            MCOutputData(:,length(UsedOutputChannels)+k) = get(a,'Value');
        end
        clear k
        
        % poll the analogue outputs
        for k = 1:length(MCoi)
            a = MCoi(k);
            MCOutputData(:,k) = get(a,'Value');
        end
        clear k
        
        
        % queue
        src.queueOutputData(MCOutputData);
        
    end

%% sychonirses manual control slider and text edit fields
    function ManualControlSliderCallback(src,~)
        
        if any(MCDhandle==src)
            % digital outputs being manipulated 
            k = find(MCDhandle == src);
            %MCOutputData(:,length(UsedOutputChannels)+k) = get(src,'Value');
            
        elseif any(MCNumoi == src)
            % text edit analogue outputs being manipulated
            k = find(MCNumoi == src);
            thisvalue = str2double(get(MCNumoi(k),'String'));
            %MCOutputData(:,k) = thisvalue;
                 
            % now move the slider to reflect the this
            set(MCoi(k),'Value',thisvalue);
        elseif any(MCoi == src)
            % sliders being manipulated 
            k = find(MCoi == src);
            thisvalue = get(MCoi(k),'Value');
            MCOutputData(:,k) = thisvalue;
              
            % now update the text edit value to reflect this
            set(MCNumoi(k),'String',oval(thisvalue,2))
        else
             error('What is being changed here? Something seriously wrong in Manual Control Callbacks.')
        end
        
        % fake a call to poll data
         PollManualControl(s);
        
    end

%% input config callback
    function [] = InputConfigCallback(~,~)
        UsedInputChannels = [];
        n = nInputChannels;
         % first scan left
         for i = 1:n/2
              if isempty(strmatch(get(li(i),'String'),InputChannels))
                  % use this channel
                  UsedInputChannels = [UsedInputChannels i];

                  InputChannelNames{i} = get(li(i),'String');
                  InputChannelRanges(i) = str2double(get(lir(i),'String'));
                  % check if it is a ground channel
                  if strcmp(get(li(i),'String'),'Ground')
                      set(li(i),'ForegroundColor','g')
                  else
                      set(li(i),'ForegroundColor','k')
                  end
              
              end
              
         end
         clear i
         % then scan right
         for i = 1:n/2
              if isempty(strmatch(get(ri(i),'String'),InputChannels))
                  % use this channel
                  UsedInputChannels = [UsedInputChannels n/2+i];
                  InputChannelNames{n/2+i} = get(ri(i),'String');
                  InputChannelRanges(n/2+i) = str2double(get(rir(i),'String'));
                  % check if it is a ground channel
                  if strcmp(get(ri(i),'String'),'Ground')
                      set(ri(i),'ForegroundColor','g')
                  else
                      set(ri(i),'ForegroundColor','k')
                  end
              end
         end
         clear i
         
         % update the input channel list
         PlotInputsList = InputChannelNames(UsedInputChannels);
         set(PlotInputs,'String',PlotInputsList)
         if ~isempty(UsedInputChannels)
             set(StartScopes,'Enable','on')
             
         else 
             set(StartScopes,'Enable','off')
         end
         % save Input Channel Names for persisitent config
         save('kontroller.Config.Input.mat','InputChannelNames','UsedInputChannels','InputChannelRanges');
        
    end

%% output config callback
function [] = OutputConfigCallback(~,~)
    % configure analogue outputs
        UsedOutputChannels = [];
        n = nOutputChannels;
         % first scan left
         for i = 1:n/2
              if isempty(strmatch(get(lo(i),'String'),OutputChannels))
                  % use this channel
                  UsedOutputChannels = [UsedOutputChannels i];
                  OutputChannelNames{i} = get(lo(i),'String');
              end
         end
         clear i
         % then scan right
         for i = 1:n/2
              if isempty(strmatch(get(ro(i),'String'),OutputChannels))
                  % use this channel
                  UsedOutputChannels = [UsedOutputChannels n/2+i];
                  OutputChannelNames{n/2+i} = get(ro(i),'String');
              end
         end
         clear i
         
         % update the output channel control signal config
         if ~isempty(UsedOutputChannels)
             set(ConfigureControlSignalsButton,'Enable','on')
             
         else 
             set(ConfigureControlSignalsButton,'Enable','off')
         end
         % now update digital outputs
         DigitalOutputChannelNames = {};
         UsedDigitalOutputChannels = [];
         n = nDigitalOutputChannels;
         % first scan left
         for i = 1:n/2
              if isempty(strmatch(get(dlo(i),'String'),DigitalOutputChannels))
                  % use this channel
                  UsedDigitalOutputChannels = [UsedDigitalOutputChannels i];
                  DigitalOutputChannelNames{i} = get(dlo(i),'String');
              end
         end
         clear i
         % then scan right
         for i = 1:n/2
              if isempty(strmatch(get(dro(i),'String'),DigitalOutputChannels))
                  % use this channel
                  UsedDigitalOutputChannels = [UsedDigitalOutputChannels n/2+i];
                  DigitalOutputChannelNames{n/2+i} = get(dro(i),'String');
              end
         end
         clear i
         
         % update the output channel control signal config
         if ~isempty(UsedOutputChannels) || ~isempty(UsedDigitalOutputChannels)
             set(ConfigureControlSignalsButton,'Enable','on')
             
         else 
             set(ConfigureControlSignalsButton,'Enable','off')
         end
         
         PlotOutputsList = [OutputChannelNames(UsedOutputChannels) DigitalOutputChannelNames(UsedDigitalOutputChannels)];
         set(PlotOutputs,'String',PlotOutputsList)
         % save Analogue Output Channel Names for persisitent config
         
         save('kontroller.Config.Output.mat','OutputChannelNames','UsedOutputChannels');
         
         % save Digital Output Channel Names for persisitent config
         save('kontroller.Config.Output.Digital.mat','DigitalOutputChannelNames','UsedDigitalOutputChannels');
        
end

%% Sampling Rate Callback
    function [] = SamplingRateCallback(~,~)
        w = str2double(get(SamplingRateControl,'String'));
        % write to file
        save('kontroller.SamplingRate.mat','w')
    end


%% oscilloscope callback
    function  [] = ScopeCallback(~,~)
        if isempty(PlotInputsList)
        else
            if scopes_running
                % stop scopes
                s.stop;
                delete(lh);
                % relabel scopes button
                set(StartScopes,'String','Start Scopes');
                scopes_running = 0;
            else
                % start scopes
                figure(handles.scope_fig)   
                % create session
                s = daq.createSession('ni');
                s.IsContinuous = true;
                s.NotifyWhenDataAvailableExceeds = w/10; % 10Hz
                % update scope_plot_data
                scope_plot_data = NaN(length(get(PlotInputs,'Value')),5*w); % 5 s of  data in each channel
                time = (1/w):(1/w):5;
                handles.scope_handles = []; % axis handles for each sub plot in scope
                rows = ceil(length(get(PlotInputs,'Value'))/2);
                ScopeThese = get(PlotInputs,'Value');

                for i = 1:length(get(PlotInputs,'Value'))
                    handles.scope_handles(i) = subplot(2,rows,i);
                    handles.plot_handles(i) = plot(handles.scope_handles(i),NaN,NaN);
                    set(handles.scope_handles(i),'ButtonDownFcn',@ToggleFilterState);
                               
                    ylabel( strcat(InputChannels{UsedInputChannels(ScopeThese(i))},' -- ',InputChannelNames{UsedInputChannels(ScopeThese(i))}))
                    s.addAnalogInputChannel(DeviceName,InputChannels{UsedInputChannels(ScopeThese(i))}, 'Voltage'); % add channel
                end
                clear i
                
                
                s.Rate = w; 
                lh = s.addlistener('DataAvailable',@ScopePlotCallback);
                
                % specify each channel's range
                for i = 1:length(s.Channels)
                    % figure out which channel it is
                    [a,~]=ind2sub(size(InputChannels), strmatch(s.Channels(i).ID, InputChannels, 'exact'));
                    s.Channels(i).Range = InputChannelRanges(a)*[-1 1];
                end
                clear i
                
                % fix scope labels
                ScopeThese = 1:length(get(PlotInputs,'Value'));
                
                % relabel scopes button
                set(StartScopes,'String','Stop Scopes');
                
                
                s.startBackground();
                scopes_running = 1;
   
            end
       
        end   
    end


%% toggle filter state
    function [] = ToggleFilterState(src,~)

        if FilterState(handles.scope_handles == src)
            FilterState(handles.scope_handles == src) = 0;
        else
            FilterState(handles.scope_handles == src) = 1;
        end
    end

%% Scope Plot Callback

    function [] = ScopePlotCallback(~,event)
        
        % figure out the size of the data increment      
        dsz = length(event.Data);
        
        % throw out the first bit of scope_plot_data
        scope_plot_data(:,1:dsz) = [];
        
        % append the new data to the end
        scope_plot_data = [scope_plot_data event.Data'];
        
        
        for si = ScopeThese
            if FilterState(si)
                % filter the data
                filtered_trace = bandPass(scope_plot_data(si,:),100,10);
                set(handles.plot_handles(si),'XData',time,'YData',filtered_trace,'Color',[1 0 0]);
            else
                set(handles.plot_handles(si),'XData',time,'YData',scope_plot_data(si,:),'Color',[0 0 1]);
            end
            
        end
    end

%% plot live data to scopes and grab data
    function [] = PlotCallback(~,event)
        sz = size(scope_plot_data);
        % capture all the data acquired...        
        a =  find(isnan(scope_plot_data(1,:)),1,'first');
        z =  a + length(event.Data);
        for si = 1:sz(1)
            scope_plot_data(si,a:z-1) = event.Data(:,si)';
        end
        
        % ...but plot only the ones requested
        if gui
            % if this is being called as part of an experiment, use
            % EpochPlot
            % control for very long stimuli, which causes plot functions to
            % crash
            plot_length = str2double(get(plot_only_control,'String'));

            EpochPlot(handles.scope_handles(ScopeThese),ScopeThese,time,scope_plot_data,FilterState,handles.plot_handles(ScopeThese),plot_length);

            trial_running = trial_running - 1;
        else
            if rand>0.9
                fprintf('.')
            end
        end
        
    end

%% configure control signals
    function [] = ConfigureControlSignals(~,~)
        no = length(UsedOutputChannels) + length(UsedDigitalOutputChannels);
        Height = 100+no*100;
        % figure out the variables in the workspace that you can use. 
        % we require them to be a 1D vector. that's it. 
        var=evalin('base','whos');
        badvar=  [];
        for i  =1:length(var)
            if  ~((length(var(i).size)==2) || (min(var(i).size) == 1))
                badvar = [badvar i];
            end
        end
        clear i
        var(badvar) = []; clear badvar
        
        % make the gui
        handles.configure_control_signals_figure = figure('Position',[200 200 450 Height],'Toolbar','none','Menubar','none','Name','Select Control Signals','NumberTitle','off','Resize','off');
        ControlHandles = [];
        if length(var) >= no
            % assemble names into a cell array
            VarNames = {};
            for i = 1:length(var)
                VarNames{i} = var(i).name;
            end
            
            
            % get name of control paradigm
            ParadigmNameUI=uicontrol(handles.configure_control_signals_figure,'Position',[(450-340)/2 Height-30 340 24],'Style', 'edit','String','Enter Name of Control Paradigm','FontSize',12);
            
            
            for i = 1:length(UsedOutputChannels)
                ControlHandles(i) = uicontrol(handles.configure_control_signals_figure,'Position',[150 10+i*100 150 50],'Style','popupmenu','Enable','on','String',VarNames,'FontSize',12);
                uicontrol(handles.configure_control_signals_figure,'Position',[30 30+i*100 100 30],'Style','text','String',OutputChannels{UsedOutputChannels(i)},'FontSize',12);
                uicontrol(handles.configure_control_signals_figure,'Position',[320 30+i*100 100 30],'Style','text','String',OutputChannelNames{UsedOutputChannels(i)},'FontSize',12);

            end
            clear i
            ti=1;
            for i = length(UsedOutputChannels)+1:no
                ControlHandles(i) = uicontrol(handles.configure_control_signals_figure,'Position',[150 10+i*100 150 50],'Style','popupmenu','Enable','on','String',VarNames,'FontSize',12);
                uicontrol(handles.configure_control_signals_figure,'Position',[30 30+i*100 100 30],'Style','text','String',DigitalOutputChannels{UsedDigitalOutputChannels(ti)},'FontSize',12);
                uicontrol(handles.configure_control_signals_figure,'Position',[320 30+i*100 100 30],'Style','text','String',DigitalOutputChannelNames{UsedDigitalOutputChannels(ti)},'FontSize',12);
                ti=ti+1;
            end
            
            clear ti
            % button to save paradigm
            uicontrol(handles.configure_control_signals_figure,'Position',[370 30 60 30],'Style','pushbutton','String','+Add','FontSize',12,'Callback',@ConfigureControlCallback);

        else
            % tell the user they don't enough variables to configure controls
            uicontrol(handles.configure_control_signals_figure,'Position',[25 70 400 200],'Style','text','String','To manually configure a control paradigm, you must have at least as many vectors in your MATLAB workspace as you have analogue outputs. This is not the case. Either close this and create some, or load a previously saved control paradigm from file. ','FontSize',12);
        
        end
        
        % button for loading saved control paradigms
        uicontrol(handles.configure_control_signals_figure,'Position',[10 30 260 30],'Style','pushbutton','String','Load saved paradigms...','FontSize',12,'Callback',@LoadSavedParadigms);
        
        
        
    end

%% configure control callback
    function [] = ConfigureControlCallback(~,~)
        no = length(UsedOutputChannels) + length(UsedDigitalOutputChannels);
        % assume everything is OK, and make a paradigm
        ControlParadigm(length(ControlParadigm)+1).Name= get(ParadigmNameUI,'String');
        thisp = length(ControlParadigm);
        % and now fill in the analogue control signals
        for i = 1:length(UsedOutputChannels);
            ControlParadigm(thisp).Outputs(i,:)=evalin('base',cell2mat(VarNames(get(ControlHandles(i),'Value'))));
        end
        % now fill in the digital control signals
        ti=1;
        for i = length(UsedOutputChannels)+1:no
            ControlParadigm(thisp).Outputs(i,:)=evalin('base',cell2mat(VarNames(get(ControlHandles(i),'Value'))));
            ti=ti+1;
        end
        clear i

        % update the paradigm list
        ControlParadigmList = [ControlParadigmList get(ParadigmNameUI,'String')];
        set(ParadigmListDisplay,'String',ControlParadigmList)
        
        % update Trial count
        Trials = zeros(1,length(ControlParadigmList));
        set(Konsole,'String','Controls have been configured. ')
        
        % enable the run button
        set(RunTrialButton,'enable','on','String','RUN w/o saving','BackgroundColor',[0.9 0.1 0.1]);
    end

%% select destintion callback
    function [] = SelectDestinationCallback(~,~)
        temp=strcat(datestr(now,'yyyy_mm_dd'),'_customname.mat');
        SaveToFile=uiputfile(strcat('C:\data\',temp));
        % activate the run buttons
        if length(get(ParadigmListDisplay,'Value')) == 1
            set(RunTrialButton,'enable','on','BackgroundColor',[0.1 0.9 0.1],'String','RUN and SAVE');
        end
        set(RunProgramButton,'enable','on');
        % update display
        set(FileNameDisplay,'String',SaveToFile);
        % reset Trial count
        Trials = zeros(1,length(ControlParadigmList)); 
        timestamps = [];
        data = []; % clears the data, so that new data is written to the new file
        sequence=  [];
        sequence_step = [];

        % reset metadata indicator
        set(MetadataButton,'BackgroundColor',[1 .5 .5]);

         
    end

%% save to file destination callback
    function [] = SaveToFileTextEdit(~,~)
        if isempty(get(FileNameDisplay,'String'))
            % no destination
            if length(get(ParadigmListDisplay,'Value')) == 1
                set(RunTrialButton,'enable','on','BackgroundColor',[0.9 0.1 0.1],'String','RUN w/o saving');
            end
        else
            if exist(strcat('c:\data\',get(FileNameDisplay,'String')),'file')
                % file already exists, will overwrite
                set(FileNameDisplay,'ForegroundColor','r')
            else
                % new file
                set(FileNameDisplay,'ForegroundColor','k')
            end
            if length(get(ParadigmListDisplay,'Value')) == 1
                set(RunTrialButton,'enable','on','BackgroundColor',[0.1 0.9 0.1],'String','RUN and SAVE');
            end
            % reset Trial count
            Trials = zeros(1,length(ControlParadigmList)); 
            % reset timestamps
            timestamps = [];
            data = []; % clears the data, so that new data is written to the new file
            sequence=  [];
            sequence_step = [];
            SaveToFile = get(FileNameDisplay,'String');

            % reset metadata indicator
            set(MetadataButton,'BackgroundColor',[1 .5 .5]);
        end
            
    end

%% RandimzeControl Callback -- for custom sequence
    function [] = RandomiseControlCallback(~,~)
        % get sequence
        if  get(RandomizeControl,'Value') == 5
            CustomSequence = inputdlg('Enter sequence of paradigms in program:','Choose custom sequence');
            set(Konsole,'string',strkat('This custom programme of the following pradigms configured: ',CustomSequence{1}))
        end
        
    end

%% run programmme
    function [] = RunProgram(~,~)
        % make sure pause programme button is enabled
        set(PauseProgramButton,'Enable','on');
        set(AbortProgramButton,'Enable','on');
        
        
        % check if pause is required
        if get(PauseProgramButton,'Value') 
            set(PauseProgramButton,'String','PAUSED')
        end
        while get(PauseProgramButton,'Value') == 1  
            pause(0.1)
        end

        if ~get(AbortProgramButton,'Value')    
        
            % figure out how many trials have been run so far
            if isempty(sequence)
                % start the timer
                tic
                % make the sequence
                np = get(ParadigmListDisplay,'Value');

                ntrials= str2num(get(RepeatNTimesControl,'String'));

                % figure out how to arrange paradigms
                switch get(RandomizeControl,'Value') 
                    case 1
                        % randomise
                        sequence = repmat(np,1,ntrials);
                        sequence = sequence(randperm(length(sequence),length(sequence)));
                    case 2
                        % interleave
                        sequence = repmat(np,1,ntrials);
                    case 3
                        % block
                        sequence =  reshape((np'*ones(1,ntrials))',1,ntrials*length(np));
                    case 4
                        % reverse block
                        sequence =  reshape((np'*ones(1,ntrials))',1,ntrials*length(np));
                        sequence = fliplr(sequence);
                    case 5
                        % arbitrary
                        if ~isempty(CustomSequence)
                            sequence =  str2num(CustomSequence{1}); %#ok<ST2NM>
                        else
                            error('Cannot find custom sequence.')
                        end

                end


                sequence_step = 1;
                programme_running = 1;
                set(RunProgramButton,'Enable','off')
                set(RunTrialButton,'Enable','off')
            end


            if sequence_step < length(sequence) + 1
                % update time estimates
                t=toc;
                if t < 2
                    % programme just started
                    ks = strkat('Running inter-trial function....');
                else
                    tt=(t/(sequence_step-1))*length(sequence) - t; % time remaining
                    tt=oval(tt,2);
                    t=oval(toc,2);
                    ks = strkat('Running inter-trial function....','\n','Elapsed time is :', (t), 'seconds'...
                   ,'\n',(tt),'seconds remain');
                end

                % start scopes
                ScopeCallback;


                % run inter-trial function
                iti = (get(InterTrialIntervalControl,'String'));
                set(Konsole,'String',ks)
                eval(iti)

                % stop scopes
                ScopeCallback;

                % check if pause is required
                if get(PauseProgramButton,'Value') 
                    set(PauseProgramButton,'String','PAUSED')
                end
                while get(PauseProgramButton,'Value') == 1  
                    pause(0.1)
                end


                % run the correct step of the sequence
                set(ParadigmListDisplay,'Value',sequence(sequence_step));
                sequence_step = sequence_step + 1;
                RunTrial; 

            else  
                % programme has finished running
                programme_running = 0;
                set(Konsole,'String','Programme has finished running.')
                set(RunProgramButton,'Enable','on')
                set(RunTrialButton,'Enable','on')
                set(PauseProgramButton,'Enable','off')
                set(AbortProgramButton,'Enable','off');

                % re-select the initially selected paradgims
                set(ParadigmListDisplay,'Value',unique(sequence));

                sequence = [];
                sequence_step = [];

                beep
                pause(0.1)
                beep


            end
        else
            % abort!
            programme_running = 0;
            set(Konsole,'String','Programme has been aborted!')
            set(RunProgramButton,'Enable','on')
            set(RunTrialButton,'Enable','on')
            set(PauseProgramButton,'Enable','off')
            set(AbortProgramButton,'Enable','off');

            % re-select the initially selected paradgims
            try
                set(ParadigmListDisplay,'Value',unique(sequence));
            catch
            end

            sequence = [];
            sequence_step = [];

            beep
            beep
            pause(0.1)
            beep
            beep
            
            set(AbortProgramButton,'Value',0)
            set(AbortProgramButton,'String','ABORT')
        end
    end

%% pause program
    function [] = PauseProgram(~,~)
        if pause_programme
            set(PauseProgramButton,'String','PAUSE');
            pause_programme = 0;
        else
            set(PauseProgramButton,'String','Pausing...')
            pause_programme = 1;
        end
        
        
    end

%% control paradigm list callback
    function [] = ControlParadigmListCallback(~,~)
        % how many paradigms selected?
        if length(get(ParadigmListDisplay,'Value')) > 1
            % more than one. so unset RUN
            set(RunTrialButton,'Enable','off');
            set(ViewControlParadigmButton,'Enable','off');
        else 
            set(ViewControlParadigmButton,'Enable','on');
            % check if destination is OK
            
                set(RunTrialButton,'Enable','on');
            
        end
        if Trials(get(ParadigmListDisplay,'Value'))
            showthis = strkat(mat2str(Trials(get(ParadigmListDisplay,'Value'))),'  trials recorded on selected Paradigm(s)');
            set(Konsole,'String',showthis)
        else
            % no trials on this paradigm
            set(Konsole,'String','No trials have been recorded on selected paradigm(s).')
        end
    end

%% view control paradigm callback
    function [] = ViewControlParadigm(~,~)
        % try to close previous figure
        try 
            close(handles.view_paradigm_figure)
        catch
        end

        % there are length(UsedOutputChannels) outputs
        no = length(UsedOutputChannels) + length(UsedDigitalOutputChannels);

        % figure out how to arrange subplots
        nrows = floor(sqrt(no));
        ncols = ceil(no/nrows);
        
        handles.view_paradigm_figure = figure('Position',[500 150 750 650],'Name','Control Signals','NumberTitle','off','Resize','on'); hold on; 
        hold on
        sr = str2double(get(SamplingRateControl,'String'));
        t  = (1:length(ControlParadigm(get(ParadigmListDisplay,'Value')).Outputs))/sr;
        ocn = [OutputChannelNames(UsedOutputChannels) DigitalOutputChannelNames(UsedDigitalOutputChannels)];
        for vi = 1:no
            subplot(nrows,ncols,vi); hold on
            plot(t,ControlParadigm(get(ParadigmListDisplay,'Value')).Outputs(vi,:),'LineWidth',2);
            set(gca,'XLim',[0 max(t)])
            title(ocn{vi},'FontSize',20,'Interpreter','none')
        end
%         prettyFig('EqualiseY =1;','fs=18;')
        prettyFig;
        
    end

%% run trial
    function [] = RunTrial(~,~) 
        webcam_buffer = [];

        % disable all buttons
        set(ConfigureInputChannelButton,'Enable','off');
        set(ConfigureOutputChannelButton,'Enable','off');
        set(ConfigureControlSignalsButton,'Enable','off');
        set(RunProgramButton,'Enable','off');
        set(PauseProgramButton,'Enable','off');
        set(StartScopes,'Enable','off');
        set(MetadataButton,'Enable','off');
        set(ManualControlButton,'Enable','off');
        set(FileNameSelect,'Enable','off');
        set(SaveControlParadigmsButton,'Enable','off');
        set(RemoveControlParadigmsButton,'Enable','off');
        
        % enable abort button
        set(AbortProgramButton,'Enable','on');
        
        ComputeEpochs;
        
        if scopes_running
            % stop scopes
            s.stop;
            delete(lh);
            % relabel scopes button
            set(StartScopes,'String','Start Scopes');
            scopes_running = 0;
        end
            
        set(RunTrialButton,'Enable','off','String','running...')
        % figure out which pradigm to run
        ThisParadigm= (get(ParadigmListDisplay,'Value'));
        
        % update plot_length
        if length(ControlParadigm(ThisParadigm).Outputs) > 50000
            if isinf(str2double(get(plot_only_control,'String')))
                set(plot_only_control,'String','50000');
            end
        end
        
        time=(1/w):(1/w):(length(ControlParadigm(ThisParadigm).Outputs)/w);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%  change following ton record a defined number of rames
        
%         % set recording time 
%         if strcmp(camstate,'on')
%             reclen = (length(ControlParadigm(ThisParadigm).Outputs)/w);
%             set(num_of_frames_edit,'string',num2str(reclen));
%         end

        
        % figure out trial no
        if isempty(data)
            % no data at all
            Trials(ThisParadigm) = 1;
            set(Konsole,'String',strkat('Running Trial: \n','Paradigm: \t \t  ',ControlParadigmList{ThisParadigm},'\n Trial: \t \t ','1'))
        else
            if length(data) < ThisParadigm
            
                % first trial in this paradigm
                Trials(ThisParadigm) = 1;
                set(Konsole,'String',strkat('Running Trial: \n','Paradigm: \t \t  ',ControlParadigmList{ThisParadigm},'\n Trial:\t \t ',mat2str(1)))
       
            else
                sz = [];
                eval(strcat('sz=size(data(ThisParadigm).',InputChannelNames{UsedInputChannels(1)},');'));
                Trials(ThisParadigm) = sz(1)+1;
                set(Konsole,'String',strkat('Running Trial: \n','Paradigm: \t \t  ',ControlParadigmList{ThisParadigm},'\n Trial: \t \t ',mat2str(sz(1)+1)))
       
                
            end
            
        end
        
        w=str2num(get(SamplingRateControl,'String')); %#ok<ST2NM>
        if isempty(w)
            error('Sampling Rate not defined!')
        end
        T= length(ControlParadigm(ThisParadigm).Outputs)/w; % duration of trial, for this trial
        % create session
        clear s
        s = daq.createSession('ni');
        s.DurationInSeconds = T;
        s.NotifyWhenDataAvailableExceeds = w/10; % 10Hz
        s.Rate = w; % sampling rate, user defined.
         
        % show the traces as we acquire them on the scope
        figure(handles.scope_fig)
        
        % update scope_plot_data
        handles.scope_handles = []; % axis handles for each sub plot in scope
        rows = ceil(length(get(PlotInputs,'Value'))/2);
        ScopeThese = get(PlotInputs,'Value');
        scope_plot_data = NaN(length(UsedInputChannels),T*w);
        
        ti = 1;
        for i = ScopeThese
            handles.scope_handles(i) = subplot(2,rows,ti); ti = ti+1;
            set(handles.scope_handles(i),'ButtonDownFcn',@ToggleFilterState);
            cla(handles.scope_handles(i));
            handles.plot_handles(i) = plot(NaN,NaN,'k');
            set(handles.scope_handles(i),'XLim',[0 T])
            plotname=strcat(InputChannels{UsedInputChannels(i)},'-',InputChannelNames{UsedInputChannels(i)});
            plotname = strrep(plotname,'_','-');
            title(plotname)
        end
        clear i
         
        % add the analogue input channels
        TheseChannels=InputChannels(UsedInputChannels);
        for i = 1:length(TheseChannels)
            s.addAnalogInputChannel(DeviceName,InputChannels{UsedInputChannels(i)}, 'Voltage');
        end
        clear i

        % add the analogue output channels
        TheseChannels=OutputChannels(UsedOutputChannels);
        for i = 1:length(TheseChannels)
             s.addAnalogOutputChannel(DeviceName,OutputChannels{UsedOutputChannels(i)}, 'Voltage');
        end
        clear i

        % add the digital output channels
        TheseChannels=DigitalOutputChannels(UsedDigitalOutputChannels);
        for i = 1:length(TheseChannels)
             s.addDigitalChannel(DeviceName,DigitalOutputChannels{UsedDigitalOutputChannels(i)}, 'OutputOnly');
        end
        clear i

        % configure listener to plot data on the scopes 
        lh = s.addlistener('DataAvailable',@PlotCallback);
        
        % configure listener to log data
        %lhWrite = s.addlistener('DataAvailable',@(src, event)logData(src, event, fid1));
        
        % queue data        
        s.queueOutputData(ControlParadigm(ThisParadigm).Outputs');
        
        % log the timestamp
        ts = size(timestamps);
        timestamps(1,ts(2)+1)=ThisParadigm; % paradigm number
        timestamps(2,ts(2)+1)=Trials(ThisParadigm); % trial number
        timestamps(3,ts(2)+1)=(now); % time
        
        % if needed, take a picture before starting the trial.
        if ~verLessThan('matlab','8.3')
            if isfield(ControlParadigm(ThisParadigm),'Webcam')
                if find(strcmp('Before',ControlParadigm(ThisParadigm).Webcam))
                    [webcam_buffer(1).pic, webcam_buffer(1).m] = TakePicture;
                    webcam_buffer(1).timestamp = now;
                end
            end
        end
        
        
        % read and write
        trial_running = T*10;
        try
            %check the camera status and start capture i necessary
            if strcmp(camstate,'on')
                % start camera capture
                timestamp = now;
                Acquire_call;
            end
            s.startForeground();

        catch err
            % probably because the hardware is reserved.
            close all
            disp('The error MATLAB reported was:')
            disp(err.message);
            errordlg('kontroller could not start the task. This is probably because the hardware is reserved. You need to restart kontroller. Sorry about that. Type "return" and hit enter to restart.')
            clear all
            keyboard
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%% block the following to record a defined number of
        %%%%%%%%%%%% frames
        
        stop camera acquire after the experiment finishes
        if strcmp(camstate,'on')
            % stop camera capture
            Acquire_call;
        end
        
        
        % if needed, take a picture after finishing the trial.
        if ~verLessThan('matlab','8.3')
            if isfield(ControlParadigm(ThisParadigm),'Webcam')
                if find(strcmp('After',ControlParadigm(ThisParadigm).Webcam))
                    [webcam_buffer(2).pic, webcam_buffer(2).m] = TakePicture;
                    webcam_buffer(2).timestamp = now;
                end
            end
        end
%         

        
        
        ProcessTrialData;
        
        

        set(ConfigureInputChannelButton,'Enable','on');
        set(ConfigureOutputChannelButton,'Enable','on');
        set(ConfigureControlSignalsButton,'Enable','on');
        set(RunProgramButton,'Enable','on');
        set(PauseProgramButton,'Enable','on');
        set(StartScopes,'Enable','on');
        set(MetadataButton,'Enable','on');
        set(ManualControlButton,'Enable','on');
        set(FileNameSelect,'Enable','on');
        set(SaveControlParadigmsButton,'Enable','on');
        set(RemoveControlParadigmsButton,'Enable','on');
        
        % save
       
        SamplingRate = str2double(get(SamplingRateControl,'String'));
        % check if the file exist and save experiment settings
        if exist(strcat(savepath,'\',get(Aviname_edit,'String'),'.mat'),'file')
            save(strcat(savepath,'\',get(Aviname_edit,'String'),'.mat'),'ControlParadigm','OutputChannelNames','SamplingRate','timestamps','-append');
        else
            save(strcat(savepath,'\',get(Aviname_edit,'String'),'.mat'),'ControlParadigm','OutputChannelNames','SamplingRate','timestamps');
        end



    end

%% process data == this function is called when the trial finishes running
    function [] = ProcessTrialData(~,~)
        % delete listeners
        delete(lh)
        
        % check if data needs to be logged
        if isempty(SaveToFile) && gui == 1
            set(RunTrialButton,'enable','on','String','RUN w/o saving');
            return
        end
        
        % combine data and label correctly
        thisdata=scope_plot_data;
       
        if gui
            ThisParadigm= (get(ParadigmListDisplay,'Value'));
        else
            ThisParadigm = RunTheseParadigms(gi);
        end
        
        % check if data exists
        if isempty(data)
            % create it          
            for i = 1:length(UsedInputChannels)
                if  ~strcmp(InputChannelNames{UsedInputChannels(i)},'Ground')               
                    eval( strcat('data(ThisParadigm).',InputChannelNames{UsedInputChannels(i)},'=thisdata(',mat2str(i),',:);'));
                end
            end
            clear i

        else
            % some data already exists, need to append
            % find the correct pradigm
            if length(data) < ThisParadigm
                % first trial in this paradigm
                for i = 1:length(UsedInputChannels)
                    if  ~strcmp(InputChannelNames{UsedInputChannels(i)},'Ground')
                        eval(strcat('data(ThisParadigm).',InputChannelNames{UsedInputChannels(i)},'=[];'))
                    end
                end
            end

            for i = 1:length(UsedInputChannels)
                if  ~strcmp(InputChannelNames{UsedInputChannels(i)},'Ground')
                    eval( strcat('data(ThisParadigm).',InputChannelNames{UsedInputChannels(i)},'=vertcat(data(ThisParadigm).',InputChannelNames{UsedInputChannels(i)},',thisdata(',mat2str(i),',:));'))
            
                end
            end

        end
            
        % pack webcam data correctly
        if ~isempty(webcam_buffer)
            for wi = 1:length(webcam_buffer)
                if isfield(data(ThisParadigm),'webcam')
                    data(ThisParadigm).webcam(length(data(ThisParadigm).webcam)+1) = webcam_buffer;
                else
                    % no webcam info
                    data(ThisParadigm).webcam = webcam_buffer(wi);
                end
            end
        end
        webcam_buffer = [];
       
        
        % save data to file
        if gui
            SamplingRate= str2double(get(SamplingRateControl,'String'));
            temp = OutputChannelNames;
            OutputChannelNames = {OutputChannelNames{UsedOutputChannels} DigitalOutputChannelNames{UsedDigitalOutputChannels}};
            save(strcat('C:\data\',SaveToFile),'data','ControlParadigm','metadata','OutputChannelNames','SamplingRate','timestamps');       
        
            OutputChannelNames = temp; clear temp
            set(RunTrialButton,'Enable','on','String','RUN and SAVE');      
            set(Konsole,'String',strkat('Trial ',mat2str(Trials(ThisParadigm)),'/Paradigm ',mat2str(ThisParadigm),' completed.'));
        end
        
        
        
        % check to make sure that the session has stopped
        if s.IsRunning
            s.stop;
        end
        % check if there is a programme running, and handle it approproately 
        if programme_running
            % continue with the flow
            RunProgram;
        end
        
    end

%% save control paradigms
    function [] = SaveControlParadigms(~,~)
        temp=strcat(datestr(now,'yyyy_mm_dd'),'_kontroller_paradigm_.mat');
        ControlParadigmSaveToFile=uiputfile(temp);
        save(ControlParadigmSaveToFile,'ControlParadigm');
    end

%% load saved control paradigms
    function [] = LoadSavedParadigms(~,~)
        [FileName,PathName] = uigetfile('*_kontroller_paradigm*');
        temp=load(strcat(PathName,FileName));

        % check that this Control PAradigm has the same number of outputs as there are output channels
        [nol,~]=size(temp.ControlParadigm(1).Outputs);
        if nol == length(UsedOutputChannels) + length(UsedDigitalOutputChannels)
            % alles OK
        else
            % ouch
            
            errordlg('Error: The Paradigm you tried to load doesnt have the same number of outputs as the number of outputs currently configured. Either load a new Control Paradigm, or change the number of OutputChannels to match this paradigm.','kontroller cannot do this.')
            return
        end 

        ControlParadigm=temp.ControlParadigm;
        clear temp
        % now update the list
        ControlParadigmList = {};
        for i = 1:length(ControlParadigm)
            ControlParadigmList = [ControlParadigmList ControlParadigm(i).Name];
        end
        set(ParadigmListDisplay,'String',ControlParadigmList)
        
        % update Trial count
        Trials = zeros(1,length(ControlParadigmList));
        set(Konsole,'String','Controls have been configured. ')
        
        % update run button
        if isempty(SaveToFile)
            set(RunTrialButton,'enable','on','String','RUN w/o saving','BackgroundColor',[0.9 0.1 0.1]);
        else
            set(RunTrialButton,'enable','on','String','RUN and SAVE','BackgroundColor',[0.1 0.9 0.1]);
        end
        delete(handles.configure_control_signals_figure)
        
        % show the name
        set(ParadigmNameDisplay,'String',strrep(FileName,'_kontroller_Paradigm.mat',''))
    end

%% metadata callback
    function [] = MetadataCallback(~,~)
        % open the editor
        handles.metadata_editor_figure = figure('Position',[60 50 450 400],'Toolbar','none','Menubar','none','Name','Metadata Editor','NumberTitle','off','Resize','off');
        uicontrol(handles.metadata_editor_figure,'Style','Text','String','Add or modify metadata using standard MATLAB syntax, one variable at a time, below:','Position',[5 340 440 50],'HorizontalAlignment','left')
        % MetadataTextControl = uicontrol(handles.metadata_editor_figure,'Style', 'edit', 'String','','Position',[5 285 440 40],'HorizontalAlignment','left','Callback',@AddMetadata);
        MetadataTextDisplay = uicontrol(handles.metadata_editor_figure,'Style','Text','String',metadatatext,'Position',[25 5 400 220]);

        % configure autocomplete
        autocompletionList = cache('autocompletionList');
        if ~iscell(autocompletionList)
            autocompletionList = {autocompletionList};
        end
        if ~isempty(autocompletionList)
            strs = autocompletionList;
            strList = java.util.ArrayList;
            for idx = 1 : length(strs),  strList.add(strs{idx});  end
            jPanelObj = com.mathworks.widgets.AutoCompletionList(strList,'');
            javacomponent(jPanelObj.getComponent, [25 250 400 100], gcf);
            jPanelObj.setStrict(false);
            jPanelObj.setVisibleRowCount(1);
            set(handle(jPanelObj,'callbackproperties'), 'ActionPerformedCallback', @AddMetadata);
        end
        
        
    end

%% metadata editor callback
    function [] = AddMetadata(src,~)   
        % evaluate only if the string is terminated with a semi-colon
        entered_string = get(src,'SelectedValue');
        if length(entered_string) == 0
            return
        end
        if ~strcmp(entered_string(end),';')
            return
        end
        % load autocompletion list
        autocompletionList = cache('autocompletionList');
        %  remember this for later for autocompletion purposes
        if isempty(find(strcmp(entered_string,autocompletionList)))
            if isempty(autocompletionList)
                autocompletionList = cell(1);
                autocompletionList{1} = entered_string;
            else
                autocompletionList = [autocompletionList entered_string];
            end
            
            cache('autocompletionList',[]);
            cache('autocompletionList',autocompletionList);
        else
            
        end

        % evaluate it
        try
            eval(strcat('metadata.',entered_string,';'));
            % rebuild display cell string
            metadatatext = [];
            fn = fieldnames(metadata);
            for i = 1:length(fn)
                metadatatext{i} = strcat(fn{i},' : ',mat2str(getfield(metadata,fn{i})));
            end
            set(MetadataTextDisplay,'String',metadatatext);
            set(MetadataTextControl,'String','');

            % remove the nagging colour from the metadata control button
            set(MetadataButton,'BackgroundColor',[1 1 1]);
        catch
            
        end


        
    end

%% clean up when quitting kontroller
    function [] = QuitkontrollerCallback(~,~)
       selection = questdlg('Are you sure you want to quit kontroller?','Confirm quit.','Yes','No','Yes'); 
       switch selection, 
          case 'Yes',
              fn = fieldnames(handles);
              for i = 1:length(fn)
                try
                    eval(['delete(handles.' fn{i} ')'])
                catch
                end
              end
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

%% clean up when quitting Manual Control
    function [] = QuitManualControlCallback(~,~)
        % stop session
        try
            s.stop;
        catch
        end
        try
            
            delete(lh)
        catch
        end
        try
            delete(lhMC)
        catch
        end
        
        try
            delete(handles.manual_control_figure)
        catch
        end
        
        try
            delete(fMCD)
        catch
        end
        scopes_running=0;
        
        % relabel scopes button
        set(StartScopes,'String','Start Scopes');

    end

%% on closing output config wiindows
    function  [] = QuitConfigOutputsCallback(~,~)
        % close both windows together
        try
            delete(handles.configure_output_channels_figure);
        end
        try
            delete(handles.configure_digital_output_channels_figure);
        end
    end

%% remove control paradigms

    function [] = RemoveControlParadigms(~,~)
        if ~isempty(ControlParadigmList)
            removethese = get(ParadigmListDisplay,'Value');
            
             
            % remove them from the ControlParadigm list
            ControlParadigmList(removethese) = [];
            
            % remove them from the display list
            set(ParadigmListDisplay,'Value',1)
            set(ParadigmListDisplay,'String',ControlParadigmList);
            % remove them from the actual control paradigm data structure
            ControlParadigm(removethese) = [];
            
        else
            % do nothing for now
        end
        
    end

%% Compute Epochs

    function [] = ComputeEpochs(~,~)
        ThisParadigm =  (get(ParadigmListDisplay,'Value'));
        TheseDigitalOutputs = [];
        TheseDigitalOutputs=ControlParadigm(ThisParadigm).Outputs(length(UsedOutputChannels)+1:length([UsedOutputChannels UsedDigitalOutputChannels]),:);
        sz = size(TheseDigitalOutputs);
        Epochs = zeros(1,sz(2));
        for si = 1:sz(1)
            TheseDigitalOutputs(si,:) = TheseDigitalOutputs(si,:).*(2^si-1);
        end
        if isvector(TheseDigitalOutputs)
            Epochs= TheseDigitalOutputs;
        else
            Epochs = sum(TheseDigitalOutputs);
        end
        
        % compress epochs
        ue = unique(Epochs);
        for si = 1:length(unique(Epochs))
            Epochs(Epochs == ue(si)) = 1e4+si;
        end
        Epochs = Epochs-1e4;
        
        % defensive porgramming
        if ~isvector(Epochs)
            error('Error 1956: Epochs is not a vector. Something wrong in ComputeEpochs')
        end
        
    end

end

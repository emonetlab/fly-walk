%% sorts fly walk events such as plume contacts
function f = sortEventsFindPeak(f)

% shared variables
smooth_length = [];% How much to smooth the signal before analyzing the peaks. (Previous value: 3)
smooth_type = []; % smoothing type
minpeakdist = []; % The minimum time that two neighboring detected peaks must have between them.
minpeakprom = []; % The minimum intensity that the peak prominence must have.
maxpeakwidth = []; % The maximum length that a signal increase can have in seconds.
minpeakheight = [];% % The mimimum intensity that the peak height can have.
min_track_length = []; % 1 second, if tracks length is shorter ignore it
smthtypelist = [];
encnum = [];
tracknum = [];
TotTracksnum = [];
smth_signal = [];
plot_xlimit = [];
plot_ylimit = [];
on_point = [];
peak_point = [];
off_point = [];
nofEncs = [];
vtnum = 1;
validtracks = [];
threshold_plot = [];

flysize = round(8/f.ExpParam.mm_per_px); %make manual
% check if signal is sorted
if ~any(strcmp(fieldnames(f.tracking_info),'signal_sorted'))
    % are peaks found
    % find peaks if not found earlier
    if ~isfield(f.tracking_info,'signal_peak')
        f = getBinarizedSignalDetection(f);
%         f = getBinarizedSignalDetection(f,threshSig,maskdilate);
%         f = FindPlumeContacts(f);
    end
    f.tracking_info.signal_sorted = zeros(size(f.tracking_info.signal_peak));
    getValidTracks;
    encnum = 1;
    vtnum = 1;
    tracknum = validtracks(vtnum);
else
    getValidTracks;
    getTrackEncNum;
end

% are there saved parameters
if exist('PeakDetectParameters.mat','file') == 2
    load('PeakDetectParameters.mat');
    f.plm_cont_par.smooth_length = smooth_length;% How much to smooth the signal before analyzing the peaks. (Previous value: 3)
    f.plm_cont_par.smooth_type = smooth_type; % smoothing type
    f.plm_cont_par.minpeakdist = minpeakdist; % The minimum time that two neighboring detected peaks must have between them.
    f.plm_cont_par.minpeakprom = minpeakprom; % The minimum intensity that the peak prominence must have.
    f.plm_cont_par.maxpeakwidth = maxpeakwidth; % The maximum length that a signal increase can have in seconds.
    f.plm_cont_par.minpeakheight = minpeakheight;% % The mimimum intensity that the peak height can have.
    f.plm_cont_par.min_track_length = min_track_length; % 1 second, if tracks length is shorter ignore it
    if ~isempty(who('sgolayorderval'))
        f.plm_cont_par.sgolayorder = sgolayorderval;
    end
else
    % default
    % first detect the peaks
    smooth_length = 1;% How much to smooth the signal before analyzing the peaks. (Previous value: 3)
    smooth_type = 'box smooth'; % smoothing type
    minpeakdist = .1; % The minimum time that two neighboring detected peaks must have between them.
    minpeakprom = .7; % The minimum intensity that the peak prominence must have.
    maxpeakwidth = 1; % The maximum length that a signal increase can have in seconds.
    minpeakheight = 1;% % The mimimum intensity that the peak height can have.
    min_track_length = 1; % 1 second, if tracks length is shorter ignore it
    f.plm_cont_par.smooth_length = smooth_length;% How much to smooth the signal before analyzing the peaks. (Previous value: 3)
    f.plm_cont_par.smooth_type = smooth_type; % smoothing type
    f.plm_cont_par.minpeakdist = minpeakdist; % The minimum time that two neighboring detected peaks must have between them.
    f.plm_cont_par.minpeakprom = minpeakprom;%3; % The minimum intensity that the peak prominence must have.
    f.plm_cont_par.maxpeakwidth = maxpeakwidth; % The maximum length that a signal increase can have in seconds.
    f.plm_cont_par.minpeakheight = minpeakheight;% % The mimimum intensity that the peak height can have.
    f.plm_cont_par.min_track_length = min_track_length; % 1 second, if tracks length is shorter ignore it
end



% % return if there is no peak detected
% if size(f.tracking_info.signal_peak,2)<=1
%     return
% end

% do not run tracking during manual sort
f.label_flies = true;         % show fly labels next to each fly
f.mark_flies = false;       % show fly markers
f.show_orientations = false;      % show orientations, 0: do not show, 1: orientations, 2: heading, 3: both
f.show_trajectories = false;      % show tracks with a tail length of trajectory_vis_length 
f.show_antenna = true;          % shows the virtual antenna, where signal is integrated for each fly in each frame, 1: only antenna, 2: mask in a separate window
f.mark_lost = false;
f.track_movie=0;

% some variables
these_frames = [];
signalplot = [];
onsetplot =  [];
offsetplot =  [];
peakplot =  [];
onsetplot_all =  [];
offsetplot_all =  [];
peakplot_all =  [];
playBNF = 0;


track_play_length = 0.5;  % sec before and after the collision, approx

play_buffer = round(track_play_length*f.ExpParam.fps);

% get image x and y limts
xlimo = f.plot_handles.ax.XLim;
ylimo = f.plot_handles.ax.YLim;

% disbale some annotation
% get originals
oa(1) = logical(f.label_flies);         % show fly labels next to each fly
oa(2) = logical(f.mark_flies);       % show fly markers
oa(3) = logical(f.show_orientations);      % show orientations, 0: do not show, 1: orientations, 2: heading, 3: both
oa(4) = logical(f.show_trajectories);      % show tracks with a tail length of trajectory_vis_length 
oa(5) = logical(f.show_antenna);          % shows the virtual antenna, where signal is integrated for each fly in each frame, 1: only antenna, 2: mask in a separate window
oa(6) = logical(f.mark_lost);

%%
scsz = get(0,'ScreenSize');
yw = 5*scsz(4)/7;
xw = 3*scsz(3)/5;
if xw<1070
    xw = 1070;
end

[~,flnm,~] = fileparts(f.path_name.Properties.Source);        
        
fSFW = figure('Position',[2.7*scsz(3)/7 1.5*scsz(4)/7 xw 5*scsz(4)/7],'NumberTitle','off','Visible','on','Name',flnm,'Menubar', 'none',...
    'Toolbar','figure','resize', 'on' ,'CloseRequestFcn',@QuitsortFlyWalkCallback);
        

%% error panel
errorpanel=uipanel('parent', fSFW,'fontunits', 'normalized','FontSize',.1,'units','normalized','pos',[643/xw 190/yw 420/xw 150/yw]);
errorboard = uicontrol('parent',errorpanel,'fontunits', 'normalized','FontSize',.15,'units','normalized','Style','text',...
            'position',[.03 .03 .9 .8],'String','','Max',2,'HorizontalAlignment', 'left','ForegroundColor','r');
overlapboard = uicontrol('parent',errorpanel,'fontunits', 'normalized','FontSize',.8,'units','normalized','Style','text',...
            'position',[.03 .85 .9 .15],'String','','HorizontalAlignment', 'left','ForegroundColor','k','Fontweight','bold');  


%% peak detect panel
peakdetectpanel=uipanel('parent', fSFW,'fontunits', 'normalized','FontSize',.1,'units','normalized','pos',[643/xw 25/yw 420/xw 155/yw]);

uicontrol('parent',peakdetectpanel,'fontunits', 'normalized','FontSize',.5,'units','normalized','Style','text',...
            'position',[0.01 .83 .23 .13],'String','smooth-len (pnts):','Fontweight','bold');
smoothlen = uicontrol('parent',peakdetectpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[.28 .85 .08 .13],'Style','edit','String',num2str(smooth_length),'ForegroundColor','k','Callback',@ParameterCall);

smthtypelist = {'box smooth','s-golay'};
ll_value = find(strcmp(smthtypelist,smooth_type));
smoothtype = uicontrol('parent',peakdetectpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[.41 .875 .2 .11],'Style','popup','String',smthtypelist,'Value',ll_value,'Callback',@ParameterCall);
if ll_value==1
    sgolvis = 'off';
elseif ll_value==2
    sgolvis = 'on';
end


if ~isempty(who('sgolayorderval'))
    sgolaytext = uicontrol('parent',peakdetectpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
            'position',[0.65 .83 .1 .13],'String','order:','Fontweight','bold','visible',sgolvis);
    sgolayorder = uicontrol('parent',peakdetectpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[.75 .84 .08 .13],'Style','edit','String',num2str(sgolayorderval),'ForegroundColor','k','visible',sgolvis,'Callback',@ParameterCall);
else
    sgolayorder = uicontrol('parent',peakdetectpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[.75 .84 .08 .13],'Style','edit','String','1','ForegroundColor','k','visible',sgolvis,'Callback',@ParameterCall);
    sgolaytext = uicontrol('parent',peakdetectpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
            'position',[0.65 .83 .1 .13],'String','order:','Fontweight','bold','visible',sgolvis);
end

uicontrol('parent',peakdetectpanel,'fontunits', 'normalized','FontSize',.5,'units','normalized','Style','text',...
            'position',[0.01 .635 .26 .13],'String','min-peak-dist (sec):','Fontweight','bold');
minpeakdisted = uicontrol('parent',peakdetectpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[.28 .65 .08 .13],'Style','edit','String',num2str(minpeakdist),'ForegroundColor','k','Callback',@ParameterCall);

uicontrol('parent',peakdetectpanel,'fontunits', 'normalized','FontSize',.5,'units','normalized','Style','text',...
            'position',[0.01 .445 .26 .13],'String','min-peak-prom (a.u):','Fontweight','bold');
minpeakpromed = uicontrol('parent',peakdetectpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[.28 .46 .08 .13],'Style','edit','String',num2str(minpeakprom),'ForegroundColor','k','Callback',@ParameterCall);

uicontrol('parent',peakdetectpanel,'fontunits', 'normalized','FontSize',.5,'units','normalized','Style','text',...
            'position',[0.01 .255 .27 .13],'String','max-peak-width (sec):','Fontweight','bold');
maxpeakwidthed = uicontrol('parent',peakdetectpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[.28 .27 .08 .13],'Style','edit','String',num2str(maxpeakwidth),'ForegroundColor','k','Callback',@ParameterCall);

uicontrol('parent',peakdetectpanel,'fontunits', 'normalized','FontSize',.5,'units','normalized','Style','text',...
            'position',[0.01 .065 .27 .13],'String','min-peak-height (a.u):','Fontweight','bold');
minpeakheighted = uicontrol('parent',peakdetectpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[.28 .08 .08 .13],'Style','edit','String',num2str(minpeakheight),'ForegroundColor','k','Callback',@ParameterCall);

uicontrol('parent',peakdetectpanel,'fontunits', 'normalized','FontSize',.5,'units','normalized','Style','text',...
            'position',[0.5 .065 .27 .13],'String','min-track-length (sec):','Fontweight','bold');
mintracklength = uicontrol('parent',peakdetectpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[.77 .08 .08 .13],'Style','edit','String',num2str(min_track_length),'ForegroundColor','k','Callback',@ParameterCall);

findButton = uicontrol('parent',peakdetectpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[.5 .4 .27 .2],'Style','pushbutton','Enable','on','String','Find Peaks','Callback',@findPeaksCall);

%% Track Panel
% trackPanel = uipanel('parent', fSFW,'fontunits', 'normalized','FontSize',.1,'units','normalized','pos',[815/xw 360/yw .23 0.4]);
trackPanel = uipanel('parent', fSFW,'fontunits', 'normalized','FontSize',.1,'units','normalized','pos',[815/xw 360/yw .23 0.4]);

% TRACK NAVIGATION
yoffset = .85;
xoffset = .03;
wd = .15;
hg = .12;
trackNum = uicontrol('parent',trackPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[xoffset yoffset wd hg],'Style','edit','String',num2str(tracknum),'ForegroundColor','k','Callback',@trackNumCall);

TotTracksnum = length(validtracks);
Tottracks = uicontrol('parent',trackPanel,'fontunits', 'normalized','FontSize',.9,'units','normalized','Style','text',...
            'position',[xoffset+wd+.005 yoffset+.01 2*wd hg],'String',['/',num2str(TotTracksnum)],'Fontweight','bold');
Prevtrack = uicontrol('parent',trackPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
            'Position',[xoffset+3*wd+.05 yoffset 1.5*wd 1.1*hg],'Style','pushbutton','Enable','on','String','< Prev','Callback',@PrevtrackCall);
Nexttrack = uicontrol('parent',trackPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
            'Position',[xoffset+5*wd-.01 yoffset 1.5*wd 1.1*hg],'Style','pushbutton','Enable','on','String','Next >','Callback',@NexttrackCall);
        
% showall_radio = uicontrol('parent',trackPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','rad',...
%     'position',[xoffset .15 .4 .1],'Value',1,'visible','on','string','show all','Callback',@ZoomCall);

zoom_radio = uicontrol('parent',trackPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','rad',...
    'position',[xoffset .05 .4 .1],'Value',0,'visible','on','string','zoom','Callback',@ZoomCall);

zoomNum = uicontrol('parent',trackPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[xoffset+.27 .05 .1 .09],'Style','edit','String','5','ForegroundColor','k','Callback',@ZoomCall);
uicontrol('parent',trackPanel,'fontunits', 'normalized','FontSize',.7,'units','normalized','Style','text',...
            'position',[xoffset+.37 .05 .25 .1],'String','*width');

uicontrol('parent',trackPanel,'fontunits', 'normalized','FontSize',.45,'units','normalized','Style','text',...
    'position',[xoffset-.077 .177 .4 .1],'Value',0,'visible','on','string','Fly-Box-Size');
        
FlyBoxSize = uicontrol('parent',trackPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[xoffset+.27 .2 .1 .09],'Style','edit','String','8','ForegroundColor','k','Callback',@FlyBoxCall);
uicontrol('parent',trackPanel,'fontunits', 'normalized','FontSize',.7,'units','normalized','Style','text',...
            'position',[xoffset+.37 .2 .25 .1],'String','(mm)');



%% Edit Panel
editPanel = uipanel('parent', fSFW,'fontunits', 'normalized','FontSize',.1,'units','normalized','pos',[35/xw 30/yw 600/xw 290/yw]);
%  ONSET
uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
            'position',[.06 .89 .1 .1],'String','Onset','fontweight','bold','ForegroundColor','g');
onset_radio = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','rad',...
    'position',[.03 .9 .03 .1],'Value',1,'Callback', @onset_rad_call,'visible','on');
onNum = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[.165 .91 .08 .08],'Style','edit','String','1','Callback',@onNumCall);

% next button
NextButton_on = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
            'Position',[.15 .8 .1 .1],'Style','pushbutton','Enable','on','String','Next >','Callback',@Nexton);
        
PrevButton_on = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[.04 .8 .1 .1],'Style','pushbutton','Enable','on','String','< Prev','Callback',@Prevon);

%  PEAK
xoffset= .27;
uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
            'position',[.06+xoffset .89 .1 .1],'String','Peak','fontweight','bold','ForegroundColor','k');
peak_radio = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','rad',...
    'position',[.03+xoffset .9 .03 .1],'Value',0,'Callback', @peak_rad_call,'visible','on');

peakNum = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[.165+xoffset .91 .08 .08],'Style','edit','String','1','Callback',@peakNumCall);

% next button
NextButton_peak = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
            'Position',[.15+xoffset .8 .1 .1],'Style','pushbutton','Enable','on','String','Next >','Callback',@Nextpeak);
        
PrevButton_peak = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[.04+xoffset .8 .1 .1],'Style','pushbutton','Enable','on','String','< Prev','Callback',@Prevpeak);

%  OFFSET
xoffset= .55;
uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
            'position',[.06+xoffset .89 .1 .1],'String','Offset','fontweight','bold','ForegroundColor','r');
off_radio = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','rad',...
    'position',[.03+xoffset .9 .03 .1],'Value',0,'Callback', @offset_rad_call,'visible','on');
offNum = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[.165+xoffset .91 .08 .08],'Style','edit','String','1','Callback',@offNumCall);

% next button
NextButton_off = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
            'Position',[.15+xoffset .8 .1 .1],'Style','pushbutton','Enable','on','String','Next >','Callback',@Nextoff);
        
PrevButton_off = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[.04+xoffset .8 .1 .1],'Style','pushbutton','Enable','on','String','< Prev','Callback',@Prevoff);

% REFLECTION
refl_radio = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized','Style','rad',...
    'position',[.3+xoffset .9 .03 .1],'Value',0,'Callback', @refl_rad_call,'visible','on');
uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized','Style','text',...
            'position',[.33+xoffset .884 .1 .1],'String','Refl.','fontweight','bold','ForegroundColor','k');
        
% DELETE ENCOUNTER
DeleteButton = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[.29+xoffset .8 .13 .1],'Style','pushbutton','Enable','on','String','del-enc','Callback',@DelEnc);

% ADD ENCOUNTER
yoffset = .61;
AddButton = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[.03 yoffset-.01 .12 .1],'Style','pushbutton','Enable','off','String','Add-enc','Callback',@AddEnc);

onAdd = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[.16 yoffset .08 .08],'Style','edit','String','NaN','ForegroundColor','g','Callback',@Addedit);
peakAdd = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[.25 yoffset .08 .08],'Style','edit','String','NaN','ForegroundColor','k','Callback',@Addedit);
offAdd = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[.34 yoffset .08 .08],'Style','edit','String','NaN','ForegroundColor','r','Callback',@Addedit);

% ENCOUNTER NAVIGATION
yoffset = .6;
xoffset = .5;
encNumBorder = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[xoffset-.01 yoffset-.015 .12 .13],'Style','pushbutton','Enable','off','String','');
encNum = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[xoffset yoffset .1 .1],'Style','edit','String','1','ForegroundColor','k','Callback',@encNumCall);
TotEncs = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.75,'units','normalized','Style','text',...
            'position',[xoffset+.11 yoffset-.013 .12 .12],'String',length(nonzeros(f.tracking_info.signal_peak(tracknum,:))),'fontweight','bold');
PrevEnc = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.55,'units','normalized',...
            'Position',[xoffset+.25 yoffset .11 .12],'Style','pushbutton','Enable','on','String','< Prev','Callback',@Prevenc);
NextEnc = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.55,'units','normalized',...
            'Position',[xoffset+.37 yoffset .11 .12],'Style','pushbutton','Enable','on','String','Next >','Callback',@Nextenc);


stopBNFButton = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[.83 .15 .15 .1],'Style','pushbutton','Enable','on','String','stop BNF','Callback',@BNF_call);

doneButton = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[.83 .03 .15 .1],'Style','pushbutton','Enable','on','String','Done','Callback',@done_call);

save_radio = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.4,'units','normalized','Style','rad',...
    'position',[.73 .03 .1 .1],'Value',0,'visible','on','string','save f');

defcolor = get(AddButton,'BackgroundColor');

if playBNF
    set(stopBNFButton,'string','stop BNF')
else
    set(stopBNFButton,'string','start BNF')
end

%% graph axes
ax1 = axes('units','normalized','Position',[50/xw 390/yw 0.7 0.35]);
hold on
rec1 = rectangle('position',[0 0 0 0],'facecolor',[.8 .8 .8],'edgecolor','none');
signalplot = plot(ax1,NaN,NaN,'LineWidth',2);
threshold_plot = plot(ax1,NaN,NaN,'r--','LineWidth',1);
onsetplot =  plot(ax1,NaN,NaN,'og');
offsetplot =  plot(ax1,NaN,NaN,'or');
peakplot =  plot(ax1,NaN,NaN,'ok');
onsetplot_all =  plot(ax1,NaN,NaN,'+g');
offsetplot_all =  plot(ax1,NaN,NaN,'+r');
peakplot_all =  plot(ax1,NaN,NaN,'+k');
% title('area')
% xlabel('sec')


%% initialize
track_start = find(f.tracking_info.fly_status(tracknum,:)==1,1,'first');
track_end = find(f.tracking_info.fly_status(tracknum,:)==1,1,'last');
these_frames = track_start:track_end;
nofEncs = length(nonzeros(f.tracking_info.signal_peak(tracknum,:)));
plot_enc = 1; % plot onset

if nofEncs~=0
    setErrorMsg;
    % refreshIntPanel;
    plotFlyTrack;
    plotSignal;
    plotPeaks;
    updateSignalPlot;
else
    plotSignal;
    set(errorboard,'string','No Peaks Detected ');
end

% set the values in the edit boxes
on_point = f.tracking_info.signal_onset(tracknum,encnum);
peak_point = f.tracking_info.signal_peak(tracknum,encnum);
off_point = f.tracking_info.signal_offset(tracknum,encnum);

set(onNum,'string',num2str(on_point));
set(offNum,'string',num2str(off_point));
set(peakNum,'string',num2str(peak_point));

setOverlapMsg;
set(encNum,'string',num2str(encnum));
set(trackNum,'string',num2str(tracknum));

%% set the flywalk window size to quarter
% 
figpossave = f.ui_handles.fig.Position; 
f.ui_handles.fig.Position = [10/1152*xw 250/771*yw 1.13*scsz(3)/3 2.08*scsz(4)/3];

%% functions

function [] = getValidTracks(~,~)
    assigned_flies = find(f.tracking_info.fly_status(:,end)>0,1,'last');
    validtracks = 1:assigned_flies;
    keep_tracks = zeros(size(validtracks));
    for i = validtracks
        trk_start = find(f.tracking_info.fly_status(i,:)==1,1,'first');
        trk_end = find(f.tracking_info.fly_status(i,:)==1,1,'last');
        trk_frames = trk_start:trk_end;
        if length(trk_frames)>f.plm_cont_par.min_track_length
            keep_tracks(i) = 1;
        end
    end
    validtracks = validtracks(logical(keep_tracks));
end


function [] = encNumCall(~,~)
    if nofEncs==0
        return
    end
    f.tracking_info.signal_sorted(tracknum,encnum) = 1;
    encnum = str2num(get(encNum,'string')); %#ok<*ST2NM>
    if encnum>nofEncs
        encnum = nofEncs; % switch to next fly
    end
    if encnum<1
        encnum = 1; % switch to next fly
    end
    if f.tracking_info.signal_sorted(tracknum,encnum)
        set(encNumBorder,'BackgroundColor','g')
    else
        set(encNumBorder,'BackgroundColor',defcolor)
    end
    plot_enc = 1; % plot onset
    set(onset_radio,'value',1)
    set(off_radio,'value',0)
    set(peak_radio,'value',0)
    setErrorMsg;
    
    % set the values in the edit boxes
    on_point = f.tracking_info.signal_onset(tracknum,encnum);
    peak_point = f.tracking_info.signal_peak(tracknum,encnum);
    off_point = f.tracking_info.signal_offset(tracknum,encnum);

    set(onNum,'string',num2str(on_point));
    set(offNum,'string',num2str(off_point));
    set(peakNum,'string',num2str(peak_point));

    plotFlyTrack;
    updateSignalPlot;
    setOverlapMsg;
    
end

function [] = Prevenc(~,~)
    if nofEncs==0
        return
    end
    encnum = encnum - 1;
    if encnum<1
        encnum = 1; % switch to next fly
    end
    set(encNum,'string',num2str(encnum));
    plot_enc = 1; % plot onset
    set(onset_radio,'value',1)
    set(off_radio,'value',0)
    set(peak_radio,'value',0)
    setErrorMsg;
    if f.tracking_info.signal_sorted(tracknum,encnum)
        set(encNumBorder,'BackgroundColor','g')
    else
        set(encNumBorder,'BackgroundColor',defcolor)
    end

    % set the values in the edit boxes
    on_point = f.tracking_info.signal_onset(tracknum,encnum);
    peak_point = f.tracking_info.signal_peak(tracknum,encnum);
    off_point = f.tracking_info.signal_offset(tracknum,encnum);

    set(onNum,'string',num2str(on_point));
    set(offNum,'string',num2str(off_point));
    set(peakNum,'string',num2str(peak_point));
    
    plotFlyTrack;
    updateSignalPlot;
    setOverlapMsg;
    
end

function [] = Nextenc(~,~)
    if nofEncs==0
        return
    end
    f.tracking_info.signal_sorted(tracknum,encnum) = 1;
    encnum = encnum + 1;
    if encnum>nofEncs
        encnum = nofEncs; % switch to next fly
    end
    set(encNum,'string',num2str(encnum));
    plot_enc = 1; % plot onset
    set(onset_radio,'value',1)
    set(off_radio,'value',0)
    set(peak_radio,'value',0)
    setErrorMsg;
    if f.tracking_info.signal_sorted(tracknum,encnum)
        set(encNumBorder,'BackgroundColor','g')
    else
        set(encNumBorder,'BackgroundColor',defcolor)
    end

    % set the values in the edit boxes
    on_point = f.tracking_info.signal_onset(tracknum,encnum);
    peak_point = f.tracking_info.signal_peak(tracknum,encnum);
    off_point = f.tracking_info.signal_offset(tracknum,encnum);

    set(onNum,'string',num2str(on_point));
    set(offNum,'string',num2str(off_point));
    set(peakNum,'string',num2str(peak_point));
    
    plotFlyTrack;
    updateSignalPlot;
    setOverlapMsg;
end

function [] = AddEnc(~,~)
    if any(strcmp({get(onAdd,'string'),get(peakAdd,'string'),get(offAdd,'string')},'NaN'))
    	return
    end
    f.tracking_info.signal_sorted(tracknum,encnum) = 1;
    % get values
    on_point = str2num(get(onAdd,'string'));
    peak_point = str2num(get(peakAdd,'string'));
    off_point = str2num(get(offAdd,'string'));
    encnum = find(f.tracking_info.signal_peak(tracknum,:)>peak_point,1);
    if isempty(encnum) % adding to the end of the list
        encnum = nofEncs +1;
    end
        
    f.tracking_info.signal_onset(tracknum,encnum+1:nofEncs+1) = f.tracking_info.signal_onset(tracknum,encnum:nofEncs);
    f.tracking_info.signal_offset(tracknum,encnum+1:nofEncs+1) = f.tracking_info.signal_offset(tracknum,encnum:nofEncs);
    f.tracking_info.signal_peak(tracknum,encnum+1:nofEncs+1) = f.tracking_info.signal_peak(tracknum,encnum:nofEncs);
    f.tracking_info.signal_sorted(tracknum,encnum+1:nofEncs+1) = f.tracking_info.signal_sorted(tracknum,encnum:nofEncs);
    f.tracking_info.signal_prom(tracknum,encnum+1:nofEncs+1) = f.tracking_info.signal_prom(tracknum,encnum:nofEncs);
    f.tracking_info.signal_width(tracknum,encnum+1:nofEncs+1) = f.tracking_info.signal_width(tracknum,encnum:nofEncs);
    f.tracking_info.signal_onset(tracknum,encnum) = on_point ;
    f.tracking_info.signal_offset(tracknum,encnum) = off_point;
    f.tracking_info.signal_peak(tracknum,encnum) = peak_point;
    f.tracking_info.signal_sorted(tracknum,encnum) = 0;
    f.tracking_info.signal_prom(tracknum,encnum) = smth_signal(peak_point)-smth_signal(on_point);
    f.tracking_info.signal_width(tracknum,encnum) = off_point-on_point;
    nofEncs = length(nonzeros(f.tracking_info.signal_peak(tracknum,:)));
    set(TotEncs,'string',['/',num2str(nofEncs)]);
    plot_enc = 1; % plot onset
    set(onset_radio,'value',1)
    set(off_radio,'value',0)
    set(peak_radio,'value',0)
    setErrorMsg;
    % refreshIntPanel;
    plotFlyTrack;
    plotPeaks;
    updateSignalPlot;
    setOverlapMsg;
    
    set(onNum,'string',num2str(on_point));
    set(offNum,'string',num2str(off_point));
    set(peakNum,'string',num2str(peak_point));
    
    % after the peak is added set edits and button to default
    set(onAdd,'string','NaN')
    set(peakAdd,'string','NaN')
    set(offAdd,'string','NaN')
    set(AddButton,'enable','off')
end


function [] = DelEnc(~,~)
    if nofEncs==0
        return
    end
    f.tracking_info.signal_onset(tracknum,encnum:nofEncs-1) = f.tracking_info.signal_onset(tracknum,encnum+1:nofEncs);
    f.tracking_info.signal_offset(tracknum,encnum:nofEncs-1) = f.tracking_info.signal_offset(tracknum,encnum+1:nofEncs);
    f.tracking_info.signal_peak(tracknum,encnum:nofEncs-1) = f.tracking_info.signal_peak(tracknum,encnum+1:nofEncs);
    f.tracking_info.signal_sorted(tracknum,encnum:nofEncs-1) = f.tracking_info.signal_sorted(tracknum,encnum+1:nofEncs);
    f.tracking_info.signal_prom(tracknum,encnum:nofEncs-1) = f.tracking_info.signal_prom(tracknum,encnum+1:nofEncs);
    f.tracking_info.signal_width(tracknum,encnum:nofEncs-1) = f.tracking_info.signal_width(tracknum,encnum+1:nofEncs);
    f.tracking_info.signal_onset(tracknum,nofEncs) = 0;
    f.tracking_info.signal_offset(tracknum,nofEncs) = 0;
    f.tracking_info.signal_peak(tracknum,nofEncs) = 0;
    f.tracking_info.signal_sorted(tracknum,encnum) = 0;
    f.tracking_info.signal_prom(tracknum,encnum) = 0;
    f.tracking_info.signal_width(tracknum,encnum) = 0;
       
    nofEncs = length(nonzeros(f.tracking_info.signal_peak(tracknum,:)));
    set(TotEncs,'string',['/',num2str(nofEncs)]);
    plot_enc = 1; % plot onset
    set(onset_radio,'value',1)
    set(off_radio,'value',0)
    set(peak_radio,'value',0)
%     setErrorMsg;
    % refreshIntPanel;
    if encnum>nofEncs
        encnum = nofEncs;
    end
    set(encNum,'string',num2str(encnum))
    if nofEncs~=0
        % set the values in the edit boxes
        on_point = f.tracking_info.signal_onset(tracknum,encnum);
        peak_point = f.tracking_info.signal_peak(tracknum,encnum);
        off_point = f.tracking_info.signal_offset(tracknum,encnum);

        set(onNum,'string',num2str(on_point));
        set(offNum,'string',num2str(off_point));
        set(peakNum,'string',num2str(peak_point));
        
        plotFlyTrack;
        plotPeaks;
        updateSignalPlot;
        setOverlapMsg;

    else
        % set the values in the edit boxes
        on_point = these_frames(1);
        peak_point = these_frames(1);
        off_point = these_frames(1);
        plotFlyTracknoDet;

        set(onNum,'string',num2str(on_point));
        set(offNum,'string',num2str(off_point));
        set(peakNum,'string',num2str(peak_point));
    end
   


end


function [] = refl_rad_call(~,~)
    if get(refl_radio,'value')
        f.reflection_status(tracknum,peak_point:these_frames(end)) = 1;
    else
        f.reflection_status(tracknum,peak_point:these_frames(end)) = 0;
    end

end


function [] = onNumCall(~,~)
    on_point = str2num(get(onNum,'string')); %#ok<ST2NM>
    if on_point<these_frames(1)
        on_point = these_frames(1);
    end
    if on_point>these_frames(end)
        on_point = these_frames(end);
    end
    if off_point<on_point
        off_point = on_point;
    end
    set(onset_radio,'value',1)
    set(off_radio,'value',0)
    set(peak_radio,'value',0)
    plot_enc = 1;
    
    if nofEncs~=0
        f.tracking_info.signal_onset(tracknum,encnum) = on_point; 
        plotPeaks;
        plotFlyTrack;
    else
        % set the values in the edit boxes
        plotFlyTracknoDet;
    end
    updateSignalPlot;
    setOverlapMsg;
end

function [] = Nexton(~,~)
    on_point = on_point + 1;
    if on_point>these_frames(end)
        on_point = these_frames(end);
        return
    end
    if off_point<on_point
        off_point = on_point;
    end
    set(onNum,'string',num2str(on_point));
    
    set(onset_radio,'value',1)
    set(off_radio,'value',0)
    set(peak_radio,'value',0)
    plot_enc = 1;
    
    if nofEncs~=0
        f.tracking_info.signal_onset(tracknum,encnum) = on_point; 
        plotPeaks;
        plotFlyTrack;
    else
        % set the values in the edit boxes
        plotFlyTracknoDet;
    end
    updateSignalPlot;
    setOverlapMsg;
end

function [] = Prevon(~,~)
    on_point = on_point - 1;
    if on_point<these_frames(1)
        on_point = these_frames(1);
        return
    end
    set(onNum,'string',num2str(on_point));
    set(onset_radio,'value',1)
    set(off_radio,'value',0)
    set(peak_radio,'value',0)
    plot_enc = 1;

    if nofEncs~=0
        f.tracking_info.signal_onset(tracknum,encnum) = on_point;
        plotPeaks;
        plotFlyTrack;
    else
        % set the values in the edit boxes
        plotFlyTracknoDet;
    end
    updateSignalPlot;
    setOverlapMsg;
end

function [] = offNumCall(~,~)
    off_point = str2num(get(offNum,'string')); %#ok<ST2NM>
    if off_point<these_frames(1)
        off_point = these_frames(1);
    end
    if off_point>these_frames(end)
        off_point = these_frames(end);
    end
    if off_point<on_point
        on_point = off_point;
    end
    set(onset_radio,'value',0)
    set(off_radio,'value',1)
    set(peak_radio,'value',0)
    plot_enc = 3;
    if nofEncs~=0
        f.tracking_info.signal_offset(tracknum,encnum) = off_point; 
        plotPeaks;
        plotFlyTrack;
    else
        % set the values in the edit boxes
        plotFlyTracknoDet;
    end
    updateSignalPlot;
    setOverlapMsg;
end

function [] = Nextoff(~,~)
    off_point = off_point + 1;
    if off_point>these_frames(end)
        off_point = these_frames(end);
        return
    end
    set(offNum,'string',num2str(off_point));
    set(onset_radio,'value',0)
    set(off_radio,'value',1)
    set(peak_radio,'value',0)
    plot_enc = 3;
    if nofEncs~=0
        f.tracking_info.signal_offset(tracknum,encnum) = off_point; 
        plotPeaks;
        plotFlyTrack;
    else
        % set the values in the edit boxes
        plotFlyTracknoDet;
    end
    updateSignalPlot;
    setOverlapMsg;
end

function [] = Prevoff(~,~)
    off_point = off_point - 1;
    if off_point<these_frames(1)
        off_point = these_frames(1);
        return
    end
    if off_point<on_point
        on_point = off_point;
    end
    set(offNum,'string',num2str(off_point));
    set(onset_radio,'value',0)
    set(off_radio,'value',1)
    set(peak_radio,'value',0)
    plot_enc = 3;
    if nofEncs~=0
        f.tracking_info.signal_offset(tracknum,encnum) = off_point; 
        plotPeaks;
        plotFlyTrack;
    else
        % set the values in the edit boxes
        plotFlyTracknoDet;
    end
    updateSignalPlot;
    setOverlapMsg;
end

function [] = peakNumCall(~,~)
    peak_point = str2num(get(peakNum,'string')); %#ok<ST2NM>
    if peak_point<these_frames(1)
        peak_point = these_frames(1);
    end
    if peak_point>these_frames(end)
        peak_point = these_frames(end);
    end
    set(onset_radio,'value',0)
    set(off_radio,'value',0)
    set(peak_radio,'value',1)
    plot_enc = 2;
    if nofEncs~=0
        f.tracking_info.signal_peak(tracknum,encnum) = peak_point; 
        plotPeaks;
        plotFlyTrack;
    else
        % set the values in the edit boxes
        plotFlyTracknoDet;
    end
    updateSignalPlot;
    setOverlapMsg;
end

function [] = Nextpeak(~,~)
    peak_point = peak_point + 1;
    if peak_point>these_frames(end)
        peak_point = these_frames(end);
        return
    end
    set(peakNum,'string',num2str(peak_point));
    set(onset_radio,'value',0)
    set(off_radio,'value',0)
    set(peak_radio,'value',1)
    plot_enc = 2;
    if nofEncs~=0
        f.tracking_info.signal_peak(tracknum,encnum) = peak_point; 
        plotPeaks;
        plotFlyTrack;
    else
        % set the values in the edit boxes
        plotFlyTracknoDet;
    end
    updateSignalPlot;
    setOverlapMsg;
end

function [] = Prevpeak(~,~)
    peak_point = peak_point - 1;
    if peak_point<these_frames(1)
        peak_point = these_frames(1);
        return
    end
    set(peakNum,'string',num2str(peak_point));
    set(onset_radio,'value',0)
    set(off_radio,'value',0)
    set(peak_radio,'value',1)
    plot_enc = 2;
    if nofEncs~=0
        f.tracking_info.signal_peak(tracknum,encnum) = peak_point; 
        plotPeaks;
        plotFlyTrack;
    else
        % set the values in the edit boxes
        plotFlyTracknoDet;
    end
    updateSignalPlot;
    setOverlapMsg;
end

% track navigation
function [] = trackNumCall(~,~)
    tracknum = str2num(get(trackNum,'string')); %#ok<ST2NM>
    if tracknum<validtracks(1)
        tracknum = validtracks(1);
    end
    if tracknum>TotTracksnum
        tracknum = TotTracksnum;
    end
    if ~any(validtracks==tracknum)
        tracknum = validtracks(find(validtracks<tracknum,1,'last'));
    end
    vtnum = find(validtracks==tracknum);
    
    track_start = find(f.tracking_info.fly_status(tracknum,:)==1,1,'first');
    track_end = find(f.tracking_info.fly_status(tracknum,:)==1,1,'last');
    these_frames = track_start:track_end;
    encnum = 1;
    if size(f.tracking_info.signal_peak,1)<tracknum
        set(trackNum,'string',num2str(tracknum));
        setZeroDetection;
        return
    else
        nofEncs = length(nonzeros(f.tracking_info.signal_peak(tracknum,:)));
        set(TotEncs,'string',['/',num2str(nofEncs)]);
        set(encNum,'string',num2str(encnum))
        plot_enc = 1; % plot onset
    end
    if f.tracking_info.signal_sorted(tracknum,encnum)
        set(encNumBorder,'BackgroundColor','g')
    else
        set(encNumBorder,'BackgroundColor',defcolor)
    end
    if nofEncs~=0
        setErrorMsg;
        % refreshIntPanel;
        plotFlyTrack;
        plotSignal;
        plotPeaks;
        updateSignalPlot;
    else
        plotSignal;
        clearEventsPlot
        set(errorboard,'string','No Peaks Detected ');
    end

    % set the values in the edit boxes
    on_point = f.tracking_info.signal_onset(tracknum,encnum);
    peak_point = f.tracking_info.signal_peak(tracknum,encnum);
    off_point = f.tracking_info.signal_offset(tracknum,encnum);

    set(onNum,'string',num2str(on_point));
    set(offNum,'string',num2str(off_point));
    set(peakNum,'string',num2str(peak_point));
    
    if nofEncs~=0
        setOverlapMsg;

    else
        % set the values in the edit boxes
        on_point = these_frames(1);
        peak_point = these_frames(1);
        off_point = these_frames(1);
        plotFlyTracknoDet;

        set(onNum,'string',num2str(on_point));
        set(offNum,'string',num2str(off_point));
        set(peakNum,'string',num2str(peak_point));
    end
    
end

function [] = setZeroDetection(~,~)
    
    nofEncs = 0;
    set(TotEncs,'string',['/',num2str(nofEncs)]);
    encnum = 0;
    set(encNum,'string',num2str(encnum))
    plotSignal;
    clearEventsPlot;
    set(errorboard,'string','No Peaks Detected ');
    % set the values in the edit boxes
    on_point = these_frames(1);
    peak_point = these_frames(1);
    off_point = these_frames(1);
    plotFlyTracknoDet;

    set(onNum,'string',num2str(on_point));
    set(offNum,'string',num2str(off_point));
    set(peakNum,'string',num2str(peak_point));

end

function [] = NexttrackCall(~,~)
    vtnum = vtnum + 1;
    
    if vtnum>TotTracksnum
        vtnum = TotTracksnum;
        return
    end
    tracknum = validtracks(vtnum);
  
    track_start = find(f.tracking_info.fly_status(tracknum,:)==1,1,'first');
    track_end = find(f.tracking_info.fly_status(tracknum,:)==1,1,'last');
    these_frames = track_start:track_end;
    if size(f.tracking_info.signal_peak,1)<tracknum
        set(trackNum,'string',num2str(tracknum));
        setZeroDetection;
        return
    else
        nofEncs = length(nonzeros(f.tracking_info.signal_peak(tracknum,:)));
        set(TotEncs,'string',['/',num2str(nofEncs)]);
        encnum = 1;
        if nofEncs==0
            set(encNum,'string','0')
        else
            set(encNum,'string',num2str(encnum))
        end
        plot_enc = 1; % plot onset
    end
    if f.tracking_info.signal_sorted(tracknum,encnum)
        set(encNumBorder,'BackgroundColor','g')
    else
        set(encNumBorder,'BackgroundColor',defcolor)
    end
    if nofEncs~=0
        setErrorMsg;
        % refreshIntPanel;
        plotFlyTrack;
        plotSignal;
        plotPeaks;
        updateSignalPlot;
    else
        plotSignal;
        clearEventsPlot
        set(errorboard,'string','No Peaks Detected ');
    end
    
    % set the values in the edit boxes
    on_point = f.tracking_info.signal_onset(tracknum,encnum);
    peak_point = f.tracking_info.signal_peak(tracknum,encnum);
    off_point = f.tracking_info.signal_offset(tracknum,encnum);

    set(onNum,'string',num2str(on_point));
    set(offNum,'string',num2str(off_point));
    set(peakNum,'string',num2str(peak_point));
    
    set(trackNum,'string',num2str(tracknum));
    if nofEncs~=0
        setOverlapMsg;

    else
        % set the values in the edit boxes
        on_point = these_frames(1);
        peak_point = these_frames(1);
        off_point = these_frames(1);
        plotFlyTracknoDet;

        set(onNum,'string',num2str(on_point));
        set(offNum,'string',num2str(off_point));
        set(peakNum,'string',num2str(peak_point));
    end
    
end

function [] = PrevtrackCall(~,~)
    vtnum = vtnum - 1;
    if vtnum<1
        vtnum = 1;
        return
    end
    tracknum = validtracks(vtnum);
    track_start = find(f.tracking_info.fly_status(tracknum,:)==1,1,'first');
    track_end = find(f.tracking_info.fly_status(tracknum,:)==1,1,'last');
    these_frames = track_start:track_end;
    if size(f.tracking_info.signal_peak,1)<tracknum
        set(trackNum,'string',num2str(tracknum));
        setZeroDetection;
        return
    else
        nofEncs = length(nonzeros(f.tracking_info.signal_peak(tracknum,:)));
        set(TotEncs,'string',['/',num2str(nofEncs)]);
        encnum = 1;
        set(encNum,'string',num2str(encnum))
        plot_enc = 1; % plot onset
    end
    if f.tracking_info.signal_sorted(tracknum,encnum)
        set(encNumBorder,'BackgroundColor','g')
    else
        set(encNumBorder,'BackgroundColor',defcolor)
    end
    if nofEncs~=0
        setErrorMsg;
        % refreshIntPanel;
        plotFlyTrack;
        plotSignal;
        plotPeaks;
        updateSignalPlot;
    else
        plotSignal;
        clearEventsPlot
        set(errorboard,'string','No Peaks Detected ');
    end

    % set the values in the edit boxes
    on_point = f.tracking_info.signal_onset(tracknum,encnum);
    peak_point = f.tracking_info.signal_peak(tracknum,encnum);
    off_point = f.tracking_info.signal_offset(tracknum,encnum);

    set(onNum,'string',num2str(on_point));
    set(offNum,'string',num2str(off_point));
    set(peakNum,'string',num2str(peak_point));
    
    set(trackNum,'string',num2str(tracknum));
    if nofEncs~=0
        setOverlapMsg;

    else
        % set the values in the edit boxes
        on_point = these_frames(1);
        peak_point = these_frames(1);
        off_point = these_frames(1);
        plotFlyTracknoDet;

        set(onNum,'string',num2str(on_point));
        set(offNum,'string',num2str(off_point));
        set(peakNum,'string',num2str(peak_point));
    end
end


function [] = onset_rad_call(~,~)
    if get(onset_radio,'value')
        set(off_radio,'value',0)
        set(peak_radio,'value',0)
        plot_enc = 1;
        
        if nofEncs~=0
            plotFlyTrack;
        else
            % set the values in the edit boxes
            plotFlyTracknoDet;
        end
        plotSignal;
    else
       set(onset_radio,'value',1)
    end
end

function [] = offset_rad_call(~,~)
    if get(off_radio,'value')
        set(onset_radio,'value',0)
        set(peak_radio,'value',0)
        plot_enc = 3;
        if nofEncs~=0
            plotFlyTrack;
        else
            % set the values in the edit boxes
            plotFlyTracknoDet;
        end
        plotSignal;
    else
       set(off_radio,'value',1)
    end
end

function [] = peak_rad_call(~,~)
    if get(peak_radio,'value')
        set(onset_radio,'value',0)
        set(off_radio,'value',0)
        plot_enc = 2;
        if nofEncs~=0
            plotFlyTrack;
        else
            % set the values in the edit boxes
            plotFlyTracknoDet;
        end
        plotSignal;
    else
       set(peak_radio,'value',1)
    end
end

function [] = ParameterCall(~,~)
    smooth_length = str2double(get(smoothlen,'string'));
    f.plm_cont_par.smooth_length = smooth_length;% How much to smooth the signal before analyzing the peaks. (Previous value: 3)

    smooth_type = smthtypelist{get(smoothtype, 'Value')};
    f.plm_cont_par.smooth_type = smooth_type; % smoothing type
    
    if strcmp(smooth_type,'s-golay')
        set(sgolayorder,'visible','on');
        sgolayorderval = str2double(get(sgolayorder,'string'));
        f.plm_cont_par.sgolayorder = str2double(get(sgolayorder,'string')); % smoothing type
        set(sgolaytext,'visible','on');
    else
        set(sgolayorder,'visible','off');
        set(sgolaytext,'visible','off');
    end
    
    minpeakdist = str2double(get(minpeakdisted,'string'));
    f.plm_cont_par.minpeakdist = minpeakdist; % The minimum time that two neighboring detected peaks must have between them.
    
    minpeakprom = str2double(get(minpeakpromed,'string'));
    f.plm_cont_par.minpeakprom = minpeakprom; % The minimum intensity that the peak prominence must have.

    maxpeakwidth = str2double(get(maxpeakwidthed,'string'));
    f.plm_cont_par.maxpeakwidth = maxpeakwidth; % The maximum length that a signal increase can have in seconds.

    minpeakheight = str2double(get(minpeakheighted,'string'));
    f.plm_cont_par.minpeakheight = minpeakheight;% % The mimimum intensity that the peak height can have.

    min_track_length = str2double(get(mintracklength,'string'));
    f.plm_cont_par.min_track_length = min_track_length; % 1 second, if tracks length is shorter ignore it
    
    if isempty(who('sgolayorderval'))
        save('PeakDetectParameters.mat','min_track_length','minpeakheight','maxpeakwidth','minpeakprom','minpeakdist','smooth_type','smooth_length');
    else
        
        save('PeakDetectParameters.mat','min_track_length','minpeakheight','maxpeakwidth','minpeakprom','minpeakdist','smooth_type','smooth_length','sgolayorderval');
    end
end

function [] = setOverlapMsg(~,~)
    % clear the board first
    set(overlapboard,'string',' ');
    switch plot_enc
        case 1 % onset
            if on_point==0
                return
            end
            set(overlapboard,'string',['Antenna Overlap:',num2str(f.tracking_info.antenna_overlap(tracknum,on_point),'%5.2f')]);
        case 2 % peak
            if peak_point==0
                return
            end
            set(overlapboard,'string',['Antenna Overlap:',num2str(f.tracking_info.antenna_overlap(tracknum,peak_point),'%5.2f')]);
        case 3 % offset
            if off_point==0
                return
            end
            set(overlapboard,'string',['Antenna Overlap:',num2str(f.tracking_info.antenna_overlap(tracknum,off_point),'%5.2f')]);
    end
end



function [] = setErrorMsg(~,~)
    error_msg = '';
    % clear the board first
    set(errorboard,'string',' ');
    if any(f.tracking_info.error_code(tracknum,f.tracking_info.signal_onset(tracknum,encnum):f.tracking_info.signal_offset(tracknum,encnum))>0)
        errcode = nonzeros(unique(f.tracking_info.error_code(tracknum,f.tracking_info.signal_onset(tracknum,encnum):f.tracking_info.signal_offset(tracknum,encnum))));
        for ecin = 1:length(errcode)
            error_msg = [error_msg,' Fly:',num2str(tracknum),':',f.error_def{errcode(ecin)}];
        end
    end
    if ~strcmp(error_msg,'')
        set(errorboard,'string',error_msg);
    end
end

function [] = findPeaksCall(~,~)
    
%     % find peaks
%     f = FindPlumeContacts(f);
%     f.tracking_info.signal_sorted = zeros(size(f.tracking_info.signal_peak));
%     getValidTracks;
%     vtnum = 1;
%     tracknum = validtracks(vtnum);
%     set(trackNum,'String',num2str(tracknum));
%     encnum = 1;
%     nofEncs = length(nonzeros(f.tracking_info.signal_peak(tracknum,:)));
%     set(TotEncs,'String',['/',num2str(nofEncs)]);
%     set(encNum,'string',num2str(encnum));
%     plot_enc = 1; % plot onset
%     setErrorMsg;
% 
% 
%     % set the values in the edit boxes
%     on_point = f.tracking_info.signal_onset(tracknum,encnum);
%     peak_point = f.tracking_info.signal_peak(tracknum,encnum);
%     off_point = f.tracking_info.signal_offset(tracknum,encnum);
% 
%     set(onNum,'string',num2str(on_point));
%     set(offNum,'string',num2str(off_point));
%     set(peakNum,'string',num2str(peak_point));
%     
%     plotFlyTrack;
%     plotSignal;
%     plotPeaks;
%     updateSignalPlot;

end


function [] = getTrackEncNum(~,~)
    % find the track number and ecounter number that sorting is interrupted
    found = 0;
    vtnum = 1;
    TotTracksnum = length(validtracks);
    while (~found)&&(vtnum<=length(TotTracksnum ))
        nofpeaks = length(nonzeros(f.tracking_info.signal_peak(validtracks(vtnum),:)));
        if any(f.tracking_info.signal_sorted(validtracks(vtnum),1:nofpeaks)==0)
            found = 1;
            encnum = find(f.tracking_info.signal_sorted(validtracks(vtnum),:)==0,1);
            tracknum = validtracks(vtnum);
        else
            vtnum = vtnum + 1;
        end
    end
    if found==0
        if nofpeaks==0
            encnum = 1;
            tracknum = validtracks(1);
        else
            encnum = nofpeaks;
            tracknum = validtracks(end);
        end
    end
        
end


function [] = Addedit(~,~)
    if ~any(strcmp({get(onAdd,'string'),get(peakAdd,'string'),get(offAdd,'string')},'NaN'))
        set(AddButton,'enable','on');
    else
        set(AddButton,'enable','off');
    end
end


function [] = SmoothSignal(~,~)
    if strcmp(f.plm_cont_par.smooth_type,'box smooth')
        smth_signal = f.tracking_info.signalm(tracknum,these_frames);
        smth_signal(these_frames) = smooth(f.tracking_info.signalm(tracknum,these_frames),f.plm_cont_par.smooth_length);
    elseif strcmp(f.plm_cont_par.smooth_type,'s-golay')
        smth_signal = f.tracking_info.signalm(tracknum,these_frames);
        smth_signal(these_frames) = smooth(f.tracking_info.signalm(tracknum,these_frames),f.plm_cont_par.smooth_length,'sgolay',f.plm_cont_par.sgolayorder);
    end
end


function [] = playlen_call(~,~)
%     track_play_length = str2double(get(playlen_edit,'string'));
%     play_buffer = round(track_play_length*f.ExpParam.fps);
end




function [] = done_call(~,~)
            
    if get(save_radio,'value')
        f.save;
    end
    QuitsortFlyWalkCallback
    
end




function [] = BNF_call(~,~)
    
%     if strcmp(get(stopBNFButton,'String'),'stop BNF') % 
%         playBNF = false;
%         set(stopBNFButton,'String','start BNF') % change status 
%     else
%         playBNF = true;
%         set(stopBNFButton,'String','stop BNF') % starts acquiring
%         playBackNForth;
%     end
end
        
        
function [] = FlyBoxCall(~,~)
    flysize = str2double(get(FlyBoxSize,'string'))/f.ExpParam.mm_per_px;
    plotFlyTrack;
end        

function [] = plotFlyTracknoDet(~,~)
    f.previous_frame = f.current_frame;
        % fly positions
    if plot_enc==1
        f.previous_frame = f.current_frame;
        f.current_frame = on_point;
    elseif plot_enc==2 
        f.current_frame = peak_point;
    elseif plot_enc==3      
        f.current_frame = off_point;
    end
    flyposx = (f.tracking_info.x(tracknum,f.current_frame));
    flyposy = (f.tracking_info.y(tracknum,f.current_frame));
    
    track_xlim = [flyposx-flysize,flyposx+flysize];
    track_ylim = [flyposy-flysize,flyposy+flysize];
    f.operateOnFrame;
    
    % activate the figure 
    set(f.plot_handles.ax,'xlim',track_xlim,'ylim',track_ylim)
    
end

function [] = plotFlyTrack(~,~)
    if f.tracking_info.signal_onset(tracknum,encnum)==0
        return
    end
   
    % fly positions
    if plot_enc==1
        f.previous_frame = f.current_frame;
        f.current_frame = f.tracking_info.signal_onset(tracknum,encnum);
        flyposx = (f.tracking_info.x(tracknum,f.tracking_info.signal_onset(tracknum,encnum)));
        flyposy = (f.tracking_info.y(tracknum,f.tracking_info.signal_onset(tracknum,encnum)));
    elseif plot_enc==2
        f.previous_frame = f.current_frame;         
        f.current_frame = f.tracking_info.signal_peak(tracknum,encnum);
        flyposx = (f.tracking_info.x(tracknum,f.tracking_info.signal_peak(tracknum,encnum)));
        flyposy = (f.tracking_info.y(tracknum,f.tracking_info.signal_peak(tracknum,encnum)));
    elseif plot_enc==3
        f.previous_frame = f.current_frame;         
        f.current_frame = f.tracking_info.signal_offset(tracknum,encnum);
        flyposx = (f.tracking_info.x(tracknum,f.tracking_info.signal_offset(tracknum,encnum)));
        flyposy = (f.tracking_info.y(tracknum,f.tracking_info.signal_offset(tracknum,encnum)));
    end
    
    track_xlim = [flyposx-flysize,flyposx+flysize];
    track_ylim = [flyposy-flysize,flyposy+flysize];
    f.operateOnFrame;
    
    if ~any(isnan([track_xlim,track_ylim]))
        % activate the figure 
        set(f.plot_handles.ax,'xlim',track_xlim,'ylim',track_ylim)
    end
end

function []=playBackNForth(~,~)
    
% % reset markers
% for nn = 1:10
%     f.plot_handles.track_marker(nn).XData = NaN;
%     f.plot_handles.track_marker(nn).YData = NaN;
% end
%     
% play_lim = 1;
% play_num = 1;
% 
% track_play_init = these_frames(1)-play_buffer;
% if track_play_init<1
%     track_play_init = 1;
% end
% track_play_end = these_frames(end)+play_buffer;
% if track_play_end>f.nframes
%     track_play_end = f.nframes;
% end
% 
%     while (play_num <= play_lim)&&playBNF
%         for i = track_play_init:(track_play_end-1)
%             if playBNF
%                 f.current_frame = i;
%                 f.operateOnFrame;
%                 for tnum = 1:length(these_flies)
%                     f.plot_handles.track_marker(tnum).XData = tracking_info.x(these_flies(tnum),i+1);
%                     f.plot_handles.track_marker(tnum).YData = tracking_info.y(these_flies(tnum),i+1);
%                 end
%             end
%         end
% 
%         for i = (track_play_end-1):-1:track_play_init
%             if playBNF
%                 f.current_frame = i;
%                 f.operateOnFrame;
%                 for tnum = 1:length(these_flies)
%                     f.plot_handles.track_marker(tnum).XData = tracking_info.x(these_flies(tnum),i+1);
%                     f.plot_handles.track_marker(tnum).YData = tracking_info.y(these_flies(tnum),i+1);
%                 end
%             end
%         end
%         play_num= play_num + 1;
%     end
%     playBNF = 0;
%     if isvalid(stopBNFButton)
%         set(stopBNFButton,'String','start BNF') % change status
%     end

end


function [] = ZoomCall(~,~)
    getPlotLimits;
    updateSignalPlot;
end



function [] = getPlotLimits(~,~)
    if ~get(zoom_radio,'Value')
        plot_xlimit = [these_frames(1) these_frames(end)];
        plot_ylimit = [min(smth_signal(these_frames))*.9 max(smth_signal(these_frames))*1.1];
    else
        if (encnum==0)&&(nofEncs==0) % no peak detected
                plot_xlimit = [these_frames(1) these_frames(end)];
                plot_ylimit = [min(smth_signal(these_frames))*.9 max(smth_signal(these_frames))*1.1];
        else
            if plot_enc==1
                xcenter = f.tracking_info.signal_onset(tracknum,encnum);
            elseif plot_enc==2
                xcenter = f.tracking_info.signal_peak(tracknum,encnum);
            elseif plot_enc==3
                xcenter = f.tracking_info.signal_offset(tracknum,encnum);
            end


    %         zoomwidnum = str2double(get(zoomNum,'string'))*f.tracking_info.signal_width(tracknum,encnum);
    %         zoomwidnum = round(zoomwidnum);
            zoomwidnum = str2double(get(zoomNum,'string'))*(f.tracking_info.signal_offset(tracknum,encnum)-f.tracking_info.signal_onset(tracknum,encnum));
            plot_xlimit = [xcenter-zoomwidnum xcenter+zoomwidnum];
            if plot_xlimit(1)<1
                framest = 1;
            else
                framest = plot_xlimit(1);
            end
            if plot_xlimit(end)>length(smth_signal)
                framen = length(smth_signal);
            else
                framen = plot_xlimit(end);
            end
            plot_ylimit = [min(smth_signal(framest:framen))*.9 max(smth_signal(framest:framen))*1.1];
            if xcenter==0
                plot_xlimit = [these_frames(1) these_frames(end)];
                plot_ylimit = [min(smth_signal(these_frames))*.9 max(smth_signal(these_frames))*1.1];
            end
        end
    end
    if plot_ylimit(2)<f.tracking_info.signal_threshold
        plot_ylimit(2) = f.tracking_info.signal_threshold*1.5;
    end
end

function [] = plotSignal(~,~)
    
    %smoothsignal
    SmoothSignal;
    
    % reset plots
    signalplot.YData = NaN; signalplot.XData = NaN;


    getPlotLimits; % get limits of signal plot

    % update plots
    signalplot.XData = these_frames;
    signalplot.YData = smth_signal(these_frames);
    threshold_plot.XData = [these_frames(1) these_frames(end)];
    threshold_plot.YData = ones(2,1)*f.tracking_info.signal_threshold;
 
end

function [] = plotPeaks(~,~)
    
%     onsetplot.YData = NaN; onsetplot.XData = NaN;
%     offsetplot.YData = NaN; offsetplot.YData = NaN;
%     peakplot.YData = NaN; peakplot.XData = NaN;
    onsetplot_all.YData = NaN; onsetplot_all.XData = NaN;
    offsetplot_all.YData = NaN; offsetplot_all.YData = NaN;
    peakplot_all.YData = NaN; peakplot_all.XData = NaN;
    
    onsetplot_all.XData = f.tracking_info.signal_onset(tracknum,1:nofEncs);
    onsetplot_all.YData = smth_signal(onsetplot_all.XData);    
    offsetplot_all.XData = f.tracking_info.signal_offset(tracknum,1:nofEncs);
    offsetplot_all.YData = smth_signal(offsetplot_all.XData);
    peakplot_all.XData = f.tracking_info.signal_peak(tracknum,1:nofEncs);
    peakplot_all.YData = smth_signal(peakplot_all.XData);
    on_point = f.tracking_info.signal_onset(tracknum,encnum);
    peak_point = f.tracking_info.signal_peak(tracknum,encnum);
    off_point = f.tracking_info.signal_offset(tracknum,encnum);
    getPlotLimits; % get limits of signal plot

end

function [] = clearEventsPlot(~,~)
    getPlotLimits; % get limits of signal plot
    onsetplot.XData = NaN;
    onsetplot.YData = NaN;
    offsetplot.XData = NaN;
    offsetplot.YData = NaN;
    peakplot.XData = NaN;
    peakplot.YData = NaN;
    onsetplot_all.XData = NaN;
    onsetplot_all.YData = NaN;
    offsetplot_all.XData = NaN;
    offsetplot_all.YData = NaN;
    peakplot_all.XData = NaN;
    peakplot_all.YData = NaN;
    if plot_xlimit(1)==plot_xlimit(2)
        plot_xlimit(1) = plot_xlimit(1)-1;
        plot_xlimit(2) = plot_xlimit(2)+1;
    end        
    if isnan(plot_ylimit(1))&&isnan(plot_ylimit(2))
        plot_ylimit = [0 1];
    end
    if (plot_ylimit(1)==0)&&(plot_ylimit(2)==0)
        plot_ylimit = [0 1];
    end
    if any(isnan([on_point plot_ylimit(1) off_point-on_point plot_ylimit(2)-plot_ylimit(1)]))
        rec1.Position = zeros(1,4);
    else
        rec1.Position = [0 plot_ylimit(1) 0 plot_ylimit(2)-plot_ylimit(1)];
    end
    set(ax1,'Ylim',plot_ylimit,'Xlim',plot_xlimit)
    if peak_point==0
        set(refl_radio,'Value',f.reflection_status(tracknum,these_frames(1)));
    else
        set(refl_radio,'Value',f.reflection_status(tracknum,peak_point));
    end
end


function [] = updateSignalPlot(~,~)
    
    getPlotLimits; % get limits of signal plot

    onsetplot.XData = on_point;
    onsetplot.YData = smth_signal(on_point);
    offsetplot.XData = off_point;
    offsetplot.YData = smth_signal(off_point);
    peakplot.XData = peak_point;
    peakplot.YData = smth_signal(peak_point);

    rec1.Position = [on_point plot_ylimit(1) off_point-on_point plot_ylimit(2)-plot_ylimit(1)];
    set(ax1,'Ylim',plot_ylimit,'Xlim',plot_xlimit)
    set(refl_radio,'Value',f.reflection_status(tracknum,peak_point));
end
        


function [] = QuitsortFlyWalkCallback(~,~)
%    selection = questdlg('Are you sure you want to quit sortFlyWalk?','Confirm quit.','Yes','No','Yes'); 
   selection = 'Yes'; 
   switch selection 
      case 'Yes'
%           playBNF = 0;
%           pause(.1)
%           set(stopBNFButton,'String','start BNF') % change status 
           
            % reset axis
            set(f.plot_handles.ax,'xlim',xlimo,'ylim',ylimo)
            f.ui_handles.fig.Position = figpossave;

            % reset visualization
            f.label_flies = oa(1);         % show fly labels next to each fly
            f.mark_flies = oa(2);       % show fly markers
            f.show_orientations = oa(3);      % show orientations, 0: do not show, 1: orientations, 2: heading, 3: both
            f.show_trajectories = oa(4);      % show tracks with a tail length of trajectory_vis_length 
            f.show_antenna = oa(5);
            f.mark_lost = oa(6);

            delete(fSFW);

      case 'No'
      return 
   end
end


end





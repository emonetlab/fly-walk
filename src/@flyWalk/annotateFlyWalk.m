%% sorts fly walk events such as plume contacts
function f = annotateFlyWalk(f)

%% is the GUI on
if isempty(f.plot_handles.ax)
    % then create it;
    f.createGUI;
end

% shared variables
selected_frames = [];
current_frame = [];
tracknum = [];
TotTracksnum = [];
plot_xlimit = [];
plot_ylimit = [];
max_y_limit = 30;   % signal y limit max
min_y_limit = 0;   % signal y limit max
DataMat = [];   % matrix of data for plotting
plotData = [];  % vector to plot
warnedForYLim = 0;
current_mobile_status = [];
current_groom_status = [];

%% the following section if for encounter detection
% set defaults
defFields = {   'smooth_length',    1;   ...  % (points), How much to smooth the signal before analyzing the peaks. (Previous value: 3)
    'minPeakDist',      0;   ...    % The minimum time that two neighboring detected peaks must have between them.
    'minPeakWidth',     .02; ...   % (sec),  minimum encounter duration .02 seconds
    'minPeakProm',      .5;  ...    % The minimum intensity that the peak prominence must have.
    'maxPeakWidth',     60;  ...   % (sec), The maximum length that a signal increase can have in seconds.
    'maxPeakHeight',    100; ...  % maximum value a peak can have
    'minPeakTrackLength', 1 }; % 1 second, if tracks length is shorter ignore it

% check if the paramters are already set
if isempty(f.plm_cont_par) % no parameter is set
    givenFields = [];
    
else % there are some parameters supplied
    % replace them with the defaults
    givenFields = fieldnames(f.plm_cont_par);
end
for indFld = 1:numel(defFields(:,1))
    if ~any(strcmp(defFields(indFld,1),givenFields))
        f.plm_cont_par.(defFields{indFld,1}) = defFields{indFld,2};
    end
end

% put the min signal length to tracking info as well. in future
% versions eliminate this
f.tracking_info.minSignalLen = f.plm_cont_par.minPeakWidth;

% extraFields = setdiff(givenFields,defFields(:,1));
% if ~isempty(extraFields)
%     disp('WARNING: these fields are provided extra in f.plm_cont_par and')
%     disp([' will not be used during encounter detection: ', strjoin(extraFields',', ')])
% end
%%


flysize = round(8/f.ExpParam.mm_per_px); %make manual
TotTracksnum = find(f.tracking_info.fly_status(:,end)~=0,1,'last');

% check if msd is calculated and saved
checkTheseMsdVars = {'msdMov','msdSum','totDisp','msdMean'...
    'msdMat','msdSlope','msdLenVal','msdWindLenVal','msdoffsetVal'};

if ~isempty(setdiff(checkTheseMsdVars,fieldnames(f.tracking_info)))
    isMsdCalculated = 0;    % msd is not calculated
    mm = []; % moving msd
    ms = [];  % msd sum
    ad = [];   % actual displacement
    mnm = [];   % mean msd over all time steps
    msdMat = [];    % msd vs time at t
    msdSlope = [];  % slope of log log msd vs time plot
    msdoffsetVal = 'center';
    msdLenVal = 0.5;        % msd calculation length , sec
    msdWindLenVal = .5;     % msd calculation window , sec
else
    isMsdCalculated = 1;    % msd is not calculated
    mm = f.tracking_info.msdMov; % moving msd
    ms = f.tracking_info.msdSum;  % msd sum
    ad = f.tracking_info.totDisp;   % actual displacement
    mnm = f.tracking_info.msdMean;  % mean of msd over all time steps
    msdMat = f.tracking_info.msdMat;    % msd vs time at t
    msdSlope = f.tracking_info.msdSlope;  % slope of log log msd vs time plot
    msdLenVal = f.tracking_info.msdLenVal;        % msd calculation length , sec
    msdWindLenVal = f.tracking_info.msdWindLenVal;     % msd calculation window , sec
    msdoffsetVal = f.tracking_info.msdoffsetVal;
end


% do not run tracking during manual sort
f.label_flies = true;         % show fly labels next to each fly
f.mark_flies = false;       % show fly markers
f.show_orientations = false;      % show orientations, 0: do not show, 1: orientations, 2: heading, 3: both
f.show_trajectories = false;      % show tracks with a tail length of trajectory_vis_length
f.show_antenna = true;          % shows the virtual antenna, where signal is integrated for each fly in each frame, 1: only antenna, 2: mask in a separate window
f.mark_lost = false;
f.track_movie=0;
f.antenna_type = 'fixed';
f = getMaskedSignal(f);
f = ApplyGroomMask2Signal(f);

% was this file annotated before
if isempty(f.annotation_info) % file is not annotated
    % create annotation info
    f.annotation_info.mobile_status = zeros(TotTracksnum,f.nframes,'uint8'); %0: stop, 1: walk, 2: back up, 3: jump
    f.annotation_info.groom_status = zeros(TotTracksnum,f.nframes,'uint8'); %0: NA, 1: wing, 2: hid leg, 3: foreleg
    f.annotation_info.signal_clean = zeros(TotTracksnum,f.nframes,'uint8'); %0: false, not clean, 1: true signal - clean
    f.annotation_info.orientation = zeros(TotTracksnum,f.nframes); % 0-360 degrees
    f.annotation_info.orientation_flipped = zeros(TotTracksnum,f.nframes,'uint8'); %0: false, 1: true orientation is flipped to correct
    f.annotation_info.collision = zeros(TotTracksnum,f.nframes,'uint8'); %0: no collision, 1: collision with another fly
    f.annotation_info.overpassing = zeros(TotTracksnum,f.nframes,'uint8'); %0: no overpass, 1: passing over another fly
    f.annotation_info.antenna_overlap = zeros(TotTracksnum,f.nframes,'uint8'); %0: no overlap, 1: overlaps (w/ another fly, reflection, itself etc)
    f.annotation_info.annotation_status = zeros(TotTracksnum,f.nframes,'uint8'); %0: not annotated 1: annotated
    f.annotation_info.active_frames = zeros(TotTracksnum,2); %1: first frame, 2: last frame
    f.annotation_info.reflection = zeros(TotTracksnum,f.nframes,'uint8'); %0: no reflection, 1: reflection present
    f.annotation_info.signal = zeros(TotTracksnum,f.nframes);
    
    
    guessAnnotation;
    
    % start from the fist track and first frame
    tracknum = 1;
    current_frame = f.annotation_info.active_frames(tracknum,1);
    
else
    % the file was annotated before. Figure out where it was left
    current_frame = 1;
    tracknum = 1;
    found_annot = false;
    while (~found_annot)&&(tracknum<=TotTracksnum)
        if find(f.annotation_info.annotation_status(tracknum,:)==1,1,'last')==f.annotation_info.active_frames(tracknum,2)
            tracknum = tracknum + 1;
        else
            current_frame = find(f.annotation_info.annotation_status(tracknum,:)==1,1,'last')+1;
            found_annot = true;
            if isempty(current_frame)
                current_frame = f.annotation_info.active_frames(tracknum,1);
            end
        end
    end
    if tracknum == TotTracksnum + 1
        tracknum = 1;
    end
    if current_frame<f.annotation_info.active_frames(tracknum,1)
        current_frame = f.annotation_info.active_frames(tracknum,1);
    end
    if current_frame>f.annotation_info.active_frames(tracknum,2)
        current_frame = f.annotation_info.active_frames(tracknum,2);
    end
    
    
end



% % return if there is no peak detected
% if size(f.tracking_info.signal_peak,2)<=1
%     return
% end



% some variables
these_frames = [];
signalplot = [];
showframe =  [];
playBNF = 0;

% get image x and y limts
xlimo = f.plot_handles.ax.XLim;
ylimo = f.plot_handles.ax.YLim;

% disable some annotation
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

fSFW = figure('units','normalized','Position',[0.389 0.21 0.6000 0.71],'NumberTitle','off','Visible','on','Name',flnm,'Menubar', 'none',...
    'Toolbar','figure','resize', 'on' ,'CloseRequestFcn',@QuitsortFlyWalkCallback);

%% select from graph
SelectGraphButton = uicontrol('parent',fSFW,'fontunits', 'normalized','FontSize',.4,'units','normalized',...
    'Position',[.58 .86 0.15 0.05],'Style','pushbutton','Enable','on','String','Select From Graph','Callback',@selectGraphFrameRange);

%% select all frames
uicontrol('parent',fSFW,'fontunits', 'normalized','FontSize',.4,'units','normalized',...
    'Position',[.43 .86 0.13 0.05],'Style','pushbutton','Enable','on','String','Select All Frames','Callback',@selectAllFramesRange);

%% y limit
uicontrol('parent',fSFW,'fontunits', 'normalized','FontSize',.5,'units','normalized','Style','text',...
    'position',[.043 .9 0.03 0.03],'String','Max','Fontweight','bold');
uicontrol('parent',fSFW,'fontunits', 'normalized','FontSize',.5,'units','normalized','Style','text',...
    'position',[.01 .9 0.03 0.03],'String','Min','Fontweight','bold');
uicontrol('parent',fSFW,'fontunits', 'normalized','FontSize',.5,'units','normalized','Style','text',...
    'position',[.053 .863 0.07 0.04],'String','Ylim','Fontweight','bold');
ylimMax = uicontrol('parent',fSFW,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[0.043 .87 0.03 0.04],'Style','edit','String',num2str(max_y_limit),'ForegroundColor','k','Callback',@ylimMaxCall);
ylimMin = uicontrol('parent',fSFW,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[0.01 .87 0.03 0.04],'Style','edit','String',num2str(min_y_limit),'ForegroundColor','k','Callback',@ylimMinCall);


%% plot input selection
uicontrol('parent',fSFW,'fontunits', 'normalized','FontSize',.5,'units','normalized','Style','text',...
    'position',[.2 .855 0.07 0.04],'String','Plot:','Fontweight','bold');
plotSelectionList = {'Speed','X','Y','Orientation','Rot. Speed','Area','Signal','Masked-Signal','Heading','msd-mov','msd-slope','msd-sum','msd-mean','abs-disp'};
pselval = 1;
plotSelection = uicontrol('parent',fSFW,'fontunits', 'normalized','FontSize',.45,'units','normalized','Style', 'popup',...
    'String',plotSelectionList,'Position', [.253 .86 0.1 0.04],'Value',pselval,'Callback',@plotSelectCall);

%% error panel
errorpanel=uipanel('parent', fSFW,'fontunits', 'normalized','FontSize',.1,'units','normalized','pos',[.63 .27 .36 .19]);
errorboard = uicontrol('parent',errorpanel,'fontunits', 'normalized','FontSize',.15,'units','normalized','Style','text',...
    'position',[.03 .03 .9 .8],'String','','Max',2,'HorizontalAlignment', 'left','ForegroundColor','r');
overlapboard = uicontrol('parent',errorpanel,'fontunits', 'normalized','FontSize',.8,'units','normalized','Style','text',...
    'position',[.03 .85 .9 .15],'String','','HorizontalAlignment', 'left','ForegroundColor','k','Fontweight','bold');


%% misc panel
miscpanel=uipanel('parent', fSFW,'fontunits', 'normalized','FontSize',.1,'units','normalized','pos',[.63 .03 .36 .22]);
uicontrol('parent',miscpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
    'position',[0.01 .88 .1 .1],'Value',0,'visible','on','string','msdLen:','Fontweight','bold');
msdLen = uicontrol('parent',miscpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[.12 .87 .11 .12],'Style','edit','String',num2str(msdLenVal),'ForegroundColor','k','Callback',@EstimateMsdCall);
% uicontrol('parent',miscpanel,'fontunits', 'normalized','FontSize',.8,'units','normalized','Style','text',...
%     'position',[.25 .88 .09 .1],'String','(sec)');

uicontrol('parent',miscpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
    'position',[.29 .88 .16 .1],'Value',0,'visible','on','string','msdWindLen:','Fontweight','bold');
msdWindLen = uicontrol('parent',miscpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[.46 .87 .11 .12],'Style','edit','String',num2str(msdWindLenVal),'ForegroundColor','k','Callback',@EstimateMsdCall);
uicontrol('parent',miscpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
    'position',[.57 .88 .08 .1],'String','(sec)');

msdOffSetList = {'start','center','end'};
msdOffset = uicontrol('parent',miscpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[.85 .89 .13 .1],'Style','popup','String',msdOffSetList,'Value',find(strcmp(msdOffSetList,msdoffsetVal)),'Callback',@EstimateMsdCall);
uicontrol('parent',miscpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
    'position',[.7 .87 .15 .1],'Value',0,'visible','on','string','msd-OffSet:','Fontweight','bold');

% insert peak detection parameters in to the misc panel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
uicontrol('parent',miscpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
    'position',[0.01 .45 .22 .1],'String','minPeakWidth (s):','Fontweight','bold');
minPeakWidthed = uicontrol('parent',miscpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[.27 .455 .1 .11],'Style','edit','String',num2str(f.plm_cont_par.minPeakWidth),'ForegroundColor','k','Callback',@ParameterCall);

uicontrol('parent',miscpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
    'position',[0.42 .45 .23 .1],'String','maxPeakWidth (s):','Fontweight','bold');
maxPeakWidthed = uicontrol('parent',miscpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[.68 .455 .1 .11],'Style','edit','String',num2str(f.plm_cont_par.maxPeakWidth),'ForegroundColor','k','Callback',@ParameterCall);

uicontrol('parent',miscpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
    'position',[0.01 .3 .24 .1],'String','minPeakProm (a.u):','Fontweight','bold');
minPeakPromed = uicontrol('parent',miscpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[.27 .305 .1 .11],'Style','edit','String',num2str(f.plm_cont_par.minPeakProm),'ForegroundColor','k','Callback',@ParameterCall);

uicontrol('parent',miscpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
    'position',[0.42 .30 .2 .1],'String','minPeakDist (s):','Fontweight','bold');
minPeakDisted = uicontrol('parent',miscpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[.68 .305 .1 .11],'Style','edit','String',num2str(f.plm_cont_par.minPeakDist),'ForegroundColor','k','Callback',@ParameterCall);

uicontrol('parent',miscpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
    'position',[0.01 .15 .26 .1],'String','minPeakHeight (a.u):','Fontweight','bold');
minPeakHeighted = uicontrol('parent',miscpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[.27 .155 .1 .11],'Style','edit','String','nan','ForegroundColor','k','Callback',@ParameterCall,'Enable','off');

uicontrol('parent',miscpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
    'position',[0.42 .15 .26 .1],'String','maxPeakHeight (a.u):','Fontweight','bold');
maxPeakHeighted = uicontrol('parent',miscpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[.68 .155 .1 .11],'Style','edit','String',num2str(f.plm_cont_par.maxPeakHeight),'ForegroundColor','k','Callback',@ParameterCall);

uicontrol('parent',miscpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
    'position',[0.01 0 .26 .1],'String','smoothLength (pnts):','Fontweight','bold');
smoothlen = uicontrol('parent',miscpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[.27 .008 .1 .11],'Style','edit','String',num2str(f.plm_cont_par.smooth_length),'ForegroundColor','k','Callback',@ParameterCall);

uicontrol('parent',miscpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
    'position',[0.42 0 .23 .1],'String','minTrackLen (s):','Fontweight','bold');
mintracklength = uicontrol('parent',miscpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[.68 .008 .1 .11],'Style','edit','String',num2str(f.plm_cont_par.minPeakTrackLength),'ForegroundColor','k','Callback',@ParameterCall);

uicontrol('parent',miscpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
    'position',[0.79 .45 .2 .1],'String','Sig. Thr. Fact.:','Fontweight','bold');
sigThreshFactEd = uicontrol('parent',miscpanel,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[.85 .35 .1 .11],'Style','edit','String','3','ForegroundColor','k','Callback',@ParameterCall);

findButton = uicontrol('parent',miscpanel,'fontunits', 'normalized','FontSize',.45,'units','normalized',...
    'Position',[.8 .08 .19 .18],'Style','pushbutton','Enable','on','String','Find Peaks','Callback',@getEncountersCall);



%% Track Panel
trackPanel = uipanel('parent', fSFW,'fontunits', 'normalized','FontSize',.1,'units','normalized','pos',[.75 .47 .23 0.4]);

% TRACK NAVIGATION
yoffset = .85;
xoffset = .03;
wd = .15;
hg = .12;
trackNum = uicontrol('parent',trackPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[xoffset yoffset wd hg],'Style','edit','String',num2str(tracknum),'ForegroundColor','k','Callback',@trackNumCall);

uicontrol('parent',trackPanel,'fontunits', 'normalized','FontSize',.9,'units','normalized','Style','text',...
    'position',[xoffset+wd+.005 yoffset+.01 2*wd hg],'String',['/',num2str(TotTracksnum)],'Fontweight','bold');
uicontrol('parent',trackPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[xoffset+3*wd+.05 yoffset 1.5*wd 1.1*hg],'Style','pushbutton','Enable','on','String','< Prev','Callback',@PrevtrackCall);
uicontrol('parent',trackPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[xoffset+5*wd-.01 yoffset 1.5*wd 1.1*hg],'Style','pushbutton','Enable','on','String','Next >','Callback',@NexttrackCall);

% showall_radio = uicontrol('parent',trackPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','rad',...
%     'position',[xoffset .15 .4 .1],'Value',1,'visible','on','string','show all','Callback',@ZoomCall);

shadeEnc_radio = uicontrol('parent',trackPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','rad',...
    'position',[xoffset .33 .5 .1],'Value',0,'visible','on','string','shade enc.','Callback',@shadeEncCall);

olayMask_radio = uicontrol('parent',trackPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','rad',...
    'position',[xoffset+.45 .33 .5 .1],'Value',0,'visible','on','string','overlay Mask.','Callback',@olayMaskCall);



uicontrol('parent',trackPanel,'fontunits', 'normalized','FontSize',.45,'units','normalized','Style','text',...
    'position',[xoffset-.03 .2 .25 .1],'Value',0,'visible','on','string','Antenna');
AntennaType = uicontrol('parent',trackPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[xoffset+.23 .225 .3 .09],'Style','popup','String',{'fixed','dynamic'},'Value',1,'Callback',@AntennaTypeCall);


uicontrol('parent',trackPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized','Style','text',...
    'position',[xoffset-.09 .11 .4 .08],'Value',0,'visible','on','string','Fly-Box-Size');
FlyBoxSize = uicontrol('parent',trackPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[xoffset+.25 .12 .2 .1],'Style','edit','String','8','ForegroundColor','k','Callback',@FlyBoxCall);
uicontrol('parent',trackPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
    'position',[xoffset+.45 .11 .2 .1],'String','(mm)');

zoom_radio = uicontrol('parent',trackPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','rad',...
    'position',[xoffset .02 .4 .1],'Value',0,'visible','on','string','zoom','Callback',@ZoomCall);
uicontrol('parent',trackPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
    'position',[xoffset+.38 .005 .4 .1],'String','frames');
zoomNum = uicontrol('parent',trackPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[xoffset+.25 .02 .2 .09],'Style','edit','String','10','ForegroundColor','k','Callback',@ZoomCall);

%% Edit Panel
editPanel = uipanel('parent', fSFW,'fontunits', 'normalized','FontSize',.1,'units','normalized','pos',[.03 .039 .59 .38]);
% mobile state
uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
    'position',[0 .89 .18 .1],'String','Mobile State','fontweight','bold');
mobile_radio(1) = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','rad',...
    'position',[.03 .8 .2 .1],'Value',1,'Callback', @mobileRadio,'visible','on','string','stop');
mobile_radio(2) = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','rad',...
    'position',[.03 .7 .2 .1],'Value',0,'Callback', @mobileRadio,'visible','on','string','walk');
mobile_radio(3) = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','rad',...
    'position',[.03 .6 .2 .1],'Value',0,'Callback', @mobileRadio,'visible','on','string','back up');
mobile_radio(4) = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','rad',...
    'position',[.03 .5 .2 .1],'Value',0,'Callback', @mobileRadio,'visible','on','string','jump');
mobile_radio(5) = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','rad',...
    'position',[.03 .4 .2 .1],'Value',0,'Callback', @mobileRadio,'visible','on','string','righting');

% groom state
xoffset = .21;
uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
    'position',[xoffset-.02 .89 .18 .1],'String','Groom State','fontweight','bold');
groom_radio(1) = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','rad',...
    'position',[xoffset .8 .2 .1],'Value',1,'Callback', @groomRadio,'visible','on','string','No Groom');
groom_radio(2) = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','rad',...
    'position',[xoffset .7 .2 .1],'Value',0,'Callback', @groomRadio,'visible','on','string','wing');
groom_radio(3) = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','rad',...
    'position',[xoffset .6 .2 .1],'Value',0,'Callback', @groomRadio,'visible','on','string','foreleg');
groom_radio(4) = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','rad',...
    'position',[xoffset .5 .2 .1],'Value',0,'Callback', @groomRadio,'visible','on','string','hid leg');

% orientation, antenna and interactions
xoffset = .4;
% uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
%             'position',[xoffset-.02 .89 .18 .1],'String','signal clean?','fontweight','bold');
signal_radio = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','rad',...
    'position',[xoffset .8 .2 .1],'Value',1,'Callback', @signalRadio,'visible','on','string','signal clean?');
collison_radio = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','rad',...
    'position',[xoffset .7 .2 .1],'Value',0,'Callback', @collisionRadio,'visible','on','string','collision');
overpass_radio = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','rad',...
    'position',[xoffset .6 .2 .1],'Value',0,'Callback', @overpassRadio,'visible','on','string','overpass');
antenolap_radio = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','rad',...
    'position',[xoffset .5 .2 .1],'Value',0,'Callback', @antenolapRadio,'visible','on','string','antenna o.lap');
reflection_radio = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','rad',...
    'position',[xoffset .4 .2 .1],'Value',0,'Callback', @reflectionRadio,'visible','on','string','reflection');


% frame navigation
yoffset = .85;
xoffset = .5;
FrameNumBorder = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[xoffset+.18 yoffset-.015 .12 .13],'Style','pushbutton','Enable','off','String','');
FrameNum = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[xoffset+.19 yoffset .1 .1],'Style','edit','String','1','ForegroundColor','k','Callback',@FrameNumCall);
uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[xoffset+.305 yoffset .09 .11],'Style','pushbutton','Enable','on','String','< Prev','Callback',@PrevFrameCall);
uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[xoffset+.4 yoffset .09 .11],'Style','pushbutton','Enable','on','String','Next >','Callback',@NextFrameCall);

% select several frames
selectFrameStart = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized','enable','off',...
    'Position',[xoffset+.15 yoffset-.15 .1 .1],'Style','edit','String','NA','ForegroundColor','k','Callback',@selectFrameCallStart);
selectFrameEnd = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized','enable','off',...
    'Position',[xoffset+.25 yoffset-.15 .1 .1],'Style','edit','String','NA','ForegroundColor','k','Callback',@selectFrameCallEnd);
SelectButton = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.45,'units','normalized',...
    'Position',[xoffset+.35 yoffset-.15 .15 .1],'Style','pushbutton','Enable','on','String','Frame Range','Callback',@selectFrameRange);


% flip direction
uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[xoffset+.29 yoffset-.28 .18 .1],'Style','pushbutton','Enable','on','String','flip direction.','Callback',@flipdir);

measure_radio = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.4,'units','normalized','Style','rad',...
    'position',[xoffset+.17 yoffset-.28 .12 .1],'Value',0,'visible','on','string','get signal?','Callback',@measureCall);

playButton = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[.83 .27 .15 .1],'Style','pushbutton','Enable','on','String','play','Callback',@play_call);

stopBNFButton = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[.83 .15 .15 .1],'Style','pushbutton','Enable','on','String','stop BNF','Callback',@BNF_call);

doneButton = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[.83 .03 .15 .1],'Style','pushbutton','Enable','on','String','Done','Callback',@done_call);

save_radio = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.4,'units','normalized','Style','rad',...
    'position',[.73 .03 .1 .1],'Value',0,'visible','on','string','save f');

defcolor = get(doneButton,'BackgroundColor');

if playBNF
    set(stopBNFButton,'string','stop BNF')
else
    set(stopBNFButton,'string','start BNF')
end

annotationStatusButton = uicontrol('parent',editPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[.03 .03 .15 .1],'Style','pushbutton','Enable','on','String','Annot. ON.','Callback',@annotStat_call);

%% graph axes
ax1 = axes('units','normalized','Position',[.04 .505 0.7 0.35]);
hold on
% rec1 = rectangle('position',[0 0 0 0],'facecolor',[.8 .8 .8],'edgecolor','none');
encounter_area = area(ax1,1,NaN,'facecolor',ones(1,3)*.95);
signalplot = plot(ax1,NaN,NaN,'LineWidth',2,'Color','k');
encounter_plot = plot(ax1,NaN,NaN,':g','LineWidth',2);
threshold_plot = plot(ax1,NaN,NaN,'m--','LineWidth',1);
maskedSignal_plot = plot(ax1,NaN,NaN,':','LineWidth',2,'Color',[0.91 0.41 0.17]);
showframe =  plot(ax1,NaN,NaN,'or');
showselected =  plot(ax1,NaN,NaN,'r');



%% initialize
% get fixed antenna signal if not annotated already
these_frames = f.annotation_info.active_frames(tracknum,1):f.annotation_info.active_frames(tracknum,2);

% get the selected plot data
plotSelectCall;

setPanel;
plotSignal;
plotPeaks;
getPlotLimits;
plotFlyTrack;

% setOverlapMsg;
setOverlapMsg;
setErrorMsg;


set(FrameNum,'string',num2str(current_frame));
set(trackNum,'string',num2str(tracknum));



%% set the flywalk window size to quarter
%
figpossave = f.ui_handles.fig.Position;
f.ui_handles.fig.Position = [10/1152*xw 250/771*yw 1.13*scsz(3)/3 2.08*scsz(4)/3];

%% functions

    function [] = guessAnnotation(~,~)
        walk_criteria = 3; % times the immobile speed
        for tn = 1:TotTracksnum
            trackspeed = getFlyKalVel(f,tn);
            f.annotation_info.mobile_status(tn,trackspeed>(f.immobile_speed*walk_criteria)) = 1; %0: stop, 1: walk, 2: back up, 3: jump
            f.annotation_info.mobile_status(tn,f.tracking_info.jump_status(tn,:)==1) = 3; %0: stop, 1: walk, 2: back up, 3: jump
            f.annotation_info.groom_status(tn,f.tracking_info.groom_mask(tn,:)==1) = 1; %0: NA, 1: wing, 2: hid leg, 3: foreleg
            f.annotation_info.signal_clean(tn,:) = f.tracking_info.mask_of_signal(tn,:); %0: false, not clean, 1: true signal - clean
            f.annotation_info.orientation(tn,:) = f.tracking_info.orientation(tn,:); % 0-360 degrees
            f.annotation_info.collision(tn,~isnan(f.tracking_info.collision(tn,:))) = 1; %0: no collision, 1: collision with another fly
            f.annotation_info.overpassing(tn,~isnan(f.tracking_info.overpassing(tn,:))) = 1; %0: no overpass, 1: passing over another fly
            alloverlap = f.tracking_info.antenna1R_overlap(tn,:)+f.tracking_info.antenna_overlap(tn,:)+f.tracking_info.antenna2R_overlap(tn,:);
            f.annotation_info.antenna_overlap(tn,:) = alloverlap>0; %0: no overlap, 1: overlaps (w/ another fly, reflection, itself etc)
            f.annotation_info.active_frames(tn,1) = find(f.tracking_info.fly_status(tn,:)==1,1); %1: first frame, 2: last frame
            f.annotation_info.active_frames(tn,2) = find(f.tracking_info.fly_status(tn,:)==1,1,'last'); %1: first frame, 2: last frame
            f.annotation_info.reflection(tn,:) = f.reflection_status(tn,:); %0: no reflection, 1- reflection present
            f.annotation_info.signal(tn,:) = f.tracking_info.signal(tn,:); % copy the signal information
        end
        
    end

    function [] = setPanel(~,~)
        % sets the values in the edit pael to the guessed or edited values
        
        % mobile status
        for mrs = 1:numel(mobile_radio)
            set(mobile_radio(mrs),'value',0);
        end
        % set current mobile
        current_mobile_status = zeros(numel(mobile_radio),1);
        current_mobile_status(f.annotation_info.mobile_status(tracknum,current_frame)+1) = 1;
        
        switch f.annotation_info.mobile_status(tracknum,current_frame)
            case 0
                set(mobile_radio(1),'value',1);
            case 1
                set(mobile_radio(2),'value',1);
            case 2
                set(mobile_radio(3),'value',1);
            case 3
                set(mobile_radio(4),'value',1);
            case 4
                set(mobile_radio(5),'value',1);
        end
        
        % groom status
        for mrs = 1:numel(groom_radio)
            set(groom_radio(mrs),'value',0);
        end
        % set current groom status
        current_groom_status = zeros(numel(groom_radio),1);
        current_groom_status(f.annotation_info.groom_status(tracknum,current_frame)+1) = 1;
        switch f.annotation_info.groom_status(tracknum,current_frame)
            case 0
                set(groom_radio(1),'value',1);
            case 1
                set(groom_radio(2),'value',1);
            case 2
                set(groom_radio(3),'value',1);
            case 3
                set(groom_radio(4),'value',1);
        end
        
        % is signal clean
        set(signal_radio,'value',f.annotation_info.signal_clean(tracknum,current_frame))
        set(collison_radio,'value',f.annotation_info.collision(tracknum,current_frame))
        set(overpass_radio,'value',f.annotation_info.overpassing(tracknum,current_frame))
        set(antenolap_radio,'value',f.annotation_info.antenna_overlap(tracknum,current_frame))
        set(reflection_radio,'value',f.annotation_info.reflection(tracknum,current_frame))
        
    end

    function [] = AntennaTypeCall(~,~)
        if strcmp(AntennaType.String{AntennaType.Value},'dynamic')
            f.antenna_type = 'dynamic';
            if isfield(f.tracking_info,'signal_dynamic')
                % it was saved previously
                f.tracking_info.signal = f.tracking_info.signal_dynamic;
            else
                % save the signal as dynamic
                f.tracking_info.signal_dynamic = f.tracking_info.signal;
                f.tracking_info.signal = f.tracking_info.signal_dynamic;
            end
            f = getMaskedSignal(f);
            guessAnnotation;
            plotData = DataMat(tracknum,:);
            setPanel;
            plotSignal;
            plotPeaks;
            getPlotLimits;
            f.operateOnFrame;
        elseif strcmp(AntennaType.String{AntennaType.Value},'fixed')
            f.antenna_type = 'fixed';
            if isfield(f.tracking_info,'signal_dynamic')
                % it was saved previously
                f.tracking_info.signal = f.tracking_info.signal_fix;
            else
                % save the signal as dynamic
                f.tracking_info.signal_dynamic = f.tracking_info.signal;
                f.tracking_info.signal = f.tracking_info.signal_fix;
            end
            f = getMaskedSignal(f);
            guessAnnotation;
            plotData = DataMat(tracknum,:);
            setPanel;
            plotSignal;
            plotPeaks;
            getPlotLimits;
            f.operateOnFrame;
        else
            disp('unknown antenna type')
            keyboard;
        end
        
    end

    function [] = selectFrameCallStart(~,~)
        frms = str2num(get(selectFrameStart,'string'));
        frme = str2num(get(selectFrameEnd,'string'));
        if isempty(frms)||isempty(frme)
            selected_frames = [];
            clearSelected;
        else
            if frms<these_frames(1)
                frms = these_frames(1);
                selectFrameStart.String = num2str(frms);
            end
            if frme>these_frames(end)
                frme = these_frames(end);
                selectFrameEnd.String = num2str(frme);
            end
            selected_frames = frms:frme;
            current_frame = frms;
            setPanel;
            plotSignal;
            plotPeaks;
            getPlotLimits;
            plotFlyTrack;
            % setOverlapMsg;
            setOverlapMsg;
            setErrorMsg;
            set(FrameNum,'string',num2str(current_frame));
            
            plotSelected;
        end
    end

    function [] = selectFrameCallEnd(~,~)
        frms = str2num(get(selectFrameStart,'string'));
        frme = str2num(get(selectFrameEnd,'string'));
        if isempty(frms)||isempty(frme)
            selected_frames = [];
            clearSelected;
        else
            if frms<these_frames(1)
                frms = these_frames(1);
                selectFrameStart.String = num2str(frms);
            end
            if frme>these_frames(end)
                frme = these_frames(end);
                selectFrameEnd.String = num2str(frme);
            end
            selected_frames = frms:frme;
            current_frame = frme;
            setPanel;
            plotSignal;
            plotPeaks;
            getPlotLimits;
            plotFlyTrack;
            % setOverlapMsg;
            setOverlapMsg;
            setErrorMsg;
            set(FrameNum,'string',num2str(current_frame));
            
            plotSelected;
        end
    end




    function [] = plotSelected(~,~)
        showselected.XData = selected_frames;
        showselected.YData = plotData(selected_frames);
    end


    function [] = clearSelected(~,~)
        showselected.XData = NaN;
        showselected.YData = NaN;
    end


    function [] = selectGraphFrameRange(~,~)
        set(SelectGraphButton,'enable','off')
        ifh = imfreehand(ax1);
        p = getPosition(ifh);
        inp = inpolygon(1:length(plotData),plotData,p(:,1),p(:,2));
        frms = find(inp,1);
        frme = find(inp,1,'last');
        delete(ifh)
        if isempty(frms)||isempty(frme)
            selected_frames = [];
            set(SelectGraphButton,'enable','on')
            clearSelected;
            return
        else
            selected_frames = frms:frme;
            set(SelectButton,'string','Single Frame')
            set(selectFrameStart,'string',num2str(frms),'enable','on')
            set(selectFrameEnd,'string',num2str(frme),'enable','on')
            set(SelectGraphButton,'enable','on')
            current_frame = frms;
            setPanel;
            plotSignal;
            plotPeaks;
            getPlotLimits;
            plotFlyTrack;
            % setOverlapMsg;
            setOverlapMsg;
            setErrorMsg;
            set(FrameNum,'string',num2str(current_frame));
            plotSelected;
        end
    end

    function [] = selectAllFramesRange(~,~)
        selected_frames = these_frames;
        set(SelectButton,'string','Single Frame')
        set(selectFrameStart,'string',num2str(these_frames(1)),'enable','on')
        set(selectFrameEnd,'string',num2str(these_frames(end)),'enable','on')
        setPanel;
        plotSignal;
        plotPeaks;
        getPlotLimits;
        plotFlyTrack;
        % setOverlapMsg;
        setOverlapMsg;
        setErrorMsg;
        set(FrameNum,'string',num2str(current_frame));
        plotSelected;
    end

    function [] = selectFrameRange(~,~)
        if strcmp(get(SelectButton,'string'),'Frame Range')
            set(SelectButton,'string','Single Frame')
            set(selectFrameStart,'string',num2str(current_frame),'enable','on')
            set(selectFrameEnd,'enable','on')
        elseif strcmp(get(SelectButton,'string'),'Single Frame')
            set(SelectButton,'string','Frame Range')
            set(selectFrameStart,'string','NA','enable','off')
            set(selectFrameEnd,'string','NA','enable','off')
            selected_frames = [];
            clearSelected;
        else
            disp('undefined button state')
            keyboard
        end
    end

    function [] = mobileRadio(~,~)
        % do it only if the annotation is enabled
        if strcmp(annotationStatusButton.String,'Annot. ON.')
            if strcmp(get(SelectButton,'string'),'Single Frame')
                if isempty(selected_frames)
                    msgbox('Select a valid frame range.');
                else
                    radio_status = vertcat(mobile_radio.Value);
                    selected_radio = find((radio_status==current_mobile_status)==0);
                    if isempty(selected_radio)
                        selected_radio = find(radio_status);
                    end
                    % change the annotation
                    f.annotation_info.mobile_status(tracknum,selected_frames) = selected_radio-1;
                    f.annotation_info.annotation_status(tracknum,selected_frames) = 1;
                    % reset buttons
                    set(mobile_radio,'Value',0);
                    mobile_radio(selected_radio).Value = 1;
                    % save the current mobile status
                    current_mobile_status(:) = 0;
                    current_mobile_status(selected_radio) = 1;
                end
            else
                radio_status = vertcat(mobile_radio.Value);
                selected_radio = find((radio_status==current_mobile_status)==0);
                if isempty(selected_radio)
                    selected_radio = find(radio_status);
                end
                % change the annotation
                f.annotation_info.mobile_status(tracknum,current_frame) = selected_radio-1;
                f.annotation_info.annotation_status(tracknum,current_frame) = 1;
                % reset buttons
                set(mobile_radio,'Value',0);
                mobile_radio(selected_radio).Value = 1;
                % save the current mobile status
                current_mobile_status(:) = 0;
                current_mobile_status(selected_radio) = 1;
            end
        else
            radio_status = vertcat(mobile_radio.Value);
            selected_radio = find((radio_status==current_mobile_status)==0);
            if ~isempty(selected_radio)
                mobile_radio(selected_radio).Value = ~mobile_radio(selected_radio).Value;
            end
        end
    end

    function [] = groomRadio(~,~)
        % do it only if the annotation is enabled
        if strcmp(annotationStatusButton.String,'Annot. ON.')
            if strcmp(get(SelectButton,'string'),'Single Frame')
                if isempty(selected_frames)
                    msgbox('Select a valid frame range.');
                else
                    radio_status = vertcat(groom_radio.Value);
                    selected_radio = find((radio_status==current_groom_status)==0);
                    if isempty(selected_radio)
                        selected_radio = find(radio_status);
                    end
                    % change the annotation
                    f.annotation_info.groom_status(tracknum,selected_frames) = selected_radio-1;
                    f.annotation_info.annotation_status(tracknum,selected_frames) = 1;
                    % reset buttons
                    set(groom_radio,'Value',0);
                    groom_radio(selected_radio).Value = 1;
                    % save the current mobile status
                    current_groom_status(:) = 0;
                    current_groom_status(selected_radio) = 1;
                    % if fly grooming set the mobile state to stop
                    if selected_radio>1
                        mobile_radio(1).Value = 1;
                        mobileRadio;
                    end
                end
            else
                radio_status = vertcat(groom_radio.Value);
                selected_radio = find((radio_status==current_groom_status)==0);
                if isempty(selected_radio)
                    selected_radio = find(radio_status);
                end
                % change the annotation
                f.annotation_info.groom_status(tracknum,current_frame) = selected_radio-1;
                f.annotation_info.annotation_status(tracknum,current_frame) = 1;
                % reset buttons
                set(groom_radio,'Value',0);
                groom_radio(selected_radio).Value = 1;
                % save the current mobile status
                current_groom_status(:) = 0;
                current_groom_status(selected_radio) = 1;
                % if fly grooming set the mobile state to stop
                if selected_radio>1
                    mobile_radio(1).Value = 1;
                    mobileRadio;
                end
            end
        else
            radio_status = vertcat(groom_radio.Value);
            selected_radio = find((radio_status==current_groom_status)==0);
            if ~isempty(selected_radio)
                groom_radio(selected_radio).Value = ~groom_radio(selected_radio).Value;
            end
        end
    end


    function [] = signalRadio(~,~)
        % do it only if the annotation is enabled
        if strcmp(annotationStatusButton.String,'Annot. ON.')
            if strcmp(get(SelectButton,'string'),'Single Frame')
                if isempty(selected_frames)
                    msgbox('Select a valid frame range.');
                else
                    % change the annotation
                    f.annotation_info.signal_clean(tracknum,selected_frames) = signal_radio.Value;
                    f.annotation_info.annotation_status(tracknum,selected_frames) = 1;
                end
            else
                % change the annotation
                f.annotation_info.signal_clean(tracknum,current_frame) = signal_radio.Value;
                f.annotation_info.annotation_status(tracknum,current_frame) = 1;
            end
        else
            signal_radio.Value = ~signal_radio.Value;
        end
    end

    function [] = collisionRadio(~,~)
        % do it only if the annotation is enabled
        if strcmp(annotationStatusButton.String,'Annot. ON.')
            if strcmp(get(SelectButton,'string'),'Single Frame')
                if isempty(selected_frames)
                    msgbox('Select a valid frame range.');
                else
                    % change the annotation
                    f.annotation_info.collision(tracknum,selected_frames) = collison_radio.Value;
                    f.annotation_info.annotation_status(tracknum,selected_frames) = 1;
                end
            else
                % change the annotation
                f.annotation_info.collision(tracknum,current_frame) = collison_radio.Value;
                f.annotation_info.annotation_status(tracknum,current_frame) = 1;
            end
        else
            collison_radio.Value = ~collison_radio.Value;
        end
    end

    function [] = overpassRadio(~,~)
        % do it only if the annotation is enabled
        if strcmp(annotationStatusButton.String,'Annot. ON.')
            if strcmp(get(SelectButton,'string'),'Single Frame')
                if isempty(selected_frames)
                    msgbox('Select a valid frame range.');
                else
                    % change the annotation
                    f.annotation_info.overpassing(tracknum,selected_frames) = overpass_radio.Value;
                    f.annotation_info.annotation_status(tracknum,selected_frames) = 1;
                end
            else
                % change the annotation
                f.annotation_info.overpassing(tracknum,current_frame) = overpass_radio.Value;
                f.annotation_info.annotation_status(tracknum,current_frame) = 1;
            end
        else
            overpass_radio.Value = ~overpass_radio.Value;
        end
    end

    function [] = antenolapRadio(~,~)
        % do it only if the annotation is enabled
        if strcmp(annotationStatusButton.String,'Annot. ON.')
            if strcmp(get(SelectButton,'string'),'Single Frame')
                if isempty(selected_frames)
                    msgbox('Select a valid frame range.');
                else
                    % change the annotation
                    f.annotation_info.antenna_overlap(tracknum,selected_frames) = antenolap_radio.Value;
                    f.annotation_info.annotation_status(tracknum,selected_frames) = 1;
                end
            else
                % change the annotation
                f.annotation_info.antenna_overlap(tracknum,current_frame) = antenolap_radio.Value;
                f.annotation_info.annotation_status(tracknum,current_frame) = 1;
            end
        else
            antenolap_radio.Value = ~antenolap_radio.Value;
        end
    end

    function [] = reflectionRadio(~,~)
        % do it only if the annotation is enabled
        if strcmp(annotationStatusButton.String,'Annot. ON.')
            if strcmp(get(SelectButton,'string'),'Single Frame')
                if isempty(selected_frames)
                    msgbox('Select a valid frame range.');
                else
                    % change the annotation
                    f.annotation_info.reflection(tracknum,selected_frames) = reflection_radio.Value;
                    f.annotation_info.annotation_status(tracknum,selected_frames) = 1;
                end
            else
                % change the annotation
                f.annotation_info.reflection(tracknum,current_frame) = reflection_radio.Value;
                f.annotation_info.annotation_status(tracknum,current_frame) = 1;
            end
        else
            % reverse the button value
            reflection_radio.Value = ~reflection_radio.Value;
        end
    end

    function [] = measureCall(~,~)
        if ~strcmp(annotationStatusButton.String,'Annot. ON.')
            measure_radio.Value = ~measure_radio.Value;
        end
    end

    function [] = flipdir(~,~)
        % do it only if the annotation is enabled
        if strcmp(annotationStatusButton.String,'Annot. ON.')
            if strcmp(get(SelectButton,'string'),'Single Frame')
                if isempty(selected_frames)
                    msgbox('Select a valid frame range.');
                else
                    % flip the orientation
                    f.annotation_info.orientation(tracknum,selected_frames) = mod(f.annotation_info.orientation(tracknum,selected_frames)+180,360);
                    f.tracking_info.orientation(tracknum,selected_frames) = mod(f.tracking_info.orientation(tracknum,selected_frames)+180,360);
                    f.annotation_info.annotation_status(tracknum,selected_frames) = 1;
                    f.annotation_info.orientation_flipped(tracknum,selected_frames) = ~f.annotation_info.orientation_flipped(tracknum,selected_frames);
                    f.operateOnFrame;
                    
                    if measure_radio.Value
                        % measure the signal with the new orientation
                        for cfi = 1:length(selected_frames)
                            current_frame = selected_frames(cfi);
                            set(FrameNum,'string',num2str(current_frame));
                            f.previous_frame = f.current_frame;
                            f.current_frame = current_frame;
                            f.operateOnFrame;
                            f = measureSignalofThisFly(f,tracknum);
                            DataMat(tracknum,current_frame) = f.tracking_info.signal(tracknum,current_frame);
                            plotData = DataMat(tracknum,:);
                            f.annotation_info.antenna_overlap(tracknum,current_frame) = (f.tracking_info.antenna1R_overlap(tracknum,current_frame)+...
                                f.tracking_info.antenna2R_overlap(tracknum,current_frame)+f.tracking_info.antenna_overlap(tracknum,current_frame))>0;
                            setPanel;
                            plotSignal;
                            plotPeaks;
                            getPlotLimits;
                            plotFlyTrack;
                            % setOverlapMsg;
                            setOverlapMsg;
                            setErrorMsg;
                        end
                        measure_radio.Value = 0;
                    end
                end
            else
                % flip the orientation
                f.annotation_info.orientation(tracknum,current_frame) = mod(f.annotation_info.orientation(tracknum,current_frame)+180,360);
                f.tracking_info.orientation(tracknum,current_frame) = mod(f.tracking_info.orientation(tracknum,current_frame)+180,360);
                f.annotation_info.annotation_status(tracknum,current_frame) = 1;
                f.annotation_info.orientation_flipped(tracknum,current_frame) = ~f.annotation_info.orientation_flipped(tracknum,current_frame);
                f.operateOnFrame;
                
                if measure_radio.Value
                    % measure the signal with the new orientation
                    f = measureSignalofThisFly(f,tracknum);
                    DataMat(tracknum,current_frame) = f.tracking_info.signal(tracknum,current_frame);
                    plotData = DataMat(tracknum,:);
                    f.annotation_info.antenna_overlap(tracknum,current_frame) = (f.tracking_info.antenna1R_overlap(tracknum,current_frame)+...
                        f.tracking_info.antenna2R_overlap(tracknum,current_frame)+f.tracking_info.antenna_overlap(tracknum,current_frame))>0;
                    plotSignal;
                    plotPeaks;
                    getPlotLimits;
                    plotFlyTrack;
                    % setOverlapMsg;
                    setOverlapMsg;
                    setErrorMsg;
                    measure_radio.Value =0;
                end
            end
        end
    end



    function [] = FrameNumCall(~,~)
        current_frame = str2num(get(FrameNum,'string')); %#ok<ST2NM>
        if current_frame<these_frames(1)
            current_frame = these_frames(1);
            set(FrameNum,'string',num2str(current_frame))
        end
        if current_frame>these_frames(end)
            current_frame = these_frames(end);
            set(FrameNum,'string',num2str(current_frame))
        end
        setPanel;
        %         plotSignal;
        plotPeaks;
        getPlotLimits;
        plotFlyTrack;
        
        % setOverlapMsg;
        setOverlapMsg;
        setErrorMsg;
        if f.annotation_info.annotation_status(tracknum,current_frame)
            set(FrameNumBorder,'BackgroundColor','g')
        else
            set(FrameNumBorder,'BackgroundColor',defcolor)
        end
    end

    function [] = NextFrameCall(~,~)
        if strcmp(annotationStatusButton.String,'Annot. ON.')
            f.annotation_info.annotation_status(tracknum,current_frame) = 1;
        end
        current_frame = current_frame + 1;
        if current_frame>these_frames(end)
            current_frame = these_frames(end);
            return
        end
        set(FrameNum,'string',num2str(current_frame));
        setPanel;
        %         plotSignal;
        plotPeaks;
        getPlotLimits;
        plotFlyTrack;
        
        % setOverlapMsg;
        setOverlapMsg;
        setErrorMsg;
        if f.annotation_info.annotation_status(tracknum,current_frame)
            set(FrameNumBorder,'BackgroundColor','g')
        else
            set(FrameNumBorder,'BackgroundColor',defcolor)
        end
    end

    function [] = PrevFrameCall(~,~)
        current_frame = current_frame - 1;
        if current_frame<these_frames(1)
            current_frame = these_frames(1);
            return
        end
        set(FrameNum,'string',num2str(current_frame));
        setPanel;
        %         plotSignal;
        plotPeaks;
        getPlotLimits;
        plotFlyTrack;
        
        % setOverlapMsg;
        setOverlapMsg;
        setErrorMsg;
        if f.annotation_info.annotation_status(tracknum,current_frame)
            set(FrameNumBorder,'BackgroundColor','g')
        else
            set(FrameNumBorder,'BackgroundColor',defcolor)
        end
    end


% track navigation
    function [] = trackNumCall(~,~)
        tracknum = str2num(get(trackNum,'string')); %#ok<ST2NM>
        if tracknum<1
            tracknum = 1;
        end
        if tracknum>TotTracksnum
            tracknum = TotTracksnum;
        end
        if ~any((1:TotTracksnum)==tracknum)
            tracknum = (find((1:TotTracksnum)<tracknum,1,'last'));
        end
        set(trackNum,'string',num2str(tracknum));
        these_frames = f.annotation_info.active_frames(tracknum,1):f.annotation_info.active_frames(tracknum,2);
        plotData = DataMat(tracknum,:);
        current_frame = these_frames(1);
        
        setPanel;
        plotSignal;
        plotPeaks;
        getPlotLimits;
        plotFlyTrack;
        
        % setOverlapMsg;
        setOverlapMsg;
        setErrorMsg;
        
        
        set(FrameNum,'string',num2str(current_frame));
        set(trackNum,'string',num2str(tracknum));
        
        
        if f.annotation_info.annotation_status(tracknum,current_frame)
            set(FrameNumBorder,'BackgroundColor','g')
        else
            set(FrameNumBorder,'BackgroundColor',defcolor)
        end
    end

    function [] = NexttrackCall(~,~)
        tracknum = tracknum + 1;
        
        if tracknum>TotTracksnum
            tracknum = TotTracksnum;
            return
        end
        
        these_frames = f.annotation_info.active_frames(tracknum,1):f.annotation_info.active_frames(tracknum,2);
        
        plotData = DataMat(tracknum,:);
        current_frame = these_frames(1);
        
        setPanel;
        plotSignal;
        plotPeaks;
        getPlotLimits;
        plotFlyTrack;
        
        % setOverlapMsg;
        setOverlapMsg;
        setErrorMsg;
        
        
        set(FrameNum,'string',num2str(current_frame));
        set(trackNum,'string',num2str(tracknum));
        
        
        if f.annotation_info.annotation_status(tracknum,current_frame)
            set(FrameNumBorder,'BackgroundColor','g')
        else
            set(FrameNumBorder,'BackgroundColor',defcolor)
        end
    end

    function [] = PrevtrackCall(~,~)
        tracknum = tracknum - 1;
        
        if tracknum<1
            tracknum = 1;
            return
        end
        
        these_frames = f.annotation_info.active_frames(tracknum,1):f.annotation_info.active_frames(tracknum,2);
        
        plotData = DataMat(tracknum,:);
        current_frame = these_frames(1);
        
        setPanel;
        plotSignal;
        plotPeaks;
        getPlotLimits;
        plotFlyTrack;
        
        % setOverlapMsg;
        setOverlapMsg;
        setErrorMsg;
        
        
        set(FrameNum,'string',num2str(current_frame));
        set(trackNum,'string',num2str(tracknum));
        
        
        if f.annotation_info.annotation_status(tracknum,current_frame)
            set(FrameNumBorder,'BackgroundColor','g')
        else
            set(FrameNumBorder,'BackgroundColor',defcolor)
        end
    end



    function [] = setOverlapMsg(~,~)
        % clear the board first
        set(overlapboard,'string',['Antenna Overlap:',num2str(f.tracking_info.antenna_overlap(tracknum,current_frame),'%5.2f')]);
    end



    function [] = setErrorMsg(~,~)
        error_msg = '';
        % clear the board first
        set(errorboard,'string',' ');
        if any(f.tracking_info.error_code(tracknum,current_frame)>0)
            errcode = nonzeros(unique(f.tracking_info.error_code(tracknum,current_frame)));
            for ecin = 1:length(errcode)
                error_msg = [error_msg,' Fly:',num2str(tracknum),':',f.error_def{errcode(ecin)}];
            end
        end
        if ~strcmp(error_msg,'')
            set(errorboard,'string',error_msg);
        end
    end



    function [] = done_call(~,~)
        savefwobj = get(save_radio,'value');
        QuitsortFlyWalkCallback
        
        if savefwobj
            f.save;
        end
        
    end

    function [] = annotStat_call(~,~)
        if strcmp(annotationStatusButton.String,'Annot. ON.')
            % start play, set the color to green, and string to stop
            annotationStatusButton.String = 'Annot. OFF.';
            annotationStatusButton.BackgroundColor = 'c';
        else
            annotationStatusButton.String = 'Annot. ON.';
            annotationStatusButton.BackgroundColor = defcolor;
        end
    end


    function [] = BNF_call(~,~)
        % plays back and forth from start to end
        if strcmp(stopBNFButton.String,'start BNF')
            if isempty(selected_frames)
                % start play, set the color to green, and string to stop
                stopBNFButton.String = 'stop BNF';
                stopBNFButton.BackgroundColor = 'g';
                startframe = f.current_frame;
                for pind = f.current_frame:these_frames(end)
                    if strcmp(stopBNFButton.String,'stop BNF')
                        NextFrameCall;
                    else
                        break
                    end
                end
                for pind = these_frames(end):-1:startframe
                    if strcmp(stopBNFButton.String,'stop BNF')
                        PrevFrameCall;
                    else
                        break
                    end
                end
                stopBNFButton.String = 'start BNF';
                stopBNFButton.BackgroundColor = defcolor;
            else
                % start play, set the color to green, and string to stop
                stopBNFButton.String = 'stop BNF';
                stopBNFButton.BackgroundColor = 'g';
                current_frame = selected_frames(1);
                f.current_frame = current_frame;
                FrameNum.String = current_frame;
                FrameNumCall;
                startframe = f.current_frame;
                for pind = selected_frames
                    if strcmp(stopBNFButton.String,'stop BNF')
                        NextFrameCall;
                    else
                        break
                    end
                end
                for pind = these_frames(end):-1:startframe
                    if strcmp(stopBNFButton.String,'stop BNF')
                        PrevFrameCall;
                    else
                        break
                    end
                end
                stopBNFButton.String = 'start BNF';
                stopBNFButton.BackgroundColor = defcolor;
            end
        elseif strcmp(stopBNFButton.String,'stop BNF')
            stopBNFButton.String = 'start BNF';
            stopBNFButton.BackgroundColor = defcolor;
        end
    end


    function [] = FlyBoxCall(~,~)
        flysize = str2double(get(FlyBoxSize,'string'))/f.ExpParam.mm_per_px;
        plotFlyTrack;
    end


    function [] = plotFlyTrack(~,~)
        f.previous_frame = f.current_frame;
        f.current_frame = current_frame;
        flyposx = (f.tracking_info.x(tracknum,current_frame));
        flyposy = (f.tracking_info.y(tracknum,current_frame));
        
        track_xlim = [flyposx-flysize,flyposx+flysize];
        track_ylim = [flyposy-flysize,flyposy+flysize];
        f.ui_handles.scrubber.Value = f.current_frame;
        f.operateOnFrame;
        drawnow limitrate
        if ~any(isnan([track_xlim,track_ylim]))
            % activate the figure
            set(f.plot_handles.ax,'xlim',track_xlim,'ylim',track_ylim)
        end
    end

    function []=play_call(~,~)
        if strcmp(playButton.String,'play')
            if isempty(selected_frames)
                % start play, set the color to green, and string to stop
                playButton.String = 'stop';
                playButton.BackgroundColor = 'g';
                for pind = f.current_frame:f.nframes
                    if strcmp(playButton.String,'stop')
                        NextFrameCall;
                    else
                        break
                    end
                end
                if pind == f.nframes
                    playButton.String = 'play';
                    playButton.BackgroundColor = defcolor;
                end
            else
                % start play, set the color to green, and string to stop
                playButton.String = 'stop';
                playButton.BackgroundColor = 'g';
                current_frame = selected_frames(1);
                f.current_frame = current_frame;
                FrameNum.String = current_frame;
                FrameNumCall;
                for pind = selected_frames
                    if strcmp(playButton.String,'stop')
                        NextFrameCall;
                    else
                        break
                    end
                end
                if pind == selected_frames(end)
                    playButton.String = 'play';
                    playButton.BackgroundColor = defcolor;
                end
            end
        elseif strcmp(playButton.String,'stop')
            playButton.String = 'play';
            playButton.BackgroundColor = defcolor;
        end
    end


    function [] = ZoomCall(~,~)
        getPlotLimits;
        updateSignalPlot;
    end

    function [] =  shadeEncCall(~,~)
        annotStat_call;
        setPanel;
        plotSignal;
        plotPeaks;
        getPlotLimits;
        plotFlyTrack;
        
        % setOverlapMsg;
        setOverlapMsg;
        setErrorMsg;
    end

    function [] = olayMaskCall(~,~)
        setPanel;
        plotSignal;
        plotPeaks;
        getPlotLimits;
        plotFlyTrack;
        
        % setOverlapMsg;
        setOverlapMsg;
        setErrorMsg;
    end

    function [] = ylimMaxCall(~,~)
        max_y_limit = str2double(get(ylimMax,'string'));
        getPlotLimits;
    end

    function [] = ylimMinCall(~,~)
        min_y_limit = str2double(get(ylimMin,'string'));
        getPlotLimits;
    end

    function [] = getPlotLimits(~,~)
        %         max_y_limit = 50;
        if ~get(zoom_radio,'Value') % frames
            plot_xlimit = [these_frames(1) these_frames(end)];
            plot_ylimit = [min(plotData(these_frames))*.9 max(plotData(these_frames))*1.1];
        else
            zoomwidnum = str2double(get(zoomNum,'string'));
            plot_xlimit = [current_frame-zoomwidnum current_frame+zoomwidnum];
            if plot_xlimit(1)<these_frames(1)
                plot_xlimit(1) = these_frames(1);
            end
            if plot_xlimit(2)>these_frames(end)
                plot_xlimit(2) = these_frames(end);
            end
            if current_frame-zoomwidnum<1
                plis = 1;
            else
                plis = current_frame-zoomwidnum;
            end
            if current_frame+zoomwidnum>these_frames(end)
                plie = these_frames(end);
                plot_xlimit(2) = plie;
            else
                plie = current_frame+zoomwidnum;
            end
            plot_ylimit = [min(plotData(plis:plie))*.9 max(plotData(plis:plie))*1.1];
        end
        if any(isnan(plot_ylimit))
            plot_ylimit = [min_y_limit max_y_limit];
        end
        if plot_xlimit(1)==plot_xlimit(2)
            plot_xlimit(2) = plot_xlimit(1) + 1;
        end
        if plot_ylimit(2)>max_y_limit
            plot_ylimit(2) = max_y_limit;
            if plot_ylimit(1)>max_y_limit
                plot_ylimit(1) = max_y_limit-5;
            end
        end
        if plot_ylimit(1)<min_y_limit
            plot_ylimit(1) = min_y_limit;
            if plot_ylimit(2)<min_y_limit
                plot_ylimit(2) = min_y_limit+5;
            end
        end
        % if both y limits are same increase max by one
        if plot_ylimit(1)==plot_ylimit(2)
            plot_ylimit(2) = plot_ylimit(1) + 1;
        end
        
        set(ax1,'Ylim',plot_ylimit,'Xlim',plot_xlimit)
        if plot_ylimit(2)==max_y_limit
            if plot_ylimit(1)==(max_y_limit-5)
                if ~warnedForYLim
                    msgbox('Data beyond set limit. Increase Ylim-Max.');
                    warnedForYLim =1;
                end
            end
        end
    end

    function [] = plotSignal(~,~)
        
        % reset plots
        signalplot.YData = NaN; signalplot.XData = NaN;
        encounter_area.XData = 1; encounter_area.YData = NaN;
        threshold_plot.XData = NaN; threshold_plot.YData = NaN;
        encounter_plot.XData = NaN; encounter_plot.YData = NaN;
        maskedSignal_plot.XData = NaN; maskedSignal_plot.YData = NaN;
        
        % update plots
        signalplot.XData = these_frames;
        signalplot.YData = plotData(these_frames);
        
        %shade the areas
        if shadeEnc_radio.Value
            threshold_plot.XData = [these_frames(1),these_frames(end)];
            threshold_plot.YData = ones(2,1)*f.tracking_info.signal_threshold;
            if size(f.tracking_info.signal_onset,1)<tracknum
               onp = [];
               offp = [];
            else
                onp = nonzeros(f.tracking_info.signal_onset(tracknum,:));
                offp = nonzeros(f.tracking_info.signal_offset(tracknum,:));
            end
            if ~isempty(onp)
                thisArea = nan(size(these_frames));
                thisEncPlot = nan(size(these_frames));
                for aind = 1:length(onp)
                    thisArea(logical((these_frames>=onp(aind)).*(these_frames<=offp(aind)))) = plot_ylimit(2);
                    thisEncPlot(logical((these_frames>=onp(aind)).*(these_frames<=offp(aind)))) = ...
                        plotData(logical((these_frames>=onp(aind)).*(these_frames<=offp(aind))));
                    
                end
                encounter_area.XData = these_frames;
                encounter_area.YData = thisArea;
                encounter_plot.XData = these_frames;
                encounter_plot.YData = thisEncPlot;
            end
        end
        
        % overlay masked portion
        if olayMask_radio.Value
            thisOlayPlot = plotData(these_frames);
            thisOlayPlot(logical(f.tracking_info.mask_of_signal(tracknum,these_frames))) = nan;
            maskedSignal_plot.XData = these_frames;
            maskedSignal_plot.YData = thisOlayPlot;
        end
        
    end

    function [] = ParameterCall(~,~)
        f.plm_cont_par.smooth_length = str2double(get(smoothlen,'string'));
        
        f.plm_cont_par.minPeakDist = str2double(get(minPeakDisted,'string'));
        
        f.plm_cont_par.minPeakProm = str2double(get(minPeakPromed,'string'));
        
        f.plm_cont_par.maxPeakWidth = str2double(get(maxPeakWidthed,'string'));
        
        f.plm_cont_par.minPeakWidth = str2double(get(minPeakWidthed,'string'));
        
        f.plm_cont_par.maxPeakHeight = str2double(get(maxPeakHeighted,'string'));
        
        f.plm_cont_par.minPeakTrackLength = str2double(get(mintracklength,'string'));
        
    end

    function [] = getEncountersCall(~,~)
        % find encounters
        % get threshold parameter
        sigThreshFactor = str2double(get(sigThreshFactEd,'string'));
        % get threshold
        threshSig = getSigThresh(f,sigThreshFactor);
        f = getBinarizedSignalDetection(f,threshSig);
        
        setPanel;
        plotSignal;
        plotPeaks;
        getPlotLimits;
        plotFlyTrack;
        
        % setOverlapMsg;
        setOverlapMsg;
        setErrorMsg;
        
    end


    function [] = plotPeaks(~,~)
        
        showframe.XData = NaN; showframe.YData = NaN;
        showframe.XData = current_frame(1);
        showframe.YData = plotData(current_frame(1));
    end

    function [] = updateSignalPlot(~,~)
        
        getPlotLimits; % get limits of signal plot
        
        showframe.XData = current_frame;
        showframe.YData = plotData(current_frame);
        
        %         rec1.Position = [on_point plot_ylimit(1) off_point-on_point plot_ylimit(2)-plot_ylimit(1)];
        set(ax1,'Ylim',plot_ylimit,'Xlim',plot_xlimit)
        %         set(refl_radio,'Value',f.reflection_status(tracknum,peak_point));
    end

    function [] = plotSelectCall(~,~)
        %       plotSelectionList = {'Speed','X','Y','Orientation','Rot. Speed','Area','Signal','Heading','msd-mov','msd-slope','msd-sum','msd-mean','abs-disp'};
        pselval = get(plotSelection,'Value');  % Get the users choice.
        selectedPlot = plotSelectionList{pselval};
        switch selectedPlot
            case 'Speed'
                x = f.tracking_info.x;
                y = f.tracking_info.y;
                dx = diffCentralMat(x,2);
                dy = diffCentralMat(y,2);
                DataMat = sqrt(dx.^2+dy.^2).*f.ExpParam.fps;
            case 'X'
                DataMat = f.tracking_info.x;
            case 'Y'
                DataMat = f.tracking_info.y;
            case 'Orientation'
                DataMat = f.tracking_info.orientation;
            case 'Rot. Speed'
                OrMat = f.tracking_info.orientation;
                DataMat = anglediffCentralMat(OrMat,2).*f.ExpParam.fps;
            case 'Area'
                DataMat = f.tracking_info.area;
            case 'Signal'
                DataMat = f.tracking_info.signal;
            case 'Masked-Signal'
                DataMat = f.tracking_info.signalm;
            case 'Heading'
                disp('Showing orientation')
                disp('Did not code heading yet')
                DataMat = f.tracking_info.orientation;
            case 'msd-mov'
                if ~isMsdCalculated
                    % calculate msd
                    EstimateMsdCall;
                    isMsdCalculated = 1;
                end
                DataMat = mm.*(f.ExpParam.mm_per_px).^2;
                
            case 'msd-slope'
                if ~isMsdCalculated
                    % calculate msd
                    EstimateMsdCall;
                    isMsdCalculated = 1;
                end
                DataMat = squeeze(msdSlope(:,:,1));
            case 'msd-sum'
                if ~isMsdCalculated
                    % calculate msd
                    EstimateMsdCall;
                    isMsdCalculated = 1;
                end
                DataMat = ms.*(f.ExpParam.mm_per_px).^2;
            case 'msd-mean'
                if ~isMsdCalculated
                    % calculate msd
                    EstimateMsdCall;
                    isMsdCalculated = 1;
                end
                DataMat = mnm.*(f.ExpParam.mm_per_px).^2;
            case 'abs-disp'
                if ~isMsdCalculated
                    % calculate msd
                    EstimateMsdCall;
                    isMsdCalculated = 1;
                end
                DataMat = ad.*f.ExpParam.mm_per_px;
            otherwise
                error('check the code for logging format')
        end
        plotData = DataMat(tracknum,:);
        setPanel;
        plotSignal;
        plotPeaks;
        getPlotLimits;
        plotFlyTrack;
        
        % setOverlapMsg;
        setOverlapMsg;
        setErrorMsg;
        
        
        set(FrameNum,'string',num2str(current_frame));
        set(trackNum,'string',num2str(tracknum));
        
    end

    function [] = EstimateMsdCall(~,~)
        % get window and estimation lengths
        msdLenVal = str2num(get(msdLen,'string'));        % msd calculation length , sec
        msdWindLenVal = str2num(get(msdWindLen,'string'));     % msd calculation window , sec
        msdoffsetVal = msdOffset.String{msdOffset.Value};
        
        f.tracking_info.msdLenVal = msdLenVal;        % msd calculation length , sec
        f.tracking_info.msdWindLenVal = msdWindLenVal;     % msd calculation window , sec
        f.tracking_info.msdoffsetVal = msdoffsetVal;
        
        % calculate msd
        x = f.tracking_info.x;
        y = f.tracking_info.y;
        nsteps = round(msdLenVal*f.ExpParam.fps); % msd calculation data points
        nwindow = round(msdWindLenVal*f.ExpParam.fps); % msd calculation data points
        disp('Calculating msd...')
        [mm,ms,mnm,ad,msdMat] = getMovingMsdMat(x,y,nsteps,2,nwindow,msdoffsetVal,1);
        f.tracking_info.msdMov = mm; % moving msd
        f.tracking_info.msdSum = ms;  % msd sum
        f.tracking_info.msdMean= mnm; % mean of the msd over all time steps
        f.tracking_info.totDisp = ad;   % actual displacement
        f.tracking_info.msdMat = msdMat;    % msd vs time at t
        timetemp = 1:size(msdMat,3);
        msdSlope = nan([size(msdMat,1),size(msdMat,2),2]);
        disp('fitting a line to log-log msd...')
        for k = 1:size(msdMat,1)
            thismsdMat = squeeze(msdMat(k,:,:));
            for i = 1:size(msdMat,2)
                msditemp = thismsdMat(i,:);
                % eliminate zero values
                thistimetemp =  timetemp;
                thistimetemp(msditemp==0) = [];
                msditemp(msditemp==0) = [];
                if isempty(msditemp)
                    msdSlope(k,i,:) = 0;
                    continue
                end
                msdSlope(k,i,:) = polyfit(log(thistimetemp),log(msditemp),1);
            end
            disp(['Completed ',num2str(k),'/',num2str(size(msdMat,1)),' ...'])
        end
        f.tracking_info.msdSlope =  msdSlope;  % slope of log log msd vs time
        
        % update the plot
        plotSelectCall;
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
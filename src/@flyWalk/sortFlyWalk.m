%% sorts fly walk interactions and behaviour
function f = sortFlyWalk(f)
% get interaction list
cil = f.crowd_interaction_list;
tracking_info = f.tracking_info;
if isempty(cil)
    disp('There is not any interaction')
    return
end

% do not run tracking during manual sort
f.track_movie=0;

% some variables
reflection_radio = zeros(10,1);
tracks_num_text = zeros(10,1);
manual_num_edit = zeros(10,1);
playBNF = 0;
flynum = [];
if any(strcmp(fieldnames(f),'edited_tracks'))
    if isempty(f.edited_tracks)
        edited_tracks = cell(size(cil));
    else
        edited_tracks = f.edited_tracks;
    end
else
    edited_tracks = cell(size(cil));
end
if any(strcmp(fieldnames(f),'edited_reflections'))
    if isempty(f.edited_reflections)
        edited_reflections = cell(size(cil));
    else
        edited_reflections = f.edited_reflections;
    end
else
    edited_reflections = cell(size(cil));% values manually corrected
end
if any(strcmp(fieldnames(f),'is_list_dropped'))
    if isempty(f.is_list_dropped)
        is_list_dropped = zeros(numel(cil),1);
    else
        is_list_dropped= f.is_list_dropped;
    end
else
    is_list_dropped = zeros(numel(cil),1);
end
if any(strcmp(fieldnames(f),'is_list_edited'))
    if isempty(f.is_list_edited)
        is_list_edited = zeros(numel(cil),1);
    else
        is_list_edited = f.is_list_edited;
    end
else
    is_list_edited = zeros(size(cil));
end

if any(strcmp(fieldnames(f),'is_list_deleted'))
    if isempty(f.is_list_deleted)
        is_list_deleted = zeros(numel(cil),1);
    else
        is_list_deleted = f.is_list_deleted;
    end
else
    is_list_deleted = zeros(size(cil));
end

if any(strcmp(fieldnames(f),'is_list_flipped'))
    if isempty(f.is_list_flipped)
        is_list_flipped = zeros(numel(cil),1);
    else
        is_list_flipped = f.is_list_flipped;
    end
else
    is_list_flipped = zeros(size(cil));
end

track_play_length = 0.5;  % sec before and after the collision, approx
joint_int_length = 5;      % join interactions if this close, and shares flies

fly_area = [];
% fly_majax = [];
% fly_minax = [];
fly_speed = [];
fly_areaM = [];
% fly_majaxM = [];
% fly_minaxM = [];
fly_speedM = [];

areaplot = gobjects(14); 
speedplot = gobjects(14);
areaplotm = gobjects(14); 
speedplotm = gobjects(14);
areaplots1 = gobjects(14); 
speedplots1 = gobjects(14);
areaplots2 = gobjects(14); 
speedplots2 = gobjects(14);

clrlist = {'k','r','b','m','g','c','y','k','r','b','m','g','c','y'};
track_play_length = 0.5;  % sec before and after the collision, approx
joint_int_length = 5;      % join interactions if too interactions are close to each other and have shared flies
play_buffer = round(track_play_length*f.ExpParam.fps);
% % create the plots
% % assume 10 fly interactions
% interaction_data = NaN(round(f.ExpParam.fps*track_play_length)*2,10,2);  % time,fly,xy
% 
% for n = 1:10
%    f.plot_handles.tracks(n) = plot(interaction_data(:,n,1),interaction_data(:,n,2),clrlist{n},'linewidth',3);
% end

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

f.label_flies = true;         % show fly labels next to each fly
f.mark_flies = false;       % show fly markers
f.show_orientations = false;      % show orientations, 0: do not show, 1: orientations, 2: heading, 3: both
f.show_trajectories = false;      % show tracks with a tail length of trajectory_vis_length 
f.show_antenna = false;          % shows the virtual antenna, where signal is integrated for each fly in each frame, 1: only antenna, 2: mask in a separate window
f.mark_lost = false;



scsz = get(0,'ScreenSize');
yw = 5*scsz(4)/7;
xw = 3*scsz(3)/5;
if xw<1070
    xw = 1070;
end

[~,flnm,~] = fileparts(f.path_name.Properties.Source);        
        
fSFW = figure('Position',[scsz(3)/7 scsz(4)/7 xw 5*scsz(4)/7],'NumberTitle','off','Visible','on','Name',flnm,'Menubar', 'none',...
    'Toolbar','figure','resize', 'on' ,'CloseRequestFcn',@QuitsortFlyWalkCallback);
        

%% error panel
errorpanel=uipanel('parent', fSFW,'fontunits', 'normalized','FontSize',.1,'units','normalized','pos',[15/xw 635/yw 500/xw 100/yw]);
errorboard = uicontrol('parent',errorpanel,'fontunits', 'normalized','FontSize',.15,'units','normalized','Style','text',...
            'position',[.03 .03 .9 .9],'String','','Max',2,'HorizontalAlignment', 'left','ForegroundColor','r');    


%% info panel
infopanel=uipanel('parent', fSFW,'fontunits', 'normalized','FontSize',.1,'units','normalized','pos',[15/xw 575/yw 500/xw 55/yw]);
infoboard = uicontrol('parent',infopanel,'fontunits', 'normalized','FontSize',.4,'units','normalized','Style','text',...
            'position',[.03 .03 .9 .9],'String','info here','Max',2,'HorizontalAlignment', 'left');        

%% TRACK MACTH PANEL
tracksMatchPanel = uipanel('parent', fSFW,'fontunits', 'normalized','FontSize',.1,'units','normalized','pos',[15/xw 120/yw 500/xw 450/yw]);


%  Reflections
uicontrol('parent',tracksMatchPanel,'fontunits', 'normalized','FontSize',.4,'units','normalized','Style','text',...
            'position',[.03 .89 .1 .1],'String','refl','fontweight','bold');

%  track before interaction
 uicontrol('parent',tracksMatchPanel,'fontunits', 'normalized','FontSize',.4,'units','normalized','Style','text',...
            'position',[.13 .89 .11 .1],'String','pre','fontweight','bold');

%  after, manual
uicontrol('parent',tracksMatchPanel,'fontunits', 'normalized','FontSize',.4,'units','normalized','Style','text',...
            'position',[.24 .89 .1 .1],'String','post','fontweight','bold');
        
% make controls
increment = .08;
for ii = 1:10
    reflection_radio(ii) = uicontrol('parent',tracksMatchPanel,'fontunits', 'normalized','FontSize',.4,'units','normalized','Style','rad',...
    'position',[.06 .928-increment*ii .09 .09],'Value',0,'Callback', @frm_num_rad_call,'visible','on');
end


for ii =  1:10
tracks_num_text(ii) = uicontrol('parent',tracksMatchPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
    'position',[.14 .932-increment*ii .08 .07],'String',ii,'ForegroundColor',clrlist{ii},'visible','on');
end


% manual track number
for ii = 1:10
manual_num_edit(ii) = uicontrol('parent',tracksMatchPanel,'fontunits', 'normalized','FontSize',.55,'units','normalized','Style','edit',...
    'position',[.25 .94-increment*ii .08 .07],'String',ii,'ForegroundColor',clrlist{ii},'callback',@ManulTrack_call,'visible','on');
end

        
% next button
NextButton = uicontrol('parent',tracksMatchPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
            'Position',[.79 .89 .21 .1],'Style','pushbutton','Enable','on','String','Next >','Callback',@Next_call);
if numel(cil)==1
    set(NextButton,'Enable','off');
end
        
PrevButton = uicontrol('parent',tracksMatchPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[.575 .89 .21 .1],'Style','pushbutton','Enable','off','String','< Prev','Callback',@Prev_call);

stopBNFButton = uicontrol('parent',tracksMatchPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[.75 .15 .21 .1],'Style','pushbutton','Enable','on','String','stop BNF','Callback',@BNF_call);

doneButton = uicontrol('parent',tracksMatchPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[.75 .03 .21 .1],'Style','pushbutton','Enable','on','String','Done','Callback',@done_call);

save_radio = uicontrol('parent',tracksMatchPanel,'fontunits', 'normalized','FontSize',.4,'units','normalized','Style','rad',...
    'position',[.55 .03 .21 .1],'Value',0,'visible','on','string','save f');

joinButton = uicontrol('parent',tracksMatchPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[.75 .27 .21 .1],'Style','pushbutton','Enable','on','String','Join','Callback',@joinInteraction);

intNum = uicontrol('parent',tracksMatchPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[.45 .89 .1 .1],'Style','edit','String','1','Callback',@intNum_call);

dropButton = uicontrol('parent',tracksMatchPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[.75 .41 .21 .1],'Style','pushbutton','Enable','on','String','Drop','Callback',@dropInteraction);

butcolor = get(dropButton,'BackgroundColor');
% 
% droppedButton = uicontrol('parent',tracksMatchPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
%     'Position',[.53 .41 .20 .1],'Style','pushbutton','Enable','off','String',' ','BackgroundColor', [1 1 1]);

AddButton = uicontrol('parent',tracksMatchPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[.75 .53 .21 .1],'Style','pushbutton','Enable','off','String','Add','Callback',@AddFly);

DeleteButton = uicontrol('parent',tracksMatchPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[.75 .645 .21 .1],'Style','pushbutton','Enable','on','String','del-int','Callback',@DelInt);


FlyNum = uicontrol('parent',tracksMatchPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[.63 .53 .1 .1],'Style','edit','String','NaN','Callback',@FlyNum_call);

FlipButton = uicontrol('parent',tracksMatchPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[.75 .75 .21 .1],'Style','pushbutton','Enable','on','String','Flip','Callback',@FlipTracks);

EditedButton = uicontrol('parent',tracksMatchPanel,'fontunits', 'normalized','FontSize',.5,'units','normalized',...
    'Position',[.5 .75 .21 .1],'Style','pushbutton','Enable','off','String','edit','BackgroundColor', [1 1 1]);

% % insert an explanation for the flips
% uicontrol('parent',tracksMatchPanel,'fontunits', 'normalized','FontSize',.4,'units','normalized','Style','text',...
%     'position',[.15 .03 .3 .1],'Value',0,'visible','on','string','Flip the parts after collision.');




if playBNF
    set(stopBNFButton,'string','stop BNF')
else
    set(stopBNFButton,'string','start BNF')
end

% join interactions
joinInteraction


%% parameters pane; 
        ParametersPanel = uipanel('parent', fSFW,'Title','Parameters', 'fontunits', 'normalized','FontSize',.1,'units','normalized','pos',[15/xw 25/yw 500/xw 100/yw]);
        


% play length 
uicontrol('parent',ParametersPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
            'position',[.01 .5 .15 .35],'String','play-t:');
uicontrol('parent',ParametersPanel,'fontunits', 'normalized','FontSize',.4,'units','normalized','Style','text',...
            'position',[.25 .5 .1 .35],'String','sec');
playlen_edit = uicontrol('parent',ParametersPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','style','edit',...
            'position',[.15 .52 .1 .35],'string',num2str(track_play_length),'callback',@playlen_call);
        
uicontrol('parent',ParametersPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
            'position',[.01 .1 .15 .35],'String','join:');
uicontrol('parent',ParametersPanel,'fontunits', 'normalized','FontSize',.4,'units','normalized','Style','text',...
            'position',[.25 .1 .1 .35],'String','points');
joindist_edit = uicontrol('parent',ParametersPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','style','edit',...
            'position',[.15 .12 .1 .35],'string',num2str(joint_int_length),'callback',@joindist_call);
        

% value watch length
uicontrol('parent',ParametersPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','Style','text',...
            'position',[.65 .49 .2 .35],'String','val-plot-len:');
uicontrol('parent',ParametersPanel,'fontunits', 'normalized','FontSize',.4,'units','normalized','Style','text',...
            'position',[.925 .45 .1 .35],'String','sec');
valplot_edit = uicontrol('parent',ParametersPanel,'fontunits', 'normalized','FontSize',.6,'units','normalized','style','edit',...
            'position',[.85 .53 .1 .35],'string',num2str(f.value_watch_length),'callback',@valplotlen_call);

%% graph axes
lnlist = {'k','r','b','m','g','c','y','k:','r:','b:','m:','g:','c:','y:'};
ax1 = axes('Position',[0.55 0.13 0.4 0.3]);
hold on
rec1 = rectangle('position',[0 0 0 0],'facecolor',[.8 .8 .8],'edgecolor','none');
for pn = 1:14
    areaplot(pn) = plot(ax1,NaN,NaN,lnlist{pn},'LineWidth',2);
    areaplotm(pn) =  plot(ax1,NaN,NaN,[clrlist{pn},'--'],'LineWidth',3);
    areaplots1(pn) =  plot(ax1,NaN,NaN,[clrlist{pn},'--'],'LineWidth',1);
    areaplots2(pn) =  plot(ax1,NaN,NaN,[clrlist{pn},'--'],'LineWidth',1);
end

title('area')
xlabel('frame #')
axis tight

ax2 = axes('Position',[0.55 0.6 0.4 0.3]);
hold on
rec2 = rectangle('position',[0 0 0 0],'facecolor',[.8 .8 .8],'edgecolor','none');
for pn = 1:14
    speedplot(pn) = plot(ax2,NaN,NaN,lnlist{pn},'LineWidth',2);
    speedplotm(pn) =  plot(ax2,NaN,NaN,[clrlist{pn},'--'],'LineWidth',3);
    speedplots1(pn) =  plot(ax2,NaN,NaN,[clrlist{pn},'--'],'LineWidth',1);
    speedplots2(pn) =  plot(ax2,NaN,NaN,[clrlist{pn},'--'],'LineWidth',1);
end

title('speed')
axis tight
% xlabel('frame #')


%% initialize
this_int = 1;
these_frames = cil{1}(:,1);
these_flies = nonzeros(unique(cil{1}(:,2:end)));
these_reflections = f.reflection_status(these_flies,these_frames(1));

% uodate info board
set(infoboard,'string',[num2str(1),'/',num2str(numel(cil)),' Interaction. Flies: ',mat2str(these_flies),'. Frames: ',num2str(these_frames(1)),...
    ':',num2str(these_frames(end)),'.']);

setErrorMsg;
refreshIntPanel;
plotFlyTrack;
getValueStats;

% set the buttons
if is_list_edited(this_int)
    set(EditedButton,'string','edited','BackgroundColor','g');
else
    set(EditedButton,'string','edit','BackgroundColor',[1 1 1]);
end
if is_list_dropped(this_int)
    set(dropButton,'string','un-drop','BackgroundColor','g');
else
    set(dropButton,'string','Drop','BackgroundColor',butcolor);
end
if is_list_flipped(this_int)
    set(FlipButton,'string','un-flip','BackgroundColor','g');
else
    set(FlipButton,'string','Flip','BackgroundColor',butcolor);
end
if is_list_deleted(this_int)
    set(DeleteButton,'string','un-delete','BackgroundColor','g');
else
    set(DeleteButton,'string','del-int','BackgroundColor',butcolor);
end


%% functions

function [] = setErrorMsg(~,~)
    error_msg = '';
    % clear the board first
    set(errorboard,'string',' ');
    for erin = 1:length(these_flies)
        if any(f.tracking_info.error_code(these_flies(erin),these_frames)>0)
            errcode = nonzeros(unique(f.tracking_info.error_code(these_flies(erin),these_frames)));
            for ecin = 1:length(errcode)
                error_msg = [error_msg,' Fly:',num2str(these_flies(erin)),':',f.error_def{errcode(ecin)}];
            end
        end
    end
    if ~strcmp(error_msg,'')
        set(errorboard,'string',error_msg);
    end
end

function [] = updateList(~,~)
    % go over all further list elements and change the fly ids
    IDs = edited_tracks{this_int};
    
    % set all fly ids to negative
    for inum = 1:size(IDs,1)
        for i = this_int+1:numel(cil)
            for j = 2:size(cil{i},2)
                cil{i}(cil{i}(:,j)==IDs(inum,1),j) = -IDs(inum,1);
            end
        end
    end
    
    % now replace them
    for inum = 1:size(IDs,1)
        for i = this_int+1:numel(cil)
            for j = 2:size(cil{i},2)
                cil{i}(cil{i}(:,j)==(-IDs(inum,1)),j) = IDs(inum,2);
            end
        end
    end
end



function [] = FlipTracks(~,~)
    
    playBNF = false;
    
    % get button status
        % get button status
    if strcmp(get(FlipButton,'string'),'Flip')
        is_list_flipped(this_int) = 1;
        set(FlipButton,'string','un-flip','BackgroundColor','g');
    else
        is_list_flipped(this_int) = 0;
        set(FlipButton,'string','Flip','BackgroundColor',butcolor);
    end
    
    if length(these_flies)==2
        values = zeros(length(these_flies),2);
        reflections = zeros(length(these_flies),2);
        values(:,1) = these_flies;
        reflections(:,1) = these_reflections;

        for i = 1:length(these_flies)
            reflections(i,2) = get(reflection_radio(i),'Value');
        end
        if length(these_flies)==2
            temp = get(manual_num_edit(1),'String');
            set(manual_num_edit(1),'String',get(manual_num_edit(2),'String'));
            set(manual_num_edit(2),'String',temp);
        end

        % manual track number
        for i = 1:length(these_flies)
            values(i,2) = str2num(get(manual_num_edit(i),'String'));
        end

        % make comparison and set the corrections
        if isequal(reflections(:,1),reflections(:,2))
            edited_reflections(this_int) = {[]};
        else
            edited_reflections(this_int) = {reflections};
        end
        if isequal(values(:,1),values(:,2))
            edited_tracks(this_int) = {[]};
        else
            edited_tracks(this_int) = {values};
        end
    else
        getValues;
        if isempty(edited_tracks{this_int})
            values = zeros(length(these_flies),2);
            values(:,1) = these_flies;
            values(:,2) = these_flies;

        else
            values = edited_tracks{this_int};
        end
        if isempty(edited_reflections{this_int})
            reflections = zeros(length(these_flies),2);
            reflections(:,1) = these_reflections;
            reflections(:,2) = these_reflections;
        else
            reflections = edited_reflections{this_int};
        end
    end

    % if different go over and flip the values and tracks
    if ~isempty(edited_tracks(this_int))
        temp = tracking_info;
        for i = 1:length(these_flies)
            fields = fieldnames(tracking_info);
            for fnm = 1:numel(fields)
                if size(tracking_info.(fields{fnm}),2)== f.nframes
                    if ismatrix(tracking_info.(fields{fnm}))
                        tracking_info.(fields{fnm})(values(i,2),round((these_frames(1)+these_frames(end))/2):end) = temp.(fields{fnm})(values(i,1),round((these_frames(1)+these_frames(end))/2):end);
                    elseif ndims(tracking_info.(fields{fnm}))==3
                        tracking_info.(fields{fnm})(values(i,2),round((these_frames(1)+these_frames(end))/2):end,:) = temp.(fields{fnm})(values(i,1),round((these_frames(1)+these_frames(end))/2):end,:);
                    end
                end

            end
        end
    end

    if ~isempty(edited_tracks(this_int))
        for i = 1:length(these_flies)
           f.reflection_status(values(i,2),these_frames(end):end) = reflections(i,2);
        end
    end
    % refresh the object
    f.tracking_info = tracking_info;
    % now replot and play
    refreshIntPanel;
    plotFlyTrack;
    getValueStats;
    updateList;
    playBNF = true;
    set(stopBNFButton,'String','stop BNF') % starts acquiring


    % set the list as edited
    is_list_edited(this_int) = 1;
    set(EditedButton,'string','edited','BackgroundColor','g');

    % update the rest of the list
   
    playBackNForth;
    
        
end


function [] = intNum_call(~,~)
    getValues
    playBNF = false;
    this_int = str2num(get(intNum,'string'));
    if this_int>numel(cil)
        this_int = numel(cil);
    elseif this_int<1
        this_int = 1;
    end
    if this_int==numel(cil)
        set(NextButton,'Enable','off')
    end
    if this_int>=2
        set(PrevButton,'Enable','on')
    end
    if this_int==1
        set(PrevButton,'Enable','off')
    end
    if this_int<numel(cil)
        set(NextButton,'Enable','on')
    end
    these_frames = cil{this_int}(:,1);
    these_flies = nonzeros(unique(cil{this_int}(:,2:end)));
    these_reflections = f.reflection_status(these_flies,these_frames(1));
    if is_list_edited(this_int)
        set(EditedButton,'string','edited','BackgroundColor','g');
    else
        set(EditedButton,'string','edit','BackgroundColor',butcolor);
    end
    if is_list_dropped(this_int)
        set(dropButton,'string','dropped','BackgroundColor','g');
    else
        set(dropButton,'string','Drop','BackgroundColor',butcolor);
    end
    
    if is_list_flipped(this_int)
        set(FlipButton,'string','un-flip','BackgroundColor','g');
    else
        set(FlipButton,'string','Flip','BackgroundColor',butcolor);
    end
    if is_list_deleted(this_int)
        set(DeleteButton,'string','un-delete','BackgroundColor','g');
    else
        set(DeleteButton,'string','del-int','BackgroundColor',butcolor);
    end
    
    % update info board
    set(infoboard,'string',[num2str(this_int),'/',num2str(numel(cil)),' Interaction. Flies: ',mat2str(these_flies),'. Frames: ',num2str(these_frames(1)),...
    ':',num2str(these_frames(end)),'.']);
    
    refreshIntPanel;
    plotFlyTrack;
    getValueStats;
    playBNF = true;
    set(stopBNFButton,'String','stop BNF') % starts acquiring
    playBackNForth;


end

function [] = FlyNum_call(~,~)
    if ~isnan(get(FlyNum,'string'))
        flynum = str2num(get(FlyNum,'string'));
        set(AddButton,'enable','on');
    end
end


function [] = valplotlen_call(~,~)
        f.value_watch_length = str2double(get(valplot_edit,'string'));
        getValueStats;
end


function [] = AddFly(~,~)
    playBNF = false;
    these_flies = [these_flies;flynum];
    set(FlyNum,'string','NaN');
    set(AddButton,'enable','off');
    these_reflections = f.reflection_status(these_flies,these_frames(1));
    refreshIntPanel
end


function [] = playlen_call(~,~)
    track_play_length = str2double(get(playlen_edit,'string'));
    play_buffer = round(track_play_length*f.ExpParam.fps);
end

function [] = dropInteraction(~,~)
    playBNF = false;
    % get button status
    if strcmp(get(dropButton,'string'),'Drop')
        is_list_dropped(this_int) = 1;
        set(dropButton,'string','un-drop','BackgroundColor','g');
    else
        is_list_dropped(this_int) = 0;
        set(dropButton,'string','Drop','BackgroundColor',butcolor);
    end
end


function [] = DelInt(~,~)
    playBNF = false;
    % get button status
    if strcmp(get(DeleteButton,'string'),'del-int')
        is_list_deleted(this_int) = 1;
        set(DeleteButton,'string','un-delete','BackgroundColor','g');
    else
        is_list_deleted(this_int) = 0;
        set(DeleteButton,'string','del_int','BackgroundColor',butcolor);
    end
end

function [] = joindist_call(~,~)
    playBNF = false;
joint_int_length = str2double(get(joindist_edit,'string'));

end

function [] = ManulTrack_call(~,~)
    
end

function [] = frm_num_rad_call(~,~)
    
end

function [] = joinInteraction(~,~)
    playBNF = false;
    % join interactions
    ciln = cil(1);
    cilnind = 1;
    tin = 2;
    while tin <=numel(cil) 
        frames1 = ciln{cilnind}(:,1);
        flies1 = nonzeros(unique(ciln{cilnind}(:,2:end)));

        frames2 = cil{tin}(:,1);
        flies2 = nonzeros(unique(cil{tin}(:,2:end)));
        if (~isempty(intersect(frames1,frames2))||((frames2(1)-frames1(end))<=joint_int_length))&&...
                ~isempty(intersect(flies1,flies2))
            nc1 = size(ciln{cilnind},2);
            nc2 = size(cil{tin},2);
            if nc2>nc1
                valpac1 = ciln{cilnind};
                valpac1(:,end+1:end+nc2-nc1) = 0;
                valpac2 = cil{tin};
            elseif nc2<nc1
                valpac2 = cil{tin};
                valpac2(:,end+1:end+nc1-nc2) = 0;
                valpac1 = ciln{cilnind};
            else
                valpac2 = cil{tin};
                valpac1 = ciln{cilnind};
            end
            ciln(cilnind) = {vertcat(valpac1,valpac2)};
            tin = tin + 1;
        else
            ciln(cilnind+1) = cil(tin);
            cilnind = cilnind + 1;
            tin = tin + 1;
        end
    end
    cntr = 1;
    for i = 1:numel(ciln)
        flies = nonzeros(unique(ciln{cntr}(:,2:end)));
        if length(flies)>7
            ciln(cntr) = [];
        else
            cntr = cntr + 1;
        end
    end
    cil = ciln;
end

function [] = done_call(~,~)
    playBNF = false;
    f.edited_tracks = edited_tracks; 
    f.edited_reflections = edited_reflections;
    f.is_list_dropped = is_list_dropped;
    f.is_list_deleted = is_list_deleted;
    f.is_list_flipped = is_list_flipped;
    f.crowd_interaction_list = cil;
    QuitsortFlyWalkCallback
end

function [] = getValues(~,~)
    values = zeros(length(these_flies),2);
    reflections = zeros(length(these_flies),2);
    values(:,1) = these_flies;
    reflections(:,1) = these_reflections;

    for i = 1:length(these_flies)
        reflections(i,2) = get(reflection_radio(i),'Value');
    end
    
    % manual track number
    for i = 1:length(these_flies)
        values(i,2) = str2num(get(manual_num_edit(i),'String'));
    end
    
    % make comparison and set the corrections
    if isequal(reflections(:,1),reflections(:,2))
        edited_reflections(this_int) = {[]};
    else
        edited_reflections(this_int) = {reflections};
    end
    if isequal(values(:,1),values(:,2))
        edited_tracks(this_int) = {[]};
    else
        edited_tracks(this_int) = {values};
    end

end

function [] = Next_call(~,~)
    % change if any reflection is changed
    for i = 1:length(these_flies)
        if ~these_reflections(i)== get(reflection_radio(i),'Value')
            f.reflection_status(these_flies(i),these_frames(end):end) = get(reflection_radio(i),'Value');
        end
    end
    
    % set previous interaction to edited
    is_list_edited(this_int) = 1;
    getValues
    playBNF = false;
    this_int = this_int + 1;
    if is_list_edited(this_int)
        set(EditedButton,'string','edited','BackgroundColor','g');
    else
        set(EditedButton,'string','edit','BackgroundColor',butcolor);
    end
    if is_list_dropped(this_int)
        set(dropButton,'string','dropped','BackgroundColor','g');
    else
        set(dropButton,'string','Drop','BackgroundColor',butcolor);
    end
    if is_list_flipped(this_int)
        set(FlipButton,'string','un-flip','BackgroundColor','g');
    else
        set(FlipButton,'string','Flip','BackgroundColor',butcolor);
    end
    if is_list_deleted(this_int)
        set(DeleteButton,'string','un-delete','BackgroundColor','g');
    else
        set(DeleteButton,'string','del-int','BackgroundColor',butcolor);
    end
   
    if this_int==numel(cil)
        set(NextButton,'Enable','off')
    end
    if this_int>=2
        set(PrevButton,'Enable','on')
    end
    % set edit number
    set(intNum,'string',num2str(this_int));
    
    these_frames = cil{this_int}(:,1);
    these_flies = nonzeros(unique(cil{this_int}(:,2:end)));
    these_reflections = f.reflection_status(these_flies,these_frames(1));
    
    % update info board
    set(infoboard,'string',[num2str(this_int),'/',num2str(numel(cil)),' Interaction. Flies: ',mat2str(these_flies),'. Frames: ',num2str(these_frames(1)),...
    ':',num2str(these_frames(end)),'.']);
    
    setErrorMsg;
    refreshIntPanel;
    plotFlyTrack;
    getValueStats;
    playBNF = true;
    set(stopBNFButton,'String','stop BNF') % starts acquiring
    playBackNForth;


end

function [] = Prev_call(~,~)
    
    getValues
%     these_flies = [];
    playBNF = false;
    this_int = this_int - 1;
    
    if is_list_edited(this_int)
        set(EditedButton,'string','edited','BackgroundColor','g');
    else
        set(EditedButton,'string','edit','BackgroundColor',butcolor);
    end
    if is_list_dropped(this_int)
        set(dropButton,'string','dropped','BackgroundColor','g');
    else
        set(dropButton,'string','Drop','BackgroundColor',butcolor);
    end
    if is_list_flipped(this_int)
        set(FlipButton,'string','un-flip','BackgroundColor','g');
    else
        set(FlipButton,'string','Flip','BackgroundColor',butcolor);
    end
    if is_list_deleted(this_int)
        set(DeleteButton,'string','un-delete','BackgroundColor','g');
    else
        set(DeleteButton,'string','del-int','BackgroundColor',butcolor);
    end
      
    if this_int==1
        set(PrevButton,'Enable','off')
    end
    if this_int<length(cil)
        set(NextButton,'Enable','on')
    end
    % set edit number
    set(intNum,'string',num2str(this_int));
    
    these_frames = cil{this_int}(:,1);
    these_flies = nonzeros(unique(cil{this_int}(:,2:end)));
    these_reflections = f.reflection_status(these_flies,these_frames(1));
    
    % update info board
    set(infoboard,'string',[num2str(this_int),'/',num2str(numel(cil)),' Interaction. Flies: ',mat2str(these_flies),'. Frames: ',num2str(these_frames(1)),...
    ':',num2str(these_frames(end)),'.']);

    setErrorMsg;
    refreshIntPanel;
    plotFlyTrack;
    getValueStats;
    playBNF = true;
    set(stopBNFButton,'String','stop BNF') % starts acquiring
    playBackNForth;

end

function [] = BNF_call(~,~)
    
    if strcmp(get(stopBNFButton,'String'),'stop BNF') % 
        playBNF = false;
        set(stopBNFButton,'String','start BNF') % change status 
    else
        playBNF = true;
        set(stopBNFButton,'String','stop BNF') % starts acquiring
        playBackNForth;
    end
end
        
        
        
        
function [] = plotFlyTrack(~,~)
   
    % clear all plot data
    for nn = 1:14
        f.plot_handles.tracks(nn).XData = NaN;
        f.plot_handles.tracks(nn).YData = NaN;
    end
   
 % get trajectories
    track_play_init = these_frames(1)-play_buffer;
    if track_play_init<1
        track_play_init = 1;
    end
    track_play_end = these_frames(end)+play_buffer;
    if track_play_end>f.nframes
        track_play_end = f.nframes;
    end
    tracksx = tracking_info.x(these_flies,track_play_init:track_play_end);
    tracksy = tracking_info.y(these_flies,track_play_init:track_play_end);
    
    flysize = max(max(tracking_info.majax(these_flies,these_frames(1):these_frames(end))));
    
    % interaction positions
    intx = nanmean(nanmean(tracking_info.x(these_flies,these_frames(1):these_frames(end))));
    inty = nanmean(nanmean(tracking_info.y(these_flies,these_frames(1):these_frames(end))));
    
    track_xlim = [intx-3*flysize,intx+3*flysize];
    track_ylim = [inty-3*flysize,inty+3*flysize];
    f.current_frame = these_frames(1);
    f.operateOnFrame;
    
    % activate the figure 
    set(f.plot_handles.ax,'xlim',track_xlim,'ylim',track_ylim)
    for tnum = 1:length(these_flies)
        f.plot_handles.tracks(tnum+7).XData = tracksx(tnum,1+play_buffer:end-play_buffer);
        f.plot_handles.tracks(tnum+7).YData = tracksy(tnum,1+play_buffer:end-play_buffer);
        tracksx(tnum,1+play_buffer:end-play_buffer) = NaN;
        tracksy(tnum,1+play_buffer:end-play_buffer) = NaN;
        f.plot_handles.tracks(tnum).XData = tracksx(tnum,:);
        f.plot_handles.tracks(tnum).YData = tracksy(tnum,:);
    end
    
end

function []=playBackNForth(~,~)
    
% reset markers
for nn = 1:10
    f.plot_handles.track_marker(nn).XData = NaN;
    f.plot_handles.track_marker(nn).YData = NaN;
end
    
play_lim = 1;
play_num = 1;

track_play_init = these_frames(1)-play_buffer;
if track_play_init<1
    track_play_init = 1;
end
track_play_end = these_frames(end)+play_buffer;
if track_play_end>f.nframes
    track_play_end = f.nframes;
end

    while (play_num <= play_lim)&&playBNF
        for i = track_play_init:(track_play_end-1)
            if playBNF
                f.current_frame = i;
                f.operateOnFrame;
                for tnum = 1:length(these_flies)
                    f.plot_handles.track_marker(tnum).XData = tracking_info.x(these_flies(tnum),i+1);
                    f.plot_handles.track_marker(tnum).YData = tracking_info.y(these_flies(tnum),i+1);
                end
            end
        end

        for i = (track_play_end-1):-1:track_play_init
            if playBNF
                f.current_frame = i;
                f.operateOnFrame;
                for tnum = 1:length(these_flies)
                    f.plot_handles.track_marker(tnum).XData = tracking_info.x(these_flies(tnum),i+1);
                    f.plot_handles.track_marker(tnum).YData = tracking_info.y(these_flies(tnum),i+1);
                end
            end
        end
        play_num= play_num + 1;
    end
    playBNF = 0;
    if isvalid(stopBNFButton)
        set(stopBNFButton,'String','start BNF') % change status
    end

end

function [] = getValueStats(~,~)
    if ~isvalid(areaplot)
        return
    end
%     fly_area = zeros(length(these_flies),4);
%     fly_majax = zeros(length(these_flies),4);
%     fly_minax = zeros(length(these_flies),4);
%     fly_speed = zeros(length(these_flies),4);
    for rpn  = 1:14
        areaplot(rpn).YData = NaN;
        areaplot(rpn).XData = NaN;
        speedplot(rpn).YData = NaN;
        speedplot(rpn).XData = NaN;
        speedplotm(rpn).XData =  NaN;
        speedplotm(rpn).YData =  NaN;
        speedplots1(rpn).XData =  NaN;
        speedplots1(rpn).YData =  NaN;
        speedplots2(rpn).XData =  NaN;
        speedplots2(rpn).YData = NaN;
        areaplotm(rpn).XData =  NaN;
        areaplotm(rpn).YData =  NaN;
        areaplots1(rpn).XData =  NaN;
        areaplots1(rpn).YData =  NaN;
        areaplots2(rpn).XData =  NaN;
        areaplots2(rpn).YData = NaN;
    end
%     cla(ax1)
%     cla(ax2)
    maxs = 0;
    maxa = 0;
    mins = 100;
    mina = 100;
    % these values are [mean_before, std_before, mean_after, std_after]
    for i = 1:length(these_flies)
        frmprev = these_frames(1)-round(f.value_watch_length*f.ExpParam.fps);
        if frmprev<1
            frmprev = 1;
        end
        frmafter = these_frames(end)+round(f.value_watch_length*f.ExpParam.fps);
        if frmafter>f.nframes
            frmafter = f.nframes;
        end
        fly_area = (tracking_info.area(these_flies(i),frmprev:frmafter));
%         fly_majax = (tracking_info.majax(these_flies(i),frmprev:frmafter));
%         fly_minax = (tracking_info.minax(these_flies(i),frmprev:frmafter));
        fly_speed = (sqrt(diff(tracking_info.x(these_flies(i),frmprev:frmafter)).^2+...
            diff(tracking_info.y(these_flies(i),frmprev:frmafter)).^2));
                   
%         plot(ax1,[frmprev,frmafter],fly_area,lnlist{pn},'LineWidth',3);
%         plot(ax2,[frmprev,frmafter],fly_speed,lnlist{pn},'LineWidth',3);
        areaplot(i).XData =  frmprev:frmafter;
        areaplot(i).YData = fly_area;
        maxa = max(maxa,max(fly_area));
        mina = min(mina,min(fly_area));
        
        speedplot(i).XData =  frmprev:frmafter-1;
        speedplot(i).YData = fly_speed;
        maxs = max(maxs,max(fly_speed));
        mins = min(mins,min(fly_speed));

       
        fly_areaM = [mean(tracking_info.area(these_flies(i),frmprev:these_frames(1))),...
            std(tracking_info.area(these_flies(i),frmprev:these_frames(1))),...
            mean(tracking_info.area(these_flies(i),these_frames(end):frmafter)),...
            std(tracking_info.area(these_flies(i),these_frames(end):frmafter))];
%         fly_majaxM = [mean(tracking_info.majax(these_flies(i),frmprev:these_frames(1))),...
%             std(tracking_info.majax(these_flies(i),frmprev:these_frames(1))),...
%             mean(tracking_info.majax(these_flies(i),these_frames(end):frmafter)),...
%             std(tracking_info.majax(these_flies(i),these_frames(end):frmafter))];
%         fly_minaxM = [mean(tracking_info.minax(these_flies(i),frmprev:these_frames(1))),...
%             std(tracking_info.minax(these_flies(i),frmprev:these_frames(1))),...
%             mean(tracking_info.minax(these_flies(i),these_frames(end):frmafter)),...
%             std(tracking_info.minax(these_flies(i),these_frames(end):frmafter))];
        fly_speedM = [mean(sqrt(diff(tracking_info.x(these_flies(i),frmprev:these_frames(1))).^2+...
            diff(tracking_info.y(these_flies(i),frmprev:these_frames(1))).^2)),...
            std(sqrt(diff(tracking_info.x(these_flies(i),frmprev:these_frames(1))).^2+...
            diff(tracking_info.y(these_flies(i),frmprev:these_frames(1))).^2)),...
            mean(sqrt(diff(tracking_info.x(these_flies(i),these_frames(end):frmafter)).^2+...
            diff(tracking_info.y(these_flies(i),these_frames(end):frmafter)).^2)),...
            std(sqrt(diff(tracking_info.x(these_flies(i),these_frames(end):frmafter)).^2+...
            diff(tracking_info.y(these_flies(i),these_frames(end):frmafter)).^2))];
        prifrm = frmprev:these_frames(1);
        frm = these_frames(1):these_frames(end);
        postfrm = these_frames(end):frmafter;
        speedplotm(i).XData =  [prifrm,frm,postfrm];
        speedplotm(i).YData =  [ones(size(prifrm))*fly_speedM(1),NaN(size(frm)),ones(size(prifrm))*fly_speedM(3)];
        speedplots1(i).XData =  [prifrm,frm,postfrm];
        speedplots1(i).YData =  [ones(size(prifrm))*(fly_speedM(1)-fly_speedM(2)),NaN(size(frm)),ones(size(prifrm))*(fly_speedM(3)-fly_speedM(4))];
        speedplots2(i).XData =  [prifrm,frm,postfrm];
        speedplots2(i).YData =  [ones(size(prifrm))*(fly_speedM(1)+fly_speedM(2)),NaN(size(frm)),ones(size(prifrm))*(fly_speedM(3)+fly_speedM(4))];
        
        areaplotm(i).XData =  [prifrm,frm,postfrm];
        areaplotm(i).YData =  [ones(size(prifrm))*fly_areaM(1),NaN(size(frm)),ones(size(prifrm))*fly_areaM(3)];
        areaplots1(i).XData =  [prifrm,frm,postfrm];
        areaplots1(i).YData =  [ones(size(prifrm))*(fly_areaM(1)-fly_areaM(2)),NaN(size(frm)),ones(size(prifrm))*(fly_areaM(3)-fly_areaM(4))];
        areaplots2(i).XData =  [prifrm,frm,postfrm];
        areaplots2(i).YData =  [ones(size(prifrm))*(fly_areaM(1)+fly_areaM(2)),NaN(size(frm)),ones(size(prifrm))*(fly_areaM(3)+fly_areaM(4))];
        
    end
    
    slimm = [0  max(fly_speedM(1)+fly_speedM(2),fly_speedM(3)+fly_speedM(4))]*1.2;
    rec1.Position = [these_frames(1) mina these_frames(end)-these_frames(1) maxa-mina];
    rec2.Position = [these_frames(1) mins these_frames(end)-these_frames(1) maxs-mins];
    if slimm(2)==0||isnan(slimm(2))
        slimm(2) = 10;
    end
    set(ax2,'Ylim',slimm)
    
end
        


function []=refreshIntPanel(~,~)
    
    set(reflection_radio(:),'visible','off')
    set(tracks_num_text(:),'visible','off')
    set(manual_num_edit(:),'visible','off')

    
    for i = 1:length(these_flies)
        set(reflection_radio(i),'Value',these_reflections(i),'visible','on');
    end
    
    for i = 1:length(these_flies)
        set(tracks_num_text(i),'String',mat2str(these_flies(i)),'visible','on');
    end
    
    
    % manual track number
    for i = 1:length(these_flies)
        set(manual_num_edit(i),'String',mat2str(these_flies(i)),'visible','on');
    end
    
    fly_areaM = zeros(length(these_flies),4);
%     fly_majaxM = zeros(length(these_flies),4);
%     fly_minaxM = zeros(length(these_flies),4);
    fly_speedM = zeros(length(these_flies),4);
    
    
end



function [] = QuitsortFlyWalkCallback(~,~)
%    selection = questdlg('Are you sure you want to quit sortFlyWalk?','Confirm quit.','Yes','No','Yes'); 
   selection = 'Yes'; 
   switch selection 
      case 'Yes'
          playBNF = 0;
          pause(.1)
          set(stopBNFButton,'String','start BNF') % change status 
          % clear all plot data
            for nn = 1:10
                f.plot_handles.tracks(nn).XData = NaN;
                f.plot_handles.tracks(nn).YData = NaN;
                f.plot_handles.track_marker(nn).XData = NaN;
                f.plot_handles.track_marker(nn).YData = NaN;
            end
            
            % update the structure
            f.edited_tracks = edited_tracks;
            f.edited_reflections = edited_reflections;
            f.is_list_dropped = is_list_dropped;
            f.is_list_edited = is_list_edited;
            f.is_list_deleted = is_list_deleted;
            f.is_list_flipped = is_list_flipped;

            % reset axis
            set(f.plot_handles.ax,'xlim',xlimo,'ylim',ylimo)

            % reset visualization
            f.label_flies = oa(1);         % show fly labels next to each fly
            f.mark_flies = oa(2);       % show fly markers
            f.show_orientations = oa(3);      % show orientations, 0: do not show, 1: orientations, 2: heading, 3: both
            f.show_trajectories = oa(4);      % show tracks with a tail length of trajectory_vis_length 
            f.show_antenna = oa(5);
            f.mark_lost = oa(6);
            
            if get(save_radio,'value')
                f.save;
            end

            delete(fSFW);

      case 'No'
      return 
   end
end


end





% VidNameGui
% VidNameGui is a GUI which is used to manually arrange the experimental
% video names for further analyses

function []  = VidNameGui(dir_path)
% if no filename is given then generate the default name
if nargin==0
    dir_path = [pwd,filesep];
end
expvidnames = {};
expvidnames_orig = {};
rows = [];
pathlist = {};
savetxt = 'expvid.names';
smthloaded = 0;

%% make GUI
scsz = get(0,'ScreenSize');
yw = 5.5*scsz(4)/7;
xw = scsz(3)/2;

f1 = figure('Position',[scsz(3)/7 scsz(4)/10 xw yw],'Name','VideoNames','Toolbar',...
    'figure','Menubar','none','NumberTitle','off','Resize','on'...
    ,'HandleVisibility','on','CloseRequestFcn',@closecallback);

%% parameters


% figure and object handles


% make the table
% Column names and column format
columnname = {'Video Name'};
columnformat = {[]};

% get video names in the folder
files = dir([dir_path,'*.avi']);
fileNames1 = {files.name}';
files = dir([dir_path,'*.mj2']);
fileNames = [fileNames1;{files.name}'];
% contruct pathlist
plt = repmat({''},numel(fileNames),1);
pathlist = [pathlist;plt];
% for flii = numel(filelist)+1:numel(filelist)+numel(allfiles)
%     filelist(flii) = {[dir_path,allfiles{flii}]};
% end


d = cell(numel(fileNames),1);


for i = 1:numel(fileNames)
    d(i,1) = fileNames(i);
end


% Create the uitable
t = uitable(f1,'Data', d,... 
            'ColumnName', columnname,...
            'units','normalized',...
            'ColumnFormat', columnformat,...
            'ColumnWidth', {xw/1.5},...
            'ColumnEditable', true,...
            'Fontsize', 11,...
            'RowName',[]);

% Set width and height
t.Position = [1/20 1/20 1/1.5 1*.9];
t.CellEditCallback = @checkentry;
t.CellSelectionCallback = @getrows;
expvidnames_orig = t.Data;

minscale= 0.05;
if yw<=708
    yw = 770;
end
       
donebutton = uicontrol(f1,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[3/4 minscale minscale*3 minscale],'Style','pushbutton','String','done!','Enable','on','Callback',@donecallback);

deletebutton = uicontrol(f1,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[3/4 125/yw minscale*3 minscale],'Style','pushbutton','String','delete','Enable','on','Callback',@deletecallback);

renamebutton = uicontrol(f1,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[3/4 200/yw minscale*3 minscale],'Style','pushbutton','String','rename','Enable','on','Callback',@renamecallback);

autorename_radio = uicontrol(f1,'fontunits', 'normalized','FontSize',.4,'units','normalized','Style','rad',...
    'position',[3/4 250/yw minscale*3 minscale],'String','Auto-Rename','fontweight','bold','Value',0);

mat_radio = uicontrol(f1,'fontunits', 'normalized','FontSize',.4,'units','normalized','Style','rad',...
    'position',[6.4/8 580/yw 70/xw minscale],'String','mat','fontweight','bold','Value',0,'Callback', @mat_rad_call);

vid_radio = uicontrol(f1,'fontunits', 'normalized','FontSize',.4,'units','normalized','Style','rad',...
    'position',[6.9/8 580/yw 70/xw minscale],'String','vid','fontweight','bold','Value',1,'Callback', @vid_rad_call);

browsedirbutton = uicontrol(f1,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[3/4 700/yw minscale*4 minscale],'Style','pushbutton','String','browse & add','Enable','on','Callback',@browsecallback);

saveas_text = uicontrol(f1,'fontunits', 'normalized','FontSize',.5,'units','normalized','Style','text',...
            'position',[3/4 650/yw minscale*4 minscale],'String','save as','fontweight','bold');
        
Aviname_edit = uicontrol(f1,'fontunits', 'normalized','FontSize',.4,'units','normalized','style','edit',...
            'position',[3/4 620/yw minscale*4 minscale],'string',savetxt);

loadbutton = uicontrol(f1,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[3/4 500/yw minscale*4 minscale],'Style','pushbutton','String','load saved','Enable','on','Callback',@loadcallback);
         
      



%%
function [] = donecallback(~,~)
   checkentry;
   
   % make pathlist
   for pi = 1:numel(pathlist)
       pathlist(pi) = {[pathlist{pi},expvidnames{pi}]};
   end
   % figure out which mode is selected for saving
   R = [get(mat_radio,'val'), get(vid_radio,'val')];  % Get state of radios.
   savetxt = get(Aviname_edit,'String');
    if R(1)==1 % mat selected unselect vid
        save([dir_path,savetxt,'.mat'],'pathlist','-v7.3');
    else % select vid
        save([dir_path,savetxt,'.mat'],'expvidnames','-v7.3');
    end

   selection = 'Yes';
   switch selection
      case 'Yes'
                delete(f1)

          try
                delete(f1)
          catch
          end
      case 'No'
      return 
   end
        
        
end

function [] = checkentry(~,~)
    % figure out entries
    expvidnames = t.Data;
    jj=1;
    while jj <= numel(expvidnames)
        if  isempty(expvidnames{jj})
            expvidnames(jj)=[];
            expvidnames_orig(jj)=[];
            pathlist(jj) = [];
        else            
            if get(autorename_radio,'val') % if auto rename selected rename
                if ~strcmp(expvidnames_orig{jj},expvidnames{jj})
                    if ~exist([pathlist{rows},expvidnames{rows}],'file')
                        % rename file
                        set(t,'Enable','off')
                        set(donebutton,'Enable','off')
                        set(deletebutton,'Enable','off')
                        set(renamebutton,'Enable','off')
    %                     movefile(expvidnames_orig{jj},expvidnames{jj})
    %                     renameall(expvidnames_orig{jj},expvidnames{jj})
                        renameall([pathlist{jj},expvidnames_orig{jj}],[pathlist{jj},expvidnames{jj}])
                        % update table
                        expvidnames_orig = expvidnames;
                        set(t,'Enable','on')
                        set(donebutton,'Enable','on')
                        set(deletebutton,'Enable','on')
                        set(renamebutton,'Enable','on')
                    else
                        % if file already exist do not move
                        expvidnames = expvidnames_orig;
                    end
                end
                
            end
        end
        jj = jj + 1;
    end
    % update table
    t.Data = expvidnames; 
        
end

function [] = getrows(~,ed)
    rows = ed.Indices(:,1);
%     rows = t.getSelectedRows;
end

function [] = mat_rad_call(~,~)
    R = [get(mat_radio,'val'), get(vid_radio,'val')];  % Get state of radios.

    if R(1)==1 % mat selected unselect vid
        set(vid_radio,'val',0);
        savetxt = 'expmat.names';
        set(Aviname_edit,'String',savetxt);
    else % select vid
        set(vid_radio,'val',1);
        savetxt = 'expvid.names';
        set(Aviname_edit,'String',savetxt);
    end
end

function [] = vid_rad_call(~,~)
    R = [get(mat_radio,'val'), get(vid_radio,'val')];  % Get state of radios.

    if R(2)==1 % vid selected unselect mat
        set(mat_radio,'val',0);
        savetxt = 'expvid.names';
        set(Aviname_edit,'String',savetxt);
    else % select mat
        set(mat_radio,'val',1);
        savetxt = 'expmat.names';
        set(Aviname_edit,'String',savetxt);
    end
end




function [] = browsecallback(~,~)
    [allfiles,path_name] = uigetfile({'*.mat';'*.avi';'*.mj2';'*.flywalk'},'MultiSelect','on'); % makes sure only avi files are chosen
    if ~iscell(allfiles)
        allfiles = {allfiles};
    end
    allfiles = allfiles';
    if ischar(allfiles{1})
        path_name = getRelPath(path_name,dir_path);
        % append names and paths
%         plt = {};
        plt = repmat(path_name,numel(allfiles),1);
        pathlist = [pathlist;plt];
        % get data from table
        expvidnames = t.Data;
        % append new filesnames
        expvidnames = [expvidnames;allfiles];
        expvidnames_orig = expvidnames;
        % update the table
        t.Data = expvidnames ;
        % set saving to mat file format
        set(vid_radio,'val',0);
        set(mat_radio,'val',1);
        if ~smthloaded
            savetxt = 'expmat.names';
        end
        set(Aviname_edit,'String',savetxt);
    end

end




function [] = loadcallback(~,~)
    % search for expvid.names and expmat.names
    if exist([dir_path,'expvid.names.mat'],'file')&&exist([dir_path,'expmat.names.mat'],'file')
        [allfiles,path_name] = uigetfile({'*names.mat'},'MultiSelect','off'); % makes sure only mat files are chosen
        % is it a vid or mat file list
        if strcmp(allfiles(4:6),'mat')
            pl=load([path_name,allfiles],'pathlist');
            pathlistl = pl.pathlist;
            expvidnamesl = cell(size(pathlistl));
            % parse it
            for pi = 1:numel(pathlistl)
                [p,n,e]=fileparts(pathlistl{pi});
                pathlistl(pi) = {[p,filesep]};
                expvidnamesl(pi) = {[n,e]};
            end
            % set saving to mat file format
            set(vid_radio,'val',0);
            set(mat_radio,'val',1);
            savetxt = 'expmat.names';
            smthloaded = 1; % set state to already loaded
            set(Aviname_edit,'String',savetxt);
            pathlist = [pathlist;pathlistl];
            expvidnames = [expvidnames;expvidnamesl];
        elseif strcmp(allfiles(4:6),'vid')
            evn=load([path_name,allfiles],'expvidnames');
            expvidnamesl = evn.expvidnames;
            pathlistl = repmat({dir_path},numel(expvidnamesl),1);
            % set saving to mat file format
            set(vid_radio,'val',1);
            set(mat_radio,'val',0);
            savetxt = 'expvid.names';
            smthloaded = 1; % set state to already loaded
            set(Aviname_edit,'String',savetxt);
            pathlist = [pathlist;pathlistl];
            expvidnames = [expvidnames;expvidnamesl];
        else
            disp('file does not have pathlist or expvidnames')
        end

    elseif exist([dir_path,'expvid.names.mat'],'file')
        evn=load('expvid.names.mat','expvidnames');
        expvidnamesl = evn.expvidnames;
        pathlistl = repmat({dir_path},numel(expvidnamesl),1);
        % set saving to mat file format
        set(vid_radio,'val',1);
        set(mat_radio,'val',0);
        savetxt = 'expvid.names';
        smthloaded = 1; % set state to already loaded
        set(Aviname_edit,'String',savetxt);
        pathlist = [pathlist;pathlistl];
        expvidnames = [expvidnames;expvidnamesl];
    elseif exist([dir_path,'expmat.names.mat'],'file')
        pl=load('expmat.names.mat','pathlist');
        pathlistl = pl.pathlist;
        expvidnamesl = cell(size(pathlistl));
        % parse it
        for pi = 1:numel(pathlistl)
            [p,n,e]=fileparts(pathlistl{pi});
            pathlistl(pi) = {[p,filesep]};
            expvidnamesl(pi) = {[n,e]};
        end
        % set saving to mat file format
        set(vid_radio,'val',0);
        set(mat_radio,'val',1);
        savetxt = 'expmat.names';
        smthloaded = 1; % set state to already loaded
        set(Aviname_edit,'String',savetxt);
        pathlist = [pathlist;pathlistl];
        expvidnames = [expvidnames;expvidnamesl];
    else
        [allfiles,path_name] = uigetfile({'*.mat'},'MultiSelect','off'); % makes sure only mat files are chosen
        % is it a vid or mat file list
        if ~(allfiles==0)
            if strcmp(allfiles(end-12:end-10),'mat')
                pl=load([path_name,allfiles],'pathlist');
                pathlistl = pl.pathlist;
                expvidnamesl = cell(size(pathlistl));
                % parse it
                for pi = 1:numel(pathlistl)
                    [p,n,e]=fileparts(pathlistl{pi});
                    pathlistl(pi) = {[p,filesep]};
                    expvidnamesl(pi) = {[n,e]};
                end
                % set saving to mat file format
                set(vid_radio,'val',0);
                set(mat_radio,'val',1);
                savetxt = allfiles(1:end-4);
                smthloaded = 1; % set state to already loaded
                set(Aviname_edit,'String',savetxt);
                pathlist = [pathlist;pathlistl];
                expvidnames = [expvidnames;expvidnamesl];
            elseif strcmp(allfiles(end-12:end-10),'vid')
                evn=load([path_name,allfiles],'expvidnames');
                expvidnamesl = evn.expvidnames;
                pathlistl = repmat({dir_path},numel(expvidnamesl),1);
                % set saving to mat file format
                set(vid_radio,'val',1);
                set(mat_radio,'val',0);
                savetxt = allfiles(1:end-4);
                smthloaded = 1; % set state to already loaded
                set(Aviname_edit,'String',savetxt);
                pathlist = [pathlist;pathlistl];
                expvidnames = [expvidnames;expvidnamesl];
            else % check if it has pathlist or expvidnames
                pl = who('-file',allfiles,'pathlist');
                evn = who('-file',allfiles,'expvidnames');
                if ~isempty(pl)&&~isempty(evn)
                    disp('file contains both expvidnames and pathlist')
                elseif strcmp(pl,'pathlist')
                    pl=load([path_name,allfiles],'pathlist');
                    pathlistl = pl.pathlist;
                    expvidnamesl = cell(size(pathlistl));
                    % parse it
                    for pi = 1:numel(pathlistl)
                        [p,n,e]=fileparts(pathlistl{pi});
                        pathlistl(pi) = {[p,filesep]};
                        expvidnamesl(pi) = {[n,e]};
                    end
                    % set saving to mat file format
                    set(vid_radio,'val',0);
                    set(mat_radio,'val',1);
                    savetxt = allfiles(1:end-4);
                    smthloaded = 1; % set state to already loaded
                    set(Aviname_edit,'String',savetxt);
                    pathlist = [pathlist;pathlistl];
                    expvidnames = [expvidnames;expvidnamesl];
                elseif strcmp(evn,'expvidnames')
                    evn=load([path_name,allfiles],'expvidnames');
                    expvidnamesl = evn.expvidnames;
                    pathlistl = repmat({dir_path},numel(expvidnamesl),1);
                    % set saving to mat file format
                    set(vid_radio,'val',1);
                    set(mat_radio,'val',0);
                    savetxt = allfiles(1:end-4);
                    smthloaded = 1; % set state to already loaded
                    set(Aviname_edit,'String',savetxt);
                    pathlist = [pathlist;pathlistl];
                    expvidnames = [expvidnames;expvidnamesl];

                end
            end
        end
    end
    
    % update table
    t.Data = expvidnames;
    expvidnames_orig = expvidnames;

end



function [] = deletecallback(~,~)
    % create mask containing rows to keep
    expvidnames = t.Data;
    mask = (1:numel(expvidnames))';
    mask(rows) = [];
    % delete selected rows and re-write data
    expvidnames = expvidnames(mask,:);
    expvidnames_orig = expvidnames_orig(mask,:);
    pathlist = pathlist(mask,:);
    % update table
    t.Data = expvidnames;
   
end

function [] = renamecallback(~,~)
    % renames the vieo file and al files associated with that file (i.e. 
    % mat, tiff, vtracks etc)
    expvidnames = t.Data;
    if length(rows)>1
        error('please select and modify only one cell')
    else
        if (~strcmp(expvidnames_orig{rows},expvidnames{rows}))&&(~isempty(expvidnames{rows}))
            if ~exist([pathlist{rows},expvidnames{rows}],'file')
                % rename file
                set(t,'Enable','off')
                set(donebutton,'Enable','off')
                set(deletebutton,'Enable','off')
                set(renamebutton,'Enable','off')
                set(browsedirbutton,'Enable','off')
        %         movefile(expvidnames_orig{rows},expvidnames{rows})
                renameall([pathlist{rows},expvidnames_orig{rows}],[pathlist{rows},expvidnames{rows}])
    %             renameall(expvidnames_orig{rows},expvidnames{rows})
                % update table
                expvidnames_orig = expvidnames;
                set(t,'Enable','on')
                set(donebutton,'Enable','on')
                set(deletebutton,'Enable','on')
                set(renamebutton,'Enable','on')
                set(browsedirbutton,'Enable','on')
            else
                expvidnames = expvidnames_orig;
            end
                
        end
    t.Data = expvidnames;
    end
   
end


% function [] = textcall(~,~)
% 
% end

function [] = closecallback(~,~)
   
   selection = 'Yes';
   switch selection
      case 'Yes'
                delete(f1)

          try
                delete(f1)
          catch
          end
      case 'No'
      return 
   end
        
        
end




end
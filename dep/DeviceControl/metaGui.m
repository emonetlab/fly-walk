% metaGui.m
% metaGui.m is a GUI which is used to set the metadata for the fly walk
% experimment

function []  = metaGui(path_name)
% if no filename is given then generate the default name
if nargin==0
    path_name = fullfile(pwd,filesep,'MetaData.mat');
end
% 
% % load defaults
% if exist('metaGui.Defaults.mat','file') == 2
%     metadata = load('metaGui.Defaults.mat');
%     metadata = metadata.metadata;
% else
%     metadata.genotype = 'CS'; % default genotype
%     metadata.days_starved = 3; % default days of starvation
%     metadata.age = 7; % age of flies days
%     metadata.odor = 'smoke'; % default genotype
%     metadata.experiment = 'ribbon'; % experiment to be carried out
%     metadata.gender = 'Female'; % default gender
%     metadata.Temp = 'UPDATE'; % default temp C
%     metadata.humidity = 'UPDATE'; % default humidty %
%     metadata.lights = 'off'; % default light situation
%     metadata.vial = 1; % vial number on this vial
%     metadata.trial = 1; % trial number on this vial
% end

metadata = [];

%% make GUI
scsz = get(0,'ScreenSize');
yw = 5.5*scsz(4)/7;
xw = scsz(3)/2;

[~,figwname,~] = fileparts(path_name);

f1 = figure('Position',[scsz(3)/7 scsz(4)/10 xw yw],'Name',figwname,'Toolbar',...
    'figure','Menubar','none','NumberTitle','off','Resize','on'...
    ,'HandleVisibility','on','CloseRequestFcn',@closecallback);

%% parameters


% figure and object handles

% get matlab folder path, assume it is the first one in the search path
defpath = getMatDirPath;
% check if something is already written
if exist(path_name,'file')
   m = matfile(path_name);
   mdt = m.metadata;
   text = mdt.text;
   metadata = rmfield(mdt,'text');
else
    % try to construct the meta from the filename
    % split the file name in to pieces
    [~,NAME,EXT] = fileparts(path_name); 
    sp = strsplit([NAME,EXT],'_');
    if (numel(sp)==10)||(numel(sp)==9) % probably bck video
        % fist get the defaults
        if exist([defpath,filesep,'metaGui.Defaults.mat'],'file') == 2
            load([defpath,filesep,'metaGui.Defaults.mat']);
        else
            metadata.ID = 'MahmutDemir'; % defaults experimenter ID
            metadata.project = 'SmokeNavigation'; % default project   
        end
        metadata.year = sp{1}; % year
        metadata.month = sp{2}; % year
        metadata.day = sp{3}; % year
        metadata.experiment = sp{8}; % experiment to be carried out
        if ~(exist([defpath,filesep,'metaGui.Defaults.mat'],'file') == 2)
            metadata.odor = 'smoke'; % default genotype  
        end
        metadata.genotype = sp{4}; % default genotype
        if ~(exist([defpath,filesep,'metaGui.Defaults.mat'],'file') == 2)
            metadata.gender = 'Female'; % default gender
        end
        metadata.days_starved = str2double(sp{6}(1:end-2)); % default days of starvation
        metadata.age = str2double(sp{7}(1:end-2)); % age of flies days
        metadata.vial = str2double(sp{5}); % vial number on this vial
        metadata.trial = str2double(sp{9}(1)); % trial number on this vial
        if ~(exist([defpath,filesep,'metaGui.Defaults.mat'],'file') == 2)         
            metadata.Temp = 'UPDATE'; % default temp C
            metadata.humidity = 'UPDATE'; % default humidty %
            metadata.lights = 'off'; % default light situation    
        end
        if isfield(metadata,'computer')
            metadata.computer = getenv('computername'); % computer name
        end
        if isfield(metadata,'user')
            metadata.user = getenv('username');     % computer user id
        end
        if isfield(metadata,'camera')
             % is there a camera connected
            iadinf = imaqhwinfo('pointgrey'); % get pointgrey camera infor
            if ~isempty(iadinf.DeviceIDs)
                metadata.camera = iadinf.DeviceInfo.DeviceName;
            else
                metadata.camera = none;
            end
        end
        
        text = [];
    elseif exist([defpath,filesep,'metaGui.Defaults.mat'],'file') == 2
        load([defpath,filesep,'metaGui.Defaults.mat']);
        text = [];
        % update the date
        if isfield(metadata,'year')
            metadata.year = year(date); % year
        end
        if isfield(metadata,'month')
            metadata.month = month(date); % year
        end
        if isfield(metadata,'day')
            metadata.day = day(date); % year
        end
        if isfield(metadata,'computer')
            metadata.computer = getenv('computername'); % computer name
        end
        if isfield(metadata,'user')
            metadata.user = getenv('username');     % computer user id
        end
        if isfield(metadata,'camera')
             % is there a camera connected
            iadinf = imaqhwinfo('pointgrey'); % get pointgrey camera infor
            if ~isempty(iadinf.DeviceIDs)
                metadata.camera = iadinf.DeviceInfo.DeviceName;
            else
                metadata.camera = none;
            end
        end
        
    else
        metadata.ID = 'MahmutDemir'; % defaults experimenter ID
        metadata.project = 'SmokeNavigation'; % default project
        metadata.year = year(date); % year
        metadata.month = month(date); % year
        metadata.day = day(date); % year
        metadata.experiment = 'ribbon'; % experiment to be carried out
        metadata.odor = 'smoke'; % default genotype
        metadata.genotype = 'CS'; % default genotype
        metadata.gender = 'Female'; % default gender
        metadata.days_starved = 3; % default days of starvation
        metadata.age = 7; % age of flies days
        metadata.vial = 1; % vial number on this vial
        metadata.trial = 1; % trial number on this vial
        metadata.Temp = 'UPDATE'; % default temp C
        metadata.humidity = 'UPDATE'; % default humidty %
        metadata.lights = 'off'; % default light situation
        metadata.computer = getenv('computername'); % computer name
        metadata.user = getenv('username');     % computer user id
        
        % is there a camera connected
        iadinf = imaqhwinfo('pointgrey'); % get pointgrey camera infor
        if ~isempty(iadinf.DeviceIDs)
            metadata.camera = iadinf.DeviceInfo.DeviceName;
        end

        text = [];
    end
end
% make the table
% Column names and column format
columnname = {'Field','Value'};
columnformat = {[],[]};

noel = 25;  % there will be 25 rows available to edit
d = cell(noel,2);
fldnm = fieldnames(metadata);  % get filed names in the metadata

for i = 1:numel(fldnm)
    d(i,1) = fldnm(i);
    d(i,2) = {metadata.(fldnm{i})};
end


% Create the uitable
t = uitable(f1,'Data', d,... 
            'ColumnName', columnname,...
            'units','normalized',...
            'ColumnFormat', columnformat,...
            'ColumnWidth', {xw/2.5/2.05,xw/2.5/2.05},...
            'ColumnEditable', [true true],...
            'Fontsize', 14,...
            'RowName',[]);

% Set width and height
t.Position = [1/20 1/20 1/2.5 1*.9];
t.CellEditCallback = @checkentry;

% experimental details text input
uicontrol(f1,'fontunits', 'normalized','FontSize',.2,'units','normalized','Style','text',...
    'position',[.5 6/7 1/2.5 1/10],'String','Experimental Details','fontweight','bold');
text_edit = uicontrol(f1,'fontunits', 'normalized','FontSize',.04,'units','normalized','style','edit',...
    'position',[1/2 1.3/4 1/2.1 4/7],'string',text,'Max',2,'HorizontalAlignment', 'left','callback',@textcall);

        
donebutton = uicontrol(f1,'fontunits', 'normalized','FontSize',.6,'units','normalized',...
    'Position',[3/4 50/yw 150/xw 50/yw],'Style','pushbutton','String','done!','Enable','on','Callback',@donecallback);

         
      



%%


function [] = donecallback(~,~)
   checkentry;
   save([defpath,filesep,'metaGui.Defaults.mat'],'metadata');
   % get text and append
   metadata.text = get(text_edit,'string');
   % check if the file exist
   if exist(path_name,'file')
       save(path_name,'metadata','-append');
   else
       save(path_name,'metadata','-v7.3');
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
    d = t.Data;
    % figure out etries
    md = [];

    for j = 1:size(d,1)
        if ~isempty(d{j,1})
            % figure out if entry is a number
            if isnumeric(d{j,2})
                md.(d{j,1}) = d{j,2};
            else % character
                if isempty(str2num(d{j,2})) % text
                    md.(d{j,1}) = d{j,2};
                else % number
                    md.(d{j,1}) = str2num(d{j,2});
                end
            end
        end
            
    end
    metadata = md;
end

function [] = textcall(~,~)
    metadata.text = get(text_edit,'string');
end

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
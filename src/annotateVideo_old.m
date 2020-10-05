% annotateVideo.m
% created by Srinivas Gorur-Shandilya at 13:46 , 28 August 2013. Contact me
% at http://srinivas.gs/contact/
% 
% annotateVideo.m is a GUI that is meant to annotate fly movies with
% information that a tracking algo can use to automatically track fly
% trajectories. 
% right now, this is used to:
% - specify the cropping rectangle
% 

function []  = annotateVideo(path_name,thesefiles)

%% parameters
startframe = 10;
frame = 10; % current frame

% working variables
path_name = '';
nframes=  [];
h = [];
movie = [];
mi = [];
moviefile= [];

% figure and object handles
moviefigure = [];
f1 =  [];
framecontrol = [];
framecontrol2= [];
mark_crop_box_button = [];
nextfilebutton = [];
cannotanalysebutton = [];
movie_axis = [];

% variables to save in the metadata file
crop_box = [];
moviefile = [];


%% choose files
if nargin == 0
    [allfiles,path_name] = uigetfile({'*.avi','*.mat'; 'AVI movies','.mat images'}','MultiSelect','on'); % makes sure only avi files are chosen
    if ~ischar(allfiles)
    % convert this into a useful format
    thesefiles = [];
    for fi = 1:length(allfiles)
        thesefiles = [thesefiles dir(strcat(path_name,oss,cell2mat(allfiles(fi))))];
    end
    else
        thesefiles(1).name = allfiles;
    end
else
end


mi=1;
initialiseAnnotate(mi);
skip=0;

    
%% make GUI function

    function [] = createGUI(eo,ed)
        titletext = thesefiles(mi).name;
        moviefigure = figure('Position',[150 250 900 600],'Name',titletext,'Toolbar','none','Menubar','none','NumberTitle','off','Resize','on','HandleVisibility','on');
        movie_axis = gca;

        f1 = figure('Position',[70 70 1500 100],'Toolbar','none','Menubar','none','NumberTitle','off','Resize','on','HandleVisibility','on');


        framecontrol = uicontrol(f1,'Position',[53 45 600 20],'Style','slider','Value',startframe,'Min',7,'Max',nframes,'SliderStep',[100/nframes 1000/nframes],'Callback',@framecallback);

        try    % R2013b and older
           addlistener(framecontrol,'ActionEvent',@framecallback);
        catch  % R2014a and newer
           addlistener(framecontrol,'ContinuousValueChange',@framecallback);
        end

        th(1)=uicontrol(f1,'Position',[1 45 50 20],'Style','text','String','frame #');

        framecontrol2 = uicontrol(f1,'Position',[383 5 60 20],'Style','edit','String',mat2str(frame),'Callback',@frame2callback);
        th(2)=uicontrol(f1,'Position',[320 5 60 20],'Style','text','String','frame #');

        nextfilebutton = uicontrol(f1,'Position',[223 5 50 20],'Style','pushbutton','String','NextFile','Enable','on','Callback',@nextcallback);

        mark_crop_box_button = uicontrol(f1,'Position',[910 50 100 20],'Style','pushbutton','String','Mark Crop','Callback',@markCrop);

        skipthisbutton = uicontrol(f1,'Position',[123 5 50 20],'Style','pushbutton','String','Skip This','Enable','on','Callback',@cannotanalysecallback);
    end

    function [] = markCrop(~,~)
        h = imrect(movie_axis);
        crop_box = wait(h);
        disp('Crop box saved!')
        saveTrackData;
    end

    function [] = cannotanalysecallback(eo,ed)
        % move this to cannot-analyse
        if exist('cannot-analyse') == 7

        else
            % make it
            mkdir('cannot-analyse')
        end
        % move this file there
        movefile(thesefiles(mi).name,strcat('cannot-analyse',oss,thesefiles(mi).name))
        % delete the .mat
        thisfile = thesefiles(mi).name;
        delete(strcat(thisfile(1:end-3),'mat'))
        % go to the next file
        skip=1;
        nextcallback;
        skip=0;
        
    end


    function [] = nextcallback(~,~)
        if mi == length(thesefiles)
            delete(moviefigure)
            delete(f1)
        else
            % clear all old variables
            disp('OK. Next file.')
            

            % delete all GUI elements
            delete(framecontrol)
            delete(framecontrol2)
            delete(nextfilebutton)
            delete(moviefigure,f1)

            % redraw entire GUI
            createGUI;

            nframes=  [];
            h = [];
            moviefile= [];

            
            mi = mi+1;
            movie = VideoReader(thesefiles(mi).name);

            % working variables
            nframes = get(movie,'NumberOfFrames');
            
            % clear variables
            if ~skip
                frame=1;
                markroi; % clears ROIs
                markstart;
                markstop;
                markleft;
                markright;
            end
            
            startframe = 10;
            frame = 10; % current frame
            
            delete(framecontrol)

            framecontrol = uicontrol(f1,'Position',[53 45 600 20],'Style','slider','Value',startframe,'Min',7,'Max',nframes,'SliderStep',[100/nframes 1000/nframes],'Callback',@framecallback);
        
            
            % update GUI
            titletext = thesefiles(mi).name;
            set(moviefigure,'Name',titletext);
            set(framecontrol,'Value',10);
            set(framecontrol2,'String','10')
            
            showImage;
            
        end
    end


%% intialise function
function [] = initialiseAnnotate(mi)
    [~,~,ext] = fileparts(thesefiles(mi).name);
    if strcmp(ext,'.mat')
        movie = matfile([path_name, oss, thesefiles(mi).name]);
        [~,~,nframes] = size(movie,'images');
    elseif strcmp(ext,'.avi') 
        movie = VideoReader([path_name, oss, thesefiles(mi).name]);
        nframes = get(movie,'NumberOfFrames');
    else
        error('Unexpected file type.')
    end
    
    createGUI;
    showImage;

end


  
%% callback functions


function [] = framecallback(~,~)
    frame = ceil((get(framecontrol,'Value')));
    showImage();
    set(framecontrol2,'String',mat2str(frame));
end


function [] = frame2callback(~,~)
    frame = ceil(str2double(get(framecontrol2,'String')));
    showImage();    
    set(framecontrol,'Value',(frame));
end

function [] = showImage(~,~)
    [~,~,ext] = fileparts(thesefiles(mi).name);
    if strcmp(ext,'.avi')
        ff = read(movie,frame);
        ff = 255-ff;
    elseif strcmp(ext,'.mat')
        ff = 255 - movie.images(:,:,frame);
    end
    figure(moviefigure), axis image
    imagesc(ff); colormap(gray)
    axis equal
    axis tight
    title(frame)
end



function  [] = saveTrackData(~,~)
    moviefile = thesefiles(mi).name;
    filename = thesefiles(mi).name;
    [~,root_name] = fileparts(thesefiles(mi).name);
    save([path_name root_name '_annotation.mat'],'crop_box','moviefile');
    
    if ~isempty(crop_box) 
        set(nextfilebutton,'Enable','on');
    else
        set(nextfilebutton,'Enable','off');
    end
    
end

end
%% movieAnalyser.m
% a barebones MATLAB class to boostrap your image analysis problem
% usage:
%
% 1.

classdef movieAnalyser < handle
    
    properties
        ui_handles
        plot_handles
        path_name
        current_frame = 1;
        previous_frame = 1;
        current_raw_frame 			% stores the raw image of the current working frame
        nframes
        videoType
        variable_name = 'frames';
        median_start = 1;
        median_stop = Inf;
        median_step = 25; % frames
        median_frame
        median_frame_rand
        ExpParam
        subtract_median = false;
        subtract_background_frame = true;
        apply_mask = true;
        median_loaded = false;
        parameter_loaded = false;
    end
    
    methods
        function m = createGUI(m)
            m.ui_handles.fig = figure('NumberTitle','off','MenuBar','none','ToolBar','figure','CloseRequestFcn',@m.quitMovieAnalyser); hold on;
            m.ui_handles.fig.Tag = 'movieAnalyser';
            screensize = get( 0, 'Screensize' );
            m.ui_handles.fig.Position(1) = round(screensize(1)/20);
            m.ui_handles.fig.Position(2) = round(screensize(4)/20);
            m.ui_handles.fig.Position(3) = round(screensize(3)*9/10);
            m.ui_handles.fig.Position(4) = round(screensize(4)*9/10);
            
            m.ui_handles.pause_button = uicontrol('Units','normalized','Position',[.45 .01 .1 .05],'String','Play','Style','togglebutton','Value',1,'Callback',@m.togglePlay);
            m.ui_handles.next_button = uicontrol('Units','normalized','Position',[.55 .01 .1 .05],'String','>','Style','togglebutton','Value',1,'Callback',@m.nextFrame);
            m.ui_handles.prev_button = uicontrol('Units','normalized','Position',[.35 .01 .1 .05],'String','<','Style','togglebutton','Value',1,'Callback',@m.prevFrame);
            
            % make a scrubber
            m.ui_handles.scrubber = uicontrol('Units','normalized','Style','slider','Position',[0 0.09 1 .01],'Parent',m.ui_handles.fig,'Min',1,'Max',m.current_frame+1,'Value',m.current_frame,'SliderStep',[.01 .02],'BusyAction','cancel','Interruptible','off');
            addlistener(m.ui_handles.scrubber,'ContinuousValueChange',@m.scrubberCallback);
            
            m.plot_handles.ax = gca;
            m.plot_handles.ax.Position = [0.01 0.15 0.99 0.85];
            m.plot_handles.im = imagesc([0 0; 0 0]);
            
            
            
            % if path_name is set, operate on frame
            if ~isempty(m.path_name)
                m.ui_handles.scrubber.Max = m.nframes;
                m.operateOnFrame;
                
            end
            
            axis tight equal ij
            
        end % end createGUI function
        
        function m = scrubberCallback(m,~,~)
            m.previous_frame = m.current_frame;
            m.current_frame = ceil(m.ui_handles.scrubber.Value);
            m.operateOnFrame;
        end
        
        function set.path_name(m,value)
            % ~~~~~~~ change me if your data is not a MAT file ~~~~~~~~~~~~~~~~~
            % verify it is there
            % modify for saved data initialization, it should not create a
            % writable file
            if strcmp(m.videoType,'mat')
                if isa(value,'matlab.io.MatFile')
                else
                    assert(exist(value,'file') == 2,'Expected a file path!')
                    m.path_name = matfile(value);
                end
                m.path_name.Properties.Writable = true;
                
                % figure out how many frames there are
                [~,~,m.nframes] = size(m.path_name,m.variable_name);
            elseif strcmp(m.videoType,'avi')||strcmp(m.videoType,'mj2')
                assert(exist(value,'file') == 2,'Expected a file path!')
                m.path_name = VideoReader(value);
                m.nframes = round(m.path_name.Duration*m.path_name.FrameRate);
            end
            
            
            %% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            
        end % end set path_name
        
        
        function m = nextFrame(m,~,~)
            if m.current_frame < m.nframes
                m.previous_frame = m.current_frame;
                m.current_frame = m.current_frame + 1;
                m.operateOnFrame;
            end
            
        end
        
        function m = prevFrame(m,~,~)
            if m.current_frame > 1
                m.previous_frame = m.current_frame;
                m.current_frame = m.current_frame - 1;
                m.operateOnFrame;
            end
            
        end
        
        function m = operateOnFrame(m,~,~)
            %% ~~~~~~~~~ redefine this method in your class ~~~~~~~~~~~~~~~
            %% what you probably want to do is first call the method from the superclass (movieAnalyser), and then redefine this function in your subclass
            % see this link for more information:
            % https://www.mathworks.com/help/matlab/matlab_oop/modifying-superclass-methods-and-properties.html
            %
            %             if ~m.current_frame==1
            %                 cla;    % clear axes
            %                 clf;
            %             end
            
            % get median frames
            if (m.current_frame==1)&&(~m.median_loaded)
                m.computeMedianFrame;
                if strcmp(m.videoType,'mat')
                    disp('Calculating the random median frame')
                    m.median_frame_rand = getMedFrmRand(m.path_name.Properties.Source);
                elseif strcmp(m.videoType,'avi')||strcmp(m.videoType,'mj2')
                    disp('Calculating the random median frame')
                     m.median_frame_rand = getMedFrmRandVideo([m.path_name.Path,filesep,m.path_name.Name]);
                end
                m.median_frame_rand =  fillFlies(m.median_frame_rand,10);
                disp('Flies in the random median frame is filled')
                m.median_loaded = true;
            end
            
            
            % read frame
            if strcmp(m.videoType,'mat')
                m.current_raw_frame = m.path_name.(m.variable_name)(:,:,m.current_frame);
            elseif strcmp(m.videoType,'avi')||strcmp(m.videoType,'mj2')
                % set the current time
                m.path_name.CurrentTime = (m.current_frame-1)/m.path_name.FrameRate;
                m.current_raw_frame = readFrame(m.path_name);
            end
            
            
            
            
            % subtract background if necessary
            if m.subtract_background_frame && ~isempty(m.ExpParam.bkg_img)
                if m.apply_mask
                    m.current_raw_frame = uint8(double(m.current_raw_frame) - double(m.ExpParam.bkg_img)).*uint8(m.ExpParam.mask);
                else
                    m.current_raw_frame = uint8(double(m.current_raw_frame) - double(m.ExpParam.bkg_img));
                end
            end
            
            % subtract median if necessary
            if m.subtract_median && ~isempty(m.median_frame)
                if m.apply_mask
                    m.current_raw_frame = m.current_raw_frame - m.median_frame_rand.*uint8(m.ExpParam.mask);
                else
                    m.current_raw_frame = m.current_raw_frame - m.median_frame_rand;
                end
            end
            
            
            %             m.current_raw_frame = adapthisteq(m.current_raw_frame); % apply this when only showing
            if isfield(m.plot_handles,'ax')
                if ~isempty(m.plot_handles.ax)
                    m.plot_handles.im.CData = m.current_raw_frame;
                    m.ui_handles.fig.Name = ['Frame# ' oval(m.current_frame)];
                    
                end
            end
            
        end
        
        function m = togglePlay(m,src,~)
            if strcmp(src.String,'Play')
                src.String = 'Pause';
                % now loop through all frames
                for i = m.current_frame:m.nframes
                    m.previous_frame = m.current_frame;
                    m.current_frame  = i;
                    m.ui_handles.scrubber.Value = i;
                    if strcmp(src.String,'Pause')
                        m.operateOnFrame;
                        drawnow limitrate
                    else
                        break
                    end
                end
            elseif strcmp(src.String,'Pause')
                src.String = 'Play';
            end
            
        end % end toggle play
        
        function m = quitMovieAnalyser(m,~,~)
            % clear all handles
            if ~isempty(m.ui_handles)
                fn = fieldnames(m.ui_handles);
                for i = 1:length(fn)
                    try
                        delete(m.ui_handles.(fn{i}))
                    catch
                    end
                    m.ui_handles.(fn{i}) = [];
                end
            end
            if ~isempty(m.plot_handles)
                fn = fieldnames(m.plot_handles);
                for i = 1:length(fn)
                    try
                        delete(m.plot_handles.(fn{i}))
                    catch
                    end
                    m.plot_handles.(fn{i}) = [];
                end
            end
        end
        
        function m = testReadSpeed(m)
            % do a sequential read test
            m.current_frame = 1;
            tic;
            for i = 1:m.nframes
                m.current_frame = i;
                m.operateOnFrame;
                t = toc;
                if t > 2
                    break
                end
            end
            t = toc;
            disp([ oval(i) ' frames read in ' oval(t) ' seconds.'])
        end
        
        
        function m = loadExpParameters(m)
            % check if the parameter file exists
            if ~m.parameter_loaded
                if strcmp(m.videoType,'mat')
                    if exist([m.path_name.Properties.Source(1:end-11),'.mat'],'file')
                        m.ExpParam = load([m.path_name.Properties.Source(1:end-11),'.mat'],'p');
                        m.ExpParam = m.ExpParam.p;
                        % make the background image uint8
                        m.ExpParam.bkg_img = uint8(m.ExpParam.bkg_img);
                        m.parameter_loaded =1;
                    end
                elseif strcmp(m.videoType,'avi')||strcmp(m.videoType,'mj2')
                    if exist([m.path_name.Path,filesep,m.path_name.Name(1:end-4),'.mat'],'file')
                        m.ExpParam = load([m.path_name.Path,filesep,m.path_name.Name(1:end-4),'.mat'],'p');
                        m.ExpParam = m.ExpParam.p;
                        % isthere a pre-saved background image
                        if ~isfield(m.ExpParam,'bkg_img')
                            % get the backgorund image by getting median
                            % frame of frames sampled at every second
                            disp('There is not a pre-saved background image')
                            disp('Will sample frames at every second and use the meadian as the bkg_img')
                            % get background image
                            bkg_img = GetBkgImg([],[m.path_name.Path,filesep,m.path_name.Name],m.ExpParam,false); % false: do not fill flies
                            m.ExpParam.bkg_img = bkg_img;
                            p = m.ExpParam;
                            p.bkg_img = bkg_img;
                            save([m.path_name.Path,filesep,m.path_name.Name(1:end-4),'.mat'],'p','-append');
                            disp('background image is saved into the original mat file');
                        end
                        % make the background image uint8
                        m.ExpParam.bkg_img = uint8(m.ExpParam.bkg_img);
                        m.parameter_loaded =1;
                    end
                end
            end
        end
        
        
        function m = computeMedianFrame(m)
            
            if ~m.median_loaded
                % is it saved previously?
                if isfield(m.ExpParam,'MedianFrame')
                    disp('Median frame is calculated previously. Using that one.')
                    m.median_frame = m.ExpParam.MedianFrame;
                    m.median_loaded = true;
                    disp('Median frame is loaded')
                    return
                end
                
                disp('Calculating the median frame')
                a = m.median_start;
                z = min([m.median_stop m.nframes]);
                
                % figure out the class of the matrix
                if strcmp(m.videoType,'mat')
                    dets = whos(m.path_name);
                    
                    
                    % read frames
                    read_these_frames = a:m.median_step:z;
                    if length(read_these_frames)>300
                        read_these_frames = round(linspace(a,z,300));
                    end
                    M = zeros(size(m.path_name,m.variable_name,1),size(m.path_name,m.variable_name,2),...
                        length(read_these_frames),dets(strcmp(m.variable_name, {dets.name})).class);
                    hwb = waitbar(0,'Please wait while I am getting the median frame...');
                    for i = 1:length(read_these_frames)
                        cf = read_these_frames(i);
                        M(:,:,i) = m.path_name.(m.variable_name)(:,:,cf); % this is 10X faster than a direct assignation;
                        waitbar(i / length(read_these_frames))                             % don't drink from the for-loops-are-bad-kool-aid font
                    end
                    close(hwb)
                else
                    
                    
                    % read frames
                    read_these_frames = a:m.median_step:z;
                    if length(read_these_frames)>300
                        read_these_frames = round(linspace(a,z,300));
                    end
                    M = zeros(m.path_name.Height,m.path_name.Width,length(read_these_frames),'uint8');
                    hwb = waitbar(0,'Please wait while I am getting the median frame...');
                    for i = 1:length(read_these_frames)
                        cf = read_these_frames(i);
                        m.path_name.CurrentTime = (cf-1)/m.path_name.FrameRate;
                        M(:,:,i) = readFrame(m.path_name); % this is 10X faster than a direct assignation; don't drink from the for-loops-are-bad-kool-aid font
                        waitbar(i / length(read_these_frames))
                    end
                    close(hwb)
                end
                
                if m.subtract_background_frame && ~isempty(m.ExpParam.bkg_img)
                    if m.apply_mask
                        M = (M - m.ExpParam.bkg_img).*uint8(m.ExpParam.mask);
                    else
                        M = M - m.ExpParam.bkg_img;
                    end
                end
                
                m.median_frame = median(M,3);
                m.median_loaded = true;
                disp('Median frame is calculated')
                
                % save the median frame to p
                p = m.ExpParam;
                p.MedianFrame = m.median_frame;
                if strcmp(m.videoType,'mat')
                    if exist([m.path_name.Properties.Source(1:end-11),'.mat'],'file')
                        save([m.path_name.Properties.Source(1:end-11),'.mat'],'p','-append');
                    end
                elseif strcmp(m.videoType,'avi')||strcmp(m.videoType,'mj2')
                    if exist([m.path_name.Path,filesep,m.path_name.Name(1:end-4),'.mat'],'file')
                    save([m.path_name.Path,filesep,m.path_name.Name(1:end-4),'.mat'],'p','-append');
                    end
                end
                disp('MedianFrame is saved into the original mat file');
               
            end
            
            
        end % end computeMedianFrame
        
    end % end all methods
end	% end classdef



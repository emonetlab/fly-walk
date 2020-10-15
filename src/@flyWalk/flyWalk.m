%% flyWalk class from movieAnalyser
%
%  Copyright (C) 2020  Srinivas Gorur-Shandilya, Mahmut Demir
% 
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation (GNU GPL-3.0)
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program. (See: flywalk/LICENSE.txt)  
%     If not, see <https://www.gnu.org/licenses/>.
%

classdef flyWalk < movieAnalyser
    
    properties
        fly_walk_version = 0.8;
        fwName
%         fwPath
        %% tracking parameters
        fly_body_threshold = 175; 	% on a 8-bit image. Set all pixels below this to zero and binarize the image
        min_fly_area = 1;           % mm^2. remove objects whose area less than this
        maximum_distance_to_link_trajectories = 1155; % mm/sec (max speed that a fly can have)
        start_frame = 1;			% where do you want to start tracking?
        track_movie = true; 		% if set to true, it runs the tracking. otherwise, it doesn't
        run_signal_modules = false;  % if set to true, gets orientations, optimizes antenna and measures the signal on operateOnFrame
        track_reverse = false; 		% if set to true, it runs the tracking when frames iterated backwards. otherwise, it doesn't
        dist_fly_edge_leave = 1.55; % mm. used to dtect flies close to the border
        % 		regionprops_args = {'Area','Orientation','Centroid','MajorAxisLength','MinorAxisLength','BoundingBox','Image'};
        regionprops_args = {'Area','Centroid','Orientation','MajorAxisLength','MinorAxisLength','PixelList','Perimeter','Eccentricity'};
        track_per_fly_max = 10;      % preallocate space for track collection
        trackingInfoExtensionFactor = 5; % when flywalk reaches to max allocated track number, multiply the alloacated space with this and extend
        max_num_of_interacting_flies = 4;
        look_for_lost_flies_length = 1; % sec, if a fly is lost more than this many frames remove it and start another track
        subtract_prestim_median_frame = 1; % subtract prestimulus
        correct_illumination = true;    % correct non uniform illumination in the arena
        
        %% Orientation, Virtual Antenna, & Signal Measurement
        n_of_segments = 2;          % Split the fly in segments along major axis to determine which end is head
        nFramesforGradOrient = 5;   % number of frames to collect fly gradient to determine orientation
        showpieces = false;         % show the splitted parts of the flies and measurements
        nPointsSpeedEstHeading = 2; % average at least this many points to estimate speed. Use kalman length normally
        nPointsSpeedEstAllign = 7;  % velocity vector estimate to allign orentation
        heading_allignment_factor = 13;    % if mean fly speed is larger than immobile speed times this factor, check heading and orientation allignment
        maxAllowedTurnAngle = 30/180*pi;    % 30 degress default, orientation differences more than this is not allowed
        %         use_fly_intensity_gradient = 0; % use the intensity gradient along the fly to determine the fy orientation
        orientation_method = 'Heading Allign';    % method to determine correct orientation: heading_lock: alling the orientation with walking direction when
        % fly starts to walk and lock that allignement.
        % 'Int Grad Vote': measure intensity gradient and determine
        % correct orientation and then lock the alignment
        % 'Heading Allign' allign the orientation with walking
        % direction all the time
        HeadingAllignPointsNum = 5; % after the orientation is locked, it has to match heading this many times
        orient_triangle_size = .6;  % size of the orientation triangle marker
        antlen = 2;                 % factor to divide fly maj axis to get antenna major axis
        antwd = 6;                  % factor to divide fly min axis to get antenna minor axis
        antoffset_lim = [0.8,1.3]; % times fly maj axis to set antenna center. i.e. x_ant = xc + Stemp.MajorAxisLength.*f.antoffset.*cos(Theta);
        antoffset                   % a vector that contains antenna ofset parameters optimized in given frames
        length_aos_mat = 5;         % number of consecutive frames for offset optimization
        antoffset_opt_mat           % matrix to contain ofset values to be used in optimization
        antoffset_status            % is antenna offset optimized or not
        data_smooth_buffer = 1;     % number of frame to exclude before and after each interaction during data smoothing
        data_smooth_maxlen = 100;   % maximum number of samples to use in the data smoothing estimation
        plm_cont_par = [];          % parameters for plume contact detection
        signal_meas_method = 'mean';  % get median intensity value in the virtual antenna
        antenna_opt_method = 'overlap'; % signal: minimizes the measured signal, overlap: minimizes the overlap with the dilated fly
        antenna_opt_dil_n = 7;      % dilate factor, dilate flies and check antenna overlap
        signalBoxSize = [9,1.5];    % signal box size [length,width] centered on fly (mm)
        signalBoxSegmentNum = 21;   % number of segments along the box measurement
        antenna_offset_default = 0.8935;  % default value for antenna offset
        antenna_type = 'fixed';   % fixed: distance to fly center is fixed, dynamic: moved away if overlaps with secondary reflection
        antenna_shape = 'ellipse';  % ellipse or circle
        R2Resize = 1.15;             % enlarge the secondary antenna for optimization
        
        
        %% visualisation and verbosity
        show_live = true; 			% do you want to see a live feedback of the tracking?
        ft_debug = true;			% prints all debug messages.
        show_split = false;          % show splitted flies in a pop up window
        label_flies = true;         % show fly labels next to each fly
        labels_hidden = 1;          % indicates that all labels are hidden
        mark_flies = false;       % show fly markers
        fly_markers_hidden = 1;     % all markers are hidden
        show_orientations = false;      % show orientations, 0: do not show, 1: orientations, 2: heading, 3: both
        orientation_hidden = 1;     % all orientations are hidden
        heading_hidden = 1;         % all headings are hidden
        trajectory_vis_length = 3;  % sec
        show_trajectories = false;      % show tracks with a tail length of trajectory_vis_length
        tracks_hidden = 1;      % all tracks are hidden
        show_antenna = false;           % shows the virtual antenna, where signal is integrated for each fly in each frame, 1: only antenna, 2: mask in a separate window
        antenna_hidden = 1;        % all antenna are hidden
        max_lost_time = 2;          % seconds, if any fly is lost this long do not show its marker any more
        mark_lost = 0;              %
        lost_hidden = 1;
        show_annotation = true;     % turn on annotation
        show_flowfield = 0;         % shows the flow field if PIV data is avalible
        show_winddir = 0;           % show the wind direction and magnitude calculated on the fly antenna
        show_windSpeed = 0;         % show the value of the wind speed with a green text
        show_pivmask = 0;           % show the mask of flies used to eliminate flies during piv calculation
        followThisFlyNumber = nan   % zoom on and follow the fly
        followBoxSize = 200;        % follow box size pixels
        followThisFlyStatus = 'off';% Current status of following a fly
        followNZoomStatus  = 0;     % zoom counter and status
        followNZoom = 'off';        % enter an integer to gradually zoom onto the fly
        
        %% PIV setting and visuality
        flowFieldColor = 'r';       % colors of the flow field arrows
        flowFieldScaleFactor = 3;   % magnification for the flow field arrows
        flowFieldStatus = 'off';    % status of flow field visibility
        flowFieldMatrix = 'filtered'; % use filtered matrix
        windDirColor = 'g';         % color of the wind directions calculated in the fly virtual antenna
        windDirLineWidth = 8;       % wind direction arrow thickness
        windDirStatus = 'off';      % wind direction visibility status
        windSpeedStatus = 'off'     % wind speed visibility status
        windDirScaleFactor = 5;     % magnification for the wind directions
        pivMaskColor = 'm';         % color of the fly elimination masks used during PIV calculation
        pivMaskStatus = 'off';       % wind directions visibility status
        
        %% current working variables and data
        current_objects 			% stores the regionprops objects of current frame
        current_object_status 		% status of current objects (0 -- unassigned, # identity of the object that this fly is assigned)
        reflection_status           % status of the reflections (0 -- no reflection, 1 -- with reflection)
        reflection_meas             % a structure that contains all the reflection measurements
        reflection_overlap          % contains the ratio between the overlapping area to reflection area
        tracking_info 				% a structure that contains all the tracking info
        HeadNOrientAllign           % logical matrix to indicate if heading of the fly is alligned with the orientation
        error_def = {'reflection assignment mismatch detected during collision','fly is lost in the middle of no-where',...
            'close to an unassigned object','has been interacting for too long','lost for too long','nan observed in maj or min ax'};   % error definition
        median_frame_prestim        % pre stimulus median frame
        
        %% reflection parameters
        fillNmeasure = true;            % fill the flies and then measure reflections
        ref_thresh = 21;                % Minimum average intensity in the predicted reflection area for reflection verification
        nframes_ref = 'all';           % number of frames to determine reflections in the begiining of the video,'all' for all frames
        frames_ref_meas = [];           % [framenum,flynum], nx2 list for frames and flies to be measured for reflections, probably due to new flies entering to arena
        show_ref_overlaps = false;      % show how reflections overlaps with other objects
        overlap_threshold = 0.8;        % reflection overlap threhold, disregard the reflection measurement if above
        ref_check_len = 1;              % number of reflection measurements to determine reflection status
        show_reflections = false;       % draw ellipses on putative reflections
        new_obj_ref_meas_buffer = 5;    % frame ofset to measure reflection of the new comers
        center_zone_edge = 50;          % mm half edge length of the box centered at the camera to define hidden-reflection zone
        flies_in_the_centre_zone = [];  % list of the flies in the centre hidden-reflection zone
        refl_dist_param = [.9588 .9865] % reflection distance parameter
        
        %% jumpers & immobile flies
        current_jumpers = [];           % list of jumping flies to be checked for their reflections after jumping is over
        check_jump_over = false;        % flag, true when someone has jumped
        jump_check_frame_num = 1;       % check the reflection of the fly this many frames after it lands
        immobile_speed = 0.7;           % mm/sec, dead or immobile speed
        immobile_decide_frm = 100;      % frame number to determine which flies are immobile
        jump_length = 41;               % mm/sec. used in to detect jumping flies
        jump_length_split = 157;        % mm/sec. used in to detect jumping split objects
        
        %% colliders and overpassers
        include_kmeans = 0;             % tries kmeans separation if watershed fails
        kalman_length = 11;                 % length of the kalman speed estimate
        close_to_wall_dist = 2.3;           % mm. if a colliding object is near a wall closer than this, then disregard
        collision_rel_area_tolerance = 0.5; % relative area tolerance for splited object after collision (1-val<s1/s2<1+val)
        interaction_rel_area_tolerance = 0.2; % relative area tolerance for splited object after collision (1-val<s1/s2<1+val)
        overpass_tot_area_tolerance = [0.03,.1];  % total area tolerance for splited object after overpass (1-val<(s1+s2)n/(s1+s2)n-1<1+val),[doubled tripled]
        collision_tot_area_tolerance = .13;  % total area tolerance for splited object after overpass (1-val<(s1+s2)n/(s1+s2)n-1<1+val),[doubled tripled]
        doubled_fly_area_ratio = 1.5;       % area ratio (new/previous) of a fly to determine whether it merged with another one (doubled)
        tripled_fly_area_ratio  = 2.5;      % area ratio (new/previous) of a fly to determine whether it merged with teo others (tripled)
        edge_coll_ignore_dist = 3;        % mm. to ignore flies close to edge
        speed_up_during_coll = [1.2,1.7];   % speed up factor for collisions to resolve better, flies headed [same,opposite] directions
        close_fly_distance = 6;             % pxl, the distance between flies to determine if they are interacting
        interaction_list = {};              % list of interacting objects (colliding and overlapping) to be resolved
        crowd_interaction_list = {};        % list of interacting objects (colliding and overlapping) to be resolved, more than 3 flies
        OverS = {}                          % overpasser list for the flies who has more than one overpasser
        CollS = {}                          % colliders list for the flies who has more than one collider
        oversind = 1;                       % index for overlap cell container
        collsind = 1;                       % index for overlap cell container
        interact_area_fix_legth = 7;        % if a fly interacts fix its area to mean of this many previous area measurements
        max_interaction_time = 1;           % seconds, if any fly is in interaction more than this drop them and start new tracks
        include_ellips_fit = 0;             % fit ellipses to fly edges
        ellips_fit_tolerance = 0.2;         % tolerance for fitting ellipses
        show_ellips_fit = 1;                % show fitted ellipses on the fly
        best_ellips_fits = [];              % carrier for fits for visualization
        
        
        %% Video settings
        video_filename = 'ISP_Sample';           % file name for gif
        video_frame_range = 250:5:6060;                                          % gif frame range
        video_fps = 40;                                                         % vidfeo record rate, if empty, ExpParam.fps
        video_figres = '-m1';                                                   % video resolution 2X
        video_xlimit = [0,2040];
        video_ylimit = [0,1200];
        video_textcolor = 'k';
        video_textsize = 14;
        video_textweight = 'Bold';
        
        
        %% interaction - resolution - verification
        value_watch_length = 1;             % sec. watch the statistics of the values to decide which fly is which before and after the interaction
        computer_guess = {};                % list of computer guesses [flyin1, flyout1; ...]
        is_drop_list = [];                     % interactions to be dropped
        edited_tracks = {};
        edited_reflections = {};
        is_list_edited = [];
        is_list_deleted = [];
        is_list_flipped = [];
        is_list_dropped = [];
        annotation_info
        
    end
    
    methods
        
        function f = makeVideo(f)
            writerObj = VideoWriter(f.video_filename);
            if isempty(f.video_fps)
                writerObj.FrameRate = f.ExpParam.fps;
            else
                writerObj.FrameRate = f.video_fps;
            end
            open(writerObj);
            [~,flnm,ext] = fileparts(f.path_name.Properties.Source);
            set(f.plot_handles.ax,'xlim',f.video_xlimit,'ylim',f.video_ylimit)
            try
                f.plot_handles = rmfield(f.plot_handles,'videotext');
            catch
            end
            vtx = f.video_xlimit(1)+50/180*diff(f.video_xlimit);
            vty = f.video_ylimit(1)+15/180*diff(f.video_ylimit);
            f.plot_handles.videotext = text(vtx,vty,'','color',f.video_textcolor,'FontSize',f.video_textsize,'FontWeight',f.video_textweight,'interpret','none');
            for n = f.video_frame_range
                f.previous_frame = f.current_frame;
                f.current_frame = n;
                f.operateOnFrame;
                f.plot_handles.videotext.String = ['frame: ',num2str(n),' - t: ',num2str(n/f.ExpParam.fps,'%5.2f') ' sec'];
                [vidframe,~] = export_fig(f.plot_handles.ax,'-nocrop',f.video_figres);
                writeVideo(writerObj,vidframe);
            end
            f.plot_handles.videotext.String = '';
            close(writerObj);
        end
        
        function f = playVideo(f,skipFrame,initFrame,endFrame)
            % plays video with given frame skipping
            switch nargin
                case 3
                    endFrame = f.nframes; % all frames to the end
                case 2
                    endFrame = f.nframes; % all frames to the end
                    initFrame = 1; % from start
                case 1
                    endFrame = f.nframes; % all frames to the end
                    initFrame = 1; % from start
                    skipFrame = 1; % just play all frames
            end
            % refine the frames if floow fly is requested
            if ischar(f.followThisFlyNumber)
                if strcmp(f.followThisFlyNumber,'off')
                    f.followThisFlyNumber = nan;
                end
            end
            if isnan(f.followThisFlyNumber)||isempty(f.followThisFlyNumber)
                for n = initFrame:skipFrame:endFrame
                    f.previous_frame = f.current_frame;
                    f.current_frame = n;
                    f.operateOnFrame;
                    f.ui_handles.fig.Name = ['frame: ',num2str(n),' - t: ',num2str(n/f.ExpParam.fps,'%5.2f') ' sec'];
                    drawnow
                end
            else
                activeframes = find(f.tracking_info.fly_status(f.followThisFlyNumber,:)==1);
                for n = activeframes(1):skipFrame:activeframes(end)
                    f.previous_frame = f.current_frame;
                    f.current_frame = n;
                    f.operateOnFrame;
                    f.ui_handles.fig.Name = ['frame: ',num2str(n),' - t: ',num2str(n/f.ExpParam.fps,'%5.2f') ' sec'];
                    drawnow
                end
            end
        end
        
        
        function f = reOptAntenna(f)
            f.track_movie = false;
            f.run_signal_modules = false;
            % optimize antenna offset
            f = reOptAntOffset(f);
            
        end
        
        function f = reCalc2ROverlaps(f)
            % reset the overlap matrix
            f.tracking_info.antenna2R_overlap = zeros(size(f.tracking_info.antenna_overlap));
            f.track_movie = false;
            f.run_signal_modules = false;
            f.current_frame = 1;
            a = f.current_frame;
            tic
            for i = a:f.nframes
                f.previous_frame = f.current_frame;
                f.current_frame = i;
                f.operateOnFrame;
                % get the overlaps
                f = get2ROverlaps(f);
                t = toc;
                fps = (i-a)/t;
                disp(['frame# ' oval(f.current_frame) ' @ ' oval(fps) ' fps'])
            end
        end
        
        
        function f = extractSignal(f)
            f.track_movie = false;
            f.run_signal_modules = false;
            f.current_frame = 1;
            a = f.current_frame;
            tic
            for i = a:f.nframes
                f.previous_frame = f.current_frame;
                f.current_frame = i;
                f.operateOnFrame;
                % get the measurement
                if ~strcmp(f.antenna_type,'fixed')
                    f= optimizeAntOffsetatAllFrames(f);
                end
                f = getSignalMeasurements(f);
                t = toc;
                fps = (i-a)/t;
                disp(['frame# ' oval(f.current_frame) ' @ ' oval(fps) ' fps'])
            end
        end
        
        function f = trackNgetOrientations(f)
            f.track_movie = false;
            f.run_signal_modules = false;
            f.current_frame = 1;
            a = f.current_frame;
            tic
            for i = a:f.nframes
                f.previous_frame = f.current_frame;
                f.current_frame = i;
                f.operateOnFrame;
                % track flies
                % find objects in the first frame
                f = findAllObjectsInFrame(f);
                
                % map these objects onto flies, taking collisions etc into account
                f = mapObjectsOntoFlies(f);
                
                % get and set periphey status of the flies
                f = PeripheryStatus(f);
                
                % fix orientations -- figure out which end is the head
                f = getOrientations(f);
                
                
                % handle jumpers
                f = HandleJumpingFlies(f);
                
                % terminate lost flies
                f = removeLostFliesfor2Long(f);
                
                t = toc;
                fps = (i-a)/t;
                disp(['frame# ' oval(f.current_frame) ' @ ' oval(fps) ' fps'])
            end
        end
        
        function f = reProcessSignal(f)
            % optimizes natenna, measures virtual antenna signal, then
            % measures the box signal
            f.tracking_info.antenna2R_overlap = zeros(size(f.tracking_info.signal));
            f.tracking_info.antenna1R_overlap = zeros(size(f.tracking_info.signal));
            f.tracking_info.antoffsetAF = zeros(size(f.tracking_info.signal));
            f = getCIZoneStatus(f);
            f = getPeripheryStatus(f);
            
            f.track_movie = false;
            f.run_signal_modules = false;
            f.current_frame = 1;
            %             reOptAntenna(f);
            f.current_frame=1;
            f.show_annotation = false;
            f.operateOnFrame;
            
            a = f.current_frame;
            if ~isfield(f.tracking_info,'BoxSignalPxl')
                f.tracking_info.BoxSignalPxl = NaN(f.signalBoxSegmentNum,f.nframes,length(f.antoffset));
            end
            len = f.signalBoxSize(1)/f.ExpParam.mm_per_px;
            segment_edges = linspace(1,ceil(len/f.signalBoxSegmentNum)*f.signalBoxSegmentNum+1,f.signalBoxSegmentNum+1)-1;
            segment_edges = segment_edges/max(segment_edges)*f.signalBoxSize(1);
            segment_center = segment_edges + circshift(segment_edges,-1);
            segment_center = ((segment_center(1:end-1))/2)-f.signalBoxSize(1)/2;
            f.tracking_info.segment_edges = segment_edges;
            f.tracking_info.segment_center = segment_center;
            tic
            for i = a:f.nframes
                f.previous_frame = f.current_frame;
                f.current_frame = i;
                f.operateOnFrame;
                f = optimizeAntOffsetatAllFrames(f);
                f = getSignalMeasurements(f);
                % get the measurement
                f = getBoxSignalMeasPxl(f);
                if ~isempty(f.ui_handles)
                    if ~isempty(f.ui_handles.fig)
                        % show tracking annotation
                        showTrackingAnnotation(f)
                    end
                end
                t = toc;
                fps = (i-a)/t;
                disp(['frame# ' oval(f.current_frame) ' @ ' oval(fps) ' fps'])
            end
        end
        
        function f = extractBoxSignal(f)
            f.track_movie = false;
            f.run_signal_modules = false;
            f.current_frame = 1;
            a = f.current_frame;
            if ~isfield(f.tracking_info,'BoxSignalPxl')
                f.tracking_info.BoxSignalPxl = NaN(f.signalBoxSegmentNum,f.nframes,length(f.antoffset));
            end
            %             if ~isfield(f.tracking_info,'BoxSignal')
            %                 f.tracking_info.BoxSignal = NaN(f.signalBoxSegmentNum,f.nframes,length(f.antoffset));
            %             end
            len = f.signalBoxSize(1)/f.ExpParam.mm_per_px;
            segment_edges = linspace(1,ceil(len/f.signalBoxSegmentNum)*f.signalBoxSegmentNum+1,f.signalBoxSegmentNum+1);
            segment_center = segment_edges + circshift(segment_edges,-1);
            segment_center = ((segment_center(1:end-1))/2)/max((segment_center(1:end-1))/2)*f.signalBoxSize(1)-f.signalBoxSize(1)/2;
            f.tracking_info.segment_edges = segment_edges;
            f.tracking_info.segment_center = segment_center;
            tic
            for i = a:f.nframes
                f.previous_frame = f.current_frame;
                f.current_frame = i;
                f.operateOnFrame;
                % get the measurement
                %                 f = getBoxSignalMeasurements(f);
                f = getBoxSignalMeasPxl(f);
                t = toc;
                fps = (i-a)/t;
                disp(['frame# ' oval(f.current_frame) ' @ ' oval(fps) ' fps'])
            end
        end
        
        function f = track(f)
            f.track_movie = true;
            f.run_signal_modules = false;
            % run sthe tracking on the video with all moduels on
            a = f.current_frame;
            tic
            for i = a:f.nframes
                f.previous_frame = f.current_frame;
                f.current_frame = i;
                f.operateOnFrame;
                f = getFlyWalkingDir(f); % get heading
                t = toc;
                fps = (i-a)/t;
                disp(['frame# ' oval(f.current_frame) ' @ ' oval(fps) ' fps'])
            end
            
            f.track_movie = false;
        end
        
        function f = trackNRunSignalModules(f)
            f.track_movie = true;
            f.run_signal_modules = true;
            % run sthe tracking on the video with all moduels on
            a = f.current_frame;
            tic
            for i = a:f.nframes
                f.previous_frame = f.current_frame;
                f.current_frame = i;
                f.operateOnFrame;
                t = toc;
                fps = (i-a)/t;
                disp(['frame# ' oval(f.current_frame) ' @ ' oval(fps) ' fps'])
            end
            f = getCIZoneStatus(f);
            %              f = getPeripheryStatus(f); % now incorporated in the
            %              tracking
            f = getMaskedSignal(f);
            f.track_movie = false;
            f.run_signal_modules = false;
        end
        
        function f = operateOnFrame(f) % overloaded function that redefines what we do on each frame
            operateOnFrame@movieAnalyser(f);
            
            % reset object information
            f.current_object_status = [];
            f.current_objects = [];
            
            % track, if needed
            if f.current_frame > f.start_frame
                
                % subtract prestimulus median frame
                if f.subtract_prestim_median_frame
                    f.current_raw_frame = f.current_raw_frame - f.median_frame_prestim - f.median_frame_rand;
                end
                
                if f.correct_illumination
                    % save original frame for now
                    crfsave = f.current_raw_frame;
                    % correct illumination
                    f.current_raw_frame = double(f.current_raw_frame)./f.ExpParam.FlatNormImage;
                    % reset the thresholded area to ariginal
                    f.current_raw_frame(crfsave>=f.fly_body_threshold) = crfsave(crfsave>=f.fly_body_threshold);
                    clear crfsave
                end
                
                % update the displayed frame
                f.plot_handles.im.CData = uint8(f.current_raw_frame);
                
                if (~f.track_reverse)&&(f.current_frame<f.previous_frame)
                    
                else
                    if f.track_movie
                        % ok, we have to track
                        % find objects in the first frame
                        f = findAllObjectsInFrame(f);
                        if isnumeric(f.nframes_ref)
                            if any(f.current_frame == f.nframes_ref)
                                f = measureObjectReflections(f);
                            end
                        elseif strcmpi(f.nframes_ref,'all')
                            f = measureObjectReflections(f);
                        end
                        
                        % map these objects onto flies, taking collisions etc into account
                        f = mapObjectsOntoFlies(f);
                        
                        % handle jumpers
                        f = HandleJumpingFlies(f);
                        
                        % handle new object reflections
                        f = handleNewObjectsReflection(f);
                        
                        % handle centre reflection zone
                        f = handleCentreZoneReflection(f);
                        
                        % terminate lost flies
                        f = removeLostFliesfor2Long(f);
                        
                        % get and set periphey status of the flies
                        f = PeripheryStatus(f);
                        
                        % get the collision ignore zone status
                        f = getCIZoneStatus(f);
                        
                    end
                    
                    % apply signal moduels if requested
                    if f.run_signal_modules
                        
                        % fix orientations -- figure out which end is the head
                        f = getOrientations(f);
                        
                        %                         %% this module might be unnecessary
                        %                         if any(f.current_frame == f.nframes_ref)
                        %                             f = checkReflectionOverlaps(f);
                        %                         end
                        %                         % verify and remove in the future
                        
                        % optimize antenna offset
                        f = optimizeAntOffset(f);
                        
                        % optimize for each frame
                        f = optimizeAntOffsetatAllFrames(f);
                        
                        % measure the signal
                        f = getSignalMeasurements(f);
                        
                        % measure box signal
                        f = getBoxSignalMeasPxl(f);
                        
                    end
                    
                end
            end
            
            
            if ~isempty(f.ui_handles)
                if ~isempty(f.ui_handles.fig)
                    if f.show_annotation
                        % show tracking annotation
                        showTrackingAnnotation(f)
                    end
                end
            end
        end % end operateOnFrame
        
        
        function showTrackingAnnotation(f)
            
            if isempty(f.tracking_info)
                return
            end
            
            % indicate the number of flies we have
            if isempty(f.tracking_info.fly_status)
                nflies = 0;
            else
                nflies = sum(f.tracking_info.fly_status(:,f.current_frame)==1);
            end
            [~,flnm,~] = fileparts(f.fwName);
            f.ui_handles.fig.Name = [flnm,' -- ',f.ui_handles.fig.Name ' -- t:' num2str(f.current_frame/f.ExpParam.fps,'%5.2f') ' sec -- ' oval(nflies) ' flies'];
            
            f.showFlies;
            
            f.showReflections;
            
            % show the orientations if requested
            f.showFlyOrientations;
            %
            % show fitted ellipses if requested
            f.showEllipsFits;
            
            % show antenna blobs if requested
            f.showAntenna;
            
            % show flow field if requested and exists
            f.showFlowField;
            
            % show wind directions on the antenna
            f.showWindDir;
            
            % show wind speed values
            f.showWindSpeed;
            
            % show piv mask if requested
            f.showPIVMask;
            
            % adjust the limits if fly following requested
            f.followThisFly;
            
            
            drawnow limitrate
        end
        
        % overload the createGUI to add some interactivity
        function f = createGUI(f)
            createGUI@movieAnalyser(f);
            % 			f.ui_handles.fig.WindowButtonDownFcn = @f.mousecallback;
            % add a checkbox for tracking
            f.ui_handles.track_button = uicontrol(f.ui_handles.fig,'Style','togglebutton','String','tracking ON','Units','normalized','Position',[0.75 0.01 0.1 0.0500],'Callback',@f.trackButtonCallback);
            if ~f.track_movie
                f.ui_handles.track_button.String = 'tracking OFF';
            end
            % update the displayed frame
            f.ui_handles.fig.Colormap = buildcmap('wkkkccb');
            
            % add some placeholders for fly positions and trajectories
            c = [jet(round(size(f.tracking_info.fly_status,1)/2)); jet(round(size(f.tracking_info.fly_status,1)/2))];
            c = c(randperm(size(c,1)),:);
            if size(f.tracking_info.fly_status,1)>size(c,1)
                lendif = size(c,1)-size(f.tracking_info.fly_status,1);
                c(end+1:end+lendif,:) = c(1:lendif,:);
            end
            try
                f.plot_handles = rmfield(f.plot_handles,'fly_trajectories');
            catch
            end
            try
                f.plot_handles = rmfield(f.plot_handles,'fly_positions');
            catch
            end
            try
                f.plot_handles = rmfield(f.plot_handles,'fly_markers');
            catch
            end
            try
                f.plot_handles = rmfield(f.plot_handles,'orientations');
            catch
            end
            try
                f.plot_handles = rmfield(f.plot_handles,'fly_antenna');
            catch
            end
            % replicate the antenna in case segmented box antenna is
            % requested
            try
                f.plot_handles = rmfield(f.plot_handles,'fly_antenna_seg');
            catch
            end
            try
                f.plot_handles = rmfield(f.plot_handles,'ellipses');
            catch
            end
            try
                f.plot_handles = rmfield(f.plot_handles,'tracks');
            catch
            end
            try
                f.plot_handles = rmfield(f.plot_handles,'track_marker');
            catch
            end
            try
                f.plot_handles = rmfield(f.plot_handles,'headings');
            catch
            end
            try
                f.plot_handles = rmfield(f.plot_handles,'labels');
            catch
            end
            try
                f.plot_handles = rmfield(f.plot_handles,'reflections');
            catch
            end
            try
                f.plot_handles = rmfield(f.plot_handles,'flowField');
            catch
            end
            try
                f.plot_handles = rmfield(f.plot_handles,'windDir');
            catch
            end
            try
                f.plot_handles = rmfield(f.plot_handles,'windSpeed');
            catch
            end
            try
                f.plot_handles = rmfield(f.plot_handles,'pivMask');
            catch
            end
            for i = size(f.tracking_info.fly_status,1):-1:1
                f.plot_handles.fly_markers(i) = plot(NaN,NaN,'o','MarkerSize',20,'Color',c(i,:),'LineWidth',3);
                f.plot_handles.fly_positions(i) = plot(NaN,NaN,'o','Color',c(i,:),'LineWidth',2,'MarkerSize',3);
                f.plot_handles.fly_trajectories(i) = plot(NaN,NaN,'Color',c(i,:),'LineWidth',2);
                f.plot_handles.orientations(i) = plot(NaN,NaN,'k','LineWidth',3);
                f.plot_handles.headings(i) = plot(NaN,NaN,'Color',c(i,:),'LineWidth',3);
                f.plot_handles.fly_antenna(i) = plot(NaN,NaN,'om');
                f.plot_handles.fly_antenna_seg(i) = plot(NaN,NaN,'og');
                f.plot_handles.ellipses(i) = plot(NaN,NaN,'r--');
                f.plot_handles.reflections(i) = plot(NaN,NaN,'g--','LineWidth',3);
                f.plot_handles.labels(i) = text(NaN,NaN,num2str(i),'color','k','FontSize',13,'FontWeight','Bold');
                f.plot_handles.windSpeed(i) = text(NaN,NaN,'','color','g','FontSize',13,'FontWeight','Bold');
                f.plot_handles.windDir(i) = quiver(NaN,NaN,NaN,NaN,f.windDirColor,'AutoScaleFactor',f.windDirScaleFactor,'LineWidth',f.windDirLineWidth,'MaxHeadSize',7);
            end
            % create handles for tracks verification
            lnlist = {'k','r','b','m','g','c','y','k:','r:','b:','m:','g:','c:','y:'};
            clrlist = {'k','r','b','m','g','c','y','k','r','b','m','g','c','y'};
            for i = 1:14
                f.plot_handles.tracks(i) = plot(NaN,NaN,lnlist{i},'LineWidth',5);
                f.plot_handles.track_marker(i) = plot(NaN,NaN,'o','MarkerSize',20,'Color',clrlist{i},'LineWidth',3);
            end
            
            % create flow field handles
            f.plot_handles.flowField = quiver(NaN,NaN,NaN,NaN,f.flowFieldColor,'AutoScaleFactor',f.flowFieldScaleFactor);
            
            % create handles for piv mask
            f.plot_handles.pivMask = plot(NaN,NaN,f.pivMaskColor);
            
            
            
            
        end
        
        function f = mousecallback(f,~,~)
            p = f.plot_handles.ax.CurrentPoint;
            p = p(1,1:2);
            
            if min(p) < 1
                return
            end
            if p(1) > size(f.current_raw_frame,2)
                return
            end
            if p(2) > size(f.current_raw_frame,1)
                return
            end
            showClosestFly(f,p);
        end
        
        function f = trackButtonCallback(f,src,event)
            if strcmp(src.String ,'tracking ON')
                src.String = 'tracking OFF';
                f.track_movie = false;
            else
                src.String = 'tracking ON';
                f.track_movie = true;
            end
        end
        
        function f = initialise(f)
            
            % do we have some saved stuff?
            if exist(f.fwName,'file') == 2
                if f.ft_debug
                    disp('Saved data exists; loading...')
                end
                load(f.fwName,'-mat')
                temp = f.path_name;
                tfwn = f.fwName;
                f = fly_walk_obj;
                if(f.fly_walk_version<0.8)||isempty(f.videoType)
                    f.videoType = 'mat'; % probably saved with a previous flywalk version
                    f.fwName = tfwn;
                end
                if strcmp(f.videoType,'mat')
                    f.path_name = temp.Properties.Source;
                else
                    f.path_name = [temp.Path,filesep,temp.Name];
                end
                if ~isfield(f.ExpParam,'FlatNormImage')
                    % get illumination correction image
                    f.ExpParam = getFlatNormImage(f.ExpParam);
                end
                
                % get prestimulus median frame if not loaded
                if isempty(f.median_frame_prestim)
                    f = getMedianFramePreStimulus(f);
                end
                
            else
                % load parameters such as mask, camera and background image
                f.loadExpParameters;
                
                % rescale parameters
                f = scaleParameters(f);
                
                if f.ft_debug
                    disp('No saved data. Initializing a new object...')
                end
                
                % load the first frame
                f.operateOnFrame;
                
                if ~isfield(f.ExpParam,'FlatNormImage')
                    % get illumination correction image
                    f.ExpParam = getFlatNormImage(f.ExpParam);
                    % save it into the p file
                    % save the median frame to p
                    p = f.ExpParam;
                    if strcmp(f.videoType,'mat')
                        if exist([f.path_name.Properties.Source(1:end-11),'.mat'],'file')
                            save([f.path_name.Properties.Source(1:end-11),'.mat'],'p','-append');
                        end
                    elseif strcmp(f.videoType,'avi')||strcmp(f.videoType,'mj2')
                        if exist([f.path_name.Path,filesep,f.path_name.Name(1:end-4),'.mat'],'file')
                            save([f.path_name.Path,filesep,f.path_name.Name(1:end-4),'.mat'],'p','-append');
                        end
                    end
                    disp('Flat image is saved into the original mat file');
                end
                
                % get prestimulus median frame if not loaded
                if isempty(f.median_frame_prestim)
                    f = getMedianFramePreStimulus(f);
                end
                
                % find objects in the start frame
                f.current_frame = 1;
                f.previous_frame = 1;
                
                % correct illumination
                if f.correct_illumination
                    f.current_raw_frame = double(f.current_raw_frame)./f.ExpParam.FlatNormImage;
                end
                
                % subtract prestimulus median frame
                if f.subtract_prestim_median_frame
                    f.current_raw_frame = double(f.current_raw_frame) - double(f.median_frame_prestim);
                end
                
                % update the displayed frame
                f.plot_handles.im.CData = uint8(f.current_raw_frame);
                
                f = findAllObjectsInFrame(f);
                
                % make placeholders and assign objects to new flies
                f = makeTrackingInfoPlaceholders(f);
                
                % initiate the signal saving matrix
                f.tracking_info.(['signal_',f.antenna_shape,'_',f.antenna_type]) = zeros(size(f.tracking_info.signal));
                
                % measure reflections
                f = measureObjectReflections(f);
                
                f = assignObjectsToNewFlies(f);
                % find centre zone flies
                f = findCentreZoneflies(f);
                
                % set intensity gradient orientation
                f = getAllFlyGradOrs(f);
                
                %                 % get the prestimulus median frame
                %                 f = getMedianFramePreStimulus(f);
                
                % show annotation
                if ~isempty(f.ui_handles)
                    if ~isempty(f.ui_handles.fig)
                        if f.show_annotation
                            % show tracking annotation
                            showTrackingAnnotation(f)
                        end
                    end
                end
                
            end
            
            
            
            
        end % end initialise
        
        function f = save(f)
            % remove the extra variable space if not deleted
            f = removeExtraVariableSpaceFromData(f);
            % first, close all the chrome
            f.quitMovieAnalyser;
            fly_walk_obj = f;
            if strcmp(f.videoType,'mat')
                save([f.path_name.Properties.Source(1:end-11) ,'.flywalk'],'fly_walk_obj','-v7.3')
            elseif strcmp(f.videoType,'avi')||strcmp(f.videoType,'mj2')
                save([f.path_name.Path,filesep,f.path_name.Name(1:end-4),'.flywalk'],'fly_walk_obj','-v7.3');
            end           
        end % end save
        
    end % end methods
end % end classdef

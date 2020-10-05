%% annotateVideo
% video annotation GUI built on top of movieAnalyser


classdef annotateVideo < movieAnalyser

	properties
		mask = NaN;
	end % end properties

	methods

		function a = annotateVideo()
			% look in the current folder for movies and load them
			allfiles = dir('*.mat');
			% remove .mat files with "annotation" in them
			rm_this = false(length(allfiles),1);
			for i = 1:length(allfiles)
				if any(strfind(allfiles(i).name,'annotation'))
					rm_this(i) = true;
				end
			end
			allfiles(rm_this) = [];

			% load the first file. 
			a.path_name = allfiles(1).name;


			a.createGUI;
		end

		function a = createGUI(a)


			createGUI@movieAnalyser(a);

			p = a.handles.next_button.Position;
			p(1) = p(1) + .1;
			a.handles.mark_roi_button = uicontrol(a.handles.fig,'Units',a.handles.next_button.Units,'Position',p,'Style','pushbutton','String','Mark Crop','Callback',@a.markCrop);


			p = a.handles.next_button.Position;
			p(1) = p(1) + .2;
			a.handles.mark_stim_start_button = uicontrol(a.handles.fig,'Units',a.handles.next_button.Units,'Position',p,'Style','pushbutton','String','Mark Stim. Start','Callback',@a.markStimStart);


	
			a.operateOnFrame;

		end % end create GUI

		function a = markStimStart(a,~,~)
			a.median_stop = a.current_frame;
			saveTrackData(a);
		end

		function a = markCrop(a,~,~)
			h = imrect(a.handles.ax);
        	crop_box = wait(h);
        	a.mask = createMask(h);
        	a.handles.fig.Name = ('Crop box saved!');
        	saveTrackData(a);
		end


		function  saveTrackData(a)

		    [parent_dir,root_name] = fileparts(a.path_name.Properties.Source);
		    mask = a.mask;
		    stim_start = a.median_stop;
		    save([parent_dir oss root_name '_annotation.mat'],'mask','stim_start');
		    
		    
		end


	end % end methods
end
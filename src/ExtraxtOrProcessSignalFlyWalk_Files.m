function [log,done] = ExtraxtOrProcessSignalFlyWalk_Files(pathlist,fid,gui_on,subt_median)
% tracks and saves all files given in pathlist

switch nargin
    case 3
        subt_median = 0;
    case 2
        subt_median = 0;
        gui_on = 0;
    case 1
        subt_median = 0;
        gui_on = 0;
        fid = []; %do not log in to a file
end

log = {};
done = zeros(numel(pathlist),1);

for i = 1:numel(pathlist)
    if ~isempty(fid)
        fprintf(fid, '%s\n',num2str(i));
        fprintf(fid, '%s\n',pathlist{i});
        fprintf(fid, ' \n');
    end
    disp(pathlist(i))
    try
        if ~exist([pathlist{i}(1:end-4),'.flywalk'],'file')
            fprintf(fid, 'there is NOT a saved file \n');
            fprintf(fid, 'starting a new one \n');
            close all
            f = flyWalk;
            filename = pathlist{i};
            f.path_name  = [filename(1:end-4),'-frames.mat'];
            f.variable_name = 'frames';
            f.subtract_median = subt_median;
            f.track_movie = true;
            f = f.initialise;
            f.ft_debug = true;
            if gui_on
                f.createGUI;
            end
            f.show_split = false;
            f.label_flies = true;
            f.show_antenna = true;
            f.show_annotation = 1;
            f.track;
            f.save;
            clear f
            done(i) = 1;
            disp(['completed file:',pathlist{i}])
            fprintf(fid, 'track complete and saved. \n');
        else
            if ~isempty(fid)
                fprintf(fid, 'there is a saved file \n');
            end
            f=openFileFlyWalk(pathlist{i},gui_on,subt_median);
            f.track_movie = false;
            f.show_split = false;
            f.label_flies = true;
            f.show_orientations = false;
            f.show_antenna = true;
            f.show_trajectories = false;
            f.mark_lost = 0;
            f.mark_flies = 0;
            if ~isfield(f.ExpParam,'FlatNormImage')
                f = getFlatNormImage(f);
                setFigure;
                imagesc(f.ExpParam.FlatNormImage)
                colorbar
            else
                setFigure;
                imagesc(f.ExpParam.FlatNormImage)
                colorbar
            end
            f.current_frame = 1;
            if ~isfield(f.tracking_info,'antoffsetAF')
                f.antoffset_lim = [0.75,1.2];
                f.antlen = 2;                 % factor to divide fly maj axis to get antenna major axis
                f.antwd = 6;
                f.antenna_opt_dil_n = 6;
                f.antenna_type = 'dynamic';   % fixed: distance to fly center is fixed, dynamic: moved away if overlaps with secondary reflection
                f.R2Resize = 1.15;             % enlarge the secondary antenna for optimization
                f.tracking_info.signal_fix = f.tracking_info.signal; 
                f.reProcessSignal;
            end
            if ~isfield(f.tracking_info,'coligzone')
                f = getCIZoneStatus(f);
            end
            if ~isfield(f.tracking_info,'periphery')
                f = getPeripheryStatus(f);
            end
            if ~isfield(f.tracking_info,'perimeter')
                f = getPerimeterNEccent(f);
            end
            f = getMaskedSignal(f);
            f.save;
            fprintf(fid, 'file is resaved on the same object \n');
            clear f
            close all
            done(i) = 2;
        end
        
        if ~isempty(fid)
                fprintf(fid, 'track complete and saved. \n');
                fprintf(fid, ' \n');
        end
    catch ME
        log = [log;{ME.message}];
        if ~isempty(fid)
                fprintf(fid, 'there was a problem. \n');
                fprintf(fid, '%s\n',ME.message);
                fprintf(fid, ' \n');
        end
    end
        
      
end

% display if there is any message
if isempty(log)
    disp('all files are done')
else
    disp(log)
end
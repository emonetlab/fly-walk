function [log,done] = reExtBoxSignalFlyWalk_Files(pathlist,fid,gui_on,subt_median)
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
            a = 1;
            tic
            for frmi = 1:f.nframes
                f.previous_frame = f.current_frame;
                f.current_frame = frmi;
                f.operateOnFrame;
                f = getBoxSignalMeasPxl(f);
                t = toc;
                fps = (frmi-a)/t;
                disp(['frame# ' oval(f.current_frame) ' @ ' oval(fps) ' fps'])
            end
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
function [log,done] = trackFilesFlyWalk(pathlist,fid,over_write,gui_on,subt_median)
% tracks and saves all files given in pathlist

switch nargin
    case 4
        subt_median = 0;
    case 3
        subt_median = 0;
        gui_on = 0;
    case 2
        subt_median = 0;
        gui_on = 0;
        over_write = 1;
    case 1
        subt_median = 0;
        gui_on = 0;
        over_write = 1;
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
        if over_write
            if exist([pathlist{i}(1:end-4),'.flywalk'],'file')
                delete([pathlist{i}(1:end-4),'.flywalk'])
                disp('old file is deleted')
            end
            if ~isempty(fid)
                fprintf(fid, 'old file is deleted \n');
            end            
        end
        if ~exist([pathlist{i}(1:end-4),'.flywalk'],'file')
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
            f.track;
            f.save;
            clear f
            done(i) = 1;
            disp(['completed file:',pathlist{i}])
        else
            if ~isempty(fid)
                fprintf(fid, 'there is a saved file \n');
            end
            done(i) = 2;
            disp('there was a saved file')
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
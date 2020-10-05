function saveFileFlyWalk(filename,f)
% loads the flywalk file for

% close all
fly_walk_obj= f;
save([filename(1:end-4),'.flywalk'],'fly_walk_obj','-v7.3');

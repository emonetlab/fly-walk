function f=loadFileFlyWalk(filename)
% loads the flywalk file for

% close all
f = load([filename(1:end-4),'.flywalk'],'-mat');
f = f.fly_walk_obj;



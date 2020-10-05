function [frames,p] = CropFrames(frames,p)
%% set cropping
% these cropping parameters are hardwired acoording to my arena. If the ROI
% of the camera or the the walking arena is changed then this parameters
% would have to be changed. 
% in order to use this code effectively handle experimental videos with the
% GUI: HandleFlyWalk first.
% this function crops the frames with crop_box in parameter space p and
% also update the location of the source and the camera

% now crop from all sides
%left
frames(1:p.crop_box.lcrp,:,:) = [];

%update camera and source
p.source.x = p.source.x - p.crop_box.lcrp;
p.camera.x = p.camera.x - p.crop_box.lcrp;

% crop right
frames(end-p.crop_box.rcrp+1:end,:,:) = [];

% crop top (lower y values in the matrix)
frames(:,1:p.crop_box.tcrp,:) = [];

%update camera and source
p.source.y = p.source.y - p.crop_box.tcrp;
p.camera.y = p.camera.y - p.crop_box.tcrp;

% crop bottom (higher y values in the matrix)
frames(:,end-p.crop_box.bcrp+1:end,:) = [];

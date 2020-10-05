function takePIVOutFlyWalkFile(filename)

% load the flywalk file
f = load([filename(1:end-4),'.flywalk'],'-mat');
f = f.fly_walk_obj;

% check if there is PIV saved
if isfield(f.tracking_info,'PIV')
    PIV = f.tracking_info.PIV;
    % remove PIV from the flywalk
    f.tracking_info = rmfield(f.tracking_info,'PIV');
    
    save([filename(1:end-4),'-PIV.mat'],'PIV','-v7.3')
    disp([filename(1:end-4),'-PIV.mat is saved'])
    
    % now save files
    fly_walk_obj = f;
    save([filename(1:end-4),'.flywalk'],'fly_walk_obj','-v7.3')
    disp([filename(1:end-4),'.flywalk is saved'])
else
    disp([filename(1:end-4),'.flywalk does not include PIV'])
end
function f = fixFlyOrientFlips(f,angle_flip_threshold,boxsigind)
% corrects sudden fly direction flips, resets the signal from box measurement
if isfield(f.tracking_info,'fixedFlyOrientFlips')
    disp('already flipped. remove field: fixedFlyOrientFlips in order to flip it')
    return
end

switch nargin
    case 2
        boxsigind = 5; % use this segment if box signal is measured
    case 1
        boxsigind = 5;
        angle_flip_threshold = 120; % degree, angle difference larger than this indicates direction flip
end


nof_flies = find(f.tracking_info.fly_status(:,end)>0,1,'last');
tin = f.tracking_info;

for i = 1:nof_flies
    jind=find(abs(angleDiffVec(f.tracking_info.orientation(i,:)))>angle_flip_threshold);
    mask_neg = find(f.tracking_info.mask_of_signal(i,:)==0);
    flyKalVel = getFlyKalVel(f,i,round(.3*f.ExpParam.fps)); % estimate filtered speed with a length of 300 ms
    if any(sum(jind==mask_neg',1))
        jind(logical(sum(jind==mask_neg',1)))=[];
    end
    % there most be even number of points
    if mod(length(jind),2)==0 % now flip the directions and correct the signal
        for flind = 1:(length(jind)/2)
            flil = (flind-1)*2+1;
            flir = (flind-1)*2+2;
            if mean(flyKalVel(jind(flil)+1:jind(flir)))<f.immobile_speed*7
                if isfield(tin,'BoxSignalPxl')
                    tin.signalm(i,jind(flil)+1:jind(flir)) = tin.BoxSignalPxl(boxsigind,jind(flil)+1:jind(flir),i); % get reversed signal
                    %flip the box signal
                    tin.BoxSignalPxl(:,jind(flil)+1:jind(flir),i) = flipud(tin.BoxSignalPxl(:,jind(flil)+1:jind(flir),i));
                else
                    tin.signalm(i,jind(flil)+1:jind(flir)) = 0;
                end
                % correct the orientation
                tin.orientation(i,jind(flil)+1:jind(flir)) = mod(tin.orientation(i,jind(flil)+1:jind(flir))+180,360);
            end
        end
    end
end
tin.fixedFlyOrientFlips = 1;    
f.tracking_info = tin;
function f = getPeripheryStatusFrame(f)
% checks if flies are in the periphery and save it in
% tracking_info.periphery

current_flies = find(f.tracking_info.fly_status(:,f.current_frame)==1);
cfps = isFlyInthePeriferi(f,current_flies);
f.tracking_info.periphery(current_flies,f.current_frame) = cfps;

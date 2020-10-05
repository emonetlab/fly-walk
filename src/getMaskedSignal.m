function f = getMaskedSignal(f,maskdilate)

if nargin<2
    maskdilate = 3;
end


f.tracking_info.signalm = f.tracking_info.signal;
f.tracking_info.mask_of_signal = f.tracking_info.signal;
tot_num_of_flies = find(f.tracking_info.fly_status(:,end)>0,1,'last');


for i = 1:tot_num_of_flies
    maskp = (f.tracking_info.periphery(i,:)>0);
    maskciz = (f.tracking_info.coligzone(i,:)>0);
    maskc = (f.tracking_info.collision(i,:)>0);
    masko = (f.tracking_info.overpassing(i,:)>0);
    maskj = (f.tracking_info.jump_status(i,:)>0);
    maskao = (f.tracking_info.antenna_overlap(i,:)>0);
    maska1o = (f.tracking_info.antenna1R_overlap(i,:)>0);
    masksize = (f.tracking_info.area(i,:)<(nanmean(f.tracking_info.area(i,:))-2*nanstd(f.tracking_info.area(i,:))));
    
    mask = maskp + maskciz + maskc + masko + maskj + maskao + maska1o + masksize;
    if strcmp(f.antenna_type,'fixed')
        maska2o = (f.tracking_info.antenna2R_overlap(i,:)>0); %blocked since antenna is adjusted for that
        mask = mask + maska2o; 
    end
    mask = mask>0;
    mask = imdilate(mask,strel('disk',maskdilate));

    f.tracking_info.signalm(i,mask) = 0;
    f.tracking_info.mask_of_signal(i,:) = ~mask; % 1: clean signal, 0: signal is probably not accurate
end


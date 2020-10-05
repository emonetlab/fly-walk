function stats = getExpStat(expmat,col,ssco)
%getExpStat
% getExpStat extracts the statistics in the experiment
switch nargin % assume the following column headers
    case 2
        ssco = 2;   % speed stop cutoff (mm/s)
    case 1
        ssco = 2;   % speed stop cutoff (mm/s)
        if size(expmat,2)==29
            colhead = {'trjNum','vialNum','trialNum','trj_ind','t','x','y','vx','vy',...
                    'speed','theta','a','b','area','signal','dtheta',...
                    'frnnum','waldir','dwaldir','fps','mm_per_px','sx','sy',...
                    'nofflies','starve_day','age_day','room_Temp','room_Hum','fileindex'};
        elseif size(expmat,2)==25
            colhead = {'trjNum','vialNum','trialNum','trj_ind','t','x','y','vx','vy',...
                    'speed','theta','a','b','area','signal','dtheta',...
                    'frnnum','waldir','dwaldir','fps','mm_per_px','sx','sy',...
                    'nofflies','fileindex'};
        elseif size(expmat,2)==34
            colhead = {'trjNum','vialNum','trialNum','trj_ind','t','x','y','vx','vy',...
                'speed','theta','a','b','area','signal','dtheta',...
                'frnnum','waldir','dwaldir','fps','mm_per_px','sx','sy',...
                'nofflies','starve_day','age_day','room_Temp','room_Hum',...
                'reflection','collision','overpass','jump','fly_status','fileindex'};
        elseif size(expmat,2)==43
            colhead = {'trjNum','vialNum','trialNum','trj_ind','t','x','y','vx','vy',...
                'speed','theta','a','b','area','signal','dtheta',...
                'frnnum','waldir','dwaldir','fps','mm_per_px','sx','sy',...
                'nofflies','starve_day','age_day','room_Temp','room_Hum',...
                'reflection','collision','overpass','jump','fly_status',...
                'onset_num','peak_num','offset_num','signal_threshold',...
                'excent','perimeter','coligzone','periphery','signal_mask',...
                'fileindex'};
        elseif size(expmat,2)==45
            colhead = {'trjNum','vialNum','trialNum','trj_ind','t','x','y','vx','vy',...
                'speed','theta','a','b','area','signal','dtheta','frnnum','waldir',...
                'dwaldir','fps','mm_per_px','sx','sy','nofflies','starve_day',...
                'age_day','room_Temp','room_Hum','reflection','collision',...
                'overpass','jump','fly_status','onset_num','peak_num','offset_num',...
                'signal_threshold','excent','perimeter','coligzone','periphery',...
                'signal_mask','wind_dir','wind_speed','fileindex'};
        else
            error('need correct column header')
        end
        % get the column outputs to sturcture inputs
        for i = 1:numel(colhead)
            col.(colhead{i}) = i;
        end
        
end

% get number of tracks
stats.ntrj = numel(unique(expmat(:,col.trjNum)));

% get number of experiments (vials)
stats.nexp = numel(unique(expmat(:,2)));

% get number of videos
stats.nfile = numel(unique(expmat(:,col.fileindex)));

% get length of the experiment
stats.lenexp = max(expmat(:,col.t));

% get trajectory lengths
trjlist = unique(expmat(:,col.trjNum));
lentrj = zeros(numel(trjlist),1);   % track length list
spdltrj = zeros(numel(trjlist),1);  % tracks speed list
pstoplist = zeros(numel(trjlist),1);  % tracks stop probability list
for i = 1:numel(trjlist)
    thisexpmat = expmat(expmat(:,col.trjNum)==trjlist(i),:); 
    lentrj(i) = size(thisexpmat,1)/mean(thisexpmat(:,col.fps));
    spdltrj(i) = mean(thisexpmat(:,col.speed));
    pstoplist(i) = sum(thisexpmat(:,col.speed)<ssco)/size(thisexpmat,1);
end
stats.lentrj = lentrj;
stats.spdltrj = spdltrj;
stats.pstoplist = pstoplist;

% stop probablity of all values included
pstopall = sum(expmat(:,col.speed)<ssco)/size(expmat(:,col.speed),1);  % tracks stop probability list
stats.pstopall = pstopall;


% get average speed
stats.mspd = mean(expmat(:,col.speed));
explist = unique(expmat(:,col.vialNum));
spdema = zeros(numel(explist),1); % average all instantaneous speed
spdemt = zeros(numel(explist),1); % average speeds of trajectories
ExpFlyNum = zeros(size(explist));
for i = 1:numel(explist)
    % go over experiments and average speed
    thisexpmat = expmat(expmat(:,col.vialNum)==explist(i),:);
    spdema(i) = mean(thisexpmat(:,col.speed));
    % go over all tracks and average
    trjlist = unique(thisexpmat(:,col.trjNum));
    for j = 1:numel(trjlist)
        spdemt(i) = spdemt(i) + mean(thisexpmat(thisexpmat(:,col.trjNum)==trjlist(j),col.speed));
    end
    spdemt(i) = spdemt(i)/numel(trjlist);
    % how many trials
    Trials = unique(thisexpmat(:,col.trialNum));
    NFlyTrial = zeros(size(Trials));
    for j = 1:length(Trials)
        thisTrial = Trials(j);
        NFlyTrial(j) = median(thisexpmat(thisexpmat(:,col.trialNum)==thisTrial,col.nofflies));
    end
    ExpFlyNum(i) = round(median(NFlyTrial));
end
stats.spdema = spdema;
stats.spdemt = spdemt;
stats.ExpFlyNum = ExpFlyNum;
stats.UniqueTotFlyNum = sum(ExpFlyNum);

% get average speed for each video
vidlist = unique(expmat(:,col.fileindex));
spdvma = zeros(numel(vidlist),1); % average all instantaneous speed
spdvmt = zeros(numel(vidlist),1); % average speeds of trajectories
expnum = zeros(numel(vidlist),1); % labels for experiments
trialnum = zeros(numel(vidlist),1); % labels for trials
mtrjlen= zeros(numel(vidlist),1); % labels for trials
noftrj = zeros(numel(vidlist),1); % number of tracks in each video

for i = 1:numel(vidlist)
    % go over the trials and average speed
    thisexpmat = expmat(expmat(:,col.fileindex)==vidlist(i),:);
    spdvma(i) = mean(thisexpmat(:,col.speed));
    % go over all tracks and average
    trjlist = unique(thisexpmat(:,col.trjNum));
    for j = 1:numel(trjlist)
        spdvmt(i) = spdvmt(i) + mean(thisexpmat(thisexpmat(:,col.trjNum)==trjlist(j),col.speed));
        mtrjlen(i) =  mtrjlen(i) + length(thisexpmat(thisexpmat(:,col.trjNum)==trjlist(j),col.speed))/mean(thisexpmat(thisexpmat(:,col.trjNum)==trjlist(j),col.fps));
    end
    spdvmt(i) = spdvmt(i)/numel(trjlist);
    expnum(i) = thisexpmat(1,col.vialNum);
    trialnum(i) = thisexpmat(1,col.trialNum);
    mtrjlen(i) = mtrjlen(i)/numel(trjlist);
    noftrj(i) =  numel(trjlist);
end
stats.spdvma = [mean(spdvma),std(spdvma)];
stats.spdvmt = [mean(spdvmt),std(spdvmt)];
stats.mtrjlen = [mean(mtrjlen),std(mtrjlen)];
stats.noftrj = [mean(noftrj),std(noftrj)];
% stats.expnum = expnum;
% stats.trialnum = trialnum;


% get lists of variables for each video recorded
fps = GetValExpMat(expmat,col.fps); % fps
stats.fps = [mean(fps),std(fps)];

nofly = GetValExpMat(expmat,col.nofflies); % # of flies
stats.noflym = [mean(nofly),std(nofly)];
stats.noflyt = sum(nofly);

% construct the table
vidname = cell(stats.nfile,1);
for i=1:stats.nfile
    vidname(i) = {['vid-',num2str(i)]};
end
T = table(expnum,trialnum,noftrj,mtrjlen,spdvma,spdvmt,fps,nofly,...
    'RowNames',vidname);


if isfield(col,'starve_day')
    starve = GetValExpMat(expmat,col.starve_day); % # of days flies starved
    stats.starve = [mean(starve),std(starve)];
    T.starve = starve;
end

if isfield(col,'age_day')
    age = GetValExpMat(expmat,col.age_day); % # of days, flies age
    stats.age = [mean(age),std(age)];
    T.age = age;
end

if isfield(col,'room_Temp')
    roomT = GetValExpMat(expmat,col.room_Temp); % temperature of the room
    stats.roomT = [mean(roomT),std(roomT)];
    T.roomT = roomT;
end

if isfield(col,'room_Hum')
    roomH = GetValExpMat(expmat,col.room_Hum); % humidity of the room
    stats.roomH = [mean(roomH),std(roomH)];
    T.roomH = roomH;
end

stats.T = T;


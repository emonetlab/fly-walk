function expmat = RedExpMat(expmat,nfly,ntrj,minspd,maxspd,mintrjlen,minTraveledDistance)
%RedExpMat
% expmat = RedExpMat(expmat,nfly,ntrj,minspd,maxspd,mintrjlen)
% return the experimental giant matix after reducing size to contain
% specified number of flies nfly or number of tracks ntrj.
%
% this code assumes an experimental giant matrix with these headers
% TableHeaders = {trj-1 exp_ind-2 trial_ind-3 trj_ind-4 t-5 x-6 y-7 vx-8 vy-9,...
%                 spd-10 theta-11 a-12 b-13 area-14 signal-15 dtheta-16,...
%                 frnnum-17 waldir-18 dwaldir-19 fps-20 mm_per_px-21 sx-22 sy-23,...
%                 nofflies-24 starve_day-25 age_day-26 room_Temp-27
%                 room_Hum-28 fileindex-29};
% UPDATE 06/20/19: expmat can be the expdata which contains the expmat and
% the col. If it is not the structure then it assumes fps column
% is 20. col should have fields: fps, fileindex, speed, nofflies, and x and
% y if totpath constraint is used
%

switch nargin
    case 6
        minTraveledDistance = 'na';
    case 5
        minTraveledDistance = 'na';
        mintrjlen = 'na'; % sec
    case 4
        minTraveledDistance = 'na';
        mintrjlen = 'na'; % sec
        maxspd = 'na';
    case 3
        minTraveledDistance = 'na';
        mintrjlen = 'na'; % sec
        maxspd = 'na';
        minspd = 'na';
    case 2
        minTraveledDistance = 'na';
        mintrjlen = 'na'; % sec
        maxspd = 'na';
        minspd = 'na';
        ntrj = 'all';
    case 1
        minTraveledDistance = 'na';
        mintrjlen = 'na'; % sec
        maxspd = 'na';
        minspd = 'na';
        ntrj = 'all';
        nfly = 'all';
end

if isstruct(expmat)
    assert(isfield(expmat,'expmat'),'expmat is not a field in the input sturcture')
    assert(isfield(expmat,'col'),'col is not a field in the input sturcture')
    assert(isfield(expmat.col,'fps'),'col is not a field in the input sturcture')
    IEM = expmat;
    expmat = IEM.expmat;
    col = IEM.col;
else
    col = [];
end

if isempty(col)
    colindnum = size(expmat,2);
    speedColNum = 10;
    nflyColNum = 24;
    fpsColNum = 20;
    colnumx = 6;
    colnumy = 7;
else
    colindnum = col.fileindex;
    speedColNum = col.speed;
    nflyColNum = col.nofflies;
    fpsColNum  = col.fps;
    colnumx = col.x;
    colnumy = col.y;
end
% if ntrj is given then ignore nfly
req_state1 = [isnumeric(ntrj),isnumeric(nfly),isnumeric(minspd)];
req_state2 = [isnumeric(ntrj),isnumeric(nfly),isnumeric(maxspd)];

if (sum(req_state1)>2)||(sum(req_state2)>2)
    error('do not request track number and speed reduction at the same time. make only one request')
elseif isnumeric(ntrj)
    % find the index for that trj
    tsi = find(expmat(:,1)==ntrj,1,'last');
    expmat = expmat(1:tsi,:);
elseif isnumeric(nfly)
    % start counting
    cfl = 0;
    for i = unique(expmat(:,colindnum))'
        if cfl<=nfly
            % get fly count
            cfl = cfl + expmat(find(expmat(:,colindnum)==i,1),nflyColNum);
            cind = find(expmat(:,colindnum)==i,1,'last');
        end
    end
    expmat = expmat(1:cind,:);
end
% apply speed reduction
if isnumeric(minspd)
    % find tracks les then this speed and eliminate
    indmask = zeros(size(expmat,1),1);
    for i = 1:expmat(end,1)
        if mean(expmat(expmat(:,1)==i,speedColNum))<=minspd
            indmask(expmat(:,1)==i) = 1;
        end
    end
    indmask = indmask.*(1:length(indmask))';
    indmask(indmask==0) = [];
    if ~isempty(indmask)
        expmat(indmask,:) = [];
    end
    % resort the track index
    if isnumeric(maxspd)
        % find tracks with speed more than maxspd and eliminate
        indmask = zeros(size(expmat,1),1);
        for i = 1:expmat(end,1)
            if mean(expmat(expmat(:,1)==i,speedColNum))>=maxspd
                indmask(expmat(:,1)==i) = 1;
            end
        end
        indmask = indmask.*(1:length(indmask))';
        indmask(indmask==0) = [];
        if ~isempty(indmask)
            expmat(indmask,:) = [];
        end
    end
elseif isnumeric(maxspd)
    % find tracks with speed more than maxspd and eliminate
    indmask = zeros(size(expmat,1),1);
    for i = 1:expmat(end,1)
        if mean(expmat(expmat(:,1)==i,speedColNum))>=maxspd
            indmask(expmat(:,1)==i) = 1;
        end
    end
    indmask = indmask.*(1:length(indmask))';
    indmask(indmask==0) = [];
    if ~isempty(indmask)
        expmat(indmask,:) = [];
    end
end
%apply track length reduction
trklist = unique(expmat(:,1));
trjlens = diff([0;find(diff(expmat(:,1)));length(expmat(:,1))]);
if isnumeric(mintrjlen)
    % eliminate tracks shorter then this
    indmask = zeros(size(expmat,1),1);
    for i = 1:length(trklist)
        thistrack = trklist(i);
        thisfps = unique(expmat(expmat(:,1)==thistrack,fpsColNum));
        if length(thisfps)>1
            keyboard
            error('should be only one fps')
            
        end
        if trjlens(i)<round(mintrjlen*thisfps)
            indmask(expmat(:,1)==thistrack) = 1;
        end
    end
    indmask = indmask.*(1:length(indmask))';
    indmask(indmask==0) = [];
    if ~isempty(indmask)
        expmat(indmask,:) = [];
    end
end

% aply track path constraint

if isnumeric(minTraveledDistance)
    trklist = unique(expmat(:,1));
    totPath = getTotPathExpMat(expmat,colnumx,colnumy);
    % eliminate tracks shorter then this
    indmask = zeros(size(expmat,1),1);
    for i = 1:length(trklist)
        thistrack = trklist(i);
        thisTotPath = totPath(expmat(:,1)==thistrack);
        if max(thisTotPath)<minTraveledDistance
            indmask(expmat(:,1)==thistrack) = 1;
        end
    end
    indmask = indmask.*(1:length(indmask))';
    indmask(indmask==0) = [];
    if ~isempty(indmask)
        expmat(indmask,:) = [];
    end
end

if ~isempty(col)
    IEM.expmat = expmat;
    expmat = IEM;
end

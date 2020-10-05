function AngCountIndx = binEncounterAngleRandom(expmat,nbins,trackPerBin,t_int,angoffset,windparam)

switch nargin
    case 5
        windparam = [];
    case 4
        windparam = [];
        angoffset = 0; % degree
    case 3
        windparam = [];
        angoffset = 0; % degree
        t_int = '1';     % use only encounter point to deterrmine angle
    case 2
        windparam = [];
        angoffset = 0; % degree
        t_int = '1';     % use only encounter point to deterrmine angle
        trackPerBin = 100;
    case 1
        windparam = [];
        angoffset = 0; % degree
        t_int = '1';     % use only encounter point to deterrmine angle
        trackPerBin = 100;
        nbins = 18;      % degree
end


if isempty(windparam)
    windDirCol = 43;
    smoothWindDirN = nan; % do not smooth
    useWindDir = 0;     % do not use wind dir
    smoothFlyOrientN = nan;
else
    windDirCol = windparam.windDirCol;
    smoothWindDirN = windparam.smoothWindDirN;
    useWindDir = windparam.useWindDir;
    smoothFlyOrientN = windparam.smoothFlyOrientN;
end


flyOrCol = 11;
% if smoothing requested, smooth the angle vectors
if ~isnan(smoothFlyOrientN)
    expmat = smoothExpMatTheta(expmat,flyOrCol,smoothFlyOrientN);
end
if useWindDir
    if ~isnan(smoothWindDirN)
        expmat = smoothExpMatTheta(expmat,windDirCol,smoothWindDirN);
    end
end

% sort and select tracks
expmat = smoothExpMatTheta(expmat,flyOrCol,t_int,'time',20,'bwd');
% get track lengths
trklist = unique(expmat(:,1));
trjlens = diff([0;find(diff(expmat(:,1)));length(expmat(:,1))]);
% sort these tracks for length
stracks = sortrows([trklist,trjlens],2,'descend');
% are there enough tracks
reqntracks = nbins*trackPerBin;
if reqntracks>length(trklist)
    % less tracks available distribute equally
    trackPerBin = floor(length(trklist)/nbins);
else
    % get top reqntracks tracks
    stracks = stracks(1:reqntracks,:);
    % remove unselected tracks
    for i = 1:length(trklist)
        thistrk = trklist(i);
        if ~any(thistrk==stracks(:,1))
            expmat(expmat(:,1)==thistrk,:) = [];
        end
    end
end

% find random 10 points in each track
nRandEncPerTrack = 10;
enc_type = 34;  % onset column
expmat(:,enc_type) = 0;

trklist = unique(expmat(:,1));
for i = 1:length(trklist)
    thistrk = trklist(i);
    thistrkind = find(expmat(:,1)==thistrk);
    % get the 1/3 center part
    thistrkind = thistrkind(round(length(thistrkind)/3):end-round(length(thistrkind)/3));
    if length(thistrkind)>nRandEncPerTrack
        encinds = randsample(thistrkind,nRandEncPerTrack);
    else
        encinds = thistrkind;
    end
    encinds = sort(encinds);
    expmat(encinds,enc_type) = (1:nRandEncPerTrack)';
end

% bin all encounters
allencs = find(expmat(:,enc_type)>0);
allencangle = expmat(allencs,11);

if useWindDir
    allencwinddir = expmat(allencs,windDirCol);
    allencangle = angleSubtVec(allencangle,allencwinddir);
    allencangle = mod(allencangle,360);
end
   
% get binned angle and indexes
[R,T,indxl] = BinAngle(allencangle/180*pi,nbins,angoffset/180*pi); % inputs and outputs of BinAngle are radians
encnumlist = cell(size(R));
indx = cell(size(R));
encangle = cell(size(R));
% fix indexes
for indexnum = 1:length(R)
    trjnBin = expmat(allencs(indxl==indexnum),1);
    thisindl = find(indxl==indexnum);
    ftind = find([1;diff(trjnBin)]);
    thisindl = thisindl((ftind));
    indx(indexnum) = {allencs(thisindl)};
    encnumlist(indexnum) = {expmat(indx{indexnum},enc_type)};
    encangle(indexnum) = {allencangle(thisindl)};
    R(indexnum) = length(thisindl);
end

maxEncNum = nRandEncPerTrack;
% allocate space
cntn = zeros(nbins,maxEncNum);

% construct the output
AngCountIndx.angle = (T/pi*180)';
AngCountIndx.count = R';
AngCountIndx.encangle = encangle; 
AngCountIndx.indx = indx';
AngCountIndx.encnumlist = encnumlist';
AngCountIndx.countn = cntn;

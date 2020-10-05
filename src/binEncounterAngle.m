function AngCountIndx = binEncounterAngle(expmat,enc_type,nbins,t_int,angoffset,windparam)

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
        nbins = 18;      % degree
    case 1
        windparam = [];
        angoffset = 0; % degree
        t_int = '1';     % use only encounter point to deterrmine angle
        nbins = 18;      % degree
        enc_type = 1;    % 1: onset, 2: peak, 3: offset
end


if isempty(windparam)
    windDirCol = 43;
    smoothWindDirN = nan; % do not smooth
    smoothWindDSpeedN = 1;
    useWindDir = 0;     % do not use wind dir
    smoothFlyOrientN = nan;
else
    windDirCol = windparam.windDirCol;
    smoothWindDirN = windparam.smoothWindDirN;
    smoothWindDSpeedN = windparam.smoothWindSpeedN;
    useWindDir = windparam.useWindDir;
    smoothFlyOrientN = windparam.smoothFlyOrientN;
end

% get the column number for binning
switch enc_type
    case 3
        enc_type = 36;  % offset column
    case 2
        enc_type = 35;  % peak column
    case 1
        enc_type = 34;  % onset column
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

% what is the maximum encounter number
maxEncNum = length(unique(expmat(expmat(:,enc_type)>0,enc_type)));

% allocate space
cntn = zeros(nbins,maxEncNum);
indxn = cell(nbins,maxEncNum);
encanglen = cell(nbins,maxEncNum);

% bin all encounters
allencs = find(expmat(:,enc_type)>0);
if strcmp(t_int,'1')
    tintsave = '1';
    allencangle = expmat(allencs,11);
elseif isnumeric(t_int)
    tintsave = t_int;
    allencangle = zeros(size(allencs));
    for i = 1:length(allencs)
        t_int = round(tintsave*expmat(allencs(i),20)); % T_int * fps
        if t_int ==0
            t_int = 1;
        end
        if (find(expmat(:,1)==expmat(allencs(i),1),1))<=(allencs(i)-t_int)
            angtemp = expmat(allencs(i)-t_int:allencs(i),11);
            angtemp(isnan(angtemp)) = [];
            allencangle(i) = meanOrientation(angtemp);
        else
            angtemp = expmat((find(expmat(:,1)==expmat(allencs(i),1),1)):allencs(i),11);
            angtemp(isnan(angtemp)) = [];
            allencangle(i) = meanOrientation(angtemp);
        end
    end
end
allencangle = mod(allencangle,360);

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
    indx(indexnum) = {allencs(indxl==indexnum)};
    encnumlist(indexnum) = {expmat(indx{indexnum},enc_type)};
    encangle(indexnum) = {allencangle(indxl==indexnum)};
end

% now do it for all encounters separately

for encnum = 1:maxEncNum
    allencs = find(expmat(:,enc_type)==encnum);
    if strcmp(tintsave,'1')
        allencangle = expmat(allencs,11);
    elseif isnumeric(tintsave)
        allencangle = zeros(size(allencs));
        for i = 1:length(allencs)
            t_int = round(tintsave*expmat(allencs(i),20)); % T_int * fps
            if (find(expmat(:,1)==expmat(allencs(i),1),1))<=(allencs(i)-t_int)
                allencangle(i) = meanOrientation(expmat(allencs(i)-t_int:allencs(i),11));
            else
                allencangle(i) = meanOrientation(expmat((find(expmat(:,1)==expmat(allencs(i),1),1)):allencs(i),11));
            end
        end
    end
    
    
    allencangle = mod(allencangle,360);  
    
    % get binned angle and indexes
    [Ren,~,indxenl] = BinAngle(allencangle/180*pi,nbins,angoffset/180*pi); % inputs and outputs of BinAngle are radians
    indxen = cell(size(Ren));
    encangen = cell(size(Ren));
    % fix indexes
    for indexnum = 1:length(indxen)
        indxen(indexnum) = {allencs(indxenl==indexnum)};
        encangen(indexnum) = {allencangle(indxenl==indexnum)};
    end
    cntn(:,encnum) = Ren';
    indxn(:,encnum) = indxen';
    encanglen(:,encnum) = encangen';
end

% construct the output
AngCountIndx.angle = (T/pi*180)';
AngCountIndx.count = R';
AngCountIndx.encangle = encangle; 
AngCountIndx.indx = indx';
AngCountIndx.encnumlist = encnumlist';
AngCountIndx.countn = cntn;
AngCountIndx.indxn = indxn;
AngCountIndx.encanglen = encanglen; 

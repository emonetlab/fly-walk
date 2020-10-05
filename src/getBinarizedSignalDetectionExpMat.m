function S = getBinarizedSignalDetectionExpMat(S,sigThresnfac,whiffFreqWindSize,DetectionParameters,disp_SigThresh)
%getBinarizedSignalDetection
% S = getBinarizedSignalDetectionExpMat(S,sigThresnfac,whiffFreqWindSize,disp_SigThresh)
% applies mask to signal. Thresholds and binarizes it, the detecs onset,
% offset and peak (middle of onset and offset) points
%
assert(any(strcmp(fieldnames(S),'expmat')),['missing field ''expmat'' in ',inputname(1)])
assert(any(strcmp(fieldnames(S),'column')),['missing field ''column'' in ',inputname(1)])

switch nargin
    case 4
        disp_SigThresh = 0;
    case 3
        DetectionParameters = [];
        disp_SigThresh = 0;
    case 2
        DetectionParameters = [];
        disp_SigThresh = 0;
        whiffFreqWindSize = 1; % sec
    case 1
        DetectionParameters = [];
        disp_SigThresh = 0;
        whiffFreqWindSize = 1; % sec
        sigThresnfac = 2.5;
end

% get these fields in the col
if isfield(S,'column')
    colFieldNames = S.column;
else
    colFieldNames = {'fileindex','signal','coligzone','periphery','signal_mask','signal_threshold','fps','onset_num','peak_num','offset_num'};
end
if ~isfield(S,'col')
    for i = 1:numel(colFieldNames)
        S.col.(colFieldNames{i}) = find(strcmp(S.column,colFieldNames{i}));
    end
else
    if ~(numel(fieldnames(S.col))>=numel(colFieldNames))
        for i = 1:numel(colFieldNames)
            if ~isfield(S.col,colFieldNames{i})
                S.col.(colFieldNames{i}) = find(strcmp(S.column,colFieldNames{i}));
            end
        end
    end
end

% put all fileds in the col in to the columnlist
scolFields = fieldnames(S.col)';
allColumnFields = S.column;
for i = 1:numel(scolFields)
    if ~any(strcmp(scolFields(i),allColumnFields))
        S.column(S.col.(scolFields{i})) = scolFields(i);
    end
end

assert(numel(unique(scolFields)) == numel(scolFields),'col has double copies')

% find the row good for these field
findColNResetFields = {'whiffLen','blankLen','whiffFreq','whiffFreqWind','signal_threshold',...
    'mu','sigma','nfac'};
for i = 1:numel(findColNResetFields)
    S = findFieldColumnNReset(S,findColNResetFields{i});
end


% reset all values whiff detection values
S.expmat(:,S.col.onset_num) = 0;
S.expmat(:,S.col.peak_num) = 0;
S.expmat(:,S.col.offset_num) = 0;

[signalThreshold,mu,sigma,nfac] = getSigThreshExpMat(S,sigThresnfac,disp_SigThresh);

%% set the parameters
% set defaults
plmContPar.smooth_length = 1;  % (points), How much to smooth the signal before analyzing the peaks. (Previous value: 3)
plmContPar.minPeakDist = .02;  % ms The minimum time that two neighboring detected peaks must have between them.
plmContPar.minPeakWidth = .02; % (sec),  minimum encounter duration .02 seconds
plmContPar.minPeakProm = .7;   % The minimum intensity that the peak prominence must have.
plmContPar.maxPeakWidth = 60;   % (sec), The maximum length that a signal increase can have in seconds.
plmContPar.maxPeakHeight = 150;  % maximum value a peak can have
plmContPar.minPeakTrackLength = 1; % 1 second, if tracks length is shorter ignore it

defFields = fieldnames(plmContPar);

if ~isempty(DetectionParameters)
    givenFields = fieldnames(DetectionParameters);

    for i = 1:numel(defFields)
        if any(strcmp(defFields(i),givenFields))
            plmContPar.(defFields{i}) = DetectionParameters.(defFields{i});
        end
    end
end
% get masked signal
SignalMask = S.expmat(:,S.col.signal_mask);
signalMasked = S.expmat(:,S.col.signal).*SignalMask;
%% iterate over all videos
theseVideos = unique(S.expmat(:,S.col.fileindex));

for vidNum = 1:length(theseVideos)
    thisVideo = theseVideos(vidNum);
    thisSigThresh  = signalThreshold(vidNum);
    fps = nonzeros(unique(S.expmat(S.expmat(:,S.col.fileindex)==thisVideo,S.col.fps)));
    if length(fps)>1
        error(['more than 1 fps in this video: ',num2str(thisVideo)])
    end
    
    % record the signal threshold
    S.expmat(S.expmat(:,S.col.fileindex)==thisVideo,S.col.signal_threshold) = thisSigThresh;
    S.expmat(S.expmat(:,S.col.fileindex)==thisVideo,S.col.mu) = mu(vidNum);
    S.expmat(S.expmat(:,S.col.fileindex)==thisVideo,S.col.sigma) = sigma(vidNum);
    S.expmat(S.expmat(:,S.col.fileindex)==thisVideo,S.col.nfac) = nfac;
    
    if isnan(thisSigThresh) % do not bother
        continue
    end
    
    % Iterate through all tracks:
    theseTracks = unique(S.expmat(S.expmat(:,S.col.fileindex)==thisVideo,1));
    
    for trj = 1:length(theseTracks)
        thisTrack = theseTracks(trj);
        track_start = find(S.expmat(:,1)==thisTrack,1,'first');
        track_end = find(S.expmat(:,1)==thisTrack,1,'last');
        if length(track_start:track_end)<(plmContPar.minPeakTrackLength*fps)
            continue
        end
        
        signalMasked(track_start:track_end) = fillgaps(signalMasked(track_start:track_end));
        % binarize signal
        thisSignal = smooth(signalMasked(track_start:track_end),plmContPar.smooth_length);
        signalt = thisSignal>thisSigThresh;
        [p,n] = getOnOffPoints(diff(signalt));
        if isempty(p)||isempty(n)
            continue;
        end
        % eliminate short and very longdetections
        len = n-p;
        delete_these = logical((len<(plmContPar.minPeakWidth*fps)).*(len>(plmContPar.maxPeakWidth*fps)));
        p(delete_these) = [];
        n(delete_these) = [];
        
        
        if isempty(p)||isempty(n)
            continue;
        end
        % delete if the detection overlaps with mask
        thisMask = SignalMask(track_start:track_end)';
        
        if isrow(p)
            deleteThese = logical(double(sum((p-1)==find(thisMask)',1)==0) + double(sum((n+1)==find(thisMask)',1)==0));
        else
            deleteThese = logical(double(sum((p-1)==find(thisMask),2)==0) + double(sum((n+1)==find(thisMask),2)==0));
        end
        p(deleteThese) = [];
        n(deleteThese) = [];
        
        
        if isempty(p)||isempty(n)
            continue;
        end
        
        % eliminate the peaks to high or too short
        deleteThese = false(size(n));
        for i = 1:length(p)
            if max(thisSignal(p(i):n(i)))<(plmContPar.minPeakProm+thisSigThresh)
                deleteThese(i) = true;
            end
            if max(thisSignal(p(i):n(i)))>(plmContPar.maxPeakHeight)
                deleteThese(i) = true;
            end
        end
        p(deleteThese) = [];
        n(deleteThese) = [];
        
        % remove zero blanks
        if length(n)>1
            theseShortBlanks = find((p(2:end)-n(1:end-1))<((plmContPar.minPeakDist)*fps));
            p(theseShortBlanks+1) = [];
            n(theseShortBlanks) = [];
        end
        
        
        if isempty(p)||isempty(n)
            continue;
        end
        
        % increment n by one
        n = n+1;
        
        whiffFreq = getWhiffFreqOfTheseOnsets(p/fps,whiffFreqWindSize);
        
        for i = 1:length(p)
            S.expmat(track_start+p(i)-1,S.col.onset_num) = i;
            S.expmat(track_start+round((p(i)+n(i))/2)-1,S.col.peak_num) = i;
            S.expmat(track_start+n(i)-1,S.col.offset_num) = i;
            S.expmat(track_start+p(i)-1,S.col.whiffLen) = (n(i)-p(i))/fps;
            S.expmat(track_start+p(i)-1,S.col.whiffFreqWind) = whiffFreq(i);
            if i<length(p)
                S.expmat(track_start+n(i)-1,S.col.blankLen) = (p(i+1)-n(i))/fps;
                S.expmat(track_start+p(i)-1,S.col.whiffFreq) = 1/(p(i+1)-p(i))*fps;
            else
                %                 S.expmat(track_start+n(i)-1,S.col.blankLen) = (p(i)-n(i))/fps;
                %                 if length(p)==1
                %                     S.expmat(track_start+n(i)-1,S.col.whiffFreq) = 1/length(track_start:track_end)*fps;
                %                 else
                %                     S.expmat(track_start+n(i)-1,S.col.whiffFreq) = 1/(p(i)-p(i-1))*fps;
                %                 end
            end
        end
        % calculate the whiff frequency over a window size
        
    end
end


allWhiffLen = S.expmat(S.expmat(:,S.col.onset_num)>0,S.col.whiffLen);
allBlankLen = S.expmat(S.expmat(:,S.col.offset_num)>0,S.col.blankLen);
allWhiffFreq = S.expmat(S.expmat(:,S.col.onset_num)>0,S.col.whiffFreq);
allWhiffFreqWind = S.expmat(S.expmat(:,S.col.onset_num)>0,S.col.whiffFreqWind);
theseTracks = unique(S.expmat(:,1));
WhiffLenList = cell(length(theseTracks),1);
BlankLenList = cell(length(theseTracks),1);
WhiffFreqList = cell(length(theseTracks),1);
WhiffFreqWindList = cell(length(theseTracks),1);
WhiffLenPerTrack = zeros(length(theseTracks),1);
BlankLenPerTrack = zeros(length(theseTracks),1);
WhiffFreqPerTrack = zeros(length(theseTracks),1);
WhiffFreqWindPerTrack = zeros(length(theseTracks),1);
for i = 1:length(theseTracks)
    WhiffLenList(i) = {S.expmat(logical((S.expmat(:,S.col.onset_num)>0).*(S.expmat(:,1)==theseTracks(i))),S.col.whiffLen)};
    BlankLenList(i) = {S.expmat(logical((S.expmat(:,S.col.offset_num)>0).*(S.expmat(:,1)==theseTracks(i))),S.col.blankLen)};
    WhiffFreqList(i) = {S.expmat(logical((S.expmat(:,S.col.onset_num)>0).*(S.expmat(:,1)==theseTracks(i))),S.col.whiffFreq)};
    WhiffFreqWindList(i) = {S.expmat(logical((S.expmat(:,S.col.onset_num)>0).*(S.expmat(:,1)==theseTracks(i))),S.col.whiffFreqWind)};
    WhiffLenPerTrack(i) = nanmean(nonzeros(S.expmat(logical((S.expmat(:,S.col.onset_num)>0).*(S.expmat(:,1)==theseTracks(i))),S.col.whiffLen)));
    BlankLenPerTrack(i) = nanmean(nonzeros(S.expmat(logical((S.expmat(:,S.col.offset_num)>0).*(S.expmat(:,1)==theseTracks(i))),S.col.blankLen)));
    WhiffFreqPerTrack(i) = nanmean(nonzeros(S.expmat(logical((S.expmat(:,S.col.onset_num)>0).*(S.expmat(:,1)==theseTracks(i))),S.col.whiffFreq)));
    WhiffFreqWindPerTrack(i) = nanmean(nonzeros(S.expmat(logical((S.expmat(:,S.col.onset_num)>0).*(S.expmat(:,1)==theseTracks(i))),S.col.whiffFreqWind)));
end
S.allWhiffLen = allWhiffLen;
S.allBlankLen = allBlankLen;
S.allWhiffFreq = allWhiffFreq;
S.allWhiffFreqWind = allWhiffFreqWind;
S.theseTracks = theseTracks;
S.WhiffLenList = WhiffLenList;
S.BlankLenList = BlankLenList;
S.WhiffFreqList = WhiffFreqList;
S.WhiffFreqWindList = WhiffFreqWindList;
S.WhiffLenPerTrack = WhiffLenPerTrack;
S.BlankLenPerTrack = BlankLenPerTrack;
S.WhiffFreqPerTrack = WhiffFreqPerTrack;
S.WhiffFreqWindPerTrack = WhiffFreqWindPerTrack;

% end of function
end

function S = findFieldColumnNReset(S,fieldName)
% find the row good for whiff length
if isempty(find(strcmp(S.column,fieldName), 1))
    totColNum = size(S.expmat,2);
    S.col.(fieldName) = totColNum+1;
    S.column(totColNum+1) = {fieldName};
else
    S.col.(fieldName) = find(strcmp(S.column,fieldName));
end
S.expmat(:,S.col.(fieldName)) = 0;
end



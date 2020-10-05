function f = getBinarizedSignalDetection(f,threshSig,maskdilate)
%getBinarizedSignalDetection
% 
% applies mask to signal. Thresholds and binarizes it, the detecs onset,
% offset and peak (middle of onset and offset) points

switch nargin
    case 2
        maskdilate = 3;
    case 1
        maskdilate = 3;
        threshSig =[];
       
end
if ~isfield(f.tracking_info,'coligzone')
    f = getCIZoneStatus(f);
end
if ~isfield(f.tracking_info,'periphery')
    f = getPeripheryStatus(f);
end
f = getMaskedSignal(f,maskdilate);
% f = fixFlyOrientFlips(f);
% f = ApplyGroomMask2Signal(f);
if  isempty(threshSig)
    [threshSig,mu,sigma,nfac]  = getSigThresh(f);
    f.tracking_info.SignalBinPar.mu = mu;
    f.tracking_info.SignalBinPar.sigma = sigma;
    f.tracking_info.SignalBinPar.signal_threshold = threshSig;
    f.tracking_info.SignalBinPar.nfac = nfac;
else
    f.tracking_info.SignalBinPar.mu = nan;
    f.tracking_info.SignalBinPar.sigma = nan;
    f.tracking_info.SignalBinPar.signal_threshold = threshSig;
    f.tracking_info.SignalBinPar.nfac = nan;
end

%% remove fields
if isfield(f.tracking_info,'signal_sorted')
    f.tracking_info = rmfield(f.tracking_info,'signal_sorted');
end
if isfield(f.tracking_info,'signal_peak')
    f.tracking_info = rmfield(f.tracking_info,'signal_peak');
end
if isfield(f.tracking_info,'signal_width')
    f.tracking_info = rmfield(f.tracking_info,'signal_width');
end
if isfield(f.tracking_info,'signal_prom')
    f.tracking_info = rmfield(f.tracking_info,'signal_prom');
end
if isfield(f.tracking_info,'signal_onset')
    f.tracking_info = rmfield(f.tracking_info,'signal_onset');
end
if isfield(f.tracking_info,'signal_offset')
    f.tracking_info = rmfield(f.tracking_info,'signal_offset');
end
%% set the parameters
% set defaults
    defFields = {   'smooth_length',    1;   ...  % (points), How much to smooth the signal before analyzing the peaks. (Previous value: 3)
                    'minPeakDist',      0;   ...    % The minimum time that two neighboring detected peaks must have between them. %%%% did not code yet
                    'minPeakWidth',     .02; ...   % (sec),  minimum encounter duration .02 seconds
                    'minPeakProm',      .5;  ...    % The minimum intensity that the peak prominence must have.
                    'maxPeakWidth',     60;  ...   % (sec), The maximum length that a signal increase can have in seconds.
                    'maxPeakHeight',    100; ...  % maximum value a peak can have
                    'minPeakTrackLength', 1 }; % 1 second, if tracks length is shorter ignore it
    
% check if the paramters are already set
if isempty(f.plm_cont_par) % no parameter is set
    givenFields = [];

else % there are some parameters supplied
    % replace them with the defaults
    givenFields = fieldnames(f.plm_cont_par);  
end
    for i = 1:numel(defFields(:,1))
        if ~any(strcmp(defFields(i,1),givenFields))
            f.plm_cont_par.(defFields{i,1}) = defFields{i,2};
        end
    end
    
    % put the min signal length to tracking info as well. in future
    % versions eliminate this
    f.tracking_info.minSignalLen = f.plm_cont_par.minPeakWidth;

extraFields = setdiff(givenFields,defFields(:,1));
if ~isempty(extraFields)
    disp(['WARNING: these fields are provided extra in f.plm_cont_par and', ...
        ' will not be used during encounter detection: ', strjoin(extraFields',', ')])
end


%% Iterate through all tracks:
noftracks = find(f.tracking_info.fly_status(:,end)>0,1,'last');
for trj = 1:noftracks    
    track_start = find(f.tracking_info.fly_status(trj,:)==1,1,'first');
    track_end = find(f.tracking_info.fly_status(trj,:)==1,1,'last');
    if length(track_start:track_end)<(f.plm_cont_par.minPeakTrackLength*f.ExpParam.fps)
        continue
    end

    f.tracking_info.signalm(trj,track_start:track_end) = fillgaps(f.tracking_info.signalm(trj,track_start:track_end));
    % binarize signal
    signalt = smooth(f.tracking_info.signalm(trj,:),f.plm_cont_par.smooth_length)>threshSig;
    [p,n] = getOnOffPoints(diff(signalt));
    if isempty(p)||isempty(n)
        continue;
    end
    % eliminate short detections
    len = n-p;
    delete_these = logical((len<(f.plm_cont_par.minPeakWidth*f.ExpParam.fps)).*(len>(f.plm_cont_par.maxPeakWidth*f.ExpParam.fps)));
    p(delete_these) = [];
    n(delete_these) = [];
    
    
    if isempty(p)||isempty(n)
        continue;
    end
    % delete if the detection aoverlaps with mask
    thisMask = f.tracking_info.mask_of_signal(trj,:); 

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
        if max(f.tracking_info.signal(trj,p(i):n(i)))<(f.plm_cont_par.minPeakProm+f.tracking_info.SignalBinPar.signal_threshold)
            deleteThese(i) = true;
        end
        if max(f.tracking_info.signal(trj,p(i):n(i)))>(f.plm_cont_par.maxPeakHeight)
            deleteThese(i) = true;
        end
    end
    p(deleteThese) = [];
    n(deleteThese) = [];
    
    
    if isempty(p)||isempty(n)
        continue;
    end
  
   % increment n by one
    n = n+1;
    % write the output to f
    f.tracking_info.signal_peak(trj,1:length(p)) = round((p+n)/2);
    f.tracking_info.signal_width(trj,1:length(p)) = (n-p);
    f.tracking_info.signal_prom(trj,1:length(p)) = NaN;
    f.tracking_info.signal_onset(trj,1:length(p)) = p;
    f.tracking_info.signal_offset(trj,1:length(p)) = n;
end

if ~isfield(f.tracking_info,'signal_peak')
    % there are no peaks in this data
    % assign empty vectors
    f.tracking_info.signal_peak(trj,1) = 0;
    f.tracking_info.signal_width(trj,1) = 0;
    f.tracking_info.signal_prom(trj,1) = NaN;
    f.tracking_info.signal_onset(trj,1) = 0;
    f.tracking_info.signal_offset(trj,1) = 0;
end
    


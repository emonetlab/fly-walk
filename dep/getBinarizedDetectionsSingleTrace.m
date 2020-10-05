function [p,n] = getBinarizedDetectionsSingleTrace(signalTrace,Parameters)
%getBinarizedDetectionsSingleTrace
% function [p,n] = getBinarizedDetectionsSingleTrace(signalTrace,Parameters)
% calculates the onset (p) and offset (n) of the whiff in given
% signalTrace. Default parameters are:
%     'smooth_length',          1;   ...    % (points), How much to smooth the signal before analyzing the peaks. (Previous value: 3)
%     'minPeakWidth',           .02; ...    % (sec),  minimum encounter duration, seconds
%     'minBlankWidth',          .03; ...    % (sec),  minimum blank duration, seconds
%     'minPeakProm',            .5;  ...    % The minimum intensity that the peak prominence must have.
%     'maxPeakWidth',           60;  ...    % (sec), The maximum length that a signal increase can have in seconds.
%     'maxPeakHeight',          100; ...    % maximum value a peak can have
%     'sigThresh',              nan; ...    % calculate the threshold using this trace
%     'fps',                    nan};       % fps has to be provided
%

% set the parameters
% set defaults
defFields = {   'smooth_length',    1;   ...    % (points), How much to smooth the signal before analyzing the peaks. (Previous value: 3)
                'minPeakWidth',     .02; ...    % (sec),  minimum encounter duration, seconds
                'minBlankWidth',    .03; ...    % (sec),  minimum blank duration, seconds
                'minPeakProm',      .5;  ...    % The minimum intensity that the peak prominence must have.
                'maxPeakWidth',     60;  ...    % (sec), The maximum length that a signal increase can have in seconds.
                'maxPeakHeight',    100; ...    % maximum value a peak can have
                'sigThresh', nan; ...           % calculate the threshold using this trace
                'fps', nan};                    % fps has to be provided
            
if nargin==1
    error('fps has to be provided: Parameters.fps = ????')
end

% check if the paramters are already set
if isempty(fieldnames(Parameters)) % no parameter is set
    givenFields = [];
    
else % there are some parameters supplied
    % replace them with the defaults
    givenFields = fieldnames(Parameters);
end
% replace defaults values eith the given ones
for i = 1:numel(defFields(:,1))
    if ~any(strcmp(defFields(i,1),givenFields))
        Parameters.(defFields{i,1}) = defFields{i,2};
    end
end

% put the min signal length to tracking info as well. in future
% versions eliminate this

extraFields = setdiff(givenFields,defFields(:,1));
if ~isempty(extraFields)
    disp(['WARNING: these fields are provided extra in Parameters and', ...
        ' will not be used during encounter detection: ', strjoin(extraFields',', ')])
end


% determine signal threshiold
if isnan(Parameters.sigThresh)
    Parameters.sigThresh = getShotNoiseThresh(signalTrace(:));
end

% determine signal threshiold
if isnan(Parameters.fps)
    error('fps has to be provided: Parameters.fps = ????')
end

% displaye used parameters
disp('Parameters used:   ')
disp(Parameters)

[p,n] = getOnOffPoints(diff(signalTrace>Parameters.sigThresh));
if isempty(p)||isempty(n)
    return
end
% eliminate short detections
len = n-p;
delete_these = logical((len<(Parameters.minPeakWidth*Parameters.fps))+...
    (len>(Parameters.maxPeakWidth*Parameters.fps)));
p(delete_these) = [];
n(delete_these) = [];

if isempty(p)||isempty(n)
    return
end

% eliminate short detections, blanks
len = p(2:end)-n(1:end-1);
delete_these = logical((len<(Parameters.minBlankWidth*Parameters.fps)));
p(find(delete_these)+1) = [];
n(delete_these) = [];

if isempty(p)||isempty(n)
    return
end

% remove extra points
if (~isempty(n))&&(~isempty(p))
    if (n(end)<p(end))
        p(end) = [];
    end
    if (p(1)>n(1))
        n(1) = [];
    end
    if length(p)==(length(n)-1)
        p(2:end+1) = p;
        p(1) = 1;
        % get the correct vector orientation
        if iscolumn(n)
            if isrow(p)
                p = p';
            end
        else
            if iscolumn(p)
                p = p';
            end
        end
        
    end
    
    
    if (n(1)<p(1))
        if length(n)==length(p)
            p(2:end+1) = p;
            p(1) = 1;
            if (n(end)<p(end))
                n(end+1) = length(signalTrace);
            end
        else
            n(1) = [];
        end
    end
    
    
end

if isempty(n)&&(length(p)==1)
    n = length(signalTrace);
end

if isempty(p)&&(length(n)==1)
    p = 1;
end

% eliminate short detections
len = n-p;
delete_these = logical((len<(Parameters.minPeakWidth*Parameters.fps))+(len>(Parameters.maxPeakWidth*Parameters.fps)));
p(delete_these) = [];
n(delete_these) = [];

if isempty(p)||isempty(n)
    return
end


% increment n by one
n = n+1;
n(n>length(signalTrace)) =  n(n>length(signalTrace))-1;

function S = assigFlyWalkingSurfacesExpData(S,parameters)
%
%assignFlyWalkingurfacesExpData
%   function S = assignFlyWalkingSurfacesExpData(S,parameters)
%   estimates the reflection status of each track in the S using the
%   reflection measurement and reflection overlap in the expmat with
%   threshold values defined in the parameters. Default threshold values
%   are:
%   param.refThresh = 25;           default threshold for reflection measurement
%   param.refIntPropThresh = .4;    default proportion above threshold value to assign surface
%   param.rolapThresh = .1;         default threshold for reflection overlap. Any 
%                                   reflection value with reflection overlap larger than
%                                   this will be regarded as unrelibale
%   S must include expmat and col with fields: trjNum, reflection,
%   reflection_meas, refOverLap1, and jump.
%   Estimates reflection status is saved to reflection column in expmat
%   mahmut demir, 9.29.20019
%

assert(isfield(S,'expmat'), [inputname(1),' does not have field "expmat"'])
assert(isfield(S,'col'), [inputname(1),' does not have field "col"'])
checkTheseFields = {'trjNum', 'reflection', 'reflection_meas', 'refOverLap1', 'jump'};
for i = 1:numel(checkTheseFields)
    assert(isfield(S.col,checkTheseFields{i}), [inputname(1),' does not have field "',checkTheseFields{i},'"'])
end
if nargin==1
    parameters = [];
end

% set default parameters
param.refThresh = 20; % default threshold for reflection measurement
param.refIntPropThresh = .4; % default proportion above threshold value to assign surface
param.rolapThresh = .1; % default threshold for reflection overlap. Any 
                        % reflection value with reflection overlap larger than
                        % this will be regarded as unrelibale

% replace with user input if given any
if ~isempty(parameters)
    userVar = fieldnames(parameters);
    paramVars = fieldnames(param);
    for i = 1:numel(userVar)
        if any(strcmp(userVar{i},paramVars'))
            param.(userVar{i}) = paramInput.(userVar{i});
        end
    end
end
% delete input
clear parameters
% set all reflection status to zero
S.expmat(:,S.col.reflection) = 0;

% find all track numbers in the given ExpData
AllTracks = unique(S.expmat(:,S.col.trjNum));
for i = 1:length(AllTracks)
    emti = S.expmat(S.expmat(:,S.col.trjNum)==AllTracks(i),:); % get expmat proportion for this track
    thisReflectionMeasurement = emti(:,S.col.reflection_meas); % get this reflection measurement
    thisReflectionOverlap = emti(:,S.col.refOverLap1); % get this reflection overlap with other stuf
    thisJumpStatus = emti(:,S.col.jump);
    % find track start and end indexes
    trackStartInd = find(S.expmat(:,S.col.trjNum)==AllTracks(i),1);
    trackEndInd = find(S.expmat(:,S.col.trjNum)==AllTracks(i),1,'last');
    if any(thisJumpStatus)
        [jsi,jse]=getOnOffPoints(diff(thisJumpStatus));
        % merge them
        [jsi,jse] = MergeOnOffPoints(jsi,jse);        
        % get segment starts and ends excluding the interactions
        [segStartFrame,segEndFrame] = getSegmentEdges(jsi,jse,1:size(emti,1));
    end
    % set un-reliable portiaon to nan for calculation
    thisReflectionMeasurement(thisReflectionOverlap>param.rolapThresh) = nan;
    % go over the segments (if any) and calculate the reflection proportion
    % wrt to the length of the track
    if any(thisJumpStatus)
        for j=1:length(segStartFrame)
            if((sum(nonnans(thisReflectionMeasurement(segStartFrame(j):segEndFrame(j)))...
                >param.refThresh)/length(nonnans(thisReflectionMeasurement(segStartFrame(j):segEndFrame(j)))))...
                >=param.refIntPropThresh) % if correct there is reflection
                S.expmat((segStartFrame(j):segEndFrame(j))+trackStartInd-1,S.col.reflection) = 1;
            end
        end
    else
        if(sum(nonnans(thisReflectionMeasurement)>param.refThresh)/length(nonnans(thisReflectionMeasurement))>=param.refIntPropThresh)
            S.expmat(trackStartInd:trackEndInd,S.col.reflection) = 1;
        end
    end
    
end

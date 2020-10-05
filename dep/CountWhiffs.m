%CountWhiffs
% function S = CountWhiffs(S) counts the number of whiffs in the given
% structure S. S must have the following fields: "expmat", "column". 
% Uses the 'onset_num' and 'offset_num' columns to calculate the number of
% whiffs, whiff durations and total whiff durations.
% Appends the results to the S with the fieldnames: "nWhiffs",
% "whiffDurTot" and "whiffDur"
%
function S = CountWhiffs(S)

em = S.expmat;
if isfield(S,'trackNum')
    theseTracks = S.trackNum;
else
    theseTracks = unique(em(:,1));
end    

        

nWhiffs = zeros(size(theseTracks));
whiffDur = cell(size(theseTracks));
whiffDurTot = zeros(size(theseTracks));
S.col.whiffOnset = find(strcmp(S.column,'onset_num'));
S.col.whiffOffset = find(strcmp(S.column,'offset_num'));

for i = 1:length(theseTracks)
    thisTrack = theseTracks(i);
    emt = em(em(:,1)==thisTrack,:);
    theseWhiffOn = nonzeros(unique(emt(:,S.col.whiffOnset)));
    theseWhiffOff = nonzeros(unique(emt(:,S.col.whiffOffset)));
    if ~isempty(theseWhiffOn) && ~isempty(theseWhiffOff)
        % delete offsets less than initial onset
        theseWhiffOff(theseWhiffOff<theseWhiffOn(1)) = [];
        
        if isempty(theseWhiffOff)
            theseWhiffOn = [];
            theseWhiffOff = [];
        else
            % delete onsets more than final offset
            theseWhiffOn(theseWhiffOn>theseWhiffOff(end)) = [];
        end
        
        % make sure that everything is sound
        if ~isempty(theseWhiffOn) && ~isempty(theseWhiffOff)
            % remove missing innner whiffs
            theseWhiffOn(logical(sum(theseWhiffOn==setdiff(theseWhiffOn,theseWhiffOff)',2))) = [];
            theseWhiffOff(logical(sum(theseWhiffOff==setdiff(theseWhiffOff,theseWhiffOn)',2))) = [];
            assert(length(theseWhiffOn)==length(theseWhiffOff),'number of whiff onset does not match number of offsets')
        end
    elseif isempty(theseWhiffOn) || isempty(theseWhiffOff)
        theseWhiffOn = [];
        theseWhiffOff = [];
    end
    
    if isempty(theseWhiffOn) && isempty(theseWhiffOff)
        continue
    end
        
    nWhiffs(i) = length(theseWhiffOn);
    whiffduri = zeros(size(theseWhiffOn));
    for j = 1:length(theseWhiffOn)
        thisWhiffOn  = theseWhiffOn(j);
        thisWhiffOff  = theseWhiffOff(j);
        whiffduri(j) = length(find(emt(:,S.col.whiffOnset)==thisWhiffOn): find(emt(:,S.col.whiffOffset)==thisWhiffOff))/emt(1,S.col.fps);
    end
    whiffDur(i) = {whiffduri};
    whiffDurTot(i) = sum(whiffduri);
    
end

S.nWhiffs = nWhiffs;
S.whiffDurTot = whiffDurTot;
S.whiffDur = whiffDur;

end


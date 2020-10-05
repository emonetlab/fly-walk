function [fs,fe] = getSegmentEdges(OnPoints,OffPoints,activeFrames)
% returns the segment boundary frame numbers for the given interaction
% points defined as OnOffPoints = [pi,ni]. The valid frames are given as
% activeFrames. Interaction frames are excluded.
%
if isempty(OnPoints)
    fs = activeFrames(1);
    fe = activeFrames(end);
else
    pi = OnPoints;
    ni = OffPoints;
    
    % initiate the output variables
    fs = zeros(length(pi)+1,1);
    fe = zeros(length(pi)+1,1);
    
    % go over the interactions
    if length(pi)>1
        for intnum = 1:(length(pi)-1)
            fs(intnum+1) = ni(intnum)+1;
            fe(intnum+1) = pi(intnum+1)-1;
        end
    elseif length(pi)==1
        fs(2) = ni(1)+1;
        fe(2) = activeFrames(end);
        fs(1) = activeFrames(1);
        fe(1) = pi(1)-1;
%         if pi==1 % interaction starts at the first frame
%             % remove the first segment
%             fs(1) = [];
%             fe(1) = [];
%         end
    else
        disp('either on or off points is empty')
    end
    
    
    % figure out the beginning
    if fs(2) == activeFrames(1)
        fs(1) = [];
        fe(1) = [];
    elseif fs(2) > activeFrames(1)
        fs(1) = activeFrames(1);
        fe(1) = pi(1)-1;
    elseif fs(2) < activeFrames(1)
        error('Interaction seems to happen before the track starts')
%         keyboard
    end
    
    % if the interaction starts at the beginning remove the first segment
    if pi(1)==1
        fs(1) = [];
        fe(1) = [];
    end
    
    if length(fs)>1
        % figure out the end
        if fs(end-1) == activeFrames(end)
            fs(end) = [];
            fe(end) = [];
        elseif ni(end)>= activeFrames(end)
            fs(end) = [];
            fe(end) = [];
        elseif fs(end-1) < activeFrames(end)
            fs(end) = ni(end) + 1;
            fe(end) = activeFrames(end);
        elseif fs(end-1) > activeFrames(end)
            error('Interaction seems to happen after the track ends')
%             keyboard
        end
    end
end
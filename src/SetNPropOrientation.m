function orientation = SetNPropOrientation(orientation,setPoint,angle_flip_threshold,StartEndIndex)
% sets the given orientation by moving up and down starting from setPoint
% between StartEndIndex, by flipping the orientations if there is > dgerees
% in between the consecutive orientations. Does not consider NaN values.
% StartEndIndex = [StartIndex,EndIndex]



switch nargin
    case 4
        setall = 0;
    case 3
        setall = 1;
    case 2
        angle_flip_threshold = 120; % degree, angle difference larger than this indicates direction flip
        setall = 1;
end
        
if setall % go through the hole series
    % get all points that have numeric values
    ValidPoints = find(~isnan(orientation));
    
    % if there is not any valid points, return
    if isempty(ValidPoints)
        return
    end
    
    % verify that setPoints is among these
    if ~ismember(setPoint,ValidPoints)
        error('SetPoint is not valid')
    end
    
    % get up and down series
    downInd = ValidPoints(1:find(ValidPoints==setPoint));
    upInd = ValidPoints(find(ValidPoints==setPoint):end);
    % remove the set point
%     downInd(end) = [];
%     upInd(1) = [];
    
    % move up the points
    for i = 2:length(upInd)
        thisOrient = orientation(upInd(i));
        reference = orientation(upInd(i-1));
        orientation(upInd(i)) = AllignOrient2Ref(thisOrient,reference,angle_flip_threshold);
    end
    
    % move down the points
    for i = length(downInd):-1:2
        thisOrient = orientation(downInd(i-1));
        reference = orientation(downInd(i));
        orientation(downInd(i-1)) = AllignOrient2Ref(thisOrient,reference,angle_flip_threshold);
    end
    
else
     
    thesePoints = StartEndIndex(1):StartEndIndex(2);
    % verify that index range covers the set point
    if ~ismember(setPoint,thesePoints)
        error('SetPoint is not valid')
    end
    
    orientationtemp = orientation(thesePoints);
    setPointtemp = find(thesePoints==setPoint);
    
    % get all points that have numeric values
    ValidPoints = find(~isnan(orientationtemp));
    
    % if there is not any valid points, return
    if isempty(ValidPoints)
        return
    end
    
    % verify that setPoints is among these
    if ~ismember(setPointtemp,ValidPoints)
        error('SetPoint is not valid')
    end
    
    % get up and down series
    downInd = ValidPoints(1:find(ValidPoints==setPointtemp));
    upInd = ValidPoints(find(ValidPoints==setPointtemp):end);
%     % remove the set point
%     downInd(end) = [];
%     upInd(1) = [];
    

    % move up the points
    for i = 2:length(upInd)
        thisOrient = orientationtemp(upInd(i));
        reference = orientationtemp(upInd(i-1));
        orientationtemp(upInd(i)) = AllignOrient2Ref(thisOrient,reference,angle_flip_threshold);
    end
    
    % move down the points
    for i = length(downInd):-1:2
        thisOrient = orientationtemp(downInd(i-1));
        reference = orientationtemp(downInd(i));
        orientationtemp(downInd(i-1)) = AllignOrient2Ref(thisOrient,reference,angle_flip_threshold);
    end
   
        
    % put the flipped part back in to the vector
    orientation(thesePoints) = orientationtemp;
end
    
    
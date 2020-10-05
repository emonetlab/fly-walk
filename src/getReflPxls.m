function R = getReflPxls(f,refOrder,theseFlies,thisFrame,resizeRef)
%getReflPxls
%   ReflPxls = getReflPxls(f,theseflies,refOrder,resize_ref) returns the pxls
%   (xloc,yloc) of the reflections predicted using the geometrical
%   prediction. refOrder defines the reflection type. 1: primary reflection
%   (the reflection of flies walking upside down on the top  surface) and
%   2: secondary reflection (the reflection of flies walking on the bottom
%   surface). theseFlies defines the flies whose reflection pxls are
%   requested (default all flies). thisFrame defines the frame number on 
%   which the reflection detection will be carried out. resizeRef resizes
%   the area of the reflection (default 1). R is a cell array of length 
%   same as number of requested flies.
%
switch nargin
    case 4
        resizeRef = 1; % do not change the reflection size
    case 3
        resizeRef = 1; % do not change the reflection size
        thisFrame = []; % use current frame
    case 2
        resizeRef = 1; % do not change the reflection size
        thisFrame = []; % use current frame
        theseFlies = 'All'; % get reflections of all flies
    case 1
        resizeRef = 1; % do not change the reflection size
        thisFrame = []; % use current frame
        theseFlies = 'All'; % get reflections of all flies
        refOrder = [1,2]; % get both reflection pixels
end

% sanity check
assert(length(refOrder)<=2,'refOrder cannot be be longer than 2')
for i = 1:length(refOrder)
    assert(any(refOrder(i)==[1,2]),'refOrder cannot have a value other than 1 or 2')
end
if isnumeric(theseFlies)
    assert(isnan(theseFlies),'Fly list cannot be NaN')
end
if isempty(thisFrame)
    thisFrame = f.current_frame;
end
if ischar(theseFlies)
    if strcmpi(theseFlies,'All')
        % get all active flies now
        theseFlies = find(f.tracking_info.fly_status(:,thisFrame)==1);
    else
        error('uncoded region')
    end
end

% go over all flies and get the pixel list
R(length(theseFlies)).flyNum = theseFlies(end); % allocate space 
% assign the fly numbers
for i = 1:length(theseFlies)
    thisFly = theseFlies(i);
    R(i).flyNum = thisFly;
end
% now get the pixels lists
for k = 1:length(refOrder)
    thisRefOrder = refOrder(k);
    for i = 1:length(theseFlies)
        thisFly = theseFlies(i);
        R(i).(['ReflPxls',num2str(thisRefOrder)]) = PredRefGeomFly(f,thisFly,thisRefOrder,resizeRef,thisFrame);
    end
end
    
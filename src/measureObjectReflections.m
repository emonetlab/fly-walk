% measureObjectReflections
% find and measure all reflection intensities in the image
%
function f = measureObjectReflections(f)


if f.fillNmeasure
    raw_image = fillFlies(f.current_raw_frame,2); % dilation number
else
    raw_image = f.current_raw_frame;
end

S = f.current_objects;


% get and measure reflections
S = PredRefGeom(S,f.ExpParam); % get reflections
S = measureRefInt(S,raw_image); % measure reflection intensity

% add to the object
f.current_objects = S;

% label reflection and fly body matches. Check if reflection falls on 
% flies or other reflection if does register -1 

% if f.ft_debug
% 	disp(['current_frame:	' oval(f.current_frame), '  ', oval(length(r)), ' objects found.'])
% end

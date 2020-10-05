% handleThisObjectsReflection
% find and measure the reflection of a given fly object, assign the
% reflection status and measure the overlap
%
function f = handleThisObjectsReflection(f,this_object)


if f.fillNmeasure
    raw_image = fillFlies(f.current_raw_frame,2); % dilation number
else
    raw_image = f.current_raw_frame;
end

% get the particular object
S = f.current_objects(f.current_object_status==this_object);


% get and measure reflections
S = PredRefGeom(S,f.ExpParam); % get reflections
S = measureRefInt(S,raw_image); % measure reflection intensity

if (min(FlyDist2Edges(f,this_object))<f.close_to_wall_dist)&&isempty(S)
    return
elseif isempty(S)
    disp('something is wrong. fly is lost somewhere in the arena without any reason')
    return
end

% record reflection measurement and update the status
f.reflection_meas(this_object,f.current_frame) = S.RFluo;
f.reflection_status(this_object,f.current_frame) = S.RFluo>f.ref_thresh;

% measure the overlap and update the status value
f = checkThisReflectionOverlap(f,this_object);


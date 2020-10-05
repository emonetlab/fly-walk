function [RefInt1,RefInt2] = measureRefIntofThisFly(f,thisFly,thisFrame)
%measureRefIntofThisFly
% returns the mean reflection intensity of given fly in given frame of the
% video. output is intensities of primary and secondary reflections

if nargin == 2
    thisFrame = f.current_frame;
end

if thisFrame == f.current_frame
    if isempty(f.current_objects)
        S = TrackInfo2Struct(f,thisFly,thisFrame);
    else
        S = f.current_objects(f.current_object_status==thisFly);
    end
else
    S = TrackInfo2Struct(f,thisFly,thisFrame);
end

% now create objects for primary and secondary reflections
 S1 = PredRefGeom(S,f.ExpParam); % get reflections 
 S2 = PredRefGeom2(S,f.ExpParam,f.refl_dist_param(2),1); % get reflections
 
 % measure the reflections
 S1 = measureRefInt(S1,f.current_raw_frame);
 S2 = measureRefInt(S2,f.current_raw_frame);
 
 RefInt1 = S1.RFluo;
 RefInt2 = S2.RFluo;


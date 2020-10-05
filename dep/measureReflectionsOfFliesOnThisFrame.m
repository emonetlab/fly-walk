% measureReflectionsOfFliesOnThisFrame
% f = measureReflectionsOfFliesOnThisFrame(f)
% measures the reflections (primary) of flies in the current frame of the
% given flywalk object f
%
function f = measureReflectionsOfFliesOnThisFrame(f)


% get and measure reflections
S = TrackInfo2Struct(f);
S = PredRefGeom(S,f.ExpParam); % get reflections
S = measureRefInt(S,f.current_raw_frame); % measure reflection intensity
% append measured fluorescence to f
for flyNum = 1:numel(S)
f.reflection_meas(S(flyNum).FlyNum,f.current_frame) = S(flyNum).RFluo;
end
    if f.current_frame<=f.ref_check_len
        theseFrames = 1:f.current_frame;
    else
        theseFrames = f.current_frame-f.ref_check_len:f.current_frame;
    end
    refmt = nonzeros(f.reflection_meas(S(flyNum).FlyNum,~isnan(f.reflection_meas(S(flyNum).FlyNum,theseFrames))));
    f.reflection_status(S(flyNum).FlyNum,f.current_frame) = mean(refmt)>f.ref_thresh;
end

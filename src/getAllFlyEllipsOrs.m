function f = getAllFlyEllipsOrs(f)
% calculates the orientations of all flies in the current frame by using
% the fly intensity gradient

if ~isempty(f.current_objects)
    return
end

% reconstruct current objects
f = reConstructCurrentObjetcs(f);

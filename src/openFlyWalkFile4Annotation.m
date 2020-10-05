function f = openFlyWalkFile4Annotation(filepath) 
f=openFileFlyWalk(filepath,1,0);
f.track_movie=0;
f.show_annotation=1;
f.show_reflections=3;
% check variables and get them
if ~isfield(f.tracking_info,'coligzone')
    disp('getting collision-ignore-zone status')
    f = getCIZoneStatus(f);
end
if ~isfield(f.tracking_info,'periphery')
    disp('getting periphery status')
    f = getPeripheryStatus(f);
end
if ~isfield(f.tracking_info,'perimeter')
    disp('measuring perimeter of flies')
    f = getPerimeterNEccent(f);
end
f.annotateFlyWalk;
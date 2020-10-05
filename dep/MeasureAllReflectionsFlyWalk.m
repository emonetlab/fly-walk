% loads the given file, tracks if not tracked, fixes orientations by two
% different methods, optimizes antenna for these two methods, then measures
% the signal for both ellipse and circle antenna using both mean and median
% methods
% now only extracts fixed antenna, ellips shape and m1 orientation
% correction. By default the flywalk is set to these settings
%
% file is saved at the end of each section so that if a later sections
% fails rest of the data is not lost
%
function MeasureAllReflectionsFlyWalk(filepath)
% open filewalk file without gui
f=openFileFlyWalk(filepath,0,0);

% set reflection measurement to all frames
f.nframes_ref = 1:f.nframes;           % number of frames to determine reflections in the begiining of the video


% measure reflections
f.track_movie = false;
f.current_frame = 1;
tic
for i = 1:f.nframes
    f.previous_frame = f.current_frame;
    f.current_frame = i;
    f.operateOnFrame;
    % get the overlaps
    f = measureReflectionsOfFliesOnThisFrame(f);
    t = toc;
    fps = (i-1)/t;
    disp(['frame# ' oval(f.current_frame) ' @ ' oval(fps) ' fps'])
end
disp('measured all reflections in this video');


% save the file
f.save;
disp('flywalk file is saved');


end

function f = findAllIgnoredInteractions(f)
% finds all ignored interactions in the video

if ~isfield(f.tracking_info,'IgnoredInteractions')
    f.tracking_info.IgnoredInteractions = NaN(size(f.tracking_info.collision)); % ignored interactions
end

for framenum = 1:f.nframes
    f = findIgnoredInteractions(f,framenum);
end
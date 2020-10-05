function f = getFlyWalkingDirAllFrames(f)
% returns the walking directions of flies estimated by calculating the
% vector angle between two consecutive fly position

if f.ft_debug
    disp('Estimating the walking direction (Heading) of all flies in this video...')
end

for frameNum = 2:f.nframes
    if f.ft_debug
        disp(['Frame #: ' num2str(frameNum)])
    end
    f = getFlyWalkingDir(f,frameNum);
end




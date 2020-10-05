function AntBoxSignal = getAntennaBoxSignal(f,flynum)
%getAntennaBoxSignal measures the signal in the virtual antena of a box
%shape. Returns the intensity along the virtual antenna box perpendicular
%to the fly orientation. This should be run after all the tracking is done
%since the code will estimate the virtuial antenna box length using the fly
%width. If the code is run while tracking the measurement length will
%change from frame to frame and can lead to complications.
%

% get antenna pixel list of this fly
antpxls = getAntPxlList(f,flynum);

% set empty signal variable
AntBoxSignal = nan(antpxls(end,3),1);

for i = 1:antpxls(end,3)
    idx = antpxls(antpxls(:,3)==i,4);
    idx(isnan(idx)) = [];
    if isempty(idx)
        continue
    end
    AntBoxSignal(i) = mean(double((f.current_raw_frame(idx))));
end
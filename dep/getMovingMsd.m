function [movingmsd,summsd,meanmsd,absdisp,msdVec] = getMovingMsd(x,nsteps,windowsize,offset)
%getMovingMsd
% [movingmsd,summsd,meanmsd,absdisp] = getMovingMsd(x,nsteps,windowsize) return the moving mean
% square displacement (msd) calculated for windowsize chunks of the input
% vector x for only nsteps. Cumulative sum of the msd for all nsteps is
% also returned.
%
% Update: absolute displacment is also returned; |x(last)-x(0)|
%
% x is a column vector or matrix
%
% if center offset is required then nstpes has to be odd. Even nsteps is
% increased by one.
%
switch nargin
    case 4
        if strcmp(offset,'center')
            if mod(nsteps,2)==0
                nsteps =  nsteps +1;
            end
            if mod(windowsize,2)==0
                windowsize =  windowsize +1;
            end
        end
    case 3
        offset = 'center'; % calculate msd and move to the center of the vector
        if mod(nsteps,2)==0
            nsteps =  nsteps +1;
        end
        if mod(windowsize,2)==0
            windowsize =  windowsize +1;
        end
    case 2
        offset = 'center'; % calculate msd and move to the center of the vector
        if mod(nsteps,2)==0
            nsteps =  nsteps +1;
        end
        windowsize = nsteps;
end

movingmsdt = zeros(size(x,1)-windowsize,1);
summsdt = zeros(size(x,1)-windowsize,1);
meanmsdt = zeros(size(x,1)-windowsize,1);
absdispt = zeros(size(x,1)-windowsize,1);
msdVecdt = zeros(size(x,1)-windowsize,nsteps);

for i = 1:(size(x,1)-windowsize)
    xtemp = x(i:i+windowsize,:);
    msdi = msd(xtemp,nsteps);
    msdVecdt(i,:) = msdi;
    movingmsdt(i) = msdi(nsteps);
    summsdt(i) = sum(msdi);
    meanmsdt(i) = mean(msdi);
    absdispt(i) = sqrt(sum((xtemp(end,:) - xtemp(1,:)).^2));
end

% preapare output
movingmsd = nan(size(x,1),1);
summsd = nan(size(x,1),1);
meanmsd = nan(size(x,1),1);
absdisp = nan(size(x,1),1);
msdVec = nan(size(x,1),nsteps);

if strcmp(offset,'center')
    movingmsd((windowsize+1)/2:(windowsize+1)/2+length(movingmsdt)-1) = movingmsdt;
    summsd((windowsize+1)/2:(windowsize+1)/2+length(movingmsdt)-1) = summsdt;
    meanmsd((windowsize+1)/2:(windowsize+1)/2+length(movingmsdt)-1) = meanmsdt;
    absdisp((windowsize+1)/2:(windowsize+1)/2+length(movingmsdt)-1) = absdispt;
    msdVec((windowsize+1)/2:(windowsize+1)/2+length(movingmsdt)-1,:) = msdVecdt;
elseif strcmp(offset,'start')
    movingmsd(1:length(movingmsdt)) = movingmsdt;
    summsd(1:length(movingmsdt)) = summsdt;
    meanmsd(1:length(movingmsdt)) = meanmsdt;
    absdisp(1:length(movingmsdt)) = absdispt;
    msdVec(1:length(movingmsdt),:) = msdVecdt;
elseif strcmp(offset,'end')
    movingmsd(end-length(movingmsdt)+1:end) = movingmsdt;
    summsd(end-length(movingmsdt)+1:end) = summsdt;
    meanmsd(end-length(movingmsdt)+1:end) = meanmsdt;
    absdisp(end-length(movingmsdt)+1:end) = absdispt;
    msdVec(end-length(movingmsdt)+1:end,:) = msdVecdt;
else
    error('unknown offset method')
end



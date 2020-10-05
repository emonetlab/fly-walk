function f = getMsdFlyWalkFile(f)
% get window and estimation lengths
msdLenVal = f.tracking_info.msdLenVal;        % msd calculation length , sec
msdWindLenVal = f.tracking_info.msdWindLenVal;     % msd calculation window , sec
msdoffsetVal = f.tracking_info.msdoffsetVal;

% calculate msd
x = f.tracking_info.x;
y = f.tracking_info.y;
nsteps = round(msdLenVal*f.ExpParam.fps); % msd calculation data points
nwindow = round(msdWindLenVal*f.ExpParam.fps); % msd calculation data points
disp('Calculating msd...')
[mm,ms,mnm,ad,msdMat] = getMovingMsdMat(x,y,nsteps,2,nwindow,msdoffsetVal,1);
f.tracking_info.msdMov = mm; % moving msd
f.tracking_info.msdSum = ms;  % msd sum
f.tracking_info.msdMean= mnm; % mean of the msd over all time steps
f.tracking_info.totDisp = ad;   % actual displacement
f.tracking_info.msdMat = msdMat;    % msd vs time at t
timetemp = 1:size(msdMat,3);
msdSlope = nan([size(msdMat,1),size(msdMat,2),2]);
disp('fitting a line to log-log msd...')
for k = 1:size(msdMat,1)
    thismsdMat = squeeze(msdMat(k,:,:));
    for i = 1:size(msdMat,2)
        msditemp = thismsdMat(i,:);
        % eliminate zero values
        thistimetemp =  timetemp;
        thistimetemp(msditemp==0) = [];
        msditemp(msditemp==0) = [];
        if isempty(msditemp)
            msdSlope(k,i,:) = 0;
            continue
        end
        msdSlope(k,i,:) = polyfit(log(thistimetemp),log(msditemp),1);
    end
    disp(['Completed ',num2str(k),'/',num2str(size(msdMat,1)),' ...'])
end
f.tracking_info.msdSlope =  msdSlope;  % slope of log log msd vs time

function msdout = msd(x,nsteps)
%msd
% msd = msd(x,nsteps) calculate the mean square displacement of given x for
% nsteps (default: the length of the vector). If x is a matrix, 1st
% dimension is taken as time and coluns are assumes as x,y and z. Max
% allowed column number is 3.
% In order to calculate the msd at a single point pass the nsteps as a
% string.
%
assert(~isscalar(x),'Please provide a vector or a matrix')

if isvector(x)
    if nargin==1
        nsteps = length(x);
        msdout = calculatemsd(x,nsteps);
    elseif isnumeric(nsteps)
        assert(isscalar(nsteps),'nsteps has to be a single integer')
        msdout = calculatemsd(x,nsteps);
    elseif ischar(nsteps)
        nsteps = str2num(nsteps);
        singlestep = 'yes';
        assert(isscalar(nsteps),'nsteps has to be a single integer')
        msdout = calculatemsd(x,nsteps,singlestep);
    else
        error('unknown nsteps. please check!')
    end
elseif ismatrix(x)
    % matrix must be a column vector
    assert(size(x,2)<3,'x has to be a matrix with max 3 column (x,y,z)')
    if size(x,2)==2
        xvec = x(:,1);
        yvec = x(:,2);
        if nargin==1
            nsteps = length(xvec);
            msdout = calculatemsd2(xvec,yvec,nsteps);
        elseif isnumeric(nsteps)
            assert(isscalar(nsteps),'nsteps has to be a single integer')
            msdout = calculatemsd2(xvec,yvec,nsteps);
        elseif ischar(nsteps)
            nsteps = str2num(nsteps);
            singlestep = 'yes';
            assert(isscalar(nsteps),'nsteps has to be a single integer')
            msdout = calculatemsd2(xvec,yvec,nsteps,singlestep);
        else
            error('unknown nsteps. please check!')
        end
    else
        xvec = x(:,1);
        yvec = x(:,2);
        zvec = x(:,3);
        if nargin==1
            nsteps = length(xvec);
            msdout = calculatemsd3(xvec,yvec,zvec,nsteps);
        elseif isnumeric(nsteps)
            assert(isscalar(nsteps),'nsteps has to be a single integer')
            msdout = calculatemsd3(xvec,yvec,zvec,nsteps);
        elseif ischar(nsteps)
            nsteps = str2num(nsteps);
            singlestep = 'yes';
            assert(isscalar(nsteps),'nsteps has to be a single integer')
            msdout = calculatemsd3(xvec,yvec,zvec,nsteps,singlestep);
        else
            error('unknown nsteps. please check!')
        end
    end
    
end

end

function msdout = calculatemsd(x,nsteps,singlestep)
if nargin == 2
    singlestep = 'no';
end
if strcmp(singlestep,'no')
    thesesteps = 1:nsteps;
elseif strcmp(singlestep,'yes')
    thesesteps = nsteps;
else
    error('unknown singlestep definition')
end

% columnize input
xin = x(:);

%# calculate msd for all deltaT's
if strcmp(singlestep,'no')
    % reshape output
    if iscolumn(x)
        msdout = zeros(nsteps,1);
    else
        msdout = zeros(1,nsteps);
    end
    for dt = thesesteps
        deltaCoords = xin(1+dt:end) - xin(1:end-dt);
%         squaredDisplacement = sum(deltaCoords.^2);
        squaredDisplacement = (deltaCoords.^2);
        msdout(dt) = mean(squaredDisplacement); %# average
    end
else
    dt = thesesteps;
    deltaCoords = xin(1+dt:end) - xin(1:end-dt);
%     squaredDisplacement = sum(deltaCoords.^2);
    squaredDisplacement = (deltaCoords.^2);
    msdout = mean(squaredDisplacement); %# average
end

end

function msdout = calculatemsd2(x,y,nsteps,singlestep)
if nargin == 3
    singlestep = 'no';
end
if strcmp(singlestep,'no')
    thesesteps = 1:nsteps;
elseif strcmp(singlestep,'yes')
    thesesteps = nsteps;
else
    error('unknown singlestep definition')
end

% columnize inputs
xin = x(:);
yin = y(:);

assert(length(xin)==length(yin),'Vector lengths has to be same')

%# calculate msd for all deltaT's
if strcmp(singlestep,'no')
    % reshape output
    if iscolumn(x)
        msdout = zeros(nsteps,1);
    else
        msdout = zeros(1,nsteps);
    end
    for dt = thesesteps
        deltaCoordsx = xin(1+dt:end) - xin(1:end-dt);
        deltaCoordsy = yin(1+dt:end) - yin(1:end-dt);
%         squaredDisplacement = sum(deltaCoordsx.^2+deltaCoordsy.^2);
        squaredDisplacement = (deltaCoordsx.^2+deltaCoordsy.^2);
        msdout(dt) = mean(squaredDisplacement); %# average
    end
else
    dt = thesesteps;
    deltaCoordsx = xin(1+dt:end) - xin(1:end-dt);
    deltaCoordsy = yin(1+dt:end) - yin(1:end-dt);
%     squaredDisplacement = sum(deltaCoordsx.^2+deltaCoordsy.^2);
    squaredDisplacement = (deltaCoordsx.^2+deltaCoordsy.^2);
    msdout = mean(squaredDisplacement); %# average
end

end
function msdout = calculatemsd3(x,y,z,nsteps,singlestep)

if nargin == 4
    singlestep = 'no';
end
if strcmp(singlestep,'no')
    thesesteps = 1:nsteps;
elseif strcmp(singlestep,'yes')
    thesesteps = nsteps;
else
    error('unknown singlestep definition')
end

% columnize inputs
xin = x(:);
yin = y(:);
zin = z(:);
lenvec = [length(xin),length(yin),length(zin)];

assert(sum(sum(lenvec==lenvec')),'Vector lengths has to be same')

%# calculate msd for all deltaT's
if strcmp(singlestep,'no')
    % reshape output
    if iscolumn(x)
        msdout = zeros(nsteps,1);
    else
        msdout = zeros(1,nsteps);
    end
    for dt = thesesteps
        deltaCoordsx = xin(1+dt:end) - xin(1:end-dt);
        deltaCoordsy = yin(1+dt:end) - yin(1:end-dt);
        deltaCoordsz = zin(1+dt:end) - zin(1:end-dt);
%         squaredDisplacement = sum(deltaCoordsx.^2+deltaCoordsy.^2+deltaCoordsz.^2);
        squaredDisplacement = (deltaCoordsx.^2+deltaCoordsy.^2+deltaCoordsz.^2);
        msdout(dt) = mean(squaredDisplacement); %# average
    end
else
    dt = thesesteps;
    deltaCoordsx = xin(1+dt:end) - xin(1:end-dt);
    deltaCoordsy = yin(1+dt:end) - yin(1:end-dt);
    deltaCoordsz = zin(1+dt:end) - zin(1:end-dt);
%     squaredDisplacement = sum(deltaCoordsx.^2+deltaCoordsy.^2+deltaCoordsz.^2);
    squaredDisplacement = (deltaCoordsx.^2+deltaCoordsy.^2+deltaCoordsz.^2);
    msdout = mean(squaredDisplacement); %# average
end

end

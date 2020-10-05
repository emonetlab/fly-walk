function [movmsd,summsd,meanmsd,absdisp,msdMat] = getMovingMsdMat(x,y,nsteps,dim,windowsize,offset,showprog)
%getMovingMsdMat
% [movmsd,summsd,meanmsd,absdisp,msdMat] = getMovingMsdMat(x,y,nsteps,dim,windowsize,offset,showprog)
% return the moving msd, sum of the msd and absolute displacement of given
% matrix in dimension dim. Default 1, Assumes column vectors.
% offset is set to 'center', calculated the msd around the point. Other
% options are ofset: 'center' | 'start' | 'end'
%

switch nargin
    case 7
        if strcmp(offset,'center')
            if mod(nsteps,2)==0
                nsteps =  nsteps +1;
            end
            if mod(windowsize,2)==0
                windowsize =  windowsize +1;
            end
        end
    case 6
        showprog = 0; % do not popup a wait bar
        if strcmp(offset,'center')
            if mod(nsteps,2)==0
                nsteps =  nsteps +1;
            end
            if mod(windowsize,2)==0
                windowsize =  windowsize +1;
            end
        end
    case 5
        offset = 'center'; % calculate msd and move to the center of the vector
        if mod(nsteps,2)==0
            nsteps =  nsteps +1;
        end
        if mod(windowsize,2)==0
            windowsize =  windowsize +1;
        end
    case 4
        offset = 'center'; % calculate msd and move to the center of the vector
        if mod(nsteps,2)==0
            nsteps =  nsteps +1;
        end
        windowsize = nsteps;
    case 3
        offset = 'center'; % calculate msd and move to the center of the vector
        if mod(nsteps,2)==0
            nsteps =  nsteps +1;
        end
        windowsize = nsteps;
        dim = 1;
end


% initate output matrices
movmsd = nan(size(x));
summsd = nan(size(x));
meanmsd = nan(size(x));
absdisp = nan(size(x));
msdMat = nan([size(x),nsteps]);

if isempty(x)
    % msd on y columns
    % if row calculation is requested then transpose x
    x = y;
    if dim == 2
        x = x';
        movmsd = movmsd';
        summsd = summsd';
        meanmsd = meanmsd';
        absdisp = absdisp';
        msdMat = permute(msdMat,[2 1 3]);
    end
    
    if showprog
        wb = waitbar(0,'Calculating msd...');
    end
    % go over columns and get the msd
    for coln = 1:size(x,2)
        [mmi,smi,ami,adi,msdVec] = getMovingMsd(x(:,coln),nsteps,windowsize,offset);
        movmsd(:,coln) = mmi;
        summsd(:,coln) = smi;
        meanmsd(:,coln) = ami;
        absdisp(:,coln) = adi;
        msdMat(:,coln,:) = msdVec;
        if showprog
            waitbar(coln/size(x,2),'Calculating msd...');
        end
    end
    if showprog
        waitbar(coln/size(x,2),'Done!');
    end
    % tanspose back if did so
    if dim == 2
        movmsd = movmsd';
        summsd = summsd';
        meanmsd = meanmsd';
        absdisp = absdisp';
        msdMat = permute(msdMat,[2 1 3]);
    end
    
    if showprog
        delete(wb)
    end
    
elseif isempty(y)
    % msd on y columns
    % if row calculation is requested then transpose x
    if dim == 2
        x = x';
        movmsd = movmsd';
        summsd = summsd';
        meanmsd = meanmsd';
        absdisp = absdisp';
        msdMat = permute(msdMat,[2 1 3]);
    end
    
    if showprog
        wb = waitbar(0,'Calculating msd...');
    end
    
    % go over columns and get the msd
    for coln = 1:size(x,2)
        [mmi,smi,ami,adi,msdVec] = getMovingMsd(x(:,coln),nsteps,windowsize,offset);
        movmsd(:,coln) = mmi;
        summsd(:,coln) = smi;
        meanmsd(:,coln) = ami;
        absdisp(:,coln) = adi;
        msdMat(:,coln,:) = msdVec;
        if showprog
            waitbar(coln/size(x,2),'Calculating msd...');
        end
    end
    if showprog
        waitbar(coln/size(x,2),'Done!');
    end
    % tanspose back if did so
    if dim == 2
        movmsd = movmsd';
        summsd = summsd';
        meanmsd = meanmsd';
        absdisp = absdisp';
        msdMat = permute(msdMat,[2 1 3]);
    end
    if showprog
        delete(wb)
    end
    
else % two matrices are supplied
    % sizes of x and y must be same
    assert(trace(size(x)==size(y)')==2,'x and y must be same size')
    % if row calculation is requested then transpose x
    if dim == 2
        x = x';
        y = y';
        movmsd = movmsd';
        summsd = summsd';
        meanmsd = meanmsd';
        absdisp = absdisp';
        msdMat = permute(msdMat,[2 1 3]);
    end
    
    if showprog
        pcnt = 0;
        wb = waitbar(pcnt,[num2str(round(pcnt*100)),'%'],'Name','Calculating msd...');
    end
    
    % go over columns and get the msd
    for coln = 1:size(x,2)
        [mmi,smi,ami,adi,msdVec] = getMovingMsd([x(:,coln),y(:,coln)],nsteps,windowsize,offset);
        movmsd(:,coln) = mmi;
        summsd(:,coln) = smi;
        meanmsd(:,coln) = ami;
        absdisp(:,coln) = adi;
        msdMat(:,coln,:) = msdVec;        
        if showprog
            pcnt = coln/size(x,2);
            waitbar(pcnt,wb,[num2str(round(pcnt*100)),'%']);
        end
    end
    if showprog
        pcnt = coln/size(x,2);
        waitbar(pcnt,wb,[num2str(round(pcnt*100)),'%']);
    end
    % tanspose back if did so
    if dim == 2
        movmsd = movmsd';
        summsd = summsd';
        meanmsd = meanmsd';
        absdisp = absdisp';
        msdMat = permute(msdMat,[2 1 3]);
    end
    if showprog
        delete(wb)
    end
    
end

end
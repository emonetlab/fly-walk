function [movmsd,summsd,absdisp] = getMsdExpMatColumn(em,nsteps,colnumx,colnumy,windowsize,pointOrtime,fpscolnum)
%getMsdExpMatColumn
% [movmsd,summsd,absdisp] = getMsdExpMatColumn(em,nsteps,colnumx,colnumy,windowsize,pointOrtime,fpscolnum)
% Calculates the measn square displacement of each track calculated at 
% nsteps (default time). Returns the sum of the msd as well. msd is calculated
% starting at 1st point in a windowsize chunks. Therefore last windowsize
% points are assigned as nan. If a track length is less than windows size, 
% nsteps and windowssize are set to the length of the track automatically.
% (default fps clumn number = 20). 
% update: the abs displacement: |x(last)-x(0)| is also returned
%
% default offset for msd calculation is center
% getMovingMsd(xtemp,nstepsi,windowsizei) will get center offset
% to get start offset:
% type getMovingMsd(xtemp,nstepsi,windowsizei,'start')
%

switch nargin
    case 6
        fpscolnum = 20;
    case 5
        fpscolnum = 20;
        pointOrtime = 'time'; % by default sclaculates the n for each track according to the fps
    case 4
        fpscolnum = 20;
        pointOrtime = 'time'; % by default sclaculates the n for each track according to the fps
        windowsize = nsteps;
    case 3
        fpscolnum = 20;
        pointOrtime = 'time'; % by default sclaculates the n for each track according to the fps
        windowsize = nsteps;
        colnumy = 7; % default y column
    case 2
        fpscolnum = 20;
        pointOrtime = 'time'; % by default sclaculates the n for each track according to the fps
        windowsize = nsteps;
        colnumy = 7; % default y column
        colnumx = 6; % default y column     
end


trackindex = unique(em(:,1));

if strcmp(pointOrtime,'time')
    
    movmsd = nan(size(em(:,1)));
    summsd = nan(size(em(:,1)));
    absdisp = nan(size(em(:,1)));
    
    for tracknum = 1:length(trackindex)
        sind = find(em(:,1)==trackindex(tracknum),1,'first');
        eind = find(em(:,1)==trackindex(tracknum),1,'last');
        if length(sind:eind)>=windowsize
            emt = em(em(:,1)==trackindex(tracknum),:);
            nstepsi = round(nsteps*emt(1,fpscolnum));
            windowsizei = round(windowsize*emt(1,fpscolnum));
            xtemp = [emt(:,colnumx),emt(:,colnumy)];
            [movmsdi,summsdi,~,absdispi] = getMovingMsd(xtemp,nstepsi,windowsizei);
        else
            nstepsi = length(sind:eind);
            windowsizei = length(sind:eind);
            emt = em(em(:,1)==trackindex(tracknum),:);
            xtemp = [emt(:,colnumx),emt(:,colnumy)];
            [movmsdi,summsdi,~,absdispi] = getMovingMsd(xtemp,nstepsi,windowsizei);
        end
        movmsd(sind:eind) = movmsdi;
        summsd(sind:eind) = summsdi;
        absdisp(sind:eind) = absdispi;
    end
else
    
    movmsd = nan(size(em(:,1)));
    summsd = nan(size(em(:,1)));
    absdisp = nan(size(em(:,1)));
    
    for tracknum = 1:length(trackindex)
        sind = find(em(:,1)==trackindex(tracknum),1,'first');
        eind = find(em(:,1)==trackindex(tracknum),1,'last');
        if length(sind:eind)>=windowsize
            emt = em(em(:,1)==trackindex(tracknum),:);
            xtemp = [emt(:,colnumx),emt(:,colnumy)];
            [movmsdi,summsdi,~,absdispi] = getMovingMsd(xtemp,nsteps,windowsize);
        else
            nstepsi = length(sind:eind);
            windowsizei = length(sind:eind);
            emt = em(em(:,1)==trackindex(tracknum),:);
            xtemp = [emt(:,colnumx),emt(:,colnumy)];
            [movmsdi,summsdi,~,absdispi] = getMovingMsd(xtemp,nstepsi,windowsizei);
        end
        movmsd(sind:eind) = movmsdi;
        summsd(sind:eind) = summsdi;
        absdisp(sind:eind) = absdispi;
    end
end

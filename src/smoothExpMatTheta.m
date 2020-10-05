function [em,smoothColumn] = smoothExpMatTheta(em,colnum,n,pointOrtime,fpscolnum,smthRef)
%smoothExpMatTheta
% em = smoothExpMatTheta(em,colnum,n,pointOrtime,fpscolnum)
% smooths the given column theta using vector algebra for each track in the
% expmat. By default takes n as seconds and calculates the number of
% smoothing points for each track sparately from fps of that track (default
% fps clumn number = 20)
%
switch nargin
    case 5
        smthRef = 'center'; % default smooth reference points. Smooths aound each point
    case 4
        smthRef = 'center'; % default smooth reference points. Smooths aound each point
        fpscolnum = 20;
    case 3
        smthRef = 'center'; % default smooth reference points. Smooths aound each point
        fpscolnum = 20;
        pointOrtime = 'time'; % by default calculates the n for each track according to the fps
end


trackindex = unique(em(:,1));
if strcmp(pointOrtime,'time')
    for tracknum = 1:length(trackindex)
        sind = find(em(:,1)==trackindex(tracknum),1,'first');
        eind = find(em(:,1)==trackindex(tracknum),1,'last');
        
        nthis = round(n*em(sind,fpscolnum));
        if nthis>(eind-sind+1)
            nthis = eind-sind+1;
        end
        if rem(nthis,2) ==0 % increase n by one if it is even.
            nthis = nthis+1;
        end
        if strcmp(smthRef,'center')
            em(sind:eind,colnum) = mod(smoothOrientation(em(sind:eind,colnum),nthis),360);
        elseif strcmp(smthRef,'bwd')
            smtortemp = mod(smoothOrientation(em(sind:eind,colnum),nthis),360);
            em(sind:eind,colnum) = smtortemp;
            em(sind+nthis:eind,colnum) = smtortemp((nthis-1)/2+1:end-(nthis-1)/2-1);
        elseif strcmp(smthRef,'fwd')
            smtortemp = mod(smoothOrientation(em(sind:eind,colnum),nthis),360);
            em(sind:eind,colnum) = smtortemp;
            em(sind:eind-nthis,colnum) = smtortemp((nthis-1)/2+1:end-(nthis-1)/2-1);
        end
    end
else
    for tracknum = 1:length(trackindex)
        sind = find(em(:,1)==trackindex(tracknum),1,'first');
        eind = find(em(:,1)==trackindex(tracknum),1,'last');
        if nthis>(eind-sind+1)
            nthis = eind-sind+1;
        else
            nthis = n;
        end
        if strcmp(smthRef,'center')
            em(sind:eind,colnum) = mod(smoothOrientation(em(sind:eind,colnum),nthis),360);
        elseif strcmp(smthRef,'bwd')
            smtortemp = mod(smoothOrientation(em(sind:eind,colnum),nthis),360);
            em(sind:eind,colnum) = smtortemp;
            em(sind+nthis:eind,colnum) = smtortemp((nthis-1)/2+1:end-(nthis-1)/2-1);
        elseif strcmp(smthRef,'fwd')
            smtortemp = mod(smoothOrientation(em(sind:eind,colnum),nthis),360);
            em(sind:eind,colnum) = smtortemp;
            em(sind:eind-nthis,colnum) = smtortemp((nthis-1)/2+1:end-(nthis-1)/2-1);
        end
    end
end
smoothColumn = em(:,colnum);
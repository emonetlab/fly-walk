function em = smoothExpMatColumn(em,colnum,n,pointOrtime,fpscolnum)
%smoothExpMatColumn
% em = smoothExpMatColumn(em,colnum,n,pointOrtime,fpscolnum)
% smooths the given column using scalar (linear) algebra for each track in the
% expmat. By default takes n as seconds and calculates the number of
% smoothing points for each track sparately from fps of that track (default
% fps clumn number = 20)
%

switch nargin
    case 4
        fpscolnum = 20;
    case 3
        fpscolnum = 20;
        pointOrtime = 'time'; % by default sclaculates the n for each track according to the fps
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
        em(sind:eind,colnum) = smooth(em(sind:eind,colnum),nthis);
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
        em(sind:eind,colnum) = smooth(em(sind:eind,colnum),n);
    end
end
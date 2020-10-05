function em = smoothGaussExpMatColumn(em,colnum,n,pointOrtime,fpscolnum)
%smoothGaussExpMatColumn
% em = smoothGaussExpMatColumn(em,colnum,n,pointOrtime,fpscolnum)
% smooths the given column within a gaussian window of size n seconds.
% Smoothing is done for each track separately. The number of smoothing 
% points for each track is calculated sparately from fps of that track
% (default fps column number = 20)
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
        if nthis<1
            nthis = 1;
        end
        em(sind:eind,colnum) = smoothdata(em(sind:eind,colnum),'gaussian',nthis);
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
        if nthis<1
            nthis = 1;
        end
        em(sind:eind,colnum) = smoothdata(em(sind:eind,colnum),'gaussian',nthis);
    end
end
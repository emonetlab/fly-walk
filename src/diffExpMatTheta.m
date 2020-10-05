function dtheta = diffExpMatTheta(em,colnum,diffMethod,pointOrtime,fpscolnum)
%diffExpMatTheta
% em = diffExpMatTheta(em,colnum,n,diffMethod,pointOrtime,fpscolnum)
% Differentiates the given column using circular algebra for each
% track in the expmat. By default differentiates the column wrt time.
% (default fps clumn number = 20). Default differentiation method is forward
% differentiation: df(x) = f(x+h) - f(x). Other differnetiation options
% are: 'fwd' | 'bwd' | 'central'
%

switch nargin
    case 4
        fpscolnum = 20;
    case 3
        fpscolnum = 20;
        pointOrtime = 'time'; % by default sclaculates the n for each track according to the fps
    case 2
        fpscolnum = 20;
        pointOrtime = 'time'; % by default sclaculates the n for each track according to the fps
        diffMethod = 'fwd';     % default method is forward differentiation
        
end



trackindex = unique(em(:,1));

if strcmp(pointOrtime,'time')
    df = zeros(size(em(:,colnum)));
    for tracknum = 1:length(trackindex)
        sind = find(em(:,1)==trackindex(tracknum),1,'first');
        eind = find(em(:,1)==trackindex(tracknum),1,'last');
        if length(sind:eind)>3
            switch diffMethod
                case 'fwd'
                    h = 1/em(sind,fpscolnum);
                    df(sind:eind) = anglediffFwd(em(sind:eind,colnum))/h;
                case 'bwd'
                    h = 1/em(sind,fpscolnum);
                    df(sind:eind) = anglediffBwd(em(sind:eind,colnum))/h;  
                case 'central'
                    h = 1/em(sind,fpscolnum);
                    df(sind:eind) = anglediffCentral(em(sind:eind,colnum))/h;
            end
        else
            df(sind:eind) = nan;
        end
    end
else
    df = zeros(size(em(:,colnum)));
    for tracknum = 1:length(trackindex)
        sind = find(em(:,1)==trackindex(tracknum),1,'first');
        eind = find(em(:,1)==trackindex(tracknum),1,'last');
        if length(sind:eind)>3
            switch diffMethod
                case 'fwd'
                    df(sind:eind) = anglediffFwd(em(sind:eind,colnum));
                case 'bwd'
                    df(sind:eind) = anglediffBwd(em(sind:eind,colnum));
                case 'central'
                    df(sind:eind) = anglediffCentral(em(sind:eind,colnum));
            end
        else
            df(sind:eind) = nan;
        end
    end
end

dtheta = df;

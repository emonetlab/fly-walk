function dcol = diffExpMatColumn(em,colnum,diffMethod,pointOrtime,fpscolnum)
%diffExpMatColumn
% em = diffExpMatColumn(em,colnum,n,diffMethod,pointOrtime,fpscolnum)
% Differentiates the given column using scalar (linear) algebra for each
% track in the expmat. By default differentiates the column wrt time.
% (default fps clumn number = 20). Default differentiation method is forward
% fifferentiation: df(x) = f(x+h) - f(x). Other differnetiation options
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
    dcol = zeros(size(em(:,1)));
    for tracknum = 1:length(trackindex)
        sind = find(em(:,1)==trackindex(tracknum),1,'first');
        eind = find(em(:,1)==trackindex(tracknum),1,'last');
        if length(sind:eind)>3
            switch diffMethod
                case 'fwd'
                    h = 1/em(sind,fpscolnum);
                    df = diffFwd(em(sind:eind,colnum))/h;
                case 'bwd'
                    h = 1/em(sind,fpscolnum);
                    df = diffBwd(em(sind:eind,colnum))/h;
                case 'central'
                    h = 1/em(sind,fpscolnum);
                    df = diffCentral(em(sind:eind,colnum))/h;
            end
            dcol(sind:eind) = df;
        else
            dcol(sind:eind) = nan;
        end
        
    end
else
    dcol = zeros(size(em(:,1)));
    for tracknum = 1:length(trackindex)
        
        sind = find(em(:,1)==trackindex(tracknum),1,'first');
        eind = find(em(:,1)==trackindex(tracknum),1,'last');
        if length(sind:eind)>2
            switch diffMethod
                case 'fwd'
                    df = diffFwd(em(sind:eind,colnum));
                case 'bwd'
                    df = diffBwd(em(sind:eind,colnum));
                case 'central'
                    df = diffCentral(em(sind:eind,colnum));
            end
            dcol(sind:eind) = df;
        else
            dcol(sind:eind) = nan;
        end
    end
end

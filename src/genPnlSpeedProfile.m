function SR=genPnlSpeedProfile(pnlprf_h,SR,linecolor,xprfylim,yprfxlim,sclrmax,prfLineWidth,colnum)
switch nargin
    case 7
        colnum = [];
    case 6
        colnum = [];
        prfLineWidth = 2; % defaulst prile linewidth
    case 5
        colnum = [];
        prfLineWidth = 2; % defaulst prile linewidth
        sclrmax = 15;
    case 4
        colnum = [];
        prfLineWidth = 2; % defaulst prile linewidth
        sclrmax = 15;
        yprfxlim = 15;
    case 3
        colnum = [];
        prfLineWidth = 2; % defaulst prile linewidth
        sclrmax = 15;
        xprfylim = 15;
        yprfxlim = 15;
    case 2
        colnum = [];
        prfLineWidth = 2; % defaulst prile linewidth
        sclrmax = 15;
        xprfylim = 15;
        yprfxlim = 15;
        linecolor = 'k';
end

if isempty(colnum)
    if isfield(SR,'col')
        colnum = SR.col.speed;
    elseif isfield(SR,'column') 
        % get the column outputs to sturcture inputs
        for i = 1:numel(SR.column)
            SR.col.(SR.column{i}) = i;
        end
        colnum = SR.col.speed;
    else
        colnum = 10;
    end
end

sp=pnlprf_h;
sp.pack({20 80}, {85 15});
sp.de.margin=0;
sp(2,1).select();
smthlen  = 4;

S = SR;
s2d = mean2dtrj(S.expmat,S.mind,colnum);
% s2d(isnan(s2d)) = 0;
S.s2d = smooth2a(s2d,smthlen);
% S.s2d = smooth2b(s2d,smthlen);

imp = imagesc(S.xbinc,S.ybinc,S.s2d,[0 sclrmax]);
axis image
colormap_range=64; % default colormap_range is 64, but change it to your needs
[~,xout] =hist(S.s2d(:),colormap_range);   % hist intensities according to the colormap range
[~,ind]=sort(abs(xout)); % sort according to values closest to zero
j = jet;
% j(ind(1),:) = [ 1 1 1 ]; % also see comment below
% you can also use instead something like j(ind(1:whatever),:)=ones(whatever,3); 
% colormap(j);
colormap(sp(2,1).axis,j);
set(gca,'YDir','reverse')
set(gca,'Box','on')
set(gca,'LineWidth',2)

% set nan to white
imp.AlphaData = ~isnan(S.s2d);

% xprofile
sp(1,1).select();
plot(S.xbinc,nanmean((S.s2d),1),linecolor,'LineWidth',prfLineWidth)
% set(gca,'YDir','reverse')
set(sp(1,1).axis, 'XLim', get(sp(2,1).axis, 'XLim'));
% set(gca,'XAxisLocation','top')
set(gca,'XTick',[],'YColor',linecolor,'XColor',linecolor,'Color','none')
ylim([0,xprfylim])

% yprofile
sp(2,2).select();
plot(nanmean((S.s2d),2),S.ybinc,linecolor,'LineWidth',prfLineWidth)
set(sp(2,2).axis, 'YLim', get(sp(2,1).axis, 'YLim'));
set(gca,'YDir','reverse')
set(gca,'YTick',[],'YColor',linecolor,'XColor',linecolor,'Color','none')
% set(gca,'XAxisLocation','top')
xlim([0,yprfxlim])

SR = S;

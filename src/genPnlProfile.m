function genPnlProfile(pnlprf_h,SR,linecolor,xprfylim,yprfxlim,cthr,clrmap,lineWidth,smoothsize,smootharena)
% works only with panel
switch nargin
    case 9
        smootharena = 0; % do not smooth arena pdf, only smooth integrated pdf along x and y
    case 8 
        smootharena = 0; % do not smooth arena pdf, only smooth integrated pdf along x and y
        smoothsize = 0; % do not smooth
    case 7
        smootharena = 0; % do not smooth arena pdf, only smooth integrated pdf along x and y
        smoothsize = 0; % do not smooth
        lineWidth = 2; % default line with for integrated pdf plots
    case 6
        smootharena = 0; % do not smooth arena pdf, only smooth integrated pdf along x and y
        smoothsize = 0; % do not smooth
        lineWidth = 2; % default line with for integrated pdf plots
        clrmap = 'wcmyk'; % default colormap for the pdf plot
    case 5
        smootharena = 0; % do not smooth arena pdf, only smooth integrated pdf along x and y
        smoothsize = 0; % do not smooth
        lineWidth = 2; % default line with for integrated pdf plots
        clrmap = 'wcmyk'; % default colormap for the pdf plot
        cthr = .0001; % 2d pdf threshold
    case 4
        smootharena = 0; % do not smooth arena pdf, only smooth integrated pdf along x and y
        smoothsize = 0; % do not smooth
        lineWidth = 2; % default line with for integrated pdf plots
        clrmap = 'wcmyk'; % default colormap for the pdf plot
        cthr = .0001; % 2d pdf threshold
        yprfxlim = xprfylim;
    case 3
        smootharena = 0; % do not smooth arena pdf, only smooth integrated pdf along x and y
        smoothsize = 0; % do not smooth
        lineWidth = 2; % default line with for integrated pdf plots
        clrmap = 'wcmyk'; % default colormap for the pdf plot
        cthr = .0001; % 2d pdf threshold
        xprfylim = 0.03;
        yprfxlim = 0.03;
    case 2
        smootharena = 0; % do not smooth arena pdf, only smooth integrated pdf along x and y
        smoothsize = 0; % do not smooth
        lineWidth = 2; % default line with for integrated pdf plots
        clrmap = 'wcmyk'; % default colormap for the pdf plot
        cthr = .0001; % 2d pdf threshold
        xprfylim = 0.03;
        yprfxlim = 0.03;
        linecolor = 'k';
end
sp=pnlprf_h;
sp.pack({20 80}, {85 15});
sp.de.margin = 0;
sp(2,1).select();
ncsr = length((SR.expmat(:,1))); 

if smootharena
    imagesc(SR.xbinc,SR.ybinc,smooth2a((SR.h2d)/ncsr,smoothsize),[0 cthr]);
else
    imagesc(SR.xbinc,SR.ybinc,smooth2a((SR.h2d)/ncsr,0),[0 cthr]);
end
axis image
set(gca,'XTick',[],'YTick',[])
% ylabel('mm')
set(gca,'YDir','reverse')
set(gca,'Box','on')
set(gca,'LineWidth',2)
colormap(sp(2,1).axis,buildcmap(clrmap));

% xprofile
sp(1,1).select();
plot(SR.xbinc,sum(smooth2a((SR.h2d)/ncsr,smoothsize),1),linecolor,'LineWidth',lineWidth)
% set(gca,'YDir','reverse')
set(sp(1,1).axis, 'XLim', get(sp(2,1).axis, 'XLim'));
% set(gca,'XAxisLocation','top')
set(gca,'XTick',[],'YColor',linecolor,'XColor',linecolor,'Color','none')
ylim([0,xprfylim])

% yprofile
sp(2,2).select();
plot(sum(smooth2a((SR.h2d)/ncsr,smoothsize),2),SR.ybinc,linecolor,'LineWidth',lineWidth)
set(sp(2,2).axis, 'YLim', get(sp(2,1).axis, 'YLim'));
set(gca,'YDir','reverse')
set(gca,'YTick',[],'YColor',linecolor,'XColor',linecolor,'Color','none')
% set(gca,'XAxisLocation','top')
xlim([0,yprfxlim])


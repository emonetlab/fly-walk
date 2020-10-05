function [h2dArena,h2dProfile] = genPnlPDFProfile(pnlprf_h,SR,plotP,smoothP)
%genPnlPDFProfile(pnlprf_h,SR,plotP,smoothP)
% function [h2da,h2dp] = genPnlPDFProfile(pnlprf_h,SR,plotP,smoothP)
% Calculates and plots normalized 2D histogram in the arena and marginals
% works only with panel
%


switch nargin
    case 3
        smoothP = []; % use default smoothing properties
    case 2
        smoothP = []; % use default smoothing properties
        plotP = []; % use default plotting properties
end



% set default values - plot Properties
plotPInput = plotP;

plotP.lineWidth = 1; % default line with for integrated pdf plots
plotP.clrmap = 'wck'; % default colormap for the pdf plot
plotP.cthr = .0001; % 2d pdf threshold
plotP.xprfylim = 0.03;
plotP.yprfxlim = 0.03;
plotP.linecolor = 'b';
plotP.scale = 'linear'; % plot the integrated profiles in linear scale
plotP.PosDataMinX = 0; % min x position for pdf calculation
plotP.PosPDFMinX = 0; % min x position for pdf calculation
plotP.PosDataDMaxX = 0; % x position offset from max x for pdf calculation
plotP.PosPDFDMaxX = 0; % y position offset from max y  for pdf calculation
plotP.PosPDFMinXExc2D = 0; % 1: does not plot exluded data in 2D 0: plots the whole arena but does not include minX data in pdf
plotP.PosPDFExc2DAlphaVal = .3;
plotP.AxisLineWidth = .5;   % axis line width
plotP.PlotProfile = 1;   % plot 2D distribution on the given axis

if isa(pnlprf_h,'panel')
    plotP.PlotProfile = 1;   % plot 2D distribution on the given axis
    
elseif isempty(pnlprf_h)||isnan(pnlprf_h)||iszero(pnlprf_h)
    plotP.PlotProfile = 0;   % do not plot 2D distribution on the given axis
end


% replace with user input
if ~isempty(plotPInput)
    userVar = fieldnames(plotPInput);
    plotPVars = fieldnames(plotP);
    for i = 1:numel(userVar)
        if any(strcmp(userVar{i},plotPVars'))
            plotP.(userVar{i}) = plotPInput.(userVar{i});
        end
    end
end
% delete input
clear plotPInput

% set default values - Smooth Properties
smoothPInput = smoothP;

smoothP.method = 'gauss';   % smooth with a gauss filter
smoothP.filterSize = 1;     % smooth with a gauss filter with 1 mm sigma
smoothP.arena = 1;          % smooth the arena with a 2D gauss filter
smoothP.profile = 1;        % smooth the arena with a 2D gauss filter and calculate the profiles

% replace with user input
if ~isempty(smoothPInput)
    userVar = fieldnames(smoothPInput);
    smoothPVars = fieldnames(smoothP);
    for i = 1:numel(userVar)
        if any(strcmp(userVar{i},smoothPVars))
            smoothP.(userVar{i}) = smoothPInput.(userVar{i});
        end
    end
end
% delete input
clear smoothPInput

% remove the points less than given x minima
remTheseXBins = logical(double(SR.xbinc<plotP.PosDataMinX)+...
    double(SR.xbinc>(max(SR.xbinc)-plotP.PosDataDMaxX)));
SR.h2d(:,remTheseXBins) = [];
SR.xbinc(remTheseXBins) = [];
% SR.mind(:,remTheseXBins) = [];

remTheseXBins = logical(double(SR.xbinc<plotP.PosPDFMinX)+...
    double(SR.xbinc>(max(SR.xbinc)-plotP.PosPDFDMaxX)));
if plotP.PosPDFMinXExc2D
    SR.h2d(:,remTheseXBins) = [];
    SR.xbinc(remTheseXBins) = [];
    %     SR.mind(:,remTheseXBins) = [];
end

h2d = SR.h2d;


if smoothP.arena
    if strcmp(smoothP.method,'box')
        h2da = smooth2a(h2d,smoothP.filterSize);
    elseif strcmp(smoothP.method,'gauss')
        h2da = imgaussfilt(h2d,smoothP.filterSize);
    else
        error('invalid smooth method')
    end
else
    h2da = h2d;
end
% normalize
h2da = h2da/sum(h2da(:));

if smoothP.profile
    if strcmp(smoothP.method,'box')
        h2dp = smooth2a(h2d,smoothP.filterSize);
    elseif strcmp(smoothP.method,'gauss')
        h2dp = imgaussfilt(h2d,smoothP.filterSize);
    else
        error('invalid smooth method')
    end
else
    h2dp = h2d;
end

% remove profile points less than minx
h2dp(:,remTheseXBins) = nan;
% normalize
h2dp = h2dp/nansum(h2dp(:));

if plotP.PlotProfile
    sp=pnlprf_h;
    sp.pack({20 80}, {85 15});
    sp.de.margin = 0;
    sp(2,1).select();
    imp = imagesc(sp(2,1).axis,SR.xbinc,SR.ybinc,h2da,[0 plotP.cthr]);
    if ~plotP.PosPDFMinXExc2D
        % set exluded data to different shade
        imp.AlphaData = double(isnan(h2dp)).*plotP.PosPDFExc2DAlphaVal+double(~isnan(h2dp));
    end
    
    
    % % following could be used if two colormaps is neede on the same figure
    % ax2 = axes;
    % scatter(ax2,randn(1,120),randn(1,120),50,randn(1,120),'filled')
    % %%Link them together
    % linkaxes([ax1,ax2])
    % %%Hide the top axes
    % ax2.Visible = 'off';
    % ax2.XTick = [];
    % ax2.YTick = [];
    % %%Give each one its own colormap
    % colormap(ax1,'hot')
    % colormap(ax2,'cool')
    % %%Then add colorbars and get everything lined up
    % set([ax1,ax2],'Position',[.17 .11 .685 .815]);
    % cb1 = colorbar(ax1,'Position',[.05 .11 .0675 .815]);
    % cb2 = colorbar(ax2,'Position',[.88 .11 .0675 .815]);
    %
    
    
    axis image
    set(sp(2,1).axis,'XTick',[],'YTick',[])
    % ylabel('mm')
    set(sp(2,1).axis,'YDir','reverse')
    set(sp(2,1).axis,'Box','on')
    set(sp(2,1).axis,'LineWidth',plotP.AxisLineWidth)
    colormap(sp(2,1).axis,buildcmap(plotP.clrmap));
    
    
    % xprofile
    sp(1,1).select();
    plot(SR.xbinc,nansum(h2dp,1),'Color',plotP.linecolor,'LineWidth',plotP.lineWidth)
    % set(gca,'YDir','reverse')
    set(sp(1,1).axis, 'XLim', get(sp(2,1).axis, 'XLim'));
    set(sp(1,1).axis,'LineWidth',plotP.AxisLineWidth)
    % set(gca,'XAxisLocation','top')
    set(gca,'XTick',[],'YColor',plotP.linecolor,'XColor',plotP.linecolor,'Color','none','YScale',plotP.scale)
    ylim([0,plotP.xprfylim])
    
    % yprofile
    sp(2,2).select();
    plot(nansum(h2dp,2),SR.ybinc,'Color',plotP.linecolor,'LineWidth',plotP.lineWidth)
    set(sp(2,2).axis, 'YLim', get(sp(2,1).axis, 'YLim'));
    set(sp(2,2).axis,'LineWidth',plotP.AxisLineWidth)
    set(gca,'YDir','reverse')
    set(gca,'YTick',[],'YColor',plotP.linecolor,'XColor',plotP.linecolor,'Color','none','XScale',plotP.scale)
    % set(gca,'XAxisLocation','top')
    xlim([0,plotP.yprfxlim])
end
switch nargout
    case 0
    case 1
        h2dArena = h2da;
    case 2
        h2dArena = h2da;
        h2dProfile = h2dp;
end



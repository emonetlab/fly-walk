function varargout = plotData2Circle(Data,tpre,tpost,option,innerc,outerc,exts,textc,precolor,postcolor,sbarprop,plotprop)
switch nargin
    case 12
        
    case 11
        plotprop = [];
    case 10
        plotprop = [];
        sbarprop = [];
    case 9
        plotprop = [];
        sbarprop = [];
        postcolor = 'k';
    case 8
        plotprop = [];
        sbarprop = [];
        postcolor = 'k';
        precolor = 'g';
    case 7
        plotprop = [];
        sbarprop = [];
        postcolor = 'k';
        precolor = 'g';
        textc = 1;
    case 6
        plotprop = [];
        sbarprop = [];
        postcolor = 'k';
        precolor = 'g';
        textc = 1;
        exts = 1; % enlargement factor for external space
    case 5
        plotprop = [];
        sbarprop = [];
        postcolor = 'k';
        precolor = 'g';
        textc = 1;
        exts = 1; % enlargement factor for external space
        outerc = 1; % enlargement factor for outer circle
    case 4
        plotprop = [];
        sbarprop = [];
        postcolor = 'k';
        precolor = 'g';
        textc = 1;
        exts = 1; % enlargement factor for external space
        outerc = 1; % enlargement factor for outer circle
        innerc = 1; % enlargement factor for inner circle
    case 3
        plotprop = [];
        sbarprop = [];
        postcolor = 'k';
        precolor = 'g';
        textc = 1;
        exts = 1; % enlargement factor for external space
        outerc = 1; % enlargement factor for outer circle
        innerc = 1; % enlargement factor for inner circle
        option = 2; % plot mean track
end

if isempty(sbarprop) % use zeros as default
    % scalebar properties
    sbarprop.xoff = 0; % xoffset for the scale bar
    sbarprop.yoff = 0; % yoffset for the scale bar
    sbarprop.text_xoff = 0; % xoffset for the scale bar text raltive to the bar
    sbarprop.text_yoff = 0; % yoffset for the scale bar text raltive to the bar
    sbarprop.lenfac = 1; % scale bar multiplication factor for the bar, increases the length
end

if isempty(plotprop) % use zeros as default
    % some plotting properties
    plotprop.shown = 0;          % n numbers per bin
    plotprop.maxn = 'all';       % max individual plot for each bin, plotting all of them clutters the plot
    plotprop.xoffn = 0;          % xoffset for printing n
    plotprop.yoffn = -3;         % yoffset for printing n
    plotprop.colorn = 'b';       % color for printing n
    plotprop.roffn = 1.1;        % roffset for printing n
    plotprop.fontsizen = 9;      % font size for n
    plotprop.showencs = 0;      % show encounters as red dots on the tracks or average track
    plotprop.encdotsize = 3;      % red dot size
    plotprop.enclinestyle = '.r';   % line stye
    plotprop.skipbin = 0;       % do not skip any bins
    plotprop.linestyle = '-';
    plotprop.ShowOnlyTheseEncs = 'all'; % no individual track requested, applies to individuals only
end

if ~isfield(plotprop,'linestyle')
    plotprop.linestyle = '-'; % set default line style
end
if ~isfield(plotprop,'ShowOnlyTheseEncs')
    plotprop.ShowOnlyTheseEncs = 'all'; % no individual track requested
end

% figure out the bin numbers and track numbers of the requested tracks
if isnumeric(plotprop.ShowOnlyTheseEncs)
    srchmat = zeros(sum([Data.ntrj]),3);
    inds = 1;
    for i = 1:numel(Data)
        inde = inds + Data(i).ntrj - 1;
        srchmat(inds:inde,1) = i;
        srchmat(inds:inde,2) = (1:Data(i).ntrj)';
        srchmat(inds:inde,3) = Data(i).index;
        inds = inde + 1;
    end
    
    
    % find the bin and track numbers
    if iscolumn(plotprop.ShowOnlyTheseEncs)
        plotprop.ShowOnlyTheseEncs = (plotprop.ShowOnlyTheseEncs)';
    end
    ShowTheseBins = srchmat(logical(sum(srchmat(:,3)==(plotprop.ShowOnlyTheseEncs),2)),1);
    ShowTheseTracks = srchmat(logical(sum(srchmat(:,3)==(plotprop.ShowOnlyTheseEncs),2)),2);
    
end





% option: 1: tracks, 2;mean, 3:tracks+mean

% determine plot indexes
tpreind = find(Data(1).time>=-tpre,1);
tpostind = find(Data(1).time>=tpost,1);

% do not smooth any track for now
smooth_len = 1;


if option==1 % plot individual tracks
    % figure out the circle size
    trjrad = 0;
    pretrjrad = 0;
    for i = 1:numel(Data)
        pretrjrad = max(trjrad,abs(min(mean(Data(i).x(:,tpreind:tpostind)-Data(i).xc,1))));
        trjrad = max(pretrjrad,abs(max(mean(Data(i).x(:,tpreind:tpostind)-Data(i).xc,1))));
    end
    cirradm = .6*pretrjrad*innerc; % mm radius of the circle inner circle
    radoffset = 1.2*trjrad*outerc; % outer circle
    anglst = mod((0:45:315)+180,360); %linspace(0,360,nofangpnt);
    %       anglst = [180 225 270 315 0 45 90 135 ]
    radtextoffsetx = [.5   1  -3  -5 -6 -5 -3 1].*textc;
    radtextoffsety = [0    2   4   5  0 -5 -3 -2]*textc;
    coor_fac = 4*exts;
    plot([-coor_fac*cirradm coor_fac*cirradm],[0 0],[0 0],[-coor_fac*cirradm coor_fac*cirradm],'LineStyle', 'none' )
    viscircles([0,0],cirradm,'LineStyle','--');
    viscircles([0,0],cirradm+radoffset,'EdgeColor','k','LineStyle','-.','LineWidth',.1);
    axis image
    axis tight
    hold on
    alind = 1;
    
    % black guide lines
    for i = anglst
        textxmbin = (cirradm+radoffset)*cosd(i-180);
        textymbin = (cirradm+radoffset)*sind(i-180);
        plot([0 textxmbin],[0 textymbin],'-.k','LineWidth',.1)
%         text((cirradm+radoffset)*cosd(i-180)+radtextoffsetx(alind),(cirradm+radoffset)*sind(i-180)+radtextoffsety(alind),[num2str(i),'^o'])
        text((cirradm+radoffset)*cosd(i-180)+radtextoffsetx(alind),(cirradm+radoffset)*sind(i-180)+radtextoffsety(alind),[num2str(i),'\circ'])
        alind = alind + 1;
    end
    
    % scale line with text
    xmbin = fix(cirradm*cosd(0)/5)*5*sbarprop.lenfac ;
    if xmbin==0
        xmbin = 5;
    end
    sbxlo = (cirradm+radoffset)*cosd(270)+radtextoffsetx(8)+3.5+sbarprop.xoff;
    sbylo = (cirradm+radoffset)*sind(270)+radtextoffsety(8)-.8+sbarprop.yoff;
    plot([sbxlo,sbxlo+xmbin],[sbylo,sbylo],'k','LineWidth',3)
    text(sbxlo+xmbin/2-1.3+sbarprop.text_xoff,sbylo+.8+sbarprop.text_yoff,[num2str(xmbin),' mm'],'FontName','Courier','FontSize',12,'FontWeight','bold')
    
    
    for i = 1:(plotprop.skipbin+1):numel(Data)
        xmbin = cirradm*cosd(Data(i).angle);
        ymbin = cirradm*sind(Data(i).angle);
        plot(xmbin,ymbin,'or','MarkerSize',4)
        zerind = find(Data(i).time==0);
        
        % plot individual tracks
        if strcmp(plotprop.maxn,'all')
            if strcmp(plotprop.ShowOnlyTheseEncs ,'all')
                for tn = 1:Data(i).ntrj % plot trajectory
                    plot(smooth(Data(i).x(tn,tpreind:zerind)-Data(i).xc(tn),smooth_len)+xmbin,smooth(Data(i).y(tn,tpreind:zerind)-Data(i).yc(tn),smooth_len)+ymbin,precolor,'LineStyle',plotprop.linestyle) % pre contact with green
                    plot(smooth(Data(i).x(tn,zerind:tpostind)-Data(i).xc(tn),smooth_len)+xmbin,smooth(Data(i).y(tn,zerind:tpostind)-Data(i).yc(tn),smooth_len)+ymbin,postcolor,'LineStyle',plotprop.linestyle) % post contact with black
                end
            else
                if any(i==ShowTheseBins)
                    swthsenc = find(i==ShowTheseBins);
                    for stind = 1:length(swthsenc)
                        it = ShowTheseBins(swthsenc(stind));
                        tn = ShowTheseTracks(swthsenc(stind));
                        plot(smooth(Data(it).x(tn,tpreind:zerind)-Data(i).xc(tn),smooth_len)+xmbin,smooth(Data(it).y(tn,tpreind:zerind)-Data(it).yc(tn),smooth_len)+ymbin,precolor,'LineStyle',plotprop.linestyle) % pre contact with green
                        plot(smooth(Data(it).x(tn,zerind:tpostind)-Data(i).xc(tn),smooth_len)+xmbin,smooth(Data(it).y(tn,zerind:tpostind)-Data(it).yc(tn),smooth_len)+ymbin,postcolor,'LineStyle',plotprop.linestyle) % post contact with black
                    end
                end
            end
        elseif isnumeric(plotprop.maxn)
            if strcmp(plotprop.ShowOnlyTheseEncs ,'all')
                if plotprop.maxn>Data(i).ntrj
                    maxn = Data(i).ntrj;
                else
                    maxn = plotprop.maxn;
                end
                % randomly sample from data
                randomtracks = datasample(1:Data(i).ntrj,maxn,'Replace',false);
                for tn = randomtracks % plot trajectory
                    plot(smooth(Data(i).x(tn,tpreind:zerind)-Data(i).xc(tn),smooth_len)+xmbin,smooth(Data(i).y(tn,tpreind:zerind)-Data(i).yc(tn),smooth_len)+ymbin,precolor,'LineStyle',plotprop.linestyle) % pre contact with green
                    plot(smooth(Data(i).x(tn,zerind:tpostind)-Data(i).xc(tn),smooth_len)+xmbin,smooth(Data(i).y(tn,zerind:tpostind)-Data(i).yc(tn),smooth_len)+ymbin,postcolor,'LineStyle',plotprop.linestyle) % post contact with black
                    % show contact with red dots if requested
                    if plotprop.showencs
                        %                     encpnts = Data(i).encon(tn,:)>0;
                        %                     encpnts(1:zerind) = false;
                        %                     encpnts(tpostind:end) = false;
                        trackxi = smooth(Data(i).x(tn,:)-Data(i).xc(tn)+xmbin,smooth_len);
                        trackyi = smooth(Data(i).y(tn,:)-Data(i).yc(tn)+ymbin,smooth_len);
                        %                     plot(trackxi(encpnts),trackyi(encpnts),plotprop.enclinestyle,'MarkerSize',plotprop.encdotsize)
                        [~,locs] = findpeaks(Data(i).encon(tn,:));
                        locs(locs<tpreind) = [];
                        locs(locs>tpostind) = [];
                        plot(trackxi(locs),trackyi(locs),plotprop.enclinestyle,'MarkerSize',plotprop.encdotsize)
                    end
                end
            else
                if any(i==ShowTheseBins)
                    swthsenc = find(i==ShowTheseBins);
                    for stind = 1:length(swthsenc)
                        it = ShowTheseBins(swthsenc(stind));
                        tn = ShowTheseTracks(swthsenc(stind));
                        plot(smooth(Data(it).x(tn,tpreind:zerind)-Data(i).xc(tn),smooth_len)+xmbin,smooth(Data(it).y(tn,tpreind:zerind)-Data(it).yc(tn),smooth_len)+ymbin,precolor,'LineStyle',plotprop.linestyle) % pre contact with green
                        plot(smooth(Data(it).x(tn,zerind:tpostind)-Data(i).xc(tn),smooth_len)+xmbin,smooth(Data(it).y(tn,zerind:tpostind)-Data(it).yc(tn),smooth_len)+ymbin,postcolor,'LineStyle',plotprop.linestyle) % post contact with black
                    end
                end
            end
        end
        
        set(gca, 'XTick', [], 'YTick', []);
        
        % print n numbers if requested
        if plotprop.shown
            textxmbin = cirradm*cosd(Data(i).angle)*plotprop.roffn;
            textymbin = cirradm*sind(Data(i).angle)*plotprop.roffn;
            text(textxmbin+plotprop.xoffn,textymbin+plotprop.yoffn,['n: ',num2str(Data(i).ntrj)],'Color',plotprop.colorn,'FontSize',plotprop.fontsizen) % print
        end
    end
    
elseif option==2 % plot mean track
    % figure out the circle size
    trjrad = 0;
    pretrjrad = 0;
    for i = 1:numel(Data)
        if Data(i).ntrj~=0
            pretrjrad = max(trjrad,abs(min(mean(Data(i).x(:,tpreind:tpostind)-Data(i).xc,1))));
            trjrad = max(pretrjrad,abs(max(mean(Data(i).x(:,tpreind:tpostind)-Data(i).xc,1))));
        end
    end
    cirradm = .6*pretrjrad*innerc; % mm radius of the circle inner circle
    radoffset = 1.2*trjrad*outerc; % outer circle
    anglst = mod((0:45:315)+180,360); %linspace(0,360,nofangpnt);
    %       anglst = [180 225 270 315 0 45 90 135 ]
    radtextoffsetx = [.5   1  -3  -5 -6 -5 -3 1].*textc;
    radtextoffsety = [0    2   4   5  0 -5 -3 -2]*textc;
    coor_fac = 4*exts;
    plot([-coor_fac*cirradm coor_fac*cirradm],[0 0],[0 0],[-coor_fac*cirradm coor_fac*cirradm],'LineStyle', 'none' )
    viscircles([0,0],cirradm,'LineStyle','--');
    viscircles([0,0],cirradm+radoffset,'EdgeColor','k','LineStyle','-.','LineWidth',.1);
    axis image
    axis tight
    hold on
    ax = gca;
    ax.XColor = 'none';
    ax.YColor = 'none';
    alind = 1;
    for i = anglst
        textxmbin = (cirradm+radoffset)*cosd(i-180);
        textymbin = (cirradm+radoffset)*sind(i-180);
        plot([0 textxmbin],[0 textymbin],'-.k','LineWidth',.1)
%         text((cirradm+radoffset)*cosd(i-180)+radtextoffsetx(alind),(cirradm+radoffset)*sind(i-180)+radtextoffsety(alind),[num2str(i),'^o'])
        text((cirradm+radoffset)*cosd(i-180)+radtextoffsetx(alind),(cirradm+radoffset)*sind(i-180)+radtextoffsety(alind),[num2str(i),'\circ'])
        alind = alind + 1;
    end
    
    
    % scale line with text
    xmbin = ceil(cirradm*cosd(0)/5)*5*sbarprop.lenfac ;
    if xmbin==0
        xmbin = 5;
    end
    sbxlo = (cirradm+radoffset)*cosd(270)+radtextoffsetx(8)+3.5+sbarprop.xoff;
    sbylo = (cirradm+radoffset)*sind(270)+radtextoffsety(8)-.8+sbarprop.yoff;
    plot([sbxlo,sbxlo+xmbin],[sbylo,sbylo],'k','LineWidth',3)
    text(sbxlo+xmbin/2-1.3+sbarprop.text_xoff,sbylo+.8+sbarprop.text_yoff,[num2str(xmbin),' mm'],'FontName','Courier','FontSize',12,'FontWeight','bold')
    
    
    
    for i = 1:(plotprop.skipbin+1):numel(Data)
        xmbin = cirradm*cosd(Data(i).angle);
        ymbin = cirradm*sind(Data(i).angle);
        plot(xmbin,ymbin,'or','MarkerSize',4)
        zerind = find(Data(i).time==0);
        if Data(i).ntrj~=0
            % pre cont green
            plot(nanmean(Data(i).x(:,tpreind:zerind)-Data(i).xc,1)+xmbin,nanmean(Data(i).y(:,tpreind:zerind)-Data(i).yc,1)+ymbin,precolor)
            % post cont black
            plot(nanmean(Data(i).x(:,zerind:tpostind)-Data(i).xc,1)+xmbin,nanmean(Data(i).y(:,zerind:tpostind)-Data(i).yc,1)+ymbin,postcolor)
            % show contact with red dots if requested
            if plotprop.showencs
                %                 encpnts = nanmean(Data(i).encon,1)>0;
                %                 encpnts(1:zerind) = false;
                %                 encpnts(tpostind:end) = false;
                trackxi = smooth(nanmean(Data(i).x-Data(i).xc,1)+xmbin,smooth_len);
                trackyi = smooth(nanmean(Data(i).y-Data(i).yc,1)+ymbin,smooth_len);
                [~,locs] = findpeaks(nanmean(Data(i).encon,1));
                locs(locs<tpreind) = [];
                locs(locs>tpostind) = [];
                plot(trackxi(locs),trackyi(locs),plotprop.enclinestyle,'MarkerSize',plotprop.encdotsize)
            end
        end
        set(gca, 'XTick', [], 'YTick', []);
        % print n numbers if requested
        if plotprop.shown
            textxmbin = cirradm*cosd(Data(i).angle)*plotprop.roffn;
            textymbin = cirradm*sind(Data(i).angle)*plotprop.roffn;
            %             text(textxmbin+plotprop.xoffn,textymbin+plotprop.yoffn,['n: ',num2str(Data(i).ntrj)],'Color',plotprop.colorn,'FontSize',plotprop.fontsizen) % print
            text(textxmbin+plotprop.xoffn,textymbin+plotprop.yoffn,num2str(Data(i).ntrj),'Color',plotprop.colorn,'FontSize',plotprop.fontsizen) % print
        end
    end
elseif option==4 % the dot product between the wind speed and the orientation vector
    % is an axis provided
    if ~isfield(plotprop.dotProd,'parentax')
        plrax_parent = gcf;
        pax = polaraxes(plrax_parent);
    else
        pax = polaraxes;
        pax.Position = plotprop.dotProd.parentax.Position;
    end
    
    % figure out the circle size
    
    theta = [Data.angle]/180*pi-pi;
    theta(end+1) = theta(1);
    hold on
    
    % creat the -1 and 1 lines
    thetagrid = linspace(0,2*pi,72);
    rgup = ones(size(thetagrid))*-1;
    rgdown = ones(size(thetagrid));
    if isfield(plotprop.dotProd,'timePoints')
        tpointlist = plotprop.dotProd.timePoints;
    else
        error('Please provide the time points as like: plotprop.dotProd.timePoints = [0,1,2];')
    end
    time = Data(1).time;
    if ~isfield(plotprop.dotProd,'Grid')
        UpWindColor = 'm';
        DownWindColor = 'b';
        UpWindLineStyle = '--';
        DownWindLineStyle = '--';
    else
        UpWindColor = plotprop.dotProd.Grid.UpWindColor;
        DownWindColor =  plotprop.dotProd.Grid.DownWindColor;
        UpWindLineStyle = plotprop.dotProd.Grid.UpWindLineStyle;
        DownWindLineStyle =  plotprop.dotProd.Grid.DownWindLineStyle;
    end
    if ~isfield(plotprop.dotProd,'Rlim')
        RlimMat = [-1.3 1]; % r limit
    else
        RlimMat =  plotprop.dotProd.Rlim;
    end
    
    polarplot(thetagrid,-rgup,[UpWindColor,UpWindLineStyle]);
    polarplot(thetagrid,-rgdown,[DownWindColor,DownWindLineStyle]);
    polarplot(thetagrid,zeros(size(thetagrid)),'--k','Linewidth',3);
    if ~isfield(plotprop.dotProd,'clrs')
        clrs = {'g','r','k','b','c','m'};
    else
        clrs = plotprop.dotProd.clrs;
    end
    if ~isfield(plotprop.dotProd,'lnstyls')
        lnstyls = {'-','-','-','-','-','-'};
    else
        lnstyls = plotprop.dotProd.lnstyls;
    end
    if ~isfield(plotprop.dotProd,'markers')
        markers = {'o','o','o','o','o','o'};
    else
        markers = plotprop.dotProd.markers;
    end
    pph = [];
    pph(length(tpointlist)).h = [];
    
    lgtxt = cell(size(tpointlist));
    
    for tpind = 1:length(tpointlist)
        
        tpoint = find(time>=tpointlist(tpind),1);
        lgtxt(tpind) = {[num2str(tpointlist(tpind),'%5.1f'),' s']};
        
        rho = zeros(size(Data));
        stdrho = zeros(size(Data));
        for i = 1:numel(Data)
            thisdotprod = Data(i).ThetaDotPhi(:,tpoint);
            thisdotprod(isnan(thisdotprod)) = [];
            rho(i) = -nanmean(thisdotprod);
            stdrho(i) = nanstd(thisdotprod)/sqrt(length(thisdotprod));
        end
        rho(end+1) = rho(1);
        stdrho(end+1) = stdrho(1);
        
        pph(tpind).h = polarplot(theta,rho,[markers{tpind},clrs{tpind},lnstyls{tpind}]);
        
        % plot the error bars
        for ni = 1 : numel(Data)
            polarplot(theta(ni)*ones(1,3),[rho(ni)-stdrho(ni), rho(ni), rho(ni)+stdrho(ni)],['-',clrs{tpind}]);
        end
        
    end
    
    pax.ThetaDir = 'counterclockwise';
    pax.FontSize = 15;
    pax.FontWeight = 'normal';
    pax.ThetaTick = [0 45 90 135 180 225 270 315];
    ttlab = {'0';'45';'90';'135';'180';'225';'270';'315'};
    pax.ThetaTickLabel = strcat(ttlab,'\circ');
    pax.ThetaZeroLocation = 'left';
    rticks([-1 0 1])
    clrsmatch = {'g','r','k','b','c','m'};
    gclrs = {'green','red','black','blue','cyan','magenta'};
    rticklabels([{['{\color{',gclrs{strcmp(clrsmatch,DownWindColor)},'}DownWind}']},{'CrossWind'},['{\color{',gclrs{strcmp(clrsmatch,UpWindColor)},'}UpWind}']])
    rlim(RlimMat)
    lgh = legend([pph.h],lgtxt,'Location','northeast');
    %     pax.RDir = 'reverse';
    
    if nargout==1
        varargout = pax;
    elseif nargout==2
        varargout{1} = pax;
        varargout{2} = lgh;
    end
    
end
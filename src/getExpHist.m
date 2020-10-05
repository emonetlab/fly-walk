function m = getExpHist(m,binsize,xyind)
%getExpHist
% m = getExpHist(m,binsize,xyind)
% provide a structure which contains the expmat with the following headers
% and it will return the structure with additional fields of 2d histogram
% 2d index mtrix and x-y bin centers
%
% this code assumes an experimental giant matrix with these headers
% TableHeaders = {trj-1 exp_ind-2 trial_ind-3 trj_ind-4 t-5 x-6 y-7 vx-8 vy-9,...
%                 spd-10 theta-11 a-12 b-13 area-14 signal-15 dtheta-16,...
%                 frnnum-17 waldir-18 dwaldir-19 fps-20 mm_per_px-21 sx-22 sy-23,...
%                 nofflies-24 fileindex-25};
% UPDATE: 6/20/19: no longer requires this header order. if the structure m
% contains column or col the code figures out the corect column numbers for
% x,y,sx and sy
%
%   Usage:
%   m = getExpHist(m), will generate 2D histogram of m.expmat for 1 mm bin
%   size, and assume column numbers for x,y,xcenter, and ycenter as [6,7,22,23]
%
%   m = getExpHist(m,10), will generate 2D histogram of m.expmat for 10 mm bin
%   size, and assume column numbers for x,y,xcenter, and ycenter as [6,7,22,23]
%
%   m = getExpHist(m,5,[1,2]), will generate 2D histogram of m.expmat for 5 mm bin
%   size, and assume column numbers for x,y [1,2]. will not ofset
%
%   m = getExpHist(m,5,[1,2,10,11]), will generate 2D histogram of m.expmat for 5 mm bin
%   size, and assume column numbers for x,y,xcenter, and ycenter as [6,7,10,11]
%
%   now accepts actual bins rather than a binsize. Usage can such:
%
%   m = getExpHist(m,[1,5]), will generate 2D histogram of m.expmat for 1
%   mm bisize in x, and 5 mm binsize for y dimensions.
%
%   m = getExpHist(m,edges), will generate 2D histogram of
%   m.expmat with edges.xedges and edges.yedges


switch nargin
    case 2
        xyind = [6,7,22,23];
    case 1
        xyind = [6,7,22,23];
        binsize = 1;
end

% is col or column present
if isfield(m,'col')
    col = m.col;
    if isfield(m.col,'sx')&&isfield(m.col,'sy')
        x = m.expmat(:,col.x)-m.expmat(:,col.sx); % offset by the source location
        y = m.expmat(:,col.y)-m.expmat(:,col.sy); % offset by the source location
    else
        x = m.expmat(:,col.x); % offset by the source location
        y = m.expmat(:,col.y); % offset by the source location
    end
elseif isfield(m,'column')
    % get the column outputs to sturcture inputs
    for i = 1:numel(m.column)
        col.(m.column{i}) = i;
    end
    x = m.expmat(:,col.x)-m.expmat(:,col.sx); % offset by the source location
    y = m.expmat(:,col.y)-m.expmat(:,col.sy); % offset by the source location
else
    if length(xyind)==4
        x = m.expmat(:,xyind(1))-m.expmat(:,xyind(3)); % offset by the source location
        y = m.expmat(:,xyind(2))-m.expmat(:,xyind(4)); % offset by the source location
    elseif length(xyind)==2
        x = m.expmat(:,xyind(1)); % do not offset by the source location
        y = m.expmat(:,xyind(2)); % do not offset by the source location
    else
        eror('define xy indexes and reference point as well')
    end
end


% is binsize or edges given
if isstruct(binsize)
    xedges = binsize.xedges;
    yedges = binsize.yedges;
else
    if sum(size(binsize))==2
        % single bin size requested
        xedges = (floor(min(x)):binsize:ceil(max(x)));
        % check uniformity
        if xedges(end)<ceil(max(x))
            xedges = [xedges,xedges(end)+binsize];
        end
        yedges = (floor(min(y)):binsize:ceil(max(y)));
        %check uniformity
        if yedges(end)<ceil(max(y))
            yedges = [yedges,yedges(end)+binsize];
        end
    elseif sum(size(binsize))==3
        % different bin sizes for x and y
        xedges = (floor(min(x)):binsize(1):ceil(max(x)));
        % check uniformity
        if xedges(end)<ceil(max(x))
            xedges = [xedges,xedges(end)+binsize(1)];
        end
        yedges = (floor(min(y)):binsize(2):ceil(max(y)));
        %check uniformity
        if yedges(end)<ceil(max(y))
            yedges = [yedges,yedges(end)+binsize(2)];
        end
    end
end
sxe = circshift(xedges,-1);
sye = circshift(yedges,-1);
m.xbinc = (xedges(1:end-1) + sxe(1:end-1))/2;
m.ybinc = (yedges(1:end-1) + sye(1:end-1))/2;
[m.h2d,m.mind] = hist2d(x,y,xedges,yedges);
function [FlyCount,Time] = CountFlyinTime(expmat,radius,col,tstep)
%CountFlyinTime
% CountFlyinTime(expmat) returns FlyCount and Time vectors which contains
% the number of flies at the source within 10 mm radious as a function of
% time with time step of 1 sec.
% trajectories who reach to the radious (default 10mm) away from the source
% are identified and the instant whne they reach the border is set as zero
% time. The time and path backwards are calculated and registered to
% columns 27 (time to source) 28 (time spent in the circle), and 29 (path
% integral)
% if the trajectory doe snot reach to the source then a NaN is assigned
% this code assumes an experimental giant matrix with these headers
% TableHeaders = {trj-1 exp_ind-2 trial_ind-3 trj_ind-4 t-5 x-6 y-7 vx-8 vy-9,...
%                 spd-10 theta-11 a-12 b-13 area-14 signal-15 dtheta-16,...
%                 frnnum-17 waldir-18 dwaldir-19 fps-20 mm_per_px-21 sx-22 sy-23,...
%                 nofflies-24 fileindex-25};
% Now appends new columns to the expmat and return the column numbers and
% headers in structure ColumnOut

% set default radius
switch nargin
    case 3
        tstep = 1;  % sec
    case 2
        tstep = 1;  % sec
        col = [];
    case 1
        tstep = 1;  % sec
        col = [];
        radius = 10; % mm
end

if isempty(col)
    col.t = 5;
    col.x = 6;
    col.sx = 22;
    col.y = 7;
    col.sy = 23;
end
% get time vector
Time = floor(min(expmat(:,col.t))):tstep:ceil(max(expmat(:,col.t)));
FlyCount = zeros(size(Time));

% what is column end index

% calculate the r for each fly
col.r = size(expmat,2)+1;
expmat(:,col.r) = sqrt((expmat(:,col.x)-expmat(:,col.sx)).^2+(expmat(:,col.y)-expmat(:,col.sy)).^2);

% go over time bisn and count
for tind = 1:length(Time)
    tp = Time(tind);
    % get only this time
    tpp = tp+tstep/2;
    tpm = tp-tstep/2;
    tem = expmat(expmat(:,col.t)<tpp,:);
    tem = tem(tem(:,col.t)>tpm,:);
    
    % find indexes that fall in that circle
    tem = tem(tem(:,col.r)<=radius,:);  % only that part of the data
    
    % count tracks adn register as flies
    FlyCount(tind) = numel(unique(tem(:,1)));
end
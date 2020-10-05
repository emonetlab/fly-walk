function [o2d,r2d,osx2d,osy2d] = orient2dtrj(expmat,mind,colnum,TrjAll,normalize,cutoff)
%orient2dtrj
% orient2dtrj(expmat,mind) returns the 2d matrix which contains the mean 
% orientation of the particles defined in index matrix mind. The
% orientation of each trajectory is averaged first then all mean orientaton
% of the trajectories were averaged later. In order to get mean orientation
% in a given bin units vectors of the gven orientation values were summed
% and then normalized by the number of the trajectories
%
% expmat: experimental giant matrix. see below
% mind: 2d index matrix
% colnum: the column value for the average. it will assumed as radian
% TrjAll: string to select all or tracks
% normalize: to normalize the sum of the vectors
% cutoff: value cut off
%
% o2d: 2d matrix containing the mean orientation
% r2d: the strength of the orientation average
% osx2d: sum of x values of the unit vectors, 2d matrix
% osy2d: sum of y values of the unit vectors, 2d matrix
%
% this code assumes an experimental giant matrix with these headers
% TableHeaders = {trj-1 exp_ind-2 trial_ind-3 trj_ind-4 t-5 x-6 y-7 vx-8 vy-9,...
%                 spd-10 theta-11 a-12 b-13 area-14 signal-15 dtheta-16,...
%                 frnnum-17 waldir-18 dwaldir-19 fps-20 mm_per_px-21 sx-22 sy-23,...
%                 nofflies-24 fileindex-25};


switch nargin
    case 5
        cutoff = 'NA';  % use all values
    case 4
        cutoff = 'NA';  % use all values
        normalize = 1;  % normalize the summed unit vectors
    case 3
        cutoff = 'NA';  % use all values
        normalize = 1;  % normalize the summed unit vectors
        TrjAll = 'Trj'; % average trajectories and then average
    case 2
        cutoff = 'NA';  % use all values
        normalize = 1;  % normalize the summed unit vectors
        TrjAll = 'Trj'; % average trajectories and then average
        colnum = 11;    % default column of interest is orientation
end

o2d = zeros(size(mind));  % initialize o2d
r2d = zeros(size(mind));  % initialize o2d
osx2d = zeros(size(mind));
osy2d = zeros(size(mind));
var = expmat(:,colnum);

if strcmp(TrjAll,'All') % do not consider trajectories, just average all
    % loop over mind and get averages
    for i = 1:length(mind(:))
        if isempty(mind{i})
            o2d(i) = NaN;
        else
            vart = var(mind{i});
            % remove Nans
            vart(isnan(vart))=[];
            if isnumeric(cutoff)
                vart = vart(vart>=cutoff);
            end
            if ~isempty(vart)
                [xc,yc]=pol2cart(vart,ones(size(vart)));
                if normalize
                    osx2d(i) = mean(xc);
                    osy2d(i) = mean(yc);
                else
                    osx2d(i) = sum(xc);
                    osy2d(i) = sum(yc);
                end                    
                [o2d(i),r2d(i)] = cart2pol(osx2d(i),osy2d(i));
            end
        end
    end
elseif strcmp(TrjAll,'Trj') % average over trajectories first and then average
    % loop over mind and get averages
    for i = 1:length(mind(:))
        if isempty(mind{i})
            o2d(i) = NaN;
        else
            indl = mind{i}; % get index list
            indl(:,2) = expmat(indl,1); % get corresponding trajectory numbers
            trjnums = unique(indl(:,2)); % unique track numbers
            cnt = 0;
            % go over track numbers and average
            for tn = trjnums'
                vart = var(indl(indl(:,2)==tn,1));
                % remove Nans
                vart(isnan(vart))=[];
                if isnumeric(cutoff)
                    if vart<=cutoff
                        vart = [];
                    end
                end
                [xc,yc]=pol2cart(vart,ones(size(vart)));
                osx2dt = mean(xc);
                osy2dt = mean(yc);                   
                if ~isempty(vart)
                    osx2d(i) = osx2d(i) + osx2dt;
                    osy2d(i) = osy2d(i) + osy2dt;
                    cnt = cnt + 1;
                end
            end
         
            if cnt==0
                o2d(i) = NaN;
            else
                if normalize
                    osx2d(i) = osx2d(i)/cnt;
                    osy2d(i) = osy2d(i)/cnt;
                end                    
                [o2d(i),r2d(i)] = cart2pol(osx2d(i),osy2d(i));
            end
        end
    end
else 
    error('TrjAll is not recognized')
end
function m2d = median2dtrj(expmat,mind,colnum,TrjAll,cutoff)
% median averages the variable given as colnum in the 2D matrix expmat
% if there are no indexes in any element of mind a NaN will be assigned
% Trajectories whose average is less than cutoff will not be included 
% in the average. in each bin first, trajectory average will be calculated
% than all trajectories will be averaged.
%
% this code assumes an experimental giant matrix with these headers
% TableHeaders = {trj-1 exp_ind-2 trial_ind-3 trj_ind-4 t-5 x-6 y-7 vx-8 vy-9,...
%                 spd-10 theta-11 a-12 b-13 area-14 signal-15 dtheta-16,...
%                 frnnum-17 waldir-18 dwaldir-19 fps-20 mm_per_px-21 sx-22 sy-23,...
%                 nofflies-24 fileindex-25};


switch nargin
    case 4
        cutoff = 'NA';  % use all values
    case 3
        cutoff = 'NA';  % use all values
        TrjAll = 'Trj'; % average trajectories and then average
    case 2
        cutoff = 'NA';  % use all values
        TrjAll = 'Trj'; % average trajectories and then average
        colnum = 10;    % default column of interest is speed
end

m2d = zeros(size(mind));  % initialize m2d
var = expmat(:,colnum);

if strcmp(TrjAll,'All') % do not consider trajectories, just average all
    % loop over mind and get averages
    for i = 1:length(mind(:))
        if isempty(mind{i})
            m2d(i) = NaN;
        else
            vart = var(mind{i});
            % remove Nans
            vart(isnan(vart))=[];
            if isnumeric(cutoff)
                vart = vart(vart>=cutoff);
            end
            if ~isempty(vart)
                m2d(i) = median(vart);
            end
        end
    end
elseif strcmp(TrjAll,'Trj') % average over trajectories first and then average
    % loop over mind and get averages
    for i = 1:length(mind(:))
        if isempty(mind{i})
            m2d(i) = NaN;
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
                vart = median(vart); % calculate the median for this track
                if isnumeric(cutoff)
                    if vart<=cutoff
                        vart = [];
                    end
                end
                if ~isempty(vart)
                    m2d(i) = m2d(i) + vart;
                    cnt = cnt + 1;
                end
            end
            if cnt==0
                m2d(i) = NaN;
            else
                m2d(i) = m2d(i)/cnt;
            end
        end
    end
else 
    error('TrjAll is not recognized')
end
function meanCount = getMeanCountInBoxExpMat(em,cntbox,TableHeaders,options)

if nargin < 4
    % get all calculations out
    options.vial = 1;
    options.trial = 1;
    options.bs = 1;
end


% get the density profile integrated around the ribbon with error bars
% calculated for vials, trials, and boothstrapped for trajectories

% define variable columns
vialcol = find(strcmp(TableHeaders,'exp_ind'));     % unique vial number
if isempty(vialcol)
    vialcol = find(strcmp(TableHeaders,'vialNum'));     % unique vial number
end
trialcol = find(strcmp(TableHeaders,'fileindex'));  % unique trial index
xcol = find(strcmp(TableHeaders,'x'));              % x position in the arena
ycol = find(strcmp(TableHeaders,'y'));              % y position in the arena
sxcol = find(strcmp(TableHeaders,'sx'));            % x position in the arena
sycol = find(strcmp(TableHeaders,'sy'));            % y position in the arena

% % define count box limits
% cntbox = [-30 300 -30 30]; % count box boundaries: [xmin xmax ymin ymax], around the source

if isfield(options,'vial')
    if options.vial
        % do the average for the vials
        vialnums = unique(em(:,vialcol));
        vialcount = zeros(length(vialnums),2);
        for i = 1:length(vialnums)
            % get the part of the expmat for this vial
            emt = em(em(:,vialcol)==vialnums(i),:);
            % register the number of points
            vialcount(i,:) = CountFliesInBox(emt,cntbox,xcol,ycol,sxcol,sycol);
        end
        meanCount.vialcount = vialcount;
        meanCount.vialcount(:,3) = meanCount.vialcount(:,1)./meanCount.vialcount(:,2);
        meanCount.vialRatio = [nanmean(meanCount.vialcount(:,3)),nanstd(meanCount.vialcount(:,3)),nanstd(meanCount.vialcount(:,3))/sqrt(length(vialnums))]; % mean, std, sem
    end
end

% do the average for the trials
if isfield(options,'trial')
    if options.trial
        trialnums = unique(em(:,trialcol));
        trialcount = zeros(length(trialnums),2);
        for i = 1:length(trialnums)
            % get the part of the expmat for this vial
            emt = em(em(:,trialcol)==trialnums(i),:);
            % register the number of points
            trialcount(i,:) = CountFliesInBox(emt,cntbox,xcol,ycol,sxcol,sycol);
        end
        meanCount.trialcount = trialcount;
        meanCount.trialcount(:,3) = meanCount.trialcount(:,1)./meanCount.trialcount(:,2);
        meanCount.trialRatio = [nanmean(meanCount.trialcount(:,3)),nanstd(meanCount.trialcount(:,3)),nanstd(meanCount.trialcount(:,3))/sqrt(length(trialnums))];
    end
end


if isfield(options,'bs')
    if options.bs
        boothsn = 10;
        em1 = [em,(1:size(em,1))'];
        stats = bootstrp(boothsn,@(emt) CountFliesInBoxBootStrap(emt,cntbox,xcol,ycol,sxcol,sycol),em1);
        boothstrpcount = stats;
        meanCount.boothstrpcount = boothstrpcount;
        
        % get ratios
        meanCount.boothstrpcount(:,5) = meanCount.boothstrpcount(:,1)./meanCount.boothstrpcount(:,2);
        meanCount.boothstrpcount(:,6) = meanCount.boothstrpcount(:,3)./meanCount.boothstrpcount(:,4);
        
        % get mean and std deviations
        meanCount.bstrpRatioRep = [nanmean(meanCount.boothstrpcount(:,5)),nanstd(meanCount.boothstrpcount(:,5)),nanstd(meanCount.boothstrpcount(:,5))/sqrt(boothsn)];
        meanCount.bstrpRatioNRep = [nanmean(meanCount.boothstrpcount(:,6)),nanstd(meanCount.boothstrpcount(:,6)),nanstd(meanCount.boothstrpcount(:,6))/sqrt(boothsn)];
    end
end
end

function count = CountFliesInBox(emt,cntbox,xcol,ycol,sxcol,sycol)
tot = size(emt,1);
% eliminate points out of the box
emt((emt(:,xcol)-emt(:,sxcol))<cntbox(1),:) = [];
emt((emt(:,xcol)-emt(:,sxcol))>cntbox(2),:) = [];
emt((emt(:,ycol)-emt(:,sycol))<cntbox(3),:) = [];
emt((emt(:,ycol)-emt(:,sycol))>cntbox(4),:) = [];
count = [size(emt,1),tot];

end

function count = CountFliesInBoxBootStrap(emt,cntbox,xcol,ycol,sxcol,sycol)
ems = emt;
tot = size(emt,1);
% eliminate points out of the box
emt((emt(:,xcol)-emt(:,sxcol))<cntbox(1),:) = [];
emt((emt(:,xcol)-emt(:,sxcol))>cntbox(2),:) = [];
emt((emt(:,ycol)-emt(:,sycol))<cntbox(3),:) = [];
emt((emt(:,ycol)-emt(:,sycol))>cntbox(4),:) = [];
count = [size(emt,1),tot];
% do the same thing without replacement
emt = ems(unique(ems(:,end)),:);
tot = size(emt,1);
% eliminate points out of the box
emt((emt(:,xcol)-emt(:,sxcol))<cntbox(1),:) = [];
emt((emt(:,xcol)-emt(:,sxcol))>cntbox(2),:) = [];
emt((emt(:,ycol)-emt(:,sycol))<cntbox(3),:) = [];
emt((emt(:,ycol)-emt(:,sycol))>cntbox(4),:) = [];
count = [count,size(emt,1),tot];
end




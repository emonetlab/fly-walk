%setConstraint2DataAngleBin
% puts constraints to the encounter angle binned data
%
function DataAngleBin = setConstraint2DataAngleBin(DataAngleBin,constraints)

% constraint structure must have these field
% constraints.xlim = [50,NaN];    % [xmin, xmax] for encounters, NaN to disregard
% constraints.ylim = [-20,20];    % [ymin, ymax] for encounters, NaN to disregard
% constraints.centerPass = 1;     % 1: enforce center line pass, 0: ignore condition
% constraints.arriveSource = 1;   % 1: Remove tracks that did not reach source, 0: ignore condition
% constraints.sourceRadius = 20;  % mm, condition for source arrival

% get the input structure fields
datafields = fieldnames(DataAngleBin);

% if encounter binned DataAngleBin is entered loop it and recall the function
if (numel(datafields)==1)&&(strcmp(datafields,'Data'))
    for fldnum = 1:numel(DataAngleBin)
        datatemp = DataAngleBin(fldnum).Data;
        datatemp = setConstraint2DataAngleBin(datatemp,constraints);
        DataAngleBin(fldnum).Data = datatemp;
    end
    
else % data with all encounters is entered
    % parse the constraint structure
    fnames = fieldnames(constraints);
    
    % remove some fields
    datafields(strcmp(datafields,{'ntrj'})) = [];
    datafields(strcmp(datafields,{'angle'})) = [];
    datafields(strcmp(datafields,{'time'})) = [];
    % for now focus on xlim
    if ismember('xlim',fnames)
        xlim = constraints.xlim;
        % min x limit
        if ~isnan(xlim(1)) % set the limit
            % go over all encounters and eliminate the ones with x position less than this
            DataAngleBin = applyLimit(DataAngleBin,'xc',xlim(1),'min',datafields);
        end
        % max x limit
        if ~isnan(xlim(2)) % set the limit
            % go over all encounters and eliminate the ones with x position less than this
            DataAngleBin = applyLimit(DataAngleBin,'xc',xlim(2),'max',datafields);
        end
    else
        disp('xlim constraints are not defined. Passing...')
    end
    
    % set the y lim
    if ismember('ylim',fnames)
        ylim = constraints.ylim;
        % min x limit
        if ~isnan(ylim(1)) % set the limit
            % go over all encounters and eliminate the ones with x position less than this
            DataAngleBin = applyLimit(DataAngleBin,'yc',ylim(1),'min',datafields);
        end
        % max x limit
        if ~isnan(ylim(2)) % set the limit
            % go over all encounters and eliminate the ones with x position less than this
            DataAngleBin = applyLimit(DataAngleBin,'yc',ylim(2),'max',datafields);
        end
    else
        disp('ylim constraints are not defined. Passing...')
    end
    
    % set center pass constraint
    % if a fly does not pass through the center line (the line dividing the
    % arena in to two halves at y= source) then that will be eliminated
    
    % set source arrival constraint
    if constraints.arriveSource
        % calculate the distance of each point to the source
        for i = 1:numel(DataAngleBin)
            status = false(DataAngleBin(i).ntrj,1);  % delete status
            for j = 1:DataAngleBin(i).ntrj
                sy = DataAngleBin(i).sy(j);
                sx = DataAngleBin(i).sx(j);
                distvec = sqrt((DataAngleBin(i).x(j,:)-sx).^2+(DataAngleBin(i).y(j,:)-sy).^2);
                % if any of these distance less than radius then this trac reached
                % to the source
                if ~any(distvec<constraints.sourceRadius)
                    status(j) = true;
                    disp(['Angle:',num2str(DataAngleBin(i).angle),' track:',num2str(j),' did not reach to the source. Eliminating...'])
                end
            end
            % remove the encounters that meet the condition
            if DataAngleBin(i).ntrj>0
                for fnum = 1:numel(datafields)
                    DataAngleBin(i).(datafields{fnum})(status,:) = [];
                end
                % reduce the track number
                DataAngleBin(i).ntrj = DataAngleBin(i).ntrj - sum(status);
            end
        end
    end
    
    
    % remove very short tracks before and after the encounter
    if constraints.pruneTracks
        
        minlb = constraints.tlenPre;    % sec
        minla = constraints.tlenPost;   % sec
        
        for i = 1:numel(DataAngleBin)
            if DataAngleBin(i).ntrj==0
                continue
            end
            
            ti0 = find(DataAngleBin(i).time==0);
            tib = find(DataAngleBin(i).time>-minlb,1)-1;
            tia = find(DataAngleBin(i).time>minla,1);
            status = false(DataAngleBin(i).ntrj,1);  % delete status
            status(isnan(DataAngleBin(i).x(:,tib))) = true;
            status(isnan(DataAngleBin(i).x(:,tia))) = true;
            if sum(status)>0
                disp(['Angle:',num2str(DataAngleBin(i).angle),' tracks:',mat2str(find(status)'),' are shorter than limits. Eliminating...'])
                if DataAngleBin(i).ntrj>0
                    for fnum = 1:numel(datafields)
                        DataAngleBin(i).(datafields{fnum})(status,:) = [];
                    end
                    % reduce the track number
                    DataAngleBin(i).ntrj = DataAngleBin(i).ntrj - sum(status);
                end
            end
            DataAngleBin(i).trklensb = sum(~isnan(DataAngleBin(i).x(:,1:ti0)),2);
            DataAngleBin(i).trklensa = sum(~isnan(DataAngleBin(i).x(:,ti0:end)),2);
            DataAngleBin(i).trksemx = (nanstd(DataAngleBin(i).x,1))./sqrt(sum(~isnan(DataAngleBin(i).x),1));
            DataAngleBin(i).trksemy = (nanstd(DataAngleBin(i).y,1))./sqrt(sum(~isnan(DataAngleBin(i).y),1));
        end
        
    end
    
    % remove slow tracks
    if constraints.remSlowTraks
        
        minlb = constraints.remSlowTraksPreT;    % sec
        minla = constraints.remSlowTraksPostT;   % sec
        
        for i = 1:numel(DataAngleBin)
            if DataAngleBin(i).ntrj==0
                continue
            end
            
            ti0 = find(DataAngleBin(i).time==0);
            tib = find(DataAngleBin(i).time>-minlb,1)-1;
            tia = find(DataAngleBin(i).time>minla,1);
            status = false(DataAngleBin(i).ntrj,1);  % delete status
            status(mean(DataAngleBin(i).spd(:,tib:tia),2)<=constraints.minTrackSpeed) = true;
            
            if sum(status)>0
                disp(['Angle:',num2str(DataAngleBin(i).angle),' tracks:',mat2str(find(status)'),' are slower than limits. Eliminating...'])
                if DataAngleBin(i).ntrj>0
                    for fnum = 1:numel(datafields)
                        DataAngleBin(i).(datafields{fnum})(status,:) = [];
                    end
                    % reduce the track number
                    DataAngleBin(i).ntrj = DataAngleBin(i).ntrj - sum(status);
                end
            end
            DataAngleBin(i).trklensb = sum(~isnan(DataAngleBin(i).x(:,1:ti0)),2);
            DataAngleBin(i).trklensa = sum(~isnan(DataAngleBin(i).x(:,ti0:end)),2);
            DataAngleBin(i).trksemx = (nanstd(DataAngleBin(i).x,1))./sqrt(sum(~isnan(DataAngleBin(i).x),1));
            DataAngleBin(i).trksemy = (nanstd(DataAngleBin(i).y,1))./sqrt(sum(~isnan(DataAngleBin(i).y),1));
        end
        
    end
    
    if constraints.centerPass
        minlb = constraints.centerPassPreT ;    % sec
        minla = constraints.centerPassPostT;   % sec
        for i = 1:numel(DataAngleBin)
            
            
            
            if DataAngleBin(i).ntrj==0
                continue
            end
            
            
            tib = find(DataAngleBin(i).time>-minlb,1)-1;
            tia = find(DataAngleBin(i).time>minla,1);
            status = false(DataAngleBin(i).ntrj,1);  % delete status
            
            
            for j = 1:DataAngleBin(i).ntrj
                % interpolate and check the intersection
                if isnan(minlb) && isnan(minla)
                    xtemp = DataAngleBin(i).x(j,:);
                    ytemp = DataAngleBin(i).y(j,:);
                    ytempr = DataAngleBin(i).y(j,:);
                    % remove nans
                    xtemp(isnan(DataAngleBin(i).x(j,:))) = [];
                    ytemp(isnan(DataAngleBin(i).x(j,:))) = [];
                    ytempr(isnan(DataAngleBin(i).x(j,:))) = [];
                elseif ~isnan(minlb) && isnan(minla)
                    xtemp = DataAngleBin(i).x(j,tib:end);
                    ytemp = DataAngleBin(i).y(j,tib:end);
                    ytempr = DataAngleBin(i).y(j,tib:end);
                    % remove nans
                    xtemp(isnan(DataAngleBin(i).x(j,tib:end))) = [];
                    ytemp(isnan(DataAngleBin(i).x(j,tib:end))) = [];
                    ytempr(isnan(DataAngleBin(i).x(j,tib:end))) = [];
                elseif isnan(minlb) && ~isnan(minla)
                    xtemp = DataAngleBin(i).x(j,1:tia);
                    ytemp = DataAngleBin(i).y(j,1:tia);
                    ytempr = DataAngleBin(i).y(j,1:tia);
                    % remove nans
                    xtemp(isnan(DataAngleBin(i).x(j,1:tia))) = [];
                    ytemp(isnan(DataAngleBin(i).x(j,1:tia))) = [];
                    ytempr(isnan(DataAngleBin(i).x(j,1:tia))) = [];
                elseif ~isnan(minlb) && ~isnan(minla)
                    xtemp = DataAngleBin(i).x(j,tib:tia);
                    ytemp = DataAngleBin(i).y(j,tib:tia);
                    ytempr = DataAngleBin(i).y(j,tib:tia);
                    % remove nans
                    xtemp(isnan(DataAngleBin(i).x(j,tib:tia))) = [];
                    ytemp(isnan(DataAngleBin(i).x(j,tib:tia))) = [];
                    ytempr(isnan(DataAngleBin(i).x(j,tib:tia))) = [];
                end
                
                
                if ~isempty(xtemp)
                    xtemp(isnan(ytempr)) = [];
                    ytemp(isnan(ytempr)) = [];
                    if ~isempty(xtemp)
                        % matlab interp1 requires unique inputs , lets get
                        % only unique inputs
                        [ytemp, index] = unique(ytemp);
                        xtemp = xtemp(index);
                        [xtemp, index] = unique(xtemp);
                        ytemp = ytemp(index);
                        % remove single point vectors
                        if length(xtemp)<2 || length(ytemp)<2
                            status(j) = true;
                            disp(['Angle:',num2str(DataAngleBin(i).angle),' track:',num2str(j),' has a single point in the Center pass limits eliminating...'])
                        else
                        if isnan(interp1(ytemp,xtemp,DataAngleBin(i).sy(j),'linear',NaN))
                            status(j) = true;
                            disp(['Angle:',num2str(DataAngleBin(i).angle),' track:',num2str(j),' did not pass the center line. Eliminating...'])
                        end
                        end
                    else
                        status(j) = true;
                    end
                else
                    status(j) = true;
                end
            end
            % remove the encounters that meet the condition
            if DataAngleBin(i).ntrj>0
                for fnum = 1:numel(datafields)
                    DataAngleBin(i).(datafields{fnum})(status,:) = [];
                end
                % reduce the track number
                DataAngleBin(i).ntrj = DataAngleBin(i).ntrj - sum(status);
            end
        end
    end
    
    
    
    
    % remove interactions
    if isfield(constraints,'remInteract')
        if isnan(constraints.remInteract)
            
            for j = 1:DataAngleBin(i).ntrj
                DataAngleBin(i).x(~isnan(DataAngleBin(i).coll(:,j)),j) = nan;
                DataAngleBin(i).y(~isnan(DataAngleBin(i).coll(:,j)),j) = nan;
                DataAngleBin(i).x(~isnan(DataAngleBin(i).opass(:,j)),j) = nan;
                DataAngleBin(i).y(~isnan(DataAngleBin(i).opass(:,j)),j) = nan;
            end
            
            
        elseif constraints.remInteract
            
            % if analyze time range given then focus on that part
            if isfield(constraints,'tlenPre')
                minlb = constraints.tlenPre;    % sec
            else
                minlb = Inf;
            end
            if isfield(constraints,'tlenPost')
                minla = constraints.tlenPost;    % sec
            else
                minla = Inf;
            end
            
            % time vector should be same for all
            tib = find(DataAngleBin(1).time>-minlb,1)-1;
            tia = find(DataAngleBin(1).time>minla,1);
            
            for i = 1:numel(DataAngleBin)
                if DataAngleBin(i).ntrj==0
                    continue
                end
                
                status = false(DataAngleBin(i).ntrj,1);  % delete status
                status(sum(~isnan(DataAngleBin(i).coll(:,tib:tia)),2)>0) = true;
                status(sum(~isnan(DataAngleBin(i).opass(:,tib:tia)),2)>0) = true;
                if sum(status)>0
                    disp(['Angle:',num2str(DataAngleBin(i).angle),' tracks:',mat2str(find(status)'),' are in interaction. Eliminating...'])
                    if DataAngleBin(i).ntrj>0
                        for fnum = 1:numel(datafields)
                            if size(DataAngleBin(i).(datafields{fnum}),1)==length(status)
                                DataAngleBin(i).(datafields{fnum})(status,:) = [];
                            end
                        end
                        % reduce the track number
                        DataAngleBin(i).ntrj = DataAngleBin(i).ntrj - sum(status);
                    end
                end
            end
            
        end
    end
    
    % remove very short tracks before and after the encounter
    if isfield(constraints,'remJump')
        
        if isnan(constraints.remJump)
            
            for j = 1:DataAngleBin(i).ntrj
                DataAngleBin(i).x(DataAngleBin(i).jump(:,j)>0,j) = nan;
                DataAngleBin(i).y(DataAngleBin(i).jump(:,j)>0,j) = nan;
                
            end
        elseif constraints.remJump
            
            % if analyze time range given then focus on that part
            if isfield(constraints,'tlenPre')
                minlb = constraints.tlenPre;    % sec
            else
                minlb = Inf;
            end
            if isfield(constraints,'tlenPost')
                minla = constraints.tlenPost;    % sec
            else
                minla = Inf;
            end
            
            % time vector should be same for all
            tib = find(DataAngleBin(1).time>-minlb,1)-1;
            tia = find(DataAngleBin(1).time>minla,1);
            
            for i = 1:numel(DataAngleBin)
                if DataAngleBin(i).ntrj==0
                    continue
                end
                status = false(DataAngleBin(i).ntrj,1);  % delete status
                status(sum(DataAngleBin(i).jump(:,tib:tia)>0,2)>0) = true;
                if sum(status)>0
                    disp(['Angle:',num2str(DataAngleBin(i).angle),' tracks:',mat2str(find(status)'),' are jumping. Eliminating...'])
                    if DataAngleBin(i).ntrj>0
                        for fnum = 1:numel(datafields)
                            if size(DataAngleBin(i).(datafields{fnum}),1)==length(status)
                                DataAngleBin(i).(datafields{fnum})(status,:) = [];
                            end
                        end
                        % reduce the track number
                        DataAngleBin(i).ntrj = DataAngleBin(i).ntrj - sum(status);
                    end
                end
            end
            
        end
    end
    
end

end

function DataAngleBin = applyLimit(DataAngleBin,fieldname,limit,limittype,datafields)
% apply the limit to data
% fieldname: fieldname in DataAngleBin to be processed
% limit: value to be applied
% limittype: min/max

for i = 1:numel(DataAngleBin)
    status = false(DataAngleBin(i).ntrj,1);  % delete status
    if strcmp(fieldname,'xc')
        sourceLoc = 'sx';
    elseif strcmp(fieldname,'yc')
        sourceLoc = 'sy';
    else
        error('undefined position limit request')
    end
    for j = 1:DataAngleBin(i).ntrj
        if strcmp(limittype,'min')           
            if (DataAngleBin(i).(fieldname)(j)-DataAngleBin(i).(sourceLoc)(j))<limit
                status(j) = true;
                disp(['Angle:',num2str(DataAngleBin(i).angle),' track:',num2str(j),' does not meet ',fieldname,' ',limittype,' criteria. Eliminating...'])
            end
        elseif strcmp(limittype,'max')
            if (DataAngleBin(i).(fieldname)(j)-DataAngleBin(i).(sourceLoc)(j))>limit
                status(j) = true;
                disp(['Angle:',num2str(DataAngleBin(i).angle),' track:',num2str(j),' does not meet ',fieldname,' ',limittype,' criteria. Eliminating...'])
            end
        else
            error('define correct limittype min/max')
        end
    end
    % remove the encounters that meet the condition
    if DataAngleBin(i).ntrj>0
        for fnum = 1:numel(datafields)
            DataAngleBin(i).(datafields{fnum})(status,:) = [];
        end
        % reduce the track number
        DataAngleBin(i).ntrj = DataAngleBin(i).ntrj - sum(status);
    end
end

end


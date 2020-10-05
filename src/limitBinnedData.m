% puts constraint to angle binned data
% usage:
% create constraint structure
% const.xlim = 20; % eliminates the encounters whose x positions is les
% than xlim
% call the function data = limitBinnedData(data,const)
% Works for both angle binned data and encounter sorted angle binned data
function data = limitBinnedData(data,const)

% get the input structure fields
datafields = fieldnames(data);

% if encounter binned data is entered loop it and recall the function
if (numel(datafields)==1)&&(strcmp(datafields,'Data'))
    for fldnum = 1:numel(data)
        datatemp = data(fldnum).Data;
        datatemp = limitBinnedData(datatemp,const);
        data(fldnum).Data = datatemp;
    end
    
else % data with all encounters is entered
    % parse the constraint structure
    fnames = fieldnames(const);
    
    % remove some fields
    datafields(strcmp(datafields,{'ntrj'})) = [];
    datafields(strcmp(datafields,{'angle'})) = [];
    datafields(strcmp(datafields,{'time'})) = [];
    % for now focus on xlim
    if ismember('xlim',fnames)
        xlim = const.xlim;
        % go over all encounters and eliminate the ones with x position less than this
        for i = 1:numel(data)
            status = false(data(i).ntrj,1);  % delete status
            for j = 1:data(i).ntrj
                if data(i).xc(j)<xlim
                    status(j) = true;
                end
            end
            % remove the encounters that meet the condition
            if data(i).ntrj>0
                for fnum = 1:numel(datafields)
                    data(i).(datafields{fnum})(status,:) = [];
                end
                % reduce the track number
                data(i).ntrj = data(i).ntrj - sum(status);
            end
        end
    else
        error('xlim constraints is not defined')
    end
    
end

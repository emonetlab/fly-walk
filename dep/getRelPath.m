function relpath = getRelPath(pathstr,pathorigin)
% returns the path string relative to the pathorigin (default current
% working directory, pwd). pathstr can be a cell array or a single
% character string
%



if nargin ==1
    pathorigin = pwd;
end

% is a cell array of paths or a single path given
if iscell(pathstr)
    relpath = cell(size(pathstr)); % initiate output cell array
else
    pathstr ={pathstr};
    relpath = cell(size(pathstr));
end

if strcmp(pathorigin(end),filesep)
    pathorigin = pathorigin(1:end-1);
end

% current dir list
cdirl = strsplit(pathorigin,filesep);

for k = 1:length(pathstr)
    pathstr_temp = pathstr{k};
    % get rid of the filesep at the end
    if strcmp(pathstr_temp(end),filesep)
        pathstr_temp = pathstr_temp(1:end-1);
    end

    % given dir list
    gdirl = strsplit(pathstr_temp,filesep);
    
    % if the file is in another disk do not attemp to get the rel path,
    % just return the original path
    if ~strcmp(cdirl{1},gdirl{1})
        if (~isempty(relpath))&&(isdir(pathstr_temp))
            pathstr_temp = [pathstr_temp,filesep];
        end
        relpath(k) = {pathstr_temp};
        continue;
    end

    % go over the pathorigin and stop where the closest match is
    ind = numel(cdirl);
    iter = 0;
    giter = 1;
    relpath_temp = [];
    if ~strcmp(pathstr_temp,pathorigin)
        while (isempty(relpath_temp))&&(ind>0)&&(giter<100)
            if ~isempty(find(ismember(gdirl,cdirl(ind)), 1))
                % contract prestring
                prestr = [];
                for i = 1:iter
                    prestr = [prestr,'..',filesep];
                end
                relpath_temp = [prestr,strjoin(gdirl(find(ismember(gdirl,cdirl(ind)))+1:end),filesep)];
            else
                iter = iter + 1;
                ind = ind - 1;
            end
            giter = giter + 1;
        end

        if giter>=100
            disp('After 100 iterations the match is not found. Check your path definitions')
        end
    end
    if (~isempty(relpath))&&(isdir(relpath_temp))
        relpath_temp = [relpath_temp,filesep];
    end
    relpath(k) = {relpath_temp};
end

if ~iscell(pathstr)
    relpath = char(relpath);
end
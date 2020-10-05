function fullpath = getFullPath(pathstr)
% returns the full path string pathstr can be a cell array or a single
% character string. The code needs to be run in the origin directory where
% relative path string originates
%
pathstrSave = pathstr;
% is a cell array of paths or a single path given
if iscell(pathstr)
    fullpath = cell(size(pathstr)); % initiate output cell array
else
    pathstr ={pathstr};
    fullpath = cell(size(pathstr));
end


for k = 1:length(pathstr)
    fp = dir(pathstr{k});
    if isempty(fp)
        % try directory search
        fnpieces = strsplit(pathstr{k},filesep);
        dirsearch = dir(fullfile('F:','**',fnpieces{end}));
        if isempty(dirsearch)
            disp([pathstr{k}, ' is not found in F:'])
            continue
        else
            % if there are more than two locations get the one with the
            % correct subfolder
            if numel(dirsearch)>1
                correctFolder = false(size(dirsearch));
                for dsind = 1:numel(dirsearch)
                    thisFolPeaces = strsplit(dirsearch(dsind).folder,filesep);
                    if strcmp(thisFolPeaces{end}(1:10),dirsearch(dsind).name(1:10))
                        correctFolder(dsind) = true;
                    end
                end
                % is there only one correct folder
                if sum(correctFolder)==1
                    corrFolderInd = find(correctFolder);
                else
                    disp('there are more than two relevant folders containing this file')
                    disp('did not code for this')
                    keyboard
                end
            else
                corrFolderInd = 1;
            end
           fullpath(k) = {[dirsearch(corrFolderInd).folder,filesep,dirsearch(corrFolderInd).name]};
        end  
    else
        fullpath(k) = {[fp.folder,filesep,fp.name]};
    end
end

if ~iscell(pathstrSave)
    fullpath = char(fullpath);
end
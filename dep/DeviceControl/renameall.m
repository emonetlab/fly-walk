function [] = renameall(oldname,newname)
    % first check if newname is empty
    if ~isempty(newname)
        [paths,fno,~] = fileparts(oldname);
        [~,fnn,~] = fileparts(newname);
        % find all associated files in the folder
        if isempty(paths)
            pfn = [];
        else
            pfn = [paths,filesep];
        end
        fs = dir([pfn,['*',fno,'*']]);
        fsn = {fs.name}';
        for fi = 1: numel(fsn)
            % get new file name
            newfn = regexprep(fsn{fi},fno,fnn);
            if ~exist([pfn,newfn],'file')
                % replace movifile if that is a mat file and if that field
                % exist
                [~,mn,fe]  = fileparts([pfn,newfn]);
                if strcmp(fe,'.mat')
                    if ~isempty(who('moviefile','-file',[pfn,fsn{fi}]))
                        mf = load([pfn,fsn{fi}],'moviefile');
                        moviefile = mf.moviefile;
                        [~,~,me]  = fileparts(moviefile);
                        moviefile = [mn,me];
                        save([pfn,fsn{fi}],'moviefile','-append')
                    end
                end
                movefile([pfn,fsn{fi}],[pfn,newfn]);
                    
            else
                disp(['trying to move "',[pfn,fsn{fi}],'" to "',[pfn,newfn],'".'])
                error('file exist. resolve the conflict first')
            end
        end
    end
 end
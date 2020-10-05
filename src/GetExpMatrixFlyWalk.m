function [expmat,properties] = GetExpMatrixFlyWalk(pathname,nflies,ntrjs,savestr,skipSizeDeter)

% pulls the data from files and puts them in a giant matrix whose headers
% are given as TableHeaders

switch nargin
    case 4
        skipSizeDeter = 1;
    case 3
        skipSizeDeter = 1;
        savestr = [];
    case 2
        skipSizeDeter = 1;
        ntrjs = 'all'; % get all tracks
        savestr = [];
    case 1
        skipSizeDeter = 1;
        savestr = [];
        ntrjs = 'all'; % get all tracks
        nflies = 'all'; % get all tracks
    case 0
        skipSizeDeter = 1;
        savestr = [];
        ntrjs = 'all'; % get all tracks
        nflies = 'all'; % get all tracks
        pathname = pwd;
end

            
% first figure out if a directory or a filelist is given
% and put create fileNames
if iscell(pathname) % a cell is given. that can be either cell array 
                    % of files or folders
    % now check if all elements are same type (folder or not)
    if exist(pathname{1},'dir')
        for i = 1:numel(pathname)
            if ~exist(pathname{i},'dir')
                error([pathname{i},' is not a directory or path does not exist'])
            end
        end
        % now all of these are directories. get all the paths in these
        % folders
        fileNames = {};
        % get all mat files
        for i = 1:numel(pathname)
            % try to load experiment file names
            if exist([pathname{i},filesep,'expmat.names.mat'],'file')
                load([pathname{i},filesep,'expmat.names.mat']);
                fileNamest = pathlist;
            elseif exist([pathname{i},filesep,'expvid.names.mat'],'file')
                load([pathname{i},filesep,'expvid.names.mat']);
                fileNamest = expvidnames;
            else % get all mat files
                filelist = dir([pathname{i},filesep,'*.flywalk']);
                fileNamest = {filelist.name}';
            end
            fileNames = [fileNames;fileNamest];
        end
    elseif strcmp(pathname{1}(end-2:end),'avi')
        % check if mat file exists
        for i = 1:numel(pathname)
            if ~exist([pathname{i}(1:end-4),'.mat'],'file')
                error([pathname{i}(1:end-4),'.mat is not a file or path does not exist'])
            end
        end
        fileNames = pathname;
    elseif strcmp(pathname{1}(end-2:end),'mat')
        if exist(pathname{1},'file')
            for i = 1:numel(pathname)
                if ~exist(pathname{i},'file')
                    error([pathname{i}, ' is not a file or path does not exist'])
                end
            end
            fileNames = pathname;
        else
            error([pathname{1},' does not exits'])
        end
    else
        error('path does not exist')
    end
                    
else % not a cell probably a single file or folder
     % first check if a folder or file
     if exist(pathname,'dir')         
        % try to load experiment file names
        if exist([pathname,filesep,'expmat.names.mat'],'file')
            load([pathname,filesep,'expmat.names.mat']);
            fileNames = pathlist;
        elseif exist([pathname,filesep,'expvid.names.mat'],'file')
            load([pathname,filesep,'expvid.names.mat']);
            fileNames = expvidnames;
        else % get all mat files
            filelist = dir([pathname,filesep,'*.flywalk']);
            fileNames = {filelist.name}';
        end
     else
         % put this filename in a cell
         fileNames = {pathname};
     end
end

% extraxt the experiment, trial and file indexes from this list
[ExpTrlId,p] = getExpTrl(fileNames); % get sortedfilenames out
% go over the list and construct the giant variable matrix
fileNames = p.fileNames;
clear p;

% what mode is requested
if (strcmp(ntrjs,'all'))&&(strcmp(nflies,'all')) % get all tracks and flies
    if ~skipSizeDeter
        % start constructing the variable matrix
        % determine the size of the matrix
        ml = 0;
        nf = 0;
        nt = 0;
        for i = 1:numel(fileNames)
            disp(['getting the size of ',fileNames{i}])
            [totlen,nof,not] = getfw2matlen(fileNames{i});
             ml =  ml + totlen;
             nf = nf + nof;
             nt = nt + not;
             disp([fileNames{i}])
             disp(['has ',num2str(nof),' flies and ',num2str(not),' tracks.'])
        end
    else
        % estimate the expected size
        % get the first file and make an estimate
        disp(['getting the size of ',fileNames{1}])
        [totlen,~,~] = getfw2matlen(fileNames{1});
        ml = totlen*3*numel(fileNames);
        disp(['Estimated total length is: ',num2str(ml)])
    end

    % create the empty matrix
    % initiate varmat, create a very large one
%     expmat  = zeros(ml,length(TableHeaders));
    initVMatColNum = 100;
    expmat  = zeros(ml,initVMatColNum);
    maxAntSegNum = nan;

    ei = 0; % end index
    ltrji = 0;
    nf = 0; % total number of flies
    nt = 0; % total number of trakcs
    for i = 1: numel(fileNames)
        disp(['Video: ',num2str(i),'/',num2str(numel(fileNames))])
        disp(['filename: ',fileNames{i}])
        [varmat,thisprop] = fw2mat(fileNames{i});
        if size(varmat,2)>initVMatColNum
            expmat(:,end+1:size(varmat,2)+4) = nan;
            expmat(:,size(varmat,2)+4) = expmat(:,initVMatColNum);
            initVMatColNum = size(varmat,2)+4;
        end
            
        si = ei + 1;
        ei = si + size(varmat,1)-1;
        expmat(si:ei,5:size(varmat,2)+4) = varmat;
        expmat(si:ei,2) = ExpTrlId(i,1);
        expmat(si:ei,3) = ExpTrlId(i,2);
        expmat(si:ei,1) = varmat(:,1)+ltrji;
        expmat(si:ei,4) = ExpTrlId(i,3);
        ltrji = varmat(end,1)+ltrji;
        disp([fileNames{i},' is appended to the giant matrix'])
        nf = nf + thisprop.nof_flies;
        nt = nt + thisprop.noftracks;
        maxAntSegNum = max(maxAntSegNum,max(varmat(:,thisprop.col.num_ant_seg)));
    end
    % remove the extra rows
    zeroind = find(expmat(:,1)==0,1,'first');
    if ~isempty(zeroind)
        expmat(zeroind:end,:) = [];
    end
elseif isnumeric(ntrjs)&& isnumeric(nflies)
    error('provide only one mode')
elseif isnumeric(ntrjs) % count tracks
    error('fix the code first in order to use it')
    if ~skipSizeDeter
        % start constructing the variable matrix
        % determine the size of the matrix
        ml = 0;
        flind = 0;
        nf = 0;
        nt = 0;
        for i = 1:numel(fileNames)
            while nt<=ntrjs
                disp(['getting the size of ',fileNames{i}])
                [totlen,nof,not] = getfw2matlen(fileNames{i});
                 ml =  ml + totlen;
                 flind = flind + 1;
                 nf = nf + nof;
                 nt = nt + not;
                 disp([fileNames{i},' has ',num2str(nof),' flies and ',num2str(not),' tracks.'])
            end
        end
    else
        % estimate the expected size
        % get the first file and make an estimate
        disp(['getting the size of ',fileNames{1}])
        [totlen,~,~] = getfw2matlen(fileNames{1});
        ml = totlen*2*numel(fileNames);
        disp(['Estimated total length is: ',num2str(ml)])
    end

    % create the empty matrix
    % initiate varmat
%     expmat  = zeros(ml,length(TableHeaders));
    expmat  = zeros(ml,100);
    maxAntSegNum = nan;
    ei = 0; % end index
    ltrji = 0;
    nf = 0; % total number of flies
    nt = 0; % total number of trakcs
    for i = 1: numel(fileNames)
        [varmat,thisprop] = fw2mat(fileNames{i});
        si = ei + 1;
        ei = si + size(varmat,1)-1;
        expmat(si:ei,4:size(varmat,2)+3) = varmat;
        expmat(si:ei,2) = ExpTrlId(i,1);
        expmat(si:ei,3) = ExpTrlId(i,2);
        expmat(si:ei,1) = varmat(:,1)+ltrji;
        expmat(si:ei,end) = ExpTrlId(i,3);
        ltrji = varmat(end,1)+ltrji;
        disp([fileNames{i},' is appended to the giant matrix'])
        nf = nf + thisprop.nof_flies;
        nt = nt + thisprop.noftracks;
        maxAntSegNum = max(maxAntSegNum,max(varmat(:,46)));
    end
    % remove the extra rows
    zeroind = find(expmat(:,1)==0,1,'first');
    if ~isempty(zeroind)
        expmat(zeroind:end,:) = [];
    end
    
elseif isnumeric(nflies) % count tracks
    error('fix the code first in order to use it')
    if ~skipSizeDeter
        % start constructing the variable matrix
        % determine the size of the matrix
        ml = 0;
        flind = 0;
        nf = 0;
        nt = 0;
        for i = 1:numel(fileNames)
            while nf<=nflies
                disp(['getting the size of ',fileNames{i}])
                [totlen,nof,not] = getfw2matlen(fileNames{i});
                 ml =  ml + totlen;
                 flind = flind + 1;
                 nf = nf + nof;
                 nt = nt + not;
                 disp([fileNames{i},' has ',num2str(nof),' flies and ',num2str(not),' tracks.'])
            end
        end
    else
        % estimate the expected size
        % get the first file and make an estimate
        disp(['getting the size of ',fileNames{1}])
        [totlen,~,~] = getfw2matlen(fileNames{1});
        ml = totlen*2*numel(fileNames);
        disp(['Estimated total length is: ',num2str(ml)])
%         nf = NaN;
%         nt = NaN;
    end

    % create the empty matrix
    % initiate varmat
%     expmat  = zeros(ml,length(TableHeaders));
    expmat  = zeros(ml,100);
    maxAntSegNum = nan;

    ei = 0; % end index
    ltrji = 0;
    nf = 0; % total number of flies
    nt = 0; % total number of trakcs
    for i = 1: numel(fileNames)
        [varmat,thisprop] = fw2mat(fileNames{i});
        si = ei + 1;
        ei = si + size(varmat,1)-1;
        expmat(si:ei,4:size(varmat,2)+3) = varmat;
        expmat(si:ei,2) = ExpTrlId(i,1);
        expmat(si:ei,3) = ExpTrlId(i,2);
        expmat(si:ei,1) = varmat(:,1)+ltrji;
        expmat(si:ei,end) = ExpTrlId(i,3);
        ltrji = varmat(end,1)+ltrji;
        nf = nf + thisprop.nof_flies;
        nt = nt + thisprop.noftracks;
        disp([fileNames{i},' is appended to the giant matrix'])
        maxAntSegNum = max(maxAntSegNum,max(varmat(:,46)));
    end
    % remove the extra rows
    zeroind = find(expmat(:,1)==0,1,'first');
    if ~isempty(zeroind)
        expmat(zeroind:end,:) = [];
    end
end

% remove extra columns
if isnan(maxAntSegNum)
    expmat = expmat(:,1:(thisprop.col.num_ant_seg+4));
else
    expmat = expmat(:,1:(thisprop.col.num_ant_seg+4+maxAntSegNum));
end

% work on the table header output. register pixel number ids for virtual
% antena
TableHeaders = thisprop.TableHeaders;
TableHeaders(5:numel(TableHeaders)+4) = TableHeaders;
TableHeaders(1) = {'trjNum'};
TableHeaders(2) = {'vialNum'};
TableHeaders(3) = {'trialNum'};
TableHeaders(4) = {'fileindex'};


if isnan(maxAntSegNum)
    TableHeaders(thisprop.col.num_ant_seg+4) = [];
else
    for asind = thisprop.col.num_ant_seg+5:(maxAntSegNum+thisprop.col.num_ant_seg+4)
        TableHeaders(asind) = {['ant_seg_',num2str(asind-(thisprop.col.num_ant_seg+4))]};
    end
end

% get the column structure
% get the column outputs to sturcture inputs
for i = 1:numel(TableHeaders)
    col.(TableHeaders{i}) = i;
end



properties.TableHeaders = TableHeaders;
properties.fileNames = fileNames;
properties.nflies = nf;
properties.ntracks = nt;
properties.ExpTrlId = ExpTrlId;
properties.col = col;

if (~isempty(savestr))&&ischar(savestr)
    save(savestr,'expmat','properties','-v7.3');
    disp(['saved to ',savestr])
end
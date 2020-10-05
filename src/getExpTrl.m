function [ExpTrlId,properties] = getExpTrl(fileNames,sortall) 
% parses the filelist and extract the experiment numbers and trial
% numbers from and assigns the file id to them which is the index of
% the filelist

switch nargin
    case 2
        if isempty(fileNames)
            % try to load experiment file names
            if exist('expmat.names.mat','file')
                load('expmat.names.mat');
                fileNames = pathlist;
            elseif exist('expvid.names.mat','file')
                load('expvid.names.mat');
                fileNames = expvidnames;
            else % get all mat files
                filelist = dir('*.mat');
                fileNames = {filelist.name}';
            end
        end
    case 1
        sortall = 0;    % ignore genotype and experiment name, just get exp # and trial
            
    case 0
        sortall = 0;    % ignore genotype and experiment name, just get exp # and trial #
        % try to load experiment file names
        if exist('expmat.names.mat','file')
            load('expmat.names.mat');
            fileNames = pathlist;
        elseif exist('expvid.names.mat','file')
            load('expvid.names.mat');
            fileNames = expvidnames;
        else % get all mat files
            filelist = dir('*.mat');
            fileNames = {filelist.name}';
        end
end

% if a single file given put it in a cell
if ~iscell(fileNames)
    fileNames = {fileNames};
end

% sort the fileNames
fileNames = sort(fileNames);

% create an empty structure for detail collection
s = repmat(struct('dgv',{},'date',{},'geno',{},'vial',{},'starve',{},'age',{},'exp',{},'trial',{}),numel(fileNames));

% go over the filenames and get details
for i = 1:numel(fileNames)
    [~,NAME,~] = fileparts(fileNames{i}); 
    sp = strsplit(NAME,'_');
    s(i).dgv = strjoin(sp(1:5),'_');
    s(i).date = strjoin(sp(1:3),'_');
    s(i).geno = sp{4};
    s(i).vial = str2double(sp{5}); % vial number on this vial
    s(i).starve = str2double(sp{6}(1:end-2)); % default days of starvation
    s(i).age = str2double(sp{7}(1:end-2)); % age of flies days
    s(i).exp = sp{8}; % experiment carried out
    s(i).trial = str2double(sp{9}(1)); % trial number on this vial
end

if sortall == 0
    % initiate the output matrix
    ExpTrlId = zeros(numel(fileNames),3); % exp id, trial id, and file id
    % ignore experimental details and just return exp # and trail #
    % find unique experiment
    explist = unique({s.dgv});
    trlist = zeros(size(explist));
    fileind = 1;
    for  i = 1:numel(explist)
        trlist(i) = length(find(strcmp({s.dgv}, explist{i})==1));
        for j = 1:trlist(i)
            ExpTrlId(fileind,1)= i;
            ExpTrlId(fileind,2)= j;
            ExpTrlId(fileind,3)= fileind;
            fileind = fileind + 1;
        end
    end
    
else
    % find unique genotype
    genolist = unique({s.geno});
    % go over the genotypes
    for gi = 1:numel(genolist)
        % find indexes corresponding to this genoype
        gind = (find(strcmp({s.geno}, genolist{gi})==1));
        % among this genotype get experiments
        explist = unique({s(gind).exp});
        % go over the experiments
        for ei = 1:numel(explist)
            expind = (find(strcmp({s(gind).exp}, explist{ei})==1));
            % register the vial and trials for this experiment
            for vti = 1:length(expind)
                ExpTrlId.(genolist{gi}).(explist{ei})(vti).date = s(gind(expind(vti))).date;
                ExpTrlId.(genolist{gi}).(explist{ei})(vti).vial = s(gind(expind(vti))).vial;
                ExpTrlId.(genolist{gi}).(explist{ei})(vti).starve = s(gind(expind(vti))).starve;
                ExpTrlId.(genolist{gi}).(explist{ei})(vti).age = s(gind(expind(vti))).age;
                ExpTrlId.(genolist{gi}).(explist{ei})(vti).trial = s(gind(expind(vti))).trial;
                ExpTrlId.(genolist{gi}).(explist{ei})(vti).flind = gind(expind(vti));
                ExpTrlId.(genolist{gi}).(explist{ei})(vti).filename = fileNames{gind(expind(vti))};
            end
        end
    end
end
properties.fileNames = fileNames;
properties.s = s;
                
          
        
        
    



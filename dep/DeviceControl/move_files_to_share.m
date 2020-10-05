% clc
% clear
filelist1 = dir('*.mat');
% filelist2 = dir('*.mj2');
filelist3 = dir('*.avi');
% filelist4 = dir('*.tif');
filelist5 = dir('*.txt');
filelist6 = dir('*.xls');
% filelist = [filelist1;filelist2;filelist3;filelist4];
filelist = [filelist1;filelist3;filelist5;filelist6];
fileNames = {filelist.name}';
NofFiles = length(filelist);
pathlist = strsplit(pwd,filesep);
cur_fldr = pathlist{end};
% c = textscan(filelist(1).date,'%s');
% date_str = datestr(c{1}{1},'yyyy_mm_dd');
% date_str = fileNames{1}(1:10);
% dest_fldr = ['Z:\mahmut_demir\Walking Assay',filesep,cur_fldr];
dest_fldr = ['Z:\home\mahmut_demir\Walking Assay',filesep,cur_fldr];
if ~exist(dest_fldr,'dir')
    mkdir(dest_fldr);
end
for i = 1:NofFiles
    if ~exist([dest_fldr,filesep,fileNames{i}],'file')
        copyfile([pwd,filesep,fileNames{i}],[dest_fldr,filesep,fileNames{i}])
        disp(['Copied ',pwd,filesep,fileNames{i},' to share'])
    else
        disp([pwd,filesep,fileNames{i},' is already in share'])
    end
end
function status = renameFlyWalk_Files(pathlist)
%renameFlyWalk_Files
% renames the flywalk files so that new data does not overwrite
% status = renameFlyWalk_Files(pathlist)
% renames and archives the files in the pathlist by adding -v001, -v002 ...
% etc version numbers

%% check if a cell array or a single path is given
if ~iscell(pathlist)
    pathlist = {pathlist};
end

status = zeros(numel(pathlist),1);

for i = 1:numel(pathlist)
    try
        if exist([pathlist{i}(1:end-4),'.flywalk'],'file')
           [~,fnmt,~] = fileparts([pathlist{i}(1:end-4),'.flywalk']);
           disp([fnmt,'.flywalk exists.']);
           % version number
           sr=dir([pathlist{i}(1:end-4),' -*.flywalk']);
           if isempty(sr)
               vn = 1;
           else               
               srn = sort({sr.name}');
               vn = str2num(srn{end}(end-10:end-8)) + 1;
           end
           fdestn = [pathlist{i}(1:end-4),' - v',num2str(vn,'%03.0f'),'.flywalk'];
           movefile([pathlist{i}(1:end-4),'.flywalk'],fdestn);
           [~,fnmt,~] = fileparts(fdestn);
           disp(['Renamed as: ',fnmt,'.flywalk']);
           status(i) = 1;
        end
        
    catch ME
        disp('error!')
        disp(ME.message);
    end  
end


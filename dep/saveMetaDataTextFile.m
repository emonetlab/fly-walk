function saveMetaDataTextFile(pathlist,saveName)
% extracts the meta data from the list of experiment files: pathlist and
% writes them as a table in the text file saveName, or in metaData.txt as
% default.
%
if nargin==1
    saveNametxt = 'metaData.txt';
    saveNameExcel = 'metaData.xls';
% elseif nargin==2
%     [~,name,~] = fileparts(saveName);
%     saveNametxt = [name,'.txt'];
%     saveNameExcel = [name,'.xls'];
end


amd = [];
MetaDataAvailable = true(size(pathlist));
for flnum = 1:numel(pathlist)
    amdthis = loadGrasshopperMetadata(pathlist{flnum});
    if isempty(amdthis)
        disp([pathlist{flnum},' will be excluded from the meta data list...'])
        MetaDataAvailable(flnum) = false;
    else
        amdthis.text = {amdthis.text};
        amd = catstruct(amd,amdthis);
    end 
    
end
T = struct2table(amd);
T.Properties.RowNames = pathlist(MetaDataAvailable);
disp('Here is the tabulated metadata.')
disp(T)

% save the metadata in to the specified file
if nargin==1
    
    writetable(T,saveNametxt,'WriteRowNames',true)
    writetable(T,saveNameExcel,'WriteRowNames',true)
    disp(['The following information saved as metadata in file ',saveNametxt,' & ',saveNameExcel])
    type(saveNametxt)

elseif nargin==2
    writetable(T,saveName,'WriteRowNames',true)
    disp(['The following information saved as metadata in file ',saveName])
    type(saveName)
end


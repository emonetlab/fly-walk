function f = annotateExpmat(DataStruct,vidNum)
% loads the the flywalk of the vidNum and starts the annotation script
f = openFileFlyWalk(DataStruct.fileNames{vidNum},1);
f.annotateFlyWalk;
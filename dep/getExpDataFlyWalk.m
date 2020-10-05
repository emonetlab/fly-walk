function data = getExpDataFlyWalk(pathlist)
%getExpDataFlyWalk
% data = getExpDataFlyWalk(pathlist)
% pulls the data from .flywalk flies listed in the pathlist, a cell array,
% and puts in a giant experimental matrix under a structure called data.
% stores the column, filenames as well. Calculates the 2D histogram and
% stores. Estiamtes the statistics and stores

[data.expmat,properties] = GetExpMatrixFlyWalk(pathlist);
data.column = properties.TableHeaders;
data.col = properties.col;
data.fileNames = properties.fileNames;
%         data.expmat = RedExpMat(data.expmat,'','',spdth,spdthmax,mintrjlen);
binsize = 1;
data = getExpHist(data,binsize);
data.binsize = binsize;
data.stats = getExpStat(data.expmat,data.col);
% check reflection measurements and assign the correct surfaces

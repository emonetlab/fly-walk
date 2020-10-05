function data = getExpDataPathFileFlyWalk(pathfile)
pthvar = load(pathfile);
assert(isfield(pthvar,'pathlist'),['pathlist does not exist in file ' ,pathfile])
data = getExpDataFlyWalk(pthvar.pathlist);
function GrasshopperMetadata = loadGrasshopperMetadata(filepath)
assert(exist([filepath(1:end-4),'.mat'],'file')==2,[filepath(1:end-4),'.mat does not exist'])
datatemp = load([filepath(1:end-4),'.mat']);

if isfield(datatemp,'metadata')
    GrasshopperMetadata = datatemp.metadata;
else
    disp([filepath,' : MetaData is not available. Will output and empty Structure.'])
    GrasshopperMetadata = [];
end

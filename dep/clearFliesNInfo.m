function f = clearFliesNInfo(f)
%clearDummyFlies
% f = clearDummyFlies(f) clears all information related to flies in the
% tracking information reagrd;es of they are dummy ior not
%

allfields = fieldnames(f.tracking_info);

% remove some fixed parameters
allfields(strcmp(allfields,'speedSmthlen')) = [];
allfields(strcmp(allfields,'angle_flip_threshold')) = [];

for i = 1:numel(allfields)
    f.tracking_info.(allfields{i}) = [];
end

% remove antenna offset parameters as well
f.antoffset = [];
f.reflection_status = [];
f.reflection_meas = [];
f.reflection_overlap = [];

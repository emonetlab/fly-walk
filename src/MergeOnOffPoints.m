function [pil,nil] = MergeOnOffPoints(pil,nil)
% merges if two interaction follows the previous one. In other words if
% ni(i) = pi(i+1)-1
if isempty(pil)
    return
end
elem = 1;
for i = 1:length(pil)-1
    if pil(elem+1) == (nil(elem)+1)
        nil(elem) = nil(elem+1);
        pil(elem+1) = [];
        nil(elem+1) = [];
    else
        elem = elem + 1;
    end
end
    
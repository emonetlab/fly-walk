function f = getRefOlap(f,thisFly,RefPxlListR,AllFlyPxlList,refOrder)
%getRefOlap
%   function f = getRefOlap(f,thisFly,RefPxlListR,AllFlyPxlList,refOrder)
%   calculates the reflection overlap of the fly thisFly using the
%   reflection pixels list structure RefPxlListR (output of getReflPxls)
%   and all pixels vector AllFlyPxlList (output of getFlyNRefMaskSigMeas(f,[]))
%   for the reflection order refOrder (default [1,2], gets overlap of the
%   all reflections).
%

switch nargin
    case 4
        refOrder = [1,2]; % get both reflection overlaps
end

% sanity check
assert(length(refOrder)<=2,'refOrder cannot be be longer than 2')
for i = 1:length(refOrder)
    assert(any(refOrder(i)==[1,2]),'refOrder cannot have a value other than 1 or 2')
end

% is the requested fly in the list
assert(any([RefPxlListR.flyNum]==thisFly),['Requested fly number is not available in ',inputname(3)])

% which flynumber if the requested one
flyInd = [RefPxlListR.flyNum]==thisFly;


% now get the reflection overlaps and assign to f.tracking_info
for k = 1:length(refOrder)
    thisRefOrder = refOrder(k);
    rt = RefPxlListR;
    if thisRefOrder==1
        thisRefPixels = rt(flyInd).ReflPxls1;
        rt(flyInd).ReflPxls1 = [];
        rpAll = [vertcat(rt.ReflPxls1);vertcat(rt.ReflPxls2)];
    else
        thisRefPixels = rt(flyInd).ReflPxls2;
        rt(flyInd).ReflPxls2 = [];
        rpAll = [vertcat(rt.ReflPxls2);vertcat(rt.ReflPxls2)];
    end
    % get unique rows
    rpAllExtThisRef = unique(rpAll,'rows');
    % get Fly and Reflection pixels except the requested one
    AllPxlList = unique([AllFlyPxlList;rpAllExtThisRef],'row');
    if thisRefOrder==1
        f.tracking_info.refOverLap1(thisFly,f.current_frame) =  size(intersect(thisRefPixels,AllPxlList,'rows'),1)/size(thisRefPixels,1);
    else
        f.tracking_info.refOverLap2(thisFly,f.current_frame) =  size(intersect(thisRefPixels,AllPxlList,'rows'),1)/size(thisRefPixels,1);
    end
end
        
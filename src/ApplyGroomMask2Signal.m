function f = ApplyGroomMask2Signal(f)
% sets values in the filtered signal that match with groom mask to zero

% generate the groom mask if not generated
if ~isfield(f.tracking_info,'groom_mak')
    f = getGroomMask(f);
end

f.tracking_info.signalm = f.tracking_info.signalm.*(~f.tracking_info.groom_mask); 
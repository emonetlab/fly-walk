function f = clearEvents(f)
% removes the signal detection fields from the tracking info 
%% remove fields
if isfield(f.tracking_info,'signal_sorted')
    f.tracking_info = rmfield(f.tracking_info,'signal_sorted');
end
if isfield(f.tracking_info,'signal_peak')
    f.tracking_info = rmfield(f.tracking_info,'signal_peak');
end
if isfield(f.tracking_info,'signal_width')
    f.tracking_info = rmfield(f.tracking_info,'signal_width');
end
if isfield(f.tracking_info,'signal_prom')
    f.tracking_info = rmfield(f.tracking_info,'signal_prom');
end
if isfield(f.tracking_info,'signal_onset')
    f.tracking_info = rmfield(f.tracking_info,'signal_onset');
end
if isfield(f.tracking_info,'signal_offset')
    f.tracking_info = rmfield(f.tracking_info,'signal_offset');
end
function f = saveSignalType(f,antenna_shape,antenna_type,orientation_method)
% saves the values of requested signal measurement method in tracking info
% Usage:
% set signal type parameters:
% orientation_method = 'M1'; (options are: 'M1','M' - default)
% measure_method = 'mean';   (options are: 'mean' - default,'median')
% antenna_type = 'fixed';    (options are: 'fixed' - default,'dynamic')
% antenna_shape = 'ellipse'; (options are: 'ellipse' - default,'circle','box')
% 
% save the values of the requested signal measurement method
% f = saveSignalType(f,antenna_shape,antenna_type,measure_method,orientation_method);
%  


f.tracking_info.(['signal_',orientation_method,'_',antenna_shape,'_',antenna_type,'_median']) = f.tracking_info.signal;
f.tracking_info.(['signal_',orientation_method,'_',antenna_shape,'_',antenna_type,'_mean']) = f.tracking_info.signal_mean;
f.tracking_info.(['antoffset_',orientation_method,'_',antenna_shape,'_',antenna_type]) = f.antoffset;
% f.antenna_shape = antenna_shape;
% f.antenna_type = antenna_type;
f.tracking_info.(['antOlap_',orientation_method,'_',antenna_shape,'_',antenna_type]) = f.tracking_info.antenna_overlap;
f.tracking_info.(['antOlap1R_',orientation_method,'_',antenna_shape,'_',antenna_type]) = f.tracking_info.antenna1R_overlap;
f.tracking_info.(['antOlap2R_',orientation_method,'_',antenna_shape,'_',antenna_type]) = f.tracking_info.antenna2R_overlap;
f.tracking_info.(['orientation_',orientation_method]) = f.tracking_info.orientation;

% be careful about the box signal
if strcmp(f.antenna_shape,'box')
    f.tracking_info.(['AntBoxSignal_',orientation_method,'_',antenna_shape,'_',antenna_type]) = f.tracking_info.AntBoxSignal;
    f.tracking_info.(['AntBoxSignalSegmentNum_',orientation_method,'_',antenna_shape,'_',antenna_type]) = f.tracking_info.AntBoxSignalSegmentNum;
    f.tracking_info.(['AntBoxSignalSlope_',orientation_method,'_',antenna_shape,'_',antenna_type]) = f.tracking_info.AntBoxSignalSlope;
end

disp(['Parameters Saved: ',orientation_method,' ',antenna_shape,' ',antenna_type])

end
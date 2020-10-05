function f = setSignalType(f,antenna_shape,antenna_type,measure_method,orientation_method)
% sets the values to requested signal measurement method
% Usage:
% set signal type parameters:
% orientation_method = 'M1'; (options are: 'M1','M' - default)
% measure_method = 'mean';   (options are: 'mean' - default,'median')
% antenna_type = 'fixed';    (options are: 'fixed' - default,'dynamic')
% antenna_shape = 'ellipse'; (options are: 'ellipse' - default,'circle','box')
% 
% set the values to requested signal measurement method
% f = setSignalType(f,antenna_shape,antenna_type,measure_method,orientation_method);
%  

switch nargin
    case 4
        orientation_method = 'M1';
    case 3
        orientation_method = 'M1';
        measure_method = 'mean';
    case 2
        orientation_method = 'M1';
        measure_method = 'mean';
        antenna_type = 'fixed';
    case 1
        orientation_method = 'M1';
        measure_method = 'mean';
        antenna_type = 'fixed';
        antenna_shape = 'ellipse';
end

assert(ismember(antenna_shape,{'ellipse','circle','box'}),['antenna shape definition "',antenna_shape,'" is not valid. Options: ellipse, circle, box'])
assert(ismember(antenna_type,{'fixed','dynamic'}),['antenna type definition "',antenna_type,'" is not valid. Options: fixed, dynamic'])
assert(ismember(measure_method,{'mean','median'}),['measurement method "',measure_method,'" is not valid. Options: mean, median'])
assert(ismember(orientation_method,{'M','M1'}),['measurement method "',orientation_method,'" is not valid. Options: M, M1'])

f.tracking_info.signal = f.tracking_info.(['signal_',orientation_method,'_',antenna_shape,'_',antenna_type,'_',measure_method]);
f.antoffset = f.tracking_info.(['antoffset_',orientation_method,'_',antenna_shape,'_',antenna_type]);
f.antenna_shape = antenna_shape;
f.antenna_type = antenna_type;
f.tracking_info.antenna_overlap = f.tracking_info.(['antOlap_',orientation_method,'_',antenna_shape,'_',antenna_type]);
f.tracking_info.antenna1R_overlap = f.tracking_info.(['antOlap1R_',orientation_method,'_',antenna_shape,'_',antenna_type]);
f.tracking_info.antenna2R_overlap = f.tracking_info.(['antOlap2R_',orientation_method,'_',antenna_shape,'_',antenna_type]);
f.tracking_info.orientation  = f.tracking_info.(['orientation_',orientation_method]);

% be careful about the box signal
if strcmp(f.antenna_shape,'box')
    f.tracking_info.AntBoxSignal = f.tracking_info.(['AntBoxSignal_',orientation_method,'_',antenna_shape,'_',antenna_type]);
    f.tracking_info.AntBoxSignalSegmentNum = f.tracking_info.(['AntBoxSignalSegmentNum_',orientation_method,'_',antenna_shape,'_',antenna_type]);
    f.tracking_info.AntBoxSignalSlope = f.tracking_info.(['AntBoxSignalSlope_',orientation_method,'_',antenna_shape,'_',antenna_type]);
end

% store the signal type parameters and display
f.tracking_info.CurrentSignalType.orientation_method = orientation_method;
f.tracking_info.CurrentSignalType.antenna_shape = antenna_shape;
f.tracking_info.CurrentSignalType.antenna_type = antenna_type;
f.tracking_info.CurrentSignalType.measure_method = measure_method;
disp(['Settings Updated: ',orientation_method,' ',antenna_shape,' ',antenna_type,' ',measure_method])


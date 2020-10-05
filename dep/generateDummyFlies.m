function f = generateDummyFlies(f,DummyFlyParamInput)
if nargin ==1
    DummyFlyParamInput = [];
end

DummyFlyParam.X = linspace(size(f.current_raw_frame,2),50);
DummyFlyParam.Y = linspace(size(f.current_raw_frame,1),50);
DummyFlyParam.Theta = -pi;
DummyFlyParam.antoffset = 0;
DummyFlyParam.minax = 1.83/f.ExpParam.mm_per_px;   % pixel
DummyFlyParam.majax = 3.39/f.ExpParam.mm_per_px;   % pixel
DummyFlyParam.area = 200;   % pixel^2
DummyFlyParam.perimeter = 55;   % pixel^2
DummyFlyParam.excent = 0.85;   % pixel^2

dumfields = fieldnames(DummyFlyParam);

for i = 1:numel(dumfields)
    if isfield(DummyFlyParamInput,dumfields{i})
        DummyFlyParam.(dumfields{i}) = DummyFlyParamInput.(dumfields{i});
    end
end

% first erase all dummy flies
f = clearFliesNInfo(f);

% how many flies are there
assert(length(DummyFlyParam.X)==length(DummyFlyParam.Y),'Length of X and Y must be same')
nflies = length(DummyFlyParam.X);
flymat = ones(nflies,f.nframes);
f.tracking_info.fly_status = flymat;
f.tracking_info.heading = flymat.*DummyFlyParam.Theta;
f.tracking_info.orientation = flymat.*DummyFlyParam.Theta;
f.tracking_info.area = flymat.*DummyFlyParam.area;
f.tracking_info.excent = flymat.*DummyFlyParam.excent;
f.tracking_info.majax = flymat.*DummyFlyParam.majax;
f.tracking_info.minax = flymat.*DummyFlyParam.minax;
f.tracking_info.perimeter = flymat.*DummyFlyParam.perimeter;
for i = 1:nflies
    f.tracking_info.x(i,1:f.nframes) = DummyFlyParam.X(i);
    f.tracking_info.y(i,1:f.nframes) = DummyFlyParam.Y(i);
end

% antenna parameters
f.antoffset = flymat*DummyFlyParam.antoffset;
f.reflection_status = flymat*0;
f.reflection_meas = nan(size(flymat));
f.reflection_overlap = nan(size(flymat));


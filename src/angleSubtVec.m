function remanglevec = angleSubtVec(anglevec,angle2subtract)
%angleSubtVec
% remanglevec = angleSubtVec(anglevec,angle2subtract)
% subtracts angle2subtract from anglevec by vector subtraction. vector
% lengths has to be same. If any element is nan the result will be nan
% inputs must be in degrees, the output will be degrees aswell
%

assert(isvector(anglevec),'Supply a vector or use angleDiff istead')
assert(isvector(angle2subtract),'Supply a vector or use angleDiff istead')
assert(length(anglevec)==length(angle2subtract),'lengths has to be same')

remanglevec = NaN(size(anglevec));
    
% convert degrees to radian
anglevec = anglevec/180*pi;
angle2subtract = angle2subtract/180*pi;

for i=1:length(anglevec)
    remanglevec(i) = angleDiff(angle2subtract(i),anglevec(i));
end

remanglevec = remanglevec/pi*180;
    
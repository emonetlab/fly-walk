function diffangle = angleDiffVec(anglevec,angle2subtract)
%angleDiffVec
% diffangle = angleDiffVec(anglevec,angle2subtract)
% returns the differentiated angle vector. input and output are in degrees
% if no angle2subtract is given then it differentiates anglevec. If
% angle2subtract is given then subtracts that from all elements of anglevec
% In order to subtract two vectors element by element then same length 
% vectors has to be supplied
%

diffangle = zeros(size(anglevec));
if nargin==1
    if length(anglevec)==1
        diffangle = 0;
        return
    end

    % convert degrees to radian
    anglevec = anglevec/180*pi;

    for i=2:length(anglevec)
        diffangle(i) = angleDiff(anglevec(i-1),anglevec(i));
    end

    diffangle(1) = [];
    diffangle = diffangle/pi*180;
else
    if isscalar(angle2subtract)
        % convert degrees to radian
        anglevec = anglevec/180*pi;
        angle2subtract = angle2subtract/180*pi;

        for i=1:length(anglevec)
            diffangle(i) = angleDiff(angle2subtract,anglevec(i));
        end

        diffangle = diffangle/pi*180;
    else
        assert(length(anglevec)==length(angle2subtract),'Vector lengths has to be same')
        % convert degrees to radian
        anglevec = anglevec/180*pi;
        angle2subtract = angle2subtract/180*pi;

        for i=1:length(anglevec)
            diffangle(i) = angleDiff(angle2subtract(i),anglevec(i));
        end

        diffangle = diffangle/pi*180;
    end
end
    
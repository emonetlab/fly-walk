function XY = getTriangleFlyHeading(f,thisFly,thisFrame)
%getTriangleFlyHeading
% XY = getTriangleFlyHeading(f,thisFly,thisFrame)
% returns the coordinates for given fly and frame (default: current frame)
% that constittues the orientation of the fly in a trinagle shape. Output
% vector is 4x2 matrix whose columns are X and Y and 4 points are the
% corners of the triangle. Start point is same as end so that triangle
% becomes closed when plotted.
%

if nargin<3
    thisFrame = f.current_frame;
end
X = zeros(4,1);
Y = zeros(4,1);

offset = [f.tracking_info.x(thisFly,thisFrame),f.tracking_info.y(thisFly,thisFrame)]; % get center of the fly
THETA = (f.tracking_info.heading(thisFly,thisFrame)*pi/180);            % get fly orientation in radians
maj = f.tracking_info.majax(thisFly,thisFrame)*f.orient_triangle_size;      % get and resize the triagle major axis
min = f.tracking_info.minax(thisFly,thisFrame)*f.orient_triangle_size;      % get and resize the triagle minor axis
[X(1),Y(1)] = pol2cart(THETA,maj);          % calculate postions of the triangle corners
[X(2),Y(2)] = pol2cart(THETA+pi/2,min);     % calculate postions of the triangle corners
[X(3),Y(3)] = pol2cart(THETA-pi/2,min);     % calculate postions of the triangle corners
X(4) = X(1);                                % set the last point as the first to close the loop
Y(4) = Y(1);                                % calculate postions of the triangle corners
X(2:3) = X(2:3) - X(1);                     % set side corners wrt to forward point
Y(2:3) = Y(2:3) - Y(1);                     % set side corners wrt to forward point
X = offset(1)+X;        % move triangle to center of the fly
Y = offset(2)+Y;        % move triangle to center of the fly

% retunr the values
XY = [X,Y];
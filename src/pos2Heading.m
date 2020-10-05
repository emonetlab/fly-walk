function heading = pos2Heading(positionx,positiony)
% return the velocity vector orientations as headings calculated by
% differentiating the position

heading = zeros(size(positionx));


vx = diff(positionx);
vy = diff(positiony);
heading(2:end) = mod(cart2pol(vx,vy)/pi*180,360); %degrees
heading(1) = heading(2);
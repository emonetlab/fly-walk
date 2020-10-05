function flyDiffVel = getFlyDiffVel(f,this_fly)
% returns the speed of the fly for all frames compuuted as differentiation
% of the position

flyDiffVel = zeros(size(f.tracking_info.x(this_fly,:)));
flyDiffVel(2:end) = sqrt(diff(f.tracking_info.x(this_fly,:)).^2+diff(f.tracking_info.y(this_fly,:)).^2);
flyDiffVel(1) = flyDiffVel(2);
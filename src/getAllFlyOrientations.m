function f = getAllFlyOrientations(f)
% calculates the fly orientations 

if strcmp(f.orientation_method,'Int Grad Vote')
    % get orientations of the flies by estimating the intensity gradient
    if ~isempty(reset_these)
        % reset all orientation collection for these flies
        f.tracking_info.grador(reset_these,:) = 0;
    end
    f = getAllFlyGradOrs(f);
elseif strcmp(f.orientation_method,'Heading Lock')
    f = getAllFlyEllipsOrs(f);
end
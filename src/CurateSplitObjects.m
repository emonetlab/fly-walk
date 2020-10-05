function split_objects = CurateSplitObjects(f,split_objects,resolve_these)
% PredictPositions. Estimates the current positions of the flies using the
% previous positions, mean spedd and acceleration. Speeds up the flies if
% they are miving in opposite direction in order to better resolution
%

% resolve these flies
resolve_these = abs(resolve_these);
immobl = isImmobile(f,resolve_these);
% curate estimate the predicted locations

who_are_immobile = resolve_these(immobl);

if ~isempty(who_are_immobile)
    for i = 1:length(who_are_immobile)
        this_immobile = who_are_immobile(i);
        % get position of the immobile
        xy = [f.tracking_info.x(this_immobile,f.current_frame);f.tracking_info.y(this_immobile,f.current_frame)];
        % get other flies positions
        pos = reshape([split_objects.Centroid],2,length(resolve_these));
        dist = sqrt((pos(1,:)-xy(1,1)).^2+(pos(2,:)-xy(2,1)).^2);
        split_objects(dist==min(dist)).Centroid = xy';

        if f.ft_debug
            disp(['fly: ',num2str(this_immobile),' seems to be immobile. Fixing its location'])
        end

    end
end


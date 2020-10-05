function f = findCentreZoneflies(f)
%findCentreZoneflies finds the flies currently in the centre zone

current_positions = reshape([f.current_objects.Centroid],2,length([f.current_objects.Centroid])/2)';

% go over them and determine if they are in the centre zone


for i = 1:size(current_positions,1)
    if isIntheCentreZone(f,current_positions(i,:))
        f.flies_in_the_centre_zone = [f.flies_in_the_centre_zone,...
            f.current_object_status(i)];
    end
end



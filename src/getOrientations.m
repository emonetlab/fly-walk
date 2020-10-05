function f = getOrientations(f)
if f.current_frame==1
    return
end
if strcmp(f.orientation_method,'Heading Allign')
    f = getFlyOrientations(f); % this does continuous orientation - heading allignment
else
    f = GetCorrectNLockOrientations(f); % this purely depends on intensity gradient along the fly
end
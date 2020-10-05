function flyPxlList = genFlyPxlList(this_fly)
% generates the ellips mask pixel list for given fly parameters. theta is
% in degrees

x = this_fly(1);
y = this_fly(2);
majax = this_fly(3)/2;
minax = this_fly(4)/2;
theta = this_fly(5)/180*pi;

flyPxlList = ellips_mat_aneq(minax,majax,theta,x,y);


function fixpnlprfax(sp,fontsize)
if nargin ==1
    fontsize = 8;
end
mainplotpos = plotboxpos(sp(2,1).axis);
% set(sp(1,1).axis,'Position',[mainplotpos(1) mainplotpos(2)-sp(1,1).position(4) mainplotpos(3) sp(2,1).position(4)]);
% set(sp(2,2).axis,'Position',[mainplotpos(1)+mainplotpos(3) mainplotpos(2) sp(1,2).position(3) mainplotpos(4)])
set(sp(1,1).axis,'Position',[mainplotpos(1) mainplotpos(2)+mainplotpos(4) mainplotpos(3) sp(1,1).position(4)]);
set(sp(2,2).axis,'Position',[mainplotpos(1)+mainplotpos(3) mainplotpos(2) sp(2,2).position(3) mainplotpos(4)])
set(sp(1,1).axis,'FontSize',fontsize);
set(sp(2,2).axis,'FontSize',fontsize)
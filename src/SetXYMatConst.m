function xymat_antenna = SetXYMatConst(xymat_antenna,constraint)
%constraint: [xmin,xmax,ymin,ymax]
xmin = constraint(1);
xmax = constraint(2);
ymin = constraint(3);
ymax = constraint(4);
    
xymat_antenna(xymat_antenna(:,2)<ymin,:)=[];
xymat_antenna(xymat_antenna(:,1)<xmin,:)=[];
xymat_antenna(xymat_antenna(:,2)>ymax,:)=[];
xymat_antenna(xymat_antenna(:,1)>xmax,:)=[];
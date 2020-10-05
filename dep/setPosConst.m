%% remove the tracjectory pieces from the experimental matrix if fell out of the position contraint
function stemp = setPosConst(stemp,ConstraintParam)
stemp.expmat((stemp.expmat(:,stemp.col.x)-stemp.expmat(:,stemp.col.sx))<ConstraintParam.xarena(1),:) = [];
stemp.expmat((stemp.expmat(:,stemp.col.x)-stemp.expmat(:,stemp.col.sx))>ConstraintParam.xarena(2),:) = [];
stemp.expmat((stemp.expmat(:,stemp.col.y)-stemp.expmat(:,stemp.col.sy))<ConstraintParam.yarena(1),:) = [];
stemp.expmat((stemp.expmat(:,stemp.col.y)-stemp.expmat(:,stemp.col.sy))>ConstraintParam.yarena(2),:) = [];
end
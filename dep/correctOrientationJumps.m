function f = correctOrientationJumps(f,method,mulThresh)
%correctOrientationJumps
% f = correctOrientationJumps(f,mulThresh)
% corrects the orienttaion jumps that is caused by a bug in the orientation
% detections. This code is able to detect and fix single frame orientation
% jumps. A jumps that lasts two frame is also corrected. The way the jumps
% are identified is : 
% Central and forward derivatives of the orientation is multiplied and
% thresholded by a factor (default 1000). Thsi gives where the jump occurs.
% Then the jumps are replaced by the mean of the prior and post orientation
% Default method is interpolating the angles, alternative is replacing ith
% average
%

switch nargin
    case 2
        mulThresh = 1000;
    case 1
        mulThresh = 1000;
        method = 'interpolate'; % alternative average   
end

theseTracks = find(f.tracking_info.fly_status(:,end)~=0);

if strcmp(method,'average')
    for flyInd = 1:length(theseTracks)
        flyNum = theseTracks(flyInd);
        dthetac = anglediffCentral(f.tracking_info.orientation(flyNum,:)); % central deivative
        dthetaf = anglediffFwd(f.tracking_info.orientation(flyNum,:)); % forward derivative
        thesejumps = find(dthetaf.*dthetac>mulThresh)+1; % threshold the multiplication
        thesejumplen = ones(size(thesejumps));
        thesejumplen(diff(thesejumps)==2) = 2; % are there any jumps lasting two frames
        % delete the extra jumps
        thesejumplen(find(diff(thesejumps)<=2)+1) = [];
        thesejumps(find(diff(thesejumps)<=2)+1) = [];
        for jnum = 1:length(thesejumps)
            ornt = [f.tracking_info.orientation(flyNum,thesejumps(jnum)-1),f.tracking_info.orientation(flyNum,thesejumps(jnum)+thesejumplen(jnum))];
            f.tracking_info.orientation(flyNum,thesejumps(jnum):thesejumps(jnum)+thesejumplen(jnum)-1) = meanOrientation(ornt);
        end
    end
elseif strcmp(method,'interpolate')
        for flyInd = 1:length(theseTracks)
        flyNum = theseTracks(flyInd);
        dthetac = anglediffCentral(f.tracking_info.orientation(flyNum,:)); % central deivative
        dthetaf = anglediffFwd(f.tracking_info.orientation(flyNum,:)); % forward derivative
        thesejumps = find(dthetaf.*dthetac>mulThresh)+1; % threshold the multiplication
        thesejumplen = ones(size(thesejumps));
        thesejumplen(diff(thesejumps)==2) = 2; % are there any jumps lasting two frames
        % delete the extra jumps
        thesejumplen(find(diff(thesejumps)<=2)+1) = [];
        thesejumps(find(diff(thesejumps)<=2)+1) = [];
        for jnum = 1:length(thesejumps)
            f.tracking_info.orientation(flyNum,thesejumps(jnum):thesejumps(jnum)+thesejumplen(jnum)-1) = nan;
        end
        fnums = find(f.tracking_info.fly_status(flyNum,:)==1,1);
        fnume = find(f.tracking_info.fly_status(flyNum,:)==1,1,'last');
        % interpolate
        f.tracking_info.orientation(flyNum,fnums:fnume) = fillgaps(f.tracking_info.orientation(flyNum,fnums:fnume)); 
        end
else
    correctOrientationJumps
    error('unknown method')
end
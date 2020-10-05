function [Data,AngCountIndx] = getAngleBinnedDataRandom(expmat,t_pre,t_post,t_int,nbins,trackPerBin,angoffset,windparam,colNames)

switch nargin
    case 8
        colNames = [];
    case 7
        colNames = [];
        windparam = [];
    case 6
        colNames = [];
        windparam = [];
        angoffset = -10; % degree
    case 5
        colNames = [];
        windparam = [];
        angoffset = -10; % degree
        trackPerBin = 100; % try to get 100 tracks per bin
    case 4
        colNames = [];
        windparam = [];
        angoffset = -10; % degree
        trackPerBin = 100; % try to get 100 tracks per bin
        nbins =  18;    % 20 degree bins
    case 3
        colNames = [];
        windparam = [];
        angoffset = -10; % degree
        trackPerBin = 100; % try to get 100 tracks per bin
        nbins = 18;     % use only encounter point to deterrmine angle
        t_int = .2;  % sec
end

if isempty(windparam)
    windDirCol = 43;
    smoothWindDirN = 1; % do not smooth
    smoothWindDSpeedN = 1;
    useWindDir = 0;     % do not use wind dir
    smoothFlyOrientN = 1;
else
    windDirCol = windparam.windDirCol;
    smoothWindDirN = windparam.smoothWindDirN;
    smoothWindDSpeedN = windparam.smoothWindSpeedN;
    useWindDir = windparam.useWindDir;
    smoothFlyOrientN = windparam.smoothFlyOrientN;
end

% go over angle offsets and combine data;
Data = [];  % data for all encounter

% define the fields to be collected
if isempty(colNames)
    if useWindDir
        colnum =     [6,  7,   10,   11,      15,        16,      29,      30,     31,    32,    42,      34,        43,      44];
        fieldname = {'x','y','spd','theta','signal','dtheta','reflection','coll','opass','jump','smask','encon','winddir','windspeed'};
        expmat = smoothExpMatTheta(expmat,windDirCol,smoothWindDirN); % smooth wind direction
        expmat = smoothExpMatColumn(expmat,windDirCol+1,smoothWindDSpeedN); % smooth wind speed
    else
        colnum =     [6,  7,   10,   11,      15,        16,      29,      30,     31,    32,    42,      34];
        fieldname = {'x','y','spd','theta','signal','dtheta','reflection','coll','opass','jump','smask','encon'};
    end
else
    if useWindDir
        fieldname = {'x','y','spd','theta','signal','dtheta','reflection','coll','opass','jump','smask','encon','winddir','windspeed'};
        colnum = zeros(size(fieldname),'uint8');
        for i = 1:numel(fieldname)
            if any(strcmp(colNames,fieldname(i))) % exist
                colnum(i) = find(strcmp(colNames,fieldname(i)));
            end
        end
        fieldname(colnum==0) = [];
        colnum(colnum==0) = [];
        % add encounter number
        fieldname(end+1) ={'encon'};
        colnum(end+1) = 34;
        % double check and verify that exits
        expmat = smoothExpMatTheta(expmat,windDirCol,smoothWindDirN); % smooth wind direction
        expmat = smoothExpMatColumn(expmat,windDirCol+1,smoothWindDSpeedN); % smooth wind speed
    else
        fieldname = {'x','y','spd','theta','signal','dtheta','reflection','coll','opass','jump','smask','encon'};
        colnum = zeros(size(fieldname),'uint8');
        for i = 1:numel(fieldname)
            if any(strcmp(colNames,fieldname(i))) % exist
                colnum(i) = find(strcmp(colNames,fieldname(i)));
            end
        end
        fieldname(colnum==0) = [];
        colnum(colnum==0) = [];
        fieldname(end+1) ={'encon'};
        colnum(end+1) = 34;
    end
end

% smooth angles if requested
flyOrCol = 11;
% if smoothing requested, smooth the angle vectors
if ~isnan(smoothFlyOrientN)
    expmat = smoothExpMatTheta(expmat,flyOrCol,smoothFlyOrientN);
end
if useWindDir
    if ~isnan(smoothWindDirN)
        expmat = smoothExpMatTheta(expmat,windDirCol,smoothWindDirN);
    end
    if ~isnan(smoothWindDSpeedN)
        expmat = smoothExpMatColumn(expmat,windDirCol+1,smoothWindDSpeedN);
    end
end

for nangoff = 1:length(angoffset)
    datatemp = [];
    datatemp(nbins).ntrj = [];
    AngCountIndx = binEncounterAngleRandom(expmat,nbins,trackPerBin,t_int,angoffset(nangoff),windparam);
    maxfps = round(max(expmat(vertcat(AngCountIndx.indx{:}),20)));
    maxencnum = size(AngCountIndx.countn,2);
    time = ((1:(t_pre+t_post)*maxfps+1)-(t_pre*maxfps+1))/maxfps;
    expmat(:,end+1) = (1:size(expmat,1))'; % put indexes at the last column of expmat
    
    % get and average all encounters
    for i = 1:nbins
        datatemp(i).angle = AngCountIndx.angle(i);
        datatemp(i).ntrj = AngCountIndx.count(i);
        datatemp(i).encnum = AngCountIndx.encnumlist{i};
        datatemp(i).index = AngCountIndx.indx{i};
        datatemp(i).encangle = AngCountIndx.encangle{i};
        indxi = AngCountIndx.indx{i};
        windSc = NaN(AngCountIndx.count(i),1); % x position of the encounter point
        windDirc = NaN(AngCountIndx.count(i),1); % y position of the encounter point
        flyOrc = NaN(AngCountIndx.count(i),1); % source-x position of the encounter point
        xc = NaN(AngCountIndx.count(i),1); % x position of the encounter point
        yc = NaN(AngCountIndx.count(i),1); % y position of the encounter point
        sx = NaN(AngCountIndx.count(i),1); % source-x position of the encounter point
        sy = NaN(AngCountIndx.count(i),1); % source-x position of the encounter point
        xencs = NaN(AngCountIndx.count(i),maxencnum); % x position of the all encounters on this track
        yencs = NaN(AngCountIndx.count(i),maxencnum); % y position of the all encounters on this track
        nencs = NaN(AngCountIndx.count(i),maxencnum); % encounter numbers of the all encounters on this track
        indencs = NaN(AngCountIndx.count(i),maxencnum); % encounter index numbers at expmat of the all encounters on this track
        ThetaDotPhi = NaN(AngCountIndx.count(i),length(time)); % dot product between the wind direction and fly orientation
        for k = 1:length(colnum)
            if AngCountIndx.count(i)>0
                datai = NaN(AngCountIndx.count(i),length(time));
                for j = 1:AngCountIndx.count(i)
                    tfps = round(expmat(indxi(j),20));
                    tpre = round(t_pre*tfps);
                    tpost = round(t_post*tfps);
                    
                    if (indxi(j)-tpre)<1
                        inds = 1;
                    else
                        inds = indxi(j)-tpre;
                    end
                    if (indxi(j)+tpost)>size(expmat,1)
                        inde = size(expmat,1);
                    else
                        inde = indxi(j)+tpost;
                    end
                    timej = expmat(inds:inde,5) - expmat(indxi(j),5);
                    indj = expmat(inds:inde,1);
                    trjindj = expmat(indxi(j),1);
                    dataj = expmat(inds:inde,colnum(k));
                    encvalj = expmat(inds:inde,34); % considering onset encounters
                    emtemp = expmat(inds:inde,:);
                    % remove the points that does not belong to this track
                    timej(indj~=trjindj) = [];
                    dataj(indj~=trjindj) = [];
                    encvalj(indj~=trjindj) = [];
                    emtemp(indj~=trjindj,:) = [];
                    
                    datai(j,:) = interp1(timej,dataj,time); % interpolate the vector
                    
                    if (strcmp(fieldname(k),{'x'}))
                        xc(j) = expmat(indxi(j),colnum(k));
                        % get source location as well
                        sx(j) = expmat(indxi(j),22);
                        sy(j) = expmat(indxi(j),23);
                        if useWindDir
                            windSc(j) = expmat(indxi(j),44); % wind spped at the contact
                            windDirc(j) = expmat(indxi(j),43); % wind direction at the contact
                        end
                        flyOrc(j) = expmat(indxi(j),11); % fly orientation at the contact
                        encinds = emtemp(encvalj>0,end);
                        xencs(j,1:length(encinds)) = emtemp(encvalj>0,6); % x position of the all encounters on this track
                        yencs(j,1:length(encinds)) = emtemp(encvalj>0,7); % y position of the all encounters on this track
                        nencs(j,1:length(encinds)) = emtemp(encvalj>0,34); % encounter numbers of the all encounters on this track
                        indencs(j,1:length(encinds)) = encinds;
                    end
                    if (strcmp(fieldname(k),{'y'}))
                        yc(j) = expmat(indxi(j),colnum(k));
                        % that means it reached the point of rotation
                        if useWindDir
                            
                            x2r = datatemp(i).x(j,:);
                            y2r = datai(j,:);
                            xc2r = xc(j);
                            yc2r = yc(j);
                            theta2r = -windDirc(j);
                            [xr,yr] = rotateTrack(theta2r,x2r,y2r,xc2r,yc2r);
                            
                            % put on the structure
                            %                             datatemp(i).xr(j,:) = xr;
                            %                             datatemp(i).yr(j,:) = yr;
                            datatemp(i).x(j,:) = xr;
                            datai(j,:) = yr;
                        end
                        
                    end
                    % calculate the dot product of two vectors
                    if (strcmp(fieldname(k),{'theta'}))
                        if useWindDir
                            wdtemp = emtemp(:,windDirCol);
                            %                             wdtemp = smoothOrientation(wdtemp,smoothWindDirN);
                            sinphi = sind(wdtemp); % wind direction at the contact
                            cosphi = cosd(wdtemp); % wind direction at the contact
                        else
                            % assume wind direction is 0
                            sinphi = sind(0); % wind direction at the contact
                            cosphi = cosd(0); % wind direction at the contact
                        end
                        
                        % calsulate for the trajectory
                        %                         fortemp = smoothOrientation(dataj,smoothFlyOrient);
                        sintheta = sind(dataj);
                        costheta = cosd(dataj);
                        
                        % get the dot product
                        ThetaDotPhi_temp = sinphi.*sintheta + cosphi.*costheta;
                        
                        % interpolate this value with the correct time vector
                        ThetaDotPhi(j,:) = interp1(timej,ThetaDotPhi_temp,time); % interpolate the vector
                        
                    end
                    
                    
                    
                end
                datatemp(i).(fieldname{k}) = datai;
            end
        end
        datatemp(i).ThetaDotPhi = ThetaDotPhi;
        %         datatemp(i).x  = xr;
        %         datatemp(i).y  = yr;
        datatemp(i).time = time;
        datatemp(i).xc = xc;
        datatemp(i).yc = yc;
        datatemp(i).sx = sx;
        datatemp(i).sy = sy;
        datatemp(i).windSc = windSc;
        datatemp(i).windDirc = windDirc;
        datatemp(i).flyOr = flyOrc;
        datatemp(i).xencs = xencs;
        datatemp(i).yencs =  yencs;
        datatemp(i).nencs = nencs;
        datatemp(i).indencs = indencs;
    end
    Data = [Data,datatemp];
   
end

%Sort the structure
Data = sortStructure(Data,'angle');



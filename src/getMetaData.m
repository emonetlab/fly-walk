% creates a meta data table for the given experiment statistics
function metadata = getMetaData(stats,MeanRange)

% is a range ort mean value requested for fly age and starved days
if nargin==1
    MeanRange = 'Range';
end

if strcmp(MeanRange,'Mean')||strcmp(MeanRange,'mean')||strcmp(MeanRange,'m')
    property = {'Room Temperature';'Room Humidity';'Fly Age';'Fly Starved';...
        '# of vials';'Experiment Duration';'fly per video';'track per video';...
        'mean track length';'Camera rate'};
    
    value = [stats.roomT(1);stats.roomH(1);stats.age(1);stats.starve(1);...
        stats.nexp;stats.lenexp;stats.noflym(1);stats.noftrj(1);...
        stats.mtrjlen(1);stats.fps(1)];
    
    err = [stats.roomT(2);stats.roomH(2);stats.age(2);stats.starve(2);...
        0;0;stats.noflym(2);stats.noftrj(2);stats.mtrjlen(2);stats.fps(2)];
    
    unit = char({'C';'%';'days';'days';'';'sec';'flies';'tracks';'sec';'fps'});
    
    metadata = table(value,err,unit,'RowNames',property);
elseif strcmp(MeanRange,'Range')||strcmp(MeanRange,'range')||strcmp(MeanRange,'r')
    property = {'Room Temperature';'Room Humidity';'Fly Age';'Fly Starved';...
        '# of vials';'Experiment Duration';'fly per video';'track per video';...
        'mean track length';'Camera rate'};
    if min(stats.T.age)==max(stats.T.age)
        agetxt = num2str(min(stats.T.age));
    else
        agetxt = [num2str(min(stats.T.age)),'-',num2str(max(stats.T.age))];
        
    end
    
    if min(stats.T.starve)==max(stats.T.starve)
        starvetxt = num2str(min(stats.T.starve));
    else
        starvetxt = [num2str(min(stats.T.starve)),'-',num2str(max(stats.T.starve))];
        
    end
    
    value = char({num2str(stats.roomT(1));num2str(stats.roomH(1));agetxt;...
        starvetxt;num2str(stats.nexp);num2str(stats.lenexp);...
        num2str(stats.noflym(1));num2str(stats.noftrj(1));num2str(stats.mtrjlen(1));num2str(stats.fps(1))});
    
    err = [stats.roomT(2);stats.roomH(2);0;0;...
        0;0;stats.noflym(2);stats.noftrj(2);stats.mtrjlen(2);stats.fps(2)];
    
    unit = char({'C';'%';'days';'days';'';'sec';'flies';'tracks';'sec';'fps'});
    
    metadata = table(value,err,unit,'RowNames',property);
else
    error('enter a valid value: e.g. Mean, mean, m, Range, range or r')
end
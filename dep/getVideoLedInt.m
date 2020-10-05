function LedInt = getVideoLedInt(filename,rec_x,rec_y)
%getVideoLedInt
% LedInt = getVideoLedInt(filename,rec_x,rec_y) returns the LED intensity
% , whose position is defined by the position boundaries as rec_x and
% rec_y, as a function of the frame number
%
if nargin ==1
    rec_x = [0 80]; % pixel lower and upper bound of the led box, x
    rec_y = [0 50]; % pixel lower and upper bound of the led box, y
end

LedInt.RecInt = nan;
LedInt.rec_x = rec_x;
LedInt.rec_y = rec_y;

    disp(['Working on: ',filename])
    mvid = matfile([filename(1:end-4),'-frames.mat']);
    [~,~,nframes] = size(mvid,'frames');
    LedInt.RecInt = zeros(nframes,1);
    h = waitbar(0,'Initializing waitbar...');
    for i = 1:nframes
        thisFrame = mvid.frames(:,:,i);
        LedIntTemp = thisFrame(1:rec_y(2),1:rec_x(2));
        LedInt.RecInt(i) = mean(double(LedIntTemp(:)));
        waitbar(i/nframes,h,'progress...')
    end
    close(h)
    [pon,poff] = getOnOffPoints(diff(LedInt.RecInt>100));
    LedInt.frmOn = find(LedInt.RecInt>100,1);
    LedInt.frmOff = find(LedInt.RecInt>100,1,'last');
    LedInt.OnPoints = pon;
    LedInt.OffPoints = poff;
    disp('done...')
    disp('----------------------------------------------------------------')
    disp('   ')
end
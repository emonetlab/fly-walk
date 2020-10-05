function [RateOn,RateOff] = getRateOverwindow(OnInd,OffInd,WindLen)
RateOn = nan(size(OnInd(1):OffInd(end)));
RateOff = nan(size(OnInd(1):OffInd(end)));
BinaryVecOn = zeros(size(OnInd(1):OffInd(end)));
BinaryVecOff = zeros(size(OnInd(1):OffInd(end)));
if nargin==2
    WindLen = []; % calculate instnataneous rate
else
    if mod(WindLen,2)==0
        WindLen = WindLen+1; % needs to be odd
    end
end

% construct binary vector
for j = 1:length(OnInd)
    if j<length(OnInd)
        BinaryVecOff(OffInd(j):OnInd(j+1)) = j;
    end
    BinaryVecOn(OnInd(j):OffInd(j)) = j;
end

if isempty(WindLen)
    startIndOffset = OnInd(1)-1;
    for j = 1:length(OnInd)
    if j<length(OnInd)
        RateOff(OffInd(j)-startIndOffset:OnInd(j+1)-startIndOffset) = 1/(OnInd(j+1)-OffInd(j));
    end
    RateOn(OnInd(j)-startIndOffset:OffInd(j)-startIndOffset) = 1/(OffInd(j)-OnInd(j));
    end
elseif WindLen>=(length(RateOn))
    RateOn(:) = length(OnInd)/sum(OffInd-OnInd);
    RateOff(:) = (length(OnInd)-1)/sum(OnInd(2:end)-OffInd(1:end-1));
else

        theseOnLen  = OffInd-OnInd;
        theseOffLen  = OnInd(2:end)-OffInd(1:end-1);
        % left end
        thisInd = 1:(WindLen+1)/2;
        theseOn = nonzeros(unique(BinaryVecOn(thisInd))); 
        theseOff = nonzeros(unique(BinaryVecOff(thisInd)));
        if ~isempty(theseOn)
            RateOn(thisInd) = length(theseOn)/length(OnInd(theseOn(1)):OffInd(theseOn(end)));
        end
        if  ~isempty(theseOff)
            RateOff(thisInd) = length(theseOff)/length(OffInd(theseOff(1)):OnInd(theseOff(end)));
        end
        % right end
        thisInd = length(RateOn)-(WindLen+1)/2+1:length(RateOn);
        theseOn = nonzeros(unique(BinaryVecOn(thisInd))); 
        theseOff = nonzeros(unique(BinaryVecOff(thisInd)));
        if ~isempty(theseOn)    
            RateOn(thisInd) = length(theseOn)/length(OnInd(theseOn(1)):OffInd(theseOn(end)));
        end
        if  ~isempty(theseOff)
            RateOff(thisInd) = length(theseOff)/length(OffInd(theseOff(1)):OnInd(theseOff(end)));
        end
        for j = ((WindLen+1)/2+1):(length(RateOn)-(WindLen+1)/2)
            thisInd = (j-(WindLen+1)/2):(j+(WindLen+1)/2);
            theseOn = nonzeros(unique(BinaryVecOn(thisInd))); 
            theseOff = nonzeros(unique(BinaryVecOff(thisInd)));
            if ~isempty(theseOn)
%                 thisrate = 0;
%                 for toi = 1:length(theseOn)
%                     thisrate = thisrate+1/theseOnLen(toi);
%                 end
                RateOn(thisInd) = length(theseOn)/length(OnInd(theseOn(1)):OffInd(theseOn(end)));
            end
            if  ~isempty(theseOff)
%                  thisrate = 0;
%                 for toi = 1:length(theseOff)
%                     thisrate = thisrate+1/theseOffLen(toi);
%                 end
                RateOff(thisInd) = length(theseOff)/length(OffInd(theseOff(1)):OnInd(theseOff(end)));
            end
        end
end

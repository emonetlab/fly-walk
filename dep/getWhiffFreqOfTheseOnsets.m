function whiffFreq = getWhiffFreqOfTheseOnsets(onsetTimes,windowLen)
% counts whiffs in windowlen centered on each whiff and coverts that to
% encounter frequency
% onsetTimes: encounter onset times in seconds
% windowlen: window size to calculate whiff freq
%
whiffFreq = zeros(size(onsetTimes));
for i = 1:length(onsetTimes)
    ott = onsetTimes;
    ott(ott>(ott(i)+windowLen/2)) = [];
    ott(ott<(ott(i)-windowLen/2)) = [];
    whiffFreq(i) = length(ott)/windowLen;
end
    
    
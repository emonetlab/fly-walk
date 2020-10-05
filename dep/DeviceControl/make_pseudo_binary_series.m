function binary_series = make_pseudo_binary_series(corr_length,max_length,duration,sr)
%make_pseudo_binary_series(corr_length,max_length,duration,sr)
%   function to generate pseudo random binary series for flickering odor
%   stimulus valve control
%   corr_length = minimum length of the time that valve is open or closed in ms
%   max_length =  maximum time that valve can be open or closed (ms)
%   sr : sampling rate, per second
%   duration = total duration of the flickering series in seconds sec
if nargin==3
    sr = 1000;  % default sampling rate
end

binary_series = zeros(duration*sr,1);

ind = 0;
time_on = 0;
time_off = 0;
for i = 1:duration*sr
    while ind<duration*sr
        if rand > .5
            time_on = time_on + corr_length/1000*sr;
            time_off = 0;
            if time_on<=max_length
                binary_series(ind+1:ind+corr_length/1000*sr) = 1;
                ind = ind+corr_length/1000*sr;
            end
            
        else
            time_off = time_off + corr_length/1000*sr;
            time_on = 0;
            if time_off<=max_length
                binary_series(ind+1:ind+corr_length/1000*sr) = 0;
                ind = ind+corr_length/1000*sr;
            end
        end
    end
end

  binary_series(duration*sr+1:end) = [];
  
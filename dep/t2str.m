function time_str = t2str(sec)
% converts seconds in to time format

mint = fix(sec/60);
s = rem(sec,60);
min = rem(mint,60);
hr = fix(mint/60);
if s<10
    sstr = [' 0',int2str(s)];
else
    sstr = [' ',int2str(s)];
end
if min<10
    mstr = [' 0',int2str(min)];
else
    mstr = [' ',int2str(min)];
end

time_str = strcat(num2str(hr,'%2.0f'),' Hr:',mstr,' min:',sstr,' sec ');

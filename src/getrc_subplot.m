function [c, r] = getrc_subplot(data_length)
% finds the appropriate column (c) and raw (r) for a given data length for
% subplot creation.

c = round(sqrt(data_length));
if rem(data_length,c)==0
    r = round(data_length/c);
else
    r = fix(data_length/c)+1;
end
if data_length==0
    error('If the data_length is zero there is no need to use subplot.')
end

function data = gaussfilt1d(data,npoints,alpha)



% Construct blurring window.
gaussFilter = gausswin(npoints,alpha);
gaussFilter = gaussFilter / sum(gaussFilter); % Normalize.

% Do the blur.
datat = data;
datat = conv(datat, gaussFilter);

xoffset = length(datat)-length(data);

data = datat(round(xoffset/2)+1:round(xoffset/2)+length(data));

% % plot it.
% hold on;
% plot(smoothedVector(halfWidth:end-halfWidth), 'b-', 'linewidth', 3);
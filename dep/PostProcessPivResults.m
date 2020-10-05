function [u_filtered,v_filtered,typevector_filtered] = PostProcessPivResults(u,v,typevector,parameters)
% validates the vectors and interpolates for missing and mask areas

% Settings
umin = parameters.PP.umin; % minimum allowed u velocity
umax = parameters.PP.umax; % maximum allowed u velocity
vmin = parameters.PP.vmin; % minimum allowed v velocity
vmax = parameters.PP.vmax; % maximum allowed v velocity
stdthresh = parameters.PP.stdthresh; % threshold for standard deviation check
nm_epsilon = parameters.PP.epsilon; % epsilon for normalized median test
nm_thresh = parameters.PP.thresh; % threshold for normalized median test

u_filtered=u;
v_filtered=v;

%% interpolating the whole image seems reasonable
% % first set all NaNs to zero, otherwise all points will be interpolated. We
% % want only the points in the fly mask and out of limit values to be
% % interpolated
% u_filtered(isnan(u)) = 0;
% v_filtered(isnan(v)) = 0;

typevector_filtered=typevector;
%vellimit check
u_filtered(u_filtered<umin)=NaN;
u_filtered(u_filtered>umax)=NaN;
v_filtered(v_filtered<vmin)=NaN;
v_filtered(v_filtered>vmax)=NaN;
% stddev check
meanu=nanmean(nanmean(nonzeros(u_filtered)));
meanv=nanmean(nanmean(nonzeros(v_filtered)));
std2u=nanstd(nonzeros(reshape(u_filtered,size(u_filtered,1)*size(u_filtered,2),1)));
std2v=nanstd(nonzeros(reshape(v_filtered,size(v_filtered,1)*size(v_filtered,2),1)));
minvalu=meanu-stdthresh*std2u;
maxvalu=meanu+stdthresh*std2u;
minvalv=meanv-stdthresh*std2v;
maxvalv=meanv+stdthresh*std2v;
u_filtered(u_filtered<minvalu)=NaN;
u_filtered(u_filtered>maxvalu)=NaN;
v_filtered(v_filtered<minvalv)=NaN;
v_filtered(v_filtered>maxvalv)=NaN;
% normalized median check
%Westerweel & Scarano (2005): Universal Outlier detection for PIV data
[J,I]=size(u_filtered);
normfluct=zeros(J,I,2);
b=1;
for c=1:2
    if c==1; velcomp=u_filtered;else;velcomp=v_filtered;end %#ok<*NOSEM>
    for i=1+b:I-b
        for j=1+b:J-b
            neigh=velcomp(j-b:j+b,i-b:i+b);
            neighcol=neigh(:);
            neighcol2=[neighcol(1:(2*b+1)*b+b);neighcol((2*b+1)*b+b+2:end)];
            med=median(neighcol2);
            fluct=velcomp(j,i)-med;
            res=neighcol2-med;
            medianres=median(abs(res));
            normfluct(j,i,c)=abs(fluct/(medianres+nm_epsilon));
        end
    end
end
info1=(sqrt(normfluct(:,:,1).^2+normfluct(:,:,2).^2)>nm_thresh);
u_filtered(info1==1)=NaN;
v_filtered(info1==1)=NaN;

typevector_filtered(isnan(u_filtered))=2;
typevector_filtered(isnan(v_filtered))=2;
typevector_filtered(typevector==0)=0; %restores typevector for mask

% set the masked area to NaN as well for interpolation
u_filtered(typevector==0)=NaN;
v_filtered(typevector==0)=NaN;


%Interpolate missing data
u_filtered=inpaint_nans_fly_walk(u_filtered,2);
v_filtered=inpaint_nans_fly_walk(v_filtered,2);

utemp = u_filtered;
vtemp = v_filtered;


% reset the points with zero intensity or bad detection to NaN
u_filtered(isnan(u)) = NaN;
v_filtered(isnan(v)) = NaN;

% replace the fly masked area with the interpolated one
u_filtered(typevector==0) = utemp(typevector==0);
v_filtered(typevector==0) = vtemp(typevector==0);

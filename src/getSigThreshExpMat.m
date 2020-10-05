function [signal_threshold,mu,sigma,nfac] = getSigThreshExpMat(S,nfac,disp_detection)
%% determine the threshold
assert(any(strcmp(fieldnames(S),'expmat')),['missing field ''expmat'' in ',inputname(1)])
assert(any(strcmp(fieldnames(S),'column')),['missing field ''column'' in ',inputname(1)])
switch nargin
    case 2
        disp_detection = 0;
    case 1
        disp_detection = 0;
        nfac = 3; % mu + nfac * sigma
end
if isempty(nfac)
    nfac = 3;
end
% save this to f
if isfield(S,'col')
    col =  S.col;
else
col.fileindex = find(strcmp(S.column,'fileindex'));
col.signal = find(strcmp(S.column,'signal'));
end

theseVideos = unique(S.expmat(:,col.fileindex));
signal_threshold = zeros(size(theseVideos));
mu = zeros(size(theseVideos));
sigma = zeros(size(theseVideos));

for i = 1:length(theseVideos)
    thisVideo = theseVideos(i);
    
    sigm = S.expmat(S.expmat(:,col.fileindex)==thisVideo,col.signal);
    sigmask = S.expmat(S.expmat(:,col.fileindex)==thisVideo,col.signal_mask);
    sigm(sigmask==0) = nan;
    sigm = sigm(:);
    sigm(sigm<0) = 0;
    sigm = nonzeros(sigm);
    sigm(isnan(sigm)) = [];
    [pc,pv] = hist(sigm,0:.1:100);
    try
        [fitobj,gof] = fit(pv',pc','gauss1');
        c=coeffvalues(fitobj);
        if disp_detection
            figure
            hold on
            plot(fitobj,pv,pc)
            plot(ones(2,1)*(c(2)+nfac*c(3)),[0 max(pc)],'--g')
            title(['r^2:',num2str(gof.rsquare,'%5.2f'),' \mu:',num2str(c(2),'%5.2f'),' \sigma:',num2str(c(3),'%5.2f'),' thresh.:',num2str(c(2)+nfac*c(3),'%5.2f')])
            text(c(2)+nfac*c(3),max(pc)*.8,['\leftarrow \mu + ',num2str(nfac),'\sigma'])
            xlim([0 30])
            xlabel('pixel value')
            ylabel('count')
        end
        if gof.rsquare<.9
            disp(['bad fit will use median + ',num2str(nfac),'*sqrt(median) = ',num2str(median(sigm)+nfac*sqrt(median(sigm)))])
            signal_threshold(i) = median(sigm)+nfac*sqrt(median(sigm));
            mu(i) = median(sigm);
            sigma(i) = sqrt(median(sigm));
        else
            disp(['fit worked succesfully:  mu + ',num2str(nfac),'*sigma = ',num2str(c(2)+nfac*c(3))])
            signal_threshold(i) = c(2)+nfac*c(3);
            mu(i) = c(2);
            sigma(i) = c(3);
        end
    catch ME
        disp(ME.message)
        disp(['will use median + ',num2str(nfac),'*sqrt(mode) = ',num2str(median(sigm)+nfac*sqrt(median(sigm)))])
        signal_threshold(i) = mode(sigm) + nfac*sqrt(mode(sigm));
        mu(i) = median(sigm);
        sigma(i) = sqrt(median(sigm));
    end
end
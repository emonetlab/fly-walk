function [signal_threshold,mu,sigma,nfac] = getSigThresh(f,nfac,disp_detection)
%% determine the threshold
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
f.tracking_info.signalThreshFactor = nfac;
tin = f.tracking_info;
sigm= tin.signalm;
sigm=sigm(:);
sigm(sigm<0) = 0;

[signal_threshold,mu,sigma,nfac] = getShotNoiseThresh(sigm,nfac,disp_detection);

% sigm=nonzeros(sigm);
% sigm(isnan(sigm))=[];
% [pc,pv]=hist(sigm,0:.1:100);
% try 
%     [fitobj,gof] = fit(pv',pc','gauss1');
%     c=coeffvalues(fitobj);
%     if disp_detection
%         figure
%         hold on
%         plot(fitobj,pv,pc)
%         plot(ones(2,1)*(c(2)+nfac*c(3)),[0 max(pc)],'--g')
%         title(['r^2:',num2str(gof.rsquare,'%5.2f'),' \mu:',num2str(c(2),'%5.2f'),' \sigma:',num2str(c(3),'%5.2f'),' thresh.:',num2str(c(2)+nfac*c(3),'%5.2f')])
%         text(c(2)+nfac*c(3),max(pc)*.8,['\leftarrow \mu + ',num2str(nfac),'\sigma'])
%         xlim([0 30])
%         xlabel('pixel value')
%         ylabel('count')
%     end
%     if gof.rsquare<.9
%         disp(['bad fit will use median + ',num2str(nfac),'*sqrt(median) = ',num2str(median(sigm)+nfac*sqrt(median(sigm)))])
%         signal_threshold = median(sigm)+nfac*sqrt(median(sigm));
%         mu = median(sigm);
%         sigma = sqrt(median(sigm));
%     else
%         disp(['fit worked succesfully:  mu + ',num2str(nfac),'sigma = ',num2str(c(2)+nfac*c(3))])
%         signal_threshold = c(2)+nfac*c(3);
%         mu = c(2);
%         sigma = c(3);
%     end
% catch ME
%     disp(ME.message)
%     disp(['will use median + ',num2str(nfac),'*sqrt(median) = ',num2str(median(sigm)+nfac*sqrt(median(sigm)))])
%     signal_threshold = median(sigm)+nfac*sqrt(median(sigm));
%     mu = median(sigm);
%     sigma = sqrt(median(sigm));
% end
% 

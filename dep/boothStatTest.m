function [p,h] = boothStatTest(nboot,bootfunc,data1,data2,alpha,showPlot)
switch nargin
    case 5
        showPlot  = 'off';
    case 4
        showPlot  = 'off'; % do not show plot
        alpha = 0.05; % calculate 5% and 95% confidence interval
end

if strcmp(bootfunc,'median')
    myStatistic = @(x1,x2) median(x1)-median(x2);
elseif strcmp(bootfunc,'mean')
    myStatistic = @(x1,x2) mean(x1)-mean(x2);
elseif strcmp(bootfunc,'std')
    myStatistic = @(x1,x2) std(x1)-std(x2);
elseif strcmp(bootfunc,'var')
    myStatistic = @(x1,x2) var(x1)-var(x2);
end

n1 = length(data1);
n2 = length(data2);

% define significance function
if strcmp(bootfunc,'median')
    mySigStat = @(x) median(x(1:n1))-median(x(n1+1:end));
elseif strcmp(bootfunc,'mean')
    mySigStat = @(x) mean(x(1:n1))-mean(x(n1+1:end));
end

sampStat = myStatistic(data1,data2);
bootstrapStat = zeros(nboot,1);

for i=1:nboot
    sampX1 = data1(ceil(rand(n1,1)*n1));
    sampX2 = data2(ceil(rand(n2,1)*n2));
    bootstrapStat(i) = myStatistic(sampX1,sampX2);
end

dataComb = [data1(:);data2(:)];
bootstrapSignif = zeros(nboot,1);
for i=1:nboot
    sampX = dataComb(ceil(rand(n1+n2,1)*(n1+n2)));
    bootstrapSignif(i) = mySigStat(sampX);
end
p = sum(abs(bootstrapSignif) > abs(sampStat)) / nboot;

% Calculate the confidence interval (I could make a function out of this...)
CI = prctile(bootstrapStat,[100*alpha/2,100*(1-alpha/2)]);

%Hypothesis test: Does the confidence interval cover zero?
h = CI(1)>0 | CI(2)<0;

%Draw a histogram of the sampled statistic
if strcmp(showPlot,'on')
    figure
    xx = min(bootstrapStat):(max(bootstrapStat)-min(bootstrapStat))/10:max(bootstrapStat);
    hist(bootstrapStat,xx);
    hold on
    ylim = get(gca,'YLim');
    h1=plot(sampStat*[1,1],ylim,'y-','LineWidth',2);
    h2=plot(CI(1)*[1,1],ylim,'r-','LineWidth',2);
    plot(CI(2)*[1,1],ylim,'r-','LineWidth',2);
%     h3=plot([0,0],ylim,'b-','LineWidth',2);
    xlabel('Difference between means');

    decision = {'Fail to reject H0','Reject H0'};
    title(decision(h+1));
    legend([h1,h2],{'Sample mean',sprintf('%2.0f%% CI',100*alpha)},'Location','NorthWest');
%     legend([h1,h2,h3],{'Sample mean',sprintf('%2.0f%% CI',100*alpha),'H0 mean'},'Location','NorthWest');
end
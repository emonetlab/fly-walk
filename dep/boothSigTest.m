function [h,p,olap,c1,c2] = boothSigTest(nboot,bootfunc,data1,data2,alpha)
switch nargin
    case 4
        alpha = 0.05; % calculate 5% and 95% confidence interval
end

if strcmp(bootfunc,'median')
    myStatistic = @(x) median(x);
elseif strcmp(bootfunc,'mean')
    myStatistic = @(x) mean(x);
elseif strcmp(bootfunc,'std')
    myStatistic = @(x) std(x);
elseif strcmp(bootfunc,'var')
    myStatistic = @(x) var(x);
end

c1 = bootci(nboot,{myStatistic,data1},'alpha',alpha);
c2 = bootci(nboot,{myStatistic,data2},'alpha',alpha);

il1 = diff(c1); % interval length
il2 = diff(c2); % interval length

% do the confidence intervals overlap
if (c1(2)>=c2(1)) && (c1(1)<=c2(1)) % some overlap
    if c1(2)>=c2(2) % interval 2 is totally in 1
        olap = 2*il2/(il1+il2);
        h = 0; % do not reject the null hypothesis
    elseif c1(2)<c2(2) % partial overlap
        olap = 2*(c1(2)-c2(1))/(il1+il2);
        h = 0; % do not reject the null hypothesis
    end
elseif (c2(2)>=c1(1)) && (c2(1)<=c1(1)) % some overlap
     if c2(2)>=c1(2) % interval 1 is totally in 2
        olap = 2*il1/(il1+il2);
        h = 0; % do not reject the null hypothesis
    elseif c2(2)<c1(2) % partial overlap
        olap = 2*(c2(2)-c1(1))/(il1+il2);
        h = 0; % do not reject the null hypothesis
     end
else % no overlap
    % calculate the distance between confidence intervals
    if c1(1)>=c2(2)
        olap = (c2(2)-c1(1))/(il1+il2);
        h = 1; % reject the null hypothesis
    elseif c2(1)>=c1(2)
        olap = (c1(2)-c2(1))/(il1+il2);
        h = 1; % reject the null hypothesis
    else % itshould not reach here, chect the code
        error('it should not reach here, check the code')
        keyboard
    end
end

% estimate p as total number of poins beyond each CI
n1 = length(data1);
n2 = length(data2);

% define significance function
if strcmp(bootfunc,'median')
    mySigStat = @(x) median(x(1:n1))-median(x(n1+1:end));
elseif strcmp(bootfunc,'mean')
    mySigStat = @(x) mean(x(1:n1))-mean(x(n1+1:end));
end

dataComb = [data1(:);data2(:)];
sampStat = mySigStat(dataComb);

bootstrapSignif = zeros(nboot,1);
for i=1:nboot
    sampX = dataComb(ceil(rand(n1+n2,1)*(n1+n2)));
    bootstrapSignif(i) = mySigStat(sampX);
end
p = sum(abs(bootstrapSignif) > abs(sampStat)) / nboot;
    
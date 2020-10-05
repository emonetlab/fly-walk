function totPath = getTotPath(x,y)

assert(length(x)==length(y),'lengths of the vectors must be same')

% copy the first point and pad to begining
x(2:end+1) = x;
y(2:end+1) = y;
totPath = cumsum(sqrt(diff(x).^2+diff(y).^2),'omitnan');

end
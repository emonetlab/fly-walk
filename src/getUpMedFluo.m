function UpMedFluo = getUpMedFluo(Fluolist)    

Fluolist = sort(Fluolist);
% find the highest median value
medind = find(((Fluolist>median(Fluolist))),1); 
UpMedFluo = mean(Fluolist(medind:end));
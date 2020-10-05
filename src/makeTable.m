function T = makeTable(f,nr)

% makes a table of variables for debugging purposes
RFmode = zeros(2*numel(f.current_objects),1);
RFmedian = zeros(2*numel(f.current_objects),1);
RFmax = zeros(2*numel(f.current_objects),1);
RFmin = zeros(2*numel(f.current_objects),1);
RFUpMed = zeros(2*numel(f.current_objects),1);

for i = 1:numel(f.current_objects)
    rflist = sort(f.current_objects(i).RFlist);
%     medind = round(median(find(rflist==median(rflist)))); % get the index of the median value
    medind = find(((rflist>median(rflist))),1);
%     medind = max((find(rflist==median(rflist)))); % get the index of the median value
    RFmode(f.current_object_status(i)) = mode(rflist);
    RFmedian(f.current_object_status(i)) = median(rflist);
    RFmin(f.current_object_status(i)) = min(rflist);
    RFmax(f.current_object_status(i)) = max(rflist);
    RFUpMed(f.current_object_status(i)) = mean(rflist(medind:end));
end

T = table((1:nr)',f.reflection_meas(1:nr,f.current_frame),...
    RFUpMed(1:nr),RFmode(1:nr),RFmedian(1:nr),RFmax(1:nr),RFmin(1:nr),...
    f.reflection_overlap(1:nr,f.current_frame),...
    f.reflection_status(1:nr,f.current_frame),...
    'VariableNames',{'number' 'ref_mean' 'Up_median' 'ref_mode' 'ref_median'...
    'ref_max' 'ref_min' 'overlap' 'status'});
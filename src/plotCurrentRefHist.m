function plotCurrentRefHist(f)

figure('units','normalized','outerposition',[.05 .2 .6 .7]);
title(['frame: ',num2str(f.current_frame),' - Reflection Histograms'])
ylabel('count')
xlabel('pixel fluorescence')
hold on

overlap_thresh = f.overlap_threshold;
for  n=1:numel(f.current_objects) 
    [c,fv]=hist(f.current_objects(n).RFlist); 
    if f.reflection_status(f.current_object_status(n),f.current_frame)
        if f.reflection_overlap(f.current_object_status(n),f.current_frame)>=overlap_thresh
            ro=plot(fv,c,'g--'); % with reflection
        else
            r=plot(fv,c,'g'); % with reflection
        end
            
    else
        if f.reflection_overlap(f.current_object_status(n),f.current_frame)>=overlap_thresh
            nro=plot(fv,c,'k--'); % with reflection
        else
            nr=plot(fv,c,'k'); % with reflection
        end
    end
    
end
lh=[];
lt = [];
if ~isempty(who('ro'))
    lh = [lh,ro];
    lt = [lt,{'w/ ref + overlap'}];
end

if ~isempty(who('r'))
    lh = [lh,r];
    lt = [lt,{'w/ ref'}];
end

if ~isempty(who('nro'))
    lh = [lh,nro];
    lt = [lt,{'no ref + overlap'}];
end

if ~isempty(who('nr'))
    lh = [lh,nr];
    lt = [lt,{'no ref'}];
end
    
legend(lh,lt)

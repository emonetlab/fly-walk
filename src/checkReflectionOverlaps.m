% checkReflectionOverlaps
% if reflection of any objects falls on any fly or another verified
% reflection it registers -1 to the reflection intensity
%
function f = checkReflectionOverlaps(f)

% which objects are know to have a reflection
these_refls = find(f.reflection_status(:,f.current_frame));
% only include the flies with reflections in the mask
the_objs_with_reflection = find(sum(f.current_object_status==these_refls',2));

if isempty(these_refls)
    return
end


current_objects= f.current_objects;

% get the fly mask first
fmask = getFlyMask(f.current_raw_frame,5,0.2,f.min_fly_area);

% run over all objects and check any overlap
for i = 1:numel(current_objects)
    these_objs = the_objs_with_reflection;
    these_objs(the_objs_with_reflection==i)= []; % remove current reflection from the list
    if isempty(these_objs)
        continue
    end
    S = current_objects(these_objs);
    % cat all pixel list
    pxllist = vertcat((S.RPixelList));
    Imask = zeros(size(f.current_raw_frame)); % mask of only positive reflections
    for j = 1:length(pxllist(:,2))
        Imask(pxllist(j,2),pxllist(j,1)) = 1;
    end
    % dilate the mask
    % dilate the mask and compare
    se = strel('disk',4);
    rmask = logical(imdilate(Imask,se));
    
    % combine reflection and fly masks
    mask = (fmask+rmask);
    
    % make the reflection mask
    refpxllist = f.current_objects(i).RPixelList;
    refmask = zeros(size(f.current_raw_frame));
    if isempty(refpxllist)
        disp('in checkReflectionOverlaps line 41. fix this. not good to ignore these cases. It looks like one of the new onjects is created without reflection measurement')
        continue
    end
    for j = 1:length(refpxllist(:,2))
        refmask(refpxllist(j,2),refpxllist(j,1)) = 1;
    end
    % check the overlap
    if any(any(mask.*refmask>0))
        f.reflection_overlap(f.current_object_status(i),f.current_frame)...
            = sum(sum((mask.*refmask>0)))/sum(sum((refmask)));
        if f.reflection_overlap(f.current_object_status(i),f.current_frame)>=f.overlap_threshold
            f.reflection_status(f.current_object_status(i),f.current_frame) = f.reflection_status(f.current_object_status(i),f.current_frame-1);
            refmeas = nonzeros(f.reflection_meas(f.current_object_status(i),1:f.current_frame-1));
            f.reflection_meas(f.current_object_status(i),f.current_frame) = refmeas(end);
        end
        if f.show_ref_overlaps
            figure
            imagesc(f.current_raw_frame)
            axis image tight
            hold on
            for k = 1:size(refmask,2)
                for l = 1:size(refmask,1)
                    if refmask(l,k)
                        plot(k,l,'w.')
                    end
                end
            end
            title(['object: ',num2str(f.current_object_status(i)),' - overlap: ',num2str(sum(sum((mask.*refmask>0)))/sum(sum((refmask))),'%1.2f')])
            xlim([min(refpxllist(:,1))-40,max(refpxllist(:,1))+40])
            ylim([min(refpxllist(:,2))-40,max(refpxllist(:,2))+40])
        end

    end
end

% f.reflection_meas_scaled(f.current_object_status,f.current_frame) = ...
%     f.reflection_meas(f.current_object_status,f.current_frame)./...
%     (1-f.reflection_overlap(f.current_object_status,f.current_frame));
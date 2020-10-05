% checkReflectionOverlaps
% if reflection of any objects falls on any fly or another verified
% reflection it registers -1 to the reflection intensity
%
function f = checkThisReflectionOverlap(f,this_object)

this_curr_objs = f.current_objects;
this_curr_objs = PredRefGeom(this_curr_objs,f.ExpParam); % get reflections
this_curr_objs = measureRefInt(this_curr_objs,f.current_raw_frame); % measure reflection intensi

this_curr_obj_num = find(f.current_object_status==this_object);
this_curr_obj = this_curr_objs(this_curr_obj_num);

% get the fly mask first
fmask = getFlyMask(f.current_raw_frame);

% which objects are know to have a reflection
these_refls = find(f.reflection_status(:,f.current_frame));
if isempty(these_refls)
    return
end
% only include the flies with reflections in the mask
the_objs_with_reflection = find(sum(f.current_object_status==these_refls',2));


% go over this object and check any overlap
these_objs = the_objs_with_reflection;
these_objs(the_objs_with_reflection==this_curr_obj_num)= []; % remove current reflection from the list
if isempty(these_objs)
    return
end
S = this_curr_objs(these_objs);

% cat all pixel list
pxllist = vertcat((S.RPixelList));
Imask = zeros(size(f.current_raw_frame));
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
refpxllist = this_curr_obj.RPixelList;
refmask = zeros(size(f.current_raw_frame));
for j = 1:length(refpxllist(:,2))
    refmask(refpxllist(j,2),refpxllist(j,1)) = 1;
end
% check the overlap
if any(any(mask.*refmask>0))
    f.reflection_overlap(this_object,f.current_frame)...
        = sum(sum((mask.*refmask>0)))/sum(sum((refmask)));
    if f.reflection_overlap(this_object,f.current_frame)>=f.overlap_threshold
        f.reflection_status(this_object,f.current_frame) = f.reflection_status(this_object,f.current_frame-1);
        refmeas = nonzeros(f.reflection_meas(this_object,1:f.current_frame-1));
        if ~isempty(refmeas)
            f.reflection_meas(this_object,f.current_frame) = refmeas(end);
        end
        
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
        title(['object: ',num2str(this_object),' - overlap: ',num2str(sum(sum((mask.*refmask>0)))/sum(sum((refmask))),'%1.2f')])
        xlim([min(refpxllist(:,1))-40,max(refpxllist(:,1))+40])
        ylim([min(refpxllist(:,2))-40,max(refpxllist(:,2))+40])
    end
end

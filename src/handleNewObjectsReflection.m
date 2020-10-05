% handleNewObjectsReflection
% measures the reflections of new objects that enters to the arena and
% calculates the overlap as well
%
function f = handleNewObjectsReflection(f)

if isempty(f.frames_ref_meas)
    return
end
delete_from_list = [];
% are there any new objects entered recently
if any(f.frames_ref_meas(:,1)==f.current_frame)
    handle_these = find(f.frames_ref_meas(:,1)==f.current_frame);
    
    for i = 1:length(handle_these)
        if any(f.current_object_status==f.frames_ref_meas(handle_these(i),2))
            f = handleThisObjectsReflection(f,f.frames_ref_meas(handle_these(i),2));
            if f.ft_debug
                disp(['fly: ',num2str(f.frames_ref_meas(handle_these(i),2)),' must have entered recently. And I am measuring its reflection now.'])
                disp(' ')
            end
        else
            if f.ft_debug
                disp(['fly: ',num2str(f.frames_ref_meas(handle_these(i),2)),' must have entered recently. I want to mease its reflection, but I cannot find it.'])
                disp(' ')
            end
        end
        delete_from_list = [delete_from_list,i];
        
    end
    f.frames_ref_meas(delete_from_list,:) = []; % delete from list
    
end


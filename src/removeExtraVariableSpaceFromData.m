function f = removeExtraVariableSpaceFromData(f)
%removeExtraVarHolderSpace
%   removes the extra space in the variables allocated prior to the
%   tracking but never used.
%

% figure our how many flies have been registered
totalFlyCount = find(f.tracking_info.fly_status(:,end)~=0,1,'last');

% now clean the extra space in tracking info
totalAllocatedFlyNumber = size(f.tracking_info.x,1);

% if the extra space is already removed just quit
if totalAllocatedFlyNumber==totalFlyCount
    return
end

% get all field names in tracking info
fldnames = fieldnames(f.tracking_info);

% go over all and delete the extra if the first dimension is matches the
% total allocation number

for i = 1:numel(fldnames)
    if size(f.tracking_info.(fldnames{i}),1)==totalAllocatedFlyNumber
        % this is a variable who has extra space in teh first dimension
        % delete the space beyond row number otalFlyCount
        f.tracking_info.(fldnames{i}) = f.tracking_info.(fldnames{i})(1:totalFlyCount,:);
    end
end

% now look into the main fields in the flywalk object
fldnames = fieldnames(f);

% remove some fild names to avoid any complication
doNotTouchTheseFields = {'tracking_info','error_def','median_frame_prestim',...
    'interaction_list','crowd_interaction_list','OverS','CollS','video_frame_range',...
    'computer_guess','edited_tracks','edited_reflections','ui_handles','plot_handles',...
    'path_name','current_raw_frame','median_frame','median_frame_rand','ExpParam',...
    'current_objects','current_object_status'};

% go ahead and remove these from the filed list
for i = 1:numel(doNotTouchTheseFields)
    fldnames(strcmp(fldnames,doNotTouchTheseFields{i})) = [];
end

% now go over these filed and remove the extra space
for i = 1:numel(fldnames)
    if size(f.(fldnames{i}),1)==totalAllocatedFlyNumber
        % this is a variable who has extra space in teh first dimension
        % delete the space beyond row number otalFlyCount
        f.(fldnames{i}) = f.(fldnames{i})(1:totalFlyCount,:);
    end
end

% now remove all handles from the plotting space

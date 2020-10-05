function f = HandleJumpingFlies(f)
%HandleJumpingFlies
% Finds jumping flies, records jumping time, and determines if they land on
% the other surface (by checking the reflection)

if f.current_frame==1
    return
end

% find jumpers and add to the list
if ~isempty(findJumpingFlies(f))
    new_jumpers = findJumpingFlies(f);
    % remove colliders and overlappers
%     all_opass = [(f.tracking_info.overpassing(~isnan(f.tracking_info.overpassing(:,f.current_frame-1)),f.current_frame-1))...
%         ;(f.tracking_info.overpassing(~isnan(f.tracking_info.overpassing(:,f.current_frame)),f.current_frame))];
%     all_coll = [(f.tracking_info.collision(~isnan(f.tracking_info.collision(:,f.current_frame-1)),f.current_frame-1))...
%         ;(f.tracking_info.collision(~isnan(f.tracking_info.collision(:,f.current_frame)),f.current_frame))];
    tji = 1;
    for tj = 1:length(new_jumpers)
        if ~isempty(getInteractions(f,new_jumpers(tji)))
            new_jumpers(new_jumpers==new_jumpers(tji)) = [];
        else
            tji = tji + 1;
        end
    end
%     new_jumpers(logical(sum(new_jumpers==all_opass,1))) = [];
%     new_jumpers(logical(sum(new_jumpers==all_coll,1))) = [];
    f.current_jumpers = unique([f.current_jumpers ; new_jumpers]);
    if ~isempty(f.current_jumpers)
        if f.ft_debug
            disp(['Fly(s) ',mat2str(f.current_jumpers),' might be jumping'])
            disp(' ')
            % register the time point for these flies
             for this_jumper = (f.current_jumpers)'
                 f.tracking_info.jump_status(this_jumper,f.current_frame) = true;
             end

        end
        f.check_jump_over = true;
    end
end

% check if jumping is over, clear list, and measure the reflection of the
% object
if f.check_jump_over
    % check if any of the jumpers still in jumping process
    
    for this_jumper = (f.current_jumpers)'
        
        if any(this_jumper == findJumpingFlies(f))
            % this guys is still jumping
        else
            landed_frame = find(f.tracking_info.jump_status(this_jumper,1:f.current_frame),1,'last')+1;
            if (f.current_frame-landed_frame)==f.jump_check_frame_num % check this many frames after fly landed
                % it is over, remove from the list
                f.current_jumpers(f.current_jumpers==this_jumper) = [];
                % now handle the reflection of this fly
                f = handleThisObjectsReflection(f,this_jumper);

                if f.ft_debug
                    % if landed on the other surface display it
                    if f.reflection_status(this_jumper,f.current_frame)==f.reflection_status(this_jumper,f.current_frame-1)
                        disp(['Fly ',mat2str(this_jumper),' has landed on the same surface'])
                        disp(' ')
                    else
                        disp(['Fly ',mat2str(this_jumper),' has landed on the opposite surface'])
                        disp(' ')
                    end
                end
            end
        end
    end

    % if all of the jumpers have landed set the check
    % state to off
    if isempty(f.current_jumpers)
        f.check_jump_over = false;
    end
end
function f = smoothData(f)

% go over the interaction list and smooth the data
% x,y,heading,orientation,area,majx,minx,signal

% get interaction list
for i = 1:numel(f.crowd_interaction_list)
    cinl = f.crowd_interaction_list{i};
    start_frame_buf = cinl(1,1)-f.data_smooth_buffer;
    end_frame_buf = cinl(end,1)+f.data_smooth_buffer;
    start_frame = cinl(1,1);
    end_frame = cinl(end,1);
    
    if start_frame<1
        start_frame_buf = 1;
    end
    
    if end_frame>f.nframes
        end_frame_buf = f.nframes;
    end
    
    interacting_flies = nonzeros(unique(cinl(:,2:end)));
    for j = 1:length(interacting_flies)
        % first set the values to NaN
%         curve = smooth(f.tracking_info.x(interacting_flies(j),:),f.data_smooth_maxlen);
%         f.tracking_info.x(interacting_flies(j),start_frame:end_frame) = curve(start_frame:end_frame);
        f.tracking_info.x(interacting_flies(j),start_frame:end_frame) = smooth(f.tracking_info.x(interacting_flies(j),start_frame:end_frame),'sgolay');
% 
%         curve = smooth(f.tracking_info.y(interacting_flies(j),:),f.data_smooth_maxlen);
%         f.tracking_info.y(interacting_flies(j),start_frame:end_frame) =  curve(start_frame:end_frame);
        f.tracking_info.y(interacting_flies(j),start_frame:end_frame) = smooth(f.tracking_info.y(interacting_flies(j),start_frame:end_frame),'sgolay');
% 
%         curve = smooth(f.tracking_info.heading(interacting_flies(j),:),f.data_smooth_maxlen);
%         f.tracking_info.heading(interacting_flies(j),start_frame:end_frame) =  curve(start_frame:end_frame);
        f.tracking_info.heading(interacting_flies(j),start_frame:end_frame) = smooth(f.tracking_info.heading(interacting_flies(j),start_frame:end_frame));
% 
%         curve = smooth(f.tracking_info.orientation(interacting_flies(j),:),f.data_smooth_maxlen);
%         f.tracking_info.orientation(interacting_flies(j),start_frame:end_frame) =  curve(start_frame:end_frame);
        f.tracking_info.orientation(interacting_flies(j),start_frame:end_frame) = smooth(f.tracking_info.orientation(interacting_flies(j),start_frame:end_frame));
% 
%         curve = smooth(f.tracking_info.area(interacting_flies(j),:),f.data_smooth_maxlen);
%         f.tracking_info.area(interacting_flies(j),start_frame:end_frame) =  curve(start_frame:end_frame);
        f.tracking_info.area(interacting_flies(j),start_frame:end_frame) = smooth(f.tracking_info.area(interacting_flies(j),start_frame:end_frame));
% 
%         curve = smooth(f.tracking_info.majax(interacting_flies(j),:),f.data_smooth_maxlen);
%         f.tracking_info.majax(interacting_flies(j),start_frame:end_frame) =  curve(start_frame:end_frame);
        f.tracking_info.majax(interacting_flies(j),start_frame:end_frame) = smooth(f.tracking_info.majax(interacting_flies(j),start_frame:end_frame));
% 
%         curve = smooth(f.tracking_info.minax(interacting_flies(j),:),f.data_smooth_maxlen);
%         f.tracking_info.minax(interacting_flies(j),start_frame:end_frame) =  curve(start_frame:end_frame);
        f.tracking_info.minax(interacting_flies(j),start_frame:end_frame) = smooth(f.tracking_info.minax(interacting_flies(j),start_frame:end_frame));
% 
%         curve = smooth(f.tracking_info.signal(interacting_flies(j),:),f.data_smooth_maxlen);
%         f.tracking_info.signal(interacting_flies(j),start_frame:end_frame) =  curve(start_frame:end_frame);
        f.tracking_info.signal(interacting_flies(j),start_frame:end_frame) = smooth(f.tracking_info.signal(interacting_flies(j),start_frame:end_frame));
    end

end

% % now fill the gaps by reverse and forward suto regression
% for i = 1:find(f.tracking_info.fly_status(:,f.current_frame)==0,1)-1
% %     f.tracking_info.x(i,1:f.current_frame) = fillgaps(f.tracking_info.x(i,1:f.current_frame),f.data_smooth_maxlen);
% %     f.tracking_info.y(i,1:f.current_frame) = fillgaps(f.tracking_info.y(i,1:f.current_frame),f.data_smooth_maxlen);
% %     f.tracking_info.heading(i,1:f.current_frame) = fillgaps(f.tracking_info.heading(i,1:f.current_frame),f.data_smooth_maxlen);
% %     f.tracking_info.orientation(i,1:f.current_frame) = fillgaps(f.tracking_info.orientation(i,1:f.current_frame),f.data_smooth_maxlen);
% %     f.tracking_info.area(i,1:f.current_frame) = fillgaps(f.tracking_info.area(i,1:f.current_frame),f.data_smooth_maxlen);
% %     f.tracking_info.majax(i,1:f.current_frame) = fillgaps(f.tracking_info.majax(i,1:f.current_frame),f.data_smooth_maxlen);
% %     f.tracking_info.minax(i,1:f.current_frame) = fillgaps(f.tracking_info.minax(i,1:f.current_frame),f.data_smooth_maxlen);
% %     f.tracking_info.signal(i,1:f.current_frame) = fillgaps(f.tracking_info.signal(i,1:f.current_frame),f.data_smooth_maxlen);
%         f.tracking_info.x(i,1:f.current_frame) = fillgaps(f.tracking_info.x(i,1:f.current_frame));
%     f.tracking_info.y(i,1:f.current_frame) = fillgaps(f.tracking_info.y(i,1:f.current_frame));
%     f.tracking_info.heading(i,1:f.current_frame) = fillgaps(f.tracking_info.heading(i,1:f.current_frame));
%     f.tracking_info.orientation(i,1:f.current_frame) = fillgaps(f.tracking_info.orientation(i,1:f.current_frame));
%     f.tracking_info.area(i,1:f.current_frame) = fillgaps(f.tracking_info.area(i,1:f.current_frame));
%     f.tracking_info.majax(i,1:f.current_frame) = fillgaps(f.tracking_info.majax(i,1:f.current_frame));
%     f.tracking_info.minax(i,1:f.current_frame) = fillgaps(f.tracking_info.minax(i,1:f.current_frame));
%     f.tracking_info.signal(i,1:f.current_frame) = fillgaps(f.tracking_info.signal(i,1:f.current_frame));
% end



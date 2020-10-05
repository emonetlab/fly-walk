function f = showFlowField(f)
%showFlowField
% draws flow field arrows

if ~f.show_flowfield
    if strcmp(f.flowFieldStatus,'off')
        return
    else
        % supress the flow field
        f.plot_handles.flowField.XData = NaN;
        f.plot_handles.flowField.YData = NaN;
        f.plot_handles.flowField.UData = NaN;
        f.plot_handles.flowField.VData = NaN;
        f.flowFieldStatus = 'off';
    end
else
    if ~isfield(f.tracking_info,'PIV')
        return
    end
    f.flowFieldStatus = 'on';
    f.plot_handles.flowField.XData = f.tracking_info.PIV.x;
    f.plot_handles.flowField.YData = f.tracking_info.PIV.y;
    if strcmp(f.flowFieldMatrix,'raw')
        f.plot_handles.flowField.UData = f.tracking_info.PIV.uMatrix(:,:,f.current_frame);
        f.plot_handles.flowField.VData = f.tracking_info.PIV.vMatrix(:,:,f.current_frame);
    elseif strcmp(f.flowFieldMatrix,'filtered')
        f.plot_handles.flowField.UData = f.tracking_info.PIV.uMatrix_filt(:,:,f.current_frame);
        f.plot_handles.flowField.VData = f.tracking_info.PIV.vMatrix_filt(:,:,f.current_frame);
    end
    f.plot_handles.flowField.Color = f.flowFieldColor;
    f.plot_handles.flowField.AutoScaleFactor = f.flowFieldScaleFactor;
end
function f = showPIVMask(f)
%showPIVMask
% shows the piv masks of the flies used to eliminate fly intensity during
% PIV calculation
%

if ~f.show_pivmask
    if strcmp(f.pivMaskStatus,'off')
        return
    else
        % supress all of the masks
        for i = 1:numel(f.plot_handles.pivMask)
            f.plot_handles.pivMask(i).XData = NaN;
            f.plot_handles.pivMask(i).YData = NaN;
            f.pivMaskStatus = 'off';
        end
    end
else
    if ~isfield(f.tracking_info,'PIV')
        return
    end
    f.pivMaskStatus = 'on';
    
    % generate piv mask coordinates
    parameters = f.tracking_info.PIV.parameters;
    diln = parameters.diln;
    thresh = parameters.thresh;
    minObjSize = parameters.minObjSize;
    camera = parameters.camera;
    if f.current_frame ==1
        frm1 = 1;
    else
        frm1 = f.current_frame-1;
    end
    A = double((f.path_name.frames(:,:,frm1)-f.ExpParam.bkg_img).*uint8(f.ExpParam.mask)-f.median_frame_prestim)./f.ExpParam.FlatNormImage;
    B = double((f.path_name.frames(:,:,f.current_frame)-f.ExpParam.bkg_img).*uint8(f.ExpParam.mask)-f.median_frame_prestim)./f.ExpParam.FlatNormImage;
    [mask,~] = getFlyNRefMask((A+B)/2,camera,diln,thresh,minObjSize);
    [polyBoundary,~] = mask2polyBoundary(mask);
    
    % update the plot
    if ~isempty(polyBoundary)
        f.plot_handles.pivMask.XData = polyBoundary(:,1);
        f.plot_handles.pivMask.YData = polyBoundary(:,2);
        f.plot_handles.pivMask.Color = f.pivMaskColor;
    end
end









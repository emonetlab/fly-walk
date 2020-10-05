function S = measureRefInt(S,I)


for Snum = 1:(numel(S))
    
    % Generate coordinates for reflection:
    % Generate the pixel list for antenna location (which spans an elliptical
    % region):
    xymat_ref = ellips_matrix_reflections(S(Snum).RMin/2,S(Snum).RMaj/2,S(Snum).Orientation,S(Snum).RX(1),S(Snum).RX(2));
    
    % record this pixel list
    S(Snum).RPixelList = xymat_ref; 
    
    % should return NaN if not measured
    
    % Eliminate the pixels from the antenna which do not correspond to real 
    %  pixels inside the frame:
    [imyl,imxl]=size(I); % image limits
    xymat_ref = SetXYMatConst(xymat_ref,[1,imxl,1,imyl]);
%     plot(xymat_ref(:,1),xymat_ref(:,2),'o')
    if isempty(xymat_ref)
        S(Snum).RFluo = NaN;
    else
        [~,S(Snum).RFlist] = fluo_of_ellips_mask_f(xymat_ref,I);  % Get fluorescence on the reflection, use this for mean fluo 
        S(Snum).RFluo =  getUpMedFluo(S(Snum).RFlist); % register the mean fluorescence for the pixels above median fluorescence
    end
end
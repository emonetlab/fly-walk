function cam = findCam(frame,showdetected,usehisteq,threshold,radrange,crop_box)
switch nargin
    case 6
    case 5
        crop_box.lcrp = 0;
        crop_box.rcrp = 0;
        crop_box.tcrp = 0;
        crop_box.bcrp = 0;
    case 4
        crop_box.lcrp = 0;
        crop_box.rcrp = 0;
        crop_box.tcrp = 0;
        crop_box.bcrp = 0;
        radrange = [30 70]; % pxl
    case 3
        crop_box.lcrp = 0;
        crop_box.rcrp = 0;
        crop_box.tcrp = 0;
        crop_box.bcrp = 0;
        radrange = [30 70]; % pxl
        threshold = 0.16;
    case 2
        crop_box.lcrp = 0;
        crop_box.rcrp = 0;
        crop_box.tcrp = 0;
        crop_box.bcrp = 0;
        radrange = [30 70]; % pxl
        threshold = 0.16;
        usehisteq = 0; % do not use histogram equalization
    case 1
        crop_box.lcrp = 0;
        crop_box.rcrp = 0;
        crop_box.tcrp = 0;
        crop_box.bcrp = 0;
        radrange = [30 70]; % pxl
        threshold = 0.16;
        usehisteq = 0; % do not use histogram equalization
        showdetected = 0;
    case 0
        error('not enough input arguments')
end
        crpx = 1+crop_box.lcrp:size(frame,2)-crop_box.rcrp;
        crpy = 1+crop_box.tcrp:size(frame,1)-crop_box.bcrp;
        framemask = zeros(size(frame));
        framemask(crpy,crpx) = 1;
        frame = uint8(double(frame).*framemask);
        if usehisteq
            frame2t = histeq(frame);
        else
            frame2t = frame;
        end
        bw = im2bw(frame2t,threshold);


        % remove all object containing fewer than 5000 pixels
        bw = bwareaopen(bw,5000);
        if showdetected
            h = figure('units','normalized','outerposition',[0 0 .8 1]);
            subtightplot(2,2,1)
            imagesc(frame);
            axis image
            title('original image')
            subtightplot(2,2,2)
            imagesc(bw);
            axis image
            title('thresholded and cleaned')
        end

        % fill a gap in the pen's cap
        se = strel('disk',2);
        bw = imclose(bw,se);
        if showdetected
            figure(h);
            subtightplot(2,2,3)
            imagesc(bw);
            axis image
            title('gaps filled')
        end

        % fill any holes, so that regionprops can be used to estimate
        % the area enclosed by each of the boundaries
        bw = imfill(bw,'holes');
        if showdetected
            figure(h);
            subtightplot(2,2,4)
            imagesc(bw);
            axis image
            title('holes filled')
        end

        % find circular objects
        % assume camera radius between 7mm and 10mm
        [centers, radii] = imfindcircles(bw,round(radrange));

        % if there is only one detected plot it
        if length(radii) ==1

            if showdetected
                figure(h);
                subtightplot(2,2,1)
                imagesc(frame);
                viscircles(centers,radii,'LineStyle',':');
                axis image
                title('original image + detected camera')
                axis equal
                axis tight
            end
            cam.x = centers(1,1);
            cam.y = centers(1,2);
            cam.rad = radii;

        else
            cam = [];
        end
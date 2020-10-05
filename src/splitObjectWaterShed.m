% splits an object
% using watershed
% celan_image: the frame to be worked on
% r0: the structure which contains the centroid and area information for
% the object of interest
function [f,split_objects,crf] = splitObjectWaterShed(f,this_object,to_how_many)

if nargin ==2
    to_how_many = 2; % try to get 2 object out of this
end

% get boxs and images of all the objects in the frame
r = getAllObjectsInFrame(f);
crf = f.current_raw_frame;

% get the object of the interest
r = r(this_object);

go_on = 1;
iter = 1;
epuplim = 10;
epdownlim = .01;
extend_param = 0.5;

max_iter = 100;


while (go_on)&&(iter<max_iter)
    iter = iter + 1;
    
    % distance transform
    D = -bwdist(~r.Image);
    
    % make a mask out of it 
    mask = imextendedmin(D,extend_param,4);

    % impose these minima and watershed
    D2 = imimposemin(D,mask);
    Ld2 = watershed(D2);
    bw3 = r.Image;
    bw3(Ld2 == 0) = 0;
    

    
    % get new objects and count
%     rn = regionprops(bw3,{'Area','Centroid','Orientation'});
    rn = regionprops(bw3,f.regionprops_args);
    
    if numel(rn)>to_how_many
        epdownlim = extend_param;
        extend_param = (epdownlim + epuplim)/2;
    elseif numel(rn)<to_how_many
        epuplim = extend_param;
        extend_param = (epdownlim + epuplim)/2;
    elseif numel(rn)==to_how_many
        go_on = 0;
        if f.ft_debug
            disp(['The object #:',num2str(this_object),' at x:',...
                num2str(round(f.current_objects(this_object).Centroid(1))),...
                ' y=',num2str(round(f.current_objects(this_object).Centroid(2))),...
                ' is split in to ', num2str(to_how_many),' flies by watershed'])
        end
        % show shed on current frame
        
        crf_ws = crf;
%         indws = ~(Ld2 == 0);
        bb=round(r.BoundingBox);
%         crfprop = whos('crf');
%         if strcmp(crfprop.class,'double')
%             crf_ws(bb(2):bb(2)+bb(4)-1,bb(1):bb(1)+bb(3)-1) = crf(bb(2):bb(2)+bb(4)-1,bb(1):bb(1)+bb(3)-1).*uint8(indws);
%         else
        crf_crop = crf(bb(2):bb(2)+bb(4)-1,bb(1):bb(1)+bb(3)-1);
        crf_crop(Ld2 == 0) = 1; %min(min(crf));
        crf_ws(bb(2):bb(2)+bb(4)-1,bb(1):bb(1)+bb(3)-1) = crf_crop;
%         crf_ws(bb(2):bb(2)+bb(4)-1,bb(1):bb(1)+bb(3)-1) = crf(bb(2):bb(2)+bb(4)-1,bb(1):bb(1)+bb(3)-1).*(indws);
        f.current_raw_frame = crf_ws;
    end
end

if f.show_split
    figure('units','normalized','outerposition',[.2 .1 .8 .8]);
    subplot(2,3,1)
    imshow(r.Image);
    axis image
    title('original')

    subplot(2,3,2)
    imshow(D,[])
    axis image
    title('distance conversuion')

    subplot(2,3,3)
    imshowpair(r.Image,mask,'blend')
    title('extend minimum')

    subplot(2,3,4)
    Ld = watershed(D);
    imshow(label2rgb(Ld))
    title('watershed on DC')

    subplot(2,3,5)
    bw2 = r.Image;
    bw2(Ld == 0) = 0;
    imshow(bw2)
    title('watershed DC OI')

    subplot(2,3,6)
    imshow(bw3)
    title('watershed')
end

if (iter>=max_iter)&&f.ft_debug
    split_objects = [];
        disp(['watershed failed for the object #:',num2str(this_object),' at x:',...
            num2str(round(f.current_objects(this_object).Centroid(1))),...
            ' y=',num2str(round(f.current_objects(this_object).Centroid(2)))])
    return
end
      

split_objects = rn;
% inherit everything
for j = 1:to_how_many
    split_objects(j).Centroid(1) = split_objects(j).Centroid(1) + r.BoundingBox(1) ;
    split_objects(j).Centroid(2) = split_objects(j).Centroid(2) + r.BoundingBox(2);
    split_objects(j).Orientation = mod(-split_objects(j).Orientation,360); % this is weird, why is it this way
    
end

if isfield(f.current_objects,'RFluo') % measure the reflections for these flies as well
    
    if f.fillNmeasure
        raw_image = fillFlies(f.current_raw_frame);
    else
        raw_image = f.current_raw_frame;
    end
    
    % get and measure reflections
    split_objects = PredRefGeom(split_objects,f.ExpParam); % get reflections
    split_objects = measureRefInt(split_objects,raw_image); % measure reflection intensity
end
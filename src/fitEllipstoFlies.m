% fits ellipses to the given object. 
% raw image is cropped accourding to the object bounding box then resized
% 10 times for better edge detection. Edges are detected with 'canny'
% method. Ellipses are fit through Hough transform. The fittinng parameters
% are constrained using the known fly parameters such as major, minor axis,
% orientation and position
% the fit code is modified from Martin Simonovsky's Ellipse detection
%
% Returns a matrix of best fits. Each row (there are params.numBest of them) contains six elements:
% [x0 y0 a b alpha score] being the center of the ellipse, its major and minor axis, its angle in degrees and score.
%

function [split_objects,bestFits] = fitEllipstoFlies(f,this_object,these_flies)
% get boxs and images of all the objects in the frame
r = getAllObjectsInFrame(f);

% get the object of the interest
r = r(this_object);
bb=(r.BoundingBox);
% setFigure;imagesc(r.Image)

% 8 bit image
% crf = f.current_raw_frame;
% bb=round(r.BoundingBox);
% image = crf(bb(2):bb(2)+bb(4)-1,bb(1):bb(1)+bb(3)-1);
resize_size = 10;
pad_size = 1;
disp_tol = 2;
E = edge(imresize(padarray(r.Image,[pad_size,pad_size]),resize_size),'canny');
pxl = zeros(length(find(E==1)),2);
cnt =1;
for i = 1:size(E,2)
    for j = 1:size(E,1)
        if E(j,i)
            pxl(cnt,:) = [j,i];
            cnt = cnt + 1;
        end
    end
end
   
% feed the know parameters with some estimations and get ask the best fits
nfit = 1000;
max_iter = 1e5;
bestFits= NaN(length(these_flies),6);
xy = zeros(length(these_flies),2);
for flynum = 1:length(these_flies)
    
    this_fly = these_flies(flynum);
    % override some default parameters
    minax = f.tracking_info.minax(this_fly,f.current_frame-1);
    majax = f.tracking_info.majax(this_fly,f.current_frame-1);
    xy(flynum,:) = [f.tracking_info.x(this_fly,f.current_frame-1),f.tracking_info.y(this_fly,f.current_frame-1)];
    theta = f.tracking_info.orientation(this_fly,f.current_frame-1);
    params.minMinorAxis = round(minax*(1-f.ellips_fit_tolerance)*resize_size);
    params.maxMinorAxis = round(minax*(1+f.ellips_fit_tolerance)*resize_size);
    params.minMajorAxis = round(majax*(1-f.ellips_fit_tolerance)*resize_size);
    params.maxMajorAxis = round(majax*(1+f.ellips_fit_tolerance)*resize_size);
    params.rotation = theta;
    params.rotationSpan = 30;
    params.minAspectRatio = .2;
    params.numBest = nfit;
    % note that the edge (or gradient) image is used
    bestFitsMat = ellipseDetection(E, params);
    
    % rescale the values
    % reset the values to normal scale
    bestFitsMat(:,1:4) = bestFitsMat(:,1:4)./resize_size;
    bestFitsMat(:,1:2) = bestFitsMat(:,1:2)-pad_size;
    % assumes half major axis
    bestFitsMat(:,3:4) = bestFitsMat(:,3:4)*2;
    
    % get the best matches from this list
    go_on = 1;
    iter = 0;
    tol = f.ellips_fit_tolerance;
    dist_vec = sqrt((bestFitsMat(:,1)-(xy(flynum,1)-bb(1))).^2+(bestFitsMat(:,2)-(xy(flynum,2)-bb(2))).^2);
    while go_on
        
        inds = (bestFitsMat(:,3)>(majax*(1-tol))).*(bestFitsMat(:,3)<(majax*(1+tol)));
        inds = inds.*(bestFitsMat(:,4)>(minax*(1-tol))).*(bestFitsMat(:,4)<(minax*(1+tol)));
       
        % fly should not move more than a half body size
        % estimate the distance vector
        inds = inds.*(dist_vec<(majax/disp_tol));
        these_fits = find(inds);
        
        if isempty(these_fits)
            tol = tol*1.03;     % increase the tolerance 1%
        elseif length(these_fits)<=3
            go_on = 0;
            bestFits(flynum,:) = bestFitsMat(these_fits(1),:);
            if f.ft_debug
                disp(['Fly: ',num2str(these_flies(flynum)),' reached to a reasonable ellips fit in ',num2str(iter),' iterations'])
            end
            
        else
            tol = tol*.97;  % decrease the tolerance by 1%
        end
        iter = iter + 1;
        if iter==max_iter
            go_on = 0;
            if f.ft_debug
                disp(['Could not find a good ellips fit in ',num2str(max_iter),' iterations'])
            end
            split_objects = [];
        end
    end
end
            
if f.show_split
    
    setFigure;
    subplot(1,2,1)
    imagesc(padarray(r.Image,[pad_size,pad_size]))
    axis image
    title(['Interacting Flies: ',mat2str(these_flies)])
   
    subplot(1,2,2)
    imagesc((1:size(E,2)/resize_size)-1,(1:size(E,1)/resize_size)-1,E);
    hold on
    %ellipse drawing implementation: http://www.mathworks.com/matlabcentral/fileexchange/289 
    clrvec = {'k','r','b','g','m','c','k--','r--','b--','g--','m--','c--'};
    for flynum = 1:length(these_flies)
        plot(xy(flynum,1)-bb(1),xy(flynum,2)-bb(2),[clrvec{flynum},'o'],'MarkerSize',5);
        text(xy(flynum,1)-bb(1)+1,xy(flynum,2)-bb(2)-1,num2str(these_flies(flynum)),'color',clrvec{flynum})
        ellipse(bestFits(flynum,3)/2,bestFits(flynum,4)/2,bestFits(flynum,5)*pi/180,bestFits(flynum,1),bestFits(flynum,2),clrvec{flynum});
    end
    axis image
    title('Edge Mask & Fits')
end

bestFits(:,1) = bestFits(:,1) + bb(1);
bestFits(:,2) = bestFits(:,2) + bb(2);


split_objects(length(these_flies),1).Area = NaN;


% make the splitted objects
if ~any(sum(isnan(bestFits),1))
    for flynum = 1:length(these_flies)
        % make 2 new imaginary objects and delete the overlapping guy
        split_objects(flynum).Area = NaN;
        split_objects(flynum).Centroid = [bestFits(flynum,1),bestFits(flynum,2)];
        split_objects(flynum).MajorAxisLength = bestFits(flynum,3); % assume average major length
        split_objects(flynum).MinorAxisLength = bestFits(flynum,4); % assume average minor length
        split_objects(flynum).Orientation = bestFits(flynum,5);

        % label other fly as missing too, and overlapping
        f.tracking_info.fly_status(abs(these_flies(flynum)),f.current_frame) = 2;
    end
end









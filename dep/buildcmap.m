function [cmap]=buildcmap(colors)
% [cmap]=buildcmap(colors)
%
% This function can be used to build your own custom colormaps. Imagine if
% you want to display rainfall distribution map. You want a colormap which
% ideally brings rainfall in mind, which is not achiveved by colormaps such
% as winter, cool or jet and such. A gradient of white to blue will do the
% task, but you might also use a more complex gradient (such as
% white+blue+red or colors='wbr'). This function can be use to build any
% colormap using main colors rgbcmyk. In image processing, w (white) can be
% used as the first color so that in the output, the background (usually
% with 0 values) appears white. In the example of rainfall map, 'wb' will
% produce a rainfall density map where the background (if its DN values are
% 0) will appear as white.
%
% Inputs:
%  colors: string (char) of color codes, any sequence of rgbcmywk
%  representing different colors (such as 'b' for blue) is acceptable. If a
%  gradient of white to blue is needed, colors would be 'wb'; a rainbow of
%  white+blue+red+green would be 'wbrg'.
%  - Alternatively -
%  colors: cell of color codes, any sequence of rgbcmywk or color
%  definitions in wikipedia: https://en.wikipedia.org/wiki/List_of_colors_by_shade
%  are acceptable. built in color definitions (such as 'b' for blue has to
%  listed seperately. Example:
%  colors = {'w','b','red','amber','k'}
%
% Example:
%  [cmap]=buildcmap('wygbr');
% %try the output cmap:
% im=imread('cameraman.tif');
% imshow(im), colorbar
% colormap(cmap) %will use the output colormap
%
% First version: 14 Feb. 2013
% sohrabinia.m@gmail.com
%
% mahmut demir modified it on 12.13.2018 to incorporate with teh colors
% listed on wikipedia
% http://en.wikipedia.org/wiki/List_of_colors
% https://en.wikipedia.org/wiki/List_of_colors_by_shade
%--------------------------------------------------------------------------

if nargin<1
    colors='wrgbcmyk';
end

if iscell(colors)
    
    ncolors=numel(colors)-1;
    
    
    bins=round(255/ncolors);
    % diff1=255-bins*ncolors;
    
    vec=zeros(300,3);
    
    vec(1,:) = getColorLetterRGB(colors{1});
    
    for i=1:ncolors
        beG=(i-1)*bins+1;
        enD=i*bins+1; %beG,enD
        cval = getColorLetterRGB(colors{i+1});
        vec(beG:enD,1)=linspace(vec(beG,1),cval(1),bins+1)';
        vec(beG:enD,2)=linspace(vec(beG,2),cval(2),bins+1)';
        vec(beG:enD,3)=linspace(vec(beG,3),cval(3),bins+1)';%colors(i+1),beG,enD,
    end
    cmap=vec(1:bins*ncolors,:);
    

elseif ischar(colors)
    
    ncolors=length(colors)-1;
    
    
    bins=round(255/ncolors);
    % diff1=255-bins*ncolors;
    
    vec=zeros(300,3);
    
    vec(1,:) = getColorLetterRGB(colors(1));
   
    for i=1:ncolors
        beG=(i-1)*bins+1;
        enD=i*bins+1; %beG,enD
        cval = getColorLetterRGB(colors(i+1));
        vec(beG:enD,1)=linspace(vec(beG,1),cval(1),bins+1)';
        vec(beG:enD,2)=linspace(vec(beG,2),cval(2),bins+1)';
        vec(beG:enD,3)=linspace(vec(beG,3),cval(3),bins+1)';%colors(i+1),beG,enD,
    end
    cmap=vec(1:bins*ncolors,:);
end
end %end of buildcmap

function RGBVal = getColorLetterRGB(colorName)

% is the color name a single letter
 if length(colorName)==1

    switch colorName
        case 'w'
            RGBVal=1;
        case 'r'
            RGBVal=[1 0 0];
        case 'g'
            RGBVal=[0 1 0];
        case 'b'
            RGBVal=[0 0 1];
        case 'c'
            RGBVal=[0 1 1];
        case 'm'
            RGBVal=[1 0 1];
        case 'y'
            RGBVal=[1 1 0];
        case 'k'
            RGBVal=[0 0 0];
    end
    
 elseif length(colorName)>1
     % do a search
      RGBVal = WikiColorDefs(colorName);
 
 else
     error('Any invidual color name should not be empty')
 end
     
    
end
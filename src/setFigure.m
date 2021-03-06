function varargout = setFigure(dimensions,units)
%setFigure
% varargout = setFigure(dimensions,units)
% opens an empty figure and sets the paper size accordingly so that figure
% saving becomes easy.
% Examples:
%
% setFigure opens a figure of size same as Nature single column width and
% half page depth.
%
% h = setFigure([.1 .1 .5 .5]) or h = SetFigure('half') opens a figure of
% half size of the screen. Units are normalized. Passes figure handle to h.
%
% setFigure('full') opens a figure whose size is equal to the whole
% display.
%
% setFigure([89 247]) opens a figure with Nature single column width and
% half page depth. Sets units to mm. It is generated by simply calling the
% function itself: setFigure, or setFigure('NatSingleHalf'). Same result
% for 'NSH', or, 'nsh'
%
% setFigure('NatSingleFull') opens an empty figure with Nature single column
% full page length. Same result for 'NSF', or, 'nsf'
%
% setFigure('NatDoubleHalf') opens an empty figure with Nature Double column
% half page length. For full page length pass instead 'NatDoubleFull'. Same
% result for 'NDH', or, 'ndh'
%
% setFigure('NatSingleX') creates an empty figure with nature single column
% and X times the half page length. Same result for 'NSX', or, 'nsx'
%
% setFigure('NatDoubleX') creates an empty figure with nature double column
% and X times the half page length. Same result for 'NDX', or, 'ndx'
%
% setFigure([100 300],'mm') opens a figure 100 x 300 mm (width x depth)
%
% Code is not case sensitive. Any combination of lower and upper case works
% as long as the speeling is correct: NatSingleFull = natSingleFull =
% NatSINGLEFull = nsf = NSF = Nsf = nSF
%
% For Neuron: 1 column, 85 mm; 1.5 column, 114 mm; and 2 column, 174 mm
% (the full width of the page).
%
% written by Mahmut Demir
%

switch nargin
    case 2
        % parse and fix units
        switch units
            case 'mm'
                units = 'centimeters';
                multfact = 1/10;
            case 'millimeter'
                units = 'centimeters';
                multfact = 1/10;
            case 'millimeters'
                units = 'centimeters';
                multfact = 1/10;
            case 'cm'
                units = 'centimeters';
                multfact = 1;
            case 'centimeter'
                units = 'centimeters';
                multfact = 1;
            case 'inches'
                multfact = 1;
            case 'normalized'
                multfact = 1;
            case 'points'
                multfact = 1;
            case 'pixels'
                multfact = 1;
            otherwise
                disp([units,' is not a valid value. Use one of these values: inches | centimeters | characters | normalized | points | pixels.'])
                error('Error using setFigure')
        end
    case 1
        units = 'normalized';
        multfact = 1;
    case 0
        units = 'cm';
        multfact = 1;
        dimensions = 'NatSingleHalf';
end

%% get mmppxl and incppxl
set(0,'units','pixels')
PixelPerInch = get(0,'ScreenPixelsPerInch');
PixelPerMm = PixelPerInch/25.4;
ScrnSizePxl = get(0,'ScreenSize');
ScreenSizeJawa = java.awt.Toolkit.getDefaultToolkit;
ScreenSizeJawa = ScreenSizeJawa.getScreenSize();
ScreenWidthJawa = ScreenSizeJawa.getWidth;
ScreenHeightJawa = ScreenSizeJawa.getHeight;
HeightDiffPixel = ScrnSizePxl(4)-ScreenHeightJawa;
WidthDiffPixel = ScrnSizePxl(3)-ScreenWidthJawa;
% jawa is more relibale
if any(ScrnSizePxl(3:4)~=[ScreenWidthJawa,ScreenHeightJawa])
    ScrnSizePxl(3:4) = [ScreenWidthJawa,ScreenHeightJawa];
end


if isnumeric(dimensions) % numeric size is requested
    if (length(dimensions)==2) % only width and depth is given
        if nargin==1
            units = 'centimeters'; % default units for width and depth request is mm
            multfact = 1/10;
        end
        % contruct the full figure position
        dimensions(3:4) = dimensions;
        dimensions(1) = (ScrnSizePxl(3)/PixelPerMm-dimensions(3))/2;
        dimensions(2) = (ScrnSizePxl(4)/PixelPerMm-dimensions(4))*1.5/5;
    elseif (length(dimensions)==4) % full figure positions are given
    else
        error('wrong figure size')
    end
elseif ischar(dimensions) % specified fixed figure sizes
    if strcmpi(dimensions,'full')
        dimensions = [0 0 1 1];
        units = 'normalized';
    elseif strcmpi(dimensions,'half')
        dimensions = [.25 .25 .5 .5];
        units = 'normalized';
    elseif strcmpi(dimensions,'NatSingleFull')
        xo = (ScrnSizePxl(3)/PixelPerMm-89)/2;
        yo = (ScrnSizePxl(4)/PixelPerMm-247)*4/5;
        dimensions = [xo yo 89 247]/10;
        units = 'centimeters';
    elseif strcmpi(dimensions,'NSF')
        xo = (ScrnSizePxl(3)/PixelPerMm-89)/2;
        yo = (ScrnSizePxl(4)/PixelPerMm-247)*4/5;
        dimensions = [xo yo 89 247]/10;
        units = 'centimeters';
    elseif strcmpi(dimensions,'NatSingleHalf')
        xo = (ScrnSizePxl(3)/PixelPerMm-89)/2;
        yo = (ScrnSizePxl(4)/PixelPerMm-247/2)*4/5;
        dimensions = [xo yo 89 247/2]/10;
        units = 'centimeters';
    elseif strcmpi(dimensions,'NSH')
        xo = (ScrnSizePxl(3)/PixelPerMm-89)/2;
        yo = (ScrnSizePxl(4)/PixelPerMm-247/2)*4/5;
        dimensions = [xo yo 89 247/2]/10;
        units = 'centimeters';
    elseif strcmpi(dimensions,'NatDoubleFull')
        xo = (ScrnSizePxl(3)/PixelPerMm-183)/2;
        yo = (ScrnSizePxl(4)/PixelPerMm-247)*4/5;
        dimensions = [xo yo 183 247]/10;
        units = 'centimeters';
    elseif strcmpi(dimensions,'NDF')
        xo = (ScrnSizePxl(3)/PixelPerMm-183)/2;
        yo = (ScrnSizePxl(4)/PixelPerMm-247)*4/5;
        dimensions = [xo yo 183 247]/10;
        units = 'centimeters';
    elseif strcmpi(dimensions,'NatDoubleHalf')
        xo = (ScrnSizePxl(3)/PixelPerMm-183)/2;
        yo = (ScrnSizePxl(4)/PixelPerMm-247/2)*4/5;
        dimensions = [xo yo 183 247/2]/10;
        units = 'centimeters';
    elseif strcmpi(dimensions,'NDH')
        xo = (ScrnSizePxl(3)/PixelPerMm-183)/2;
        yo = (ScrnSizePxl(4)/PixelPerMm-247/2)*4/5;
        dimensions = [xo yo 183 247/2]/10;
        units = 'centimeters';
    else
        if strcmpi(dimensions(1:2),'NS')||strcmpi(dimensions(1:2),'ND')
            if numel(strsplit(dimensions(3:end),'-'))==0
                PageLenMult = 1; % get the half page size by default
                PageWidthMult = 1; % do not resize the width
            elseif numel(strsplit(dimensions(3:end),'-'))==1 % modifiy only the length
                PageLenMult = str2num(dimensions(3:end)); % get the half page size by default
                PageWidthMult = 1; % do not resize the width
            elseif numel(strsplit(dimensions(3:end),'-'))==2 % modify both the length and the width
                WidthLen = strsplit(dimensions(3:end),'-');
                PageLenMult = str2num(WidthLen{2}); % length modify factor
                PageWidthMult = str2num(WidthLen{1}); % width modify factor
            end
            if strcmpi(dimensions(1:2),'NS')
                xo = (ScrnSizePxl(3)/PixelPerMm-89*PageWidthMult)/2;
                yo = (ScrnSizePxl(4)/PixelPerMm-247*PageLenMult/2)*2/5;
                dimensions = [xo yo 89*PageWidthMult 247/2*PageLenMult]/10;
            elseif strcmpi(dimensions(1:2),'ND')
                xo = (ScrnSizePxl(3)/PixelPerMm-183*PageWidthMult)/2;
                yo = (ScrnSizePxl(4)/PixelPerMm-247/2*PageLenMult)*2/5;
                dimensions = [xo yo 183*PageWidthMult 247/2*PageLenMult]/10;
            end
            
        elseif strcmpi(dimensions(1:9),'NatSingle')||strcmpi(dimensions(1:9),'NatDouble')
            if numel(strsplit(dimensions(10:end),'-'))==0
                PageLenMult = 1; % get the half page size by default
                PageWidthMult = 1; % do not resize the width
            elseif numel(strsplit(dimensions(10:end),'-'))==1 % modifiy only the length
                PageLenMult = str2num(dimensions(10:end)); % get the half page size by default
                PageWidthMult = 1; % do not resize the width
            elseif numel(strsplit(dimensions(10:end),'-'))==2 % modify both the length and the width
                WidthLen = strsplit(dimensions(10:end),'-');
                PageLenMult = str2num(WidthLen{2}); % length modify factor
                PageWidthMult = str2num(WidthLen{1}); % width modify factor
            end
            if strcmpi(dimensions(1:9),'NatSingle')
                xo = (ScrnSizePxl(3)/PixelPerMm-89*PageWidthMult)/2;
                yo = (ScrnSizePxl(4)/PixelPerMm-247*PageLenMult/2)*2/5;
                dimensions = [xo yo 89*PageWidthMult 247/2*PageLenMult]/10;
            elseif strcmpi(dimensions(1:9),'NatDouble')
                xo = (ScrnSizePxl(3)/PixelPerMm-183*PageWidthMult)/2;
                yo = (ScrnSizePxl(4)/PixelPerMm-247/2*PageLenMult)*2/5;
                dimensions = [xo yo 183*PageWidthMult 247/2*PageLenMult]/10;
            end
        end
        units = 'centimeters';
        ScreenSizeCentiMeter = ScrnSizePxl/PixelPerMm/10;
        HeightDiffCM = HeightDiffPixel/PixelPerMm/10;
        WidthtDiffCM = WidthDiffPixel/PixelPerMm/10;
        % offset dimensions
        dimensions(1:2) = dimensions(1:2) + [WidthtDiffCM,HeightDiffCM]; 
        
    end
    multfact = 1;
end
% avoid any negative dimensions
% dimensions(dimensions<0) = 0;
% work on the oversize diemntsion
% OverSizeDims = ScreenSizeCentiMeter(3:4)<dimensions(3:4);
% for i = 1:length(OverSizeDims)
%     if OverSizeDims(i)
%         dimensions(i) = ScreenSizeCentiMeter(2+i)-dimensions(2+i);
%     end
% end
fig = figure('units',units,'position',dimensions*multfact);
fig.PaperSize = fig.OuterPosition(3:4);
fig.Color = 'w'; % background color

if nargout
    varargout = {fig};
end
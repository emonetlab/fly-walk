function [R,T,indx] = BinAngle(angle,nbins,angoffset)
% bins angles by nbins many bins between zero and 2*pi
% all inputs must be radians

if any(angle>2*pi)
    disp('WARNING: Make sure that all angles are in radians')
end

% set all angles between 0 to 2pi
angle = mod(angle,2*pi);
switch nargin
    case 2
        angoffset = -2*pi/nbins/2; % center around zero
    case 1
        nbins = 36; % BINS OF 10 DEGREES
        angoffset = -2*pi/nbins/2; % center around zero
end

% if ofset is same as bin size set to zero
if abs(angoffset)==(2*pi/nbins)
    angoffset = 0;
end

if angoffset==0
    if isscalar(nbins)
        Tedge = linspace(angoffset,2*pi+angoffset,nbins+1);
        Tedges = Tedge;
        Tedge(end)= [];
        Tbinc = zeros(size(Tedge));
        Tedgecs = circshift(Tedge,1);
        for i = 1:length(Tedge)
            Tbinc(i) = (angleDiff(Tedgecs(i),Tedge(i)))/2+Tedgecs(i);
        end
        Tbinc = circshift(Tbinc,-1);
        Tbinc = mod(Tbinc,2*pi);
        % set bin numbers
        % at zero angle ofsett it is one to one
        Tbinnum = 1:length(Tbinc);
    else
        Tedge = nbins;
        Tedges = Tedge;
        Tedge(end)= [];
        Tbinc = zeros(size(Tedge));
        Tedgecs = circshift(Tedge,1);
        for i = 1:length(Tedge)
            Tbinc(i) = (angleDiff(Tedgecs(i),Tedge(i)))/2+Tedgecs(i);
        end
        Tbinc = circshift(Tbinc,-1);
        Tbinc = mod(Tbinc,2*pi);
        %         Tedges = mod(Tedges,2*pi);
    end
    
    % now go over all bins and counts the angles and get the indexes
    if nargout==3
        [R,~,indx] =histcounts(angle,Tedges);
    else
        [R,~,~] = histcounts(angle,Tedges);
    end
    
    % take Tbinc out
    T = Tbinc;
    
else
    if isscalar(nbins)
        Tedge = linspace(angoffset,2*pi+angoffset,nbins+1);
        Tedges = Tedge;
        if angoffset<0
            Tedges(1) = 0;
            Tedges(end+1) = 2*pi;
        else
            Tedges(2:end) = Tedge(1:end-1);
            Tedges(end+1) = 2*pi;
            Tedges(1) = 0;
        end
        Tbinc = zeros(size(Tedges));
        Tedgecs = circshift(Tedges,1);
        for i = 1:length(Tedges)
            Tbinc(i) = (angleDiff(Tedgecs(i),Tedges(i)))/2+Tedgecs(i);
        end
        Tbinc = circshift(Tbinc,-1);
        Tbinc = mod(Tbinc,2*pi);
        % remove the element at the end
        Tbinc(end) = [];
        % set the first and end the zero
        Tbinc(end) = Tbinc(2)-(Tbinc(3)-Tbinc(2));
        Tbinc(1) = Tbinc(2)-(Tbinc(3)-Tbinc(2));
        Tbinnum = [1:length(Tbinc)-1,1];
        
    else
        disp('did not code this')
        keyboard
        Tedge = nbins;
        Tbinc = zeros(size(Tedge));
        Tedgecs = circshift(Tedge,1);
        for i = 1:length(Tedge)
            Tbinc(i) = (angleDiff(Tedgecs(i),Tedge(i)))/2+Tedgecs(i);
        end
        Tbinc = circshift(Tbinc,-1);
        Tbinc = mod(Tbinc,2*pi);
        Tedge = mod(Tedge,2*pi);
    end
    
    % combine the splitted bins
    splitbins = find((sum(Tbinnum==Tbinnum',1))==2);
    % length has to be 2
    if length(splitbins)~=2
        disp('there has to be only one split bin. Check the code')
        keyboard
    end
    
    % now go over all bins and counts the angles and get the indexes
    if nargout==3
        [R,~,indx] = histcounts(angle,Tedges);
        % merge the split bins
        R(splitbins(1)) = R(splitbins(1))+R(splitbins(2));
        R(splitbins(2)) = [];
        indx(indx==splitbins(2)) = splitbins(1);
    else
        [R,~,~] = histcounts(angle,Tedges);
        % merge the split bins
        R(splitbins(1)) = R(splitbins(1))+R(splitbins(2));
        R(splitbins(2)) = [];
    end
    
    
    
    
    % take Tbinc out
    Tbinc(splitbins(2)) = [];
    T = mod(Tbinc,2*pi);
end
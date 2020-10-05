function showEllipsFits(f)
% draws the ellipses fit to the merging objects

bestFits = f.best_ellips_fits;
if isempty(bestFits)
    return
end
clrvec = {'k','r','b','g','m','c','k--','r--','b--','g--','m--','c--'};
if f.show_ellips_fit && ~isempty(f.ui_handles)
    figure(f.ui_handles.fig);
    hold on
    for flynum = 1:length(bestFits(:,1))
        f.plot_handles.ellipses = ellipse(bestFits(flynum,3)/2,bestFits(flynum,4)/2,...
            bestFits(flynum,5)*pi/180,bestFits(flynum,1),bestFits(flynum,2),clrvec{flynum});
    end
end

% delete the data
f.best_ellips_fits = [];
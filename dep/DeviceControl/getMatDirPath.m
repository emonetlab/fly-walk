function mdp = getMatDirPath()
% returns the path for matlab directory
% get matlab folder path, assume it is the first one in the search path
mdp=matlabpath;mdp=strsplit(mdp,';');mdp=mdp{1};
% check if that is actually MATLAb directory
if ~strcmp(mdp(end-5:end),'MATLAB')
    % try to use userpath method
    try 
        up = userpath;
        up = strsplit(up,filesep);
        mdp = [strjoin(up(1:end-1),filesep),filesep,'MATLAB'];
    catch ME
        disp(['path is ',mdp])
        disp('check matlab path or reset')
        disp(ME.message)
        error('this is not matlab path')
    end
end
    
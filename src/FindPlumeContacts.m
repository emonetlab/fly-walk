function f = FindPlumeContacts(f,frame_num)
%FindPlumeContacts
%   f = FindPlumeContacts(f)
%   Finds peaks in signal (tracking_info.signal) with the given parameters.
%   Elminates peaks below thresholds and the ones who does not fall in to
%   the constraints. Located peaks are appended to the tracking info:
%   peak: frame numbers for peaks
%   width: width of each signal whiff
%   prom: peak prominence of the whiff
%   
%%%%%%%%%%%  PARAMETERS  %%%%%%%%%%%%%%%%%%%%
%   smooth_length: smooths signal prior to the peak detection (data points)
%   minpeakheight: (a.u.) minimum peak height value to be detected in the signal
%   minpeakdist: (sec) the minimum distance between peaks. Peaks closer will be ignored
%   maxpeakwidth: (sec) peaks wider will be ignored 
%   minpeakprom: minimum peak prominence
%   signal_threshold: (a.u.) peaks higher than this will be ignored
%   xloc_constraint: (flies close to the source tend to be closer.
%   Elimnates flies closer then xloc_constraint to the left edge

if nargin==1
    frame_num = f.nframes;
end

%% set the parameters
if isempty(f.plm_cont_par)
%     f.plm_cont_par.ybound = size(f.ExpParam.bkg_img,1);
%     f.plm_cont_par.xbound = size(f.ExpParam.bkg_img,2);
    f.plm_cont_par.smooth_length = 5;% How much to smooth the signal before analyzing the peaks. (Previous value: 3)
    f.plm_cont_par.smooth_type = 'box smooth'; % smoothing type
    f.plm_cont_par.minpeakdist = .1; % The minimum time that two neighboring detected peaks must have between them.
    f.plm_cont_par.minpeakprom = 1;%3; % The minimum intensity that the peak prominence must have.
    f.plm_cont_par.maxpeakwidth = 1; % The maximum length that a signal increase can have in seconds.
    f.plm_cont_par.minpeakheight = 5;%3; % The mimimum intensity that the peak height can have.
    f.plm_cont_par.signal_threshold = 100; % Delete signal peaks larger than this.
    f.plm_cont_par.xloc_constraint = 15; % Delete signals close to the source.
    f.plm_cont_par.min_track_length = 1; % 1 second, if tracks length is shorter ignore it
end
%% remove fields
if isfield(f.tracking_info,'signal_sorted')
    f.tracking_info = rmfield(f.tracking_info,'signal_sorted');
end
if isfield(f.tracking_info,'signal_peak')
    f.tracking_info = rmfield(f.tracking_info,'signal_peak');
end
if isfield(f.tracking_info,'signal_width')
    f.tracking_info = rmfield(f.tracking_info,'signal_width');
end
if isfield(f.tracking_info,'signal_prom')
    f.tracking_info = rmfield(f.tracking_info,'signal_prom');
end
if isfield(f.tracking_info,'signal_onset')
    f.tracking_info = rmfield(f.tracking_info,'signal_onset');
end
if isfield(f.tracking_info,'signal_offset')
    f.tracking_info = rmfield(f.tracking_info,'signal_offset');
end

%% Iterate through all tracks:
noftracks = find(f.tracking_info.fly_status(:,frame_num)==0,1,'last') - 1;
for trj = 1:noftracks
% Finding peaks in the signal detected by the fly :%%%%%%%%%%%%%%%%%%%%%%%%
track_start = find(f.tracking_info.fly_status(trj,:)==1,1,'first');
track_end = find(f.tracking_info.fly_status(trj,:)==1,1,'last');
if length(track_start:track_end)<(f.plm_cont_par.min_track_length*f.ExpParam.fps)
    continue
end
% try
if strcmp(f.plm_cont_par.smooth_type,'box smooth')
    smth_signal = smooth(f.tracking_info.signal(trj,track_start:track_end),f.plm_cont_par.smooth_length);
elseif strcmp(f.plm_cont_par.smooth_type,'s-golay')
    smth_signal = smooth(f.tracking_info.signal(trj,track_start:track_end),f.plm_cont_par.smooth_length,'sgolay',f.plm_cont_par.sgolayorder);
end
f.tracking_info.signal(trj,track_start:track_end) = fillgaps(f.tracking_info.signal(trj,track_start:track_end));
    [~,locs,widths,proms,borders] = findpeaks1(smth_signal,track_start:track_end,'MaxPeakWidth',f.plm_cont_par.maxpeakwidth*f.ExpParam.fps,...
        'MinPeakDistance',f.plm_cont_par.minpeakdist*f.ExpParam.fps,'MinPeakProminence',f.plm_cont_par.minpeakprom,...
    'MinPeakHeight',f.plm_cont_par.minpeakheight,'Annotate','extents','WidthReference','halfheight');
% catch
%     % no peaks found or findpeaks error
%     pks = [];
%     locs = [];
%     widths = [];
%     proms = [];
% end

% If no signal peaks/increases are found, go to next iteration: 
    if isempty(locs)
        continue;
    end
    
    % write the output to f
    f.tracking_info.signal_peak(trj,1:length(locs)) = locs;
    f.tracking_info.signal_width(trj,1:length(locs)) = widths;
    f.tracking_info.signal_prom(trj,1:length(locs)) = proms';
    f.tracking_info.signal_onset(trj,1:length(locs)) = borders(1,:);
    f.tracking_info.signal_offset(trj,1:length(locs)) = borders(2,:);

end

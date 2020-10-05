function [fps,frames] = SaveVideoFrames(vid_name)
%SaveVideoFrames
% function [fps,frames] = SaveVideoFrames(vid_name)
% use this file to save frames from a large avi to mat file frame by frame
% initiate a matfile and saves frames in mj2 file one by one
% returns fps but an empty frames
%
% written by Mahmut Demir 08/19/2020

vidobj = VideoReader(vid_name);
fps = vidobj.FrameRate; % get frame rate
nFrames = vidobj.Duration*vidobj.FrameRate;
% write an empty frame
frames = zeros(vidobj.Height,vidobj.Width,10,'uint8');
% save the matfile in 7.3 version
save([vid_name(1:end-4),'-frames.mat'],'frames','-v7.3');
disp('Created initial matfile')

disp('I will attempt to open an m file and save frames one by one')
% save frames starting from the last
m = matfile([vid_name(1:end-4),'-frames.mat'],'Writable',true);
disp([vid_name(1:end-4),'-frames.mat is opened'])

% extend frames in matfile
m.frames(:,:,nFrames) = uint8(0);

disp(['Saving frames: ',vid_name])
for i = 1:nFrames
    m.frames(:,:,i) = readFrame(vidobj);
    disp([num2str(i),'/',num2str(nFrames)])
%     if i==1
%         fprintf('%d%% ', fix(0/round(nFrames/20))*10);
%     end
%     if rem(i,round(nFrames/20))==0
%         fprintf('%d%% ', fix(i/round(nFrames/20))*10);
%     end
end
disp(['Saving complete: ',vid_name])

frames = [];
        
    
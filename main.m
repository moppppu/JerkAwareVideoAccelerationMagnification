%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Shoichiro Takeda, Nippon Telegraph and Telephone Corporation
% Date (last update): 2020/01/16
% License: Please refer to the attached LICENCE file
%
% Please refer to the original paper: 
%   "Jerk-Aware Video Acceleration Magnification", CVPR 2018
%
% All code provided here is to be used for **research purposes only**. 
%
% This implementation also includes some lightly-modified third party codes:
%   - matlabPyrTools, from "https://github.com/LabForComputationalVision/matlabPyrTools"
%   - myPyToolsExt&Filters from "http://people.csail.mit.edu/nwadhwa/phase-video/PhaseBasedRelease_20131023.zip"
%   - main & myfuntions,  from "https://github.com/acceleration-magnification/sources (*initial version)"
% All credit for the third party codes is with the authors.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc;
close all;
clear all;

% Add path
addpath(fullfile(pwd, 'outputs'));
addpath(fullfile(pwd, 'myPyrToolsExt'));
addpath(fullfile(pwd, 'myfunctions/Filters'));
addpath(fullfile(pwd, 'myfunctions/utilize'));
addpath(fullfile(pwd, 'Filters'));

% Set dir
% dataDir = 'C:\Users\Shoichiro Takeda\Videos'; % Change your dir
dataDir = '/Users/shoichirotakeda/Movies';
outputDir = [pwd, '\outputs'];

% Select input video
inFile = fullfile(dataDir,['baby.mp4']); % Change your data name
[Path,FileName,Ext] = fileparts(inFile);

% Read video
fprintf('Read input video\n');
vr = VideoReader(inFile);
vid = vr.read();

% Set video parameter
FrameRate = round(vr.FrameRate);
[nH, nW, nC, nF]= size(vid);
ScaleVideoSize = 1;
StartFrame = 1;
EndFrame   = nF;
fprintf('Original VideoSize ... nH:%d, nW:%d, nC:%d, nF:%d\n', nH, nW, nC, nF);

% Set CSF parameter
nOri = 8; % number of orientations
nProp = 5; % fix all video in CVPR2018

% % Set magnification parameter (gun.mp4)
% alpha = 10;
% targetFreq = 20;
% fs = 480;
% beta = 0.3;

% % Set magnification parameter (golf.mp4)
% alpha = 25;
% targetFreq = 2;
% fs = 60;
% beta = 0.8;

% Set magnification parameter (cat_toy.mp4)
% alpha = 5;
% targetFreq = 3;
% fs = 240;
% beta = 0.8;

% Set magnification parameter (ukulele.mp4)
ScaleVideoSize = 0.5;
StartFrame = 4.8*FrameRate;
EndFrame   = StartFrame+10*FrameRate;

% Set Parameter
alpha = 25;
targetFreq = 40;
fs = 240;
beta = 1;

% Set output Name
resultName = ['mag-',FileName, ...
            '-scale-' num2str(ScaleVideoSize) ...
            '-ori-' num2str(nOri) ...
            '-fs-' num2str(fs) ...
            '-ft-' num2str(targetFreq) ...
            '-alp-' num2str(alpha) ...
            '-beta-' num2str(beta) ...
            ];
        
%% Preprocess for input video
% Resize (H x W) scale
TmpVid = imresizeVideo(vid, ScaleVideoSize);
clear vid;
vid = TmpVid;
clear TmpVid;

% Resize time
TmpVid = vid(:,:,:,StartFrame:EndFrame);
clear vid;
vid = TmpVid;

% Get final input video parameter
[nH, nW, nC, nF]= size(vid);
fprintf('Resized VideoSize ... nH:%d, nW:%d, nC:%d, nF:%d\n', nH, nW, nC, nF);

% Change RGB to YIQ color space & extract only Y color space
originalFrame = zeros(nH, nW, nC, nF, 'single');
for i = 1:1:nF 
    originalFrame(:, :, :, i) = single(rgb2ntsc(im2single(vid(:, :, :, i))));   
end

% Perform 2D FFT
fft_Y = single(fftshift(fftshift(fft2(squeeze(originalFrame(:,:,1,:))),1),2));

%% Get complex steerable filters (CSF) and filter indices (determine the filtering area in Fouried domain)
% Get maximum pyramid levels
ht = maxSCFpyrHt(zeros(nH,nW));

% Get CSF and indices
[CSF, filtIDX] = getCSFandIDX([nH nW], 2.^[0:-0.5:-ht], nOri, 'twidth', 0.75);

% Get pyramid patameter
nPyrLevel = size(CSF,1);

%% Get pyramid scale facter : lambda (Eq.6)
lambda =  zeros(nPyrLevel, nOri);
for level = 1:1:nPyrLevel
    if level == 1 || level == nPyrLevel
        tmp_h_down = size(CSF{level,1},1) ./ size(CSF{1,1},1);
        tmp_w_down = size(CSF{level,1},2) ./ size(CSF{1,1},2);
        DownSamplingFacter = (tmp_h_down + tmp_w_down) ./ 2;
        lambda(level,1) = 1/DownSamplingFacter;
    else
        for ori = 1:1:nOri
            tmp_h_down = size(CSF{level,ori},1) ./ size(CSF{1,1},1);
            tmp_w_down = size(CSF{level,ori},2) ./ size(CSF{1,1},2);
            DownSamplingFacter = (tmp_h_down + tmp_w_down) ./ 2;
            lambda(level,ori) = 1/DownSamplingFacter;
        end
    end
end

%% Calculate phase difference
fprintf('\n');
fprintf('Calculating Amplitude & Phase\n');

for level = 2:1:nPyrLevel-1 % except for the highest/lowest pyramid level
    for ori = 1:1:nOri
        fprintf('Processing pyramid level: %d, orientation: %d\n', level, ori);
    
        hIDX = filtIDX{level,ori}{1};
        wIDX = filtIDX{level,ori}{2};
        cfilter = CSF{level,ori};       

        for f = 1:nF
            % here, we apply rondomized sparcification algorhithm
            CSF_fft_Y = cfilter .* fft_Y(hIDX, wIDX, f);  
            R = ifft2(ifftshift(CSF_fft_Y)); 

            if f == 1
                phaseRef = angle(R);    
                phase = gpuArray( zeros(nF, numel(hIDX), numel(wIDX), 'single') );
            end

            phaseCurrent = angle(R);
            phase(f,:,:) = mod(pi+phaseCurrent-phaseRef,2*pi)-pi;
        end

        fprintf('Phase Unwrapping \n');
        phase = unwrap(phase);
        
        % Phase-based video motion processing in SIGGRAPH 2013
        % filtered_phase{level,ori} = gather(permute(FIRWindowBP(permute(phase, [2,3,1]), (targetFreq-1/2)/fs, (targetFreq+1/2)/fs), [3,1,2]));

        fprintf('Temporal Acceleration Filtering \n');
        filtered_phase{level,ori} = gather(applyTAF(phase, 1, targetFreq, fs));

        fprintf('Create Jerk-Aware Filter\n'); % (Eq.1-5)
        JAF{level,ori} = gather(getJAF(phase, 1, targetFreq, fs, lambda(level,ori).*beta));
    end
end

%% Propagation Correction for Jerk-Aware Filter (Eq.7)
fprintf('\n');
fprintf('Propagation Correction for Jerk-Aware Filter\n');  

for ori = 1:1:nOri
    fprintf('Processing orientation: %d of %d\n', ori, nOri);

    for level = 2:1:nPyrLevel-1
        pJAF = JAF{level,ori}; % initialized

        for prop = level+1:level+(nProp-1)
            if prop <= nPyrLevel-1
                pJAF = pJAF .* myimresize3(JAF{prop,ori}, pJAF); % multiple cascade
            end
        end

        JAF{level,ori} = pJAF;
    end
    
end

%% Magnification
fprintf('\n');
fprintf('Magnification \n');

fft_magY = zeros(nH, nW, nF, 'single');

for level = 2:1:nPyrLevel-1 % except for the highest/lowest pyramid level
    for ori = 1:1:nOri
        fprintf('Processing pyramid level: %d, orientation: %d\n', level, ori);
        
        hIDX = filtIDX{level,ori}{1};
        wIDX = filtIDX{level,ori}{2};
        cfilter = CSF{level,ori};
        
        % detP = filtered_phase{level,ori}; 
        detP = JAF{level,ori} .* filtered_phase{level,ori};

        for f = 1:nF
            CSF_fft_Y = cfilter .* fft_Y(hIDX, wIDX, f);  
            R = ifft2(ifftshift(CSF_fft_Y)); 
            magR = R .* exp( 1i * (alpha * squeeze(detP(f,:,:))));
            fft_magR = fftshift(fft2(magR));
            fft_magY(hIDX, wIDX, f) = fft_magY(hIDX, wIDX, f) + (2 * cfilter .* fft_magR);
        end
    end

    clear detP
end 

% Add the lowest pyramid level
hIDX = filtIDX{nPyrLevel,1}{1};
wIDX = filtIDX{nPyrLevel,1}{2};
cfilter = CSF{nPyrLevel,1};  
for f = 1:nF
    fft_magY(hIDX, wIDX, f) = fft_magY(hIDX, wIDX, f) + (fft_Y(hIDX, wIDX, f) .* cfilter .^2 ); 
end

%% Rendering Video
fprintf('\n');
fprintf('Rendering Video\n');
tic;

outFrame = originalFrame; 
for f = 1:nF
    magY = real(ifft2(ifftshift(fft_magY(:,:,f))));
    outFrame(:, :, 1, f) = magY; 
    outFrame(:, :, :, f) = ntsc2rgb(outFrame(:,:,:,f));       
end

fprintf('\n');
fprintf('Output Video\n');
outName = fullfile(outputDir,'pre.avi');
vidOut = VideoWriter(outName, 'Uncompressed AVI');
vidOut.FrameRate = FrameRate;
open(vidOut) 

outFrame_final = im2uint8(outFrame);
                     
writeVideo(vidOut, outFrame_final);

close(vidOut);

%% Compress output data size via ffmpeg
! ffmpeg -i ./outputs/pre.avi -c:v libx264 -preset veryslow -crf 1 -pix_fmt yuv420p ./outputs/output.mp4
fprintf('\n');
fprintf('rename\n'); movefile('./outputs/output.mp4',['./outputs/', resultName, '.mp4']);
fprintf('delete prefile\n'); delete('./outputs/pre.avi');
fprintf('Done\n');

% %% Visualize phase diferences
% % pyr = 2;
% % oct = 5;
% % phase_caxis = [-2,2];
% 
% pyr = 3;
% oct = 5;
% phase_caxis = [-1.5,1.5];
% 
% for i = 3
%     
%     clear F
% 
%     for t = 1:1:nF
%         figure('position',[1256.20000000000,1392.20000000000,403.200000000000,233.600000000000]);
%         set(gcf,'Visible', 'off');
%         set(gcf,'color',[0 0 0])
%         colormap jet;
% 
%         if i == 1
% %             imagesc(vid(:,:,:,t));
% %             axis off;
% 
%         elseif i==2
% %             imagesc( squeeze( JAF{pyr,ori}(t,:,:)) );
% %             caxis(map_caxis);
% %             axis off;
% 
%         elseif i==3
%             imagesc( squeeze( filtered_phase{pyr,oct}(t,:,:) ) );
%             caxis(phase_caxis);  
%             axis off;
%         end
% 
%         F(t) = getframe(gcf);
%     end
% 
%     fprintf('\n');
%     fprintf('Output Video\n');
%     outName = fullfile(outputDir,['visualize_',num2str(i),'.avi']);
%     vidOut = VideoWriter(outName, 'Uncompressed AVI');
%     vidOut.FrameRate = FrameRate;
%     open(vidOut) 
% 
%     writeVideo(vidOut, F);
% 
%     disp('Finished')
%     close(vidOut);
% 
%     close all
% 
% end

%%% Author: Dr. Seyran Khademi.
%%% Code rewritten from Yichao Zhang.
%%% Date: July 2017.

% The function takes the video parameters and genrated 1D kernel and 
% the kernel is convloveld to input video at temporal dimension (frames)

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
% This implementation also includes some modified third party codes:
%   - tempkernel.m,  from "https://github.com/acceleration-magnification/sources (*initial version)"
% All credit for the third party codes is with the authors.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% input video => (frame, h, w) 
% *varargin is used to changes convolution dimension (dim<=3)

function output = applyTAF(input, convdim, targetFreq, samplingRate)

    if convdim > 4
        error('Cannot convolve with given dimension values')
    end
    
    % kernel parameters
    windowSize = ceil(samplingRate / (4 * targetFreq));
    sigma      = windowSize/sqrt(2);
    
    if windowSize < 3
        windowSize = 3;
    end

    if mod(windowSize,2) == 0
        x = linspace(-4*sigma, 4*sigma, windowSize+1);
    else
        x = linspace(-4*sigma, 4*sigma, windowSize);
        windowSize = windowSize - 1;
    end
    
    sigma1 = sigma;
    sigma2 = 2 * sigma;   

    % build DOG kernel
    % (Comment: kernel generated should meet two requirements    :
    %    (1) sum(DOG_kernel) = 0
    %    (2) sum(abs(DOG_kernel)) = 1

    gaussFilter1 = exp(-x .^ 2 / (2 * sigma1 ^ 2));
    gaussFilter1 = gaussFilter1 / sum (gaussFilter1); % normalize
    gaussFilter2 = exp(-x .^ 2 / (2 * sigma2 ^ 2));
    gaussFilter2 = gaussFilter2 / sum (gaussFilter2); % normalize
    DOG_kernel   = gaussFilter1-gaussFilter2; % DOG

    % normalization so that maximum value of the kernel is 1.
    DOG_kernel = DOG_kernel./sum(abs(DOG_kernel)); % 'Normalization'
    kernel = DOG_kernel'; % K x 1�ɕύX for high speed
    
    % Shift dimension for 1D convolution
    input = shiftdim(input, convdim-1);
    
    % Convolution
    output = convn(input, kernel, 'same'); % 1D convolove is the fastest process
    output(1:windowSize/2,:,:) = 0;
    output(end-windowSize/2+1:end,:,:) = 0;
    
    % Return dimension
    returndim = numel(size(output)) - (convdim-1);
    output = shiftdim(output, returndim);

end

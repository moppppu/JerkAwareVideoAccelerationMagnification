%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author: Shoichiro Takeda, Nippon Telegraph and Telephone Corporation
% Date (initial)    : 2017/10/12
% Date (last update): 2020/01/16
% License: Please refer to the attached LICENCE file
%
% Please refer to the original paper: 
%   "Jerk-Aware Video Acceleration Magnification", CVPR 2018
%
% All code provided here is to be used for **research purposes only**. 
%
% This implementation also includes some lightly-modified third party codes:
%   - tempkernel.m,  from "https://github.com/acceleration-magnification/sources (*initial version)"
% All credit for the third party codes is with the authors.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Get Jerk-Aware Filter (Eq.1-5)
% input order => (frame, h, w)

function JAF = getJAF(input, convdim, targetFreq, samplingRate, beta)

    if convdim > 4
        error('Cannot convolve with given dimension values')
    end

    % Set filter parameters
    windowSize = ceil(samplingRate / (4 * targetFreq)); 
    sigma      = windowSize/sqrt(2);
    
    if windowSize < 3
        windowSize = 3;
    end
    
    if mod(windowSize,2) == 0
        x = linspace(-4*sigma, 4*sigma, windowSize+1 + 3);
    else
        x = linspace(-4*sigma, 4*sigma, windowSize + 3);
        windowSize = windowSize - 1;
    end
    
    % build Jerk kernel
    % (Comment: kernel generated should meet two requirements    :
    %    (1) sum(Jerk_kernel) = 0
    %    (2) sum(abs(Jerk_kernel)) = 1
    
    gaussFilter = exp(-x .^ 2 / (2 * sigma ^ 2));
    gaussFilter = gaussFilter / sum (gaussFilter); % normalize
    
    jerk_kernel = diff(gaussFilter,3,2);

    % normalization so that maximum value of the kernel is 1.
    jerk_kernel_norm = jerk_kernel./sum(abs(jerk_kernel)); % 'Normalization'

    kernel = jerk_kernel_norm'; % K x 1

    % kernel plot
    %{
        figure;
        hold on;
        plot(gaussFilter1,'r')
        plot(gaussFilter2,'b')
        plot(kernel,'k')
        pause;
    %}
    
    % Shift dimension for 1D convolution
    input = shiftdim(input, convdim-1);

    % Calculate jerk value
    jerk = convn(input, kernel, 'same');
    jerk(1:windowSize/2,:,:) = 0;
    jerk(end-windowSize/2+1:end,:,:) = 0;

    % Abslute
    jerk = abs(jerk);
    
    % Normalization
    norm_jerk = ( jerk - min(jerk(:)) ) ./ ( max(jerk(:)) - min(jerk(:)) );
    
    % Clip value
    norm_jerk( norm_jerk < 0 ) = 0;
    norm_jerk( norm_jerk > 1 ) = 1;
    
    % Flip value
    jerk_based_smoothness = 1 - norm_jerk;

    % Correct by beta
    if beta ~= 0
        JAF = jerk_based_smoothness .^ beta; 
    else
        JAF = jerk_based_smoothness;
    end
    
    % Return dimension
    returndim = numel(size(JAF)) - (convdim-1);
    JAF = shiftdim(JAF, returndim);

end

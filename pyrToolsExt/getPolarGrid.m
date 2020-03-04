% [ANGLE, RAD] = getPolarGrid(DIMENSIONS)
% 
% Constructs rectangular grids ANGLE and RAD of dimension DIMENSIONS such 
% that ANGLE and RAD are polar coordinates (theta and r respective) of the
% points on the grid with origin at the center of the grid. 
%
% Based on buildSCFpyr in matlabPyrTools
%
% Authors: Neal Wadhwa
% License: Please refer to the LICENCE file
% Date: July 2013
%

% イメージの各(x,y)座標系を極座標系における(θ,r)であらわしたときの値を導出する
function [ angle, rad ] = getPolarGrid( dimension )
    center = ceil((dimension+0.5)/2);

    % Create rectangular grid
    [xramp,yramp] = meshgrid( ([1:dimension(2)]-center(2))./(dimension(2)/2), ...
        ([1:dimension(1)]-center(1))./(dimension(1)/2) );
  
    % Convert to polar coordinates
    angle = atan2(yramp,xramp); % -pi~+piの範囲で角度θを算出する（左回りの第三象限スタート）
    rad = sqrt(xramp.^2 + yramp.^2);
   
    % Eliminate places where rad is zero, so logarithm is well defined
    % (θ, r)でrが0の時は、log取れないので、近くの値で近似する
    rad(center(1),center(2)) =  rad(center(1),center(2)-1);
end


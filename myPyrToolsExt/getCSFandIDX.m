% FILTERS = getCSF(DIMENSION, RVALS, ORIENTATIONS, ...)
%
% Returns the transfer function of the different scales and orientations of
% a complex steerable pyramid.
%
% DIMENSIONS is the dimension of the image to be filtered
% RVALS specify the boundary between adjacent filters
% rVal�̓t�B���^�[�T�C�Y�i���s���~�b�h�̊e�K�w�ɑ΂��Ĉ��̃t�B���^�T�C�Y��ۂ��߂ɕK�v�j
% ORIENTATIONS specify the number of orientations
%
% Optional Arguments
% TWIDTH controls the falloff of the filters�@�ifalloff:�����j
%
% Based on buildSCFpyr in matlabPyrTools
%
% Authors: Neal Wadhwa
% License: Please refer to the LICENCE file
% Date: July 2013
%
% *Modified by Shoichiro Takeda @ 2020/01/16
%  - outputs cropped filters & indices with the pyramid structure

function [filters, IDX] = getCSFandIDX(dimension, rVals, orientations, varargin )

p = inputParser;

defaultTwidth = 1; %Controls falloff of filters

addRequired(p, 'dimension');
addRequired(p, 'rVals');
addRequired(p, 'order');
addOptional(p, 'twidth', defaultTwidth, @isnumeric);
parse(p, dimension, rVals, orientations, varargin{:});

dimension = p.Results.dimension;
rVals = p.Results.rVals;
orientations = p.Results.order;
twidth = p.Results.twidth;

[angle, rad] = getPolarGrid(dimension);

% added by takeda
nPyrLevels = max(size(rVals))+1;
filters = cell(nPyrLevels, orientations);
IDX = cell(nPyrLevels, orientations);

for k = 1:nPyrLevels-1
    
    [himask, lomask] = getRadialMaskPair(rVals(k), rad, twidth);
    
    if k == 1 % the highest pyramid level
        indices = getIDXFromFilter(himask);
        IDX{k,1} = indices;
        filters{k,1} = himask(indices{1}, indices{2});    
        
    else
        radMask = himask .* lomaskPrev;
        for j = 1:orientations
            orimask = radMask .* getAngleMask(j, orientations, angle);
            indices = getIDXFromFilter(orimask);
            IDX{k,j} = indices;
            filters{k,j} = orimask(indices{1}, indices{2});      
        end
    end
   
   lomaskPrev = lomask;
   
end

% the lowest pyramid level
indices = getIDXFromFilter(lomaskPrev);
IDX{nPyrLevels,1} = indices;
filters{nPyrLevels,1} = lomaskPrev(indices{1}, indices{2});    

end


%% size(V) = (time, h, w); 
%% situation: resize V (time, h, w) to (time, h', w')(=tSize); 
function rV = original_imresize3_gpu(V, target)

    if isequal(size(V), size(target)) == 1
        rV = V;
    else
        V  = gpuArray(V);
        rV = gpuArray(zeros(size(target), 'single'));
        for t = 1:1:size(V,1)
            rV(t,:,:) = imresize(squeeze(V(t,:,:)), [size(target,2), size(target,3)]);
        end
        rV = gather(rV);
    end
    
end
%%% size(V) = (time, h, w); 
%%% situation: resize V (time, h, w) to (time, h', w')(=tSize); 
%%% Shoichiro Takeda 2020/07/30

function rV = myimresize3(V, target)

    if isequal(size(V), size(target))
        rV = V;
    else
        if license('test', 'Parallel Computing Toolbox') && canUseGPU() % canUseGPU() is available arter R2019a 
            V  = gpuArray(V);
            rV = gpuArray(zeros(size(target), 'single'));
            for t = 1:1:size(V,1)
                rV(t,:,:) = imresize(squeeze(V(t,:,:)), [size(target,2), size(target,3)]);
            end
            rV = gather(rV);
        else
            rV = zeros(size(target), 'single');
            for t = 1:1:size(V,1)
                rV(t,:,:) = imresize(squeeze(V(t,:,:)), [size(target,2), size(target,3)]);
            end
        end
    end

end

% input = (nH, nW, nC, nF)
% scale = 0~1

function output = imresizeVideo(input, scale)

    if scale == 1
        output = input;
    else
        [nH, nW, nC, nF] = size(input);
        scaled_nH = round(nH * scale);
        scaled_nW = round(nW * scale);
        if license('test', 'Parallel Computing Toolbox') && canUseGPU() % canUseGPU() is available arter R2019a 
            input_gpu = gpuArray(input);
            output_gpu = gpuArray(zeros(scaled_nH, scaled_nW, nC, nF, 'uint8'));
            for frameIDX = 1:1:nF
                for colorIDX = 1:1:nC
                    output_gpu(:,:,colorIDX, frameIDX) = imresize(input_gpu(:,:,colorIDX,frameIDX), [scaled_nH, scaled_nW]);
                end
            end
            output = gather(output_gpu);
        else
            output = zeros(scaled_nH, scaled_nW, nC, nF, 'uint8');
            for frameIDX = 1:1:nF
                for colorIDX = 1:1:nC
                    output(:,:,colorIDX, frameIDX) = imresize(input(:,:,colorIDX,frameIDX), [scaled_nH, scaled_nW]);
                end
            end
        end
    end

end
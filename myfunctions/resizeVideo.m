
% input = (h,w,nC,nF)
% scale = 0~1
% ここにGUIでフレームレートの切り出し操作いれる？

function output = resizeVideo(input, scale)

if (scale~= 1)
%     fprintf('Resizing Video by Scale Factor %d\n', scale);
    
    [h, w, nC, nF] = size(input);
    h = round(h * scale);
    w = round(w * scale);
    
    output = zeros(h, w, nC, nF, 'uint8');
    
    for frameIDX = 1:1:nF
        for colorIDX = 1:1:nC
            output(:,:,colorIDX, frameIDX) = imresize(input(:,:,colorIDX,frameIDX), [h, w]);
        end
    end
%     
%     fprintf('Resizing VideoSize ... h:%d w:%d nC:%d, nF:%d\n', ...
%         size(output,1), size(output,2), size(output,3), size(output,4));
    
else
    output = input;
end

end


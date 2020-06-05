function OutIm = ResizeImage(MovingIm, FixedIm)
% Resize MovingIm to the dimensions of FixedIm

    sz = size(FixedIm);
    for ii = 1:size(MovingIm,3)
        for jj = 1:size(MovingIm,4)
            OutIm(:,:,ii,jj) = imresize(MovingIm(:,:,ii,jj), sz(1:2));
        end
    end
end
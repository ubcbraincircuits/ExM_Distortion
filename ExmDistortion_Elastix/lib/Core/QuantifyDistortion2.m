function [err, pDist] = QuantifyDistortion2(InPix, TransPix, moving)

% threshold image using Otsu's method
level = graythresh(moving);
mask = imbinarize(moving, level);

% mask vector field and get x y z vectors
idx = zeros(size(InPix,1),1);
for ii = 1:size(InPix,1)
    if ndims(mask) == 3
        idx(ii) = mask(InPix(ii,1),InPix(ii,2),InPix(ii,3));
    elseif ismatrix(mask)
        idx(ii) = mask(InPix(ii,1),InPix(ii,2));
    end
end

MaskIdx = find(idx);

% preallocate
N = length(MaskIdx);
pDist = zeros(N^2, 1);
err = zeros(N^2, 1);

count = 1;

for i = 1:N
    % get pixel coordinates
    In_xyz_i = InPix(MaskIdx(i),:);
    Trans_xyz_i = TransPix(MaskIdx(i),:);
    for j = i+1:N
        % get pixel coordinates
        In_xyz_j = InPix(MaskIdx(j),:);
        Trans_xyz_j = TransPix(MaskIdx(j),:);

        % calculate pixel to pixel distance for input points
        pDist(count,1) = sqrt(sum((In_xyz_i - In_xyz_j).^2));
        
        % calculate pixel to pixel distance for input points
        pDist(count,2) = sqrt(sum((Trans_xyz_i - Trans_xyz_j).^2));

        % calculate difference between vectors
        err(count) = abs(pDist(count,2) - pDist(count,1));

        % update counter
        count = count+1;
    end
end

end



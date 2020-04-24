% %% Estimate distortion for ExM samples
% % 
% % Pipeline:
% %   Align planes
% %       Register expanded image to non-expanded image using scale, rotation, and translation
% %       Find "best" transformation
% %           Use transformation from best matching channel or take mean
% %   Calculate expansion factor
% %   Apply non-rigid registration to scaled image to find local distortions
% %   
% %   
% %
% % To do:
% %   Align each image from Z-dimension and across channels and find the best
% %   fitting frame
% %
% %   Compare B-Spline non-rigid registration method to current
% %   
% %   Quantify distortions
% 
% clear, clc
% 
% %% Load data
% 
% dataPath = 'D:\UBC\Databinge\tutor\ExM_Distortion\';
% before = loadTif([dataPath, 'BeforeMAPprocedure-Parv488-Syt2-568-vGAT-647-STACK.tif']);
% after = loadTif([dataPath, 'AfterMAPprocedure-Parv488-Syt2-568-vGAT-647-STACK.tif']);
% 
% 
% %% Separate channels
% 
% numChans = 4;
% b = uint16(separateChannels(before, numChans));
% a = uint16(separateChannels(after, numChans));
% 
% %% Find best matching slices for each channel
% 
% % note this can take over an hour
% % tic
% % [matchingSlices, corrMat] = matchSlices(b, a);
% % toc
% 
% matchingSlices = [4, 2; 5, 5; 1, 12; 9, 11];
% % 
% % figure, 
% % for C = 1:numChans    
% %     subplot(4,1,C), imagesc(corrMat(:,:,C)), colormap jet;
% %     ylabel('before'), xlabel('after'), title(['channel ', num2str(C)])
% %     c = colorbar; c.Label.String = 'Correlation';
% % end
% 
% %% Choose the best channel for further analysis
% 
% idx = evaluateMatches(b, a, matchingSlices);
% 
% fixed = b(:,:,matchingSlices(idx,1), idx);
% moving = a(:,:,matchingSlices(idx,2), idx);
% 
% 
% %% Visualize
% excessPixels = size(moving)-size(fixed);
% visFixed = padarray(fixed, excessPixels/2, 0, 'both');
% figure, imagesc([visFixed moving])
% 
% 
% % register
% [optimizer, metric] = imregconfig('monomodal');
% moving = imhistmatch(moving, fixed);
% tform = imregtform(moving, fixed, 'similarity', optimizer, metric);
% movingRegistered = imwarp(moving,tform,'OutputView',imref2d(size(fixed)));
% 
% figure, imshowpair(fixed, movingRegistered)
% 
% 
% % Estimate expansion factor. This assumes expansion is equal in x and y.
% % Check tform.T(1,1) and tform.T(2,2) for expansion in x and y respectively
% expansionFactor = 1/sqrt(det(tform.T)); 
% 
% 
% %% non-rigid registration
% 
% 
% AFS = 1.0; % AccumulatedFieldSmoothing
% % This parameter controls the amount of diffusion-like regularization.
% % imregdemons applies the standard deviation of the Gaussian smoothing to
% % regularize the accumulated field at each iteration. Larger values result
% % in smoother output displacement fields. Smaller values result in more
% % localized deformation in the output displacement field. 
% % Values typically are in the range [0.5, 3.0].
% 
% 
% [D,movingReg] = imregdemons(movingRegistered,fixed,[500 400 200], ...
%     'AccumulatedFieldSmoothing', AFS);
% 
% figure, imshowpair(fixed, movingReg)
% 
% %% Visualize local distortions 
% 
% % resize for ease of visualization
% % simpfixed = imresize(fixed, 1/13);
% simpfixed = fixed;
% simpD = imresize(D, 1/13);
% % simpD = D;
% 
% 
% [x,y] = meshgrid(0:13:size(simpfixed,1)-1, 0:13:size(simpfixed,2)-1);
% u = simpD(:,:,1);
% v = simpD(:,:,2);
% 
% figure, imshowpair(movingReg, movingRegistered)
% hold on, quiver(x,y,-u,-v)
% % axis([0, size(simpfixed,2)-1, 0, size(simpfixed,1)-1])
% 


%%
% numBins = 10;
% [N, edges, bins] = histcounts(pxDist, numBins);
% 
% clear tt
% for i = 1:numBins
%     idx = bins == i;
%     tt(i) = mean(relError(idx));
%     sem(i) = std(relError(idx));
% 
% end
% 
% figure, plot(edges(1:end-1),tt),
% hold on, plot(edges(1:end-1), tt+sem)

%%
simpD = imresize(D, 1/13);
tic
[rr, dd] = quantifyDistortion(simpD);
toc


tic
[relError2, pxDist] = quantifyDistortion2(simpD);
toc


figure, plot(sort(relError))
hold on
plot(sort(rr))
%% helper functions

function I = loadTif(tifFile)
% Load tiff file to array

    info = imfinfo(tifFile);
    tampon = imread(tifFile,'Index',1);
    F = length(info);
    I = zeros(size(tampon,1),size(tampon,2),F,'uint16');
    I(:,:,1) = tampon(:,:,1);
    tic
    wait_bar = waitbar(0,['Loading ',tifFile]);
    ind = 0;
    for i = 2:F
        if ind == 0, waitbar(i/F, wait_bar); end
        ind = ind + 1; if ind == 100, ind = 0; end
        tampon = imread(tifFile,'Index',i,'Info',info);
        I(:,:,i) = tampon(:,:,1);
    end
    close(wait_bar);
    temps = num2str(round(10*toc)/10);
    disp([tifFile ' open in ' num2str(temps) 's'])
end


function sepData = separateChannels(data, numChans)
% separate tif into 4D array
% sepData is of shape HEIGHT x WIDTH x DEPTH x CHANNEL

sepData = zeros(size(data,1), size(data,2), size(data,3)/numChans, numChans);
for C = 1:numChans
    sepData(:,:,:,C) = data(:,:,C:numChans:end);
end

end



function [matchingSlices, corrMat] = matchSlices(beforeImg, afterImg)
% function to match depth based on image correlation after registration
% input: 
%   before and after expansion 4D images
% output:
%   matching_slices is a 2-element vector containing the slices in b and a
%   with the highest correlation after registration

[optimizer, metric] = imregconfig('monomodal'); % registration parameters

% pre-allocate
numChans = size(beforeImg,4);
corrMat = zeros(size(beforeImg,3), size(afterImg,3), numChans);  
matchingSlices = zeros(numChans, 2);

% compare all combinations of slices
for C = 1:numChans
    for i = 1:size(beforeImg,3)
        fixed = beforeImg(:,:,i,C);

        parfor j = 1:size(afterImg,3)
            % prepare images for registration
            moving = afterImg(:,:,j,C);
            moving = imhistmatch(moving, fixed);

            % perform registration
            tform = imregtform(moving, fixed, 'similarity', optimizer, metric);
            movingRegistered = imwarp(moving,tform,'OutputView',imref2d(size(fixed)));

            % populate correlation matrix
            corrMat(i, j, C) = corr2(fixed, movingRegistered);

        end
    end
    
    tmpCorrMat = corrMat(:,:,C);
    [beforeSlice, afterSlice] = find(tmpCorrMat == max(tmpCorrMat(:)));
    matchingSlices(C,:) = [beforeSlice, afterSlice];
end

end


function idx = evaluateMatches(beforeImg, afterImg, matchingSlices)
% takes pairs of images and matching slices and returns index of
[optimizer, metric] = imregconfig('monomodal'); % registration parameters

numChans = size(matchingSlices,1);
imgCorr = zeros(numChans,1);
for C = 1:numChans
    
    fixed = beforeImg(:,:,matchingSlices(C,1),C);
    moving = afterImg(:,:,matchingSlices(C,2),C);
    moving = imhistmatch(moving, fixed);
    
    
    tform = imregtform(moving, fixed, 'similarity', optimizer, metric);
    movingRegistered = imwarp(moving,tform,'OutputView',imref2d(size(fixed)));
    
    imgCorr(C) = corr2(fixed, movingRegistered);
    
end

[~, idx] = max(imgCorr);

end



function [relError, pxDist] = quantifyDistortion(D)

[H,W,Z] = size(D);

D2 = reshape(D, [H*W, Z]);

relError = zeros( (H*W)^2, 1);
pxDist = zeros( (H*W)^2, 1);

count = 1;

% f = waitbar(0, 'Calculating error');
for i = 1:size(D2,1)
    for j = 1:size(D2,1)       
        % calculate pixel to pixel distance
        [y1, x1] = ind2sub([H W], i);
        [y2, x2] = ind2sub([H W], j);
        pxDist(count) = sqrt( (x1 - x2)^2 + (y1 - y2)^2);        
        
        % calculate relative error from vector field
        relError(count) = sqrt(...
            (D(y1,x1,1)-D(y2,x2,1))^2 + (D(y1,x1,2)-D(y2,x2,2))^2 );
        
        % update counter
        count = count+1;
    end

%     waitbar(i/size(D2,1), f, 'Calculating error');
end

% close(f)
end



function [relError, pxDist] = quantifyDistortion2(D)

[H,W,Z] = size(D);
D2 = reshape(D, [H*W, Z]);

numComparisons = (H*W)^2;

relError = zeros(numComparisons,1);
pxDist = zeros(numComparisons,1);

Dtemp1 = D(:,:,1);
Dtemp2 = D(:,:,2);
parfor idx = 1:numComparisons
    [i, j] = ind2sub(size(D2), idx);
    
    % get pixel locations
    [y1, x1] = ind2sub([H W], j);
    [y2, x2] = ind2sub([H W], i);
    
    % calculate distance
    pxDist(idx) = sqrt( (x1 - x2)^2 + (y1 - y2)^2 );
    
    % calculate difference between vectors at two points
    relError(idx) = sqrt(...
        (D(y1,x1,1)-D(y2,x2,1))^2 + (D(y1,x1,2)-D(y2,x2,2))^2 ...
        );


end
end

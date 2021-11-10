function [tform, movingRegistered, mp, fp] = cpregister(moving, fixed, tform_type)
% Control point rigid registration pipeline
%
% Input:       
%           fixed, moving       (images for registration)
% Output:       
%           tform               (transformation matrix)
%           movingRegistered    (registered Image)
%           mp                  (moving point coordinates)
%           fp                  (fixed point coordinates)


[mp,fp] = cpselect(moving,fixed,'Wait',true);
tformEstimate = fitgeotrans(mp,fp,'NonreflectiveSimilarity');
% movingRegistered = imwarp(moving,tforobj,'OutputView',imref2d(size(fixed)));


[optimizer, metric] = imregconfig('monomodal');
optimizer.MaximumStepLength = 6.25e-3;
optimizer.MaximumIterations = 100;

% tform = imregtform(uint8(moving), uint8(fixed), 'similarity', optimizer, metric);
tform = imregtform(moving, fixed, tform_type, optimizer, metric, ...
    'InitialTransformation', tformEstimate);
movingRegistered = imwarp(moving,tform,'OutputView',imref2d(size(fixed)));


end
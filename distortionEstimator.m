%% Estimate distortion for ExM samples
% 
% Pipeline:
%   Register expanded image to non-expanded image using scale, rotation, and translation
%   Find "best" transformation
%       Consider all combinations of images to match depth
%       Use transformation from best matching channel or take mean
%   Calculate expansion factor
%   Apply non-rigid registration to scaled image to find local distortions
%   
%   
%
% To do:
%   Align each image from Z-dimension and across channels and find the best
%   fitting frame
%
%   Compare B-Spline non-rigid registration method to current
%   
%   Quantify distortions

%% Load data

data_path = '';
before = loadtiff([data_path, 'BeforeMAPprocedure-Parv488-Syt2-568-vGAT-647-STACK.tif']);
after = loadtiff([data_path, 'AfterMAPprocedure-Parv488-Syt2-568-vGAT-647-STACK.tif']);

% Separate color channels
b1 = before(:,:,1:4:end);
b2 = before(:,:,2:4:end);
b3 = before(:,:,3:4:end);
b4 = before(:,:,4:4:end);

a1 = after(:,:,1:4:end);
a2 = after(:,:,2:4:end);
a3 = after(:,:,3:4:end);
a4 = after(:,:,4:4:end);

%% Rigid registration
% TO DO: register across all combinations of images in z-stack to find
% which image planes have best correspondence. (Match depth)

fixed = b2(:,:,1);
moving = a2(:,:,1);
moving = imhistmatch(moving, fixed);


% visualize
excessPixels = size(moving)-size(fixed);
visFixed = padarray(fixed, excessPixels/2, 0, 'both');
figure, imagesc([visFixed moving])


[optimizer, metric] = imregconfig('monomodal');
tform = imregtform(moving, fixed, 'similarity', optimizer, metric);
movingRegistered = imwarp(moving,tform,'OutputView',imref2d(size(fixed)));

figure
imshowpair(fixed, movingRegistered)


% Estimate expansion factor. This assumes expansion is equal in x and y.
% Check tform.T(1,1) and tform.T(2,2) for expansion in x and y respectively
expansionFactor = 1/sqrt(det(tform.T)); 

%% register by fitting a displacement field

movingVol = imwarp(a2, tform, 'OutputView', imref2d(size(b2)));


AFS = 1.0; % AcuumulatedFieldSmoothing
% This parameter controls the amount of diffusion-like regularization.
% imregdemons applies the standard deviation of the Gaussian smoothing to
% regularize the accumulated field at each iteration. Larger values result
% in smoother output displacement fields. Smaller values result in more
% localized deformation in the output displacement field. 
% Values typically are in the range [0.5, 3.0].


[D,movingReg] = imregdemons(movingRegistered,fixed,[500 400 200], ...
    'AccumulatedFieldSmoothing', AFS);

figure, imshowpair(fixed, movingReg)

%% visualize local distortions 

% resize for ease of visualization
simpfixed = imresize(fixed, 1/13);
simpD = imresize(D, 1/13);


[x,y] = meshgrid(0:1:size(simpfixed,1)-1, 0:1:size(simpfixed,2)-1);
u = simpD(:,:,1);
v = simpD(:,:,2);

figure, quiver(x,y,u,v)
axis([0, size(simpfixed,2)-1, 0, size(simpfixed,1)-1])


%% helper functions

function I = loadtiff(tiff_file)
% Load tiff file to array

    info = imfinfo(tiff_file);
    tampon = imread(tiff_file,'Index',1);
    F = length(info);
    I = zeros(size(tampon,1),size(tampon,2),F,'uint16');
    I(:,:,1) = tampon(:,:,1);
    tic
    wait_bar = waitbar(0,['Loading ',tiff_file]);
    ind = 0;
    for i = 2:F
        if ind == 0, waitbar(i/F, wait_bar); end
        ind = ind + 1; if ind == 100, ind = 0; end
        tampon = imread(tiff_file,'Index',i,'Info',info);
        I(:,:,i) = tampon(:,:,1);
    end
    close(wait_bar);
    temps = num2str(round(10*toc)/10);
    disp([tiff_file ' open in ' num2str(temps) 's'])
end
clear; clc; close all;

restoredefaultpath;
addpath(genpath('lib/'));
addpath('param_files/');
suptitleStr = 'Image62 Green Channel';

DataPath = '../Stripping_Data/';
ElastixPath = '/Users/abhijitc/Documents/Software/elastix-5.0.0-mac/bin/';
MainPath = sprintf('output/%s/',strrep(suptitleStr,' ','_'));
mkdir(MainPath);

%% Load TIF files

before = LoadTif([DataPath, '62-BeforeStripping.tif']);
after = LoadTif([DataPath, '62-AfterStripping.tif']);

%% Separate channels

numChansB = input('Enter no. of channels in before image = ');
beforeIm = double(SeparateChannels(before, numChansB));
numChansA = input('Enter no. of channels in after image = ');
afterIm = double(SeparateChannels(after, numChansA));

%% Resize Image

dsF = 4; % Downsample factor
sz = size(afterIm);
afterIm = ResizeImage(afterIm, zeros(sz(1)/dsF, sz(2)/dsF, sz(3)));
sz = size(beforeIm);
beforeIm = ResizeImage(beforeIm, zeros(sz(1)/dsF, sz(2)/dsF, sz(3)));

ChanSelB = input('Enter the channel for analysis in before image = ');
ChanSelA = input('Enter the channel for analysis in after image = ');

afterIm = afterIm(:,:,:,ChanSelA);
afterIm = uint8(255*(afterIm - min(afterIm(:)))./(max(afterIm(:)) - min(afterIm(:))));
beforeIm = beforeIm(:,:,:,ChanSelB );
beforeIm = uint8(255*(beforeIm - min(beforeIm(:)))./(max(beforeIm(:)) - min(beforeIm(:))));
afterIm = imhistmatchn(afterIm, beforeIm);

%% 3D BSpline registration

AnalysisPath = fullfile(MainPath,'3D_BSpline/'); mkdir(AnalysisPath);
PlotPath = fullfile(AnalysisPath,'Plots/'); mkdir(PlotPath);

% Run 3D BSpline registration on elastix

ElastixOutDir = fullfile(AnalysisPath,'Elastix_3D_BSpline_Dir/');
[aBSpline3D, ~] = elastix(afterIm,beforeIm,ElastixOutDir,{'Parameters_BSpline3D.txt'},ElastixPath);
aBSpline3D = uint8(aBSpline3D);

% Generate distortion vetors

PixStep = 10;
InputFileName = fullfile(AnalysisPath,'InputVectors3D.txt'); % Give any name - this file will be generated
TransformixOutDir = fullfile(AnalysisPath,'Transformix_Dir/'); mkdir(TransformixOutDir);
ParamFile = fullfile(ElastixOutDir,'TransformParameters.0.txt');
DistortionStruct = GenDistortionVectors(afterIm, PixStep, InputFileName, ElastixPath, TransformixOutDir, ParamFile);

% Match slices to find the best match

Slices.before = 1:PixStep:size(beforeIm,3);
Slices.after = 1:PixStep:size(aBSpline3D,3);
[matchSliceIdx, corrMat] = MatchSlices(beforeIm, aBSpline3D, 'None', Slices);
DistortionStructMatch = SelectDistortionSlice(DistortionStruct, matchSliceIdx(1), 3);

% Plot the matched slices

PlotBestMatchSlices(corrMat, beforeIm(:,:,matchSliceIdx(1)), afterIm(:,:,matchSliceIdx(1)), ...
    aBSpline3D(:,:,matchSliceIdx(1)), DistortionStructMatch, [suptitleStr ' 3D BSpline'], PlotPath);

% Plot distortion 

nbins = 50;
[err, pDist] = QuantifyDistortion2(DistortionStruct.InputPoints, DistortionStruct.TransPoints, afterIm);
PlotDistortion(pDist, err, nbins, [suptitleStr ' 3D BSpline'], PlotPath);

% Save Results in a .mat file

save(fullfile(AnalysisPath,'3D_Spline_Results.mat'), 'beforeIm', 'afterIm', 'aBSpline3D', 'matchSliceIdx','corrMat');

%%
%
%% 3D Rigid registration + 2D BSpline

AnalysisPath = fullfile(MainPath,'3D_Rigid_2D_BSpline/'); mkdir(AnalysisPath);
PlotPath = fullfile(AnalysisPath,'Plots/'); mkdir(PlotPath);

% Run 3D Rigid registration on elastix

ElastixOutDir = fullfile(AnalysisPath,'Elastix_3D_Rigid_Dir/');
[aRigid3D, ~] = elastix(afterIm,beforeIm,ElastixOutDir,{'Parameters_Rigid3D.txt'},ElastixPath);
aRigid3D = uint8(aRigid3D);

% Match slices to find the best match

PixStep = 10;
Slices.before = 1:PixStep:size(beforeIm,3);
Slices.after = 1:PixStep:size(aRigid3D,3);
[matchSliceIdx, corrMat] = MatchSlices(beforeIm, aRigid3D, 'None', Slices);

% Run 2D BSpline registration for the best match slices on elastix

ElastixOutDir = fullfile(AnalysisPath,'Elastix_2D_BSpline_Dir/');
[aBSpline2D, ~] = elastix(aRigid3D(:,:,matchSliceIdx(2)),beforeIm(:,:,matchSliceIdx(1)),ElastixOutDir,{'Parameters_BSpline.txt'},ElastixPath);
aBSpline2D = uint8(aBSpline2D);

% Generate distortion vetors

InputFileName = fullfile(AnalysisPath,'InputVectors2D.txt'); % Give any name - this file will be generated
TransformixOutDir = fullfile(AnalysisPath,'Transformix_Dir/'); mkdir(TransformixOutDir);
ParamFile = fullfile(ElastixOutDir,'TransformParameters.0.txt');
DistortionStruct = GenDistortionVectors(aRigid3D(:,:,matchSliceIdx(2)), PixStep, InputFileName, ElastixPath, TransformixOutDir, ParamFile);

% Plot the matched slices

PlotBestMatchSlices(corrMat, beforeIm(:,:,matchSliceIdx(1)), aRigid3D(:,:,matchSliceIdx(2)), ...
    aBSpline2D, DistortionStruct, [suptitleStr ' 3D Rigid + 2D BSpline'], PlotPath);

% Plot distortion 

[err, pDist] = QuantifyDistortion2(DistortionStruct.InputPoints, DistortionStruct.TransPoints, aRigid3D(:,:,matchSliceIdx(2)));
PlotDistortion(pDist, err, nbins, [suptitleStr ' 3D Rigid + 2D BSpline'], PlotPath);

% Save Results in a .mat file

save(fullfile(AnalysisPath,'3D_Rigid_2D_Spline_Results.mat'), 'beforeIm', 'afterIm', 'aRigid3D', 'aBSpline2D', 'matchSliceIdx','corrMat');

%%
%
%% 2D Rigid registration + 2D BSpline

AnalysisPath = fullfile(MainPath,'2D_Rigid_2D_BSpline/'); mkdir(AnalysisPath);
PlotPath = fullfile(AnalysisPath,'Plots/'); mkdir(PlotPath);

% Match slices after 2D rigid registration to find the best match

PixStep = 10;
Slices.before = 1:PixStep:size(beforeIm,3);
Slices.after = 1:PixStep:size(afterIm,3);
[matchSliceIdx, corrMat] = MatchSlices(beforeIm, afterIm, 'Elastix', Slices, 'OutputDir', fullfile(AnalysisPath,'Temp/'), 'ElastixPath', ElastixPath);

% Run 2D Rigid + 2D BSpline registration for the best match slices on elastix

ElastixOutDir = fullfile(AnalysisPath,'Elastix_2D_Rigid_Dir/');
[aRigid2D, ~] = elastix(afterIm(:,:,matchSliceIdx(2)),beforeIm(:,:,matchSliceIdx(1)),ElastixOutDir,{'Parameters_Rigid.txt'},ElastixPath);
aRigid2D = uint8(aRigid2D);

ElastixOutDir = fullfile(AnalysisPath,'Elastix_2D_BSpline_Dir/');
[aBSpline2D, ~] = elastix(aRigid2D,beforeIm(:,:,matchSliceIdx(1)),ElastixOutDir,{'Parameters_BSpline.txt'},ElastixPath);
aBSpline2D = uint8(aBSpline2D);

% Generate distortion vetors

InputFileName = fullfile(AnalysisPath,'InputVectors2D.txt'); % Give any name - this file will be generated
TransformixOutDir = fullfile(AnalysisPath,'Transformix_Dir/'); mkdir(TransformixOutDir);
ParamFile = fullfile(ElastixOutDir,'TransformParameters.0.txt');
DistortionStruct = GenDistortionVectors(aRigid2D, PixStep, InputFileName, ElastixPath, TransformixOutDir, ParamFile);

% Plot the matched slices

PlotBestMatchSlices(corrMat, beforeIm(:,:,matchSliceIdx(1)), aRigid2D, ...
    aBSpline2D, DistortionStruct, [suptitleStr ' 2D Rigid + 2D BSpline'], PlotPath);

% Plot distortion 

[err, pDist] = QuantifyDistortion2(DistortionStruct.InputPoints, DistortionStruct.TransPoints, aRigid2D);
PlotDistortion(pDist, err, nbins, [suptitleStr ' 2D Rigid + 2D BSpline'], PlotPath);

% Save Results in a .mat file

save(fullfile(AnalysisPath,'2D_Rigid_2D_Spline_Results.mat'), 'beforeIm', 'afterIm', 'aRigid2D', 'aBSpline2D', 'matchSliceIdx','corrMat');
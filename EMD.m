classdef EMD < handle & dynamicprops
    properties
        fig
        dataA
        dataB
        registration
        outputs
        handles
    end
    
    methods
        function obj = EMD()
            obj.fig = figure('Name', 'EMD', 'Position', [150,150,1200,500]);
            obj.dataA = ExmViewer();
            obj.dataA.main_panel.Position =  [0.01,0.1,0.4,0.85];
            obj.dataA.main_panel.Title = 'Image A';
            obj.dataA.main_panel.FontSize = 11;
            
            obj.dataB = ExmViewer();
            obj.dataB.main_panel.Position = [0.42, 0.1, 0.4, 0.85];
            obj.dataB.main_panel.Title = 'Image B';
            obj.dataB.main_panel.FontSize = 11;
            
            % non-rigid registration parameters
            obj.registration.non_rigid.params.AFS = '3.0';
            obj.registration.non_rigid.params.use_mask = true;
            obj.registration.non_rigid.params.smooth_kernel = '2';
            obj.registration.non_rigid.params.downsample_factor = '4';
            
            obj.outputs.save_path = pwd;
            obj.outputs.filename = '';
                        
            uicontrol('Style', 'pushbutton', ...
               'String', 'Match histograms', ...
               'Units', 'norm', ...
               'Position', [0.3775, 0.015 0.075, 0.075], ...
               'TooltipString', ['MatchHistograms', newline...
               'This will compare the distribution of pixel intensities on both image stacks,', newline, ...
               'and adjust the darker image stack to match the brighter image stack. This', newline, ...
               'process may take a few seconds. It is not necessary if image features are', newline, ...
               'clearly visible in both image stacks.'], ...
               'Callback', @(source,eventData) match_histograms(obj,source,eventData));
            
           expansionPanel = uipanel('Parent', obj.fig, ...
               'Position', [0.83 0.67 0.16 0.33], 'Title', 'Expansion', ...
               'FontSize', 11);           
               expansionPanelResults = uiflowcontainer('v0', expansionPanel, ...
                   'Units','norm','Position',[0.05 0.05, 0.9, 0.2]);
                   uicontrol(expansionPanelResults, ...
                       'Style', 'text', ...
                       'String', 'Expansion Factor: ');
                   obj.registration.rigid.exp_factor = uicontrol(expansionPanelResults, ...
                       'Style', 'text', ...
                       'String', '');           
               expansionPanelAutoRegistration = uiflowcontainer('v0', expansionPanel, ...
                   'Units','norm','Position',[0.05 0.65, 0.9, 0.3]);
                   uicontrol(expansionPanelAutoRegistration, ...
                       'Style', 'pushbutton', ...
                       'String', 'Auto Register', ...
                       'TooltipString', ['AutomaticRegister', newline, ...
                       'Registers images automatically.', newline, ...
                       'This is not working well yet!', newline, ...
                       'Control point registration is recommended.'], ...
                       'Callback', @(source,eventData) autoRegisterCallback(obj, source, eventData));
               expansionPanelManualRegistration = uiflowcontainer('v0', expansionPanel, ...
                   'Units','norm','Position',[0.05 0.3, 0.9, 0.3]);
                   uicontrol(expansionPanelManualRegistration, ...
                       'Style', 'pushbutton', ...
                       'String', 'Control Point Register', ...
                       'TooltipString', ['ControlPointRegister', newline, ...
                       'Registers images based on manually selected control points.', newline, ...
                       'Opens a figure window displaying before and after expansion images.', newline, ...
                       'Select corresponding points on each image. Each point is labeled with', newline, ...
                       'a number. Ensure that corresponding points on each image have the', newline, ...
                       'the same number. The easiest way to do this is to select a point on', newline, ...
                       'image A, and then select the point on image B. Once finished, close', newline, ...
                       'the figure window.'], ...
                       'Callback', @(source,eventData) cpRegisterCallback(obj, source,eventData));
                
           distortionPanel = uipanel('Parent', obj.fig, ...
               'Position', [0.83 0.34 0.16 0.33], 'Title', 'Distortion', ...
               'FontSize', 11);           
               distortionPanelContainers = uiflowcontainer('v0', distortionPanel, ...
                   'FlowDirection', 'TopDown');               
                    distortionPanelRegistrationContainer = uiflowcontainer('v0', distortionPanelContainers);                    
                        uicontrol(distortionPanelRegistrationContainer, ...
                            'Style', 'text', ...
                            'TooltipString', ['AccumulatedFieldSmoothing', newline, ...
                            'This parameter controls the amount of diffusion-like regularization.', newline, ...
                            'Larger values result in smoother output displacement fields. Smaller', newline, ...
                            'values result in more localized deformation in the output displacement', newline, ...
                            'field. Values typically are in the range [0.5, 3.0].'], ...
                            'String', [newline, 'AFS'], ...
                            'Position', [0, 0, 10, 5]);                        
                        obj.handles.AFS = uicontrol(distortionPanelRegistrationContainer, ...
                            'Style', 'edit', ...
                            'String', obj.registration.non_rigid.params.AFS, ...
                            'TooltipString', ['AccumulatedFieldSmoothing', newline, ...
                            'This parameter controls the amount of diffusion-like regularization.', newline, ...
                            'Larger values result in smoother output displacement fields. Smaller', newline, ...
                            'values result in more localized deformation in the output displacement', newline, ...
                            'field. Values typically are in the range [0.5, 3.0].'], ...
                            'Callback', @(source, eventData) AFS_callback(obj, source, eventData));                        
                    distortionPanelMaskContainer = uiflowcontainer('v0', distortionPanelContainers);                    
                        obj.handles.mask = uicontrol(distortionPanelMaskContainer, ...
                            'Style', 'checkbox', ...
                            'String', 'Mask', ...
                            'TooltipString', ['Use Mask', newline, ...
                            'This will create a binary mask based on intensity values in the moving', newline, ...
                            'image. The mask is applied to the resulting deformation field. This is', newline, ...
                            'recommended to eliminate distortion estimates from areas in the image', newline, ...
                            'without substantial signal.'], ...
                            'Value', obj.registration.non_rigid.params.use_mask, ...
                            'Callback', @(source, eventData) mask_callback(obj, source, eventData));                        
                        uicontrol(distortionPanelMaskContainer, ...
                            'Style', 'text', ...
                            'TooltipString', ['SmoothKernel', newline, ...
                            'This parameter has no effect if the "Mask" parameter is unchecked.', newline, ...
                            'This parameter defines the standard deviation of the Gaussian smoothing', newline, ...
                            'kernel applied to the image before masking. Larger values result in a', newline, ...
                            'greater degree smoothing.'], ...
                            'String', 'Smooth kernel')                        
                        obj.handles.smk = uicontrol(distortionPanelMaskContainer, ...
                            'Style', 'edit', ...
                            'String', obj.registration.non_rigid.params.smooth_kernel, ...
                            'Callback', @(source, eventData) smooth_kernel_callback(obj, source, eventData));                        
                    distortionPanelDownsampleContainer = uiflowcontainer('v0', distortionPanelContainers);                    
                        uicontrol(distortionPanelDownsampleContainer, ...
                            'Style', 'text', ...
                            'TooltipString', ['DownsampleFactor', newline...
                            'This parameter resizes the deformation field by 1/X, where X is the downsample factor.', newline, ...
                            'A larger value will result in a greater reduction in the deformation field size. This', newline, ...
                            'is used to more easily visualize the deformations in the image. Reducing the size of', newline, ...
                            'the deformation field also reduces the computational complexity of the quantification.', newline ...
                            'Having too large of a DownsampleFactor compromises the resolution of the estimated ', newline ...
                            'deformation field. Adjust this value based on memory requirements.'], ...
                            'String', ['Downsample', newline, 'factor'])                        
                        obj.handles.dsf = uicontrol(distortionPanelDownsampleContainer, ...
                            'Style', 'edit', ...
                            'TooltipString', ['DownsampleFactor', newline...
                            'This parameter resizes the deformation field by 1/X, where X is the downsample factor.', newline, ...
                            'A larger value will result in a greater reduction in the deformation field size. This', newline, ...
                            'is used to more easily visualize the deformations in the image. Reducing the size of', newline, ...
                            'the deformation field also reduces the computational complexity of the quantification.', newline ...
                            'Having too large of a DownsampleFactor compromises the resolution of the estimated ', newline ...
                            'deformation field. Adjust this value based on memory requirements.'], ...
                            'String', obj.registration.non_rigid.params.downsample_factor, ...
                            'Callback', @(source, eventData) downsample_callback(obj, source, eventData));                        
                    distortionPanelActionContainer = uiflowcontainer('v0', distortionPanelContainers);                    
                        uicontrol(distortionPanelActionContainer, ...
                            'Style', 'pushbutton', ...
                            'String', 'Reset', ...
                            'Callback', @(source, eventData) reset_callback(obj, source, eventData))                        
                        uicontrol(distortionPanelActionContainer, ...
                            'Style', 'pushbutton', ...
                            'String', 'Quantify', ...
                            'Callback', @(source, eventData) quantify_distortion(obj, source, eventData))    
           
           outputPanel = uipanel('Parent', obj.fig, ...
               'Position', [0.83 0.01 0.16 0.33], 'Title', 'Output', ...
               'FontSize', 11);           
                outputPanelContainers = uiflowcontainer('v0', outputPanel, ...
                    'FlowDirection', 'TopDown');           
                    outputPanelPathContainer = uiflowcontainer('v0', outputPanelContainers);
                        uicontrol(outputPanelPathContainer, ...
                            'Style', 'pushbutton', ...
                            'String', 'Choose Save Path', ...
                            'Callback', @(source, eventData) output_path_callback(obj, source, eventData));
                        obj.handles.save_path = uicontrol(outputPanelPathContainer, ...
                            'Style', 'text', ...
                            'String', obj.outputs.save_path);                        
                    outputPanelFilenameContainer = uiflowcontainer('v0', outputPanelContainers);
                        uicontrol(outputPanelFilenameContainer, ...
                            'Style', 'text', ...
                            'String', 'Filename:');                        
                        uicontrol(outputPanelFilenameContainer, ...
                            'Style', 'edit', ...
                            'String', '', ...
                            'Callback', @(source, eventData) output_filename_callback(obj, source, eventData));                        
                    outputPanelFigureContainer = uiflowcontainer('v0', outputPanelContainers);
                        uicontrol(outputPanelFigureContainer, ...
                            'Style', 'text', ...
                            'String', 'Save figures', ...
                            'TooltipString', ['SaveFigures', newline...
                            'If selected, this will save the figure outputs from the expansion and distortion panels.', newline, ...
                            'Do not close the figures if you wish to save them!!!!', newline, ...
                            'Figures are saved as structures within the output .mat file. To generate the figure, use', newline, ...
                            'the command:' , newline, ...
                            'h = struct2handle(FIGURE, 0)'])                        
                        obj.handles.save_fig = uicontrol(outputPanelFigureContainer, ...
                            'Style', 'checkbox', ...
                            'Value', 1, ...
                            'TooltipString', ['SaveFigures', newline...
                            'If selected, this will save the figure outputs from the expansion and distortion panels.', newline, ...
                            'Do not close the figures if you wish to save them!!!!', newline, ...
                            'Figures are saved as structures within the output .mat file. To generate the figure, use', newline, ...
                            'the command:' , newline, ...
                            'h = struct2handle(FIGURE, 0)'], ...
                            'Callback', @(source, eventData) output_figure_callback(obj, source, eventData));                        
                    outputPanelSaveContainer = uiflowcontainer('v0', outputPanelContainers);
                        uicontrol(outputPanelSaveContainer, ...
                            'Style', 'pushbutton', ...
                            'String', 'Save', ...
                            'Callback', @(source, eventData) save_callback(obj, source, eventData));
        end
    end
end

% Miscellaneous
function match_histograms(obj, ~, ~)
stateA = get_state(obj.dataA);
stateB = get_state(obj.dataB);
dataA = obj.dataA.tmpData;
dataB = obj.dataB.tmpData;


dataA = dataA(:, :, stateA.frame_start:stateA.frame_end, stateA.view_chan);
dataB = dataB(:, :, stateB.frame_start:stateB.frame_end, stateB.view_chan);


if median(dataA(:)) > median(dataB(:))
    tmp = imhistmatchn(uint16(dataB), uint16(obj.dataA.tmpData(:)));
    insert_data(obj.dataB, tmp);
else
    tmp = imhistmatchn(uint16(dataA), uint16(obj.dataB.tmpData(:)));
    insert_data(obj.dataB, tmp);
end

end
function state = get_state(obj)

% if isempty(obj.tmpData)
%     obj.tmpData = obj.data;
% end

state.num_chans = str2double(get(obj.numChans, 'String'));
state.view_chan = str2double(get(obj.viewChan, 'String'));
state.frame_start = str2double(get(obj.frameStart, 'String'));
% if isempty(get(obj.frameEnd, 'String'))
%     state.frame_end = size(obj.tmpData, 3);
%     set(obj.frameEnd, 'String', num2str(frame_end));
% else
%     state.frame_end = str2double(get(obj.frameEnd, 'String'));
% end
state.frame_end = str2double(get(obj.frameEnd, 'String'));
state.flip_lr = get(obj.flipLR, 'Value');
state.flip_ud = get(obj.flipUD, 'Value');

end

% Expansion panel
function autoRegisterCallback(obj, ~, ~)
    stateA = get_state(obj.dataA);
    stateB = get_state(obj.dataB);
    
    moving = max(uint16(obj.dataB.tmpData(:,:,:,stateB.view_chan)), [], 3);
    fixed = max(uint16(obj.dataA.tmpData(:,:,:,stateA.view_chan)), [], 3);
    
    moving = imhistmatch(moving, fixed);
    
%     se = strel('disk',10);
%     fixed = imopen(fixed, se);
%     moving = imopen(moving, se);

    
    [optimizer, metric] = imregconfig('monomodal');
%     optimizer.MaximumStepLength = 0.00625;
%     optimizer.MaximumIterations = 300;
%     optimizer.RelaxationFactor = 0.99;
%     optimizer.MinimumStepLength = ;
%     optimizer.GradientMagnitudeTolerance = 1e-10;
    Rfixed = imref2d(size(fixed), obj.dataA.metadata.voxelSizeX, obj.dataA.metadata.voxelSizeY);
    Rmoving = imref2d(size(moving), obj.dataB.metadata.voxelSizeX, obj.dataB.metadata.voxelSizeY);
    
    scale = Rfixed.ImageExtentInWorldX/Rmoving.ImageExtentInWorldX;
    
    A = [scale 0 0;
        0 scale 0;
        0 0 1];
    initial_tform = affine2d(A);
    obj.registration.rigid.tform = imregtform(moving, Rmoving, fixed, Rfixed, 'similarity', optimizer, metric, ...
        'InitialTransformation', initial_tform);
%     obj.registration.rigid.tform = imregtform(moving, fixed, 'similarity', optimizer, metric);
    
%     obj.registration.rigid.tform = imregtform(moving, Rmoving, fixed, Rfixed, 'similarity', optimizer, metric);
    obj.registration.rigid.result = imwarp(moving, obj.registration.rigid.tform, ...
        'OutputView',imref2d(size(fixed)));
    figure, imshowpair(fixed, obj.registration.rigid.result)


end % NOT DONE
function cpRegisterCallback(obj, ~, ~)
    stateA = get_state(obj.dataA);
    stateB = get_state(obj.dataB);
    
    moving = max(uint16(obj.dataB.tmpData(:,:,:,stateB.view_chan)), [], 3);
    fixed = max(uint16(obj.dataA.tmpData(:,:,:,stateA.view_chan)), [], 3);
    [obj.registration.rigid.tform, ...
        obj.registration.rigid.result, ...
        obj.registration.rigid.params.moving_points, ...
        obj.registration.rigid.params.fixed_points] = helper.cpregister(moving, fixed, 'similarity');

    exp_factor = helper.get_expansion2D(obj.registration.rigid.tform, obj.dataA.metadata.voxelSizeX, ...
        obj.dataB.metadata.voxelSizeY);
    set(obj.registration.rigid.exp_factor, 'String', num2str(exp_factor));
    obj.registration.rigid.fig = figure;
    imshowpair(fixed, obj.registration.rigid.result), 
    title(['Expansion Factor: ', num2str(exp_factor)])
end

% Distortion panel
function AFS_callback(obj, source, ~)
obj.registration.non_rigid.params.AFS = source.String;
end
function mask_callback(obj, source, ~)
obj.registration.non_rigid.params.use_mask = source.Value;
end
function smooth_kernel_callback(obj, source, ~)
obj.registration.non_rigid.params.smooth_kernel = source.String;
end
function downsample_callback(obj, source, ~)
obj.registration.non_rigid.params.downsample_factor = source.String;
end
function reset_callback(obj, ~, ~)
% reset to defaults
obj.registration.non_rigid.params.AFS = '3.0';
obj.registration.non_rigid.params.use_mask = true;
obj.registration.non_rigid.params.smooth_kernel = '2';
obj.registration.non_rigid.params.downsample_factor = '4';
            
set(obj.handles.AFS, 'String', obj.registration.non_rigid.params.AFS);
set(obj.handles.mask, 'Value', obj.registration.non_rigid.params.use_mask);
set(obj.handles.smk, 'String', obj.registration.non_rigid.params.smooth_kernel);
set(obj.handles.dsf, 'String', obj.registration.non_rigid.params.downsample_factor);
end
function quantify_distortion(obj, ~, ~)
stateA = get_state(obj.dataA);
    
moving = obj.registration.rigid.result;
fixed = max(uint16(obj.dataA.tmpData(:,:,stateA.frame_start:stateA.frame_end,stateA.view_chan)), [], 3);
moving = imhistmatch(moving, fixed);

[D, obj.registration.non_rigid.result] = imregdemons(moving, fixed, [500 400 200], ...
    'AccumulatedFieldSmoothing', str2double(obj.registration.non_rigid.params.AFS));

if obj.registration.non_rigid.params.use_mask
    mask = moving;
    mask = imgaussfilt(mask, str2double(obj.registration.non_rigid.params.smooth_kernel));
    level = graythresh(mask);
    mask = imbinarize(mask, level);
%     se = strel('disk', 2);
%     tmp=imopen(tmp, se);
else
    mask = ones(size(moving));
end

% downsample
F = str2double(obj.registration.non_rigid.params.downsample_factor);
D = imresize(D, 1/F, 'bilinear') ./ F;
D = D .* imresize(mask, 1/F, 'bilinear');

[x,y] = meshgrid(0:size(D,1)-1, 0:size(D,2)-1);
u = D(:,:,1);
v = D(:,:,2);

X = D(:,:,1);
Y = D(:,:,2);

[row, col] = find(X~=0);
N=numel(row);

err = nan(sum(1:N-1), 1);
pDist = nan(sum(1:N-1), 1);
count = 1;
for i=1:N
    % point1
    x_orig1=col(i);
    y_orig1=row(i);
    x_trans1=col(i) + X(row(i), col(i));
    y_trans1=row(i) + Y(row(i), col(i));
    for j=i+1:N
        %point2
        x_orig2=col(j);
        y_orig2=row(j);
        x_trans2=col(j) + X(row(j), col(j));
        y_trans2=row(j) + Y(row(j), col(j));
        
        %original distance
        dist_orig=sqrt((x_orig1-x_orig2)^2+(y_orig1-y_orig2)^2);
        %transformed distance
        dist_trans=sqrt((x_trans1-x_trans2)^2+(y_trans1-y_trans2)^2);        
        
        err(count) = abs(dist_orig-dist_trans);
        pDist(count) = dist_orig;   
        count=count+1;
    end
end

% Results are expressed in pixels at the resolution of the downsampled 
% before image. Correct for this by multiplying by pixel resolution (um/px) 
% and then undoing the downsampling factor
scale_factor = (obj.dataA.metadata.voxelSizeX * F);

obj.registration.non_rigid.error = err .* scale_factor;
obj.registration.non_rigid.pixel_distance = pDist .* scale_factor;

nbins=100;
[~,edges,bins] = histcounts(obj.registration.non_rigid.pixel_distance, nbins);

bin_rms=zeros(1,nbins);
bin_stds=zeros(1,nbins);
for i = 1:nbins
  bin_rms(i) = rms(obj.registration.non_rigid.error(bins==i));
  bin_stds(i) = std(obj.registration.non_rigid.error(bins==i));
end

obj.registration.non_rigid.fig = figure; 
subplot(2,2,1), 
imshowpair(imresize(fixed, 1/F), imresize(moving, 1/F)); hold on, 
quiver(x,y,-u,-v, 'w', 'AutoScaleFactor', 3, 'linewidth', 1)
title('Distortion visualized')
subplot(2,2,2), imshowpair(fixed, obj.registration.non_rigid.result)
title('Final registration result')
subplot(2,2,3:4), errorbar(edges(2:end), bin_rms, bin_stds);
ylabel('rms error (\mum)'), xlabel('Pixel distance (\mum)')

obj.registration.non_rigid.D = D;
end

% Output panel
function output_path_callback(obj, ~, ~)
obj.outputs.save_path = uigetdir;
set(obj.handles.save_path, 'String', obj.outputs.save_path);
end
function output_filename_callback(obj, source, ~)
obj.outputs.filename = source.String;
if ~contains(obj.outputs.filename, '.mat')
    obj.outputs.filename = [obj.outputs.filename, '.mat'];
    source.String = [source.String, '.mat'];
end
end
function save_callback(obj, ~, ~)

% compile processing history
proc.imageA = get_state(obj.dataA);
proc.imageB = get_state(obj.dataB);
proc.expansion = obj.registration.rigid.params;
proc.distortion = obj.registration.non_rigid.params;

exp_factor = round(str2double(obj.registration.rigid.exp_factor.String),2);
distortion = cat(2,obj.registration.non_rigid.pixel_distance,obj.registration.non_rigid.error);

varList = {'exp_factor', 'distortion', 'proc'};

if obj.handles.save_fig.Value
    try 
        exp_figure = handle2struct(obj.registration.rigid.fig);
        varList = [varList, 'exp_figure'];
    catch 
        disp('No figure handle found for expansion.')
    end
    try
        dis_figure = handle2struct(obj.registration.non_rigid.fig);
        varList = [varList, 'dis_figure'];
    catch
        disp('No figure handle found for distortion.')
    end
end

save([obj.outputs.save_path, filesep, obj.outputs.filename], varList{:})
end

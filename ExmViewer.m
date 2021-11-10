classdef ExmViewer < handle & dynamicprops
   properties
      main_panel
      data {mustBeNumeric}
      tmpData
      numChans
      viewChan
      pBottom
      metadata
      frameStart
      frameEnd
      flipLR
      flipUD
      handles
   end
     
   methods
       function obj = ExmViewer(state)
           if nargin < 1
               state.num_chans = '1';
               state.view_chan = '1';
               state.frame_start = '1';
               state.frame_end = '';
               state.flip_lr = 0;
               state.flip_ud = 0;
           end
           
           obj.main_panel = uipanel();
           
           % create top panel for loading image and channel information
           pTop = uipanel('Parent', obj.main_panel, ...
               'Position',[0 0.9 0.75 0.1]);

           buttonsTop = uiflowcontainer('v0', pTop, ...
               'Units','norm','Position',[0.05, 0.05, 0.9, 0.9]);
           
           uicontrol(buttonsTop, ...
               'Style', 'pushbutton', ...
               'String', 'Load Image', ...
               'Callback', @(source,eventData) load_callback(obj,source,eventData));
           
           uicontrol(buttonsTop, ...
               'Style', 'text', ...
               'String', 'Number of channels: ');
           
           obj.numChans = uicontrol(buttonsTop, ...
               'Style', 'edit', ...
               'String', state.num_chans, ...
               'Callback', @(source, eventData) numChans_callback(obj, source, eventData));
           
           uicontrol(buttonsTop, ...
               'Style', 'text', ...
               'String', 'View channel: ');
           
           obj.viewChan = uicontrol(buttonsTop, ...
               'Style', 'edit', ...
               'String', '1', ...
               'Callback', @(source, eventData) viewChan_callback(obj, source, eventData));
           
           % create bottom panel for displaying the image
           obj.pBottom = uipanel('Parent', obj.main_panel, ...
               'Position',[0 0 0.75 0.9]);
           
           
           % create right panel for displaying imaging preprocessing
           % functions
           toprightPanel = uipanel('Parent', obj.main_panel, ...
               'Position', [0.75 0.4 0.25 0.5], 'Title', 'Preprocessing', ...
               'FontSize', 10);
           
           buttonsRight = uiflowcontainer('v0', toprightPanel, ...
               'Units','norm','Position',[0, 0, 1, 1], 'FlowDirection', ...
               'TopDown');
           
           obj.flipLR = uicontrol(buttonsRight, ...
               'Style', 'Checkbox', ...
               'String', 'Flip left / right', ...
               'Value', state.flip_lr, ...
               'Callback', @(source,eventData) flipLR_callback(obj,source,eventData));
           
           obj.flipUD = uicontrol(buttonsRight, ...
               'Style', 'Checkbox', ...
               'String', 'Flip up / down', ...
               'Value', state.flip_ud, ...
               'Callback', @(source,eventData) flipUD_callback(obj,source,eventData));
           
           frameStart = uiflowcontainer('v0', buttonsRight, ...
               'Units', 'norm', 'Position', [0, 0, 1, 0.2]);
           
           uicontrol(frameStart, ...
               'Style', 'text', ...
               'String', 'Frame start: ')
           
           obj.frameStart = uicontrol(frameStart, ...
               'Style', 'edit', ...
               'String', state.frame_start, ...
               'Callback', @(source,eventData) frameStart_callback(obj,source,eventData));
         
           frameEnd = uiflowcontainer('v0', buttonsRight);
           
           uicontrol(frameEnd, ...
               'Style', 'text', ...
               'String', 'Frame end: ')
           
           obj.frameEnd = uicontrol(frameEnd, ...
               'Style', 'edit', ...
               'String', state.frame_end, ...
               'Callback', @(source,eventData) frameEnd_callback(obj,source,eventData));
           
           uicontrol(buttonsRight, ...
               'Style', 'pushbutton', ...
               'String', 'Reset', ...
               'Callback', @(source,eventData) reset_callback(obj,source,eventData));
           
           % create bottom right panel to show image metadata
           bottomRightPanel = uipanel('Parent', obj.main_panel, ...
               'Position', [0.75, 0, 0.25, 0.385], 'Title', 'Metadata', ...
               'FontSize', 10);
         
           metadataText = uiflowcontainer('v0', bottomRightPanel, ...
               'Units','norm','Position',[0, 0, 1, 1], 'FlowDirection', ...
               'TopDown');
           
               uicontrol(metadataText, ...
                   'Style', 'text', ...
                   'String', 'Filename', ...
                   'FontSize', 8);

               obj.handles.filename = uicontrol(metadataText, ...
                   'Style', 'text', ...
                   'String', '', ...
                   'FontSize', 5);

               uicontrol(metadataText, ...
                   'Style', 'text', ...
                   'String', 'Image Size (px x px)', ...
                   'FontSize', 8);

               obj.handles.imageSize = uicontrol(metadataText, ...
                   'Style', 'text', ...
                   'String', '', ...
                   'FontSize', 8);

               uicontrol(metadataText, ...
                   'Style', 'text', ...
                   'String', 'Pixel size (nm x nm)', ...
                   'FontSize', 8);

               obj.handles.pixel_size = uicontrol(metadataText, ...
                   'Style', 'text', ...
                   'String', '', ...
                   'FontSize', 8);

               uicontrol(metadataText, ...
                   'Style', 'text', ...
                   'String', 'Step size (nm)', ...
                   'FontSize', 8);

               obj.handles.stepSize = uicontrol(metadataText, ...
                   'Style', 'text', ...
                   'String', '', ...
                   'FontSize', 8);

       end
       
       function insert_data(obj, data)
           state = get_state(obj);
           
           obj.tmpData(:,:,state.frame_start:state.frame_end, state.view_chan) = data;
           render_data(obj);
       end
   end

end

% top panel
function load_callback(obj, source, eventData)
    [obj.data, obj.metadata] = helper.load_czi();
    obj.tmpData = obj.data;
    
    reset_state(obj);
    
    set(obj.handles.imageSize, 'String', [num2str(obj.metadata.stackSizeX), 'x', ...
        num2str(obj.metadata.stackSizeY)])
    set(obj.handles.pixel_size, 'String', [num2str(1000*obj.metadata.voxelSizeX, 3), ...
        'x', num2str(1000*obj.metadata.voxelSizeY, 3)]);
    set(obj.handles.stepSize, 'String', num2str(1000*obj.metadata.voxelSizeZ, 3));
    set(obj.handles.filename, 'String', obj.metadata.filename);
    
    render_data(obj);
end
function numChans_callback(obj, source, eventData)
state = get_state(obj);

% conditions that must be met
cond1 = size(obj.data, 3) > state.num_chans;
cond2 = ~rem(size(obj.data, 3), state.num_chans);
cond3 = state.num_chans >= state.view_chan;

if ~all([cond1, cond2, cond3])
    set(obj.numChans, 'String', '1')
    set(obj.viewChan, 'String', '1')
end

set(obj.frameEnd, ...
'String', num2str(min([state.frame_end, size(obj.data,3)/state.num_chans])));

assert(cond1, 'Number of channels exceeds images in stack')
assert(cond2, 'Number of images in stack must be divisible by number of channels')
assert(cond3, 'View channel exceeds number of channels')


for chan = 1:state.num_chans
    tmp(:,:,:,chan) = obj.data(:,:, chan:state.num_chans:end);
end

obj.tmpData = tmp;
render_data(obj);
end
function viewChan_callback(obj, source, eventData)
state = get_state(obj);

% error handling
if state.view_chan > state.num_chans
    disp("View channel greater than number channels")
    set(obj.viewChan, 'String', '1')
end

render_data(obj);
end

% pre-processing panel
function flipLR_callback(obj, source, eventData)

cond1 = ~isempty(obj.tmpData); 
if ~all(cond1)
    set(obj.flipLR, 'Value', 0)
end
assert(cond1, 'Load data before attempting operations')

obj.tmpData = fliplr(obj.tmpData);
render_data(obj);
end
function flipUD_callback(obj, source, eventData)

cond1 = ~isempty(obj.tmpData); 
if ~all(cond1)
    set(obj.flipUD, 'Value', 0)
end
assert(cond1, 'Load data before attempting operations')


obj.tmpData = flipud(obj.tmpData);
render_data(obj);
end
function frameStart_callback(obj, source, eventData)
render_data(obj);
end
function frameEnd_callback(obj, source, eventData)
state = get_state(obj);
set(obj.frameEnd, 'String', num2str(min([size(obj.data,3)/state.num_chans, state.frame_end])));
render_data(obj);
end
function reset_callback(obj, source, eventData)
reset_state(obj);
render_data(obj);
end

% miscellaneous
function reset_state(obj)
obj.tmpData = obj.data;
set(obj.numChans, 'String', '1');
set(obj.viewChan, 'String', '1');
set(obj.frameStart, 'String', '1');
set(obj.frameEnd, 'String', num2str(size(obj.tmpData, 3)));
set(obj.flipLR, 'Value', 0);
set(obj.flipUD, 'Value', 0);
end
function state = get_state(obj)
state.num_chans = str2double(get(obj.numChans, 'String'));
state.view_chan = str2double(get(obj.viewChan, 'String'));
state.frame_start = str2double(get(obj.frameStart, 'String'));
state.frame_end = str2double(get(obj.frameEnd, 'String'));
end
function render_data(obj)
state = get_state(obj);
sliceViewer(obj.tmpData(:, :, state.frame_start:state.frame_end, state.view_chan), ...
    'Parent', obj.pBottom);
end

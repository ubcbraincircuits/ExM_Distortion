function [data, metadata] = load_czi()
% Uses Bio-Formats to load image data and metadata from CZI file
%
% Input: czi file
% Outputs:
%           data:       Image data
%           metadata:   Structure containing dataset name and resolution

[file, path] = uigetfile('*');
if ~file
    return
end
f = waitbar(0, 'Loading ...');
czi_data = bfopen([path, file]);



omeMeta = czi_data{1, 4};
% image dimensions
metadata.stackSizeX = omeMeta.getPixelsSizeX(0).getValue(); % width (px)
metadata.stackSizeY = omeMeta.getPixelsSizeY(0).getValue(); % height (px)
metadata.stackSizeZ = omeMeta.getPixelsSizeZ(0).getValue(); % depth (slices)

% voxel sizes (um)
metadata.voxelSizeX = double(omeMeta.getPixelsPhysicalSizeX(0).value(ome.units.UNITS.MICROMETER));
metadata.voxelSizeY = double(omeMeta.getPixelsPhysicalSizeY(0).value(ome.units.UNITS.MICROMETER));
metadata.voxelSizeZ = double(omeMeta.getPixelsPhysicalSizeZ(0).value(ome.units.UNITS.MICROMETER));

% return image data
data = zeros(metadata.stackSizeY, ...
    metadata.stackSizeX, ...
    metadata.stackSizeZ);

metadata.filename = file;

for i = 1:metadata.stackSizeZ
   data(:,:,i) = czi_data{1}{i, 1};
end

close(f)

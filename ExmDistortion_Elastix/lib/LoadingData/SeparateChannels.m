function sepData = SeparateChannels(data, numChans)
% separate tif into 4D array
% sepData is of shape HEIGHT x WIDTH x DEPTH x CHANNEL

sepData = zeros(size(data,1), size(data,2), size(data,3)/numChans, numChans);
for C = 1:numChans
    sepData(:,:,:,C) = data(:,:,C:numChans:end);
end

end

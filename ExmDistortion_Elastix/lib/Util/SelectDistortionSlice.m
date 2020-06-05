function DistortionStructOut = SelectDistortionSlice(DistortionStruct, Slice, SliceDim)

idx = DistortionStruct.InputPoints(:,SliceDim) == Slice;
DistortionStructOut.InputPoints = DistortionStruct.InputPoints(idx, setdiff(1:3, SliceDim));
DistortionStructOut.TransPoints = DistortionStruct.TransPoints(idx, setdiff(1:3, SliceDim));
DistortionStructOut.Distortions = DistortionStruct.Distortions(idx, setdiff(1:3, SliceDim));

end
function DistortionStruct = GenDistortionVectors(Im, PixStep, InputFileName, ElastixPath, TransformixOutDir, ParamFile)

GenInputVectors(Im, PixStep, InputFileName);
system([sprintf('export PATH=%s ;',ElastixPath),...
    sprintf(' transformix -def %s -out %s -tp %s',InputFileName,TransformixOutDir,ParamFile)]);
transformData = readmatrix(sprintf('%s/outputpoints.txt',TransformixOutDir));
transformData(:,isnan(mean(transformData,1))) = [];

if ndims(Im) == 3
    DistortionStruct.InputPoints = transformData(:,5:7);
    DistortionStruct.TransPoints = transformData(:,11:13);
    DistortionStruct.Distortions = transformData(:,14:16);
elseif ismatrix(Im)
    DistortionStruct.InputPoints = transformData(:,4:5);
    DistortionStruct.TransPoints = transformData(:,8:9);
    DistortionStruct.Distortions = transformData(:,10:11);
end

end
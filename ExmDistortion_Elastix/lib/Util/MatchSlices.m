function [matchingSlices, corrMat] = MatchSlices(beforeImg, afterImg, Type, Slices, varargin)
% function to match depth based on image correlation after registration
% input: 
%   before and after expansion 4D images
% output:
%   matching_slices is a 2-element vector containing the slices in b and a
%   with the highest correlation after registration

if nargin < 3
    Slices.after = 1:size(afterImg,3);
    Slices.before = 1:size(beforeImg,3);
    Type = '';
elseif nargin < 4
    Slices.after = 1:size(afterImg,3);
    Slices.before = 1:size(beforeImg,3);
end

switch Type
    case 'Elastix'
        OutputDir = 'OutputDir/';
        ElastixPath = '';
        ParamFile = {'Parameters_Rigid.txt'};
        assignopts(who, varargin{:});
end

[optimizer, metric] = imregconfig('monomodal'); % registration parameters

% pre-allocate
numChans = size(beforeImg,4);
corrMat = zeros(length(Slices.before), length(Slices.after), numChans);  
matchingSlices = zeros(numChans, 2);

% compare all combinations of slices
for C = 1:numChans
    BestmovingRegistered = NaN(size(afterImg,1),size(afterImg,2));
    for i = Slices.before
        fixed = beforeImg(:,:,i,C);

        for j = Slices.after
            % prepare images for registration
            moving = afterImg(:,:,j,C);
%             moving = imhistmatch(moving, fixed);

            % perform registration
            switch Type
                case 'Elastix'
                    temp = elastix(moving, fixed, OutputDir, ParamFile, ElastixPath);
                case 'None'
                    temp = moving;
                case 'Default'
                    tform = imregtform(moving, fixed, 'similarity', optimizer, metric);
                    temp = imwarp(moving,tform,'OutputView',imref2d(size(fixed)));
            end
            
            % populate correlation matrix
            corrMat(Slices.before==i, Slices.after==j, C) = corr2(fixed, temp);
            tempCorr = corrMat(:,:,C);
        end
    end
    
    tmpCorrMat = corrMat(:,:,C);
    [beforeSlice, afterSlice] = find(tmpCorrMat == max(tmpCorrMat(:)));
    matchingSlices(C,:) = [Slices.before(beforeSlice), Slices.after(afterSlice)];
    disp(C);
end

end

function [] = GenInputVectors(RefIm, PixStep, InputFileName)

% Generate 3D or 2D vector file for transformix

    X = 1:PixStep:size(RefIm,1);
    Y = 1:PixStep:size(RefIm,2);
    
    if ndims(RefIm) == 3
        Z = 1:PixStep:size(RefIm,3);
    elseif ismatrix(RefIm)
        Z = 1;
    else
        error('Only 2D and 3D images allowed!!');
    end
    
    n = length(X)*length(Y)*length(Z);
    
    fid = fopen(InputFileName,'w');
    fprintf(fid, 'index\n%d\n', n);
    
    for x = X
        for y = Y
            for z = Z
                if ndims(RefIm) == 3
                    fprintf(fid, '%d %d %d\n', x,y,z);
                elseif ismatrix(RefIm)
                    fprintf(fid, '%d %d\n', x,y);
                end
            end
        end
    end
    fclose(fid);
end

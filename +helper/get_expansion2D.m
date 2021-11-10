function [exp_factor, scale] = get_expansion2D(tform, before_px_size, after_px_size)
    
    scale = 1/sqrt(det(tform.T));
    
    exp_factor = round(scale * after_px_size/before_px_size,1);

end
function I = LoadTif(tifFile)
% Load tiff file to array

    info = imfinfo(tifFile);
    tampon = imread(tifFile,'Index',1);
    F = length(info);
    I = zeros(size(tampon,1),size(tampon,2),F,'uint8');
    I(:,:,1) = tampon(:,:,1);
    tic
    wait_bar = waitbar(0,['Loading ',tifFile]);
    ind = 0;
    for i = 2:F
        if ind == 0, waitbar(i/F, wait_bar); end
        ind = ind + 1; if ind == 100, ind = 0; end
        tampon = imread(tifFile,'Index',i,'Info',info);
        I(:,:,i) = tampon(:,:,1);
    end
    close(wait_bar);
    temps = num2str(round(10*toc)/10);
    disp([tifFile ' open in ' num2str(temps) 's'])
end
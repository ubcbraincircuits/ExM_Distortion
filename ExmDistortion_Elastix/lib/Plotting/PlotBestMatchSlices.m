function [] = PlotBestMatchSlices(CorrMat, beforeExp, afterExp, afterReg, DistortionStruct, suptitleStr, plot_path)
fig = figure;
set(fig, 'Position', [0 0 1440 360]);

subplot(1,6,1);
h = heatmap(CorrMat);
xlabel('afterExp');
ylabel('beforeReg');
h.Colormap = jet;
title(sprintf('Corr'));

subplot(1,6,2);
imshow(beforeExp);
title('Before Exp');

subplot(1,6,3);
imshow(afterExp);
title('After Exp');

subplot(1,6,4);
imshow(afterReg);
title('After Reg');

InPoints = DistortionStruct.InputPoints;
Dists = DistortionStruct.Distortions;

subplot(1,6,5);
imshowpair(afterExp, afterReg);
hold on;
quiver(InPoints(:,1),InPoints(:,2),-1*Dists(:,1),-1*Dists(:,2));
title(sprintf('After Exp vs After Reg'));

subplot(1,6,6);
imshowpair(beforeExp, afterReg);
title(sprintf('Before vs After Reg, r = %.2f', corr(double(beforeExp(:)),double(afterReg(:)))));

suptitle(sprintf('Best Match Slices: %s',suptitleStr));
set(findall(gcf,'-property','FontSize'),'FontSize',15);
saveas(fig,fullfile(plot_path,sprintf('Summary_Plot.png')));

end
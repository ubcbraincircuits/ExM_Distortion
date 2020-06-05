function [] = PlotDistortion(pDist, err, nbins, suptitleStr, PlotPath)

[~,edges,bins] = histcounts(pDist(:,1), nbins);

bin_means=zeros(1,nbins);
for i = 1:nbins
  ind = bins == i;  
  bin_means(i) = mean(err(ind));
end

fig = figure;
set(fig, 'Position', [0 0 1440 720]);
subplot(121)
plot(edges(2:end), bin_means)
xlabel('Distance / px','fontsize',18)
ylabel('error / px','fontsize',18)
set(gca,'FontSize',18)
subplot(122)
plot(edges(2:end), 100*bin_means./edges(2:end))
xlabel('Distance / px','fontsize',18)
ylabel('error / %','fontsize',18);

suptitle(sprintf('Distortions - %s',suptitleStr));
set(findall(gcf,'-property','FontSize'),'FontSize',18);
saveas(fig,[PlotPath sprintf('Distortions.png')]);

end
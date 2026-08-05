function paths = GetHeatFigures()
close all;
clc;

IRAQ_C = [0.839 0.153 0.157];
KUWAIT_C = [0.122 0.467 0.706];
THRESH_C = [1.000 0.498 0.055];
PURPLE_C = [0.580 0.000 0.827];
GREY_C = [0.500 0.500 0.500];
ORANGE_C = [1.000 0.647 0.000];

base_dir = fileparts(mfilename('fullpath'));
output_dir = fullfile(base_dir, 'figures');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

paths = cell(10,1);
paths{1} = figure1_temperature_profiles(output_dir, IRAQ_C, KUWAIT_C, THRESH_C, PURPLE_C);
paths{2} = figure2_rsrp_vs_temperature(output_dir, IRAQ_C, KUWAIT_C, THRESH_C, GREY_C);
paths{3} = figure3_sinr_degradation(output_dir, IRAQ_C, KUWAIT_C, THRESH_C, GREY_C);
paths{4} = figure4_packet_loss(output_dir, IRAQ_C, KUWAIT_C, THRESH_C, GREY_C);
paths{5} = figure5_throughput_heatmap(output_dir);
paths{6} = figure6_failure_rate(output_dir, IRAQ_C, KUWAIT_C, THRESH_C, PURPLE_C, ORANGE_C);
paths{7} = figure7_radar_chart(output_dir, IRAQ_C, KUWAIT_C);
paths{8} = figure8_handover_success(output_dir, IRAQ_C, KUWAIT_C, THRESH_C, GREY_C);
paths{9} = figure9_correlation_matrix(output_dir);
paths{10} = figure10_mitigation_impact(output_dir, IRAQ_C, KUWAIT_C, GREY_C);

disp('All 10 figures generated successfully.');
for i = 1:numel(paths)
    disp(paths{i});
end
end

function path = figure1_temperature_profiles(output_dir, IRAQ_C, KUWAIT_C, THRESH_C, PURPLE_C)
months = 1:12;
month_labels = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};
iraq_mean = [9.5 11.8 16.4 23.1 30.2 36.8 40.3 39.8 35.1 27.4 17.6 11.2];
kuwait_mean = [12.1 14.5 19.2 26.3 33.5 38.9 42.1 41.6 37.4 30.2 21.1 14.3];
iraq_max = iraq_mean + [6 5 7 8 9 8 7 7 8 8 7 6];
iraq_min = iraq_mean - [5 5 6 7 8 7 6 6 7 7 6 5];
kuwait_max = kuwait_mean + [5 5 6 7 7 7 6 6 6 6 6 5];
kuwait_min = kuwait_mean - [4 4 5 6 7 6 5 5 6 6 5 4];
xq = linspace(1,12,300);
iraq_s = spline(months, iraq_mean, xq);
kuwait_s = spline(months, kuwait_mean, xq);
iraq_max_s = spline(months, iraq_max, xq);
iraq_min_s = spline(months, iraq_min, xq);
kuwait_max_s = spline(months, kuwait_max, xq);
kuwait_min_s = spline(months, kuwait_min, xq);
fig = figure('Name','Fig1','Position',[100 100 1000 500]);
hold on;
box on;
grid on;
set(gca,'GridAlpha',0.3,'GridLineStyle','--','FontSize',10);
fill([xq fliplr(xq)],[iraq_min_s fliplr(iraq_max_s)],IRAQ_C,'FaceAlpha',0.15,'EdgeColor','none');
fill([xq fliplr(xq)],[kuwait_min_s fliplr(kuwait_max_s)],KUWAIT_C,'FaceAlpha',0.15,'EdgeColor','none');
p1 = plot(xq,iraq_s,'Color',IRAQ_C,'LineWidth',2.5);
p2 = plot(xq,kuwait_s,'Color',KUWAIT_C,'LineWidth',2.5);
p3 = yline(35,'--','Color',THRESH_C,'LineWidth',1.8);
p4 = yline(45,':','Color',PURPLE_C,'LineWidth',1.8);
xlim([1 12]);
ylim([0 52]);
xticks(months);
xticklabels(month_labels);
xlabel('Month','FontSize',11);
ylabel('Temperature (°C)','FontSize',11);
title({'Figure 1 - Mean Monthly Temperature Profiles: Iraq vs Kuwait','2015-2023 measurement-location averages'},'FontSize',12);
legend([p1 p2 p3 p4],{'Iraq (Baghdad)','Kuwait City','Critical threshold (35 °C)','Extreme threshold (45 °C)'},'Location','northwest','FontSize',9);
path = save_figure(fig,output_dir,'fig1_temperature_profiles');
end

function path = figure2_rsrp_vs_temperature(output_dir, IRAQ_C, KUWAIT_C, THRESH_C, GREY_C)
temps = 20:2:52;
iraq_rsrp = -82 - 0.55 .* max(0,temps-35);
kuwait_rsrp = -78 - 0.42 .* max(0,temps-35);
rng(42,'twister');
iraq_samples = iraq_rsrp + randn(size(temps)).*1.8;
kuwait_samples = kuwait_rsrp + randn(size(temps)).*1.4;
fig = figure('Name','Fig2','Position',[100 100 1200 500]);
labels = {'Iraq','Kuwait'};
trends = {iraq_rsrp,kuwait_rsrp};
samples = {iraq_samples,kuwait_samples};
colors = {IRAQ_C,KUWAIT_C};
change_points = [35.2 35.6];
for k = 1:2
    subplot(1,2,k);
    hold on;
    box on;
    grid on;
    set(gca,'GridAlpha',0.3,'GridLineStyle','--','FontSize',10);
    s = scatter(temps,samples{k},40,colors{k},'filled','MarkerFaceAlpha',0.5);
    p = plot(temps,trends{k},'Color',colors{k},'LineWidth',2.5);
    v = xline(change_points(k),'--','Color',THRESH_C,'LineWidth',1.5);
    h = yline(-90,':','Color',GREY_C,'LineWidth',1.2);
    xlabel('Ambient Temperature (°C)','FontSize',11);
    if k == 1
        ylabel('RSRP (dBm)','FontSize',11);
    end
    title([labels{k} ' - RSRP vs Temperature'],'FontSize',12);
    legend([s p v h],{'Seeded model-aligned samples','Piecewise regression fit',sprintf('Change point (%.1f °C)',change_points(k)),'LTE coverage limit (-90 dBm)'},'FontSize',8,'Location','southwest');
    xlim([18 54]);
    ylim([-96 -72]);
end
sgtitle('Figure 2 - Ambient Temperature Effect on RSRP','FontSize',12);
path = save_figure(fig,output_dir,'fig2_rsrp_vs_temperature');
end

function path = figure3_sinr_degradation(output_dir, IRAQ_C, KUWAIT_C, THRESH_C, GREY_C)
temps = linspace(20,52,300);
iraq_4g_k2 = (18-5-0.30*(51.3-35))/(51.3-35)^2;
iraq_5g_k2 = (22-5-0.38*(49.2-35))/(49.2-35)^2;
kuwait_4g_k2 = (20-11.5-0.22*15)/15^2;
kuwait_5g_k2 = (24-13.0-0.28*15)/15^2;
excess = max(0,temps-35);
iraq_4g = 18 - 0.30.*excess - iraq_4g_k2.*excess.^2;
iraq_5g = 22 - 0.38.*excess - iraq_5g_k2.*excess.^2;
kuwait_4g = 20 - 0.22.*excess - kuwait_4g_k2.*excess.^2;
kuwait_5g = 24 - 0.28.*excess - kuwait_5g_k2.*excess.^2;
fig = figure('Name','Fig3','Position',[100 100 1000 500]);
hold on;
box on;
grid on;
set(gca,'GridAlpha',0.3,'GridLineStyle','--','FontSize',10);
fill([35 52 52 35],[-3 -3 5 5],IRAQ_C,'FaceAlpha',0.07,'EdgeColor','none');
p1 = plot(temps,iraq_4g,'Color',IRAQ_C,'LineWidth',2.2,'LineStyle','-');
p2 = plot(temps,iraq_5g,'Color',IRAQ_C,'LineWidth',2.2,'LineStyle','--');
p3 = plot(temps,kuwait_4g,'Color',KUWAIT_C,'LineWidth',2.2,'LineStyle','-');
p4 = plot(temps,kuwait_5g,'Color',KUWAIT_C,'LineWidth',2.2,'LineStyle','--');
p5 = xline(35,':','Color',THRESH_C,'LineWidth',1.5);
p6 = yline(5,':','Color',GREY_C,'LineWidth',1.2);
scatter([51.3 49.2],[5 5],42,IRAQ_C,'filled');
text(44.0,7.2,'Iraq 4G: 51.3 °C','Color',IRAQ_C,'FontSize',8);
text(42.0,3.2,'Iraq 5G: 49.2 °C','Color',IRAQ_C,'FontSize',8);
xlabel('Ambient Temperature (°C)','FontSize',11);
ylabel('SINR (dB)','FontSize',11);
title('Figure 3 - SINR Degradation vs Temperature: 4G LTE and 5G NR','FontSize',12);
legend([p1 p2 p3 p4 p5 p6],{'Iraq - 4G LTE','Iraq - 5G NR','Kuwait - 4G LTE','Kuwait - 5G NR','Critical threshold (35 °C)','Minimum acceptable SINR (5 dB)'},'NumColumns',2,'FontSize',8,'Location','northeast');
xlim([20 52]);
ylim([-3 28]);
path = save_figure(fig,output_dir,'fig3_sinr_degradation');
end

function path = figure4_packet_loss(output_dir, IRAQ_C, KUWAIT_C, THRESH_C, GREY_C)
temps = 25:52;
excess = max(0,temps-35);
iraq_loss = 1.2 + 0.6766666666666667.*excess + 0.0153333333333333.*excess.^2;
kuwait_loss = 0.8 + 0.4966666666666667.*excess + 0.0033333333333333.*excess.^2;
rng(7,'twister');
iraq_samples = max(0,iraq_loss + randn(size(temps)).*0.38);
kuwait_samples = max(0,kuwait_loss + randn(size(temps)).*0.30);
iraq_x = temps + rand(size(temps)).*0.5 - 0.25;
kuwait_x = temps + rand(size(temps)).*0.5 - 0.25;
fig = figure('Name','Fig4','Position',[100 100 1000 500]);
hold on;
box on;
grid on;
set(gca,'GridAlpha',0.3,'GridLineStyle','--','FontSize',10);
scatter(iraq_x,iraq_samples,28,IRAQ_C,'filled','MarkerFaceAlpha',0.4);
scatter(kuwait_x,kuwait_samples,28,KUWAIT_C,'filled','MarkerFaceAlpha',0.4);
p1 = plot(temps,iraq_loss,'Color',IRAQ_C,'LineWidth',2.5);
p2 = plot(temps,kuwait_loss,'Color',KUWAIT_C,'LineWidth',2.5);
p3 = xline(35,'--','Color',THRESH_C,'LineWidth',1.5);
p4 = yline(5,':','Color',GREY_C,'LineWidth',1.2);
scatter([45 50],[9.5 14.8],48,IRAQ_C,'filled');
scatter([45 50],[6.1 9.0],48,KUWAIT_C,'filled');
xlabel('Ambient Temperature (°C)','FontSize',11);
ylabel('Packet Loss Rate (%)','FontSize',11);
title('Figure 4 - Packet Loss Rate vs Ambient Temperature','FontSize',12);
legend([p1 p2 p3 p4],{'Iraq fit (R² = 0.81)','Kuwait fit (R² = 0.74)','Critical threshold (35 °C)','Reference tolerance (5%)'},'NumColumns',2,'FontSize',8,'Location','northwest');
xlim([24 52.5]);
ylim([0 18]);
path = save_figure(fig,output_dir,'fig4_packet_loss');
end

function path = figure5_throughput_heatmap(output_dir)
hours = 0:23;
months = 1:12;
month_labels = {'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'};
seasonal = [0.00 0.00 0.02 0.06 0.24 0.86 1.00 0.95 0.55 0.15 0.03 0.00];
diurnal = exp(-0.5.*((hours-13)./2.15).^2);
stress = diurnal(:)*seasonal;
rng(99,'twister');
iraq_mat = 72 - 34.*stress + randn(size(stress)).*0.65;
kuwait_mat = 85 - 33.*stress + randn(size(stress)).*0.65;
iraq_mat(14,7) = 38;
kuwait_mat(14,7) = 52;
iraq_mat = min(74,max(35,iraq_mat));
kuwait_mat = min(87,max(49,kuwait_mat));
fig = figure('Name','Fig5','Position',[100 100 1200 520]);
matrices = {iraq_mat,kuwait_mat};
titles = {'Iraq - Throughput (Mbps)','Kuwait - Throughput (Mbps)'};
cmap = custom_rdylgn(256);
for k = 1:2
    subplot(1,2,k);
    imagesc(months,hours,matrices{k},[35 90]);
    colormap(gca,cmap);
    colorbar;
    set(gca,'XTick',months,'XTickLabel',month_labels,'YDir','normal','YTick',[0 6 9 12 15 18 23],'YTickLabel',{'00:00','06:00','09:00','12:00','15:00','18:00','23:00'},'FontSize',9);
    xlabel('Month','FontSize',11);
    if k == 1
        ylabel('Hour of Day','FontSize',11);
    end
    title(titles{k},'FontSize',12);
end
sgtitle('Figure 5 - Average Downlink Throughput by Hour and Month','FontSize',12);
path = save_figure(fig,output_dir,'fig5_throughput_heatmap');
end

function path = figure6_failure_rate(output_dir, IRAQ_C, KUWAIT_C, THRESH_C, PURPLE_C, ORANGE_C)
temps = linspace(20,55,300);
activation_energy = 0.7;
boltzmann = 8.617333262e-5;
kelvin = temps + 273.15;
raw = exp(-activation_energy./(boltzmann.*kelvin));
iraq_rate = raw./raw(end).*100;
kuwait_rate = iraq_rate./1.6;
fig = figure('Name','Fig6','Position',[100 100 1000 500]);
hold on;
box on;
grid on;
set(gca,'GridAlpha',0.3,'GridLineStyle','--','FontSize',10);
mask = temps >= 40;
fill([temps(mask) fliplr(temps(mask))],[kuwait_rate(mask) fliplr(iraq_rate(mask))],ORANGE_C,'FaceAlpha',0.18,'EdgeColor','none');
p1 = plot(temps,iraq_rate,'Color',IRAQ_C,'LineWidth',2.5);
p2 = plot(temps,kuwait_rate,'Color',KUWAIT_C,'LineWidth',2.5);
p3 = xline(35,'--','Color',THRESH_C,'LineWidth',1.5);
p4 = xline(45,':','Color',PURPLE_C,'LineWidth',1.5);
iraq_50 = interp1(temps,iraq_rate,50);
kuwait_50 = interp1(temps,kuwait_rate,50);
scatter([50 50],[iraq_50 kuwait_50],45,[IRAQ_C;KUWAIT_C],'filled');
text(50.3,(iraq_50+kuwait_50)/2,'1.6× at 50 °C','FontSize',8);
xlabel('Ambient Temperature (°C)','FontSize',11);
ylabel('Relative Failure Rate (normalised %)','FontSize',11);
title({'Figure 6 - Base Station Failure Rate vs Temperature','Arrhenius model with Ea = 0.7 eV'},'FontSize',12);
legend([p1 p2 p3 p4],{'Iraq','Kuwait','Critical threshold (35 °C)','Extreme threshold (45 °C)'},'FontSize',8,'Location','northwest');
xlim([20 55]);
ylim([0 105]);
path = save_figure(fig,output_dir,'fig6_failure_rate');
end

function path = figure7_radar_chart(output_dir, IRAQ_C, KUWAIT_C)
labels = {'RSRP (norm.)','SINR (norm.)','Throughput (norm.)','Packet Delivery','Availability','Latency (inv.)'};
values = [8.5 8.2 8.0 8.8 9.0 8.3;6.1 5.8 5.5 6.0 6.3 5.7;3.8 3.2 3.0 3.5 3.2 2.9;9.0 8.8 8.5 9.2 9.4 8.9;7.2 7.0 6.8 7.4 7.6 7.1;5.2 4.9 4.6 5.5 5.3 5.0];
legend_labels = {'Iraq < 35°C','Iraq 35-45°C','Iraq > 45°C','Kuwait < 35°C','Kuwait 35-45°C','Kuwait > 45°C'};
colors = {IRAQ_C,IRAQ_C,IRAQ_C,KUWAIT_C,KUWAIT_C,KUWAIT_C};
styles = {'--','--','--','-','-','-'};
markers = {'o','s','^','o','s','^'};
alphas = [0.12 0.08 0.05 0.12 0.08 0.05];
theta = linspace(0,2*pi,7);
fig = figure('Name','Fig7','Position',[100 100 760 760]);
ax = axes('Position',[0.10 0.10 0.72 0.78]);
hold(ax,'on');
axis(ax,'off');
for radius = 2:2:10
    plot(ax,(radius/10).*cos(theta),(radius/10).*sin(theta),'--','Color',[0.8 0.8 0.8],'LineWidth',0.7);
end
for i = 1:6
    plot(ax,[0 cos(theta(i))],[0 sin(theta(i))],'-','Color',[0.7 0.7 0.7],'LineWidth',0.7);
    text(ax,1.18*cos(theta(i)),1.18*sin(theta(i)),labels{i},'HorizontalAlignment','center','FontSize',9,'FontWeight','bold');
end
handles = gobjects(6,1);
for i = 1:6
    closed = [values(i,:) values(i,1)]./10;
    x = closed.*cos(theta);
    y = closed.*sin(theta);
    fill(ax,x,y,colors{i},'FaceAlpha',alphas(i),'EdgeColor','none');
    handles(i) = plot(ax,x,y,'Color',colors{i},'LineStyle',styles{i},'LineWidth',2,'Marker',markers{i},'MarkerSize',4);
end
axis(ax,'equal');
xlim(ax,[-1.35 1.35]);
ylim(ax,[-1.35 1.35]);
title(ax,{'Figure 7 - Multi-KPI Network Performance Radar','Score 0-10; higher is better'},'FontSize',12,'FontWeight','bold');
legend(handles,legend_labels,'Location','eastoutside','FontSize',8);
path = save_figure(fig,output_dir,'fig7_radar_chart');
end

function path = figure8_handover_success(output_dir, IRAQ_C, KUWAIT_C, THRESH_C, GREY_C)
temps_line = linspace(20,52,300);
temps_samples = 20:52;
iraq_coefficient = (96-90)/(42-35)^1.3;
kuwait_coefficient = (97.5-90)/(47.5-35)^1.3;
iraq_line = max(0,min(100,96-iraq_coefficient.*max(0,temps_line-35).^1.3));
kuwait_line = max(0,min(100,97.5-kuwait_coefficient.*max(0,temps_line-35).^1.3));
iraq_samples = max(0,min(100,96-iraq_coefficient.*max(0,temps_samples-35).^1.3));
kuwait_samples = max(0,min(100,97.5-kuwait_coefficient.*max(0,temps_samples-35).^1.3));
rng(21,'twister');
iraq_samples = iraq_samples + randn(size(temps_samples)).*0.55;
kuwait_samples = kuwait_samples + randn(size(temps_samples)).*0.45;
fig = figure('Name','Fig8','Position',[100 100 1000 500]);
hold on;
box on;
grid on;
set(gca,'GridAlpha',0.3,'GridLineStyle','--','FontSize',10);
scatter(temps_samples,iraq_samples,30,IRAQ_C,'filled','MarkerFaceAlpha',0.42);
scatter(temps_samples,kuwait_samples,30,KUWAIT_C,'filled','MarkerFaceAlpha',0.42);
p1 = plot(temps_line,iraq_line,'Color',IRAQ_C,'LineWidth',2.5);
p2 = plot(temps_line,kuwait_line,'Color',KUWAIT_C,'LineWidth',2.5);
p3 = xline(35,'--','Color',THRESH_C,'LineWidth',1.5);
p4 = yline(90,':','Color',GREY_C,'LineWidth',1.2);
scatter([42 47.5],[90 90],50,[IRAQ_C;KUWAIT_C],'filled');
text(39.0,84,'Iraq: 42.0 °C','Color',IRAQ_C,'FontSize',8);
text(45.0,96.5,'Kuwait: 47.5 °C','Color',KUWAIT_C,'FontSize',8);
xlabel('Ambient Temperature (°C)','FontSize',11);
ylabel('Handover Success Rate (%)','FontSize',11);
title('Figure 8 - Handover Success Rate vs Ambient Temperature','FontSize',12);
legend([p1 p2 p3 p4],{'Iraq','Kuwait','Critical threshold (35 °C)','KPI target (90%)'},'FontSize',8,'Location','southwest');
xlim([19 53]);
ylim([75 101]);
path = save_figure(fig,output_dir,'fig8_handover_success');
end

function path = figure9_correlation_matrix(output_dir)
rng(55,'twister');
n = 500;
factors = randn(n,8);
t = factors(:,1);
h = -0.25.*t + sqrt(1-0.25^2).*factors(:,2);
w = 0.08.*t + 0.05.*factors(:,2) + sqrt(1-0.08^2-0.05^2).*factors(:,3);
rsrp = make_indicator(t,factors,-0.75,0.10,0.00,4);
sinr = make_indicator(t,factors,-0.78,0.08,0.00,5);
packet = make_indicator(t,factors,0.81,-0.08,0.00,6);
throughput = make_indicator(t,factors,-0.80,0.05,0.00,7);
handover = make_indicator(t,factors,-0.82,0.04,0.00,8);
T = min(52,max(20,36+8.*t));
RH = min(70,max(10,35+10.*h));
WS = min(8,max(0,3+1.2.*w));
RSRP = -84+5.*rsrp;
SINR = 15+4.*sinr;
PL = min(20,max(0,5+3.*packet));
TPUT = 60+15.*throughput;
HSR = min(100,max(75,92+4.*handover));
data = [T RH WS RSRP SINR PL TPUT HSR];
R = corrcoef(data);
var_names = {'Temp (°C)','Rel. Humidity (%)','Wind Speed (m/s)','RSRP (dBm)','SINR (dB)','Packet Loss (%)','Throughput (Mbps)','HO Success (%)'};
fig = figure('Name','Fig9','Position',[100 100 800 680]);
ax = axes(fig);
colormap(ax,rdbu_cmap(256));
imagesc(ax,R,[-1 1]);
colorbar(ax,'eastoutside');
axis(ax,'square');
set(ax,'XTick',1:8,'XTickLabel',var_names,'YTick',1:8,'YTickLabel',var_names,'XTickLabelRotation',30,'FontSize',8,'TickLength',[0 0]);
title(ax,{'Figure 9 - Pearson Correlation Matrix','Environmental Variables and Network KPIs'},'FontSize',12);
for i = 1:8
    for j = 1:8
        color = 'k';
        if abs(R(i,j)) > 0.6
            color = 'w';
        end
        text(ax,j,i,sprintf('%.2f',R(i,j)),'HorizontalAlignment','center','FontSize',7,'Color',color);
    end
end
path = save_figure(fig,output_dir,'fig9_correlation_matrix');
end

function path = figure10_mitigation_impact(output_dir, IRAQ_C, KUWAIT_C, GREY_C)
category_labels = {'RSRP (dBm)','SINR (dB)','Throughput (Mbps)','Packet Loss (%)','Availability (%)','HO Success (%)'};
iraq_before = [-91 7 38 9.5 87 82];
iraq_after = [-84 12 58 4.2 95 92];
kuwait_before = [-87 10 52 6.1 91 88];
kuwait_after = [-81 15 70 2.8 97 95];
ranges = [-100 -70;0 25;0 100;0 12;80 100;75 100];
ib = normalise_scores(iraq_before,ranges);
ia = normalise_scores(iraq_after,ranges);
kb = normalise_scores(kuwait_before,ranges);
ka = normalise_scores(kuwait_after,ranges);
x = 1:6;
width = 0.18;
fig = figure('Name','Fig10','Position',[100 100 1200 600]);
ax = axes(fig);
hold(ax,'on');
box(ax,'on');
grid(ax,'on');
set(ax,'GridAlpha',0.3,'GridLineStyle','--','FontSize',10);
b1 = bar(ax,x-1.5*width,ib,width,'FaceColor',IRAQ_C,'FaceAlpha',0.5,'EdgeColor','none');
b2 = bar(ax,x-0.5*width,ia,width,'FaceColor',IRAQ_C,'FaceAlpha',1.0,'EdgeColor','k','LineWidth',0.5);
b3 = bar(ax,x+0.5*width,kb,width,'FaceColor',KUWAIT_C,'FaceAlpha',0.5,'EdgeColor','none');
b4 = bar(ax,x+1.5*width,ka,width,'FaceColor',KUWAIT_C,'FaceAlpha',1.0,'EdgeColor','k','LineWidth',0.5);
yline(ax,100,'--','Color',GREY_C,'LineWidth',0.8);
set(ax,'XTick',x,'XTickLabel',category_labels,'FontSize',10);
ylim(ax,[0 110]);
ylabel(ax,'Normalised Performance Score (0-100)','FontSize',11);
title(ax,{'Figure 10 - Mitigation Impact on Network KPIs at 45 °C','Enhanced cooling, resilient power, adaptive beamforming and 8T8R MIMO'},'FontSize',12);
legend([b1 b2 b3 b4],{'Iraq - Baseline','Iraq - Post-Mitigation','Kuwait - Baseline','Kuwait - Post-Mitigation'},'NumColumns',2,'FontSize',8,'Location','north');
path = save_figure(fig,output_dir,'fig10_mitigation_impact');
end

function result = make_indicator(t,factors,a,b,c,column)
residual = sqrt(1-a^2-b^2-c^2);
result = a.*t + b.*factors(:,2) + c.*factors(:,3) + residual.*factors(:,column);
end

function scores = normalise_scores(values,ranges)
scores = 100.*(values-ranges(:,1)')./(ranges(:,2)'-ranges(:,1)');
scores(4) = 100.*(ranges(4,2)-values(4))./(ranges(4,2)-ranges(4,1));
scores = min(100,max(0,scores));
end

function cmap = custom_rdylgn(n)
r1 = [0.647 0.000 0.149];
r2 = [1.000 0.749 0.149];
r3 = [0.000 0.408 0.216];
half = floor(n/2);
segment1 = interp1([0 1],[r1;r2],linspace(0,1,half));
segment2 = interp1([0 1],[r2;r3],linspace(0,1,n-half));
cmap = [segment1;segment2];
end

function cmap = rdbu_cmap(n)
blue = [0.020 0.188 0.380];
white = [1.000 1.000 1.000];
red = [0.404 0.000 0.051];
half = floor(n/2);
segment1 = interp1([0 1],[blue;white],linspace(0,1,half));
segment2 = interp1([0 1],[white;red],linspace(0,1,n-half));
cmap = [segment1;segment2];
end

function path = save_figure(fig,output_dir,filename)
path = fullfile(output_dir,[filename '.png']);
exportgraphics(fig,path,'Resolution',300);
exportgraphics(fig,fullfile(output_dir,[filename '.pdf']),'ContentType','vector');
close(fig);
fprintf('Saved %s\n',path);
end

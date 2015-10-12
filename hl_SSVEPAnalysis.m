addpath(genpath('/users2/purpadmin/Hsin/fieldtrip'));
addpath(genpath('/users2/purpadmin/Hsin/meg_utils'));
addpath(genpath('/users2/purpadmin/Hsin/myFunc'))
ft_defaults

%% %Set data to analyze
subjid    = 'HK';
exptDir   = '/Volumes/DRIVE1/DATA/hsin/MEG/BR';
fileBase  = 'R0978_BR_8.6.15';
load data_hdr

dataDir   = sprintf('%s/%s/%s', exptDir,subjid,fileBase);
logDir    = sprintf('%s/%s/%s/log', exptDir,subjid,fileBase);
preprocDir= sprintf('%s/preproc', dataDir);
xanaDir   = sprintf('%s/analysis', dataDir);
figDir    = sprintf('%s/%s', xanaDir, 'figures');
analStr   = 'bhlei';
fileName  = sprintf('%s/%s_%s.sqd',preprocDir,fileBase,analStr);
ft_datafileName = sprintf('%s/%s_%s_ft.mat',dataDir,fileBase,analStr); %This is the epoched file in ft format
dataMatrixName  = sprintf('%s/%s_%s_dataMatrix.mat',dataDir,fileBase,analStr); %This is the epoched data in a matrix
satInfoName     = sprintf('%s/%s_satInfo.mat',preprocDir,fileBase);
badEpochIdxName = sprintf('%s/%s_%s_badEpochIdx.mat',preprocDir,fileBase,analStr);

% make the dir if it doesn't exist
if ~exist(xanaDir,'dir')
    fprintf('Generating analysis directory\n');
    mkdir(xanaDir)
end
if ~exist(figDir,'dir')
    fprintf('Generating analysis figure directory\n');
    mkdir(figDir)
end

logInfo = what(logDir);
try load(sprintf('%s/%s',logDir,logInfo.mat{1}))
catch
    fprintf('no log loaded \n')
end
file_to_load     = 'trial';
getavedataMatrix = 0;
savefile_ave     = 0;
savename_ave     = sprintf('%s/%s_%s_avedataMatrix.mat',dataDir,fileBase,analStr);
%%
switch file_to_load
    case 'trial'
        fprintf('------loading data mat file------\n')
        load(dataMatrixName)
        %dataMatrix = dataMatrix*10^15;
    case 'average'
        fprintf('------loading data mat file------\n')
        load(savename_ave)
end
fprintf('------loading EpochInfo mat file------\n')
load(badEpochIdxName)
fprintf('------loading Saturation mat file------\n')
load(satInfoName)
%% average trials within condition. can be used for phase-locked power analysis (SSVEP)
if getavedataMatrix == 1
    
    nSamples = size(dataMatrix,1);
    nChan    = size(dataMatrix,2);
    nCond    = 15;
    avedataMatrix = nan(nSamples,nChan,nCond);
    avedataMatrix_ntrial = nan(nCond,1);

    for cond = 1:nCond
        condIdx = triggerNumber == cond & badEpochIdx_stat' == 0;
        avedataMatrix(:,:,cond) = mean(dataMatrix(:,:,condIdx),3);
        avedataMatrix_ntrial(cond) = sum(condIdx);
    end
    if savefile_ave == 1
        fprintf('------Saving average time course------ \n')
        save(savename_ave, 'avedataMatrix', 'nSamples', 'nChan', 'nCond', 'tstart', 'tend','Fs','t');
    end
end
%% Get PowerDensity Evoked power
t  = -500:3500;
Fs = 1000;
f1 = 15;
t1 = 3000;
t2 = 3500;
ncond = 8;

selectIdx   = t<0;
tagFreq     = f1*2;
tempMatrix  = dataMatrix(selectIdx,:,:);
[fre_b,pds_b_tr,fc_b_tr,resolution_b,leakageIdx_b] = getPowerDensity(tempMatrix,Fs,tagFreq);

tagFreq   = f1*2;
selectIdx = t>=t1 & t<t2;
tempMatrix_1 = dataMatrix(selectIdx,:,:);
[fre,pds_tr,fc_tr,resolution,leakageIdx] = getPowerDensity(tempMatrix_1,Fs,tagFreq);

goodIdx = badEpochIdx_all' == 0 & badEpochIdx_bc'==0;
ipds_b = mean(pds_b_tr(:,:,goodIdx),3);    
epds_b = abs(mean(fc_b_tr(:,:,goodIdx),3));
ipds   = nan(length(fre), 157, ncond); %induced power
ipds_v = nan(length(fre), 157, ncond); %induced power variance
epds   = nan(length(fre), 157, ncond); %evoked power
ephs   = nan(length(fre), 157, ncond); %evoked power phase
%plv    = nan(length(fre), 157, ncond);
ntrial = nan(1,ncond);
for cond = 1:ncond;
    %if cond == 6
    %   cond = [6 7 8];
    %end
    Idx = ismember(triggerNumber,cond) & goodIdx;
    cond = cond(1);
    temp_pds = pds_tr(:,:,Idx);
    temp_fc  = fc_tr(:,:,Idx);
    ipds(:,:,cond)   = mean(temp_pds,3);
    ipds_v(:,:,cond) = std(temp_pds,[],3);
    epds(:,:,cond)   = abs(mean(temp_fc,3));
    ephs(:,:,cond)   = angle(mean(temp_fc,3));
    ntrial(cond)     = sum(Idx);
end
disp(ntrial)
%%
nchan   = 10;
condIdx = 1:6;
temppds = mean(epds(:,:,condIdx),3);
temppds = temppds(fre==30,:);
[~,maxchan]  = sort(temppds,'descend');
chan_to_plot = maxchan(1:nchan);
chan_max     = maxchan(1);

temp = zeros(1,157);
temp(chan_to_plot) = 1;
cfg.colorbar  = 'no';
cfg.colormap  = [1 1 1; 0 0 0];
cfg.maplimits = [0 1];
hl_topoplot_2d(temp,[],cfg,[.4 .4],'Channel selected')
temp = sprintf('%s/%d_%dms_nchan = %d', figDir,t1,t2,nchan);
saveas(gcf,temp,'eps')
%% plot power on Mesh
fre_to_plot = 30;
for cond = 1:8
    sensorData  = epds(fre == fre_to_plot,:,cond);
    SNR         = sensorData;
    
    temptitle = sprintf('Power. contrast level %d; Frequency: %d Hz', cond, fre_to_plot);
    cfg = [];
    cfg.maplimits = [0 15];
    hl_topoplot_2d(SNR,[],cfg,[.5 .5],temptitle)
    temp = sprintf('%s/%d_%dms_topo_%dHz_c%d', figDir,t1,t2,fre_to_plot,cond);
    saveas(gcf,temp,'epsc')
end
%% Evoked Power spectrum
cond = condIdx;
f1   = 15;
f2   = f1*2;
chan = chan_to_plot;

%Plot Evoked power
frerange = fre>=0 & fre<=60;
cpsFigure(1,.5); hold on;
tempdata = squeeze(mean(epds(frerange,chan,cond),2));
plot(fre(frerange), tempdata,'-','Linewidth',2)
legend('1','2','3','4','5','6','7','8')

frerange = fre_b>=0 & fre_b<=60;
h1=plot(fre_b(frerange), mean(epds_b(frerange,chan),2),'k-o','LineWidth',2);
plot([f1 f1],[0 max(tempdata(:))+20],'--k',[f2 f2],[0 max(tempdata(:))+20],'--k');

xlim([0 60])
ylim([0 30])
xlabel('Hz')
ylabel('Power')
title(['Evoked power. chan ',num2str(chan)],'FontSize',14)

frerange = fre>=0 & fre<=60;
cpsFigure(1,.5); hold on;
tempdata = squeeze(mean(epds(frerange,chan,[7 8]),2));
plot(fre(frerange), tempdata,'-','Linewidth',2)
legend('small','large')

frerange = fre_b>=1 & fre_b<=60;
h2=plot(fre_b(frerange), mean(epds_b(frerange,chan),2),'k-o','LineWidth',2);

xlim([0 60])
ylim([0 30])
xlabel('Hz')
ylabel('Power')
title(['Evoked power. chan ',num2str(chan)],'FontSize',14)

temp = sprintf('%s/%d_%dms_evoked_pds_1', figDir,t1,t2);
saveas(h1,temp,'epsc')
temp = sprintf('%s/%d_%dms_evoked_pds_2', figDir,t1,t2);
saveas(h2,temp,'epsc')
%% Induced power Spectrum
cond = condIdx;
f1   = 15;
f2   = f1*2;

%induced power in target only condition
frerange = fre>=1 & fre<=60;
cpsFigure(1,.5); hold on;
tempdata = squeeze(mean(ipds(frerange,chan,cond),2));
plot(fre(frerange), tempdata,'-','Linewidth',2);
legend('1','2','3','4','5','6')
h1 = gcf;

xlim([0 60])
ylim([0 100])
xlabel('Hz','FontSize',16)
ylabel('Power','FontSize',16)
title(['Induced power. chan ',num2str(chan)],'FontSize',16)

%std of induced power in target only condition
frerange = fre>=1 & fre<=60;
cpsFigure(1,.5); hold on;
tempdata = squeeze(mean(ipds_v(frerange,chan,cond),2));
plot(fre(frerange), tempdata,'-','Linewidth',2);
legend('1','2','3','4','5','6')
h2 = gcf;

xlim([0 60])
ylim([0 100])
xlabel('Hz','FontSize',16)
ylabel('Std','FontSize',16)
title(['Std of induced power. channel ',num2str(chan)],'FontSize',16)

%induced power in competitor condition
frerange = fre>=1 & fre<=60;
cpsFigure(1,.5); hold on;
tempdata = squeeze(mean(ipds(frerange,chan,[7 8]),2));
plot(fre(frerange), tempdata,'-','Linewidth',2)
legend('small','large')

xlim([0 60])
ylim([0 100])
xlabel('Hz','FontSize',16)
ylabel('Power','FontSize',16)
title(['channel ',num2str(chan)],'FontSize',16)

temp = sprintf('%s/%d_%dms_induced_pds', figDir,t1,t2);
saveas(h1,temp,'epsc')
temp = sprintf('%s/%d_%dms_induced_vpds', figDir,t1,t2);
saveas(h2,temp,'epsc')
%% plot evoked power CRF
%contrast    = [0.1250    0.2500    0.5000    0.7500    0.9800];
contrast    = 1:8;
fre_to_plot = f2;
cond        = 1:8;
shift       = resolution*1;

chan          = chan_to_plot;
sensorData    = squeeze(mean((epds(fre==fre_to_plot,chan,cond)),2));
baselinefre_h = fre_to_plot+shift;
baseline_h    = squeeze(mean((epds(fre==baselinefre_h,chan,cond)),2));
baselinefre_l = fre_to_plot-shift;
baseline_l    = squeeze(mean((epds(fre==baselinefre_l,chan,cond)),2));
SNR = sensorData ./ ((baseline_h+baseline_l) / 2);

cpsFigure(.5,1.3);
subplot(2,1,1)
semilogx(contrast,sensorData','-o','LineWidth',2); hold on;
ylim([0 16])
ylabel('Power','FontSize',14)
title(sprintf('CRF %d Hz \n chan %s; ', fre_to_plot, num2str(chan)),'FontSize',12)

subplot(2,1,2)
semilogx(contrast,SNR','-o','LineWidth',2); hold on;
ylim([0 10])
ylabel('SNR','FontSize',14)
xlabel('log contrast','FontSize',14)
title(sprintf('%d Hz \n chan %s; ', fre_to_plot, num2str(chan)),'FontSize',12)
tightfig;

temp = sprintf('%s/%d_%dms_CRF', figDir,t1,t2);
saveas(gcf,temp,'epsc')
%% Plot Phase
fre_to_plot = f2;
cond = 1:6;

chan = chan_to_plot;
sensorData = squeeze(mean((ephs(fre==fre_to_plot,chan,cond)),2));
cpsFigure(.75,.5);
polar(pi,1);hold on;
cm = jmaColors('italy',[],length(cond));
for c = 1:length(sensorData)
    po = polar(sensorData(c),1,'o');
    set(po,'MarkerSize',8,'MarkerFaceColor',cm(c,:))
end
legend({'','1','2','3','4','5','6','7','8'},'Location','Best')

cond = 7:8;
sensorData = squeeze(mean((ephs(fre==fre_to_plot,chan,cond)),2));
for c = 1:length(sensorData)
    po = polar(sensorData(c),1,'o');
    set(po,'MarkerSize',10,'MarkerEdgeColor',cm(c,:));
end
legend({'','1','2','3','4','5','6','sm','large'},'Location','Best')
tightfig;

temp = sprintf('%s/%d_%dms_phase', figDir,t1,t2);
saveas(gcf,temp,'epsc')
%% plot induced power CRF
contrast    = [0.1250    0.2500    0.5000    0.7500    0.9800];
contrast    = 1:8;
fre_to_plot = f2;
cond        = 1:8;
shift       = resolution;

chan          = chan_to_plot;
sensorData    = squeeze(mean((ipds(fre==fre_to_plot,chan,cond)),2));
baselinefre_h = fre_to_plot+shift;
baseline_h    = squeeze(mean((ipds(fre==baselinefre_h,chan,cond)),2));
baselinefre_l = fre_to_plot-shift;
baseline_l    = squeeze(mean((ipds(fre==baselinefre_l,chan,cond)),2));
SNR = sensorData ./ ((baseline_h+baseline_l) / 2);

cpsFigure(.5,1.3);
subplot(2,1,1)
semilogx(contrast, sensorData','-o','LineWidth',2); hold on;
ylabel('Power','FontSize',14)
title(sprintf('iCRF %d Hz \n Chan %s; ', fre_to_plot, num2str(chan)),'FontSize',14)

subplot(2,1,2)
semilogx(contrast, SNR','-o','LineWidth',2); hold on;
%xlim([.1 1])
ylim([1 2])
ylabel('SNR','FontSize',14)
xlabel('log contrast','FontSize',14)
title(sprintf('%d Hz \n Chan %s; ', fre_to_plot, num2str(chan)),'FontSize',14)
tightfig;
h1 = gcf;

cpsFigure(.5,.5);
sensorData = squeeze(mean((ipds_v(fre==fre_to_plot,chan,cond)),2));
semilogx(contrast, sensorData','-o','LineWidth',2); hold on;
%xlim([.1 1])
ylabel('Std','FontSize',14)
xlabel('log contrast','FontSize',14)
title(sprintf('%d Hz \n Chan %s; ', fre_to_plot, num2str(chan)),'FontSize',14)
tightfig;
h2 = gcf;

temp = sprintf('%s/%d_%dms_iCRF', figDir,t1,t2);
saveas(h1,temp,'epsc')
temp = sprintf('%s/%d_%dms_iCRF_std', figDir,t1,t2);
saveas(h2,temp,'epsc')

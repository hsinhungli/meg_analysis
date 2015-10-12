addpath(genpath('/users2/purpadmin/Hsin/fieldtrip'));
addpath(genpath('/users2/purpadmin/Hsin/eeglab13_4_4b'));
ft_defaults

%% Set data to analyze
subjid    = 'LH';
exptDir   = '/Volumes/DRIVE1/DATA/hsin/MEG/BR';
fileBase  = 'R0959_BR_6.2.15';

dataDir   = sprintf('%s/%s/%s', exptDir,subjid,fileBase);
preprocDir= sprintf('%s/preproc', dataDir);
analStr   = 'elbi';

savefile  = 1;
savename  = sprintf('%s/%s_dataMatrix.mat',dataDir,fileBase);
if exist(savename,'file') == 0;
    %%
    fprintf('------generating new data mat file------')
    % remember, these channel numbers use zero indexing
    megChan   = 0:156;
    refChan   = 157:159;
    trigChan  = 160:163; %This can be 160~167 depends on what channels are used in the exp
    photoChan = 191;
    getChan   = megChan;
    
    tstart = -500;
    tend   = 3500;
    t      = tstart:tend;
    
    fileName  = sprintf('%s/%s_%s.sqd',preprocDir,fileBase,analStr);
    
    logfileName = sprintf('%s/logfile/%s',dataDir,'LH_EXP_1506031053');
    load(logfileName,'trialInfo','timing','expPar');
    
    %% GetdataMatrix
    [dataMatrix,trigger,Fs] = hl_getData(fileName, trigChan, getChan, tstart, tend);
    %dataMatrix: time x channel x nepoch
    
    nSamples = size(dataMatrix,1);
    nChan    = size(dataMatrix,2);
    nEpoch   = size(dataMatrix,3);
    
    %% save data if required
    if savefile
        save(savename,'-v7.3');
    end
else 
    fprintf('------loading data mat file------')
    load(savename)
end

%% average trials within condition for phase-locked power analysis (SSVEP)
selectIdx  = 1:612;
dataMatrix = dataMatrix(:,:,1:612);
trigger    = trigger(1:612,:);
nCond = 12;
avedataMatrix = nan(nSamples,nChan,nCond);
for cond = 1:nCond
    condIdx    = trigger(:,2) == cond;
    avedataMatrix(:,:,cond) = mean(dataMatrix(:,:,condIdx),3);
end
%clear dataMatrix

%% Get PowerDensity
selectIdx = t>=0 & t<3000;
tagFrequency = 6;
tempMatrix   = avedataMatrix(selectIdx,:,1:6);
[fre, pds]   = getPowerDensity(tempMatrix,Fs,tagFrequency);

selectIdx = t<0;
tagFrequency = 6;
tempMatrix   = avedataMatrix(selectIdx,:,1:6);
tempMatrix   = mean(tempMatrix,3);
[fre_baseline, pds_baseline]   = getPowerDensity(tempMatrix,Fs,tagFrequency);
%% plot selected data
cond    = 1:6;
chan    = 5; 
frerange = fre>=1 & fre<=30;

figure; hold on;
plot(fre(frerange), squeeze(pds(frerange,chan,cond)),'-o')
legend('1','2','3','4','5','6')

frerange = fre_baseline>=1 & fre_baseline<=30;
plot(fre_baseline(frerange), pds_baseline(frerange,chan),'k-o','LineWidth',1.5)
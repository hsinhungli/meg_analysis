% For visual inspection after the first-stage preprocessing has been done.
% The preprocessed file should have an tag defined by analStr in its
% filename. This script calls that preprocessed file for visual inspection
addpath(genpath('/users2/purpadmin/Hsin/eeglab13_4_4b'));
addpath(genpath('/users2/purpadmin/Hsin/fieldtrip'));
addpath(genpath('/users2/purpadmin/Hsin/meg_utils-master'));
addpath(genpath('/users2/purpadmin/Hsin/myFunc'));
addpath(genpath('/users2/purpadmin/Hsin/denoise'));

ft_defaults

%%
subjid    = 'MR';
exptDir   = '/Volumes/DRIVE1/DATA/hsin/MEG/BR';
fileBase  = 'R0983_BR_8.20.15';

dataDir   = sprintf('%s/%s/%s', exptDir,subjid,fileBase);
preprocDir= sprintf('%s/preproc', dataDir);
figDir    = sprintf('%s/%s', preprocDir, 'figures');
analStr   = 'bhlei';
fileName  = sprintf('%s/%s_%s.sqd',preprocDir,fileBase,analStr);
ft_datafileName = sprintf('%s/%s_%s_ft.mat',dataDir,fileBase,analStr); %This is the epoched file in ft format
dataMatrixName  = sprintf('%s/%s_%s_dataMatrix.mat',dataDir,fileBase,analStr); %This is the epoched data in a matrix
satMatrixName   = sprintf('%s/%s_satMatrix.mat',preprocDir,fileBase);
badEpochIdxName = sprintf('%s/%s_%s_badEpochIdx.mat',preprocDir,fileBase,analStr);
badEpochs       = [];

% remember, these channel numbers use zero indexing
megChan   = 0:156;
refChan   = 157:159;
trigChan  = 160:163;  %This can be 160~167 if ALL the trigger channels are used in the experiment
photoChan = 191;
getChan   = megChan;
Fs        = 1000;

loaddataMatrix  = 1;
saveEpochedFile = 0;
savedataMatrix  = 0;
getsatMatrix    = 1;
%% get epoch from continuous data
if exist(ft_datafileName,'file') == 0  %Check whether this sqd file has been epoched before and saved already
    fprintf('generating epoched file\n')
    
    tstart = -500;
    tend   = 3500;
    t      = tstart:tend;
    [trl,triggerNumber] = hl_gettrlinfo(fileName, trigChan, tstart, tend);
    ntrial = size(trl,1);
    
    prep_data = ft_preprocessing(struct('dataset',fileName,...
        'channel','MEG','continuous','yes','trl',trl));
    if saveEpochedFile == 1
        fprintf('saving new epoched file in ft structure\n')
        save(ft_datafileName, 'prep_data','-v7.3');
    end
    if savedataMatrix == 1;
        fprintf('saving dataMatrix in mat file\n')
        dataMatrix = cell2mat(prep_data.trial);
        dataMatrix = reshape(dataMatrix,[length(megChan), length(t), ntrial]);
        dataMatrix = permute(dataMatrix,[2 1 3]) * 10^15; %dataMatrix: time x chan x epoch
        save(dataMatrixName,'dataMatrix','tstart','tend','triggerNumber','Fs','t','-v7.3');
    end
else
    %load epoched data
    fprintf('loading previous epoched ft file\n')
    load(ft_datafileName)
    if loaddataMatrix == 1;
        fprintf('loading previous epoched dataMatrix\n')
        load(dataMatrixName)
    end
end

%% Get saturation matrix
%eegplot(permute(dataMatrix,[2 1 3]),'srate',Fs,'winlength',1,'dispchans',80);
%eegplot(dataMatrix,'srate',Fs,'winlength',20,'dispchans',80,'position',windowSize);

% windowSize  = 20;
% plotFig     = 1;
% rawfileName = sprintf('%s/%s.sqd',dataDir,fileBase);
% [rawdataMatrix,trigger,Fs] = hl_getData(rawfileName, trigChan, megChan+1, tstart, tend);
% satMatrix   = hl_find_saturation(rawdataMatrix, windowSize, plotFig);
% save(satMatrixName,'satMatrix');
% clear rawdataMatrix

%% ICA
% cfg     = [];
% badChan = [21 65 41 120 153];
% chan_to_run = megChan+1;
% chan_to_run(badChan) = [];
% cfg.channel = megChan+1;
% cfg.method  = 'runica';
% cfg.numcomponent = 50;
% ica_data_set = ft_componentanalysis(cfg,prep_data);

%% Check bad epoch using variance of channel and number of bad channel withn an epoch
var_thresh = [.1 10]; 
nbadchannel_thresh = 10;
[bad_epochs_auto, bad_epochs_2D, ~] = hl_find_bad_epoch(permute(dataMatrix,[1 3 2]), var_thresh, nbadchannel_thresh, 1);
disp(find(bad_epochs_auto)')
%% Check variance and kurtosis for each trial
var_ub = 1.5; 
kur_ub = 1.5;
skew_b = 2;
[bad_epochs_var, bad_epochs_kur, bad_epochs_skew] = hl_trialvariance(dataMatrix, var_ub, kur_ub, skew_b);
disp(find(bad_epochs_var));
disp(find(bad_epochs_kur));
disp(find(bad_epochs_skew));
%% ft_rejectvisual (summary mode)
cfg           = [];
cfg.ylim      = 1e-12;  % scaling (10 fT/cm)
cfg.megscale  = 1;
cfg.channel   = 'MEG';
cfg.keeptrial = 'nan';
dummy         = ft_rejectvisual(cfg,prep_data);

bad_epochs_summary = zeros(1, length(dummy.trial));
for ievent = 1:length(dummy.trial)
    bad_epochs_summary(ievent) = isnan(dummy.trial{ievent}(1));
    if bad_epochs_summary(ievent) == 1;
        fprintf('Trial %d selected as a bad trial\n', ievent)
    end
end
fprintf('There are %d bad trials selected in this dataset\n',sum(bad_epochs_summary))
cpsFigure(.5,1.5);
imagesc(bad_epochs_summary'); title('bad epochs summary','FontSize',18); colormap(gray); hold on;
tempIdx = bad_epochs_auto' | bad_epochs_summary;
disp(find(tempIdx))
%% ft_databrowser: Butterfly: Grand
cfg          = [];
cfg.continuous = 'no';
cfg.channel    = 0:2:156;
cfg.ylim       = [-3 3] * 1e-12;
cfg.viewmode   = 'butterfly';
artf           = ft_databrowser(cfg,prep_data);

artf.artfctdef.reject = 'nan';
dummy = ft_rejectartifact(artf,prep_data);

bad_epochs_man_bf = zeros(1, length(dummy.trial));
for ievent = 1:length(dummy.trial)
    tempIdx = sum(isnan(dummy.trial{ievent}(:)));
    if tempIdx ~= 0;
        bad_epochs_man_bf(ievent) = 1;
        fprintf('Trial %d marked with artifact \n', ievent)
    elseif tempIdx == 0
        bad_epochs_man_bf(ievent) = 0;
    end
end
cpsFigure(.5,1.5);
imagesc(bad_epochs_man_bf'); title('bad_epochs_man_bf','FontSize',18); colormap(gray); hold on;
tempIdx = bad_epochs_auto' | bad_epochs_summary | bad_epochs_man_bf;
disp(find(tempIdx))
%% ft_databrowser: Butterfly: Eye
cfg          = [];
cfg.continuous = 'no';
cfg.channel    = [151,156,92,136,125,127,154,123,89,142,128,117,116,99,85,83,150,152,143,8,10,11,148,147,48,39,37]; %This is not zero Indexing!!
cfg.ylim       = [-3 3] * 1e-12;
cfg.viewmode   = 'butterfly';
artf           = ft_databrowser(cfg,prep_data);

artf.artfctdef.reject = 'nan';
dummy = ft_rejectartifact(artf,prep_data);

bad_epochs_man_eye = zeros(1, length(dummy.trial));
for ievent = 1:length(dummy.trial)
    tempIdx = sum(isnan(dummy.trial{ievent}(:)));
    if tempIdx ~= 0;
        bad_epochs_man_eye(ievent) = 1;
        fprintf('Trial %d marked with artifact \n', ievent)
    elseif tempIdx == 0
        bad_epochs_man_eye(ievent) = 0;
    end
end
%% ft_databrowser
cfg          = [];
cfg.continuous  = 'no';
cfg.channel     = 0:2:156;
cfg.ylim        = [-.3 .3]*1e-12;
cfg.viewmode    = 'vertical';
cfg.blocksize   = 4;
artf            = ft_databrowser(cfg,prep_data);

artf.artfctdef.reject = 'nan';
dummy = ft_rejectartifact(artf,prep_data);

bad_epochs_man_ver = zeros(1, length(dummy.trial));
for ievent = 1:length(dummy.trial)
    tempIdx = sum(isnan(dummy.trial{ievent}(:)));
    if tempIdx ~= 0;
        bad_epochs_man_ver(ievent) = 1;
        fprintf('Trial %d marked with artifact \n', ievent)
    elseif tempIdx == 0
        bad_epochs_man_ver(ievent) = 0;
    end
end
cpsFigure(.5,1.5);
imagesc(bad_epochs_man_ver'); title('bad_epochs_man_bf','FontSize',18); colormap(gray); hold on;
%%
badEpochIdx_stat = bad_epochs_summary | bad_epochs_auto' | bad_epochs_var | bad_epochs_kur | bad_epochs_skew;
badEpochIdx_man  = bad_epochs_man_bf | bad_epochs_man_ver | bad_epochs_man_eye;
badEpochIdx_all  = badEpochIdx_stat | badEpochIdx_man;
cpsFigure(1,1.2);
subplot(1,2,1)
imagesc(badEpochIdx_all'); title('badEpochIdx all','FontSize',18); colormap(gray);
subplot(1,2,2)
imagesc(badEpochIdx_stat'); title('badEpochIdx stat','FontSize',18); colormap(gray);
%save(badEpochIdxName,'badEpochIdx_all','badEpochIdx_stat','badEpochIdx_man','bad_epochs_auto','bad_epochs_man_bf','bad_epochs_man_ver','bad_epochs_summary');
save(badEpochIdxName,'badEpochIdx_stat','badEpochIdx_man','badEpochIdx_all');
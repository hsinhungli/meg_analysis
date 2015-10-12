addpath(genpath('/users2/purpadmin/Hsin/eeglab13_4_4b'));
addpath(genpath('/users2/purpadmin/Hsin/fieldtrip'));
addpath(genpath('/users2/purpadmin/Hsin/denoise'));
addpath(genpath('/users2/purpadmin/Hsin/meg_utils'));
addpath(genpath('/users2/purpadmin/Hsin/myFunc'));

ft_defaults

%%
subjid    = 'RD';
exptDir   = '/Volumes/DRIVE1/DATA/hsin/MEG/BR';
fileBase  = 'R0817_BR_8.14.15';

dataDir   = sprintf('%s/%s/%s', exptDir,subjid,fileBase);
preprocDir= sprintf('%s/preproc', dataDir);
figDir    = sprintf('%s/%s', preprocDir, 'figures');

%% make the preproc dir if it doesn't exist
if ~exist(preprocDir,'dir')
    fprintf('Generating preproc directory\n');
    mkdir(preprocDir)
end

%% segment if needed
runFiles = dir(sprintf('%s/%s*.sqd',preprocDir,fileBase));
if isempty(runFiles)
    %% segment original sqd into runs
    dataFile = sprintf('%s/%s.sqd',dataDir,fileBase);
    
    % check settings in segmentSqd before running
    fprintf('----------Run Segmentation----------\n')
    nRuns = hl_segmentSqd(dataFile);
    runs  = 1:nRuns;
    
    %% move run files into preproc directory
    runFiles = dir(sprintf('%s/*run*.sqd', dataDir));
    for iRun = 1:nRuns
        movefile(sprintf('%s/%s', dataDir, runFiles(iRun).name), preprocDir)
    end
else
    % we have done preprocessing before, so find the number of runs
    fprintf('----------This file has been segmented before. Loading the segmented files----------\n')
    nRuns  = length(runFiles);
    runs   = 1:nRuns;
end
close all;
%% view data
% just from run 1
run1Data = sqdread(sprintf('%s/%s', preprocDir, runFiles(1).name));
sqdread(sprintf('%s/%s', preprocDir, runFiles(1).name),'info')
run1Data   = run1Data(:,1:157)';
srate      = 1000;
windowSize = [1 5 2560 1392];
eegplot(run1Data,'srate',srate,'winlength',20,'dispchans',80,'position',windowSize);

%% run 1st-stage preproc for each run: Continuous data
for iRun = 3
    run = runs(iRun);
    runFile = sprintf('%s/%s_run%02d.sqd',preprocDir,fileBase,run);
    
    fprintf('----------Preprocessing for run %s----------\n',num2str(run))
    preprocFileName = hl_MEGPreproc_con(runFile, figDir, [], run);
end
%% combine run files into preprocessed sqd
analStr     = hl_getTag(preprocFileName);
fprintf('analStr: %s \n',analStr)
outFileName = sprintf('%s_%s.sqd', fileBase, analStr);
outfile     = hl_combineSqd(preprocDir, outFileName, analStr);

%% run 2nd-stage preproc: Epoch data
tstart = -500;
tend   = 3500;
analStr = [analStr 'i'];
ft_datafileName = sprintf('%s/%s_%s_ft.mat',dataDir,fileBase,analStr);
dataMatrixName  = sprintf('%s/%s_%s_dataMatrix.mat',dataDir,fileBase,analStr);
satInfoName     = sprintf('%s/%s_satInfo.mat',preprocDir,fileBase);
[prep_data,dataMatrix,triggerNumber,satMatrix,badEpochIdx_bc] = hl_MEGPreproc_epo(outfile,tstart,tend);
fprintf('----------Saving data matrix %s----------\n',num2str(run))
save(ft_datafileName, 'prep_data','tstart','tend','triggerNumber','Fs','-v7.3');
save(dataMatrixName,'dataMatrix','tstart','tend','triggerNumber','Fs','-v7.3');
save(satInfoName,'satMatrix','badEpochIdx_bc');
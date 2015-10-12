%%
trigMat = hl_recoverTrig;
filename = '/Volumes/DRIVE1/DATA/hsin/MEG/BR/RD/R0817_BR_8.14.15/R0817_BR_8.14.15.sqd';
[data,info] = sqdread(filename,'Channels',191);

%%
trial = 212;
plot(data(trigMat(trial,:)-100:trigMat(trial,:)+5000))
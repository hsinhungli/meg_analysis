rng default
Fs = 1000; %Sampling frequency in Hz
t  = 0:1/Fs:2-1/Fs;
ntrial   = 100;
nChannel = 2;

simData = nan(length(t),nChannel,ntrial);
for tr = 1:ntrial
    simData(:,1,tr) = cos(2*pi*15*t + pi/2) + 1;
    simData(:,2,tr) = cos(2*pi*15*t + rand*2*pi) + 1;
end
tempData = simData(1:1000,:,:);
N = size(tempData,1); %nSample

[fre,pds_tr,fc_tr,resolution,leakageIdx] = getPowerDensity(tempData,Fs);

ipds = mean(pds_tr,3);
figure;
plot(fre,ipds)
xlim([0 100])
title('Periodogram Using FFT')
xlabel('Frequency (Hz)')
ylabel('Power')

epds = abs(mean(fc_tr,3));
ephs = angle(mean(fc_tr,3));
figure;
plot(fre,epds)
xlim([0 100])
title('Periodogram Using FFT')
xlabel('Frequency (Hz)')
ylabel('Power')

figure;
po = polar(ephs(fre==15),1,'o');
%%
% N   = length(x); %nSample
% Nyquist = Fs/2;  %Nyquist frequency
% fx  = fft(x)/N;  
% pds = 2*abs(fx(1:N/2+1));
% fre = linspace(0,1,N/2+1)*Nyquist;
% 
% plot(fre,pds)
% title('Periodogram Using FFT')
% xlabel('Frequency (Hz)')
% ylabel('Power')
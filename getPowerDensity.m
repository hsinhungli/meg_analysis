function [fre, pds, fc, resolution, leakageIdx] = getPowerDensity(data,Fs,tagFrequency)
% Data should a matrix with time x channel x trial
% Fs is the sampling rate of the data
% tagFrequency is the critical frequency that will be checked whether
% suffered from leakage (optional). If leakageIdx is 1, there is leakage
% This script perform FFT along the first dimension of the data matrix

if nargin<3
    tagFrequency = [];
    leakageIdx = [];
end

%% compute fft
N = size(data,1);
Nyquist = Fs/2;

fx  = fft(data)/N; %Scale by number of samples
fre = linspace(0,1,N/2+1) * Nyquist; %Frequency component corresponding to output of fft
pds = 2*abs(fx(1:N/2+1,:,:)); %Multiply by 2 since only half the energy is in the positive half of the spectrum
fc  = 2*fx(1:N/2+1,:,:);

resolution = fre(3) - fre(2);

if ~isempty(tagFrequency)
    leakageIdx = nan(1,numel(tagFrequency));
    for i = 1:numel(tagFrequency)
        leakageIdx(i) = isempty(find(fre==tagFrequency(i)));
    end
    if sum(leakageIdx)
        fprintf('there is leakage in power spectrum\n')
    end
end
end

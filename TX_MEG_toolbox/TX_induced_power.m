function POW_data = TX_induced_power( data_set,time,channel,trial,base )
%POW_data = TX_induced_power( data_set,time,channel,trial )
%time: a vector of time points
%trial: trial number

baseline = 1:15 ;  % for modulation


trl_num = trial;


cfg = [];
cfg.trials     = 1:trl_num;
cfg.keeptrials = 'yes';
cfg.method     = 'wavelet';
cfg.output     = 'pow';
cfg.channel    = channel;
cfg.width      = [linspace(1.5,7,20) linspace(7,15,30)];
cfg.foi        = 1:1:50;
cfg.toi        = time;
POW_data = ft_freqanalysis(cfg, data_set);

if exist('base') == 1
    pow_temp = POW_data.powspctrm;
    pow_temp = squeeze(mean(pow_temp(1:trl_num,:,:,:)));
    base_temp = repmat(mean(squeeze(pow_temp(:,:,baseline)),3),[1 1 length(time)]);
    pow_temp(:,:,:) = 10*log10(squeeze(pow_temp(:,:,:))./base_temp);
    POW_data = TX_mat2ft_data(pow_temp,'chan_freq_time',1,100,1:1:50);
% else
%     pow_temp = POW_data.powspctrm;
%     pow_temp = squeeze(mean(pow_temp(1:trl_num,:,:,:)));
%     POW_data = TX_mat2ft_data(pow_temp,'chan_freq_time',1,100,4:1:50); %
%     wrong
end

end


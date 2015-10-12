function [POW_data ] = TX_evoked_power( AVG,time,base  )
%[PAVG ] = untitled10( AVG,time )
%Detailed explanation goes here

baseline = 9:19 ;  % if onset is 100.


cfg = [];
cfg.channel    = 'MEG';
cfg.method     = 'wavelet';
cfg.width      = [linspace(1.5,7,20) linspace(7,15,30)];
cfg.output     = 'pow';
cfg.foi        = 1:1:50;
cfg.toi        = time;
POW_data = ft_freqanalysis(cfg,AVG );




if exist('base') == 1
    pow_temp = POW_data.powspctrm;
    
    base_temp = repmat(mean(squeeze(pow_temp(:,:,baseline)),3),[1 1 length(time)]);
    pow_temp(:,:,:) = 10*log10(squeeze(pow_temp(:,:,:))./base_temp);
    POW_data = TX_mat2ft_data(pow_temp,'chan_freq_time',1,100,1:1:50);
else
    pow_temp = POW_data.powspctrm;
    pow_temp = squeeze(mean(pow_temp(1:trl_num,:,:,:)));
    POW_data = TX_mat2ft_data(pow_temp,'chan_freq_time',1,100,1:1:50);
end



end


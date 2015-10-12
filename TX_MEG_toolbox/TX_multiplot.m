function [ ] = TX_multiplot( data_set,method,channel,baseline,interactive, xlim,ylim,zlim ,highlight)
%   TX_multiplot( data_set,method,
%   xlim,ylim,zlim,baseline,interactive,data_type )
%   Method: 'single' 'single3' 'multi' 'multi3' 'topo' 'topo3'
%
load layout
cfg = [];
%cfg.marker = 'off';
cfg.markersize = 0.5;
cfg.comment = 'no';

if exist('highlight')
    cfg.highlight = highlight;
end

cfg.xlim = xlim;

cfg.layout = layout;
cfg.channel = channel;
cfg.baseline = baseline;
%cfg.baselinetype = 'absolute';



if interactive == 1
    cfg.interactive = 'yes';
end







switch method
    case 'single'
        cfg.ylim = ylim;
        cfg.channel = channel;
        
        ft_singleplotER(cfg,data_set);
        
    case 'single3'
        cfg.ylim = ylim;
        cfg.zlim = zlim;
        ft_singleplotTFR(cfg, data_set);
        
    case 'multi'
        cfg.ylim = ylim;
        ft_multiplotER(cfg,data_set);
        
    case 'multi3'
        cfg.ylim = ylim;
        cfg.zlim = zlim;
        ft_multiplotTFR(cfg,data_set);
        
    case 'topo'
        %cfg.ylim = ylim;
        cfg.zlim = zlim;
        ft_topoplotER(cfg,data_set)
        
    case 'topo3'
        cfg.ylim = ylim;
        cfg.zlim = zlim;
        %        cfg.gridscale = 300;
        %        cfg.contournum = 4;
        %cfg.colormap = spring(4);
        cfg.markersymbol = '.';
        cfg.markersize = 1;
        %        cfg.markercolor = [0 0.69 0.94]
        ft_topoplotTFR(cfg,data_set)
        
end

end


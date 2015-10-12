name = dir('*.sqd')





bad{1} =[ 152, 40, 64, 112, 115, 20]


bad{2} =[152, 40, 64, 112, 115]



bad{3} =[  152, 40, 64, 112, 115, 20]



bad{4} = [152, 40, 64, 112, 115, 20]


bad{5} = [ 152, 40, 64, 112, 115]




for i = 1:5
sqdDenoise(50000,-100:100,0,name(i).name,bad{i},'yes',180);
end










TX_reverse_trigger('R0372_Pilot_AM_10.06.14-Filtered.sqd',[161:164]) 

cd ..
cd R0729

sqdDenoise(50000,-100:100,10,'R0729_singletone_8.24.13.sqd',[ 40 64],'yes',180);

TX_reverse_trigger('R0729_bifurcation_b1_8.24.13-Filtered.sqd',[161:168]) 



TX_reverse_trigger('run1.sqd',[161:168]) 
TX_reverse_trigger('run2.sqd',[161:168]) 

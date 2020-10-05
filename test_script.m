% test_script
f = flyWalk;

% f.path_name  = '..\..\data\Walking Assay\2016_10_24 GmrHid SR\2016_10_24_GmrHid_1_2ds_5do_SR60_2-frames.mat';
% f.path_name  = '..\..\data\Walking Assay\2016_12_08 CS EA Doses\2016_12_08_CS_2_3ds_7do_EA60_1-frames.mat';
% f.path_name  = '..\..\data\Walking Assay\2016_09_08 Humidified Air\2016_09_08_CS_1_2ds_5do_CompAirSR60_1-frames.mat';
f.path_name  = '..\..\data\Walking Assay\2016_03_29 Gr63a SR\2016_03_29_Gr63a_1_3ds_7do_SR60_2-frames.mat';
% f.path_name = '..\..\data\Walking Assay\2016_02_24 CS SO 400_500ml 05Hz\2016_02_24_CS_1_3ds_1wo_SO60ml400ml500ml05Hz_3-frames.mat';

f.variable_name = 'frames';
f.subtract_median = false;
f.track_movie = true;
f = f.initialise;
f.ft_debug = true;
f.createGUI;
f.show_split = false;
f.label_flies = true;
f.show_orientations = true;
f.show_antenna = true;
 
% f.save;
% f.testReadSpeed;
% MakeIntermittentSmoke
% Makes a control paradigm which has a ribbon then pulses it, makes it
% oscillate, and finally intermittent

% define parameters and constants
inittime = 3;  % sec
initvol = 100; % ml/min
ribvol = 100;    % ml/min
side_vol = 500;   % side jet air volume
TotalTime = 90;    % sec
mfc_vol(1) = 200;   % ML/MIN
mfc_vol(2) = 1000;  % ML/MIN
sr = 1000;  % digitization sampling rate Hz
corr_length = [10,100,500]; % ms, 50Hz, 5Hz, 1Hz
max_length = [5000]; %ms, 0.1 Hz 
saveit = 1;
save_name = 'IntSmoke_170905_500mlpmin_90sec';

parad_num = 1;

for k = 1:length(side_vol)
    for i = 1:length(max_length)
        for j = 1:length(corr_length)
            nop = TotalTime*sr;

            voltages = zeros(5,nop); % allocate space for the output matrix and set to zero

            % initial turn on
            voltages(5,1:end-1) = 1; % turn the odor initially
            voltages(1,1:inittime*sr+1) = initvol/mfc_vol(1)*5;
            
            % turn on the led for camera timing
            voltages(3,1:end-1) = 1; % turn on the led in the beginning and off at the end

            % straight ribbon
            voltages(1,inittime*sr+1:end-1) = ribvol/mfc_vol(1)*5;

        %     % pulsed ribbon
        %     for i = 1:pulsenum
        %         voltages(4,((i*pulseinterval+(i-1)*pulsewidth)+inittime+riblen)*sr+1:...
        %             (i*(pulseinterval+pulsewidth)+inittime+riblen)*sr+1) = 1;
        %     end
        %     voltages(1,(inittime+riblen)*sr+1:(inittime+riblen+...
        %         (pulsewidth+pulseinterval)*pulsenum)*sr+1) = pulsevol/mfc_vol(1)*5;  % write voltage for the MFC

            % set air for side jet
            voltages(2,inittime*sr+1:end-inittime*sr) = side_vol(k)/mfc_vol(2)*5; % voltage for clean air side oscillation
            
            % get valve binary series
            binary_series = make_pseudo_binary_series(corr_length(j),max_length(i),TotalTime-2*inittime);
            voltages(4,inittime*sr+1:end-inittime*sr) = binary_series;  % write voltage for the side valve
            
            % at the final time point set everything to zero
            % set all to zero
            voltages(:,end) = 0;
            
            % end generating paradigms
            ControlParadigm(parad_num).Name = ['JV:',num2str(side_vol(k)),'_UL:',num2str(max_length(i)/1000),...
                '_LL:',num2str(corr_length(j)/1000)];
            ControlParadigm(parad_num).Outputs = voltages;
            
            parad_num = parad_num + 1;
        end
    end
    
end

% turn off everthing
voltages = zeros(5,sr); % allocate space for the output matrix and set to zero
% end generating paradigms
ControlParadigm(parad_num).Name = 'end';
ControlParadigm(parad_num).Outputs = voltages;

if saveit
        save ([save_name,'_Kontroller_Paradigm.mat'], 'ControlParadigm')
end
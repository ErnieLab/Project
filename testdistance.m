% test

Pico_Power = 30; % [dBm]

dis_constrain = 300;

Serving_Pico_location = [0 0];
Target_Pico_location =  [0 dis_constrain];

Serving_power_table = zeros(dis_constrain-1,0);
Target_power_table  = zeros(dis_constrain-1,0);


for step = 1:1: (dis_constrain-1)
	dist_to_Serving           = norm([0 0+step] - Serving_Pico_location);
	Rsrp_Serving              = Pico_Power - PLmodel_3GPP(dist_to_Serving, 'P');
	Serving_power_table(step) = Rsrp_Serving;

	dist_to_Target            = norm([0 0+step] - Target_Pico_location);
	Rsrp_Target               = Pico_Power - PLmodel_3GPP(dist_to_Target, 'P');
	Target_power_table(step)  = Rsrp_Target;

	if     abs(Rsrp_Serving - Rsrp_Target) == 5
		point_050dbm = step;
	elseif abs(Rsrp_Serving - Rsrp_Target) == 4.5
		point_045dbm = step;
	elseif abs(Rsrp_Serving - Rsrp_Target) == 4
		point_040dbm = step;
	elseif abs(Rsrp_Serving - Rsrp_Target) == 3.5
		point_035dbm = step;
	end
end

plot(1:1: (dis_constrain-1), Serving_power_table);
hold on
plot(1:1: (dis_constrain-1), Target_power_table);
% plot(point_050dbm);




% ===================================================== %
% 該function是用來讓**Non-CoMP**的UE，來更新Throughput  %
% ===================================================== %
function [UE_throughput_After_update] = Non_CoMP_Update_Throughput(n_MC, n_PC, BS_RB_table, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
														           idx_UE, Serving_Cell_index, BW_PRB)

% ------- %
% Initial %
% ------- %
if Serving_Cell_index <= n_MC
	RB_we_can_count = find(UE_RB_used(idx_UE, :) == 1);           % 我們可以拿的RB，也就是提供UE  Throughput的RB
else
	RB_we_can_count = find(UE_RB_used(idx_UE, 1:Pico_part) == 1); % 我們可以拿的RB，也就是提供UE  Throughput的RB
end

UE_throughput = 0;

% ------------------------------------------------ %
% 先算UE的Throughput，以及每個RB提供的Throughput   %  
% ------------------------------------------------ %
if Serving_Cell_index <= n_MC
	Serving_Cell_RSRP_watt_perRB = RsrpBS_Watt(Serving_Cell_index)/n_ttoffered;
else
	Serving_Cell_RSRP_watt_perRB = RsrpBS_Watt(Serving_Cell_index)/Pico_part;
end

for RB_index = 1:1:length(RB_we_can_count)   % 這些UE拿的RB，最後要算出每一塊所提供的  RSRQ
	RB_Total_Interference = 0;
	RB_RSRQ               = 0;
	RB_throughput         = 0;
	for BS_index = 1:1:(n_MC + n_PC)
		if BS_index ~= Serving_Cell_index
			if BS_index <= n_MC
				if BS_RB_table(BS_index, RB_we_can_count(RB_index)) == 1
					RsrpMC_watt_perRB     = RsrpBS_Watt(BS_index)/n_ttoffered;
					RB_Total_Interference = RB_Total_Interference + RsrpMC_watt_perRB;
				end
			else
				if BS_RB_table(BS_index, RB_we_can_count(RB_index)) == 1
					RsrpPC_watt_perRB     = RsrpBS_Watt(BS_index)/Pico_part;
					RB_Total_Interference = RB_Total_Interference + RsrpPC_watt_perRB;
				end
			end
		end
	end
	RB_Total_Interference = (sqrt(RB_Total_Interference) + AMP_Noise)^2;
	RB_RSRQ               = Serving_Cell_RSRP_watt_perRB*(1/(RB_Total_Interference + Serving_Cell_RSRP_watt_perRB));
	RB_throughput         = BW_PRB*MCS_3GPP36942(RB_RSRQ);

	UE_throughput         = UE_throughput + RB_throughput;
end

UE_throughput_After_update = UE_throughput;
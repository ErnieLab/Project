% ===================================================== %
% 該function是用來讓**Non-CoMP**的UE，來更新Throughput  %
% ===================================================== %
function [BS_RB_table_output, BS_RB_who_used_output, UE_RB_used_output,UE_throughput_After_update] = Non_CoMP_Update_Throughput_and_Delete_Useless_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
														                                                                                              idx_UE, Serving_Cell_index, BW_PRB)

% ------- %
% Initial %
% ------- %
if Serving_Cell_index <= n_MC
	RB_we_can_count = find(UE_RB_used(idx_UE, :) == 1);           % 我們可以拿的RB，也就是提供UE  Throughput的RB
else
	RB_we_can_count = find(UE_RB_used(idx_UE, 1:Pico_part) == 1); % 我們可以拿的RB，也就是提供UE  Throughput的RB
end

RB_throughput = zeros(1, length(RB_we_can_count));

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
	RB_SINR               = 0;

	for BS_index = 1:1:(n_MC + n_PC)
		if BS_index ~= Serving_Cell_index
			if BS_RB_table(BS_index, RB_we_can_count(RB_index)) == 1
				if BS_index <= n_MC				
					RsrpMC_watt_perRB     = RsrpBS_Watt(BS_index)/n_ttoffered;
					RB_Total_Interference = RB_Total_Interference + RsrpMC_watt_perRB;				
				else				
					RsrpPC_watt_perRB     = RsrpBS_Watt(BS_index)/Pico_part;
					RB_Total_Interference = RB_Total_Interference + RsrpPC_watt_perRB;				
				end
			end
		end
	end	
	RB_Total_Interference   = RB_Total_Interference + AMP_Noise; 
	RB_SINR                 = Serving_Cell_RSRP_watt_perRB/RB_Total_Interference;
	RB_throughput(RB_index) = BW_PRB*MCS_3GPP36942(RB_SINR);

end


% ------------------------ %
% 把Throughput = 0的RB丟掉 %
% ------------------------ %
while isempty(find(RB_throughput == 0)) == 0
	if isempty(RB_throughput) == 1
		break;
	end

	[~, RB_zero_index] = min(RB_throughput);	
	
	BS_RB_table(Serving_Cell_index, RB_we_can_count(RB_zero_index))    = 0;
	BS_RB_who_used(Serving_Cell_index, RB_we_can_count(RB_zero_index)) = 0;
	UE_RB_used(idx_UE, RB_we_can_count(RB_zero_index))                 = 0;	

	RB_we_can_count(RB_zero_index) = [];
	RB_throughput(RB_zero_index)   = [];
end


% ----------------------------------- %
% Update Throughput and Rsource Table %
% ----------------------------------- %
BS_RB_table_output         = BS_RB_table;
BS_RB_who_used_output      = BS_RB_who_used;
UE_RB_used_output          = UE_RB_used;

UE_throughput_After_update = sum(RB_throughput);

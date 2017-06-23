% ================================================= %
% 該function是用來讓**CoMP**的UE，根據SINR來丟掉RB  %
% ================================================= %
function [BS_RB_table_output, BS_RB_who_used_output, UE_RB_used_output, UE_throughput_After_throw] = CoMP_throw_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
																												   idx_UE, Serving_Cell_index, Cooperating_Cell_index, GBR, BW_PRB)
																												   

% ------- %
% Initial %
% ------- % 
RB_we_can_throw = find(UE_RB_used(idx_UE, 1:Pico_part) == 1);   % UE正在使用的RB位置，也就是我們可以丟掉的位置
RB_SINR         = zeros(1, length(RB_we_can_throw));            % 這些可以丟的RB，每一塊的SINR是多少
RB_throughput   = zeros(1, length(RB_we_can_throw));            % 這些可以丟的RB，每一塊的Throughput是多少

UE_throughput   = 0; 

% ------------------------------------------------ %
% 先算UE的Throughput，以及每個RB提供的Throughput   %  
% ------------------------------------------------ %
Serving_Cell_RSRP_watt_perRB     = RsrpBS_Watt(Serving_Cell_index)/Pico_part;
Cooperating_Cell_RSRP_watt_perRB = RsrpBS_Watt(Cooperating_Cell_index)/Pico_part;

for RB_index = 1:1:length(RB_we_can_throw)   % 這些可以丟的RB，最後要算出每一塊所提供的  SINR
	RB_Total_Interference = 0;
	for BS_index = 1:1:(n_MC + n_PC)
		if BS_index ~= Serving_Cell_index && BS_index ~= Cooperating_Cell_index % 除了Serving Cell 跟 Cooperating Cell，其他Cell如果有用
			if BS_RB_table(BS_index, RB_we_can_throw(RB_index)) == 1
				if BS_index <= n_MC
					RsrpMC_watt_perRB     = RsrpBS_Watt(BS_index)/n_ttoffered;         % watt在除以RB數目					
					RB_Total_Interference = RB_Total_Interference + RsrpMC_watt_perRB; % 加起來
				else
					RsrpPC_watt_perRB     = RsrpBS_Watt(BS_index)/Pico_part;           % watt在除以RB數目						 
					RB_Total_Interference = RB_Total_Interference + RsrpPC_watt_perRB; % 加起來
				end 
			end
		end
	end
	RB_Total_Interference   = RB_Total_Interference + AMP_Noise;  % 全部加好後還要加上白雜訊  [watt]
	RB_SINR(RB_index)       = (Serving_Cell_RSRP_watt_perRB + Cooperating_Cell_RSRP_watt_perRB)/RB_Total_Interference; % CoMP: 兩邊Cell的Power加起來
	RB_throughput(RB_index) = BW_PRB*MCS_3GPP36942(RB_SINR(RB_index));
end
UE_throughput = sum(RB_throughput); % 更新UE的Throughput


% ------------------- %
% 再來看有誰可以踢掉  %
% ------------------- %
while UE_throughput > GBR
	[RB_minSINR_value, RB_minSINR_index] = min(RB_SINR);

	RB_minSINR_throughput = BW_PRB*MCS_3GPP36942(RB_minSINR_value);

	if (UE_throughput - RB_minSINR_throughput >= GBR)		
		BS_RB_table(Serving_Cell_index, RB_we_can_throw(RB_minSINR_index))        = 0;
		BS_RB_who_used(Serving_Cell_index, RB_we_can_throw(RB_minSINR_index))     = 0;
		BS_RB_table(Cooperating_Cell_index, RB_we_can_throw(RB_minSINR_index))    = 0;
		BS_RB_who_used(Cooperating_Cell_index, RB_we_can_throw(RB_minSINR_index)) = 0;
		UE_RB_used(idx_UE, RB_we_can_throw(RB_minSINR_index))                     = 0;

		UE_throughput = UE_throughput - RB_minSINR_throughput;

		RB_SINR(RB_minSINR_index)         = [];
		RB_we_can_throw(RB_minSINR_index) = [];
		RB_throughput(RB_minSINR_index)   = [];
	else
		break;
	end
end

BS_RB_table_output        = BS_RB_table;
UE_RB_used_output         = UE_RB_used;
BS_RB_who_used_output     = BS_RB_who_used;
UE_throughput_After_throw = UE_throughput;

% ================================================= %
% 該function是用來讓**CoMP**的UE，來更新Throughput  %
% ================================================= %
function [BS_RB_table_output, BS_RB_who_used_output, UE_RB_used_output, UE_throughput_After_update] = CoMP_Update_Throughput_and_Delete_Useless_RB(n_MC, n_PC, BS_RB_table, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
														                                                                                           idx_UE, Serving_Cell_index, Cooperating_Cell_index, BW_PRB)

% ------- %
% Initial %
% ------- %
RB_we_can_count = find(UE_RB_used(idx_UE, 1:Pico_part) == 1); % 我們可以拿的RB，也就是提供UE  Throughput的RB

RB_throughput = zeros(1, length(RB_we_can_count));

% ------------------------------------------------ %
% 先算UE的Throughput，以及每個RB提供的Throughput   %  
% ------------------------------------------------ %
Serving_Cell_RSRP_watt_perRB     = RsrpBS_Watt(Serving_Cell_index)/Pico_part;
Cooperating_Cell_RSRP_watt_perRB = RsrpBS_Watt(Cooperating_Cell_index)/Pico_part;

for RB_index = 1:1:length(RB_we_can_count)   % 這些可以丟的RB，最後要算出每一塊所提供的  SINR
	RB_Total_Interference = 0;
	RB_SINR               = 0;

	for BS_index = 1:1:(n_MC + n_PC)
		if BS_index ~= Serving_Cell_index && BS_index ~= Cooperating_Cell_index % 除了Serving Cell 跟 Cooperating Cell，其他Cell如果有用
			if BS_RB_table(BS_index, RB_we_can_count(RB_index)) == 1
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
	RB_SINR                 = (Serving_Cell_RSRP_watt_perRB + Cooperating_Cell_RSRP_watt_perRB)/RB_Total_Interference; % CoMP: 兩邊Cell的Power加起來
	RB_throughput(RB_index) = BW_PRB*MCS_3GPP36942(RB_SINR);
end

% -------------------------- %
% 先把Throughput = 0的RB丟掉 %
% -------------------------- %
while isempty(find(RB_throughput == 0)) == 0
	if isempty(RB_throughput) == 1
		break;
	end

	[~, RB_zero_index] = min(RB_throughput);	
	
	BS_RB_table(Serving_Cell_index, RB_we_can_count(RB_zero_index))        = 0;
	BS_RB_who_used(Serving_Cell_index, RB_we_can_count(RB_zero_index))     = 0;
	BS_RB_table(Cooperating_Cell_index, RB_we_can_count(RB_zero_index))    = 0;
	BS_RB_who_used(Cooperating_Cell_index, RB_we_can_count(RB_zero_index)) = 0;	
	UE_RB_used(idx_UE, RB_we_can_count(RB_zero_index))                     = 0;	

	RB_SINR(RB_zero_index)         = [];
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

% ================================================= %
% 該function是用來讓**CoMP**的UE，根據RSRQ來丟掉RB  %
% ================================================= %
function [BS_RB_table_output, BS_RB_who_used_output, UE_RB_used_output, UE_throughput_After_throw] = CoMP_throw_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
																												   idx_UE, Serving_Cell_index, Cooperating_Cell_index, GBR, BW_PRB)
																												   

% ------- %
% Initial %
% ------- % 
RB_we_can_throw = find(UE_RB_used(idx_UE, 1:Pico_part) == 1);   % UE正在使用的RB位置，也就是我們可以丟掉的位置
RB_RSRQ         = zeros(1, length(RB_we_can_throw));            % 這些可以丟的RB，每一塊的RSRQ是多少
RB_throughput   = zeros(1, length(RB_we_can_throw));            % 這些可以丟的RB，每一塊的Throughput是多少

UE_throughput   = 0; 

% ------------------------------------------------ %
% 先算UE的Throughput，以及每個RB提供的Throughput   %  
% ------------------------------------------------ %
Serving_Cell_RSRP_watt_perRB     = RsrpBS_Watt(Serving_Cell_index)/Pico_part;
Cooperating_Cell_RSRP_watt_perRB = RsrpBS_Watt(Cooperating_Cell_index)/Pico_part;

for RB_index = 1:1:length(RB_we_can_throw)   % 這些可以丟的RB，最後要算出每一塊所提供的  RSRQ
	RB_Total_Interference = 0;
	for BS_index = 1:1:(n_MC + n_PC)
		if BS_index ~= Serving_Cell_index && BS_index ~= Cooperating_Cell_index % 除了Serving Cell 跟 Cooperating Cell，其他Cell如果有用
			if BS_index <= n_MC
				if BS_RB_table(BS_index, RB_we_can_throw(RB_index)) == 1               % 別的Macro Cell有用到該RB，就要算進來 
					RsrpMC_watt_perRB     = RsrpBS_Watt(BS_index)/n_ttoffered;         % watt在除以RB數目					
					RB_Total_Interference = RB_Total_Interference + RsrpMC_watt_perRB; % 加起來
				end
			else
				if BS_RB_table(BS_index, RB_we_can_throw(RB_index)) == 1               % 別的Pico Cell有用到該RB，就要算進來 
					RsrpPC_watt_perRB     = RsrpBS_Watt(BS_index)/Pico_part;           % watt在除以RB數目						 
					RB_Total_Interference = RB_Total_Interference + RsrpPC_watt_perRB; % 加起來
				end
			end 
		end
	end
	RB_Total_Interference   = (sqrt(RB_Total_Interference) + AMP_Noise)^2; % 全部加好後還要加上白雜訊  [watt]
	RB_RSRQ(RB_index)       = (Serving_Cell_RSRP_watt_perRB + Cooperating_Cell_RSRP_watt_perRB)*(1/(RB_Total_Interference + Serving_Cell_RSRP_watt_perRB + Cooperating_Cell_RSRP_watt_perRB)); % CoMP: 兩邊Cell的Power加起來
	RB_throughput(RB_index) = BW_PRB*MCS_3GPP36942(RB_RSRQ(RB_index));
end
UE_throughput = sum(RB_throughput); % 更新UE的Throughput

% -------------------------- %
% 先把Throughput = 0的RB丟掉 %
% -------------------------- %
while isempty(find(RB_throughput == 0)) == 0
	if isempty(RB_throughput) == 1
		break;
	end

	[~, RB_zero_index] = min(RB_throughput);
	
	UE_RB_used(idx_UE, RB_we_can_throw(RB_zero_index))                     = 0;	
	BS_RB_table(Serving_Cell_index, RB_we_can_throw(RB_zero_index))        = 0;
	BS_RB_who_used(Serving_Cell_index, RB_we_can_throw(RB_zero_index))     = 0;
	BS_RB_table(Cooperating_Cell_index, RB_we_can_throw(RB_zero_index))    = 0;
	BS_RB_who_used(Cooperating_Cell_index, RB_we_can_throw(RB_zero_index)) = 0;	

	RB_RSRQ(RB_zero_index)         = [];
	RB_throughput(RB_zero_index)   = [];
	RB_we_can_throw(RB_zero_index) = [];
end

% ------------------- %
% 再來看有誰可以踢掉  %
% ------------------- %
while UE_throughput > GBR
	[RB_minRSRQ_value, RB_minRSRQ_index] = min(RB_RSRQ);

	RB_minRSRQ_throughput = BW_PRB*MCS_3GPP36942(RB_minRSRQ_value);

	if (UE_throughput - RB_minRSRQ_throughput >= GBR)
		UE_RB_used(idx_UE, RB_we_can_throw(RB_minRSRQ_index))                     = 0;
		BS_RB_table(Serving_Cell_index, RB_we_can_throw(RB_minRSRQ_index))        = 0;
		BS_RB_who_used(Serving_Cell_index, RB_we_can_throw(RB_minRSRQ_index))     = 0;
		BS_RB_table(Cooperating_Cell_index, RB_we_can_throw(RB_minRSRQ_index))    = 0;
		BS_RB_who_used(Cooperating_Cell_index, RB_we_can_throw(RB_minRSRQ_index)) = 0;

		UE_throughput = UE_throughput - RB_minRSRQ_throughput;

		RB_we_can_throw(RB_minRSRQ_index) = [];
		RB_RSRQ(RB_minRSRQ_index)         = [];
		RB_throughput(RB_minRSRQ_index)   = []; % 雖然這裡沒用到，但是還是寫一下，方便debug
	else
		break;
	end
end

BS_RB_table_output        = BS_RB_table;
UE_RB_used_output         = UE_RB_used;
BS_RB_who_used_output     = BS_RB_who_used;
UE_throughput_After_throw = UE_throughput;

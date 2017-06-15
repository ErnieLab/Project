% ============================================= %
% 該function是用來讓**CoMP**的UE，強制離開CoMP  %
% ============================================= %
function [BS_RB_table_output, BS_RB_who_used_output, UE_RB_used_output, idx_UEcnct_TST_output, idx_UEcnct_CoMP_output, UE_CoMP_orNOT_output, UE_throughput_After_Leave] = CoMP_Compel_to_Non_CoMP(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
																																															    idx_UE, Serving_Cell_index, Cooperating_Cell_index, idx_UEcnct_CoMP, BW_PRB)
																																															    
% ---------------------------------- %
% 放開Cooperating Cell的RB，結束CoMP %
% ---------------------------------- %
RB_we_can_throw = find(UE_RB_used(idx_UE, 1:Pico_part) == 1); % UE正在使用的RB位置，也就是我們可以丟掉的位置

for RB_index = 1:1:length(RB_we_can_throw)
	BS_RB_table(Cooperating_Cell_index, RB_we_can_throw(RB_index))    = 0;
	BS_RB_who_used(Cooperating_Cell_index, RB_we_can_throw(RB_index)) = 0;	
end

% --------------------------- %
% 更新結束CoMP後的Throughput  %
% --------------------------- %
RB_we_can_count = find(UE_RB_used(idx_UE, 1:Pico_part) == 1); % UE正在使用的RB位置，也就是我們可以計算Throughput的位置

UE_throughput = 0;                                            % 離開CoMP後的Throughput是多少

Serving_Cell_RSRP_watt_perRB = RsrpBS_Watt(Serving_Cell_index)/Pico_part;

for RB_index = 1:1:length(RB_we_can_count)   % 這些可以丟的RB，最後要算出每一塊所提供的  SINR
	RB_Total_Interference = 0;
	RB_SINR               = 0;
	RB_throughput         = 0;
	for BS_index = 1:1:(n_MC + n_PC)
		if BS_index ~= Serving_Cell_index
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
	RB_Total_Interference = RB_Total_Interference + AMP_Noise;  % 全部加好後還要加上白雜訊  [watt]
	RB_SINR               = Serving_Cell_RSRP_watt_perRB/RB_Total_Interference;
	RB_throughput         = BW_PRB*MCS_3GPP36942(RB_SINR);

	UE_throughput         = UE_throughput + RB_throughput;
end

UE_CoMP_orNOT_output       = 0;
idx_UEcnct_CoMP(idx_UE, 1) = 0;
idx_UEcnct_CoMP(idx_UE, 2) = 0;

% --------------- %
% 把矩陣全部輸出  %
% --------------- %
BS_RB_table_output        = BS_RB_table;
BS_RB_who_used_output     = BS_RB_who_used;
UE_RB_used_output         = UE_RB_used;
idx_UEcnct_TST_output     = Serving_Cell_index;
idx_UEcnct_CoMP_output    = idx_UEcnct_CoMP;
UE_throughput_After_Leave = UE_throughput;












% ============================================================================== %
% 該function是用來讓**CoMP**的UE，根據SINR來找可以做CoMP的RB ，讓UE持續執行CoMP  %
% ============================================================================== %
function [BS_RB_table_output, BS_RB_who_used_output, UE_RB_used_output, UE_throughput_After_take, Dis_Connect_Reason] = CoMP_take_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
																																	 idx_UE, Serving_Cell_index, Cooperating_Cell_index, UE_throughput, ...
																																	 GBR, BW_PRB)

% ----------------------------------------- %
% 暫存用，如果要不到RB，要恢復成原本的樣子  %
% ----------------------------------------- %
temp_BS_RB_table    = BS_RB_table;
temp_BS_RB_who_used = BS_RB_who_used;
temp_UE_RB_used     = UE_RB_used;
temp_UE_throughput  = UE_throughput;

Dis_Connect_Reason = 0; % 有2個原因使UE被切斷:   (1)Dis_Connect_Reason = 1  --> BS沒有資源給你拿了
                        %                        (2)Dis_Connect_Reason = 2  --> UE看到他可以用的RB之頻譜效率全都=0

% --------------------------- %
% CoMP要多拿RB，來這裡想辦法  %
% --------------------------- %
RB_Serving_Cell_empty     = find(BS_RB_table(Serving_Cell_index, 1:Pico_part) == 0);     % Serving Cell空的RB
RB_Cooperating_Cell_empty = find(BS_RB_table(Cooperating_Cell_index, 1:Pico_part) == 0); % Cooperating Cell空的RB

% 先把UE可能要拿的位置找出來  : Serving Cell跟Cooperating Cell沒有使用到的RB位置
RB_both_empty      = intersect(RB_Serving_Cell_empty, RB_Cooperating_Cell_empty);
RB_both_empty_SINR = zeros(1, length(RB_both_empty));

% 先看看有沒有得做CoMP
if (isempty(RB_both_empty) == 1)
	% Serving Cell跟ooperating Cell沒有都沒使用的RB，Sorry你無法做CoMP
	BS_RB_table    = temp_BS_RB_table;		
	BS_RB_who_used = temp_BS_RB_who_used;
	UE_RB_used     = temp_UE_RB_used;

	Dis_Connect_Reason = 1;
else
	Serving_Cell_RSRP_watt_perRB     = RsrpBS_Watt(Serving_Cell_index)/Pico_part;
	Cooperating_Cell_RSRP_watt_perRB = RsrpBS_Watt(Cooperating_Cell_index)/Pico_part;
	
	% 這些可以拿的RB，最後要算出每一塊如果做CoMP後，可以提供的SINR
	for RB_index = 1:1:length(RB_both_empty)
		RB_Total_Interference = 0;
		for BS_index = 1:1:(n_MC + n_PC)
			if BS_index ~= Serving_Cell_index && BS_index ~= Cooperating_Cell_index
				if BS_RB_table(BS_index, RB_both_empty(RB_index)) == 1
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
		RB_Total_Interference        = RB_Total_Interference + AMP_Noise;
		RB_both_empty_SINR(RB_index) = (Serving_Cell_RSRP_watt_perRB + Cooperating_Cell_RSRP_watt_perRB)/RB_Total_Interference;
	end

	while UE_throughput < GBR
		if isempty(RB_both_empty) == 1
			% 沒得拿了，沒辦法出去吧
			BS_RB_table    = temp_BS_RB_table;				
			BS_RB_who_used = temp_BS_RB_who_used;	
			UE_RB_used     = temp_UE_RB_used;	

			Dis_Connect_Reason = 1;
			break;
		else
			% 抓到第一個執行CoMP的RB目標
			[UE_CoMP_RB_maxSINR_value, UE_CoMP_RB_maxSINR_index] = max(RB_both_empty_SINR);

			% 該目標RB抓來做CoMP後的Throughput
			RB_throughput = BW_PRB*MCS_3GPP36942(UE_CoMP_RB_maxSINR_value);

			if RB_throughput == 0 % 如果拿了Throughput最高的RB, Throughput居然是0，代表UE離兩邊Cell都太遠了 ，直接結束
				BS_RB_table    = temp_BS_RB_table;				
				BS_RB_who_used = temp_BS_RB_who_used;	
				UE_RB_used     = temp_UE_RB_used;

				Dis_Connect_Reason = 2;
				break;
			else	
				BS_RB_table(Serving_Cell_index, RB_both_empty(UE_CoMP_RB_maxSINR_index))        = 1;				
				BS_RB_who_used(Serving_Cell_index, RB_both_empty(UE_CoMP_RB_maxSINR_index))     = idx_UE;
				BS_RB_table(Cooperating_Cell_index, RB_both_empty(UE_CoMP_RB_maxSINR_index))    = 1;
				BS_RB_who_used(Cooperating_Cell_index, RB_both_empty(UE_CoMP_RB_maxSINR_index)) = idx_UE;
				UE_RB_used(idx_UE, RB_both_empty(UE_CoMP_RB_maxSINR_index))                     = 1;

				UE_throughput = UE_throughput + RB_throughput;

				RB_both_empty(UE_CoMP_RB_maxSINR_index)      = [];
				RB_both_empty_SINR(UE_CoMP_RB_maxSINR_index) = [];
			end
		end
	end
end

% -------------------------------- %
% 最後直接看Throughput 有沒有過QoS %
% -------------------------------- %
if UE_throughput >= GBR
	Dis_Connect_Reason = 0;
	UE_throughput_After_take = UE_throughput;
else
	UE_throughput_After_take = temp_UE_throughput;
end

% --------------- %
% 把矩陣全部輸出  %
% --------------- %
BS_RB_table_output       = BS_RB_table;
BS_RB_who_used_output    = BS_RB_who_used; 
UE_RB_used_output        = UE_RB_used;


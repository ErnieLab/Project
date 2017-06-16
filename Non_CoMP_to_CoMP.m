% =============================================================================== %
% 該function是用來讓**Non-CoMP**的UE，根據SINR來找可以做CoMP的RB  ，進入CoMP mode %
% =============================================================================== %
function [BS_RB_table_output, BS_RB_who_used_output, UE_RB_used_output, idx_UEcnct_TST_output, idx_UEcnct_CoMP_output, UE_CoMP_orNOT_output, UE_throughput_After_take] = Non_CoMP_to_CoMP(BS_lct, n_MC, n_PC, P_MC_dBm, P_PC_dBm, BS_RB_table, BS_RB_who_used, UE_lct, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
																																														  idx_UE, Serving_Cell_index, Cooperating_Cell_index, UE_throughput, ...
																																														  GBR, BW_PRB, idx_UEcnct_CoMP, UE_CoMP_orNOT)
% -------------------------------------------------------------------------------------------------------------- %
% 先把該UE的RB存取狀況給存起來，因為這裡CoMP是用RSRP來tigger ，，不能執行CoMP的時候也是要把原本的狀況還給人家    %
% -------------------------------------------------------------------------------------------------------------- %
temp_BS_RB_table        = BS_RB_table;
temp_BS_RB_who_used     = BS_RB_who_used;
temp_UE_RB_used         = UE_RB_used;
temp_Serving_Cell_index = Serving_Cell_index;
temp_UE_throughput      = UE_throughput;

% -------------------------------------------- %
% 把做Dynamic Resource Scheduling 的RB找出來  %
% -------------------------------------------- %
% 其實就是UE現在手上拿的，但Cooperating_Cell_index沒有使用的，就是這些

% 先找UE自己使用了哪幾塊RB
RB_UE_used = find(UE_RB_used(idx_UE,:) == 1);

% 找出Cooperating_Cell_used
RB_Cooperating_Cell_empty = find(BS_RB_table(Cooperating_Cell_index, 1:Pico_part) == 0); % Target Cell空的RB

% 交集就是Dynamic Resource Scheduling 設計出來的幾個RB，首先的目標就是拿這幾個RB來做CoMP
RB_DRS      = intersect(RB_UE_used, RB_Cooperating_Cell_empty);
RB_DRS_SINR = zeros(1, length(RB_DRS));

% ---------------------------- %
% Non-CoMP UE先把拿的RB還回去  %
% ---------------------------- %
for RB_index = 1:1:Pico_part
	if UE_RB_used(idx_UE, RB_index) == 1 && BS_RB_table(Serving_Cell_index, RB_index) == 1 && BS_RB_who_used(Serving_Cell_index, RB_index) == idx_UE			
		BS_RB_table(Serving_Cell_index, RB_index)    = 0;
		BS_RB_who_used(Serving_Cell_index, RB_index) = 0;
		UE_RB_used(idx_UE, RB_index)                 = 0;	
	end
end
UE_throughput_CoMP = 0;

% -------------------------------------------------------- %
% 開始拿Dynamic Resource Scheduling所設計出來的RB來做CoMP  %
% -------------------------------------------------------- %
Serving_Cell_RSRP_watt_perRB     = RsrpBS_Watt(Serving_Cell_index)/Pico_part;
Cooperating_Cell_RSRP_watt_perRB = RsrpBS_Watt(Cooperating_Cell_index)/Pico_part;

if isempty(RB_DRS) == 0 % 有交集進來算

	% 這DRS的RB，每一塊RB做CoMP後，對Throughput的貢獻是多少
	for RB_index = 1:1:length(RB_DRS)   % 這些可以拿的RB，最後要算出每一塊如果做CoMP後，可以提供的Throughput
		RB_Total_Interference = 0;
		for BS_index = 1:1:(n_MC + n_PC)
			if BS_index ~= Serving_Cell_index && BS_index ~= Cooperating_Cell_index % 除了Serving Cell 跟 Cooperating Cell，其他Cell如果有用
				if BS_RB_table(BS_index, RB_DRS(RB_index)) == 1
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
		RB_Total_Interference = RB_Total_Interference + AMP_Noise;   % 全部加好後還要加上白雜訊  [watt]
		RB_DRS_SINR(RB_index) = (Serving_Cell_RSRP_watt_perRB + Cooperating_Cell_RSRP_watt_perRB)/RB_Total_Interference; % CoMP: 兩邊Cell的Power加起來
	end

	while UE_throughput_CoMP < GBR
		if (isempty(RB_DRS) == 1)
			% Dynamic Resource Scheduling被你拿完了
			break;
		else
			[RB_maxSINR_value, RB_maxSINR_index] = max(RB_DRS_SINR);

			RB_throughput = BW_PRB*MCS_3GPP36942(RB_maxSINR_value);

			if 	RB_throughput == 0 % 如果拿了Throughput最高的RB, Throughput居然是0，代表UE離兩邊Cell都太遠了 ，直接結束
				BS_RB_table    = temp_BS_RB_table;				
				BS_RB_who_used = temp_BS_RB_who_used;
				UE_RB_used     = temp_UE_RB_used;
				break;
			else
				BS_RB_table(Serving_Cell_index, RB_DRS(RB_maxSINR_index))        = 1;				
				BS_RB_who_used(Serving_Cell_index, RB_DRS(RB_maxSINR_index))     = idx_UE;
				BS_RB_table(Cooperating_Cell_index, RB_DRS(RB_maxSINR_index))    = 1;
				BS_RB_who_used(Cooperating_Cell_index, RB_DRS(RB_maxSINR_index)) = idx_UE;
				UE_RB_used(idx_UE, RB_DRS(RB_maxSINR_index))                     = 1;

				UE_throughput_CoMP = UE_throughput_CoMP + RB_throughput;

				RB_DRS(RB_maxSINR_index)      = [];
				RB_DRS_SINR(RB_maxSINR_index) = [];
			end
		end
	end
end

% ------------------------------------------------ %
% Dynamic Resource Scheduling拿完了，來這裡想辦法  %
% ------------------------------------------------ %
if (isempty(RB_DRS) == 1) && (UE_throughput_CoMP < GBR)

	% 先把UE可能要拿的位置找出來  : Serving Cell沒有使用到的RB位置
	RB_UE_might_CoMP = find(BS_RB_table(Serving_Cell_index, 1:Pico_part) == 0);

	% 如果Cooperating　Cell有用這些RB來做CoMP，先砍掉，因為無法移動已經在做CoMP的RB
	for RB_index = 1:1:length(RB_UE_might_CoMP)
		if BS_RB_table(Cooperating_Cell_index, RB_UE_might_CoMP(RB_index)) == 1
			if UE_CoMP_orNOT(BS_RB_who_used(Cooperating_Cell_index, RB_UE_might_CoMP(RB_index))) == 1
				RB_UE_might_CoMP(RB_index) = 0;
			end
		end
	end
	RB_UE_might_CoMP(find(RB_UE_might_CoMP == 0)) = [];

	RB_UE_might_CoMP_SINR = zeros(1, length(RB_UE_might_CoMP));

	% 先看看有沒有得做CoMP
	if (isempty(RB_UE_might_CoMP) == 1)
		% Serving Cell沒有使用的RB位置，Cooperating　Cell都拿去做CoMP了，你運氣也太差了吧
		BS_RB_table    = temp_BS_RB_table;		
		BS_RB_who_used = temp_BS_RB_who_used;
		UE_RB_used     = temp_UE_RB_used;
	else
		% 這些可以拿的RB，最後要算出每一塊如果做CoMP後，可以提供的SINR
		for RB_index = 1:1:length(RB_UE_might_CoMP)
			RB_Total_Interference = 0;
			for BS_index = 1:1:(n_MC + n_PC)
				if BS_index ~= Serving_Cell_index && BS_index ~= Cooperating_Cell_index
					if BS_RB_table(BS_index, RB_UE_might_CoMP(RB_index)) == 1
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
			RB_Total_Interference           = RB_Total_Interference + AMP_Noise;
			RB_UE_might_CoMP_SINR(RB_index) = (Serving_Cell_RSRP_watt_perRB + Cooperating_Cell_RSRP_watt_perRB)/RB_Total_Interference;
		end

		while UE_throughput_CoMP < GBR
			if isempty(RB_UE_might_CoMP) == 1
				% 沒得換了，沒辦法出去吧
				BS_RB_table    = temp_BS_RB_table;				
				BS_RB_who_used = temp_BS_RB_who_used;	
				UE_RB_used     = temp_UE_RB_used;			
				break;
			else
				% 抓到第一個執行CoMP的RB目標
				[UE_might_CoMP_RB_maxSINR_value, UE_might_CoMP_RB_maxSINR_index] = max(RB_UE_might_CoMP_SINR);

				% 該目標RB抓來做CoMP後的Throughput
				RB_throughput = BW_PRB*MCS_3GPP36942(UE_might_CoMP_RB_maxSINR_value);

				if RB_throughput == 0 % 如果拿了Throughput最高的RB, Throughput居然是0，代表UE離兩邊Cell都太遠了 ，直接結束
					BS_RB_table    = temp_BS_RB_table;				
					BS_RB_who_used = temp_BS_RB_who_used;	
					UE_RB_used     = temp_UE_RB_used;
					break;
				else	
					% 先看這個RB目標，Cooperating  Cell 有沒有使用，沒使用就直接拿，有使用就要搬
					if BS_RB_table(Cooperating_Cell_index, RB_UE_might_CoMP(UE_might_CoMP_RB_maxSINR_index)) == 0

						BS_RB_table(Serving_Cell_index, RB_UE_might_CoMP(UE_might_CoMP_RB_maxSINR_index))        = 1;				
						BS_RB_who_used(Serving_Cell_index, RB_UE_might_CoMP(UE_might_CoMP_RB_maxSINR_index))     = idx_UE;
						BS_RB_table(Cooperating_Cell_index, RB_UE_might_CoMP(UE_might_CoMP_RB_maxSINR_index))    = 1;
						BS_RB_who_used(Cooperating_Cell_index, RB_UE_might_CoMP(UE_might_CoMP_RB_maxSINR_index)) = idx_UE;
						UE_RB_used(idx_UE, RB_UE_might_CoMP(UE_might_CoMP_RB_maxSINR_index))                     = 1;

						UE_throughput_CoMP = UE_throughput_CoMP + RB_throughput;

						RB_UE_might_CoMP(UE_might_CoMP_RB_maxSINR_index)      = [];
						RB_UE_might_CoMP_SINR(UE_might_CoMP_RB_maxSINR_index) = [];
					else
						% 把Cooperating Cell佔住目標RB的user找出來
						User_index_occupy_CoMP_RB = BS_RB_who_used(Cooperating_Cell_index,  RB_UE_might_CoMP(UE_might_CoMP_RB_maxSINR_index));

						% 這裡是再算Cooperating Cell打給該user的power
						dis_berween_user_cooperating = norm(UE_lct(User_index_occupy_CoMP_RB,:) - BS_lct(Cooperating_Cell_index,:));
						user_rsrp_dBm                = P_PC_dBm -  PLmodel_3GPP(dis_berween_user_cooperating, 'P');
						user_rsrp_dB                 = user_rsrp_dBm - 30;
						user_rsrp_watt               = 10^(user_rsrp_dB/10); 
						user_rsrp_watt_perRB         = user_rsrp_watt/Pico_part;

						% 接下來該user要去佔其他空的RB，看能不能繼續維持QoS
						Cooperating_Cell_empty                   = find(BS_RB_table(Cooperating_Cell_index, 1:1:Pico_part) == 0); % 把Target Cell沒有使用的抓出來，準備換過去的候選RB
						User_occupy_cooperating_empty_throughput = zeros(1, length(Cooperating_Cell_empty));

						% 要被移動RB的user，放掉該RB
						BS_RB_table(Cooperating_Cell_index, RB_UE_might_CoMP(UE_might_CoMP_RB_maxSINR_index))    = 0;
						BS_RB_who_used(Cooperating_Cell_index, RB_UE_might_CoMP(UE_might_CoMP_RB_maxSINR_index)) = 0;
						UE_RB_used(User_index_occupy_CoMP_RB, RB_UE_might_CoMP(UE_might_CoMP_RB_maxSINR_index))  = 0;

						% 換到每個RB後所得到的Throughput
						for Empty_index = 1:1:length(Cooperating_Cell_empty)

							BS_RB_table(Cooperating_Cell_index, Cooperating_Cell_empty(Empty_index))    = 1;
							BS_RB_who_used(Cooperating_Cell_index, Cooperating_Cell_empty(Empty_index)) = User_index_occupy_CoMP_RB;
							UE_RB_used(User_index_occupy_CoMP_RB, Cooperating_Cell_empty(Empty_index))  = 1;

							RB_user_take = find(UE_RB_used(User_index_occupy_CoMP_RB, 1:1:Pico_part) == 1);
							for RB_index = 1:1:length(RB_user_take)
								RB_Total_Interference = 0;
								RB_SINR               = 0;
								RB_throuhgput         = 0;
								for BS_index = 1:1:(n_MC + n_PC)
									if BS_index ~= Cooperating_Cell_index
										if BS_RB_table(BS_index, RB_user_take(RB_index)) == 1
											if BS_index <= n_MC
												dist_MC           = norm(UE_lct(User_index_occupy_CoMP_RB,:) - BS_lct(BS_index,:));
												RsrpMC_dBm        = P_MC_dBm - PLmodel_3GPP(dist_MC, 'M');
												RsrpMC_dB         = RsrpMC_dBm - 30;
												RsrpMC_watt       = 10^(RsrpMC_dB/10);
												RsrpMC_watt_perRB = RsrpMC_watt/n_ttoffered;

												RB_Total_Interference = RB_Total_Interference + RsrpMC_watt_perRB;
											else
												dist_PC           = norm(UE_lct(User_index_occupy_CoMP_RB,:) - BS_lct(BS_index,:));
												RsrpPC_dBm        = P_PC_dBm - PLmodel_3GPP(dist_PC, 'P');
												RsrpPC_dB         = RsrpPC_dBm - 30;
												RsrpPC_watt       = 10^(RsrpPC_dB/10);
												RsrpPC_watt_perRB = RsrpPC_watt/Pico_part;

												RB_Total_Interference = RB_Total_Interference + RsrpPC_watt_perRB;
											end
										end
									end								
								end
								RB_Total_Interference = RB_Total_Interference + AMP_Noise; 
								RB_SINR               = user_rsrp_watt_perRB/RB_Total_Interference;
								RB_throuhgput         = BW_PRB*MCS_3GPP36942(RB_SINR);

								User_occupy_cooperating_empty_throughput(Empty_index) = User_occupy_cooperating_empty_throughput(Empty_index) + RB_throuhgput;
							end

							BS_RB_table(Cooperating_Cell_index, Cooperating_Cell_empty(Empty_index))    = 0;
							BS_RB_who_used(Cooperating_Cell_index, Cooperating_Cell_empty(Empty_index)) = 0;
							UE_RB_used(User_index_occupy_CoMP_RB, Cooperating_Cell_empty(Empty_index))  = 0;
						end

						[user_maxThourghput_value, user_maxThourghput_index] = max(User_occupy_cooperating_empty_throughput);

						if user_maxThourghput_value < GBR
							% 換也沒用，RB還來!!!!
							BS_RB_table(Cooperating_Cell_index, RB_UE_might_CoMP(UE_might_CoMP_RB_maxSINR_index))    = 1;
							BS_RB_who_used(Cooperating_Cell_index, RB_UE_might_CoMP(UE_might_CoMP_RB_maxSINR_index)) = User_index_occupy_CoMP_RB;
							UE_RB_used(User_index_occupy_CoMP_RB, RB_UE_might_CoMP(UE_might_CoMP_RB_maxSINR_index))  = 1;

							% 這個RB試過了，結果是換不了，把該RB剃除UE的選取範圍內
							RB_UE_might_CoMP(UE_might_CoMP_RB_maxSINR_index)      = [];
							RB_UE_might_CoMP_SINR(UE_might_CoMP_RB_maxSINR_index) = [];
						else
							% 換RB是ok的，被換RB的user換過去
							BS_RB_table(Cooperating_Cell_index, Cooperating_Cell_empty(user_maxThourghput_index))    = 1;
							BS_RB_who_used(Cooperating_Cell_index, Cooperating_Cell_empty(user_maxThourghput_index)) = User_index_occupy_CoMP_RB;
							UE_RB_used(User_index_occupy_CoMP_RB, Cooperating_Cell_empty(user_maxThourghput_index))  = 1;

							% UE把RB拿起來做CoMP
							BS_RB_table(Serving_Cell_index, RB_UE_might_CoMP(UE_might_CoMP_RB_maxSINR_index))        = 1;				
							BS_RB_who_used(Serving_Cell_index, RB_UE_might_CoMP(UE_might_CoMP_RB_maxSINR_index))     = idx_UE;
							BS_RB_table(Cooperating_Cell_index, RB_UE_might_CoMP(UE_might_CoMP_RB_maxSINR_index))    = 1;
							BS_RB_who_used(Cooperating_Cell_index, RB_UE_might_CoMP(UE_might_CoMP_RB_maxSINR_index)) = idx_UE;
							UE_RB_used(idx_UE, RB_UE_might_CoMP(UE_might_CoMP_RB_maxSINR_index))                     = 1;

							UE_throughput_CoMP = UE_throughput_CoMP + RB_throughput;

							% 這個RB試過了，是ok的，把該RB剃除選取範圍內
							RB_UE_might_CoMP(UE_might_CoMP_RB_maxSINR_index)      = [];
							RB_UE_might_CoMP_SINR(UE_might_CoMP_RB_maxSINR_index) = [];
						end
					end
				end
			end
		end
	end
end


% 如果執行完拿RB的迴圈，跳出來後Throughput滿足QoS，代表要做CoMP；如果是不滿足QoS跳出來的話，代表不要做CoMP
if UE_throughput_CoMP >= GBR 
	UE_CoMP_orNOT_output = 1;
else
	UE_CoMP_orNOT_output = 0;
end


% ------------------------------------------- %
% 最後直接看UE_CoMP_orNOT_output來做後續處理  %
% ------------------------------------------- %
if UE_CoMP_orNOT_output == 1
	UE_throughput_After_take   = UE_throughput_CoMP;
	idx_UEcnct_TST_output      = 0;

	idx_UEcnct_CoMP(idx_UE, 1) = Serving_Cell_index;
	idx_UEcnct_CoMP(idx_UE, 2) = Cooperating_Cell_index;

else
	UE_throughput_After_take   = temp_UE_throughput;
	idx_UEcnct_TST_output      = temp_Serving_Cell_index;

	idx_UEcnct_CoMP(idx_UE, 1) = 0;
	idx_UEcnct_CoMP(idx_UE, 2) = 0;	
end

% --------------- %
% 把矩陣全部輸出  %
% --------------- %
BS_RB_table_output       = BS_RB_table;
BS_RB_who_used_output    = BS_RB_who_used;
UE_RB_used_output        = UE_RB_used;
idx_UEcnct_CoMP_output   = idx_UEcnct_CoMP;









					



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
temp_UE_RB_used         = UE_RB_used;
temp_BS_RB_who_used     = BS_RB_who_used;
temp_Serving_Cell_index = Serving_Cell_index;
temp_UE_throughput      = UE_throughput;

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

% -------------------------------------- %
% 看沒使用的RB有沒有交集，先抓他們來用   %
% -------------------------------------- %
RB_Serving_Cell_empty     = find(BS_RB_table(Serving_Cell_index, 1:Pico_part) == 0);     % Serving Cell空的RB
RB_Cooperating_Cell_empty = find(BS_RB_table(Cooperating_Cell_index, 1:Pico_part) == 0); % Target  Cell空的RB

RB_empty_intersect        = intersect(RB_Serving_Cell_empty, RB_Cooperating_Cell_empty); % 兩個Cell都沒使用的RB
RB_SINR_intersect         = zeros(1, length(RB_empty_intersect));

Serving_Cell_RSRP_watt_perRB     = RsrpBS_Watt(Serving_Cell_index)/Pico_part;
Cooperating_Cell_RSRP_watt_perRB = RsrpBS_Watt(Cooperating_Cell_index)/Pico_part;

if (isempty(RB_empty_intersect) == 0) % 有交集進來算	
	for RB_index = 1:1:length(RB_empty_intersect)   % 這些可以拿的RB，最後要算出每一塊如果做CoMP後，可以提供的Throughput
		RB_Total_Interference = 0;
		for BS_index = 1:1:(n_MC + n_PC)
			if BS_index ~= Serving_Cell_index && BS_index ~= Cooperating_Cell_index % 除了Serving Cell 跟 Cooperating Cell，其他Cell如果有用
				if BS_index <= n_MC
					if BS_RB_table(BS_index, RB_empty_intersect(RB_index)) == 1            % 有其他Macro Cell有用到該RB，就要算進來 
						RsrpMC_watt_perRB     = RsrpBS_Watt(BS_index)/n_ttoffered;         % watt在除以RB數目						
						RB_Total_Interference = RB_Total_Interference + RsrpMC_watt_perRB; % 加起來
					end
				else
					if BS_RB_table(BS_index, RB_empty_intersect(RB_index)) == 1            % 有其他Pico Cell有用到該RB，就要算進來 
						RsrpPC_watt_perRB     = RsrpBS_Watt(BS_index)/Pico_part;           % watt在除以RB數目						 
						RB_Total_Interference = RB_Total_Interference + RsrpPC_watt_perRB; % 加起來
					end
				end 
			end
		end
		RB_Total_Interference       = (sqrt(RB_Total_Interference) + AMP_Noise)^2;  % 全部加好後還要加上白雜訊  [watt]
		RB_SINR_intersect(RB_index) = (Serving_Cell_RSRP_watt_perRB + Cooperating_Cell_RSRP_watt_perRB)/RB_Total_Interference; % CoMP: 兩邊Cell的Power加起來
	end

	while UE_throughput_CoMP < GBR	
		if (isempty(RB_empty_intersect) == 1)
			% 沒有空的給你拿了，出去迴圈想辦法
			break;
		else
			[RB_maxSINR_value, RB_maxSINR_index] = max(RB_SINR_intersect);

			RB_throughput = BW_PRB*MCS_3GPP36942(RB_maxSINR_value);

			if 	RB_throughput == 0 % 如果拿了Throughput最高的RB, Throughput居然是0，代表UE離兩邊Cell都太遠了  => 不玩了??
				BS_RB_table    = temp_BS_RB_table;
				UE_RB_used     = temp_UE_RB_used;
				BS_RB_who_used = temp_BS_RB_who_used;
				break;
			else	
				BS_RB_table(Serving_Cell_index, RB_empty_intersect(RB_maxSINR_index))        = 1;				
				BS_RB_who_used(Serving_Cell_index, RB_empty_intersect(RB_maxSINR_index))     = idx_UE;
				BS_RB_table(Cooperating_Cell_index, RB_empty_intersect(RB_maxSINR_index))    = 1;
				BS_RB_who_used(Cooperating_Cell_index, RB_empty_intersect(RB_maxSINR_index)) = idx_UE;

				UE_RB_used(idx_UE, RB_empty_intersect(RB_maxSINR_index)) = 1;

				UE_throughput_CoMP = UE_throughput_CoMP + RB_throughput;

				RB_SINR_intersect(RB_maxSINR_index)  = [];
				RB_empty_intersect(RB_maxSINR_index) = [];
		    end
		end
	end
end

% ------------------------------------------------------------------- %
% 已經沒有現成的可以用了，只能叫  Cooperating Cell想辦法整理出空的來  %
% ------------------------------------------------------------------- %
if (isempty(RB_empty_intersect) == 1) && (UE_throughput_CoMP < GBR)

	% 先把UE可能要拿的位置找出來
	RB_Serving_Cell_empty       = find(BS_RB_table(Serving_Cell_index, 1:Pico_part) == 0);       % Serving Cell沒有使用的RB
	RB_Cooperating_someone_used = find(BS_RB_table(Cooperating_Cell_index, 1:Pico_part) == 1);   % Cooperating Cell有使用的RB

	% 把有人正在做CoMP的RB拿掉
	for RB_index = 1:1:length(RB_Cooperating_someone_used)
		if UE_CoMP_orNOT(BS_RB_who_used(Cooperating_Cell_index, RB_Cooperating_someone_used(RB_index))) == 1
			RB_Cooperating_someone_used(RB_index) = 0;
		end
	end
	RB_Cooperating_someone_used(find(RB_Cooperating_someone_used == 0)) = [];
	
	RB_Cooperating_need_to_move = intersect(RB_Serving_Cell_empty, RB_Cooperating_someone_used);  % Serving Cell沒有使用，但Cooperating Cell有用的 RB

	% 這些RB位置如果拿來做CoMP，所提供的SINR是多少
	RB_SINR_need_to_move = zeros(1, length(RB_Cooperating_need_to_move));

	if (isempty(RB_Cooperating_need_to_move) == 1)
		% 全部都被占光光，只能放棄你了
		BS_RB_table    = temp_BS_RB_table;		
		BS_RB_who_used = temp_BS_RB_who_used;
		UE_RB_used     = temp_UE_RB_used;
	else
		% 這些可以拿的RB，最後要算出每一塊如果做CoMP後，可以提供的SINR
		for RB_index = 1:1:length(RB_Cooperating_need_to_move)   
			RB_Total_Interference = 0;
			for BS_index = 1:1:(n_MC + n_PC)
				if BS_index ~= Serving_Cell_index && BS_index ~= Cooperating_Cell_index
					if BS_index <= n_MC
						if BS_RB_table(BS_index, RB_Cooperating_need_to_move(RB_index)) == 1    % 有其他Macro Cell有用到該RB，就要算進來 
							RsrpMC_watt_perRB     = RsrpBS_Watt(BS_index)/n_ttoffered;         % watt在除以RB數目						
							RB_Total_Interference = RB_Total_Interference + RsrpMC_watt_perRB; % 加起來
						end
					else
						if BS_RB_table(BS_index, RB_Cooperating_need_to_move(RB_index)) == 1    % 有其他Pico Cell有用到該RB，就要算進來 
							RsrpPC_watt_perRB     = RsrpBS_Watt(BS_index)/Pico_part;           % watt在除以RB數目						 
							RB_Total_Interference = RB_Total_Interference + RsrpPC_watt_perRB; % 加起來
						end
					end
				end 
			end
			RB_Total_Interference          = (sqrt(RB_Total_Interference) + AMP_Noise)^2;  % 全部加好後還要加上白雜訊  [watt]
			RB_SINR_need_to_move(RB_index) = (Serving_Cell_RSRP_watt_perRB + Cooperating_Cell_RSRP_watt_perRB)/RB_Total_Interference; % CoMP: 兩邊Cell的Power加起來
		end

		while UE_throughput_CoMP < GBR
			if (isempty(RB_Cooperating_need_to_move) == 1)
				% 全部都換不到，只好回去Non-CoMP  mode
				BS_RB_table    = temp_BS_RB_table;				
				BS_RB_who_used = temp_BS_RB_who_used;	
				UE_RB_used     = temp_UE_RB_used;			
				break;
			else
				[RB_maxSINR_value_CoMP, RB_maxSINR_index_CoMP] = max(RB_SINR_need_to_move);  % UE找到哪一個RB拿來做CoMP會最好，但其實這個RB在Cooperating   Cell是有人使用的，所以要叫佔住的人移到  Cooperating Cell其他空的RB上

				RB_throughput = BW_PRB*MCS_3GPP36942(RB_maxSINR_value_CoMP);	
				
				if RB_throughput == 0 % 拿最好的來做CoMP，Throughpu還是= 0 ---> 離兩個Cell太遠了
					BS_RB_table    = temp_BS_RB_table;					
					BS_RB_who_used = temp_BS_RB_who_used;	
					UE_RB_used     = temp_UE_RB_used;			
					break;
				else
					UE_index_need_to_move = BS_RB_who_used(Cooperating_Cell_index, RB_Cooperating_need_to_move(RB_maxSINR_index_CoMP)); % 抓到在Cooperating Cell使用這個RB的UE了

					% 該UE把該RB換到其他空的地方，比較看看哪個Throughput  可以滿足QoS
					RB_Cooperating_empty       = find(BS_RB_table(Cooperating_Cell_index, 1:Pico_part)  == 0); % UE可以換RB的地方
					RB_after_change_throughput = zeros(1, length(RB_Cooperating_empty));                       % 換過去之後所得到的Throughput，對應到上面的矩陣

					temp_change_BS_RB_table    = BS_RB_table;    % 暫存用
					temp_change_UE_RB_used     = UE_RB_used;     % 暫存用
					temp_change_BS_RB_who_used = BS_RB_who_used; % 暫存用

					for change_index = 1:1:length(RB_Cooperating_empty)
						% 把計畫放掉的RB給放掉						
						BS_RB_table(Cooperating_Cell_index, RB_Cooperating_need_to_move(RB_maxSINR_index_CoMP))    = 0;
						BS_RB_who_used(Cooperating_Cell_index, RB_Cooperating_need_to_move(RB_maxSINR_index_CoMP)) = 0;	
						UE_RB_used(UE_index_need_to_move, RB_Cooperating_need_to_move(RB_maxSINR_index_CoMP))      = 0;			

						% 把換過去要拿的RB拿起來						
						BS_RB_table(Cooperating_Cell_index, RB_Cooperating_empty(change_index))    = 1;
						BS_RB_who_used(Cooperating_Cell_index, RB_Cooperating_empty(change_index)) = UE_index_need_to_move;		
						UE_RB_used(UE_index_need_to_move, RB_Cooperating_empty(change_index))      = 1;		

						% 把換過去後的UE  Throughput算出來

						% 先把要被畫的那位UE，從Cooperating  Cell 收到的Power算出來
						dist_need_to_move = norm(UE_lct(UE_index_need_to_move,:) - BS_lct(Cooperating_Cell_index,:));
						Rsrp_dBm          = P_PC_dBm -  PLmodel_3GPP(dist_need_to_move, 'P');
						Rsrp_dB           = Rsrp_dBm - 30;
						Rsrp_watt         = 10^(Rsrp_dB/10); 
						Rsrp_watt_perRB   = Rsrp_watt/Pico_part;

						RB_we_take = find(UE_RB_used(UE_index_need_to_move, 1:1:Pico_part) == 1);
						for RB_index = 1:1:length(RB_we_take)   % 這些可以丟的RB，最後要算出每一塊所提供的  Throughput
							RB_Total_Interference = 0;
							RB_SINR       = 0;			
							for BS_index = 1:1:(n_MC + n_PC)
								if BS_index ~= Cooperating_Cell_index
									if BS_index <= n_MC
										if BS_RB_table(BS_index, RB_we_take(RB_index)) == 1                                 % 別的Macro Cell有用到該RB，就要算進來 
											dist_MC           = norm(UE_lct(UE_index_need_to_move,:) - BS_lct(BS_index,:)); % 該UE距離Macro Cell多遠 [meter]
											RsrpMC_dBm        = P_MC_dBm - PLmodel_3GPP(dist_MC, 'M');	                    % 該UE從Macro Cell收到的RSRP [dBm]
											RsrpMC_dB         = RsrpMC_dBm - 30;                                            % dBm 換 dB
											RsrpMC_watt       = 10^(RsrpMC_dB/10);                                          % dB 換 watt
											RsrpMC_watt_perRB = RsrpMC_watt/n_ttoffered;                                    % watt在除以RB數目
												
											RB_Total_Interference = RB_Total_Interference + RsrpMC_watt_perRB; % 加起來
										end
									else
										if BS_RB_table(BS_index, RB_we_take(RB_index)) == 1                                 % 別的Pico Cell有用到該RB，就要算進來 
											dist_PC           = norm(UE_lct(UE_index_need_to_move,:) - BS_lct(BS_index,:)); % 該UE距離Pico Cell多遠 [meter]
											RsrpPC_dBm        = P_PC_dBm - PLmodel_3GPP(dist_PC, 'P');	                    % 該UE從Pico Cell收到的RSRP [dBm]
											RsrpPC_dB         = RsrpPC_dBm - 30;                                            % dBm 換 dB
											RsrpPC_watt       = 10^(RsrpPC_dB/10);                                          % dB 換 watt
											RsrpPC_watt_perRB = RsrpPC_watt/Pico_part;                                      % watt在除以RB數目
												 
											RB_Total_Interference = RB_Total_Interference + RsrpPC_watt_perRB; % 加起來
										end
									end 
								end
							end
							RB_Total_Interference                    = (sqrt(RB_Total_Interference) + AMP_Noise)^2; % 全部加好後還要加上白雜訊  [watt]
							RB_SINR                                  = Rsrp_watt_perRB/RB_Total_Interference;
							RB_after_change_throughput(change_index) = RB_after_change_throughput(change_index) + BW_PRB*MCS_3GPP36942(RB_SINR);
						end
						BS_RB_table    = temp_change_BS_RB_table;
						UE_RB_used     = temp_change_UE_RB_used;
						BS_RB_who_used = temp_change_BS_RB_who_used;
					end

					[RB_maxThroughput_value_after_other_move, RB_maxThroughput_index_after_other_move] = max(RB_after_change_throughput);

					if RB_maxThroughput_value_after_other_move < GBR
						% 這個人換沒有用，UE要去找下一個人
						RB_SINR_need_to_move(RB_maxSINR_index_CoMP)        = [];
						RB_Cooperating_need_to_move(RB_maxSINR_index_CoMP) = [];
					else
						% OK了 --> 互相找到目標RB

						% 先把要移動的RB先移過去
						UE_RB_used(UE_index_need_to_move, RB_Cooperating_need_to_move(RB_maxSINR_index_CoMP))      = 0;
						BS_RB_table(Cooperating_Cell_index, RB_Cooperating_need_to_move(RB_maxSINR_index_CoMP))    = 0;
						BS_RB_who_used(Cooperating_Cell_index, RB_Cooperating_need_to_move(RB_maxSINR_index_CoMP)) = 0;

						UE_RB_used(UE_index_need_to_move, RB_Cooperating_empty(RB_maxThroughput_index_after_other_move))      = 1;
						BS_RB_table(Cooperating_Cell_index, RB_Cooperating_empty(RB_maxThroughput_index_after_other_move))    = 1;
						BS_RB_who_used(Cooperating_Cell_index, RB_Cooperating_empty(RB_maxThroughput_index_after_other_move)) = UE_index_need_to_move;

						% 把要做CoMP的RB拿起來
						UE_RB_used(idx_UE, RB_Cooperating_need_to_move(RB_maxSINR_index_CoMP))                     = 1;
						BS_RB_table(Serving_Cell_index, RB_Cooperating_need_to_move(RB_maxSINR_index_CoMP))        = 1;				
						BS_RB_who_used(Serving_Cell_index, RB_Cooperating_need_to_move(RB_maxSINR_index_CoMP))     = idx_UE;
						BS_RB_table(Cooperating_Cell_index, RB_Cooperating_need_to_move(RB_maxSINR_index_CoMP))    = 1;
						BS_RB_who_used(Cooperating_Cell_index, RB_Cooperating_need_to_move(RB_maxSINR_index_CoMP)) = idx_UE;

						UE_throughput_CoMP = UE_throughput_CoMP + RB_throughput;

						RB_SINR_need_to_move(RB_maxSINR_index_CoMP)        = [];
						RB_Cooperating_need_to_move(RB_maxSINR_index_CoMP) = [];
					end
				end
			end
		end
	end
end

if UE_throughput_CoMP >= GBR % 如果執行完拿RB的迴圈，跳出來後Throughput滿足QoS，代表要做CoMP；如果是不滿足QoS跳出來的話，代表不要做CoMP
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

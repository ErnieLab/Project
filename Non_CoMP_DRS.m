% =================================================================== %
% 該function是用來讓**Non-CoMP**的UE，執行Dynamic  Resource Scheduling %
% =================================================================== %
function [BS_RB_table_output, BS_RB_who_used_output, UE_RB_used_output, UE_throughput_After_Scheduling] = Non_CoMP_DRS(BS_lct, n_MC, n_PC, P_MC_dBm, P_PC_dBm, BS_RB_table, BS_RB_who_used, UE_lct, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
																													   idx_UE, Serving_Cell_index, Target_Cell_index, UE_throughput, ...
																													   GBR, BW_PRB, UE_CoMP_orNOT)

% ------- %
% Initial %
% ------- %
if Serving_Cell_index <= n_MC
	RB_UE_used = find(UE_RB_used(idx_UE,:) == 1);                 % UE自己用的每一塊RB
else
	RB_UE_used = find(UE_RB_used(idx_UE, 1:1:Pico_part) == 1);    % UE自己用的每一塊RB
end

Target_Cell_used = find(BS_RB_table(Target_Cell_index, 1:1:Pico_part) == 1); % Target Cell已經再使用的RB，下面會把正在給人家做CoMP的RB給砍掉
for RB_index = 1:1:length(Target_Cell_used)
	if UE_CoMP_orNOT(BS_RB_who_used(Target_Cell_index, Target_Cell_used(RB_index))) == 1
		Target_Cell_used(RB_index) = 0;
	end
end
Target_Cell_used(find(Target_Cell_used == 0)) = [];

Target_might_move_these_RB = intersect(RB_UE_used, Target_Cell_used);       % UE在用的RB，Target也正在給別人用 的RB
might_move_these_RB_SINR   = zeros(1, length(Target_might_move_these_RB));

% ----------------------------- %
% 先把每一塊RB對UE的SINR算出來  %
% ----------------------------- %
% 兩邊要有交集，才能做Dynamic  Resource Scheduling
if isempty(Target_might_move_these_RB) ~= 1

	if Serving_Cell_index <= n_MC
		Serving_Cell_RSRP_watt_perRB = RsrpBS_Watt(Serving_Cell_index)/n_ttoffered;
	else
		Serving_Cell_RSRP_watt_perRB = RsrpBS_Watt(Serving_Cell_index)/Pico_part;
	end

	for RB_index = 1:1:length(Target_might_move_these_RB)
		RB_Total_Interference = 0;
		for BS_index = 1:1:(n_MC + n_PC)
			if BS_index ~= Serving_Cell_index  % 注意這邊
				if BS_RB_table(BS_index, Target_might_move_these_RB(RB_index)) == 1
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
		RB_Total_Interference              = RB_Total_Interference + AMP_Noise;  % 全部加好後還要加上白雜訊  [watt]
		might_move_these_RB_SINR(RB_index) = Serving_Cell_RSRP_watt_perRB/RB_Total_Interference;
	end

	% ------------------------------------ %
	% 開始換搂~~換完要記得更新Throughput   %
	% ------------------------------------ %
	while UE_throughput < GBR
		if isempty(Target_might_move_these_RB) == 1  % 有交集進來算，沒交集代表UE佔的位置，Target   Cell都沒有佔到，或者沒辦法換，也就是今天UE的Throughput不夠，是大環境的問題
			break;
		else
			[~, might_move_RB_minSINR_index] = max(might_move_these_RB_SINR);  % 這個是Target Cell準備要移走的RB

			User_index_occupy_target_might_move_RB = BS_RB_who_used(Target_Cell_index, Target_might_move_these_RB(might_move_RB_minSINR_index)); % 佔住準備要移走的RB的UE

			% 這裡是再算Target Cell打給該user的power
			dis_berween_user_target = norm(UE_lct(User_index_occupy_target_might_move_RB,:) - BS_lct(Target_Cell_index,:));
			user_rsrp_dBm           = P_PC_dBm -  PLmodel_3GPP(dis_berween_user_target, 'P');
			user_rsrp_dB            = user_rsrp_dBm - 30;
			user_rsrp_watt          = 10^(user_rsrp_dB/10); 
			user_rsrp_watt_perRB    = user_rsrp_watt/Pico_part;

			% 要被移動RB的user，放掉該RB
			BS_RB_table(Target_Cell_index, Target_might_move_these_RB(might_move_RB_minSINR_index))                     = 0;
			BS_RB_who_used(Target_Cell_index, Target_might_move_these_RB(might_move_RB_minSINR_index))                  = 0;
			UE_RB_used(User_index_occupy_target_might_move_RB, Target_might_move_these_RB(might_move_RB_minSINR_index)) = 0;

			% 接下來該user要去佔其他空的RB，看能不能繼續維持QoS
			Target_Cell_empty                   = find(BS_RB_table(Target_Cell_index, 1:1:Pico_part) == 0); % 把Target Cell沒有使用的抓出來，準備換過去的候選RB
			User_occupy_target_empty_throughput = zeros(1, length(Target_Cell_empty));

			% 換到每個RB後所得到的Throughput
			for Empty_index = 1:1:length(Target_Cell_empty)

				BS_RB_table(Target_Cell_index, Target_Cell_empty(Empty_index))                     = 1;
				BS_RB_who_used(Target_Cell_index, Target_Cell_empty(Empty_index))                  = User_index_occupy_target_might_move_RB;
				UE_RB_used(User_index_occupy_target_might_move_RB, Target_Cell_empty(Empty_index)) = 1;

				RB_user_take = find(UE_RB_used(User_index_occupy_target_might_move_RB, 1:1:Pico_part) == 1);
				for RB_index = 1:1:length(RB_user_take)
					RB_Total_Interference = 0;
					RB_SINR               = 0;
					RB_throuhgput         = 0;
					for BS_index = 1:1:(n_MC + n_PC)	
						if BS_index ~= Target_Cell_index
							if BS_RB_table(BS_index, RB_user_take(RB_index)) == 1
								if BS_index <= n_MC								
									dist_MC           = norm(UE_lct(User_index_occupy_target_might_move_RB,:) - BS_lct(BS_index,:));
									RsrpMC_dBm        = P_MC_dBm - PLmodel_3GPP(dist_MC, 'M');
									RsrpMC_dB         = RsrpMC_dBm - 30;
									RsrpMC_watt       = 10^(RsrpMC_dB/10);
									RsrpMC_watt_perRB = RsrpMC_watt/n_ttoffered;

									RB_Total_Interference = RB_Total_Interference + RsrpMC_watt_perRB;
								else						
									dist_PC           = norm(UE_lct(User_index_occupy_target_might_move_RB,:) - BS_lct(BS_index,:));
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

					User_occupy_target_empty_throughput(Empty_index) = User_occupy_target_empty_throughput(Empty_index) + RB_throuhgput;
				end

				BS_RB_table(Target_Cell_index, Target_Cell_empty(Empty_index))                     = 0;
				BS_RB_who_used(Target_Cell_index, Target_Cell_empty(Empty_index))                  = 0;
				UE_RB_used(User_index_occupy_target_might_move_RB, Target_Cell_empty(Empty_index)) = 0;
			end

			[user_maxThourghput_value, user_maxThourghput_index] = max(User_occupy_target_empty_throughput);

			if user_maxThourghput_value < GBR
				% 換也沒用，RB還來!!!!
				BS_RB_table(Target_Cell_index, Target_might_move_these_RB(might_move_RB_minSINR_index))                     = 1;
				BS_RB_who_used(Target_Cell_index, Target_might_move_these_RB(might_move_RB_minSINR_index))                  = User_index_occupy_target_might_move_RB;
				UE_RB_used(User_index_occupy_target_might_move_RB, Target_might_move_these_RB(might_move_RB_minSINR_index)) = 1;

				% 這個RB試過了，結果是換不了，把該RB剃除UE的選取範圍內
				might_move_these_RB_SINR(might_move_RB_minSINR_index)   = [];
				Target_might_move_these_RB(might_move_RB_minSINR_index) = [];
			else
				% 換RB是ok的，被換RB的user換過去
				BS_RB_table(Target_Cell_index, Target_Cell_empty(user_maxThourghput_index))                     = 1;
				BS_RB_who_used(Target_Cell_index, Target_Cell_empty(user_maxThourghput_index))                  = User_index_occupy_target_might_move_RB;
				UE_RB_used(User_index_occupy_target_might_move_RB, Target_Cell_empty(user_maxThourghput_index)) = 1;

				% 這個RB試過了，是ok的，把該RB剃除選取範圍內
				might_move_these_RB_SINR(might_move_RB_minSINR_index)   = [];
				Target_might_move_these_RB(might_move_RB_minSINR_index) = [];

				% 更新UE的Throughput
				UE_throughput = 0; % 歸零重新算，因為Scheduling是針對干擾，所以要重新算
				for RB_index = 1:1:length(RB_UE_used)  % 這些可以丟的RB，最後要算出每一塊所提供的  Throughput
					RB_Total_Interference = 0;
					RB_SINR               = 0;
					RB_throuhgput         = 0;
					for BS_index = 1:1:(n_MC + n_PC)
						if BS_index ~= Serving_Cell_index  % 注意這邊
							if BS_RB_table(BS_index, RB_UE_used(RB_index)) == 1
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
					RB_throuhgput         = BW_PRB*MCS_3GPP36942(RB_SINR);

					UE_throughput = UE_throughput + RB_throuhgput;
				end
			end
		end
	end
end

BS_RB_table_output             = BS_RB_table;
BS_RB_who_used_output          = BS_RB_who_used;
UE_RB_used_output              = UE_RB_used;

UE_throughput_After_Scheduling = UE_throughput;
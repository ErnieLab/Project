% =================================================== %
% 該function是用來讓**Non-CoMP**的UE，根據SINR來拿RB  %
% =================================================== %
function [BS_RB_table_output, BS_RB_who_used_output, UE_RB_used_output, UE_throughput_After_take, Dis_Connect_Reason] = Non_CoMP_take_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
										                                                                                                 idx_UE, Serving_Cell_index, UE_throughput, GBR, BW_PRB)
										                                                                                                 
% ----------------------------------------- %
% 暫存用，如果要不到RB，要恢復成原本的樣子  %
% ----------------------------------------- %
temp_BS_RB_table    = BS_RB_table;
temp_BS_RB_who_used = BS_RB_who_used;
temp_UE_RB_used     = UE_RB_used;
temp_UE_throughput  = UE_throughput;

% ------- %
% Initial %
% ------- %
if Serving_Cell_index <= n_MC
	RB_we_can_take = find(BS_RB_table(Serving_Cell_index, :) == 0);           % 我們可以拿的RB，也就是Serving_Cell_index沒有使用的RB
else
	RB_we_can_take = find(BS_RB_table(Serving_Cell_index, 1:Pico_part) == 0); % 我們可以拿的RB，也就是Serving_Cell_index沒有使用的RB
end

RB_SINR = zeros(1, length(RB_we_can_take));             % UE準備跟Serving_Cell_index拿RB，所以該矩陣是Serving_Cell_index中，沒有被使用的RB的SINR   

Dis_Connect_Reason = 0; % 有2個原因使UE被切斷:   (1)Dis_Connect_Reason = 1  --> BS沒有資源給你拿了
                        %                        (2)Dis_Connect_Reason = 2  --> UE看到他可以用的RB之頻譜效率全都=0

% ---------------- %
% 看有沒有RB可以拿 %
% ---------------- %
if (isempty(RB_we_can_take) == 1) % 沒有RB可以拿，不好意思你被犧牲搂
	BS_RB_table    = temp_BS_RB_table;
	BS_RB_who_used = temp_BS_RB_who_used;
	UE_RB_used     = temp_UE_RB_used;
	UE_throughput  = temp_UE_throughput;

	Dis_Connect_Reason   = 1;
else
	% ---------------------------------------------------------------- %
	% 計算Serving_Cell_index中，沒有被使用的RB之可以提供的Throughpu  t %   
	% ---------------------------------------------------------------- %
	if Serving_Cell_index <= n_MC
		Serving_Cell_RSRP_watt_perRB = RsrpBS_Watt(Serving_Cell_index)/n_ttoffered;
	else
		Serving_Cell_RSRP_watt_perRB = RsrpBS_Watt(Serving_Cell_index)/Pico_part;
	end

	for RB_index = 1:1:length(RB_we_can_take)   % 這些可以丟的RB，最後要算出每一塊所提供的  Throughput
		RB_Total_Interference = 0;
		for BS_index = 1:1:(n_MC + n_PC)
			if BS_index ~= Serving_Cell_index
				if BS_index <= n_MC
					if BS_RB_table(BS_index, RB_we_can_take(RB_index)) == 1                % 別的Macro Cell有用到該RB，就要算進來 
						RsrpMC_watt_perRB     = RsrpBS_Watt(BS_index)/n_ttoffered;         % watt在除以RB數目					
						RB_Total_Interference = RB_Total_Interference + RsrpMC_watt_perRB; % 加起來
					end
				else
					if BS_RB_table(BS_index, RB_we_can_take(RB_index)) == 1                % 別的Pico Cell有用到該RB，就要算進來 
						RsrpPC_watt_perRB     = RsrpBS_Watt(BS_index)/Pico_part;           % watt在除以RB數目						 
						RB_Total_Interference = RB_Total_Interference + RsrpPC_watt_perRB; % 加起來
					end
				end 
			end
		end
		RB_Total_Interference = (sqrt(RB_Total_Interference) + AMP_Noise)^2;                % 全部加好後還要加上白雜訊  [watt]
		RB_SINR(RB_index)     = Serving_Cell_RSRP_watt_perRB/RB_Total_Interference;		
	end

	% ---------------------------------- %
	% 開始拿Resource Block來讓UE支持GBR  %
	% ---------------------------------- %
	while UE_throughput < GBR	
		if (isempty(RB_we_can_take) == 1) % 如果RB已經被拿光了	
			BS_RB_table    = temp_BS_RB_table;
			BS_RB_who_used = temp_BS_RB_who_used;
			UE_RB_used     = temp_UE_RB_used;
			UE_throughput  = temp_UE_throughput;

			Dis_Connect_Reason = 1;
			break;
		else
			[RB_maxSINR_value, RB_maxSINR_index] = max(RB_SINR);

			RB_throughput = BW_PRB*MCS_3GPP36942(RB_maxSINR_value);			

			if RB_throughput == 0  % 如果拿了SINR最高的RB, Throughput居然是0，代表UE離 Serving_Cell_index太遠了		
				BS_RB_table    = temp_BS_RB_table;				
				BS_RB_who_used = temp_BS_RB_who_used;
				UE_RB_used     = temp_UE_RB_used;
				UE_throughput  = temp_UE_throughput;

				Dis_Connect_Reason = 2;	
				break;
			else
				BS_RB_table(Serving_Cell_index, RB_we_can_take(RB_maxSINR_index))    = 1;      % 把該位置記錄說，有人在用了
				BS_RB_who_used(Serving_Cell_index, RB_we_can_take(RB_maxSINR_index)) = idx_UE; % 誰用了該RB 登記起來
				UE_RB_used(idx_UE, RB_we_can_take(RB_maxSINR_index))                 = 1;      % UE拿了哪些位置的RB，自己也要知道

		    	UE_throughput = UE_throughput + RB_throughput; % UE的Throughput

		        RB_SINR(RB_maxSINR_index)        = [];
		        RB_we_can_take(RB_maxSINR_index) = [];
			end
		end
	end
end

% --------------------------- %
% 決定UE是有人服務，還是放棄  %
% --------------------------- %
if UE_throughput >= GBR
	Dis_Connect_Reason = 0;
end

% --------------- %
% 把矩陣輸出出去  %
% --------------- %
BS_RB_table_output    = BS_RB_table;
UE_RB_used_output     = UE_RB_used;
BS_RB_who_used_output = BS_RB_who_used;  
UE_throughput_After_take = UE_throughput;
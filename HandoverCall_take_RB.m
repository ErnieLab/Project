% ======================================================== %
% 該function是用來讓**Handover Call**的UE，根據RSRQ來拿RB  %
% ======================================================== %
function [BS_RB_table_output, BS_RB_who_used_output, UE_RB_used_output, idx_UEcnct_TST, UE_throughput_After_take, Dis_Handover_Reason] = HandoverCall_take_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
										                                                                                                                     idx_UE, Serving_Cell_index, Target_Cell_index, UE_Throughput, GBR, BW_PRB)

% ----------------------------------------- %
% 暫存用，如果要不到RB，要恢復成原本的樣子  %
% ----------------------------------------- %
temp_BS_RB_table    = BS_RB_table;
temp_BS_RB_who_used = BS_RB_who_used;
temp_UE_RB_used     = UE_RB_used;
temp_UE_Throughput  = UE_Throughput;

Dis_Handover_Reason = 0;                                    % 有2個原因使UE被切斷:   (1)Dis_Handover_Reason = 1  --> BS沒有資源給你拿了
                                                            %                        (2)Dis_Handover_Reason = 2  --> UE看到他可以用的RB之頻譜效率全都=0
UE_throughput_After_Handover = 0;

% ------- %
% Initial %
% ------- %
if Serving_Cell_index <= n_MC
	RB_UE_used = find(UE_RB_used(idx_UE,:) == 1);                              % UE自己用的每一塊RB
else
	RB_UE_used = find(UE_RB_used(idx_UE, 1:1:Pico_part) == 1);                 % UE自己用的每一塊RB
end

if Target_Cell_index <= n_MC
	RB_we_can_take = find(BS_RB_table(Target_Cell_index,:) == 0);              % UE可以跟Target Cell拿的RB位置
else
	RB_we_can_take = find(BS_RB_table(Target_Cell_index, 1:1:Pico_part) == 0); % UE可以跟Target Cell拿的RB位置
end

RB_we_can_take_RSRQ = zeros(1, length(RB_we_can_take)); % 每一塊可以拿的RB，所提供的RSRQ多少   [bit/sec/RB]

% ----------------------------------- %
% UE先把跟Serving Cell拿的RB全部放掉  %
% ----------------------------------- %
if isempty(RB_UE_used) ~= 1
	for RB_index = 1:1:length(RB_UE_used)	
		BS_RB_table(Serving_Cell_index, RB_UE_used(RB_index))    = 0;
		BS_RB_who_used(Serving_Cell_index, RB_UE_used(RB_index)) = 0;
		UE_RB_used(idx_UE, RB_UE_used(RB_index))                 = 0;
	end
end

% ---------------- %
% 看有沒有RB可以拿 %
% ---------------- %
if isempty(RB_we_can_take) == 1
	BS_RB_table                  = temp_BS_RB_table;
	BS_RB_who_used               = temp_BS_RB_who_used;
	UE_RB_used                   = temp_UE_RB_used;
	UE_throughput_After_Handover = 0;
	Dis_Handover_Reason           = 1;
else
	% ------------------------------------ %
	% 再來算說Target Cell的RB的RSRQ是多少  %
	% ------------------------------------ %
	if Target_Cell_index <= n_MC
		trgtRSRP_watt_perRB = RsrpBS_Watt(Target_Cell_index)/n_ttoffered;
	else
		trgtRSRP_watt_perRB = RsrpBS_Watt(Target_Cell_index)/Pico_part;
	end

	for RB_index = 1:1:length(RB_we_can_take)   % 這些可以拿的RB，最後要算出每一塊的RSRQ
		RB_Total_Interference = 0;
		for BS_index = 1:1:(n_MC + n_PC)
			if BS_index ~= Target_Cell_index
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
		RB_Total_Interference         = (sqrt(RB_Total_Interference) + AMP_Noise)^2; % 全部加好後還要加上白雜訊  [watt]
		RB_we_can_take_RSRQ(RB_index) = trgtRSRP_watt_perRB*(1/(RB_Total_Interference  + trgtRSRP_watt_perRB));		
	end

	% ---------------------------------- %
	% 開始拿Resource Block來讓UE支持GBR  %
	% ---------------------------------- %
	while UE_throughput_After_Handover < GBR	
		if (isempty(RB_we_can_take) == 1) % 如果RB已經被拿光了，還是沒辦法滿足，GG把RB還給人家八
			BS_RB_table                  = temp_BS_RB_table;
			BS_RB_who_used               = temp_BS_RB_who_used;
			UE_RB_used                   = temp_UE_RB_used;
			UE_throughput_After_Handover = 0;
			Dis_Handover_Reason          = 1;
			break;
		else
			[RB_maxRSRQ_value, RB_maxRSRQ_index] = max(RB_we_can_take_RSRQ);

			RB_throughput = BW_PRB*MCS_3GPP36942(RB_maxRSRQ_value);

			if RB_throughput == 0  % 如果拿了RSRQ最高的RB, Throughput居然是0，代表UE離 idx_trgt太遠了             
				BS_RB_table                  = temp_BS_RB_table;
				BS_RB_who_used               = temp_BS_RB_who_used;
				UE_RB_used                   = temp_UE_RB_used;
				UE_throughput_After_Handover = 0;
				Dis_Handover_Reason          = 2;
				break;
			else				
		    	BS_RB_table(Target_Cell_index, RB_we_can_take(RB_maxRSRQ_index))    = 1;      % 把該位置記錄說，有人在用了		    	
		    	BS_RB_who_used(Target_Cell_index, RB_we_can_take(RB_maxRSRQ_index)) = idx_UE; % 登記一下這RB是idx_UE用的
		    	UE_RB_used(idx_UE, RB_we_can_take(RB_maxRSRQ_index))                 = 1;     % UE拿了哪些位置的RB，自己也要知道

		    	UE_throughput_After_Handover = UE_throughput_After_Handover + RB_throughput; % UE的Throughput

		        RB_we_can_take_RSRQ(RB_maxRSRQ_index) = [];
		        RB_we_can_take(RB_maxRSRQ_index)      = [];		        
			end
		end
	end
end

% --------------------------- %
% 決定UE是有人服務，還是放棄  %
% --------------------------- %
if UE_throughput_After_Handover >= GBR	
	idx_UEcnct_TST           = Target_Cell_index;
	UE_throughput_After_take = UE_throughput_After_Handover;

	Dis_Handover_Reason      = 0;
else	
	idx_UEcnct_TST           = Serving_Cell_index;
	UE_throughput_After_take = temp_UE_Throughput;
end

BS_RB_table_output    = BS_RB_table;
BS_RB_who_used_output = BS_RB_who_used;
UE_RB_used_output     = UE_RB_used;
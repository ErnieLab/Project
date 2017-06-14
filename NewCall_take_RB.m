% =================================================== %
% 該function是用來讓**New Call**的UE，根據RSRQ來拿RB  %
% =================================================== %
function [BS_RB_table_output, BS_RB_who_used_output, UE_RB_used_output, idx_UEcnct_TST, UE_throughput_After_take, Dis_Connect_Reason] = NewCall_take_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
										                                                                                                               idx_UE, idx_trgt, GBR, BW_PRB)
										                                                                                                              
% ----------------------------------------- %
% 暫存用，如果要不到RB，要恢復成原本的樣子  %
% ----------------------------------------- %
temp_BS_RB_table    = BS_RB_table;
temp_UE_RB_used     = UE_RB_used;
temp_BS_RB_who_used = BS_RB_who_used;

% ------- %
% Initial %
% ------- %
if idx_trgt <= n_MC
	RB_we_can_take = find(BS_RB_table(idx_trgt, :) == 0);   % 我們可以拿的RB，也就是idx_trgt沒有使用的RB
else
	RB_we_can_take = find(BS_RB_table(idx_trgt, 1:Pico_part) == 0);   % 我們可以拿的RB，也就是idx_trgt沒有使用的RB
end

RB_RSRQ            = zeros(1, length(RB_we_can_take));     % UE準備跟idx_trgt拿RB，所以該矩陣是idx_trgt中，沒有被使用的RB的RSRQ               
UE_connect_BS      = 0;                                    % 因為是New Call，所以沒有人服務他
UE_throughput      = 0;                                    % 因為是New Call，所以Throughput是0

Dis_Connect_Reason = 0;                                    % 有2個原因使UE被切斷:   (1)Dis_Connect_Reason = 1  --> BS沒有資源給你拿了
                                                           %                        (2)Dis_Connect_Reason = 2  --> UE看到他可以用的RB之頻譜效率全都=0
% ---------------- %
% 看有沒有RB可以拿 %
% ---------------- %
if (isempty(RB_we_can_take) == 1) % 沒有RB可以拿，不好意思你被犧牲
	UE_connect_BS       = 0;
	UE_throughput       = 0;
	Dis_Connect_Reason  = 1;
else
	% ------------------------------------------------------ %
	% 計算idx_trgt中，沒有被使用的RB之可以提供的Throughpu  t %   
	% ------------------------------------------------------ %
	if idx_trgt <= n_MC
		trgtRSRP_watt_perRB = RsrpBS_Watt(idx_trgt)/n_ttoffered;
	else
		trgtRSRP_watt_perRB = RsrpBS_Watt(idx_trgt)/Pico_part;
	end

	for RB_index = 1:1:length(RB_we_can_take)   % 這些可以拿的RB，最後要算出每一塊的RSRQ
		RB_Total_Interference = 0;
		for BS_index = 1:1:(n_MC + n_PC)
			if BS_index ~= idx_trgt
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
		RB_Total_Interference = (sqrt(RB_Total_Interference) + AMP_Noise)^2; % 全部加好後還要加上白雜訊  [watt]
		RB_RSRQ(RB_index)     = trgtRSRP_watt_perRB*(1/(RB_Total_Interference  + trgtRSRP_watt_perRB));		
	end

	% ---------------------------------- %
	% 開始拿Resource Block來讓UE支持GBR  %
	% ---------------------------------- %
	while UE_throughput < GBR	
		if (isempty(RB_we_can_take) == 1)               % 如果RB已經被拿光了，還是沒辦法滿足，GG把RB還給人家八
			BS_RB_table        = temp_BS_RB_table;
			BS_RB_who_used     = temp_BS_RB_who_used;
			UE_RB_used         = temp_UE_RB_used;
			UE_throughput      = 0;
			Dis_Connect_Reason = 1;
			break;
		else
			[RB_maxRSRQ_value, RB_maxRSRQ_index] = max(RB_RSRQ);

			RB_throughput = BW_PRB*MCS_3GPP36942(RB_maxRSRQ_value);

			if RB_throughput == 0  % 如果拿了RSRQ最高的RB, Throughput居然是0，代表UE離 idx_trgt太遠了             
				BS_RB_table        = temp_BS_RB_table;
				BS_RB_who_used     = temp_BS_RB_who_used;
				UE_RB_used         = temp_UE_RB_used;
				UE_throughput      = 0;
				Dis_Connect_Reason = 2;
				break;
			else
				UE_RB_used(idx_UE, RB_we_can_take(RB_maxRSRQ_index))       = 1;      % UE拿了哪些位置的RB，自己也要知道
		    	BS_RB_table(idx_trgt, RB_we_can_take(RB_maxRSRQ_index))    = 1;      % 把該位置記錄說，有人在用了		    	
		    	BS_RB_who_used(idx_trgt, RB_we_can_take(RB_maxRSRQ_index)) = idx_UE; % 登記一下這RB是idx_UE用的

		    	UE_throughput =  UE_throughput + RB_throughput;          % UE的Throughput

		        RB_RSRQ(RB_maxRSRQ_index)         = [];
		        RB_we_can_take(RB_maxRSRQ_index)  = [];		        
			end
		end
	end
end

% --------------------------- %
% 決定UE是有人服務，還是放棄  %
% --------------------------- %
if UE_throughput >= GBR
	Dis_Connect_Reason = 0;
	UE_connect_BS = idx_trgt;
else
	UE_connect_BS = 0;
end

BS_RB_table_output    = BS_RB_table;
BS_RB_who_used_output = BS_RB_who_used;
UE_RB_used_output     = UE_RB_used;

% 回傳現在是有沒有Cell服務，如果有是誰在服務
idx_UEcnct_TST = UE_connect_BS;

% 算好的Throughtput傳出去          
UE_throughput_After_take = UE_throughput;
% =========================================================== %
% 該function是用來讓**CoMP**的UE，根據RSRQ來換執行CoMP的RB   %
% =========================================================== %
function [BS_RB_table_output, BS_RB_who_used_output, UE_RB_used_output, UE_throughput_After_change] = CoMP_change_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
																												     idx_UE, Serving_Cell_index, Cooperating_Cell_index, UE_throughput, GBR, BW_PRB)
																												     
% ------- %
% Initial %
% ------- %
RB_UE_used      = find(UE_RB_used(idx_UE, 1:Pico_part) == 1); % UE自己用的每一塊RB
RB_UE_used_RSRQ = zeros(1, length(RB_UE_used));               % 自己用的每一塊RB所提供的RSRQ  [bit/sec/RB]

RB_Serving_Cell_empty     = find(BS_RB_table(Serving_Cell_index, 1:Pico_part) == 0);     % Serving Cell空的RB
RB_Cooperating_Cell_empty = find(BS_RB_table(Cooperating_Cell_index, 1:Pico_part) == 0); % Target  Cell空的RB
RB_empty                  = intersect(RB_Serving_Cell_empty, RB_Cooperating_Cell_empty); % 兩個Cell都沒使用的RB ，也就是我們可以拿的空RB
RB_empty_RSRQ             = zeros(1, length(RB_empty));                                  % 每一塊可以拿的RB，所提供的RSRQ多少   [bit/sec/RB]

% --------------------------------------- %
% 先把每一塊RB對UE的Throughput貢獻算出來  %
% --------------------------------------- %
Serving_Cell_RSRP_watt_perRB     = RsrpBS_Watt(Serving_Cell_index)/Pico_part;
Cooperating_Cell_RSRP_watt_perRB = RsrpBS_Watt(Cooperating_Cell_index)/Pico_part;

RB_RSRQ = zeros(1, Pico_part);

for RB_index = 1:1:Pico_part   % 這些可以丟的RB，最後要算出每一塊所提供的  Throughput
	RB_Total_Interference = 0;
	for BS_index = 1:1:(n_MC + n_PC)
		if BS_index ~= Serving_Cell_index && BS_index ~= Cooperating_Cell_index % 除了Serving Cell 跟 Cooperating Cell，其他Cell如果有用
			if BS_index <= n_MC
				if BS_RB_table(BS_index, RB_index) == 1                                % 別的Macro Cell有用到該RB，就要算進來 
					RsrpMC_watt_perRB     = RsrpBS_Watt(BS_index)/n_ttoffered;         % watt在除以RB數目					
					RB_Total_Interference = RB_Total_Interference + RsrpMC_watt_perRB; % 加起來
				end
			else
				if BS_RB_table(BS_index, RB_index) == 1                                % 別的Pico Cell有用到該RB，就要算進來 
					RsrpPC_watt_perRB     = RsrpBS_Watt(BS_index)/Pico_part;           % watt在除以RB數目						 
					RB_Total_Interference = RB_Total_Interference + RsrpPC_watt_perRB; % 加起來
				end
			end 
		end
	end
	RB_Total_Interference = (sqrt(RB_Total_Interference) + AMP_Noise)^2; % 全部加好後還要加上白雜訊  [watt]
	RB_RSRQ(RB_index)     = (Serving_Cell_RSRP_watt_perRB + Cooperating_Cell_RSRP_watt_perRB)*(1/(RB_Total_Interference + Serving_Cell_RSRP_watt_perRB + Cooperating_Cell_RSRP_watt_perRB)); % CoMP: 兩邊Cell的Power加起來
end
RB_UE_used_RSRQ = RB_RSRQ(RB_UE_used); % UE正在使用的RB之RSRQ
RB_empty_RSRQ   = RB_RSRQ(RB_empty);   % Serving_Cell_index沒有使用的RB之RSRQ

% ----------------- %
% 看有沒有RB可以換  %  
% ----------------- %
while UE_throughput < GBR
	if (isempty(RB_empty) == 1)  % 該BS沒有空的RB，不能換
		break;
	else
		% -------------------------------- %
		% 開始跟空的RB交換，來讓UE支持GBR  %
		% -------------------------------- %
		[RB_UE_used_minRSRQ_value, RB_UE_used_minRSRQ_index] = min(RB_UE_used_RSRQ);
		[RB_empty_maxRSRQ_value, RB_empty_maxRSRQ_index]     = max(RB_empty_RSRQ);
		
		if 	RB_UE_used_minRSRQ_value >= RB_empty_maxRSRQ_value  % 如果自己拿的RB中，最小RSRQ的那個，還比空的RB能提供最大的RSRQ還大
			break;
		else
			% 跟空的RB交換位置
			UE_RB_used(idx_UE, RB_UE_used(RB_UE_used_minRSRQ_index))                     = 0;
			BS_RB_table(Serving_Cell_index, RB_UE_used(RB_UE_used_minRSRQ_index))        = 0;
			BS_RB_who_used(Serving_Cell_index, RB_UE_used(RB_UE_used_minRSRQ_index))     = 0;
			BS_RB_table(Cooperating_Cell_index, RB_UE_used(RB_UE_used_minRSRQ_index))    = 0;
			BS_RB_who_used(Cooperating_Cell_index, RB_UE_used(RB_UE_used_minRSRQ_index)) = 0;		

			UE_RB_used(idx_UE, RB_empty(RB_empty_maxRSRQ_index))                     = 1;
			BS_RB_table(Serving_Cell_index, RB_empty(RB_empty_maxRSRQ_index))        = 1;
			BS_RB_who_used(Serving_Cell_index, RB_empty(RB_empty_maxRSRQ_index))     = idx_UE;
			BS_RB_table(Cooperating_Cell_index, RB_empty(RB_empty_maxRSRQ_index))    = 1;
			BS_RB_who_used(Cooperating_Cell_index, RB_empty(RB_empty_maxRSRQ_index)) = idx_UE;

			temp_RB      = RB_UE_used(RB_UE_used_minRSRQ_index);
			temp_RB_RSRQ = RB_UE_used_RSRQ(RB_UE_used_minRSRQ_index);

			RB_UE_used(RB_UE_used_minRSRQ_index)      = []; RB_UE_used      = [RB_UE_used RB_empty(RB_empty_maxRSRQ_index)];
			RB_UE_used_RSRQ(RB_UE_used_minRSRQ_index) = []; RB_UE_used_RSRQ = [RB_UE_used_RSRQ RB_empty_RSRQ(RB_empty_maxRSRQ_index)];
			RB_empty(RB_empty_maxRSRQ_index)          = []; RB_empty        = [RB_empty temp_RB];
			RB_empty_RSRQ(RB_empty_maxRSRQ_index)     = []; RB_empty_RSRQ   = [RB_empty_RSRQ temp_RB_RSRQ];
            
            % 更新UE throughput
            RB_UE_used_minThroughput_value = BW_PRB*MCS_3GPP36942(RB_UE_used_minRSRQ_value);
            RB_empty_maxThroughput_value   = BW_PRB*MCS_3GPP36942(RB_empty_maxRSRQ_value);

			UE_throughput = UE_throughput - RB_UE_used_minThroughput_value + RB_empty_maxThroughput_value;
		end
	end
end

% 輸出改變的矩陣
BS_RB_table_output    = BS_RB_table;
UE_RB_used_output     = UE_RB_used;
BS_RB_who_used_output = BS_RB_who_used;

% 把UE的Throughput輸出
UE_throughput_After_change = UE_throughput;
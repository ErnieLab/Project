%%Rebuild System 2017.2.22
clc, clear, close all
load('ttSimuT');

% ============================================================================== %
%   ____                                                                         %
%  |    \                                                                        %
%  |     \                                                                       %
%  |     |                                                                       %
%  |     /                                                                       %
%  |____/                                                                        % 
%  |        ____            ____        _  _      __     __|__      __           %
%  |       /    \    | /   /    \     |/ \/ \    /  \      |       /  \    | /   %
%  |       |    |\   |/    |    |\    |  |  |    |__/      | /     |__/    |/    %
%  |       \____/ \  |     \____/ \   |  |  |    |___      |/      |___    |     %
% ============================================================================== %

% -----------------------------------------------------
% -------/* Simulation Parameters Setting /* ----------
% -----------------------------------------------------
MTS_1s = 1;		% [sec]														% Minimum Time-of-Stay from 3GPP Standard [sec]
MTS_5s = 5;		% [sec]
TST_HD = 0;


% -----------------------------------------------------
% -----------------/* Time Slot */---------------------
% -----------------------------------------------------
t_d        = 0.1; % ONE MILLISECOND % it's UNIT: sec		% [[[ADJ]]]     % Simulation time duration [sec]
t_start    = t_d;
t_simu     = (t_d/t_d) * ttSimuT; % it's UNIT: sec			% [[[ADJ]]]     % Total Simulation Time [sec]
n_Measured = t_simu/t_d;	                                                % # measurements [# number of times]

											    
% -----------------------------------------------------
% ----------------/* Base Station */-------------------
% -----------------------------------------------------
rectEdge = 4763;															% 系統的邊界 [meter]
load('MC_lct_4sq');															% 大細胞的位置讀出來，矩陣叫:  Macro_location		
load('PC_lct_4sq_n250_random');                                         % 小細胞的位置讀出來 ，矩陣叫: Pico_location
BS_lct = [Macro_location ; Pico_location];								    % 全部細胞的位置

P_MC_dBm    =  46;															% 大細胞 total TX power (全部頻帶加起來的power) [dBm]
P_PC_dBm    =  30;															% 小細胞 total TX power (全部頻帶加起來的power) [dBm]
P_minRsrpRQ = -100; % [dBm]                          		% [[[ADJ]]]     % Minimum Required power to provide services 
																			% sufficiently for UE accessing to BS [dBm]
																			% Requirement for accessing a particular cell
MACROCELL_RADIUS = (10^((P_MC_dBm-P_minRsrpRQ-128.1)/37.6))*1e+3;
PICOCELL_RADIUS  = (10^((P_PC_dBm-P_minRsrpRQ-140.7)/36.7))*1e+3;

n_MC = length(Macro_location);			                                    % 大細胞的數目
n_PC = length(Pico_location);	                                            % 小細胞的數目
n_BS = n_MC + n_PC;															% 全部細胞的數目

% -----------------------------------------------------
% -------------/* Resource Parameter */----------------
% -----------------------------------------------------
sys_BW      = 5   * 1e+6;									% [[[ADJ]]]		% 系統總頻寬 5MHz
BW_PRB      = 180 * 1e+3;													% LTE 每個Resource Block的頻寬為 180kHz
n_ttoffered = sys_BW/(BW_PRB/9*10);											% [[[ADJ]]]     % #max cnct per BS i.e., PRB
                                                                            % 系統 RB 的總數，*9/10那段是把RB的CP算進來除
																			% B E N: Max #PRB under BW = 10 Mhz per slot(0.5ms)
Pico_part   = n_ttoffered;                                                  % Pico Cell可以使用的部分

GBR         = 256 * 1024;													% Guaranteed Bit Rate is 256 kbit/sec
% -----------------------------------------------------
% -----------------/* Channel */-----------------------
% -----------------------------------------------------
Gamma_MC            = 3.76;                                                 % Pathloss Exponent (MC)            
Gamma_PC            = 3.67;                                                 % Pathloss Exponent (PC)  
P_N_dBmHz           = -174; % [dBm/Hz]										% 高斯雜訊的 Power Density [dBm/Hz]
LTE_NoiseFloor_dBm  = P_N_dBmHz + 10*log10(BW_PRB);							% Noise Floor approximate -121.45 [dBm/RB]
LTE_NoiseFloor_watt = 10^((LTE_NoiseFloor_dBm - 30)/10);					% Noise Floor approximate 7.1614 * 1e+16 [watt/RB]



% -----------------------------------------------------
% ------------/* User 位置和數目 */--------------------
% -----------------------------------------------------
load('UE_lct_n400_random');
UE_lct = UE_location;                                                       % 讀UE的位置出來 (注意檔名)
n_UE = length(UE_lct);			                                            % 全部UE的數目

% -----------------------------------------------------
% -------------/* Handover Setting */------------------
% -----------------------------------------------------
HHM    = 3;	  % [dB]										% [[[ADJ]]]     % Handover Hysteresis Margin [dB]
t_TTT  = 0.1; % [sec]										% [[[ADJ]]]     % NYC
t_T310 = 1;   % [sec]

% -----------------------------------------------------
% ----------------/* Q-Learning */---------------------
% -----------------------------------------------------
n_FuzzyDegree =  5;
n_Rule        = 25;
n_Act         =  5;

FQ_BS_DF_TST = 0.8;											% [[[INH]]]     % Discount Factor
FQ_BS_LR_TST = 0.2;											% [[[INH]]]     % Learning Rate
FQ_BS_LI_TST = 5  ;											% [[[INH]]]     % Learning Interval is 5 [sec]

% -----------------------------------------------------
% -----------/* 把系統Model圖跑出來 */-----------------
% -----------------------------------------------------
figure(), hold on;
plot(Macro_location(:,1), Macro_location(:,2), 'sk', 'MarkerFaceColor', 'k','MarkerSize',10);
plot(Pico_location(:,1), Pico_location(:,2), '^k', 'MarkerFaceColor', 'g','MarkerSize', 5);
plot(UE_lct(:,1), UE_lct(:,2), '*', 'Color',[0.8 0.0 0.2],'MarkerSize',5);
plot([+1,-1,-1,+1,+1]*rectEdge/2, [+1,+1,-1,-1,+1]*rectEdge/2, 'Color', [0.3 0.3 0.0]);
title('Beginning');
legend('Macrocell','Picocell','User');
set(gcf,'numbertitle','off');
set(gcf,'name','Environment');



% ================================================================== %
%   ________                                                         %
%      |                                                        |    %
%      |                                                        |    %
%      |                                                        |    %
%      |                                                        |    %
%      |           __      .       |       .       ____         |    %
%      |        | /  \           __|__            /    \        |    %
%      |        |/    \    |       |       |     |      |       |    %
%      |        |     |    |       | /     |     |      |\      |    %
%   ___|____    |     |    |       |/      |      \____/  \     |    %
% ================================================================== %

% -----------------------------------------------------
% ---------/* 下面是細胞跟UE的初始化 */----------------
% -----------------------------------------------------
% MC Setting
dist_MC    = zeros(1, n_MC);										        % dist. btwn UE and MC
RsrpMC_dBm = zeros(1, n_MC);										        % RSRP from MC
RsrpMC_dB  = zeros(1, n_MC);
idx_RsrpMC = 0;														        % Just Initialization

% PC setting
dist_PC    = zeros(1, n_PC);										        % dist. btwn PC and UE
RsrpPC_dBm = zeros(1, n_PC);										        % RSRP from PC
RsrpPC_dB  = zeros(1, n_PC);
idx_RsrpPC = 0;														        % Just Initialization

% UE setting
UE_v              = zeros(n_UE, 2);									        % User's velocities on x-axis & y-axis respectively
UE_timer_RWP1step = zeros(n_UE, 1);									        % The Timer of RandomWayPoint for changing DIRC
load('seedSpeedMDS'); 	% 1000 x 6666								        % 2016.11.17
load('seedAngleDEG');   % 1000 x 6666								        % 2016.11.24
load('seedEachStep'); 	% 1000 x 6666									    % 2016.11.17
idx_SEED          = ones(n_UE, 1);	% seed index						    % 2016.11.17
INT_SSL           = zeros(n_UE,1);	% Interference proposed by SSL

% -----------------------------------------------------
% ---------/* 下面是TST BDRY的初始化*/-----------------
% -----------------------------------------------------
% BS部分
n_RBoffer_TST   = zeros(1, n_BS);									        % The number of RB a BS offer to UEs inside it
Load_TST        = zeros(1, n_BS);
CIO_TST         = zeros(1, n_BS);

n_HO_BS_TST     = zeros(1, n_BS);	% Only for target cell			        % KPI: Handover Number of BS

% UE部分
crntRSRP_TST    = zeros(n_UE, 1);		% [dBm]

idx_UEcnct_TST  = zeros(1, n_UE);                                           % UE實際連結的基地台
idx_UEprey_TST  = zeros(1, n_UE);		                                    % UE想要連結的基地台


logical_HO      = zeros(1, n_UE);								            % '1' if idx_UEcnct just changed; '0' if idx_UEcnct is same.

timer_Arrive    = zeros(1, n_UE);	                                        % 2017.01.04


timer_TTT_TST  = zeros(1, n_UE) + t_TTT;
n_HO_UE_TST    = zeros(1, n_UE);								            % KPI: Handover Number of UE
n_HO_M2M       = 0;
n_HO_M2P       = 0;
n_HO_P2M       = 0;
n_HO_P2P       = 0;
n_HO_P2P_CoMP  = 0;

state_PPE_TST  = zeros(n_UE, 5);
n_PPE_1s_TST   = zeros(1, n_UE);								            % KPI: Ping-Pong Number
n_PPE_5s_TST   = zeros(1, n_UE);								            % KPI: Ping-Pong Number
PPR_5s_TST     = zeros(1, n_UE);								            % 2016.12.15


timer_Drop_OngoingCall_NoRB      = zeros(1, n_UE) + t_T310;
timer_Drop_OngoingCall_RBNotGood = zeros(1, n_UE) + t_T310;

timer_Drop_CoMPCall_NoRB         = zeros(1, n_UE) + t_T310;
timer_Drop_CoMPCall_RBNotGood    = zeros(1, n_UE) + t_T310;

% DropReason           = zeros(1,n_UE);	                                    % 2016.12.27	Drop Reason Range = [1,2,3,4] 
% 													                                    %   1 : RB not enough
% 													                                    %   2 : ToS limit
% 													                                    %   3 : Connecting
% 													                                    %   4 : TTT countdown

% DropReason1_M2M___RB = zeros(1,n_UE);	% Drop Reason = 1                   % 因為資源不夠而中斷 (Drop)連線
% DropReason2_M2P___RB = zeros(1,n_UE);	% Drop Reason = 1                     M2M(Macro to Macro)
% DropReason3_P2M___RB = zeros(1,n_UE);	% Drop Reason = 1                     M2P(Macro to Pico)
% DropReason4_P2P___RB = zeros(1,n_UE);	% Drop Reason = 1

% DropReason5_M2M__ToS = zeros(1,n_UE);	% Drop Reason = 2                   % 因為ToS太短，小於ToS Threshold，所以不Handover
% DropReason6_M2P__ToS = zeros(1,n_UE);	% Drop Reason = 2
% DropReason7_P2M__ToS = zeros(1,n_UE);	% Drop Reason = 2
% DropReason8_P2P__ToS = zeros(1,n_UE);	% Drop Reason = 2

% DropReason9_MMM_Conn = zeros(1,n_UE);	% Drop Reason = 3                   % A3 event 沒有發生，且因為CIO 的關係造成dropping
% DropReasonX_PPP_Conn = zeros(1,n_UE);	% Drop Reason = 3                     MMM and PPP代表目前serving對象為MC or PC

% DropReasonY_M2M__TTT = zeros(1,n_UE);	% Drop Reason = 4                   % 在TTT以內的時間發生dropping
% DropReasonY_M2P__TTT = zeros(1,n_UE);	% Drop Reason = 4
% DropReasonY_P2M__TTT = zeros(1,n_UE);	% Drop Reason = 4
% DropReasonY_P2P__TTT = zeros(1,n_UE);	% Drop Reason = 4
% % 老師的解讀:Reason1, 3, 4都是因為資源不夠的關係 (待確認)

% UE TST (LPA的部分)
LPA_P1t = zeros(1,n_UE);	% TrgtCell
LPA_P2t = zeros(1,n_UE);
LPA_P3t = zeros(1,n_UE);
LPA_Ps  = 10^((P_minRsrpRQ-30)/10);	% [Watt]
LPA_t1  = zeros(1,n_UE);
LPA_t2  = zeros(1,n_UE);
LPA_t3  = zeros(1,n_UE);
LPA_idx_pkt      = zeros(1,n_UE);
LPA_pred_trgtToS = zeros(1,n_UE);


GPSinTST_trgtToS = zeros(1,n_UE); % GPS量出來的 TOS

% -----------------------------------------------------
% ---------/* Fuzzy Q Learning 的初始化*/--------------
% -----------------------------------------------------
DoM_CIO_TSTc       = zeros(n_BS, n_FuzzyDegree);
DoM_Load_TSTc      = zeros(n_BS, n_FuzzyDegree);
DoT_Rule_New_TSTc  = zeros(n_BS, n_Rule);
DoT_Rule_Old_TSTc  = zeros(n_BS, n_Rule);
Q_Table_TSTc       = zeros(n_Rule, n_Act, n_BS);
% load('Q_Table_TSTc');
GlobalAct_TSTc     = zeros(1,n_BS);
idx_subAct_choosed_new_TSTc = zeros(n_BS, n_Rule);
idx_subAct_choosed_old_TSTc = zeros(n_BS, n_Rule);
Q_fx_new_TSTc      = zeros(1,n_BS);
Q_fx_old_TSTc      = zeros(1,n_BS);
V_fx_new_TSTc      = zeros(1,n_BS);
Q_reward_TSTc      = zeros(1,n_BS);
Q_bonus_TSTc       = zeros(1,n_BS);

% -----------------------------------------------------
% ---------/* 計算 Performance 的初始化 */-------------
% -----------------------------------------------------
% 算BS的
PRFM_TST_BS_CBR   = zeros(1, n_Measured);
PRFM_TST_BS_CDR   = zeros(1, n_Measured);
PRFM_TST_BS_QoS   = zeros(1, n_Measured);

% 算UE的
PRFM_TST_UE_nHO   = zeros(1, n_Measured);
PRFM_TST_UE_CBR   = zeros(1, n_Measured);	% 2017.01.05
PRFM_TST_UE_CDR   = zeros(1, n_Measured);
PRFM_TST_UE_1snPP = zeros(1, n_Measured);
PRFM_TST_UE_5snPP = zeros(1, n_Measured);
PRFM_TST_UE_5sPPR = zeros(1, n_Measured);

% 算Load Balancing
LB_Idle           = zeros(1, n_Measured);	% 2017.01.19
LB___PC           = zeros(1, n_Measured);	% 2017.01.19
LB___MC           = zeros(1, n_Measured);	% 2017.01.19

% Counter 
PRFM_CTR          = 1;

% -----------------------------------------------------
% ---------------/* 我的東西 初始化 */-----------------
% -----------------------------------------------------
CRE_Macro       = zeros(1, n_MC) + 0;                      % Macro 的 CRE [dBm]
CRE_Pico        = zeros(1, n_PC) + 0;                      % Pico  的 CRE [dBm]
CRE             = [CRE_Macro CRE_Pico];                    % Cell Range Expension，主要給小細胞用的，讓小細胞抓更多人進來

BS_RB_table     = zeros(n_MC + n_PC, n_ttoffered);         % 全部Cell的RB使用狀況    0:未用 1:已用
BS_RB_who_used  = zeros(n_MC + n_PC, n_ttoffered);         % Cell的RB看是哪個UE在用
UE_RB_used      = zeros(n_UE, n_ttoffered);                % UE使用了哪些RB          0:未用 1:已用
UE_Throughput   = zeros(1, n_UE);                          % 顯示每個UE的Throughput  

UE_CoMP_orNOT   = zeros(1, n_UE);                          % 判斷UE又沒有在做CoMP  0:沒有 1:正在做CoMP                    
idx_UEcnct_CoMP = zeros(n_UE, 2);                          % 看UE是給哪兩個Cell做CoMP : Colunm1 是 Serving Cell, Colunm2 是 Cooperating Cell
CoMP_Threshold  = 4;                                       % 執行CoMP的RSRP Threshold，一定要大於 3dB  (dBm)
CoMP_change_TTT = zeros(1, n_UE) + t_TTT;                  % UE在執行CoMP時，交換Serving和Cooperating角色的TTT


% UE Block定義: 原本UE沒有Serving Cell, 該UE想重新連上線，卻被拒絕
% UE Drop 定義: UE原本有一Serving Cell在服務, 但因種種原因他被放棄

n_Block_UE                 = 0;				               % 被Blcok的人數

n_Block_NewCall_NoRB_Macro = 0;                            % NewCall 因為發現Cell(Max RSRP)沒有可以用的RB了, 所以放棄連線: Block 
n_Block_NewCall_NoRB_Pico  = 0;

n_Block_NewCall_RBNotGood_Macro  = 0;                      % NewCall 因為看到Cell(Max RSRP)可以用的RB之頻譜效率都=0  , 所以放棄連線: Block
n_Block_NewCall_RBNotGood_Pico   = 0;

n_Block_Waiting_BlockTimer       = 0;                      % 在等Block timer，被Block的



UE_CBR                     = 0;                            % Call Block Rate: 全部UE跑完後，  N(被Block的人數) / n_UE

n_Drop_UE                   = 0;                           % 被Drop 的人數

Drop_OngoingCall_NoRB_Macro = 0;                           % OngoingCall 因為發現Serving Cell 沒有可以用的RB了， 並且持續1秒，所以被放棄支持連線:  Drop
Drop_OngoingCall_NoRB_Pico  = 0;

Drop_OngoingCall_RBNotGood_Macro = 0;                      % OngoingCall 因為發現Serving Cell 可以用的RB之頻譜效率都=0 ，並且持續1秒，所以放棄連線:  Drop
Drop_OngoingCall_RBNotGood_Pico  = 0;

Drop_CoMPCall_NoRB_Pico          = 0;                      % CoMPCall因為發現Serving Cell和Cooperating Cell沒有可以用的RB了，並且持續1秒， 所以被放棄支持連線:  Drop

Drop_CoMPCall_RBNotGood_Pico     = 0;                      % CoMPCall因為發現Serving Cell和Cooperating Cell可以用的RB之頻譜效率都=0 ，並且持續1秒，所以放棄連線:  Drop


UE_CDR                     = 0;                            % Call Drop Rate: 全部UE跑完後， N(被Drop的人數) / n_UE

CDR_BS                     = zeros(1,n_BS);                % 每個Base Station把UE給Drop的次數 
CBR_BS                     = zeros(1,n_BS);                % 每個Base Station把UE給Block的次數

n_DeadUE_BS                = zeros(1, n_BS);		       % 在算BS的Call Block Rate用的
n_LiveUE_BS                = zeros(1, n_BS);		       % 在算BS的Call Block Rate用的    

CBR_BS_TST 		           = zeros(1, n_BS);			   % KPI: Call Block Rate  
CDR_BS_TST 		           = zeros(1, n_BS);			   % KPI: Outage Probability 2016.11.15 -> Call Drop Rate 2017.01.04

BS_RB_consumption          = zeros(1, n_BS);               % 每個Base Station在這段時間所使用的RB數
	
UE_survive                 = 0;                            % UE平均存活人數

Success_Enter_CoMP_times = 0;                              % 成功的進入CoMP的次數
Success_Leave_CoMP_times = 0;                              % 成功的離開CoMP，沒有被切斷的次數

Failure_Leave_CoMP_Compel_times    = 0;
Failure_Leave_CoMP_NoRB_times      = 0;                    % 離開CoMP後沒人有辦法接手
Failure_Leave_CoMP_RBNotGood_times = 0;


Handover_Failure_times                    = 0;             % Handover失敗的次數
Handover_to_Macro_Failure_NoRB_times      = 0;             % 想handover到Macro但是被拒絕的次數
Handover_to_Pico_Failure_NoRB_times       = 0;             % 想handover到Pico但是被拒絕的次數

Handover_to_Macro_Failure_RBNotGood_times = 0;             % 想handover到Macro但是被拒絕的次數
Handover_to_Pico_Failure_RBNotGood_times  = 0;             % 想handover到Pico但是被拒絕的次數


Macro_Serving_Num_change        = zeros((ttSimuT/t_d), 1);
Pico_NonCoMP_Serving_Num_change = zeros((ttSimuT/t_d), 1);
Pico_CoMP_Serving_Num_change    = zeros((ttSimuT/t_d), 1);
% ============================================================= %
%    ________                                                   %
%   /                                                           %
%  /                                                            %
%  \                                                            %
%   \________      ___|___      ____        |  /     ___|___    %
%            \        |        /    \       | /         |       %
%             \       |       |      |      |/          |       %
%             /       | /     |      |\     |           | /     %
%   _________/        |/       \____/  \    |           |/      %
% ============================================================= %
tic

% Loop 1: Time
for idx_t = t_start : t_d : t_simu   								            % [sec] % 0.1 sec per loop
	if (rem(idx_t,t_simu/ttSimuT) < 1e-3)                                       % 顯示時間用的，不知道在幹嘛， 不過不影響
		fprintf(' %.3f sec\n', idx_t)
	end

	AMP_Noise  = LTE_NoiseFloor_watt * randn(1);                            % 每個時間點的白高斯 雜訊都不一樣 [watt/RB]


	% Loop 2: User	
	% 寫收訊號的，A3 event，統計各個Performance，關係到RB 的要自己來 ( 細胞loading的問題, UE's SINR計算 )
	for idx_UE = 1:n_UE
		Dis_Connect_Reason  = 0;
		Dis_Handover_Reason = 0;

		if idx_t >= 1.9
			a = 1;
		end

		if idx_UE == 175
			a = 1;
		end

		% ============================================================================================= %
		%                    ________                             \                    ___              %
		%   |          |    |                  |    /            __\__ _______        |   |      |__    %
		%   |          |    |              |   |   /--------               | |        |___|   ___|___   %
		%   |          |    |              |  /|  /  \    /       ___      | |         ___   |  _|_ /   %
		%   |          |    |________      | / |      \  /        ___      | |         ___   |   |_     %
		%   |          |    |                  |       \/         ___      / \         /__   /          %
		%   |          |    |                  |       /\        |   |   \/   \  /       /  /   / \     %
		%    __________     |________          |    __/  \__     |___|   /\    \/      \/  /   /   \_   %
		%                                                                                               %
		% ============================================================================================= %
		for mc = 1:n_MC
			dist_MC(mc)    = norm(UE_lct(idx_UE,:) - Macro_location(mc,:)); % 該UE距離全部MC多遠 [meter]
			RsrpMC_dBm(mc) = P_MC_dBm - PLmodel_3GPP(dist_MC(mc), 'M');		% 該UE從這些MC收到的RSRP [dBm]
		end
		for pc = 1:n_PC
			dist_PC(pc)    = norm(UE_lct(idx_UE,:) - Pico_location(pc,:));  % 該UE距離全部PC多遠 [meter]
			RsrpPC_dBm(pc) = P_PC_dBm - PLmodel_3GPP(dist_PC(pc), 'P');	    % 該UE從這些PC收到的RSRP [dBm]
		end
		RsrpBS_dBm  = [RsrpMC_dBm RsrpPC_dBm];
		RsrpBS_dB   = RsrpBS_dBm - 30;								          
		RsrpBS_Watt = 10.^(RsrpBS_dB/10);                                   % 全部換成瓦特

		% =============================================================================================== %
		%                                                                                                 %
		%                                                ______                               ____        %
		%   |\     |                                   /                     |\          /|  |    \       %
		%   | \    |      __                          /              __      | \        / |  |     |      %
		%   |  \   |    /    \   _ ____      ______  |             /    \    |  \      /  |  |____/       %
		%   |   \  |   |      |  |/    \             |            |      |   |   \    /   |  |            %
		%   |    \ |   |      |  |      |             \           |      |   |    \  /    |  |            %
		%   |     \|    \ __ /   |      |              \_______    \ __ /    |      v     |  |            %
		%                                                                                                 %
		% =============================================================================================== %
		% UE在Non-CoMP下走的FlowChart
		if UE_CoMP_orNOT(idx_UE) == 0  % UE沒有做CoMP
			temp_CoMP_state = 0;

			% ------------------------------------------------------------------------------- %
			% 找出目前哪個基地台RSRP對該UE最大 ，而且是多少dB (對比到學長主程式的311-313行 )  %
			% ------------------------------------------------------------------------------- %
			temp_rsrp = RsrpBS_dBm + CIO_TST;
			% target對象不要選到自己
			if idx_UEcnct_TST(idx_UE) ~= 0
				temp_rsrp(idx_UEcnct_TST(idx_UE)) = min(temp_rsrp); 
			end
			% 選RSRP+CIO最大的出來				
			[~, idx_trgt] = max(temp_rsrp);

			% ------------------------------ %
			% 把目前應該要服務我的人抓出來   %
			% ------------------------------ %
			if idx_UEcnct_TST(idx_UE) == 0						 % 如果沒人服務我，只會發生在initial的時候
				idx_UEprey_TST(idx_UE) = idx_trgt;				 % RSRP 最大的成為我的目標
			else                             				     % 如果已經有人服務我了
				idx_UEprey_TST(idx_UE) = idx_UEcnct_TST(idx_UE); % 那目前的連線對象就是我的目標
			end

			% ----------------- %
			% 看有沒有人服務你  %
			% ----------------- %
			if (idx_UEcnct_TST(idx_UE) == 0) % 沒人服務，這可能是initial  or 被踢掉

				% --------------------------------------------------------------------- %
				% 當user被踢掉後，必須等一段時間才能重新拿RB，這裡就UE是在等這段時間    %
				% 當user等完了之後，就要開始拿RB                                        %
				% --------------------------------------------------------------------- %
				if (timer_Arrive(idx_UE) ~= 0) % Waiting Users
					timer_Arrive(idx_UE) = timer_Arrive(idx_UE) - t_d;	% Countdown
					if (timer_Arrive(idx_UE) < t_d)
						timer_Arrive(idx_UE) = 0;
					end
					Dis_Connect_Reason = 3; % 還在等連線，也算在Call  Block Rate頭上
 
				else  %(timer_Arrive(idx_UE) == 0): Arriving Users	
					% ---------------- %
					% 拿Resource Block %
					% ---------------- %				
					[BS_RB_table, BS_RB_who_used, UE_RB_used, idx_UEcnct_TST(idx_UE), UE_Throughput(idx_UE), Dis_Connect_Reason] = NewCall_take_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
									                                                                                                               idx_UE, idx_trgt, GBR, BW_PRB);
									                                                                                                               
					% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);

					% -------------------------------------------------------------------- %
					% 不論UE是死是活，都會再給他一個等待時間，下次她被放棄時就會數這個     %
					% -------------------------------------------------------------------- %
					while timer_Arrive(idx_UE) == 0	
						timer_Arrive(idx_UE) = poissrnd(1);	% 2017.01.05 Not to be ZERO please.  % 不要是 0
					end					

					% ---------------------------------------------------- %
					% 計算Ping-Pong Effect是否有發生，跟Performance 的計算 %
					% 有兩個KPI: (1) 1秒內發生碰撞   (2) 5秒內發生碰撞     %
					% ---------------------------------------------------- %
					if idx_UEcnct_TST(idx_UE) ~= state_PPE_TST(idx_UE,1)	% 2017.01.04

						state_PPE_TST(idx_UE,:) = PingPong_Update(state_PPE_TST(idx_UE,:), idx_UEcnct_TST(idx_UE), idx_t);
						% ===/* Ping Pong State Update [1 sec] */===
						if    (state_PPE_TST(idx_UE,1) == state_PPE_TST(idx_UE,3) ...
							&& state_PPE_TST(idx_UE,1) ~= state_PPE_TST(idx_UE,2) ...
							&& state_PPE_TST(idx_UE,4) -  state_PPE_TST(idx_UE,5) <= MTS_1s ...
							&& prod(state_PPE_TST(idx_UE,:)) ~= 0)	% 2017.01.04 Live 2 Dead 2 Live is not Ping-Pong, Dead 2 Live 2 Dead either.
							% Ping-Pong Effect Occur
							n_PPE_1s_TST(idx_UE) = n_PPE_1s_TST(idx_UE) + 1; % [PRFM]
						end
						% ===/* Ping Pong State Update [5 sec] */===
						if    (state_PPE_TST(idx_UE,1) == state_PPE_TST(idx_UE,3) ...
							&& state_PPE_TST(idx_UE,1) ~= state_PPE_TST(idx_UE,2) ...
							&& state_PPE_TST(idx_UE,4) -  state_PPE_TST(idx_UE,5) <= MTS_5s ...
							&& prod(state_PPE_TST(idx_UE,:)) ~= 0)	% 2017.01.04 Live 2 Dead 2 Live is not Ping-Pong, Dead 2 Live 2 Dead either.
							% Ping-Pong Effect Occur
							n_PPE_5s_TST(idx_UE) = n_PPE_5s_TST(idx_UE) + 1; % [PRFM]
							PPR_5s_TST(idx_UE)   = n_PPE_5s_TST(idx_UE) / n_HO_UE_TST(idx_UE);	% 2016.12.15
						end
					end 					
				end

				% ----------------- %
				% 計算UE Call Block %
				% ----------------- %
				if Dis_Connect_Reason == 0

					% 還原
					Dis_Connect_Reason = 0;

				else
					if Dis_Connect_Reason == 1
						n_Block_UE = n_Block_UE + 1;

						% 該UE因為Cell的資源不夠被放棄
						if idx_trgt <= n_MC
							n_Block_NewCall_NoRB_Macro = n_Block_NewCall_NoRB_Macro + 1;							
						else
							n_Block_NewCall_NoRB_Pico = n_Block_NewCall_NoRB_Pico + 1;
						end

						% 還原
						Dis_Connect_Reason = 0;

					elseif Dis_Connect_Reason == 2
						n_Block_UE = n_Block_UE + 1;
						
						% 該UE因為看到的RB之頻譜效率都太低了,  所以被拒絕
						if idx_trgt <= n_MC
							n_Block_NewCall_RBNotGood_Macro = n_Block_NewCall_RBNotGood_Macro + 1;							
						else
							n_Block_NewCall_RBNotGood_Pico = n_Block_NewCall_RBNotGood_Pico + 1;
						end

						% 還原
						Dis_Connect_Reason = 0;
					elseif Dis_Connect_Reason == 3
						n_Block_UE = n_Block_UE + 1;

						% 因為UE還在等 ，所以也算被Block
						n_Block_Waiting_BlockTimer = n_Block_Waiting_BlockTimer + 1;

						% 還原
						Dis_Connect_Reason = 0;
					end
				end
			else %(idx_UEcnct_TST(idx_UE) ~= 0): 有人正在服務我 

				% --------------- %
				% 更新Throuhgput  %
				% --------------- %
				[UE_Throughput(idx_UE)] = Non_CoMP_Update_Throughput(n_MC, n_PC, BS_RB_table, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
														             idx_UE, idx_UEcnct_TST(idx_UE), BW_PRB);				

				% -------------------- %
				% 看A3 Event有沒有成立 %
				% -------------------- %						
				if (RsrpBS_dBm(idx_trgt) + CIO_TST(idx_trgt) > RsrpBS_dBm(idx_UEcnct_TST(idx_UE)) + CIO_TST(idx_UEcnct_TST(idx_UE)) + HHM)

					% A3 Event一旦trigger，TTT就開始數
					if (timer_TTT_TST(idx_UE) <= t_TTT && timer_TTT_TST(idx_UE) > 0)

						% 單純減TTT
						timer_TTT_TST(idx_UE) = timer_TTT_TST(idx_UE) - t_d;
						if (timer_TTT_TST(idx_UE) < 1e-5)	% [SPECIAL CASE] 0930
							timer_TTT_TST(idx_UE) = 0;		% [SPECIAL CASE]
						end 

					elseif (timer_TTT_TST(idx_UE) == 0)	
						% ==================================================================== %	% ================================== %
						%     -----    ------    -----             -------   -----   -------   %	%   ------  ------   ------  -   --	 %
						%    /         |     )  (                     |     (           |      %	%   |     ) |     \  |     )  \ /	 %
						%   |     ---  |-----    -----     o -_       |      -----      |      %	%   ------  |      | ------    V 	 %
						%    \     |   |              )    | | |      |           )     |      %	%   |     ) |     /  |     \   |	 %
						%     -----    -         -----     - - -      -      -----      -      %	%   ------  ------   -     -   -	 %
						% ==================================================================== %	% ================================== %
						% distance_UE_target = norm(UE_lct(idx_UE,:) - BS_lct(idx_trgt,:));							
						% % tToS
						% if idx_trgt <= n_MC
						% 	GPSinTST_trgtToS(idx_UE) = GPS_fx(BS_lct(idx_trgt,:), MACROCELL_RADIUS, UE_lct(idx_UE,:), UE_v(idx_UE,:)) - t_TTT; % 2017.01.21
						% else  % idx_trgt > n_MC
						% 	GPSinTST_trgtToS(idx_UE) = GPS_fx(BS_lct(idx_trgt,:), distance_UE_target, UE_lct(idx_UE,:), UE_v(idx_UE,:)) - t_TTT; % 2017.01.21
						% end

						% Willie的演算法
						% if GPSinTST_trgtToS(idx_UE) > TST_HD
							% 通過A3 Event ---> 數完TTT ---> Time of Stay Threshold大於TST_HD ---> 接下來檢查夠不夠資源

						% Handover Call來拿RB
						temp_idx_UEcnct_TST = idx_UEcnct_TST(idx_UE); % 暫存的，來紀錄從哪裡handover到哪裡
						[BS_RB_table, BS_RB_who_used, UE_RB_used, idx_UEcnct_TST(idx_UE), UE_Throughput(idx_UE), Dis_Handover_Reason] = HandoverCall_take_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
										                                                                                                                    idx_UE, idx_UEcnct_TST(idx_UE), idx_trgt, UE_Throughput(idx_UE), GBR, BW_PRB);
						% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);

						if idx_UEcnct_TST(idx_UE) == idx_trgt
							% !!!!!!!!!!成功Handvoer到Target Cell!!!!!!!!!!
							% ---------------- %
							% Handover次數計算 %
							% ---------------- %
							n_HO_UE_TST(idx_UE)   = n_HO_UE_TST(idx_UE)   + 1;
							n_HO_BS_TST(idx_trgt) = n_HO_BS_TST(idx_trgt) + 1;	% Only for target cell

							% ----------------------------------- %
							% 看Handover是從什麼Cell換到什麼Cell  %
							% ----------------------------------- %
							if     temp_idx_UEcnct_TST <= n_MC && idx_UEcnct_TST(idx_UE) <= n_MC
								n_HO_M2M = n_HO_M2M + 1;
							elseif temp_idx_UEcnct_TST <= n_MC && idx_UEcnct_TST(idx_UE) >  n_MC
								n_HO_M2P = n_HO_M2P + 1;
							elseif temp_idx_UEcnct_TST >  n_MC && idx_UEcnct_TST(idx_UE) <= n_MC
								n_HO_P2M = n_HO_P2M + 1;
							elseif temp_idx_UEcnct_TST >  n_MC && idx_UEcnct_TST(idx_UE) >  n_MC
								n_HO_P2P = n_HO_P2P + 1;
							end	

							% ------------------------------------- %
							% 記錄該UE在該時間點是否執行了Handover  %
							% ------------------------------------- %
							logical_HO(idx_UE) = 1;	% Handover success.

							% --------- %
							% TTT Reset %
							% --------- %
							timer_TTT_TST(idx_UE) = t_TTT;	% 2016.12.28

							% --------------------- %
							% Ping-Pong Rate UPDATE %
							% --------------------- %
							PPR_5s_TST(idx_UE)    = n_PPE_5s_TST(idx_UE) / n_HO_UE_TST(idx_UE);	% 2017.01.01
						else
							Handover_Failure_times = Handover_Failure_times + 1;

							% Handover失敗了，看是Handover誰而失敗，阿為什麼失敗，計錄下來
							if Dis_Handover_Reason == 1
								if idx_trgt <= n_MC
									Handover_to_Macro_Failure_NoRB_times = Handover_to_Macro_Failure_NoRB_times + 1;
								else
									Handover_to_Pico_Failure_NoRB_times  = Handover_to_Pico_Failure_NoRB_times + 1;
								end

							elseif Dis_Handover_Reason == 2
								if idx_trgt <= n_MC
									Handover_to_Macro_Failure_RBNotGood_times = Handover_to_Macro_Failure_RBNotGood_times + 1;										
								else
									Handover_to_Pico_Failure_RBNotGood_times  = Handover_to_Pico_Failure_RBNotGood_times + 1;
								end
							end
							Dis_Handover_Reason = 0;

							% ------------------------------------- %
							% 記錄該UE在該時間點是否執行了Handover  %
							% ------------------------------------- %
							logical_HO(idx_UE) = 0;	% Handover fail
						end
						% end
					end		
				else
					% 沒有Handover !!!
					logical_HO(idx_UE) = 0;

					% TTT Reset
					timer_TTT_TST(idx_UE) = t_TTT;
				end
				% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);

                % ----------------------------------------------------------- %
				% 如果(1)沒有過A3 Event               __\  就會走以下的流程   %
				%     (2)過了但是Target Cell沒有資源    /	                  %
				% ----------------------------------------------------------- %			
				if logical_HO(idx_UE) == 0

					% ------------------------------------------------------ %
					% 如果Throughput < GBR，先來換換看，這裡注意一定要先換   %
					% ------------------------------------------------------ %
					if UE_Throughput(idx_UE) < GBR
						if idx_UEcnct_TST(idx_UE) <= n_MC
							%  看能不能換個RB 位置 					
							if (isempty(find(UE_RB_used(idx_UE,:) == 1)) == 0) && (isempty(find(BS_RB_table(idx_UEcnct_TST(idx_UE),:) == 0)) == 0)
								[BS_RB_table, BS_RB_who_used, UE_RB_used, UE_Throughput(idx_UE)] = Non_CoMP_Serving_change_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
									                                                                                          idx_UE, idx_UEcnct_TST(idx_UE), UE_Throughput(idx_UE), GBR, BW_PRB);						                                                                                          
							end
						else
							%  看能不能換個RB 位置 					
							if (isempty(find(UE_RB_used(idx_UE, 1:Pico_part) == 1)) == 0) && (isempty(find(BS_RB_table(idx_UEcnct_TST(idx_UE),:) == 0)) == 0)
								[BS_RB_table, BS_RB_who_used, UE_RB_used, UE_Throughput(idx_UE)] = Non_CoMP_Serving_change_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
									                                                                                          idx_UE, idx_UEcnct_TST(idx_UE), UE_Throughput(idx_UE), GBR, BW_PRB);		                                                                                          
							end
						end

						% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);
					end

					% ------------------------------------ %
					% 如果Throughput >= GBR，看能不能丟RB  %
					% ------------------------------------ %
					if UE_Throughput(idx_UE) >= GBR
						% 把頻譜效率 = 0的RB丟掉，如果還可以再丟，那就繼續丟
						[BS_RB_table, BS_RB_who_used, UE_RB_used, UE_Throughput(idx_UE)] = Non_CoMP_throw_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
																										     idx_UE, idx_UEcnct_TST(idx_UE), GBR, BW_PRB);

						% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);
					end

					% ------------------------------------------- %
					% 先看看能不能執行Dynamic Resource Scheduling % 
					% ------------------------------------------- %
					if UE_Throughput(idx_UE) < GBR
						if idx_trgt > n_MC
							% Dynamic Resource Scheduling 寫在這段
							if (isempty(find(UE_RB_used(idx_UE, 1:Pico_part) == 1)) == 0) && (isempty(find(BS_RB_table(idx_trgt,:) == 0)) == 0)
								[BS_RB_table, BS_RB_who_used, UE_RB_used, UE_Throughput(idx_UE)] = Non_CoMP_DRS(BS_lct, n_MC, n_PC, P_MC_dBm, P_PC_dBm, BS_RB_table, BS_RB_who_used, UE_lct, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
																												idx_UE, idx_UEcnct_TST(idx_UE), idx_trgt, UE_Throughput(idx_UE), ...
																												GBR, BW_PRB, UE_CoMP_orNOT);

								% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);
							end							

							% 做完Dynamic Resource Scheduling 發現QoS還是不夠，就看看能不能做CoMP，前提是Serving也要是Pico   Cell，如果不是那就沒辦法做CoMP了
							if UE_Throughput(idx_UE) < GBR
								
								% --------------------- %
								% 再看看能不能執行CoMP  %  
								% --------------------- %
								if idx_UEcnct_TST(idx_UE) > n_MC

									% ----------- %
									% 更新Loading %
									% ----------- %
									[Load_TST] = Update_Loading(n_BS, n_MC, BS_RB_table, n_ttoffered, Pico_part);	

									if Load_TST(idx_UEcnct_TST(idx_UE)) > Load_TST(idx_trgt)
										if RsrpBS_dBm(idx_UEcnct_TST(idx_UE)) <= RsrpBS_dBm(idx_trgt) + CoMP_Threshold
											% CoMP掛在這邊
											% [BS_RB_table, BS_RB_who_used, UE_RB_used, idx_UEcnct_TST(idx_UE), idx_UEcnct_CoMP, UE_CoMP_orNOT(idx_UE), UE_Throughput(idx_UE)] = Non_CoMP_to_CoMP(BS_lct, n_MC, n_PC, P_MC_dBm, P_PC_dBm, BS_RB_table, BS_RB_who_used, UE_lct, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
											% 																																				idx_UE, idx_UEcnct_TST(idx_UE), idx_trgt, UE_Throughput(idx_UE), ...
											% 																																				GBR, BW_PRB, idx_UEcnct_CoMP, UE_CoMP_orNOT);
											
											% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);
											if UE_CoMP_orNOT(idx_UE) == 1
												Success_Enter_CoMP_times = Success_Enter_CoMP_times + 1;
											end	
										end
									end
								end

							end
						end
					end					

					% ---------------------------------------------------------- %
					% 如果在上面執行了CoMP，QoS一定會通過，沒通過的話再多拿RB    % 
					% ---------------------------------------------------------- %
					if UE_Throughput(idx_UE) < GBR	
						[BS_RB_table, BS_RB_who_used, UE_RB_used, UE_Throughput(idx_UE), Dis_Connect_Reason] = Non_CoMP_take_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
																																	idx_UE, idx_UEcnct_TST(idx_UE), UE_Throughput(idx_UE), GBR, BW_PRB);																											
							
						% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);

					end 

					% ----------------------------------------------------------------- %
					% 總於言之呢，Throughput有過QoS，就是OK啦，如果不ok就不會進來這了   %
					% ----------------------------------------------------------------- %
					if UE_Throughput(idx_UE) >= GBR
						Dis_Connect_Reason = 0;
					end
				end 


				% ---------------------------------- %
				% 計算UE Call Drop and BS Call Drop  %
				% ---------------------------------- %
				if Dis_Connect_Reason == 0          % 會進來這代表 (1)UE handover成功 (2)沒有handover or handover失敗，但是UE成功連回Serving  Cell

					% Dropping timer 重置為 1sec					
					timer_Drop_OngoingCall_NoRB(idx_UE)      = t_T310;
					timer_Drop_OngoingCall_RBNotGood(idx_UE) = t_T310;

					% 還原
					Dis_Connect_Reason = 0;
				else
					if Dis_Connect_Reason == 1      % 會進來這裡就是  (1)找Serving Cell要資源，Serving Cell說資源沒了
						if timer_Drop_OngoingCall_NoRB(idx_UE) <= t_T310 && timer_Drop_OngoingCall_NoRB(idx_UE) > 0
							timer_Drop_OngoingCall_NoRB(idx_UE) = timer_Drop_OngoingCall_NoRB(idx_UE) - t_d;
							if timer_Drop_OngoingCall_NoRB(idx_UE) < 1e-5	% [SPECIAL CASE]
								timer_Drop_OngoingCall_NoRB(idx_UE) = 0;		% [SPECIAL CASE]
							end 

							% 還原
							Dis_Connect_Reason = 0;

						elseif timer_Drop_OngoingCall_NoRB(idx_UE) == 0

							% Drop記上一筆
							n_Drop_UE = n_Drop_UE + 1;

							% 該UE因為Cell的資源不夠被放棄						
							CDR_BS(idx_UEcnct_TST(idx_UE)) = CDR_BS(idx_UEcnct_TST(idx_UE)) + 1;

							% 看UE是被Macro還是Pico說資源不夠，而把你斷掉的
							if idx_UEcnct_TST(idx_UE) <= n_MC
								Drop_OngoingCall_NoRB_Macro = Drop_OngoingCall_NoRB_Macro + 1;								
							else
								Drop_OngoingCall_NoRB_Pico  = Drop_OngoingCall_NoRB_Pico + 1;
							end

							% 把RB還給Serving Cell
							if idx_UEcnct_TST(idx_UE) <= n_MC
								for RB_index = 1:1:n_ttoffered
									if BS_RB_table(idx_UEcnct_TST(idx_UE), RB_index) == 1 && UE_RB_used(idx_UE, RB_index) == 1
										BS_RB_table(idx_UEcnct_TST(idx_UE), RB_index)    = 0;
										BS_RB_who_used(idx_UEcnct_TST(idx_UE), RB_index) = 0;
										UE_RB_used(idx_UE, RB_index)                     = 0;
									end
								end
							else
								for RB_index = 1:1:Pico_part
									if BS_RB_table(idx_UEcnct_TST(idx_UE), RB_index) == 1 && UE_RB_used(idx_UE, RB_index) == 1
										BS_RB_table(idx_UEcnct_TST(idx_UE), RB_index)    = 0;
										BS_RB_who_used(idx_UEcnct_TST(idx_UE), RB_index) = 0;
										UE_RB_used(idx_UE, RB_index)                     = 0;
									end
								end
							end		
							idx_UEcnct_TST(idx_UE) = 0; % 結束連線
							UE_Throughput(idx_UE)  = 0; % UE的throughput歸零

							% Dropping timer 重置為 1sec
							timer_Drop_OngoingCall_NoRB(idx_UE)      = t_T310;
							timer_Drop_OngoingCall_RBNotGood(idx_UE) = t_T310;

							% 還原
							Dis_Connect_Reason = 0;
						end

					elseif Dis_Connect_Reason == 2  % 會進來這裡就是  (1)找Serving Cell要資源，發現Serving Cell的RB質量不夠

						if timer_Drop_OngoingCall_RBNotGood(idx_UE) <= t_T310 && timer_Drop_OngoingCall_RBNotGood(idx_UE) > 0
							% 倒數Drop timer 
							timer_Drop_OngoingCall_RBNotGood(idx_UE) = timer_Drop_OngoingCall_RBNotGood(idx_UE) - t_d;
							if timer_Drop_OngoingCall_RBNotGood(idx_UE) < 1e-5	% [SPECIAL CASE]
								timer_Drop_OngoingCall_RBNotGood(idx_UE) = 0;		% [SPECIAL CASE]
							end 

							% 還原
							Dis_Connect_Reason = 0;

						elseif timer_Drop_OngoingCall_RBNotGood(idx_UE) == 0

							% Drop記上一筆
							n_Drop_UE = n_Drop_UE + 1;

							% 該Ongoing Call因為看到的RB之頻譜效率都太低了,  並且持續1秒, 所以被拒絕
							CDR_BS(idx_UEcnct_TST(idx_UE))  = CDR_BS(idx_UEcnct_TST(idx_UE)) + 1;

							% 這裡是因為UE自己走太遠，但在之間如果有想Handover但被拒絕，導致他走太遠沒人服務，這也要算一筆							
							if idx_UEcnct_TST(idx_UE) <= n_MC
								Drop_OngoingCall_RBNotGood_Macro = Drop_OngoingCall_RBNotGood_Macro + 1;
							else
								Drop_OngoingCall_RBNotGood_Pico  = Drop_OngoingCall_RBNotGood_Pico + 1;
							end		

							% 把RB還給Serving Cell
							if idx_UEcnct_TST(idx_UE) <= n_MC
								for RB_index = 1:1:n_ttoffered
									if BS_RB_table(idx_UEcnct_TST(idx_UE), RB_index) == 1 && UE_RB_used(idx_UE, RB_index) == 1
										BS_RB_table(idx_UEcnct_TST(idx_UE), RB_index)    = 0;
										BS_RB_who_used(idx_UEcnct_TST(idx_UE), RB_index) = 0;
										UE_RB_used(idx_UE, RB_index)                     = 0;
									end
								end
							else
								for RB_index = 1:1:Pico_part
									if BS_RB_table(idx_UEcnct_TST(idx_UE), RB_index) == 1 && UE_RB_used(idx_UE, RB_index) == 1
										BS_RB_table(idx_UEcnct_TST(idx_UE), RB_index)    = 0;
										BS_RB_who_used(idx_UEcnct_TST(idx_UE), RB_index) = 0;
										UE_RB_used(idx_UE, RB_index)                     = 0;
									end
								end
							end	
							idx_UEcnct_TST(idx_UE) = 0; % 結束連線
							UE_Throughput(idx_UE)  = 0; % UE的throughput歸零

							% Dropping timer 重置為 1sec
							timer_Drop_OngoingCall_NoRB(idx_UE)      = t_T310;
							timer_Drop_OngoingCall_RBNotGood(idx_UE) = t_T310;

							% 還原
							Dis_Connect_Reason = 0;
						end						
					end
				end
				% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);

				% --------------------------------- %
				% 主要統計: 檢查Ping-Pong有沒有發生 %
				% --------------------------------- %
				if logical_HO(idx_UE) == 1

					% ---------------------------------------------------- %
					% 計算Ping-Pong Effect是否有發生，跟Performance 的計算 %
					% 有兩個KPI: (1) 1秒內發生碰撞   (2) 5秒內發生碰撞     %
					% ---------------------------------------------------- %
					state_PPE_TST(idx_UE,:) = PingPong_Update(state_PPE_TST(idx_UE,:), idx_UEcnct_TST(idx_UE), idx_t);
					% ===/* Ping Pong State Update [1 sec] */===
					if    (state_PPE_TST(idx_UE,1) == state_PPE_TST(idx_UE,3) ...
						&& state_PPE_TST(idx_UE,1) ~= state_PPE_TST(idx_UE,2) ...
						&& state_PPE_TST(idx_UE,4) -  state_PPE_TST(idx_UE,5) <= MTS_1s ...
						&& prod(state_PPE_TST(idx_UE,:)) ~= 0)	% 2017.01.04 Live 2 Dead 2 Live is not Ping-Pong, Dead 2 Live 2 Dead either.
						% Ping-Pong Effect Occur
						n_PPE_1s_TST(idx_UE) = n_PPE_1s_TST(idx_UE) + 1; % [PRFM]
					end
					% ===/* Ping Pong State Update [5 sec] */===
					if    (state_PPE_TST(idx_UE,1) == state_PPE_TST(idx_UE,3) ...
						&& state_PPE_TST(idx_UE,1) ~= state_PPE_TST(idx_UE,2) ...
						&& state_PPE_TST(idx_UE,4) -  state_PPE_TST(idx_UE,5) <= MTS_5s ...
						&& prod(state_PPE_TST(idx_UE,:)) ~= 0)	% 2017.01.04 Live 2 Dead 2 Live is not Ping-Pong, Dead 2 Live 2 Dead either.
						% Ping-Pong Effect Occur
						n_PPE_5s_TST(idx_UE) = n_PPE_5s_TST(idx_UE) + 1; % [PRFM]
						PPR_5s_TST(idx_UE)   = n_PPE_5s_TST(idx_UE) / n_HO_UE_TST(idx_UE);	% 2016.12.15
					end

					% 還原
					logical_HO(idx_UE) = 0;
				else
					if UE_CoMP_orNOT(idx_UE) == 1 % 如果開始執行CoMP，這時Ping-pong  effect 不存在					
						state_PPE_TST(idx_UE,:) = 0;
					end
				end
			end
		% ======================================================= %
		%                                                         %
		%       ______                               ____         %
		%      /                     |\          /|  |    \       %
		%     /              __      | \        / |  |     |      %
		%    |             /    \    |  \      /  |  |____/       %
		%    |            |      |   |   \    /   |  |            %
		%     \           |      |   |    \  /    |  |            %
		%      \_______    \ __ /    |      v     |  |            %
		%                                                         %
		% ======================================================= %			
		else
			temp_Serving     = idx_UEcnct_CoMP(idx_UE, 1); % 算BS的Call Block Rate用的
			temp_Cooperating = idx_UEcnct_CoMP(idx_UE, 2); % 算BS的Call Block Rate用的
			temp_CoMP_state  = 1;                          % 算BS的Call Block Rate用的

			% --------------- %
			% 更新Throuhgput  %
			% --------------- %
			[UE_Throughput(idx_UE)] = CoMP_Update_Throughput(n_MC, n_PC, BS_RB_table, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
														     idx_UE, idx_UEcnct_CoMP(idx_UE, 1), idx_UEcnct_CoMP(idx_UE, 2), BW_PRB);

			% --------------------- %
			% 先看有沒有要離開CoMP  %
			% --------------------- %
			if RsrpBS_dBm(idx_UEcnct_CoMP(idx_UE, 1)) > RsrpBS_dBm(idx_UEcnct_CoMP(idx_UE, 2)) + CoMP_Threshold % 強制離開，有沒有滿足QoS給Serving  Cell想辦法
				
				[BS_RB_table, BS_RB_who_used, UE_RB_used, idx_UEcnct_TST(idx_UE), idx_UEcnct_CoMP, UE_CoMP_orNOT(idx_UE), UE_Throughput(idx_UE)] = CoMP_Compel_to_Non_CoMP(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
																																										   idx_UE, idx_UEcnct_CoMP(idx_UE, 1), idx_UEcnct_CoMP(idx_UE, 2), idx_UEcnct_CoMP, BW_PRB);
				if UE_Throughput(idx_UE) < GBR					
					[BS_RB_table, BS_RB_who_used, UE_RB_used, UE_Throughput(idx_UE), Dis_Connect_Reason] = Non_CoMP_take_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
																															idx_UE, idx_UEcnct_TST(idx_UE), UE_Throughput(idx_UE), GBR, BW_PRB);
				else
					Dis_Connect_Reason = 0;
				end

				% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);
			end 

			if UE_CoMP_orNOT(idx_UE) == 1
				% ------------------------- %
				% 再看有沒有要交換Cell角色  %
				% ------------------------- %
				if RsrpBS_dBm(idx_UEcnct_CoMP(idx_UE, 2)) > RsrpBS_dBm(idx_UEcnct_CoMP(idx_UE, 1)) + HHM
					% 交換條件一旦trigger，TTT就開始數
					if (CoMP_change_TTT(idx_UE) <= t_TTT && CoMP_change_TTT(idx_UE) > 0)
						% 單純減TTT
						CoMP_change_TTT(idx_UE) = CoMP_change_TTT(idx_UE) - t_d;
						if (CoMP_change_TTT(idx_UE) < 1e-5)	% [SPECIAL CASE]
							CoMP_change_TTT(idx_UE) = 0;	% [SPECIAL CASE]
						end 

					elseif (CoMP_change_TTT(idx_UE) == 0)	
						% 交換Serving Cell, Cooperating Cell角色
						temp = idx_UEcnct_CoMP(idx_UE, 1);
						idx_UEcnct_CoMP(idx_UE, 1) = idx_UEcnct_CoMP(idx_UE, 2);
						idx_UEcnct_CoMP(idx_UE, 2) = temp;

						temp_Serving     = idx_UEcnct_CoMP(idx_UE, 1);
						temp_Cooperating = idx_UEcnct_CoMP(idx_UE, 2);

						% 重置
						CoMP_change_TTT(idx_UE) = t_TTT;
					end
				else
					% TTT Reset
					CoMP_change_TTT(idx_UE) = t_TTT;
				end

				% ------------------------------------------------------ %
				% 如果Throughput < GBR，先來換換看，這裡注意一定要先換   %
				% ------------------------------------------------------ %
				if UE_Throughput(idx_UE) < GBR 																								
					%  看能不能換CoMP的RB 位置 		
					if UE_Throughput(idx_UE) < GBR && (isempty(find(UE_RB_used(idx_UE, 1:Pico_part) == 1)) == 0)
						[BS_RB_table, BS_RB_who_used, UE_RB_used, UE_Throughput(idx_UE)] = CoMP_change_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
																										  idx_UE, idx_UEcnct_CoMP(idx_UE, 1), idx_UEcnct_CoMP(idx_UE, 2), UE_Throughput(idx_UE), GBR, BW_PRB);
					end

					% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);
				end

				% ----------------------------------- %
				% 如果Throughput > GBR，看能不能丟RB  %
				% ----------------------------------- %
				if UE_Throughput(idx_UE) >= GBR
					[BS_RB_table, BS_RB_who_used, UE_RB_used, UE_Throughput(idx_UE)] = CoMP_throw_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
																									 idx_UE, idx_UEcnct_CoMP(idx_UE, 1), idx_UEcnct_CoMP(idx_UE, 2), GBR, BW_PRB);

					% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);
				end

				% ------------------------------------------------------------ %
				% 再來看UE的Throughput狀況怎樣，再來看說要不要多拿RB來做CoMP   %
				% ------------------------------------------------------------ %
				if UE_Throughput(idx_UE) < GBR
					[BS_RB_table, UE_RB_used, BS_RB_who_used, UE_Throughput(idx_UE), Dis_Connect_Reason] = CoMP_take_RB(BS_lct, n_MC, n_PC, P_MC_dBm, P_PC_dBm, BS_RB_table, BS_RB_who_used, UE_lct, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
																														idx_UE, idx_UEcnct_CoMP(idx_UE, 1), idx_UEcnct_CoMP(idx_UE, 2), UE_Throughput(idx_UE), ...
																														GBR, BW_PRB, UE_CoMP_orNOT);

					% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);
				end

				% ----------------------------------------------------------------- %
				% 總於言之呢，Throughput有過QoS，就是OK啦，如果不ok就不會進來這了   %
				% ----------------------------------------------------------------- %
				if UE_Throughput(idx_UE) >= GBR
					Dis_Connect_Reason = 0;
				end
			end

			% ---------------------------------- %
			% 計算UE Call Drop and BS Call Drop  %
			% ---------------------------------- %			
			% 主要因為 RSRP的關係離開了CoMP，那要看後續有沒有人接手
			if UE_CoMP_orNOT(idx_UE) == 0 
				if Dis_Connect_Reason == 0  % 有人接 => OK!!~

					timer_Drop_OngoingCall_NoRB(idx_UE)      = t_T310;
					timer_Drop_OngoingCall_RBNotGood(idx_UE) = t_T310;

					% 順利離開CoMP到Serving Cell，P2P_CoMP+1
					n_HO_P2P_CoMP = n_HO_P2P_CoMP + 1;

					% Success Leave CoMP 記上一筆
					Success_Leave_CoMP_times = Success_Leave_CoMP_times + 1;

				else % GG沒人接手，只能數個TTT，這時你已經切斷Cooperating的服務了，你只能以靠Serving去Non-CoMP的迴圈找機會
					if Dis_Connect_Reason == 1						
						if timer_Drop_OngoingCall_NoRB(idx_UE) <= t_T310 && timer_Drop_OngoingCall_NoRB(idx_UE) > 0
							timer_Drop_OngoingCall_NoRB(idx_UE) = timer_Drop_OngoingCall_NoRB(idx_UE) - t_d;
							if timer_Drop_OngoingCall_NoRB(idx_UE) < 1e-5	% [SPECIAL CASE]
								timer_Drop_OngoingCall_NoRB(idx_UE) = 0;		% [SPECIAL CASE]
							end 
						end

						% 被強制離開CoMP加一筆
						Failure_Leave_CoMP_Compel_times = Failure_Leave_CoMP_Compel_times + 1;

						% 還原
						Dis_Connect_Reason = 0;

					elseif Dis_Connect_Reason == 2						
						if timer_Drop_OngoingCall_RBNotGood(idx_UE) <= t_T310 && timer_Drop_OngoingCall_RBNotGood(idx_UE) > 0
							timer_Drop_OngoingCall_RBNotGood(idx_UE) = timer_Drop_OngoingCall_RBNotGood(idx_UE) - t_d;
							if timer_Drop_OngoingCall_RBNotGood(idx_UE) < 1e-5	% [SPECIAL CASE]
								timer_Drop_OngoingCall_RBNotGood(idx_UE) = 0;		% [SPECIAL CASE]
							end 
						end

						% 被強制離開CoMP加一筆
						Failure_Leave_CoMP_Compel_times = Failure_Leave_CoMP_Compel_times + 1;

						% 還原
						Dis_Connect_Reason = 0;
					end
				end

			% 繼續執行CoMP
			else
				if Dis_Connect_Reason == 0 % 很好持續進行CoMP

					% Dropping timer 重置為 1sec
					timer_Drop_CoMPCall_NoRB(idx_UE)      = t_T310;
					timer_Drop_CoMPCall_RBNotGood(idx_UE) = t_T310;

					% 還原
					Dis_Connect_Reason = 0;
				else
					if Dis_Connect_Reason == 1 % 因為找不到資源給你CoMP了，數TTT等待機會，TTT結束還沒機會我看你也是走遠了
						if timer_Drop_CoMPCall_NoRB(idx_UE) <= t_T310 && timer_Drop_CoMPCall_NoRB(idx_UE) > 0
							timer_Drop_CoMPCall_NoRB(idx_UE) = timer_Drop_CoMPCall_NoRB(idx_UE) - t_d;
							if timer_Drop_CoMPCall_NoRB(idx_UE) < 1e-5	% [SPECIAL CASE]
								timer_Drop_CoMPCall_NoRB(idx_UE) = 0;		% [SPECIAL CASE]
							end 

							% 還原
							Dis_Connect_Reason = 0;
						elseif timer_Drop_CoMPCall_NoRB(idx_UE) == 0

							% Drop記上一筆
							n_Drop_UE = n_Drop_UE + 1;	

							% Failure Leave CoMP 記上一筆
							Failure_Leave_CoMP_NoRB_times = Failure_Leave_CoMP_NoRB_times + 1;

							% 因為CoMP一定是兩個Pico來做，現在資源不夠了
							Drop_CoMPCall_NoRB_Pico  = Drop_CoMPCall_NoRB_Pico + 1;	

							% 該UE因為Cell的資源不夠被放棄
							CDR_BS(idx_UEcnct_CoMP(idx_UE, 1)) = CDR_BS(idx_UEcnct_CoMP(idx_UE, 1)) + 0.5;
							CDR_BS(idx_UEcnct_CoMP(idx_UE, 2)) = CDR_BS(idx_UEcnct_CoMP(idx_UE, 2)) + 0.5;

							% 等不到資源，自行了斷，把RB還給兩邊
							for RB_index = 1:1:Pico_part
								if BS_RB_table(idx_UEcnct_CoMP(idx_UE, 1), RB_index) == 1 && BS_RB_table(idx_UEcnct_CoMP(idx_UE, 2), RB_index) == 1  && UE_RB_used(idx_UE, RB_index) == 1
									BS_RB_table(idx_UEcnct_CoMP(idx_UE, 1), RB_index)    = 0;
									BS_RB_who_used(idx_UEcnct_CoMP(idx_UE, 1), RB_index) = 0;
									BS_RB_table(idx_UEcnct_CoMP(idx_UE, 2), RB_index)    = 0;
									BS_RB_who_used(idx_UEcnct_CoMP(idx_UE, 2), RB_index) = 0;			
									UE_RB_used(idx_UE, RB_index)                         = 0;
								end
							end
							idx_UEcnct_CoMP(idx_UE, 1) = 0; % 結束連線
							idx_UEcnct_CoMP(idx_UE, 2) = 0; % 結束連線
							UE_CoMP_orNOT(idx_UE)      = 0; % 結束CoMP，重回New Call
							UE_Throughput(idx_UE)      = 0; % UE的throughput歸零


							% Dropping timer 重置為 1sec
							timer_Drop_CoMPCall_NoRB(idx_UE)      = t_T310;
							timer_Drop_CoMPCall_RBNotGood(idx_UE) = t_T310;

							% 還原
							Dis_Connect_Reason = 0;
						end			

					elseif Dis_Connect_Reason == 2 % UE發現兩邊Cell來做CoMP的質量都不夠，數一下TTT等機會，沒有也是要放棄
						if timer_Drop_CoMPCall_RBNotGood(idx_UE) <= t_T310 && timer_Drop_CoMPCall_RBNotGood(idx_UE) > 0
							timer_Drop_CoMPCall_RBNotGood(idx_UE) = timer_Drop_CoMPCall_RBNotGood(idx_UE) - t_d;
							if timer_Drop_CoMPCall_RBNotGood(idx_UE) < 1e-5	% [SPECIAL CASE]
								timer_Drop_CoMPCall_RBNotGood(idx_UE) = 0;		% [SPECIAL CASE]
							end 

							% 還原
							Dis_Connect_Reason = 0;
						elseif timer_Drop_CoMPCall_RBNotGood(idx_UE) == 0

							% Drop記上一筆
							n_Drop_UE = n_Drop_UE + 1;

							% Failure Leave CoMP 記上一筆
							Failure_Leave_CoMP_RBNotGood_times = Failure_Leave_CoMP_RBNotGood_times + 1;

							% 因為CoMP一定是兩個Pico來做，現在資源不夠好
							Drop_CoMPCall_RBNotGood_Pico = Drop_CoMPCall_RBNotGood_Pico + 1;

							% 該UE因為Cell的資源不夠被放棄
							CDR_BS(idx_UEcnct_CoMP(idx_UE, 1)) = CDR_BS(idx_UEcnct_CoMP(idx_UE, 1)) + 0.5;
							CDR_BS(idx_UEcnct_CoMP(idx_UE, 2)) = CDR_BS(idx_UEcnct_CoMP(idx_UE, 2)) + 0.5;

							% 等不到資源，自行了斷，把RB還給兩邊
							for RB_index = 1:1:Pico_part
								if BS_RB_table(idx_UEcnct_CoMP(idx_UE, 1), RB_index) == 1 && BS_RB_table(idx_UEcnct_CoMP(idx_UE, 2), RB_index) == 1  && UE_RB_used(idx_UE, RB_index) == 1
									BS_RB_table(idx_UEcnct_CoMP(idx_UE, 1), RB_index)    = 0;
									BS_RB_who_used(idx_UEcnct_CoMP(idx_UE, 1), RB_index) = 0;
									BS_RB_table(idx_UEcnct_CoMP(idx_UE, 2), RB_index)    = 0;
									BS_RB_who_used(idx_UEcnct_CoMP(idx_UE, 2), RB_index) = 0;
									UE_RB_used(idx_UE, RB_index)                         = 0;
								end
							end
							idx_UEcnct_CoMP(idx_UE, 1) = 0; % 結束連線
							idx_UEcnct_CoMP(idx_UE, 2) = 0; % 結束連線
							UE_CoMP_orNOT(idx_UE)      = 0; % 結束CoMP，重回New Call
							UE_Throughput(idx_UE)      = 0; % UE的throughput歸零


							% Dropping timer 重置為 1sec
							timer_Drop_CoMPCall_NoRB(idx_UE)      = t_T310;
							timer_Drop_CoMPCall_RBNotGood(idx_UE) = t_T310;

							% 還原
							Dis_Connect_Reason = 0;
						end						
					end
				end				
			end

			% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);
		end

		% ========================================================================================================================== %
		% 以下等等用來算Cell的CBR                                                                                                    % 
		% Cell角度的CBR: 若UE沒有連上預期的連線目標，反而到最後UE變得沒有Serving   Cell，這時這個Block Call就會算在預期的連線Cell上  %
		% Cell角度的CDR: 若UE本身有Serving Cell，但到最後UE離開Serving  Cell，這筆Call Drop就算在Serving Cell上                      %
		% ========================================================================================================================== %
		if temp_CoMP_state == 0
			if UE_CoMP_orNOT(idx_UE) == 0

				% 原本沒做CoMP，後來也沒有做CoMP				
				if idx_UEprey_TST(idx_UE) ~= 0     % 該UE是有預期的連線目標，正常都會有
					if idx_UEcnct_TST(idx_UE) == 0 % UE有預期目標，但最後卻沒有Serving  Cell
						n_DeadUE_BS(idx_UEprey_TST(idx_UE)) = n_DeadUE_BS(idx_UEprey_TST(idx_UE)) + 1;

					else % idx_UEcnct_TST(idx_UE) ~= 0
						n_LiveUE_BS(idx_UEcnct_TST(idx_UE)) = n_LiveUE_BS(idx_UEcnct_TST(idx_UE)) + 1;
					end
				else
					fprintf('BS_CBR calculation BUG\n');
				end	
			else
				% 原本沒做CoMP，後來有做CoMP	
				n_LiveUE_BS(idx_UEcnct_CoMP(idx_UE, 1)) = n_LiveUE_BS(idx_UEcnct_CoMP(idx_UE, 1)) + 0.5;
				n_LiveUE_BS(idx_UEcnct_CoMP(idx_UE, 2)) = n_LiveUE_BS(idx_UEcnct_CoMP(idx_UE, 2)) + 0.5;
			end
		else
			if UE_CoMP_orNOT(idx_UE) == 0
				if idx_UEcnct_TST(idx_UE) == 0
					n_DeadUE_BS(temp_Serving) = n_DeadUE_BS(temp_Serving) + 0.5;
					n_DeadUE_BS(temp_Cooperating) = n_DeadUE_BS(temp_Cooperating) + 0.5;
				else
					n_LiveUE_BS(temp_Serving) = n_LiveUE_BS(temp_Serving) + 1;
				end

			else
				n_LiveUE_BS(temp_Serving)     = n_LiveUE_BS(temp_Serving) + 0.5;
				n_LiveUE_BS(temp_Cooperating) = n_LiveUE_BS(temp_Cooperating) + 0.5;
			end	
		end

		% ============================================================================================ %
		%                    ________          /                     |                      |          %
		%   |          |    |               ___|___      |         __|__                ____|____      %
		%   |          |    |                  |     ____|__         |      ____            |          %
		%   |          |    |                __|__       |  |     ___|___  |    |        /  |  /       %
		%   |          |    |________       |__|__|      |  |        |     |____|       / \ | / \      %
		%   |          |    |               |__|__|     /   |        |___  |               /|\         %
		%   |          |    |                __|__     /  \ |     /  |     |_____         / | \        %
		%    __________     |________      ____|____  /    \|    /\__|_____________    __/  |  \__     %
		%                                                                                              %
		% ============================================================================================ %
		[lct_new, v_new, t_oneStep] = UMM_RWPmodel('V', idx_t, t_start, UE_lct(idx_UE,:), ...
													UE_timer_RWP1step(idx_UE,1), t_d, rectEdge, UE_v(idx_UE,:), ...
													seedSpeedMDS(idx_UE,idx_SEED(idx_UE)), ...
													seedAngleDEG(idx_UE,idx_SEED(idx_UE)), ... 
													seedEachStep(idx_UE,idx_SEED(idx_UE)));
		UE_lct(idx_UE, :) = lct_new;
		UE_v(idx_UE, :)   = v_new;
		UE_timer_RWP1step(idx_UE,1) = t_oneStep - t_d;	% Damn Bug 2016.10.18

		if UE_timer_RWP1step(idx_UE,1) < t_d
			UE_timer_RWP1step(idx_UE,1) = 0;
			% Seeds Checking
			idx_SEED(idx_UE) = idx_SEED(idx_UE) + 1;
			if (idx_SEED(idx_UE) == 10000)
				idx_SEED(idx_UE) = 1;	% Rerun Seeds
				seedLack = 1;			% For checking whether 10000 seeds is insufficient in 40000 sec. 2016.11.22
			end
		end

    end 
    % 結束Loop 2(UE的Loop)

    % ======================== %
    % 算Macro跟Pico的服務人數  %
    % ======================== %
    for idx_UE = 1:1:n_UE  
		Macro_Serving_Num_change(round(idx_t/t_d), 1)        = length(find(0 < idx_UEcnct_TST & idx_UEcnct_TST <= n_MC));
		Pico_NonCoMP_Serving_Num_change(round(idx_t/t_d), 1) = length(find(idx_UEcnct_TST > n_MC));
		Pico_CoMP_Serving_Num_change(round(idx_t/t_d), 1)    = length(nonzeros(UE_CoMP_orNOT)); 
    end

    % ============================== %
    % 算BS所使用的Resource Block數量 %
    % ============================== %
    for idx_BS = 1:1:n_BS
    	if idx_BS <= n_MC
    		BS_RB_consumption(idx_BS) = BS_RB_consumption(idx_BS) + length(nonzeros(BS_RB_table(idx_BS, :)));
    	else
    		BS_RB_consumption(idx_BS) = BS_RB_consumption(idx_BS) + length(nonzeros(BS_RB_table(idx_BS, 1:Pico_part)));
    	end    	
    end

	% ======================================== %
	% 算UE的Call Block Rate and Call Drop Rate %
	% ======================================== %
	% UE Call Block Rate
	UE_CBR = UE_CBR + (n_Block_UE);

	% UE Call Drop Rate 
	UE_CDR  = UE_CDR + (n_Drop_UE);

	% UE平均存活人數	
	UE_survive = UE_survive + (n_UE - n_Block_UE - n_Drop_UE);
	
	% 重置
	n_Block_UE  = 0;	
	n_Drop_UE   = 0;

	% ======================================== %
    % 算BS的Call Block Rate and Call Drop Rate %
	% ======================================== %	
	
	for idx_BS = 1:n_BS
		% BS Call Block Rate
		if n_DeadUE_BS(idx_BS) == 0 && n_LiveUE_BS(idx_BS) == 0    % 如果沒有人把該BS 當目標，該BS 的CBR = 0
			CBR_BS_TST(idx_BS) = 0;
		else
			CBR_BS_TST(idx_BS) = n_DeadUE_BS(idx_BS) / (n_DeadUE_BS(idx_BS) + n_LiveUE_BS(idx_BS));
		end

		% BS Call Drop Rate
		if isempty(find(idx_UEcnct_TST == idx_BS)) == 1 && CDR_BS(idx_BS) == 0
			CDR_BS_TST(idx_BS) = 0;
		else
			CDR_BS_TST(idx_BS) = CDR_BS(idx_BS) / (CDR_BS(idx_BS) + length(find(idx_UEcnct_TST == idx_BS)) + length(find(idx_UEcnct_CoMP == idx_BS))*(1/2));
		end
	end

	% 重置

	n_DeadUE_BS(1,:) = 0;
	n_LiveUE_BS(1,:) = 0;
	CDR_BS(1,:)      = 0;
	
	% ----------- %
	% 更新Loading %
	% ----------- %
	[Load_TST] = Update_Loading(n_BS, n_MC, BS_RB_table, n_ttoffered, Pico_part);	

	% ================================================ % % ====================================== %
	%          -          -------        --            % %   --------    --------      -------    %
	%          |          |      )      /  \           % %   |          /        \    /           %
	%          |          |------      /----\          % %   |------|  |        \ |  |            %
	%          |          |           /      \         % %   |          \        X    \           %
	%          -------    -          -        -        % %   -           -------- \    -------    %
	% ================================================ % % ====================================== %	
	% Loop 4: 基地台開始做Fuzzy Q (需要細胞的CIO, Loading, CBR, CDR)
	if (idx_t == t_start || rem(idx_t, FQ_BS_LI_TST) == 0)
		for idx_BS = 1:n_BS			
			% Fuzzifier
			DoM_CIO_TSTc(idx_BS,:)      = FQc1_Fuzzifier(CIO_TST(idx_BS), 'C');  % CIO的degree of membership
			DoM_Load_TSTc(idx_BS,:)     = FQc1_Fuzzifier(Load_TST(idx_BS),'L');  % Loading的degree of membership
			DoT_Rule_New_TSTc(idx_BS,:) = FQc2_DegreeOfTruth(DoM_CIO_TSTc(idx_BS,:), DoM_Load_TSTc(idx_BS,:),'D');  %算degree of truth的方法D (相乘)

			if (idx_t ~= t_start)
				% 算Q Bonus
				Q_reward_TSTc(idx_BS) = FQc6_Reward(Load_TST(idx_BS), CBR_BS_TST(idx_BS), CDR_BS_TST(idx_BS),'C');
				V_fx_new_TSTc(idx_BS) = FQc5_Vfunction(DoT_Rule_New_TSTc(idx_BS,:), Q_Table_TSTc(:,:,idx_BS));
				Q_bonus_TSTc(idx_BS)  = FQc7_Qbonus(Q_reward_TSTc(idx_BS), FQ_BS_DF_TST, V_fx_new_TSTc(idx_BS), ...
																							Q_fx_old_TSTc(idx_BS));
				% Q Update
				Q_Table_TSTc(:,:,idx_BS) = FQc8_Qupdate(Q_Table_TSTc(:,:,idx_BS), idx_subAct_choosed_old_TSTc(idx_BS,:), ...
															FQ_BS_LR_TST, Q_bonus_TSTc(idx_BS), DoT_Rule_Old_TSTc(idx_BS,:));
			end
			% Global Action
			[GlobalAct_TSTc(idx_BS),idx_subAct_choosed_new_TSTc(idx_BS,:)] = FQc3_GlobalAction(DoT_Rule_New_TSTc(idx_BS,:), ...
																									Q_Table_TSTc(:,:,idx_BS));
			%這邊GlobalAct是當作變化量，要在加上前一次的CIO，當作下一次真正使用的CIO    (目的是為了不讓CIO變化太大) 
			if     (CIO_TST(idx_BS) + GlobalAct_TSTc(idx_BS) < -5)
				CIO_TST(idx_BS) = -5;
			elseif (CIO_TST(idx_BS) + GlobalAct_TSTc(idx_BS) > 5)
				CIO_TST(idx_BS) = 5;
			else
				CIO_TST(idx_BS) = CIO_TST(idx_BS) + GlobalAct_TSTc(idx_BS);
			end

			% 計算Q-function 
			Q_fx_new_TSTc(idx_BS) = FQc4_Qfunction(DoT_Rule_New_TSTc(idx_BS,:), Q_Table_TSTc(:,:,idx_BS), ...
																	idx_subAct_choosed_new_TSTc(idx_BS,:));			
		end	
		% Recording for the different iteration of 'Q-function'
		Q_fx_old_TSTc               = Q_fx_new_TSTc;
		idx_subAct_choosed_old_TSTc = idx_subAct_choosed_new_TSTc;
		DoT_Rule_Old_TSTc           = DoT_Rule_New_TSTc;
	end
	% 結束 Loop 4

end

toc
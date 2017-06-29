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
rectEdge = 4763;															% 系統?��???[meter]
load('MC_lct_4sq');															% 大細?��?位置�?��來�??�陣??  Macro_location		
load('PC_lct_4sq_n250_MP1000_PP40');                                         % 小細?��?位置�?���?，矩??��: Pico_location
BS_lct = [Macro_location ; Pico_location];								    % ?�部細�??��?�?

P_MC_dBm    =  46;															% 大細??total TX power (?�部?�帶?�起來�?power) [dBm]
P_PC_dBm    =  30;															% 小細??total TX power (?�部?�帶?�起來�?power) [dBm]
P_minRsrpRQ = -100; % [dBm]                          		% [[[ADJ]]]     % Minimum Required power to provide services 
																			% sufficiently for UE accessing to BS [dBm]
																			% Requirement for accessing a particular cell
MACROCELL_RADIUS = (10^((P_MC_dBm-P_minRsrpRQ-128.1)/37.6))*1e+3;
PICOCELL_RADIUS  = (10^((P_PC_dBm-P_minRsrpRQ-140.7)/36.7))*1e+3;

n_MC = length(Macro_location);			                                    % 大細?��??�目
n_PC = length(Pico_location);	                                            % 小細?��??�目
n_BS = n_MC + n_PC;															% ?�部細�??�數??

% -----------------------------------------------------
% -------------/* Resource Parameter */----------------
% -----------------------------------------------------
sys_BW      = 5   * 1e+6;									% [[[ADJ]]]		% 系統總頻�?5MHz
BW_PRB      = 180 * 1e+3;													% LTE 每�?Resource Block?�頻寬為 180kHz
n_ttoffered = sys_BW/(BW_PRB/9*10);											% [[[ADJ]]]     % #max cnct per BS i.e., PRB
                                                                            % 系統 RB ?�總?��?*9/10??��?��?RB?�CP算�?來除
																			% B E N: Max #PRB under BW = 10 Mhz per slot(0.5ms)
Pico_part   = n_ttoffered;                                                  % Pico Cell?�以使用?�部??

GBR         = 256 * 1024;													% Guaranteed Bit Rate is 256 kbit/sec
% -----------------------------------------------------
% -----------------/* Channel */-----------------------
% -----------------------------------------------------
Gamma_MC            = 3.76;                                                 % Pathloss Exponent (MC)            
Gamma_PC            = 3.67;                                                 % Pathloss Exponent (PC)  
P_N_dBmHz           = -174; % [dBm/Hz]										% 高斯?��???Power Density [dBm/Hz]
LTE_NoiseFloor_dBm  = P_N_dBmHz + 10*log10(BW_PRB);							% Noise Floor approximate -121.45 [dBm/RB]
LTE_NoiseFloor_watt = 10^((LTE_NoiseFloor_dBm - 30)/10);					% Noise Floor approximate 7.1614 * 1e-16 [watt/RB]



% -----------------------------------------------------
% ------------/* User 位置?�數??*/--------------------
% -----------------------------------------------------
load('UE_lct_n400_random');
UE_lct = UE_location;                                                       % �?E?��?置出�?(注�?檔�?)
n_UE = length(UE_lct);			                                            % ?�部UE?�數??

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
% -----------/* ?�系統Model?��??��? */-----------------
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
% ---------/* 下面?�細?��?UE?��?始�? */----------------
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
% ---------/* 下面?�TST BDRY?��?始�?*/-----------------
% -----------------------------------------------------
% BS?��?
n_RBoffer_TST   = zeros(1, n_BS);									        % The number of RB a BS offer to UEs inside it
Load_TST        = zeros(1, n_BS);
CIO_TST         = zeros(1, n_BS);

n_HO_BS_TST     = zeros(1, n_BS);	% Only for target cell			        % KPI: Handover Number of BS

% UE?��?
crntRSRP_TST    = zeros(n_UE, 1);		% [dBm]

idx_UEcnct_TST  = zeros(1, n_UE);                                           % UE實�?????�基?�台
idx_UEprey_TST  = zeros(1, n_UE);		                                    % UE?��?????�基?�台


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

% DropReason1_M2M___RB = zeros(1,n_UE);	% Drop Reason = 1                   % ?�為資�?不�??�中??(Drop)???
% DropReason2_M2P___RB = zeros(1,n_UE);	% Drop Reason = 1                     M2M(Macro to Macro)
% DropReason3_P2M___RB = zeros(1,n_UE);	% Drop Reason = 1                     M2P(Macro to Pico)
% DropReason4_P2P___RB = zeros(1,n_UE);	% Drop Reason = 1

% DropReason5_M2M__ToS = zeros(1,n_UE);	% Drop Reason = 2                   % ?�為ToS太短，�??�ToS Threshold，�?以�?Handover
% DropReason6_M2P__ToS = zeros(1,n_UE);	% Drop Reason = 2
% DropReason7_P2M__ToS = zeros(1,n_UE);	% Drop Reason = 2
% DropReason8_P2P__ToS = zeros(1,n_UE);	% Drop Reason = 2

% DropReason9_MMM_Conn = zeros(1,n_UE);	% Drop Reason = 3                   % A3 event 沒�??��?，�??�為CIO ?��?係�??�dropping
% DropReasonX_PPP_Conn = zeros(1,n_UE);	% Drop Reason = 3                     MMM and PPP�?��?��?serving對象?�MC or PC

% DropReasonY_M2M__TTT = zeros(1,n_UE);	% Drop Reason = 4                   % ?�TTT以內?��??�發?�dropping
% DropReasonY_M2P__TTT = zeros(1,n_UE);	% Drop Reason = 4
% DropReasonY_P2M__TTT = zeros(1,n_UE);	% Drop Reason = 4
% DropReasonY_P2P__TTT = zeros(1,n_UE);	% Drop Reason = 4
% % ?�師?�解�?Reason1, 3, 4?�是?�為資�?不�??��?�?(待確�?

% UE TST (LPA?�部??
LPA_P1t = zeros(1,n_UE);	% TrgtCell
LPA_P2t = zeros(1,n_UE);
LPA_P3t = zeros(1,n_UE);
LPA_Ps  = 10^((P_minRsrpRQ-30)/10);	% [Watt]
LPA_t1  = zeros(1,n_UE);
LPA_t2  = zeros(1,n_UE);
LPA_t3  = zeros(1,n_UE);
LPA_idx_pkt      = zeros(1,n_UE);
LPA_pred_trgtToS = zeros(1,n_UE);


GPSinTST_trgtToS = zeros(1,n_UE); % GPS?�出來�? TOS

% -----------------------------------------------------
% ---------/* Fuzzy Q Learning ?��?始�?*/--------------
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
% ---------/* 計�? Performance ?��?始�? */-------------
% -----------------------------------------------------
% 算BS??
PRFM_TST_BS_CBR   = zeros(1, n_Measured);
PRFM_TST_BS_CDR   = zeros(1, n_Measured);
PRFM_TST_BS_QoS   = zeros(1, n_Measured);

% 算UE??
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
% ---------------/* ?��??�西 ?��???*/-----------------
% -----------------------------------------------------
CRE_Macro       = zeros(1, n_MC) + 0;                      % Macro ??CRE [dBm]
CRE_Pico        = zeros(1, n_PC) + 0;                      % Pico  ??CRE [dBm]
CRE             = [CRE_Macro CRE_Pico];                    % Cell Range Expension，主要給小細?�用?��?讓�?細�??�更多人?��?

BS_RB_table     = zeros(n_MC + n_PC, n_ttoffered);         % ?�部Cell?�RB使用???    0:?�用 1:已用
BS_RB_who_used  = zeros(n_MC + n_PC, n_ttoffered);         % Cell?�RB?�是?��?UE?�用
UE_RB_used      = zeros(n_UE, n_ttoffered);                % UE使用了哪些RB          0:?�用 1:已用
UE_Throughput   = zeros(1, n_UE);                          % 顯示每�?UE?�Throughput

UE_surviving    = 0; 

UE_CoMP_orNOT   = zeros(1, n_UE);                          % ?�斷UE?��??�在?�CoMP  0:沒�? 1:�?��?�CoMP                    
idx_UEcnct_CoMP = zeros(n_UE, 2);                          % ?�UE?�給?�兩?�Cell?�CoMP : Colunm1 ??Serving Cell, Colunm2 ??Cooperating Cell
CoMP_Threshold  = 4;                                       % ?��?CoMP?�RSRP Threshold，�?定�?大於 3dB  (dBm)
CoMP_change_TTT = zeros(1, n_UE) + t_TTT;                  % UE?�執行CoMP?��?交�?Serving?�Cooperating角色?�TTT


% UE Block定義: ?�本UE沒�?Serving Cell, 該UE?��??��?上�?，卻被�?�?
% UE Drop 定義: UE?�本?��?Serving Cell?��??? 但�?種種?��?他被?��?

n_Block_UE                 = 0;				               % 被Blcok?�人??

n_Block_NewCall_NoRB_Macro = 0;                            % NewCall ?�為?�現Cell(Max RSRP)沒�??�以?��?RB�? ??��?��????: Block 
n_Block_NewCall_NoRB_Pico  = 0;

n_Block_NewCall_RBNotGood_Macro  = 0;                      % NewCall ?�為?�到Cell(Max RSRP)?�以?��?RB之頻譜�??�都=0  , ??��?��????: Block
n_Block_NewCall_RBNotGood_Pico   = 0;

n_Block_Waiting_BlockTimer       = 0;                      % ?��?Block timer，被Block??



UE_CBR                     = 0;                            % Call Block Rate: ?�部UE跑�?後�?  N(被Block?�人?? / n_UE

n_Drop_UE                   = 0;                           % 被Drop ?�人??

Drop_OngoingCall_NoRB_Macro = 0;                           % OngoingCall ?�為?�現Serving Cell 沒�??�以?��?RB了�? 並�??��?1秒�???��被放棄支?��?�?  Drop
Drop_OngoingCall_NoRB_Pico  = 0;

Drop_OngoingCall_RBNotGood_Macro = 0;                      % OngoingCall ?�為?�現Serving Cell ?�以?��?RB之頻譜�??�都=0 ，並且�?�?秒�???��?��????:  Drop
Drop_OngoingCall_RBNotGood_Pico  = 0;

Drop_CoMPCall_NoRB_Pico          = 0;                      % CoMPCall?�為?�現Serving Cell?�Cooperating Cell沒�??�以?��?RB了�?並�??��?1秒�? ??��被放棄支?��?�?  Drop

Drop_CoMPCall_RBNotGood_Pico     = 0;                      % CoMPCall?�為?�現Serving Cell?�Cooperating Cell?�以?��?RB之頻譜�??�都=0 ，並且�?�?秒�???��?��????:  Drop


UE_CDR                     = 0;                            % Call Drop Rate: ?�部UE跑�?後�? N(被Drop?�人?? / n_UE
Average_UE_CDR             = 0;

CDR_BS                     = zeros(1,n_BS);                % 每�?Base Station?�UE給Drop?�次??
CBR_BS                     = zeros(1,n_BS);                % 每�?Base Station?�UE給Block?�次??

n_DeadUE_BS                = zeros(1, n_BS);		       % ?��?BS?�Call Block Rate?��?
n_LiveUE_BS                = zeros(1, n_BS);		       % ?��?BS?�Call Block Rate?��?    

CBR_BS_TST 		           = zeros(1, n_BS);			   % KPI: Call Block Rate  
CDR_BS_TST 		           = zeros(1, n_BS);			   % KPI: Outage Probability 2016.11.15 -> Call Drop Rate 2017.01.04

BS_RB_consumption          = zeros(1, n_BS);               % 每�?Base Station?��?段�??��?使用?�RB??

BS_last_time_serving       = zeros(1, n_BS);               % 上�?state?��??�人
	
UE_survive                 = 0;                            % UE平�?存活人數

Success_Enter_CoMP_times = 0;                              % ?��??��??�CoMP?�次??
Success_Leave_CoMP_times = 0;                              % ?��??�離?�CoMP，�??�被?�斷?�次??

Failure_Leave_CoMP_Compel_times    = 0;
Failure_Leave_CoMP_NoRB_times      = 0;                    % ?��?CoMP後�?人�?辦�??��?
Failure_Leave_CoMP_RBNotGood_times = 0;


Handover_Failure_times                    = 0;             % Handover失�??�次??
Handover_to_Macro_Failure_NoRB_times      = 0;             % ?�handover?�Macro但是被�?絕�?次數
Handover_to_Pico_Failure_NoRB_times       = 0;             % ?�handover?�Pico但是被�?絕�?次數

Handover_to_Macro_Failure_RBNotGood_times = 0;             % ?�handover?�Macro但是被�?絕�?次數
Handover_to_Pico_Failure_RBNotGood_times  = 0;             % ?�handover?�Pico但是被�?絕�?次數


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
	if (rem(idx_t,t_simu/ttSimuT) < 1e-3)                                       % 顯示?��??��?，�??��??�幹?��? 不�?不影??
		fprintf(' %.3f sec\n', idx_t)
	end

	AMP_Noise  = LTE_NoiseFloor_watt * abs(randn(1));                            % 每�??��?點�??��????��??��?�?�� [watt/RB]

	% CIO_TST(1:1:n_MC) = -5;

	UE_surviving = 0;
	UE_surviving = length(nonzeros(UE_CoMP_orNOT)) + length(nonzeros(idx_UEcnct_TST));

	% Loop 2: User	
	% 寫收訊�??��?A3 event，統計�??�Performance，�?係到RB ?��??�己�?( 細�?loading?��?�? UE's SINR計�? )
	for idx_UE = 1:n_UE
		Dis_Connect_Reason  = 0;
		Dis_Handover_Reason = 0;

		if idx_t >= 2.8
			a = 1;
		end
		if idx_UE == 64
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
			dist_MC(mc)    = norm(UE_lct(idx_UE,:) - Macro_location(mc,:)); % 該UE距離?�部MC多�? [meter]
			RsrpMC_dBm(mc) = P_MC_dBm - PLmodel_3GPP(dist_MC(mc), 'M');		% 該UE從�?些MC?�到?�RSRP [dBm]
		end
		for pc = 1:n_PC
			dist_PC(pc)    = norm(UE_lct(idx_UE,:) - Pico_location(pc,:));  % 該UE距離?�部PC多�? [meter]
			RsrpPC_dBm(pc) = P_PC_dBm - PLmodel_3GPP(dist_PC(pc), 'P');	    % 該UE從�?些PC?�到?�RSRP [dBm]
		end
		RsrpBS_dBm  = [RsrpMC_dBm RsrpPC_dBm];
		RsrpBS_dB   = RsrpBS_dBm - 30;								          
		RsrpBS_Watt = 10.^(RsrpBS_dB/10);                                   % ?�部?��??�特

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
		% UE?�Non-CoMP下走?�FlowChart
		if UE_CoMP_orNOT(idx_UE) == 0  % UE沒�??�CoMP
			temp_CoMP_state = 0;

			% ------------------------------------------------------------------------------- %
			% ?�出?��??��??�地?�RSRP對該UE??�� ，�?且是多�?dB (對�??�學?�主程�???11-313�?)  %
			% ------------------------------------------------------------------------------- %
			temp_rsrp = RsrpBS_dBm + CIO_TST;
			% target對象不�??�到?�己
			if idx_UEcnct_TST(idx_UE) ~= 0
				temp_rsrp(idx_UEcnct_TST(idx_UE)) = min(temp_rsrp); 
			end
			% ?�RSRP+CIO??��?�出�?			
			[~, idx_trgt] = max(temp_rsrp);

			% ------------------------------ %
			% ?�目?��?該�??��??��?人�??��?   %
			% ------------------------------ %
			% ?��?專�??��?Call  Block Rate?��?�?
			if idx_UEcnct_TST(idx_UE) == 0						 
				idx_UEprey_TST(idx_UE) = idx_trgt;			 
			else                             				     
				idx_UEprey_TST(idx_UE) = idx_UEcnct_TST(idx_UE);                      
			end

			% ----------------- %
			% ?��?沒�?人�??��?  %
			% ----------------- %
			if (idx_UEcnct_TST(idx_UE) == 0) % 沒人?��?，�??�能?�initial  or 被踢??

				% --------------------------------------------------------------------- %
				% ?�user被踢?��?，�??��?�?��?��??�能?�新?�RB，�?裡就UE?�在等�?段�???   %
				% ?�user等�?了�?後�?就�??��??�RB                                        %
				% --------------------------------------------------------------------- %
				if (timer_Arrive(idx_UE) ~= 0) % Waiting Users
					timer_Arrive(idx_UE) = timer_Arrive(idx_UE) - t_d;	% Countdown
					if (timer_Arrive(idx_UE) < t_d)
						timer_Arrive(idx_UE) = 0;
					end
					Dis_Connect_Reason = 3; % ?�在等�?線�?也�??�Call  Block Rate?��?
 
				else  %(timer_Arrive(idx_UE) == 0): Arriving Users	
					% ---------------- %
					% ?�Resource Block %
					% ---------------- %
					[BS_RB_table, BS_RB_who_used, UE_RB_used, idx_UEcnct_TST(idx_UE), UE_Throughput(idx_UE), Dis_Connect_Reason] = NewCall_take_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
									                                                                                                               idx_UE, idx_trgt, GBR, BW_PRB);
									                                                                                                               
					% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);

					% -------------------------------------------------------------------- %
					% 不�?UE?�死?�活，都?��?給�?�??等�??��?，�?次她被放棄�?就�??��???    %
					% -------------------------------------------------------------------- %
					while timer_Arrive(idx_UE) == 0	
						timer_Arrive(idx_UE) = poissrnd(1);	% 2017.01.05 Not to be ZERO please.  % 不�???0
					end					

					% ---------------------------------------------------- %
					% 計�?Ping-Pong Effect?�否?�發?��?跟Performance ?��?�?%
					% ?�兩?�KPI: (1) 1秒內?��?碰�?   (2) 5秒內?��?碰�?     %
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
				% 計�?UE Call Block %
				% ----------------- %
				if Dis_Connect_Reason == 0


					% ?��?
					Dis_Connect_Reason = 0;

				else
					if Dis_Connect_Reason == 1
						n_Block_UE = n_Block_UE + 1;

						% 該UE?�為Cell?��?源�?夠被?��?
						if idx_trgt <= n_MC
							n_Block_NewCall_NoRB_Macro = n_Block_NewCall_NoRB_Macro + 1;							
						else
							n_Block_NewCall_NoRB_Pico = n_Block_NewCall_NoRB_Pico + 1;
						end

						% ?��?
						Dis_Connect_Reason = 0;

					elseif Dis_Connect_Reason == 2
						n_Block_UE = n_Block_UE + 1;
						
						% 該UE?�為?�到?�RB之頻譜�??�都太�?�?  ??��被�?�?
						if idx_trgt <= n_MC
							n_Block_NewCall_RBNotGood_Macro = n_Block_NewCall_RBNotGood_Macro + 1;							
						else
							n_Block_NewCall_RBNotGood_Pico = n_Block_NewCall_RBNotGood_Pico + 1;
						end

						% ?��?
						Dis_Connect_Reason = 0;
					elseif Dis_Connect_Reason == 3
						n_Block_UE = n_Block_UE + 1;

						% ?�為UE?�在�?，�?以�?算被Block
						n_Block_Waiting_BlockTimer = n_Block_Waiting_BlockTimer + 1;

						% ?��?
						Dis_Connect_Reason = 0;
					end
				end
			else %(idx_UEcnct_TST(idx_UE) ~= 0): ?�人�?��?��???

				% ------------------------------------------------- %
				% ?�新Throuhgput and ?��?Throughput 沒貢?��?RB?��?  %
				% ------------------------------------------------- %
				[BS_RB_table, BS_RB_who_used, UE_RB_used, UE_Throughput(idx_UE)] = Non_CoMP_Update_Throughput_and_Delete_Useless_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
														                                                                            idx_UE, idx_UEcnct_TST(idx_UE), BW_PRB);

				% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);

				% -------------------- %
				% ?�A3 Event?��??��?�?%
				% -------------------- %						
				if (RsrpBS_dBm(idx_trgt) + CIO_TST(idx_trgt) > RsrpBS_dBm(idx_UEcnct_TST(idx_UE)) + CIO_TST(idx_UEcnct_TST(idx_UE)) + HHM)

					% A3 Event�?��trigger，TTT就�?始數
					if (timer_TTT_TST(idx_UE) <= t_TTT && timer_TTT_TST(idx_UE) > 0)

						% ?��?減TTT
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

						% Willie?��?算�?
						% if GPSinTST_trgtToS(idx_UE) > TST_HD
							% ?��?A3 Event ---> ?��?TTT ---> Time of Stay Threshold大於TST_HD ---> ?��?來檢?��?不�?資�?

						% Handover Call來拿RB
						temp_idx_UEcnct_TST = idx_UEcnct_TST(idx_UE); % ?��??��?來�??��??�裡handover?�哪�?
						[BS_RB_table, BS_RB_who_used, UE_RB_used, idx_UEcnct_TST(idx_UE), UE_Throughput(idx_UE), Dis_Handover_Reason] = Non_CoMP_HandoverCall_take_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
										                                                                                                                              idx_UE, idx_UEcnct_TST(idx_UE), idx_trgt, UE_Throughput(idx_UE), GBR, BW_PRB);
						% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);

						if idx_UEcnct_TST(idx_UE) == idx_trgt
							% !!!!!!!!!!?��?Handvoer?�Target Cell!!!!!!!!!!
							% ---------------- %
							% Handover次數計�? %
							% ---------------- %
							n_HO_UE_TST(idx_UE)   = n_HO_UE_TST(idx_UE)   + 1;
							n_HO_BS_TST(idx_trgt) = n_HO_BS_TST(idx_trgt) + 1;	% Only for target cell

							% ----------------------------------- %
							% ?�Handover?��?�?��Cell?�到�?��Cell  %
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
							% 記�?該UE?�該?��?點是?�執行�?Handover  %
							% ------------------------------------- %
							logical_HO(idx_UE) = 1;	% Handover success.
							Dis_Connect_Reason = 0; % ?��??�Hnadover?��?，Dis_Connect_Reason�??= 0 

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

							% Handover失�?了�??�是Handover誰�?失�?，阿?��?麼失?��?計�?下�?
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
							% 記�?該UE?�該?��?點是?�執行�?Handover  %
							% ------------------------------------- %
							logical_HO(idx_UE) = 0;	% Handover fail
						end
						% end
					end		
				else
					% 沒�?Handover !!!
					logical_HO(idx_UE) = 0;

					% TTT Reset
					timer_TTT_TST(idx_UE) = t_TTT;
				end
				% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);

                % ----------------------------------------------------------- %
				% 如�?(1)沒�??�A3 Event               __\  就�?走以下�?流�?   %
				%     (2)?��?但是Target Cell沒�?資�?    /	                  %
				% ----------------------------------------------------------- %			
				if logical_HO(idx_UE) == 0

					% ------------------------------------------------------ %
					% 如�?Throughput < GBR，�?來�??��?，�?裡注?��?定�??��?   %
					% ------------------------------------------------------ %
					if UE_Throughput(idx_UE) < GBR
						if idx_UEcnct_TST(idx_UE) <= n_MC
							%  ?�能不能?��?RB 位置 					
							if (isempty(find(UE_RB_used(idx_UE,:) == 1)) == 0) && (isempty(find(BS_RB_table(idx_UEcnct_TST(idx_UE),:) == 0)) == 0)
								[BS_RB_table, BS_RB_who_used, UE_RB_used, UE_Throughput(idx_UE)] = Non_CoMP_Serving_change_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
									                                                                                          idx_UE, idx_UEcnct_TST(idx_UE), UE_Throughput(idx_UE), GBR, BW_PRB);						                                                                                          
							end
						else
							%  ?�能不能?��?RB 位置 					
							if (isempty(find(UE_RB_used(idx_UE, 1:Pico_part) == 1)) == 0) && (isempty(find(BS_RB_table(idx_UEcnct_TST(idx_UE),1:Pico_part) == 0)) == 0)
								[BS_RB_table, BS_RB_who_used, UE_RB_used, UE_Throughput(idx_UE)] = Non_CoMP_Serving_change_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
									                                                                                          idx_UE, idx_UEcnct_TST(idx_UE), UE_Throughput(idx_UE), GBR, BW_PRB);		                                                                                          
							end
						end

						% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);
					end

					% ------------------------------------ %
					% 如�?Throughput >= GBR，�??��??��?RB  %
					% ------------------------------------ %
					if UE_Throughput(idx_UE) >= GBR
						% ?�頻譜�???= 0?�RB丟�?，�??��??�以?��?，那就繼續�?
						[BS_RB_table, BS_RB_who_used, UE_RB_used, UE_Throughput(idx_UE)] = Non_CoMP_throw_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
																										     idx_UE, idx_UEcnct_TST(idx_UE), GBR, BW_PRB);

						% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);
					else
						% Sorry，�??��??�Target?�Macro，那你只?��??�己�?
						if idx_trgt <= n_MC
							[BS_RB_table, BS_RB_who_used, UE_RB_used, UE_Throughput(idx_UE), Dis_Connect_Reason] = Non_CoMP_take_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
																																	idx_UE, idx_UEcnct_TST(idx_UE), UE_Throughput(idx_UE), GBR, BW_PRB);	
							
							% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);

						% OK! Target?�Pico，�??�以?��??��?�?
						else
							% --------------------------- %
							% Dynamic Resource Scheduling %
							% --------------------------- %
							% if (isempty(find(UE_RB_used(idx_UE, 1:Pico_part) == 1)) == 0) && (isempty(find(BS_RB_table(idx_trgt, 1:Pico_part) == 0)) == 0)
							% 	[BS_RB_table, BS_RB_who_used, UE_RB_used, UE_Throughput(idx_UE)] = Non_CoMP_DRS(BS_lct, n_MC, n_PC, P_MC_dBm, P_PC_dBm, BS_RB_table, BS_RB_who_used, UE_lct, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
							% 																					idx_UE, idx_UEcnct_TST(idx_UE), idx_trgt, UE_Throughput(idx_UE), ...
							% 																					GBR, BW_PRB, UE_CoMP_orNOT);

							% 	% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);
							% end

							% Pico?��?Dynamic Resource Scheduling ?�現QoS?�是不�?，就?��??��??��?CoMP
							if UE_Throughput(idx_UE) < GBR
								[BS_RB_table, BS_RB_who_used, UE_RB_used, UE_Throughput(idx_UE), Dis_Connect_Reason] = Non_CoMP_take_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
																																		idx_UE, idx_UEcnct_TST(idx_UE), UE_Throughput(idx_UE), GBR, BW_PRB);
									
								% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);
							end
						end						
					end	

					% ----------------------------------------------------------------- %
					% 總於�???��?Throughput?��?QoS，就?�OK?��?如�?不ok就�??��?來�?�?  %
					% ----------------------------------------------------------------- %
					if UE_Throughput(idx_UE) >= GBR
						Dis_Connect_Reason = 0;
					end
				end 


				% ---------------------------------- %
				% 計�?UE Call Drop and BS Call Drop  %
				% ---------------------------------- %
				if Dis_Connect_Reason == 0          % ?��?來�?�?�� (1)UE handover?��? (2)沒�?handover or handover失�?，�??�UE?��????Serving  Cell

					% Dropping timer ?�置??1sec					
					timer_Drop_OngoingCall_NoRB(idx_UE)      = t_T310;
					timer_Drop_OngoingCall_RBNotGood(idx_UE) = t_T310;

					% ?��?
					Dis_Connect_Reason = 0;
				else
					if Dis_Connect_Reason == 1      % ?��?來�?裡就?? (1)?�Serving Cell要�?源�?Serving Cell說�?源�?�?
						if timer_Drop_OngoingCall_NoRB(idx_UE) <= t_T310 && timer_Drop_OngoingCall_NoRB(idx_UE) > 0
							timer_Drop_OngoingCall_NoRB(idx_UE) = timer_Drop_OngoingCall_NoRB(idx_UE) - t_d;
							if timer_Drop_OngoingCall_NoRB(idx_UE) < 1e-5	% [SPECIAL CASE]
								timer_Drop_OngoingCall_NoRB(idx_UE) = 0;	% [SPECIAL CASE]
							end 

							% ?��?
							Dis_Connect_Reason = 0;

						elseif timer_Drop_OngoingCall_NoRB(idx_UE) == 0

							% Drop記�?�??
							n_Drop_UE = n_Drop_UE + 1;

							% 該UE?�為Cell?��?源�?夠被?��?						
							CDR_BS(idx_UEcnct_TST(idx_UE)) = CDR_BS(idx_UEcnct_TST(idx_UE)) + 1;

							% ?�UE?�被Macro?�是Pico說�?源�?夠�??��?你斷?��?
							if idx_UEcnct_TST(idx_UE) <= n_MC
								Drop_OngoingCall_NoRB_Macro = Drop_OngoingCall_NoRB_Macro + 1;								
							else
								Drop_OngoingCall_NoRB_Pico  = Drop_OngoingCall_NoRB_Pico + 1;
							end

							% ?�RB?�給Serving Cell
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
							idx_UEcnct_TST(idx_UE) = 0; % 結�????
							UE_Throughput(idx_UE)  = 0; % UE?�throughput歸零

							% Dropping timer ?�置??1sec
							timer_Drop_OngoingCall_NoRB(idx_UE)      = t_T310;
							timer_Drop_OngoingCall_RBNotGood(idx_UE) = t_T310;

							% ?��?
							Dis_Connect_Reason = 0;
						end

					elseif Dis_Connect_Reason == 2  % ?��?來�?裡就?? (1)?�Serving Cell要�?源�??�現Serving Cell?�RB質�?不�?

						if timer_Drop_OngoingCall_RBNotGood(idx_UE) <= t_T310 && timer_Drop_OngoingCall_RBNotGood(idx_UE) > 0
							% ?�數Drop timer 
							timer_Drop_OngoingCall_RBNotGood(idx_UE) = timer_Drop_OngoingCall_RBNotGood(idx_UE) - t_d;
							if timer_Drop_OngoingCall_RBNotGood(idx_UE) < 1e-5	% [SPECIAL CASE]
								timer_Drop_OngoingCall_RBNotGood(idx_UE) = 0;		% [SPECIAL CASE]
							end 

							% ?��?
							Dis_Connect_Reason = 0;

						elseif timer_Drop_OngoingCall_RBNotGood(idx_UE) == 0

							% Drop記�?�??
							n_Drop_UE = n_Drop_UE + 1;

							% 該Ongoing Call?�為?�到?�RB之頻譜�??�都太�?�?  並�??��?1�? ??��被�?�?
							CDR_BS(idx_UEcnct_TST(idx_UE))  = CDR_BS(idx_UEcnct_TST(idx_UE)) + 1;

							% ?�裡?��??�UE?�己走太?��?但在之�?如�??�想Handover但被?��?，�??��?走太?��?人�??��??��?要�?�??							
							if idx_UEcnct_TST(idx_UE) <= n_MC
								Drop_OngoingCall_RBNotGood_Macro = Drop_OngoingCall_RBNotGood_Macro + 1;
							else
								Drop_OngoingCall_RBNotGood_Pico  = Drop_OngoingCall_RBNotGood_Pico + 1;
							end		

							% ?�RB?�給Serving Cell
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
							idx_UEcnct_TST(idx_UE) = 0; % 結�????
							UE_Throughput(idx_UE)  = 0; % UE?�throughput歸零

							% Dropping timer ?�置??1sec
							timer_Drop_OngoingCall_NoRB(idx_UE)      = t_T310;
							timer_Drop_OngoingCall_RBNotGood(idx_UE) = t_T310;

							% ?��?
							Dis_Connect_Reason = 0;
						end						
					end
				end
				% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);

				% --------------------------------- %
				% 主�?統�?: 檢查Ping-Pong?��??�發??%
				% --------------------------------- %
				if logical_HO(idx_UE) == 1

					% ---------------------------------------------------- %
					% 計�?Ping-Pong Effect?�否?�發?��?跟Performance ?��?�?%
					% ?�兩?�KPI: (1) 1秒內?��?碰�?   (2) 5秒內?��?碰�?     %
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

					% ?��?
					logical_HO(idx_UE) = 0;
				else
					if UE_CoMP_orNOT(idx_UE) == 1 % 如�??��??��?CoMP，�??�Ping-pong  effect 不�???				
						state_PPE_TST(idx_UE,:) = 0;
					end
				end
			end	
		end

		% ========================================================================================================================== %
		% 以�?等�??��?算Cell?�CBR                                                                                                    % 
		% Cell角度?�CBR: ?�UE沒�?????��??��?線目標�??��??��?後UE變�?沒�?Serving   Cell，�??��??�Block Call就�?算在?��??��?線Cell�? %
		% Cell角度?�CDR: ?�UE?�身?�Serving Cell，�??��?後UE?��?Serving  Cell，�?筆Call Drop就�??�Serving Cell�?                     %
		% ========================================================================================================================== %
		if temp_CoMP_state == 0
			if UE_CoMP_orNOT(idx_UE) == 0

				% ?�本沒�?CoMP，�?來�?沒�??�CoMP				
				if idx_UEprey_TST(idx_UE) ~= 0     % 該UE?��??��??��?線目標�?�?��?��???
					if idx_UEcnct_TST(idx_UE) == 0 % UE?��??�目標�?但�?後卻沒�?Serving  Cell
						n_DeadUE_BS(idx_UEprey_TST(idx_UE)) = n_DeadUE_BS(idx_UEprey_TST(idx_UE)) + 1;

					else % idx_UEcnct_TST(idx_UE) ~= 0
						n_LiveUE_BS(idx_UEcnct_TST(idx_UE)) = n_LiveUE_BS(idx_UEcnct_TST(idx_UE)) + 1;
					end
				else
					fprintf('BS_CBR calculation BUG\n');
				end	
			else
				% ?�本沒�?CoMP，�?來�??�CoMP	
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

    % 結�?Loop 2(UE?�Loop)
    % ======================== %
    % 算Macro跟Pico?��??�人?? %
    % ======================== %
    for idx_UE = 1:1:n_UE  
		Macro_Serving_Num_change(round(idx_t/t_d), 1)        = length(find(0 < idx_UEcnct_TST & idx_UEcnct_TST <= n_MC));
		Pico_NonCoMP_Serving_Num_change(round(idx_t/t_d), 1) = length(find(idx_UEcnct_TST > n_MC));
		Pico_CoMP_Serving_Num_change(round(idx_t/t_d), 1)    = length(nonzeros(UE_CoMP_orNOT)); 
    end

    % ============================== %
    % 算BS??��?��?Resource Block?��? %
    % ============================== %
    for idx_BS = 1:1:n_BS
    	if idx_BS <= n_MC
    		BS_RB_consumption(idx_BS) = BS_RB_consumption(idx_BS) + length(nonzeros(BS_RB_table(idx_BS, :)));
    	else
    		BS_RB_consumption(idx_BS) = BS_RB_consumption(idx_BS) + length(nonzeros(BS_RB_table(idx_BS, 1:Pico_part)));
    	end    	
    end

	% ======================================== %
	% 算UE?�Call Block Rate and Call Drop Rate %
	% ======================================== %
	% UE Call Block Rate
	UE_CBR = UE_CBR + (n_Block_UE);

	% UE Call Drop Rate 
	Average_UE_CDR = Average_UE_CDR + n_Drop_UE*(UE_surviving/n_UE);
	
	UE_CDR  = UE_CDR + (n_Drop_UE);

	% UE平�?存活人數	
	UE_survive = UE_survive + (n_UE - n_Block_UE - n_Drop_UE);
	
	% ?�置
	n_Block_UE  = 0;	
	n_Drop_UE   = 0;

	% ======================================== %
    % 算BS?�Call Block Rate and Call Drop Rate %
	% ======================================== %
	for idx_BS = 1:n_BS
		% BS Call Block Rate
		if n_DeadUE_BS(idx_BS) == 0 && n_LiveUE_BS(idx_BS) == 0    % 如�?沒�?人�?該BS ?�目標�?該BS ?�CBR = 0
			CBR_BS_TST(idx_BS) = 0;
		else
			CBR_BS_TST(idx_BS) = n_DeadUE_BS(idx_BS) / (n_DeadUE_BS(idx_BS) + n_LiveUE_BS(idx_BS));
		end

		% BS Call Drop Rate
		if n_HO_BS_TST(idx_BS) == 0 && CDR_BS(idx_BS) == 0
			CDR_BS_TST(idx_BS) = 0;
		else
			CDR_BS_TST(idx_BS) = CDR_BS(idx_BS) / (CDR_BS(idx_BS) + n_HO_BS_TST(idx_BS));
		end
	end

	% ?�置
	n_LiveUE_BS(1,:) = 0;
	n_DeadUE_BS(1,:) = 0;
	n_HO_BS_TST(1,:) = 0;
	CDR_BS(1,:)      = 0;

	% ----------- %
	% ?�新Loading %
	% ----------- %
	[Load_TST] = Update_Loading(n_BS, n_MC, BS_RB_table, n_ttoffered, Pico_part);	

	% ================================================ % % ====================================== %
	%          -          -------        --            % %   --------    --------      -------    %
	%          |          |      )      /  \           % %   |          /        \    /           %
	%          |          |------      /----\          % %   |------|  |        \ |  |            %
	%          |          |           /      \         % %   |          \        X    \           %
	%          -------    -          -        -        % %   -           -------- \    -------    %
	% ================================================ % % ====================================== %	
	% Loop 4: ?�地?��?始�?Fuzzy Q (???細�??�CIO, Loading, CBR, CDR)
	if (idx_t == t_start || rem(idx_t, FQ_BS_LI_TST) <= 0.01)
		for idx_BS = 1:n_BS			
			% Fuzzifier
			DoM_CIO_TSTc(idx_BS,:)      = FQc1_Fuzzifier(CIO_TST(idx_BS), 'C');  % CIO?�degree of membership
			DoM_Load_TSTc(idx_BS,:)     = FQc1_Fuzzifier(Load_TST(idx_BS),'L');  % Loading?�degree of membership
			DoT_Rule_New_TSTc(idx_BS,:) = FQc2_DegreeOfTruth(DoM_CIO_TSTc(idx_BS,:), DoM_Load_TSTc(idx_BS,:),'D');  %算degree of truth?�方法D (?��?)

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
			%?��?GlobalAct?�當作�??��?，�??��?上�?�?��?�CIO，當作�?�?��?�正使用?�CIO    (?��??�為了�?讓CIO變�?太大) 
			% if     (CIO_TST(idx_BS) + GlobalAct_TSTc(idx_BS) < -5)
			% 	CIO_TST(idx_BS) = -5;
			% elseif (CIO_TST(idx_BS) + GlobalAct_TSTc(idx_BS) > 5)
			% 	CIO_TST(idx_BS) = 5;
			% else
			% 	CIO_TST(idx_BS) = CIO_TST(idx_BS) + GlobalAct_TSTc(idx_BS);
			% end
			CIO_TST(idx_BS) = GlobalAct_TSTc(idx_BS);

			% 計�?Q-function 
			Q_fx_new_TSTc(idx_BS) = FQc4_Qfunction(DoT_Rule_New_TSTc(idx_BS,:), Q_Table_TSTc(:,:,idx_BS), ...
																	idx_subAct_choosed_new_TSTc(idx_BS,:));			
		end	
		% Recording for the different iteration of 'Q-function'
		Q_fx_old_TSTc               = Q_fx_new_TSTc;
		idx_subAct_choosed_old_TSTc = idx_subAct_choosed_new_TSTc;
		DoT_Rule_Old_TSTc           = DoT_Rule_New_TSTc;

	end
	% 結�? Loop 4

end

toc
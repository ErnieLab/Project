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
rectEdge = 4763;															% ç³»çµ±?„é???[meter]
load('MC_lct_4sq');															% å¤§ç´°?žç?ä½ç½®è®?‡ºä¾†ï??©é™£??  Macro_location		
load('PC_lct_4sq_n250_random');                                         % å°ç´°?žç?ä½ç½®è®?‡ºä¾?ï¼ŒçŸ©??«: Pico_location
BS_lct = [Macro_location ; Pico_location];								    % ?¨éƒ¨ç´°è??„ä?ç½?

P_MC_dBm    =  46;															% å¤§ç´°??total TX power (?¨éƒ¨?»å¸¶? èµ·ä¾†ç?power) [dBm]
P_PC_dBm    =  30;															% å°ç´°??total TX power (?¨éƒ¨?»å¸¶? èµ·ä¾†ç?power) [dBm]
P_minRsrpRQ = -100; % [dBm]                          		% [[[ADJ]]]     % Minimum Required power to provide services 
																			% sufficiently for UE accessing to BS [dBm]
																			% Requirement for accessing a particular cell
MACROCELL_RADIUS = (10^((P_MC_dBm-P_minRsrpRQ-128.1)/37.6))*1e+3;
PICOCELL_RADIUS  = (10^((P_PC_dBm-P_minRsrpRQ-140.7)/36.7))*1e+3;

n_MC = length(Macro_location);			                                    % å¤§ç´°?žç??¸ç›®
n_PC = length(Pico_location);	                                            % å°ç´°?žç??¸ç›®
n_BS = n_MC + n_PC;															% ?¨éƒ¨ç´°è??„æ•¸??

% -----------------------------------------------------
% -------------/* Resource Parameter */----------------
% -----------------------------------------------------
sys_BW      = 5   * 1e+6;									% [[[ADJ]]]		% ç³»çµ±ç¸½é »å¯?5MHz
BW_PRB      = 180 * 1e+3;													% LTE æ¯å?Resource Block?„é »å¯¬ç‚º 180kHz
n_ttoffered = sys_BW/(BW_PRB/9*10);											% [[[ADJ]]]     % #max cnct per BS i.e., PRB
                                                                            % ç³»çµ± RB ?„ç¸½?¸ï?*9/10??®µ?¯æ?RB?„CPç®—é?ä¾†é™¤
																			% B E N: Max #PRB under BW = 10 Mhz per slot(0.5ms)
Pico_part   = n_ttoffered;                                                  % Pico Cell?¯ä»¥ä½¿ç”¨?„éƒ¨??

GBR         = 256 * 1024;													% Guaranteed Bit Rate is 256 kbit/sec
% -----------------------------------------------------
% -----------------/* Channel */-----------------------
% -----------------------------------------------------
Gamma_MC            = 3.76;                                                 % Pathloss Exponent (MC)            
Gamma_PC            = 3.67;                                                 % Pathloss Exponent (PC)  
P_N_dBmHz           = -174; % [dBm/Hz]										% é«˜æ–¯?œè???Power Density [dBm/Hz]
LTE_NoiseFloor_dBm  = P_N_dBmHz + 10*log10(BW_PRB);							% Noise Floor approximate -121.45 [dBm/RB]
LTE_NoiseFloor_watt = 10^((LTE_NoiseFloor_dBm - 30)/10);					% Noise Floor approximate 7.1614 * 1e-16 [watt/RB]



% -----------------------------------------------------
% ------------/* User ä½ç½®?Œæ•¸??*/--------------------
% -----------------------------------------------------
load('UE_lct_n400_random');
UE_lct = UE_location;                                                       % è®?E?„ä?ç½®å‡ºä¾?(æ³¨æ?æª”å?)
n_UE = length(UE_lct);			                                            % ?¨éƒ¨UE?„æ•¸??

% -----------------------------------------------------
% -------------/* Handover Setting */------------------
% -----------------------------------------------------
HHM    = 2;	  % [dB]										% [[[ADJ]]]     % Handover Hysteresis Margin [dB]
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
% -----------/* ?Šç³»çµ±Model?–è??ºä? */-----------------
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
% ---------/* ä¸‹é¢?¯ç´°?žè?UE?„å?å§‹å? */----------------
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
% ---------/* ä¸‹é¢?¯TST BDRY?„å?å§‹å?*/-----------------
% -----------------------------------------------------
% BS?¨å?
n_RBoffer_TST          = zeros(1, n_BS);									        % The number of RB a BS offer to UEs inside it
Load_TST               = zeros(1, n_BS);
CIO_TST                = zeros(1, n_BS);

n_HO_BS_TST     = zeros(1, n_BS);	% Only for target cell			        % KPI: Handover Number of BS

% UE?¨å?
crntRSRP_TST    = zeros(n_UE, 1);		% [dBm]

idx_UEcnct_TST  = zeros(1, n_UE);                                           % UEå¯¦é?????„åŸº?°å°
idx_UEprey_TST  = zeros(1, n_UE);		                                    % UE?³è?????„åŸº?°å°


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

% DropReason1_M2M___RB = zeros(1,n_UE);	% Drop Reason = 1                   % ? ç‚ºè³‡æ?ä¸å??Œä¸­??(Drop)???
% DropReason2_M2P___RB = zeros(1,n_UE);	% Drop Reason = 1                     M2M(Macro to Macro)
% DropReason3_P2M___RB = zeros(1,n_UE);	% Drop Reason = 1                     M2P(Macro to Pico)
% DropReason4_P2P___RB = zeros(1,n_UE);	% Drop Reason = 1

% DropReason5_M2M__ToS = zeros(1,n_UE);	% Drop Reason = 2                   % ? ç‚ºToSå¤ªçŸ­ï¼Œå??¼ToS Thresholdï¼Œæ?ä»¥ä?Handover
% DropReason6_M2P__ToS = zeros(1,n_UE);	% Drop Reason = 2
% DropReason7_P2M__ToS = zeros(1,n_UE);	% Drop Reason = 2
% DropReason8_P2P__ToS = zeros(1,n_UE);	% Drop Reason = 2

% DropReason9_MMM_Conn = zeros(1,n_UE);	% Drop Reason = 3                   % A3 event æ²’æ??¼ç?ï¼Œä?? ç‚ºCIO ?„é?ä¿‚é??dropping
% DropReasonX_PPP_Conn = zeros(1,n_UE);	% Drop Reason = 3                     MMM and PPPä»?¡¨?®å?servingå°è±¡?ºMC or PC

% DropReasonY_M2M__TTT = zeros(1,n_UE);	% Drop Reason = 4                   % ?¨TTTä»¥å…§?„æ??“ç™¼?Ÿdropping
% DropReasonY_M2P__TTT = zeros(1,n_UE);	% Drop Reason = 4
% DropReasonY_P2M__TTT = zeros(1,n_UE);	% Drop Reason = 4
% DropReasonY_P2P__TTT = zeros(1,n_UE);	% Drop Reason = 4
% % ?å¸«?„è§£è®?Reason1, 3, 4?½æ˜¯? ç‚ºè³‡æ?ä¸å??„é?ä¿?(å¾…ç¢ºèª?

% UE TST (LPA?„éƒ¨??
LPA_P1t = zeros(1,n_UE);	% TrgtCell
LPA_P2t = zeros(1,n_UE);
LPA_P3t = zeros(1,n_UE);
LPA_Ps  = 10^((P_minRsrpRQ-30)/10);	% [Watt]
LPA_t1  = zeros(1,n_UE);
LPA_t2  = zeros(1,n_UE);
LPA_t3  = zeros(1,n_UE);
LPA_idx_pkt      = zeros(1,n_UE);
LPA_pred_trgtToS = zeros(1,n_UE);


GPSinTST_trgtToS = zeros(1,n_UE); % GPS?å‡ºä¾†ç? TOS

% -----------------------------------------------------
% ---------/* Fuzzy Q Learning ?„å?å§‹å?*/--------------
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
% ---------/* è¨ˆç? Performance ?„å?å§‹å? */-------------
% -----------------------------------------------------
% ç®—BS??
PRFM_TST_BS_CBR   = zeros(1, n_Measured);
PRFM_TST_BS_CDR   = zeros(1, n_Measured);
PRFM_TST_BS_QoS   = zeros(1, n_Measured);

% ç®—UE??
PRFM_TST_UE_nHO   = zeros(1, n_Measured);
PRFM_TST_UE_CBR   = zeros(1, n_Measured);	% 2017.01.05
PRFM_TST_UE_CDR   = zeros(1, n_Measured);
PRFM_TST_UE_1snPP = zeros(1, n_Measured);
PRFM_TST_UE_5snPP = zeros(1, n_Measured);
PRFM_TST_UE_5sPPR = zeros(1, n_Measured);

% ç®—Load Balancing
LB_Idle           = zeros(1, n_Measured);	% 2017.01.19
LB___PC           = zeros(1, n_Measured);	% 2017.01.19
LB___MC           = zeros(1, n_Measured);	% 2017.01.19

% Counter 
PRFM_CTR          = 1;

% -----------------------------------------------------
% ---------------/* ?‘ç??±è¥¿ ?å???*/-----------------
% -----------------------------------------------------
CRE_Macro       = zeros(1, n_MC) + 0;                      % Macro ??CRE [dBm]
CRE_Pico        = zeros(1, n_PC) + 0;                      % Pico  ??CRE [dBm]
CRE             = [CRE_Macro CRE_Pico];                    % Cell Range Expensionï¼Œä¸»è¦çµ¦å°ç´°?žç”¨?„ï?è®“å?ç´°è??“æ›´å¤šäºº?²ä?

BS_RB_table     = zeros(n_MC + n_PC, n_ttoffered);         % ?¨éƒ¨Cell?„RBä½¿ç”¨???    0:?ªç”¨ 1:å·²ç”¨
BS_RB_who_used  = zeros(n_MC + n_PC, n_ttoffered);         % Cell?„RB?‹æ˜¯?ªå?UE?¨ç”¨
UE_RB_used      = zeros(n_UE, n_ttoffered);                % UEä½¿ç”¨äº†å“ªäº›RB          0:?ªç”¨ 1:å·²ç”¨
UE_Throughput   = zeros(1, n_UE);                          % é¡¯ç¤ºæ¯å?UE?„Throughput

UE_surviving    = 0; 

UE_CoMP_orNOT   = zeros(1, n_UE);                          % ?¤æ–·UE?ˆæ??‰åœ¨?šCoMP  0:æ²’æ? 1:æ­?œ¨?šCoMP                    
idx_UEcnct_CoMP = zeros(n_UE, 2);                          % ?‹UE?¯çµ¦?ªå…©?‹Cell?šCoMP : Colunm1 ??Serving Cell, Colunm2 ??Cooperating Cell
CoMP_Threshold  = 4;                                       % ?·è?CoMP?„RSRP Thresholdï¼Œä?å®šè?å¤§æ–¼ 3dB  (dBm)
CoMP_change_TTT = zeros(1, n_UE) + t_TTT;                  % UE?¨åŸ·è¡ŒCoMP?‚ï?äº¤æ?Serving?ŒCooperatingè§’è‰²?„TTT


% UE Blockå®šç¾©: ?Ÿæœ¬UEæ²’æ?Serving Cell, è©²UE?³é??°é?ä¸Šç?ï¼Œå»è¢«æ?çµ?
% UE Drop å®šç¾©: UE?Ÿæœ¬?‰ä?Serving Cell?¨æ??? ä½†å?ç¨®ç¨®?Ÿå?ä»–è¢«?¾æ?

n_Block_UE                 = 0;				               % è¢«Blcok?„äºº??

n_Block_NewCall_NoRB_Macro = 0;                            % NewCall ? ç‚º?¼ç¾Cell(Max RSRP)æ²’æ??¯ä»¥?¨ç?RBäº? ??»¥?¾æ????: Block 
n_Block_NewCall_NoRB_Pico  = 0;

n_Block_NewCall_RBNotGood_Macro  = 0;                      % NewCall ? ç‚º?‹åˆ°Cell(Max RSRP)?¯ä»¥?¨ç?RBä¹‹é »è­œæ??‡éƒ½=0  , ??»¥?¾æ????: Block
n_Block_NewCall_RBNotGood_Pico   = 0;

n_Block_Waiting_BlockTimer       = 0;                      % ?¨ç?Block timerï¼Œè¢«Block??



UE_CBR                     = 0;                            % Call Block Rate: ?¨éƒ¨UEè·‘å?å¾Œï?  N(è¢«Block?„äºº?? / n_UE

n_Drop_UE                   = 0;                           % è¢«Drop ?„äºº??

Drop_OngoingCall_NoRB_Macro = 0;                           % OngoingCall ? ç‚º?¼ç¾Serving Cell æ²’æ??¯ä»¥?¨ç?RBäº†ï? ä¸¦ä??ç?1ç§’ï???»¥è¢«æ”¾æ£„æ”¯?é?ç·?  Drop
Drop_OngoingCall_NoRB_Pico  = 0;

Drop_OngoingCall_RBNotGood_Macro = 0;                      % OngoingCall ? ç‚º?¼ç¾Serving Cell ?¯ä»¥?¨ç?RBä¹‹é »è­œæ??‡éƒ½=0 ï¼Œä¸¦ä¸”æ?çº?ç§’ï???»¥?¾æ????:  Drop
Drop_OngoingCall_RBNotGood_Pico  = 0;

Drop_CoMPCall_NoRB_Pico          = 0;                      % CoMPCall? ç‚º?¼ç¾Serving Cell?ŒCooperating Cellæ²’æ??¯ä»¥?¨ç?RBäº†ï?ä¸¦ä??ç?1ç§’ï? ??»¥è¢«æ”¾æ£„æ”¯?é?ç·?  Drop

Drop_CoMPCall_RBNotGood_Pico     = 0;                      % CoMPCall? ç‚º?¼ç¾Serving Cell?ŒCooperating Cell?¯ä»¥?¨ç?RBä¹‹é »è­œæ??‡éƒ½=0 ï¼Œä¸¦ä¸”æ?çº?ç§’ï???»¥?¾æ????:  Drop


UE_CDR                     = 0;                            % Call Drop Rate: ?¨éƒ¨UEè·‘å?å¾Œï? N(è¢«Drop?„äºº?? / n_UE
Average_UE_CDR             = 0;

CDR_BS                     = zeros(1,n_BS);                % æ¯å?Base Station?ŠUEçµ¦Drop?„æ¬¡??
CBR_BS                     = zeros(1,n_BS);                % æ¯å?Base Station?ŠUEçµ¦Block?„æ¬¡??

n_DeadUE_BS                = zeros(1, n_BS);		       % ?¨ç?BS?„Call Block Rate?¨ç?
n_LiveUE_BS                = zeros(1, n_BS);		       % ?¨ç?BS?„Call Block Rate?¨ç?    

CBR_BS_TST 		           = zeros(1, n_BS);			   % KPI: Call Block Rate  
CDR_BS_TST 		           = zeros(1, n_BS);			   % KPI: Outage Probability 2016.11.15 -> Call Drop Rate 2017.01.04

BS_RB_consumption          = zeros(1, n_BS);               % æ¯å?Base Station?¨é?æ®µæ??“æ?ä½¿ç”¨?„RB??

BS_last_time_serving       = zeros(1, n_BS);               % ä¸Šå?state?å??„äºº
	
UE_survive                 = 0;                            % UEå¹³å?å­˜æ´»äººæ•¸

Success_Enter_CoMP_times = 0;                              % ?å??„é??¥CoMP?„æ¬¡??
Success_Leave_CoMP_times = 0;                              % ?å??„é›¢?‹CoMPï¼Œæ??‰è¢«?‡æ–·?„æ¬¡??

Failure_Leave_CoMP_Compel_times    = 0;
Failure_Leave_CoMP_NoRB_times      = 0;                    % ?¢é?CoMPå¾Œæ?äººæ?è¾¦æ??¥æ?
Failure_Leave_CoMP_RBNotGood_times = 0;

Handover_success_rate                     = 0;             % UE Handover 成功的機率 (從Base Station 的角度看出去)

Handover_Failure_times                    = 0;             % Handoverå¤±æ??„æ¬¡??
Handover_to_Macro_Failure_NoRB_times      = 0;             % ?³handover?°Macroä½†æ˜¯è¢«æ?çµ•ç?æ¬¡æ•¸
Handover_to_Pico_Failure_NoRB_times       = 0;             % ?³handover?°Picoä½†æ˜¯è¢«æ?çµ•ç?æ¬¡æ•¸

Handover_to_Macro_Failure_RBNotGood_times = 0;             % ?³handover?°Macroä½†æ˜¯è¢«æ?çµ•ç?æ¬¡æ•¸
Handover_to_Pico_Failure_RBNotGood_times  = 0;             % ?³handover?°Picoä½†æ˜¯è¢«æ?çµ•ç?æ¬¡æ•¸

BS_Loading_Record_RB               = zeros(n_BS, (ttSimuT/t_d));
BS_Loading_Record_Serving_Num      = zeros(n_BS, (ttSimuT/t_d));

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
	if (rem(idx_t,t_simu/ttSimuT) < 1e-3)                                       % é¡¯ç¤º?‚é??¨ç?ï¼Œä??¥é??¨å¹¹?›ï? ä¸é?ä¸å½±??
		fprintf(' %.3f sec\n', idx_t)
	end

	AMP_Noise  = LTE_NoiseFloor_watt * abs(randn(1));                            % æ¯å??‚é?é»žç??½é????œè??½ä?ä¸?¨£ [watt/RB]

	CIO_TST(1:1:n_MC) = -5;

	UE_surviving = 0;
	UE_surviving = length(nonzeros(UE_CoMP_orNOT)) + length(nonzeros(idx_UEcnct_TST));

	% Loop 2: User	
	% å¯«æ”¶è¨Šè??„ï?A3 eventï¼Œçµ±è¨ˆå??‹Performanceï¼Œé?ä¿‚åˆ°RB ?„è??ªå·±ä¾?( ç´°è?loading?„å?é¡? UE's SINRè¨ˆç? )
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
			dist_MC(mc)    = norm(UE_lct(idx_UE,:) - Macro_location(mc,:)); % è©²UEè·é›¢?¨éƒ¨MCå¤šé? [meter]
			RsrpMC_dBm(mc) = P_MC_dBm - PLmodel_3GPP(dist_MC(mc), 'M');		% è©²UEå¾žé?äº›MC?¶åˆ°?„RSRP [dBm]
		end
		for pc = 1:n_PC
			dist_PC(pc)    = norm(UE_lct(idx_UE,:) - Pico_location(pc,:));  % è©²UEè·é›¢?¨éƒ¨PCå¤šé? [meter]
			RsrpPC_dBm(pc) = P_PC_dBm - PLmodel_3GPP(dist_PC(pc), 'P');	    % è©²UEå¾žé?äº›PC?¶åˆ°?„RSRP [dBm]
		end
		RsrpBS_dBm  = [RsrpMC_dBm RsrpPC_dBm];
		RsrpBS_dB   = RsrpBS_dBm - 30;								          
		RsrpBS_Watt = 10.^(RsrpBS_dB/10);                                   % ?¨éƒ¨?›æ??¦ç‰¹

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
		% UE?¨Non-CoMPä¸‹èµ°?„FlowChart
		if UE_CoMP_orNOT(idx_UE) == 0  % UEæ²’æ??šCoMP
			temp_CoMP_state = 0;

			% ------------------------------------------------------------------------------- %
			% ?¾å‡º?®å??ªå??ºåœ°?°RSRPå°è©²UE??¤§ ï¼Œè?ä¸”æ˜¯å¤šå?dB (å°æ??°å­¸?·ä¸»ç¨‹å???11-313è¡?)  %
			% ------------------------------------------------------------------------------- %
			temp_rsrp = RsrpBS_dBm + CIO_TST;
			% targetå°è±¡ä¸è??¸åˆ°?ªå·±
			if idx_UEcnct_TST(idx_UE) ~= 0
				temp_rsrp(idx_UEcnct_TST(idx_UE)) = min(temp_rsrp); 
			end
			% ?¸RSRP+CIO??¤§?„å‡ºä¾?			
			[~, idx_trgt] = max(temp_rsrp);

			% ------------------------------ %
			% ?Šç›®?æ?è©²è??å??‘ç?äººæ??ºä?   %
			% ------------------------------ %
			% ?™é?å°ˆé??•ç?Call  Block Rate?„å?é¡?
			if idx_UEcnct_TST(idx_UE) == 0						 
				idx_UEprey_TST(idx_UE) = idx_trgt;			 
			else                             				     
				idx_UEprey_TST(idx_UE) = idx_UEcnct_TST(idx_UE);                      
			end

			% ----------------- %
			% ?‹æ?æ²’æ?äººæ??™ä?  %
			% ----------------- %
			if (idx_UEcnct_TST(idx_UE) == 0) % æ²’äºº?å?ï¼Œé??¯èƒ½?¯initial  or è¢«è¸¢??

				% --------------------------------------------------------------------- %
				% ?¶userè¢«è¸¢?‰å?ï¼Œå??ˆç?ä¸?®µ?‚é??èƒ½?æ–°?¿RBï¼Œé?è£¡å°±UE?¯åœ¨ç­‰é?æ®µæ???   %
				% ?¶userç­‰å?äº†ä?å¾Œï?å°±è??‹å??¿RB                                        %
				% --------------------------------------------------------------------- %
				if (timer_Arrive(idx_UE) ~= 0) % Waiting Users
					timer_Arrive(idx_UE) = timer_Arrive(idx_UE) - t_d;	% Countdown
					if (timer_Arrive(idx_UE) < t_d)
						timer_Arrive(idx_UE) = 0;
					end
					Dis_Connect_Reason = 3; % ?„åœ¨ç­‰é?ç·šï?ä¹Ÿç??¨Call  Block Rate?­ä?
 
				else  %(timer_Arrive(idx_UE) == 0): Arriving Users	
					% ---------------- %
					% ?¿Resource Block %
					% ---------------- %
					[BS_RB_table, BS_RB_who_used, UE_RB_used, idx_UEcnct_TST(idx_UE), UE_Throughput(idx_UE), Dis_Connect_Reason] = NewCall_take_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
									                                                                                                               idx_UE, idx_trgt, GBR, BW_PRB);
									                                                                                                               
					% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);

					% -------------------------------------------------------------------- %
					% ä¸è?UE?¯æ­»?¯æ´»ï¼Œéƒ½?ƒå?çµ¦ä?ä¸??ç­‰å??‚é?ï¼Œä?æ¬¡å¥¹è¢«æ”¾æ£„æ?å°±æ??¸é???    %
					% -------------------------------------------------------------------- %
					while timer_Arrive(idx_UE) == 0	
						timer_Arrive(idx_UE) = poissrnd(1);	% 2017.01.05 Not to be ZERO please.  % ä¸è???0
					end					

					% ---------------------------------------------------- %
					% è¨ˆç?Ping-Pong Effect?¯å¦?‰ç™¼?Ÿï?è·ŸPerformance ?„è?ç®?%
					% ?‰å…©?‹KPI: (1) 1ç§’å…§?¼ç?ç¢°æ?   (2) 5ç§’å…§?¼ç?ç¢°æ?     %
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
				% è¨ˆç?UE Call Block %
				% ----------------- %
				if Dis_Connect_Reason == 0


					% ?„å?
					Dis_Connect_Reason = 0;

				else
					if Dis_Connect_Reason == 1
						n_Block_UE = n_Block_UE + 1;

						% è©²UE? ç‚ºCell?„è?æºä?å¤ è¢«?¾æ?
						if idx_trgt <= n_MC
							n_Block_NewCall_NoRB_Macro = n_Block_NewCall_NoRB_Macro + 1;							
						else
							n_Block_NewCall_NoRB_Pico = n_Block_NewCall_NoRB_Pico + 1;
						end

						% ?„å?
						Dis_Connect_Reason = 0;

					elseif Dis_Connect_Reason == 2
						n_Block_UE = n_Block_UE + 1;
						
						% è©²UE? ç‚º?‹åˆ°?„RBä¹‹é »è­œæ??‡éƒ½å¤ªä?äº?  ??»¥è¢«æ?çµ?
						if idx_trgt <= n_MC
							n_Block_NewCall_RBNotGood_Macro = n_Block_NewCall_RBNotGood_Macro + 1;							
						else
							n_Block_NewCall_RBNotGood_Pico = n_Block_NewCall_RBNotGood_Pico + 1;
						end

						% ?„å?
						Dis_Connect_Reason = 0;
					elseif Dis_Connect_Reason == 3
						n_Block_UE = n_Block_UE + 1;

						% ? ç‚ºUE?„åœ¨ç­?ï¼Œæ?ä»¥ä?ç®—è¢«Block
						n_Block_Waiting_BlockTimer = n_Block_Waiting_BlockTimer + 1;

						% ?„å?
						Dis_Connect_Reason = 0;
					end
				end
			else %(idx_UEcnct_TST(idx_UE) ~= 0): ?‰äººæ­?œ¨?å???

				% ------------------------------------------------- %
				% ?´æ–°Throuhgput and ?Šå?Throughput æ²’è²¢?»ç?RB?”æ?  %
				% ------------------------------------------------- %
				[BS_RB_table, BS_RB_who_used, UE_RB_used, UE_Throughput(idx_UE)] = Non_CoMP_Update_Throughput_and_Delete_Useless_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
														                                                                            idx_UE, idx_UEcnct_TST(idx_UE), BW_PRB);

				% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);

				% -------------------- %
				% ?‹A3 Event?‰æ??‰æ?ç«?%
				% -------------------- %						
				if (RsrpBS_dBm(idx_trgt) + CIO_TST(idx_trgt) > RsrpBS_dBm(idx_UEcnct_TST(idx_UE)) + CIO_TST(idx_UEcnct_TST(idx_UE)) + HHM)

					% A3 Eventä¸?—¦triggerï¼ŒTTTå°±é?å§‹æ•¸
					if (timer_TTT_TST(idx_UE) <= t_TTT && timer_TTT_TST(idx_UE) > 0)

						% ?®ç?æ¸›TTT
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

						% Willie?„æ?ç®—æ?
						% if GPSinTST_trgtToS(idx_UE) > TST_HD
							% ?šé?A3 Event ---> ?¸å?TTT ---> Time of Stay Thresholdå¤§æ–¼TST_HD ---> ?¥ä?ä¾†æª¢?¥å?ä¸å?è³‡æ?

						% Handover Callä¾†æ‹¿RB
						temp_idx_UEcnct_TST = idx_UEcnct_TST(idx_UE); % ?«å??„ï?ä¾†ç??„å??ªè£¡handover?°å“ªè£?
						[BS_RB_table, BS_RB_who_used, UE_RB_used, idx_UEcnct_TST(idx_UE), UE_Throughput(idx_UE), Dis_Handover_Reason] = Non_CoMP_HandoverCall_take_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
										                                                                                                                              idx_UE, idx_UEcnct_TST(idx_UE), idx_trgt, UE_Throughput(idx_UE), GBR, BW_PRB);
						% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);

						if idx_UEcnct_TST(idx_UE) == idx_trgt
							% !!!!!!!!!!?å?Handvoer?°Target Cell!!!!!!!!!!
							% ---------------- %
							% Handoveræ¬¡æ•¸è¨ˆç? %
							% ---------------- %
							n_HO_UE_TST(idx_UE)   = n_HO_UE_TST(idx_UE)   + 1;
							n_HO_BS_TST(idx_trgt) = n_HO_BS_TST(idx_trgt) + 1;	% Only for target cell

							% ----------------------------------- %
							% ?‹Handover?¯å?ä»?º¼Cell?›åˆ°ä»?º¼Cell  %
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
							% è¨˜é?è©²UE?¨è©²?‚é?é»žæ˜¯?¦åŸ·è¡Œä?Handover  %
							% ------------------------------------- %
							logical_HO(idx_UE) = 1;	% Handover success.
							Dis_Connect_Reason = 0; % ?ªè??¯Hnadover?å?ï¼ŒDis_Connect_Reasonä¸??= 0 

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

							% Handoverå¤±æ?äº†ï??‹æ˜¯Handoverèª°è?å¤±æ?ï¼Œé˜¿?ºä?éº¼å¤±?—ï?è¨ˆé?ä¸‹ä?
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
							% è¨˜é?è©²UE?¨è©²?‚é?é»žæ˜¯?¦åŸ·è¡Œä?Handover  %
							% ------------------------------------- %
							logical_HO(idx_UE) = 0;	% Handover fail
						end
						% end
					end		
				else
					% æ²’æ?Handover !!!
					logical_HO(idx_UE) = 0;

					% TTT Reset
					timer_TTT_TST(idx_UE) = t_TTT;
				end
				% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);

                % ----------------------------------------------------------- %
				% å¦‚æ?(1)æ²’æ??ŽA3 Event               __\  å°±æ?èµ°ä»¥ä¸‹ç?æµç?   %
				%     (2)?Žä?ä½†æ˜¯Target Cellæ²’æ?è³‡æ?    /	                  %
				% ----------------------------------------------------------- %			
				if logical_HO(idx_UE) == 0

					% ------------------------------------------------------ %
					% å¦‚æ?Throughput < GBRï¼Œå?ä¾†æ??›ç?ï¼Œé?è£¡æ³¨?ä?å®šè??ˆæ?   %
					% ------------------------------------------------------ %
					if UE_Throughput(idx_UE) < GBR
						if idx_UEcnct_TST(idx_UE) <= n_MC
							%  ?‹èƒ½ä¸èƒ½?›å?RB ä½ç½® 					
							if (isempty(find(UE_RB_used(idx_UE,:) == 1)) == 0) && (isempty(find(BS_RB_table(idx_UEcnct_TST(idx_UE),:) == 0)) == 0)
								[BS_RB_table, BS_RB_who_used, UE_RB_used, UE_Throughput(idx_UE)] = Non_CoMP_Serving_change_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
									                                                                                          idx_UE, idx_UEcnct_TST(idx_UE), UE_Throughput(idx_UE), GBR, BW_PRB);						                                                                                          
							end
						else
							%  ?‹èƒ½ä¸èƒ½?›å?RB ä½ç½® 					
							if (isempty(find(UE_RB_used(idx_UE, 1:Pico_part) == 1)) == 0) && (isempty(find(BS_RB_table(idx_UEcnct_TST(idx_UE),1:Pico_part) == 0)) == 0)
								[BS_RB_table, BS_RB_who_used, UE_RB_used, UE_Throughput(idx_UE)] = Non_CoMP_Serving_change_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
									                                                                                          idx_UE, idx_UEcnct_TST(idx_UE), UE_Throughput(idx_UE), GBR, BW_PRB);		                                                                                          
							end
						end

						% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);
					end

					% ------------------------------------ %
					% å¦‚æ?Throughput >= GBRï¼Œç??½ä??½ä?RB  %
					% ------------------------------------ %
					if UE_Throughput(idx_UE) >= GBR
						% ?Šé »è­œæ???= 0?„RBä¸Ÿæ?ï¼Œå??œé??¯ä»¥?ä?ï¼Œé‚£å°±ç¹¼çºŒä?
						[BS_RB_table, BS_RB_who_used, UE_RB_used, UE_Throughput(idx_UE)] = Non_CoMP_throw_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
																										     idx_UE, idx_UEcnct_TST(idx_UE), GBR, BW_PRB);

						% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);
					else
						% Sorryï¼Œå??œä??„Target?¯Macroï¼Œé‚£ä½ åª?½é??ªå·±äº?
						if idx_trgt <= n_MC
							[BS_RB_table, BS_RB_who_used, UE_RB_used, UE_Throughput(idx_UE), Dis_Connect_Reason] = Non_CoMP_take_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
																																	idx_UE, idx_UEcnct_TST(idx_UE), UE_Throughput(idx_UE), GBR, BW_PRB);	
							
							% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);

						% OK! Target?¯Picoï¼Œä??¯ä»¥?«ä??šé?äº?
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

							% Pico?šå?Dynamic Resource Scheduling ?¼ç¾QoS?„æ˜¯ä¸å?ï¼Œå°±?‹ç??½ä??½å?CoMP
							if UE_Throughput(idx_UE) < GBR
								[BS_RB_table, BS_RB_who_used, UE_RB_used, UE_Throughput(idx_UE), Dis_Connect_Reason] = Non_CoMP_take_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
																																		idx_UE, idx_UEcnct_TST(idx_UE), UE_Throughput(idx_UE), GBR, BW_PRB);
									
								% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);
							end
						end						
					end	

					% ----------------------------------------------------------------- %
					% ç¸½æ–¼è¨???¢ï?Throughput?‰é?QoSï¼Œå°±?¯OK?¦ï?å¦‚æ?ä¸okå°±ä??ƒé?ä¾†é?äº?  %
					% ----------------------------------------------------------------- %
					if UE_Throughput(idx_UE) >= GBR
						Dis_Connect_Reason = 0;
					end
				end 


				% ---------------------------------- %
				% è¨ˆç?UE Call Drop and BS Call Drop  %
				% ---------------------------------- %
				if Dis_Connect_Reason == 0          % ?ƒé?ä¾†é?ä»?¡¨ (1)UE handover?å? (2)æ²’æ?handover or handoverå¤±æ?ï¼Œä??¯UE?å????Serving  Cell

					% Dropping timer ?ç½®??1sec					
					timer_Drop_OngoingCall_NoRB(idx_UE)      = t_T310;
					timer_Drop_OngoingCall_RBNotGood(idx_UE) = t_T310;

					% ?„å?
					Dis_Connect_Reason = 0;
				else
					if Dis_Connect_Reason == 1      % ?ƒé?ä¾†é?è£¡å°±?? (1)?¾Serving Cellè¦è?æºï?Serving Cellèªªè?æºæ?äº?
						if timer_Drop_OngoingCall_NoRB(idx_UE) <= t_T310 && timer_Drop_OngoingCall_NoRB(idx_UE) > 0
							timer_Drop_OngoingCall_NoRB(idx_UE) = timer_Drop_OngoingCall_NoRB(idx_UE) - t_d;
							if timer_Drop_OngoingCall_NoRB(idx_UE) < 1e-5	% [SPECIAL CASE]
								timer_Drop_OngoingCall_NoRB(idx_UE) = 0;	% [SPECIAL CASE]
							end 

							% ?„å?
							Dis_Connect_Reason = 0;

						elseif timer_Drop_OngoingCall_NoRB(idx_UE) == 0

							% Dropè¨˜ä?ä¸??
							n_Drop_UE = n_Drop_UE + 1;

							% è©²UE? ç‚ºCell?„è?æºä?å¤ è¢«?¾æ?						
							CDR_BS(idx_UEcnct_TST(idx_UE)) = CDR_BS(idx_UEcnct_TST(idx_UE)) + 1;

							% ?‹UE?¯è¢«Macro?„æ˜¯Picoèªªè?æºä?å¤ ï??Œæ?ä½ æ–·?‰ç?
							if idx_UEcnct_TST(idx_UE) <= n_MC
								Drop_OngoingCall_NoRB_Macro = Drop_OngoingCall_NoRB_Macro + 1;								
							else
								Drop_OngoingCall_NoRB_Pico  = Drop_OngoingCall_NoRB_Pico + 1;
							end

							% ?ŠRB?„çµ¦Serving Cell
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
							idx_UEcnct_TST(idx_UE) = 0; % çµæ????
							UE_Throughput(idx_UE)  = 0; % UE?„throughputæ­¸é›¶

							% Dropping timer ?ç½®??1sec
							timer_Drop_OngoingCall_NoRB(idx_UE)      = t_T310;
							timer_Drop_OngoingCall_RBNotGood(idx_UE) = t_T310;

							% ?„å?
							Dis_Connect_Reason = 0;
						end

					elseif Dis_Connect_Reason == 2  % ?ƒé?ä¾†é?è£¡å°±?? (1)?¾Serving Cellè¦è?æºï??¼ç¾Serving Cell?„RBè³ªé?ä¸å?

						if timer_Drop_OngoingCall_RBNotGood(idx_UE) <= t_T310 && timer_Drop_OngoingCall_RBNotGood(idx_UE) > 0
							% ?’æ•¸Drop timer 
							timer_Drop_OngoingCall_RBNotGood(idx_UE) = timer_Drop_OngoingCall_RBNotGood(idx_UE) - t_d;
							if timer_Drop_OngoingCall_RBNotGood(idx_UE) < 1e-5	% [SPECIAL CASE]
								timer_Drop_OngoingCall_RBNotGood(idx_UE) = 0;		% [SPECIAL CASE]
							end 

							% ?„å?
							Dis_Connect_Reason = 0;

						elseif timer_Drop_OngoingCall_RBNotGood(idx_UE) == 0

							% Dropè¨˜ä?ä¸??
							n_Drop_UE = n_Drop_UE + 1;

							% è©²Ongoing Call? ç‚º?‹åˆ°?„RBä¹‹é »è­œæ??‡éƒ½å¤ªä?äº?  ä¸¦ä??ç?1ç§? ??»¥è¢«æ?çµ?
							CDR_BS(idx_UEcnct_TST(idx_UE))  = CDR_BS(idx_UEcnct_TST(idx_UE)) + 1;

							% ?™è£¡?¯å??ºUE?ªå·±èµ°å¤ª? ï?ä½†åœ¨ä¹‹é?å¦‚æ??‰æƒ³Handoverä½†è¢«?’ç?ï¼Œå??´ä?èµ°å¤ª? æ?äººæ??™ï??™ä?è¦ç?ä¸??							
							if idx_UEcnct_TST(idx_UE) <= n_MC
								Drop_OngoingCall_RBNotGood_Macro = Drop_OngoingCall_RBNotGood_Macro + 1;
							else
								Drop_OngoingCall_RBNotGood_Pico  = Drop_OngoingCall_RBNotGood_Pico + 1;
							end		

							% ?ŠRB?„çµ¦Serving Cell
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
							idx_UEcnct_TST(idx_UE) = 0; % çµæ????
							UE_Throughput(idx_UE)  = 0; % UE?„throughputæ­¸é›¶

							% Dropping timer ?ç½®??1sec
							timer_Drop_OngoingCall_NoRB(idx_UE)      = t_T310;
							timer_Drop_OngoingCall_RBNotGood(idx_UE) = t_T310;

							% ?„å?
							Dis_Connect_Reason = 0;
						end						
					end
				end
				% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);

				% --------------------------------- %
				% ä¸»è?çµ±è?: æª¢æŸ¥Ping-Pong?‰æ??‰ç™¼??%
				% --------------------------------- %
				if logical_HO(idx_UE) == 1

					% ---------------------------------------------------- %
					% è¨ˆç?Ping-Pong Effect?¯å¦?‰ç™¼?Ÿï?è·ŸPerformance ?„è?ç®?%
					% ?‰å…©?‹KPI: (1) 1ç§’å…§?¼ç?ç¢°æ?   (2) 5ç§’å…§?¼ç?ç¢°æ?     %
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

					% ?„å?
					logical_HO(idx_UE) = 0;
				else
					if UE_CoMP_orNOT(idx_UE) == 1 % å¦‚æ??‹å??·è?CoMPï¼Œé??‚Ping-pong  effect ä¸å???				
						state_PPE_TST(idx_UE,:) = 0;
					end
				end
			end	
		end

		% ========================================================================================================================== %
		% ä»¥ä?ç­‰ç??¨ä?ç®—Cell?„CBR                                                                                                    % 
		% Cellè§’åº¦?„CBR: ?¥UEæ²’æ?????æ??„é?ç·šç›®æ¨™ï??è??°æ?å¾ŒUEè®Šå?æ²’æ?Serving   Cellï¼Œé??‚é??‹Block Callå°±æ?ç®—åœ¨?æ??„é?ç·šCellä¸? %
		% Cellè§’åº¦?„CDR: ?¥UE?¬èº«?‰Serving Cellï¼Œä??°æ?å¾ŒUE?¢é?Serving  Cellï¼Œé?ç­†Call Dropå°±ç??¨Serving Cellä¸?                     %
		% ========================================================================================================================== %
		if temp_CoMP_state == 0
			if UE_CoMP_orNOT(idx_UE) == 0

				% ?Ÿæœ¬æ²’å?CoMPï¼Œå?ä¾†ä?æ²’æ??šCoMP				
				if idx_UEprey_TST(idx_UE) ~= 0     % è©²UE?¯æ??æ??„é?ç·šç›®æ¨™ï?æ­?¸¸?½æ???
					if idx_UEcnct_TST(idx_UE) == 0 % UE?‰é??Ÿç›®æ¨™ï?ä½†æ?å¾Œå»æ²’æ?Serving  Cell
						n_DeadUE_BS(idx_UEprey_TST(idx_UE)) = n_DeadUE_BS(idx_UEprey_TST(idx_UE)) + 1;

					else % idx_UEcnct_TST(idx_UE) ~= 0
						n_LiveUE_BS(idx_UEcnct_TST(idx_UE)) = n_LiveUE_BS(idx_UEcnct_TST(idx_UE)) + 1;
					end
				else
					fprintf('BS_CBR calculation BUG\n');
				end	
			else
				% ?Ÿæœ¬æ²’å?CoMPï¼Œå?ä¾†æ??šCoMP	
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

    % çµæ?Loop 2(UE?„Loop)
    % ======================== %
    % ç®—Macroè·ŸPico?„æ??™äºº?? %
    % ======================== %  
    [Load_TST] = Update_Loading(n_BS, n_MC, BS_RB_table, n_ttoffered, Pico_part);	  
    for idx_BS = 1:1:n_BS
    	BS_Loading_Record_RB(idx_BS, round(idx_t/t_d))          = Load_TST(idx_BS); 
    	BS_Loading_Record_Serving_Num(idx_BS, round(idx_t/t_d)) = length(find(idx_UEcnct_TST == idx_BS));   	   	
    end

    % ============================== %
    % ç®—BS??½¿?¨ç?Resource Block?¸é? %
    % ============================== %
    for idx_BS = 1:1:n_BS
    	if idx_BS <= n_MC
    		BS_RB_consumption(idx_BS) = BS_RB_consumption(idx_BS) + length(nonzeros(BS_RB_table(idx_BS, :)));
    	else
    		BS_RB_consumption(idx_BS) = BS_RB_consumption(idx_BS) + length(nonzeros(BS_RB_table(idx_BS, 1:Pico_part)));
    	end    	
    end

	% ======================================== %
	% ç®—UE?„Call Block Rate and Call Drop Rate %
	% ======================================== %
	% UE Call Block Rate
	UE_CBR = UE_CBR + (n_Block_UE);

	% UE Call Drop Rate 
	if UE_surviving ~= 0
		Average_UE_CDR = Average_UE_CDR + (n_Drop_UE/UE_surviving);
	else
		Average_UE_CDR = Average_UE_CDR + 0;
	end
	
	UE_CDR  = UE_CDR + (n_Drop_UE);

	% UE handover成功的機率 (從基地台的角度看出去)
	if n_HO_BS_TST(idx_BS) == 0 && CDR_BS(idx_BS) == 0
		Handover_success_rate = Handover_success_rate + 0;
	else	
		Handover_success_rate = Handover_success_rate + ( sum(CDR_BS(idx_BS)) /(sum(CDR_BS(idx_BS)) + sum(n_HO_BS_TST(idx_BS))));
	end	

	% UEå¹³å?å­˜æ´»äººæ•¸	
	UE_survive = UE_survive + (n_UE - n_Block_UE - n_Drop_UE);
	
	% ?ç½®
	n_Block_UE  = 0;	
	n_Drop_UE   = 0;

	% ======================================== %
    % ç®—BS?„Call Block Rate and Call Drop Rate %
	% ======================================== %
	for idx_BS = 1:n_BS
		% BS Call Block Rate
		if n_DeadUE_BS(idx_BS) == 0 && n_LiveUE_BS(idx_BS) == 0    % å¦‚æ?æ²’æ?äººæ?è©²BS ?¶ç›®æ¨™ï?è©²BS ?„CBR = 0
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

	% ?ç½®
	n_LiveUE_BS(1,:) = 0;
	n_DeadUE_BS(1,:) = 0;
	n_HO_BS_TST(1,:) = 0;
	CDR_BS(1,:)      = 0;

	% ----------- %
	% ?´æ–°Loading %
	% ----------- %
	[Load_TST] = Update_Loading(n_BS, n_MC, BS_RB_table, n_ttoffered, Pico_part);	

	% ================================================ % % ====================================== %
	%          -          -------        --            % %   --------    --------      -------    %
	%          |          |      )      /  \           % %   |          /        \    /           %
	%          |          |------      /----\          % %   |------|  |        \ |  |            %
	%          |          |           /      \         % %   |          \        X    \           %
	%          -------    -          -        -        % %   -           -------- \    -------    %
	% ================================================ % % ====================================== %	
	% Loop 4: ?ºåœ°?°é?å§‹å?Fuzzy Q (???ç´°è??„CIO, Loading, CBR, CDR)
	if (idx_t == t_start || rem(idx_t, FQ_BS_LI_TST) <= 0.01)
		for idx_BS = 1:n_BS			
			% Fuzzifier
			DoM_CIO_TSTc(idx_BS,:)      = FQc1_Fuzzifier(CIO_TST(idx_BS), 'C');  % CIO?„degree of membership
			DoM_Load_TSTc(idx_BS,:)     = FQc1_Fuzzifier(Load_TST(idx_BS),'L');  % Loading?„degree of membership
			DoT_Rule_New_TSTc(idx_BS,:) = FQc2_DegreeOfTruth(DoM_CIO_TSTc(idx_BS,:), DoM_Load_TSTc(idx_BS,:),'D');  %ç®—degree of truth?„æ–¹æ³•D (?¸ä?)

			if (idx_t ~= t_start)
				% ç®—Q Bonus
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
			%?™é?GlobalAct?¯ç•¶ä½œè??–é?ï¼Œè??¨å?ä¸Šå?ä¸?¬¡?„CIOï¼Œç•¶ä½œä?ä¸?¬¡?Ÿæ­£ä½¿ç”¨?„CIO    (?®ç??¯ç‚ºäº†ä?è®“CIOè®Šå?å¤ªå¤§) 
			% if     (CIO_TST(idx_BS) + GlobalAct_TSTc(idx_BS) < -5)
			% 	CIO_TST(idx_BS) = -5;
			% elseif (CIO_TST(idx_BS) + GlobalAct_TSTc(idx_BS) > 5)
			% 	CIO_TST(idx_BS) = 5;
			% else
			% 	CIO_TST(idx_BS) = CIO_TST(idx_BS) + GlobalAct_TSTc(idx_BS);
			% end
			CIO_TST(idx_BS) = GlobalAct_TSTc(idx_BS);

			% è¨ˆç?Q-function 
			Q_fx_new_TSTc(idx_BS) = FQc4_Qfunction(DoT_Rule_New_TSTc(idx_BS,:), Q_Table_TSTc(:,:,idx_BS), ...
																	idx_subAct_choosed_new_TSTc(idx_BS,:));			
		end	
		% Recording for the different iteration of 'Q-function'
		Q_fx_old_TSTc               = Q_fx_new_TSTc;
		idx_subAct_choosed_old_TSTc = idx_subAct_choosed_new_TSTc;
		DoT_Rule_Old_TSTc           = DoT_Rule_New_TSTc;

	end
	% çµæ? Loop 4

end

toc
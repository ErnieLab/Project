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
rectEdge = 4763;															% Á≥ªÁµ±?ÑÈ???[meter]
load('MC_lct_4sq');															% Â§ßÁ¥∞?ûÁ?‰ΩçÁΩÆËÆ?á∫‰æÜÔ??©Èô£??  Macro_location		
load('PC_lct_4sq_n250_MP1000_PP40');                                         % Â∞èÁ¥∞?ûÁ?‰ΩçÁΩÆËÆ?á∫‰æ?ÔºåÁü©??è´: Pico_location
BS_lct = [Macro_location ; Pico_location];								    % ?®ÈÉ®Á¥∞Ë??Ñ‰?ÁΩ?

P_MC_dBm    =  46;															% Â§ßÁ¥∞??total TX power (?®ÈÉ®?ªÂ∏∂?†Ëµ∑‰æÜÁ?power) [dBm]
P_PC_dBm    =  30;															% Â∞èÁ¥∞??total TX power (?®ÈÉ®?ªÂ∏∂?†Ëµ∑‰æÜÁ?power) [dBm]
P_minRsrpRQ = -100; % [dBm]                          		% [[[ADJ]]]     % Minimum Required power to provide services 
																			% sufficiently for UE accessing to BS [dBm]
																			% Requirement for accessing a particular cell
MACROCELL_RADIUS = (10^((P_MC_dBm-P_minRsrpRQ-128.1)/37.6))*1e+3;
PICOCELL_RADIUS  = (10^((P_PC_dBm-P_minRsrpRQ-140.7)/36.7))*1e+3;

n_MC = length(Macro_location);			                                    % Â§ßÁ¥∞?ûÁ??∏ÁõÆ
n_PC = length(Pico_location);	                                            % Â∞èÁ¥∞?ûÁ??∏ÁõÆ
n_BS = n_MC + n_PC;															% ?®ÈÉ®Á¥∞Ë??ÑÊï∏??

% -----------------------------------------------------
% -------------/* Resource Parameter */----------------
% -----------------------------------------------------
sys_BW      = 5   * 1e+6;									% [[[ADJ]]]		% Á≥ªÁµ±Á∏ΩÈ†ªÂØ?5MHz
BW_PRB      = 180 * 1e+3;													% LTE ÊØèÂ?Resource Block?ÑÈ†ªÂØ¨ÁÇ∫ 180kHz
n_ttoffered = sys_BW/(BW_PRB/9*10);											% [[[ADJ]]]     % #max cnct per BS i.e., PRB
                                                                            % Á≥ªÁµ± RB ?ÑÁ∏Ω?∏Ô?*9/10??Æµ?ØÊ?RB?ÑCPÁÆóÈ?‰æÜÈô§
																			% B E N: Max #PRB under BW = 10 Mhz per slot(0.5ms)
Pico_part   = n_ttoffered;                                                  % Pico Cell?Ø‰ª•‰ΩøÁî®?ÑÈÉ®??

GBR         = 256 * 1024;													% Guaranteed Bit Rate is 256 kbit/sec
% -----------------------------------------------------
% -----------------/* Channel */-----------------------
% -----------------------------------------------------
Gamma_MC            = 3.76;                                                 % Pathloss Exponent (MC)            
Gamma_PC            = 3.67;                                                 % Pathloss Exponent (PC)  
P_N_dBmHz           = -174; % [dBm/Hz]										% È´òÊñØ?úË???Power Density [dBm/Hz]
LTE_NoiseFloor_dBm  = P_N_dBmHz + 10*log10(BW_PRB);							% Noise Floor approximate -121.45 [dBm/RB]
LTE_NoiseFloor_watt = 10^((LTE_NoiseFloor_dBm - 30)/10);					% Noise Floor approximate 7.1614 * 1e-16 [watt/RB]



% -----------------------------------------------------
% ------------/* User ‰ΩçÁΩÆ?åÊï∏??*/--------------------
% -----------------------------------------------------
load('UE_lct_n400_random');
UE_lct = UE_location;                                                       % ËÆ?E?Ñ‰?ÁΩÆÂá∫‰æ?(Ê≥®Ê?Ê™îÂ?)
n_UE = length(UE_lct);			                                            % ?®ÈÉ®UE?ÑÊï∏??

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
% -----------/* ?äÁ≥ªÁµ±Model?ñË??∫‰? */-----------------
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
% ---------/* ‰∏ãÈù¢?ØÁ¥∞?ûË?UE?ÑÂ?ÂßãÂ? */----------------
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
% ---------/* ‰∏ãÈù¢?ØTST BDRY?ÑÂ?ÂßãÂ?*/-----------------
% -----------------------------------------------------
% BS?®Â?
n_RBoffer_TST   = zeros(1, n_BS);									        % The number of RB a BS offer to UEs inside it
Load_TST        = zeros(1, n_BS);
CIO_TST         = zeros(1, n_BS);

n_HO_BS_TST     = zeros(1, n_BS);	% Only for target cell			        % KPI: Handover Number of BS

% UE?®Â?
crntRSRP_TST    = zeros(n_UE, 1);		% [dBm]

idx_UEcnct_TST  = zeros(1, n_UE);                                           % UEÂØ¶È?????ÑÂü∫?∞Âè∞
idx_UEprey_TST  = zeros(1, n_UE);		                                    % UE?≥Ë?????ÑÂü∫?∞Âè∞


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

% DropReason1_M2M___RB = zeros(1,n_UE);	% Drop Reason = 1                   % ?†ÁÇ∫Ë≥áÊ?‰∏çÂ??å‰∏≠??(Drop)???
% DropReason2_M2P___RB = zeros(1,n_UE);	% Drop Reason = 1                     M2M(Macro to Macro)
% DropReason3_P2M___RB = zeros(1,n_UE);	% Drop Reason = 1                     M2P(Macro to Pico)
% DropReason4_P2P___RB = zeros(1,n_UE);	% Drop Reason = 1

% DropReason5_M2M__ToS = zeros(1,n_UE);	% Drop Reason = 2                   % ?†ÁÇ∫ToSÂ§™Áü≠ÔºåÂ??ºToS ThresholdÔºåÊ?‰ª•‰?Handover
% DropReason6_M2P__ToS = zeros(1,n_UE);	% Drop Reason = 2
% DropReason7_P2M__ToS = zeros(1,n_UE);	% Drop Reason = 2
% DropReason8_P2P__ToS = zeros(1,n_UE);	% Drop Reason = 2

% DropReason9_MMM_Conn = zeros(1,n_UE);	% Drop Reason = 3                   % A3 event Ê≤íÊ??ºÁ?Ôºå‰??†ÁÇ∫CIO ?ÑÈ?‰øÇÈ??êdropping
% DropReasonX_PPP_Conn = zeros(1,n_UE);	% Drop Reason = 3                     MMM and PPP‰ª?°®?ÆÂ?servingÂ∞çË±°?∫MC or PC

% DropReasonY_M2M__TTT = zeros(1,n_UE);	% Drop Reason = 4                   % ?®TTT‰ª•ÂÖß?ÑÊ??ìÁôº?üdropping
% DropReasonY_M2P__TTT = zeros(1,n_UE);	% Drop Reason = 4
% DropReasonY_P2M__TTT = zeros(1,n_UE);	% Drop Reason = 4
% DropReasonY_P2P__TTT = zeros(1,n_UE);	% Drop Reason = 4
% % ?ÅÂ∏´?ÑËß£ËÆ?Reason1, 3, 4?ΩÊòØ?†ÁÇ∫Ë≥áÊ?‰∏çÂ??ÑÈ?‰ø?(ÂæÖÁ¢∫Ë™?

% UE TST (LPA?ÑÈÉ®??
LPA_P1t = zeros(1,n_UE);	% TrgtCell
LPA_P2t = zeros(1,n_UE);
LPA_P3t = zeros(1,n_UE);
LPA_Ps  = 10^((P_minRsrpRQ-30)/10);	% [Watt]
LPA_t1  = zeros(1,n_UE);
LPA_t2  = zeros(1,n_UE);
LPA_t3  = zeros(1,n_UE);
LPA_idx_pkt      = zeros(1,n_UE);
LPA_pred_trgtToS = zeros(1,n_UE);


GPSinTST_trgtToS = zeros(1,n_UE); % GPS?èÂá∫‰æÜÁ? TOS

% -----------------------------------------------------
% ---------/* Fuzzy Q Learning ?ÑÂ?ÂßãÂ?*/--------------
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
% ---------/* Ë®àÁ? Performance ?ÑÂ?ÂßãÂ? */-------------
% -----------------------------------------------------
% ÁÆóBS??
PRFM_TST_BS_CBR   = zeros(1, n_Measured);
PRFM_TST_BS_CDR   = zeros(1, n_Measured);
PRFM_TST_BS_QoS   = zeros(1, n_Measured);

% ÁÆóUE??
PRFM_TST_UE_nHO   = zeros(1, n_Measured);
PRFM_TST_UE_CBR   = zeros(1, n_Measured);	% 2017.01.05
PRFM_TST_UE_CDR   = zeros(1, n_Measured);
PRFM_TST_UE_1snPP = zeros(1, n_Measured);
PRFM_TST_UE_5snPP = zeros(1, n_Measured);
PRFM_TST_UE_5sPPR = zeros(1, n_Measured);

% ÁÆóLoad Balancing
LB_Idle           = zeros(1, n_Measured);	% 2017.01.19
LB___PC           = zeros(1, n_Measured);	% 2017.01.19
LB___MC           = zeros(1, n_Measured);	% 2017.01.19

% Counter 
PRFM_CTR          = 1;

% -----------------------------------------------------
% ---------------/* ?ëÁ??±Ë•ø ?ùÂ???*/-----------------
% -----------------------------------------------------
CRE_Macro       = zeros(1, n_MC) + 0;                      % Macro ??CRE [dBm]
CRE_Pico        = zeros(1, n_PC) + 0;                      % Pico  ??CRE [dBm]
CRE             = [CRE_Macro CRE_Pico];                    % Cell Range ExpensionÔºå‰∏ªË¶ÅÁµ¶Â∞èÁ¥∞?ûÁî®?ÑÔ?ËÆìÂ?Á¥∞Ë??ìÊõ¥Â§ö‰∫∫?≤‰?

BS_RB_table     = zeros(n_MC + n_PC, n_ttoffered);         % ?®ÈÉ®Cell?ÑRB‰ΩøÁî®???    0:?™Áî® 1:Â∑≤Áî®
BS_RB_who_used  = zeros(n_MC + n_PC, n_ttoffered);         % Cell?ÑRB?ãÊòØ?™Â?UE?®Áî®
UE_RB_used      = zeros(n_UE, n_ttoffered);                % UE‰ΩøÁî®‰∫ÜÂì™‰∫õRB          0:?™Áî® 1:Â∑≤Áî®
UE_Throughput   = zeros(1, n_UE);                          % È°ØÁ§∫ÊØèÂ?UE?ÑThroughput

UE_surviving    = 0; 

UE_CoMP_orNOT   = zeros(1, n_UE);                          % ?§Êñ∑UE?àÊ??âÂú®?öCoMP  0:Ê≤íÊ? 1:Ê≠?ú®?öCoMP                    
idx_UEcnct_CoMP = zeros(n_UE, 2);                          % ?ãUE?ØÁµ¶?™ÂÖ©?ãCell?öCoMP : Colunm1 ??Serving Cell, Colunm2 ??Cooperating Cell
CoMP_Threshold  = 4;                                       % ?∑Ë?CoMP?ÑRSRP ThresholdÔºå‰?ÂÆöË?Â§ßÊñº 3dB  (dBm)
CoMP_change_TTT = zeros(1, n_UE) + t_TTT;                  % UE?®Âü∑Ë°åCoMP?ÇÔ?‰∫§Ê?Serving?åCooperatingËßíËâ≤?ÑTTT


% UE BlockÂÆöÁæ©: ?üÊú¨UEÊ≤íÊ?Serving Cell, Ë©≤UE?≥È??∞È?‰∏äÁ?ÔºåÂçªË¢´Ê?Áµ?
% UE Drop ÂÆöÁæ©: UE?üÊú¨?â‰?Serving Cell?®Ê??? ‰ΩÜÂ?Á®ÆÁ®Æ?üÂ?‰ªñË¢´?æÊ?

n_Block_UE                 = 0;				               % Ë¢´Blcok?Ñ‰∫∫??

n_Block_NewCall_NoRB_Macro = 0;                            % NewCall ?†ÁÇ∫?ºÁèæCell(Max RSRP)Ê≤íÊ??Ø‰ª•?®Á?RB‰∫? ??ª•?æÊ????: Block 
n_Block_NewCall_NoRB_Pico  = 0;

n_Block_NewCall_RBNotGood_Macro  = 0;                      % NewCall ?†ÁÇ∫?ãÂà∞Cell(Max RSRP)?Ø‰ª•?®Á?RB‰πãÈ†ªË≠úÊ??áÈÉΩ=0  , ??ª•?æÊ????: Block
n_Block_NewCall_RBNotGood_Pico   = 0;

n_Block_Waiting_BlockTimer       = 0;                      % ?®Á?Block timerÔºåË¢´Block??



UE_CBR                     = 0;                            % Call Block Rate: ?®ÈÉ®UEË∑ëÂ?ÂæåÔ?  N(Ë¢´Block?Ñ‰∫∫?? / n_UE

n_Drop_UE                   = 0;                           % Ë¢´Drop ?Ñ‰∫∫??

Drop_OngoingCall_NoRB_Macro = 0;                           % OngoingCall ?†ÁÇ∫?ºÁèæServing Cell Ê≤íÊ??Ø‰ª•?®Á?RB‰∫ÜÔ? ‰∏¶‰??ÅÁ?1ÁßíÔ???ª•Ë¢´ÊîæÊ£ÑÊîØ?ÅÈ?Á∑?  Drop
Drop_OngoingCall_NoRB_Pico  = 0;

Drop_OngoingCall_RBNotGood_Macro = 0;                      % OngoingCall ?†ÁÇ∫?ºÁèæServing Cell ?Ø‰ª•?®Á?RB‰πãÈ†ªË≠úÊ??áÈÉΩ=0 Ôºå‰∏¶‰∏îÊ?Á∫?ÁßíÔ???ª•?æÊ????:  Drop
Drop_OngoingCall_RBNotGood_Pico  = 0;

Drop_CoMPCall_NoRB_Pico          = 0;                      % CoMPCall?†ÁÇ∫?ºÁèæServing Cell?åCooperating CellÊ≤íÊ??Ø‰ª•?®Á?RB‰∫ÜÔ?‰∏¶‰??ÅÁ?1ÁßíÔ? ??ª•Ë¢´ÊîæÊ£ÑÊîØ?ÅÈ?Á∑?  Drop

Drop_CoMPCall_RBNotGood_Pico     = 0;                      % CoMPCall?†ÁÇ∫?ºÁèæServing Cell?åCooperating Cell?Ø‰ª•?®Á?RB‰πãÈ†ªË≠úÊ??áÈÉΩ=0 Ôºå‰∏¶‰∏îÊ?Á∫?ÁßíÔ???ª•?æÊ????:  Drop


UE_CDR                     = 0;                            % Call Drop Rate: ?®ÈÉ®UEË∑ëÂ?ÂæåÔ? N(Ë¢´Drop?Ñ‰∫∫?? / n_UE
Average_UE_CDR             = 0;

CDR_BS                     = zeros(1,n_BS);                % ÊØèÂ?Base Station?äUEÁµ¶Drop?ÑÊ¨°??
CBR_BS                     = zeros(1,n_BS);                % ÊØèÂ?Base Station?äUEÁµ¶Block?ÑÊ¨°??

n_DeadUE_BS                = zeros(1, n_BS);		       % ?®Á?BS?ÑCall Block Rate?®Á?
n_LiveUE_BS                = zeros(1, n_BS);		       % ?®Á?BS?ÑCall Block Rate?®Á?    

CBR_BS_TST 		           = zeros(1, n_BS);			   % KPI: Call Block Rate  
CDR_BS_TST 		           = zeros(1, n_BS);			   % KPI: Outage Probability 2016.11.15 -> Call Drop Rate 2017.01.04

BS_RB_consumption          = zeros(1, n_BS);               % ÊØèÂ?Base Station?®È?ÊÆµÊ??ìÊ?‰ΩøÁî®?ÑRB??

BS_last_time_serving       = zeros(1, n_BS);               % ‰∏äÂ?state?çÂ??Ñ‰∫∫
	
UE_survive                 = 0;                            % UEÂπ≥Â?Â≠òÊ¥ª‰∫∫Êï∏

Success_Enter_CoMP_times = 0;                              % ?êÂ??ÑÈ??•CoMP?ÑÊ¨°??
Success_Leave_CoMP_times = 0;                              % ?êÂ??ÑÈõ¢?ãCoMPÔºåÊ??âË¢´?áÊñ∑?ÑÊ¨°??

Failure_Leave_CoMP_Compel_times    = 0;
Failure_Leave_CoMP_NoRB_times      = 0;                    % ?¢È?CoMPÂæåÊ?‰∫∫Ê?Ëæ¶Ê??•Ê?
Failure_Leave_CoMP_RBNotGood_times = 0;


Handover_Failure_times                    = 0;             % HandoverÂ§±Ê??ÑÊ¨°??
Handover_to_Macro_Failure_NoRB_times      = 0;             % ?≥handover?∞Macro‰ΩÜÊòØË¢´Ê?ÁµïÁ?Ê¨°Êï∏
Handover_to_Pico_Failure_NoRB_times       = 0;             % ?≥handover?∞Pico‰ΩÜÊòØË¢´Ê?ÁµïÁ?Ê¨°Êï∏

Handover_to_Macro_Failure_RBNotGood_times = 0;             % ?≥handover?∞Macro‰ΩÜÊòØË¢´Ê?ÁµïÁ?Ê¨°Êï∏
Handover_to_Pico_Failure_RBNotGood_times  = 0;             % ?≥handover?∞Pico‰ΩÜÊòØË¢´Ê?ÁµïÁ?Ê¨°Êï∏


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
	if (rem(idx_t,t_simu/ttSimuT) < 1e-3)                                       % È°ØÁ§∫?ÇÈ??®Á?Ôºå‰??•È??®Âππ?õÔ? ‰∏çÈ?‰∏çÂΩ±??
		fprintf(' %.3f sec\n', idx_t)
	end

	AMP_Noise  = LTE_NoiseFloor_watt * abs(randn(1));                            % ÊØèÂ??ÇÈ?ÈªûÁ??ΩÈ????úË??Ω‰?‰∏?®£ [watt/RB]

	% CIO_TST(1:1:n_MC) = -5;

	UE_surviving = 0;
	UE_surviving = length(nonzeros(UE_CoMP_orNOT)) + length(nonzeros(idx_UEcnct_TST));

	% Loop 2: User	
	% ÂØ´Êî∂Ë®äË??ÑÔ?A3 eventÔºåÁµ±Ë®àÂ??ãPerformanceÔºåÈ?‰øÇÂà∞RB ?ÑË??™Â∑±‰æ?( Á¥∞Ë?loading?ÑÂ?È°? UE's SINRË®àÁ? )
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
			dist_MC(mc)    = norm(UE_lct(idx_UE,:) - Macro_location(mc,:)); % Ë©≤UEË∑ùÈõ¢?®ÈÉ®MCÂ§öÈ? [meter]
			RsrpMC_dBm(mc) = P_MC_dBm - PLmodel_3GPP(dist_MC(mc), 'M');		% Ë©≤UEÂæûÈ?‰∫õMC?∂Âà∞?ÑRSRP [dBm]
		end
		for pc = 1:n_PC
			dist_PC(pc)    = norm(UE_lct(idx_UE,:) - Pico_location(pc,:));  % Ë©≤UEË∑ùÈõ¢?®ÈÉ®PCÂ§öÈ? [meter]
			RsrpPC_dBm(pc) = P_PC_dBm - PLmodel_3GPP(dist_PC(pc), 'P');	    % Ë©≤UEÂæûÈ?‰∫õPC?∂Âà∞?ÑRSRP [dBm]
		end
		RsrpBS_dBm  = [RsrpMC_dBm RsrpPC_dBm];
		RsrpBS_dB   = RsrpBS_dBm - 30;								          
		RsrpBS_Watt = 10.^(RsrpBS_dB/10);                                   % ?®ÈÉ®?õÊ??¶Áâπ

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
		% UE?®Non-CoMP‰∏ãËµ∞?ÑFlowChart
		if UE_CoMP_orNOT(idx_UE) == 0  % UEÊ≤íÊ??öCoMP
			temp_CoMP_state = 0;

			% ------------------------------------------------------------------------------- %
			% ?æÂá∫?ÆÂ??™Â??∫Âú∞?∞RSRPÂ∞çË©≤UE??§ß ÔºåË?‰∏îÊòØÂ§öÂ?dB (Â∞çÊ??∞Â≠∏?∑‰∏ªÁ®ãÂ???11-313Ë°?)  %
			% ------------------------------------------------------------------------------- %
			temp_rsrp = RsrpBS_dBm + CIO_TST;
			% targetÂ∞çË±°‰∏çË??∏Âà∞?™Â∑±
			if idx_UEcnct_TST(idx_UE) ~= 0
				temp_rsrp(idx_UEcnct_TST(idx_UE)) = min(temp_rsrp); 
			end
			% ?∏RSRP+CIO??§ß?ÑÂá∫‰æ?			
			[~, idx_trgt] = max(temp_rsrp);

			% ------------------------------ %
			% ?äÁõÆ?çÊ?Ë©≤Ë??çÂ??ëÁ?‰∫∫Ê??∫‰?   %
			% ------------------------------ %
			% ?ôÈ?Â∞àÈ??ïÁ?Call  Block Rate?ÑÂ?È°?
			if idx_UEcnct_TST(idx_UE) == 0						 
				idx_UEprey_TST(idx_UE) = idx_trgt;			 
			else                             				     
				idx_UEprey_TST(idx_UE) = idx_UEcnct_TST(idx_UE);                      
			end

			% ----------------- %
			% ?ãÊ?Ê≤íÊ?‰∫∫Ê??ô‰?  %
			% ----------------- %
			if (idx_UEcnct_TST(idx_UE) == 0) % Ê≤í‰∫∫?çÂ?ÔºåÈ??ØËÉΩ?Øinitial  or Ë¢´Ë∏¢??

				% --------------------------------------------------------------------- %
				% ?∂userË¢´Ë∏¢?âÂ?ÔºåÂ??àÁ?‰∏?Æµ?ÇÈ??çËÉΩ?çÊñ∞?øRBÔºåÈ?Ë£°Â∞±UE?ØÂú®Á≠âÈ?ÊÆµÊ???   %
				% ?∂userÁ≠âÂ?‰∫Ü‰?ÂæåÔ?Â∞±Ë??ãÂ??øRB                                        %
				% --------------------------------------------------------------------- %
				if (timer_Arrive(idx_UE) ~= 0) % Waiting Users
					timer_Arrive(idx_UE) = timer_Arrive(idx_UE) - t_d;	% Countdown
					if (timer_Arrive(idx_UE) < t_d)
						timer_Arrive(idx_UE) = 0;
					end
					Dis_Connect_Reason = 3; % ?ÑÂú®Á≠âÈ?Á∑öÔ?‰πüÁ??®Call  Block Rate?≠‰?
 
				else  %(timer_Arrive(idx_UE) == 0): Arriving Users	
					% ---------------- %
					% ?øResource Block %
					% ---------------- %
					[BS_RB_table, BS_RB_who_used, UE_RB_used, idx_UEcnct_TST(idx_UE), UE_Throughput(idx_UE), Dis_Connect_Reason] = NewCall_take_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
									                                                                                                               idx_UE, idx_trgt, GBR, BW_PRB);
									                                                                                                               
					% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);

					% -------------------------------------------------------------------- %
					% ‰∏çË?UE?ØÊ≠ª?ØÊ¥ªÔºåÈÉΩ?ÉÂ?Áµ¶‰?‰∏??Á≠âÂ??ÇÈ?Ôºå‰?Ê¨°Â•πË¢´ÊîæÊ£ÑÊ?Â∞±Ê??∏È???    %
					% -------------------------------------------------------------------- %
					while timer_Arrive(idx_UE) == 0	
						timer_Arrive(idx_UE) = poissrnd(1);	% 2017.01.05 Not to be ZERO please.  % ‰∏çË???0
					end					

					% ---------------------------------------------------- %
					% Ë®àÁ?Ping-Pong Effect?ØÂê¶?âÁôº?üÔ?Ë∑üPerformance ?ÑË?ÁÆ?%
					% ?âÂÖ©?ãKPI: (1) 1ÁßíÂÖß?ºÁ?Á¢∞Ê?   (2) 5ÁßíÂÖß?ºÁ?Á¢∞Ê?     %
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
				% Ë®àÁ?UE Call Block %
				% ----------------- %
				if Dis_Connect_Reason == 0


					% ?ÑÂ?
					Dis_Connect_Reason = 0;

				else
					if Dis_Connect_Reason == 1
						n_Block_UE = n_Block_UE + 1;

						% Ë©≤UE?†ÁÇ∫Cell?ÑË?Ê∫ê‰?Â§†Ë¢´?æÊ?
						if idx_trgt <= n_MC
							n_Block_NewCall_NoRB_Macro = n_Block_NewCall_NoRB_Macro + 1;							
						else
							n_Block_NewCall_NoRB_Pico = n_Block_NewCall_NoRB_Pico + 1;
						end

						% ?ÑÂ?
						Dis_Connect_Reason = 0;

					elseif Dis_Connect_Reason == 2
						n_Block_UE = n_Block_UE + 1;
						
						% Ë©≤UE?†ÁÇ∫?ãÂà∞?ÑRB‰πãÈ†ªË≠úÊ??áÈÉΩÂ§™‰?‰∫?  ??ª•Ë¢´Ê?Áµ?
						if idx_trgt <= n_MC
							n_Block_NewCall_RBNotGood_Macro = n_Block_NewCall_RBNotGood_Macro + 1;							
						else
							n_Block_NewCall_RBNotGood_Pico = n_Block_NewCall_RBNotGood_Pico + 1;
						end

						% ?ÑÂ?
						Dis_Connect_Reason = 0;
					elseif Dis_Connect_Reason == 3
						n_Block_UE = n_Block_UE + 1;

						% ?†ÁÇ∫UE?ÑÂú®Á≠?ÔºåÊ?‰ª•‰?ÁÆóË¢´Block
						n_Block_Waiting_BlockTimer = n_Block_Waiting_BlockTimer + 1;

						% ?ÑÂ?
						Dis_Connect_Reason = 0;
					end
				end
			else %(idx_UEcnct_TST(idx_UE) ~= 0): ?â‰∫∫Ê≠?ú®?çÂ???

				% ------------------------------------------------- %
				% ?¥Êñ∞Throuhgput and ?äÂ?Throughput Ê≤íË≤¢?ªÁ?RB?îÊ?  %
				% ------------------------------------------------- %
				[BS_RB_table, BS_RB_who_used, UE_RB_used, UE_Throughput(idx_UE)] = Non_CoMP_Update_Throughput_and_Delete_Useless_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
														                                                                            idx_UE, idx_UEcnct_TST(idx_UE), BW_PRB);

				% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);

				% -------------------- %
				% ?ãA3 Event?âÊ??âÊ?Á´?%
				% -------------------- %						
				if (RsrpBS_dBm(idx_trgt) + CIO_TST(idx_trgt) > RsrpBS_dBm(idx_UEcnct_TST(idx_UE)) + CIO_TST(idx_UEcnct_TST(idx_UE)) + HHM)

					% A3 Event‰∏?ó¶triggerÔºåTTTÂ∞±È?ÂßãÊï∏
					if (timer_TTT_TST(idx_UE) <= t_TTT && timer_TTT_TST(idx_UE) > 0)

						% ?ÆÁ?Ê∏õTTT
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

						% Willie?ÑÊ?ÁÆóÊ?
						% if GPSinTST_trgtToS(idx_UE) > TST_HD
							% ?öÈ?A3 Event ---> ?∏Â?TTT ---> Time of Stay ThresholdÂ§ßÊñºTST_HD ---> ?•‰?‰æÜÊ™¢?•Â?‰∏çÂ?Ë≥áÊ?

						% Handover Call‰æÜÊãøRB
						temp_idx_UEcnct_TST = idx_UEcnct_TST(idx_UE); % ?´Â??ÑÔ?‰æÜÁ??ÑÂ??™Ë£°handover?∞Âì™Ë£?
						[BS_RB_table, BS_RB_who_used, UE_RB_used, idx_UEcnct_TST(idx_UE), UE_Throughput(idx_UE), Dis_Handover_Reason] = Non_CoMP_HandoverCall_take_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
										                                                                                                                              idx_UE, idx_UEcnct_TST(idx_UE), idx_trgt, UE_Throughput(idx_UE), GBR, BW_PRB);
						% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);

						if idx_UEcnct_TST(idx_UE) == idx_trgt
							% !!!!!!!!!!?êÂ?Handvoer?∞Target Cell!!!!!!!!!!
							% ---------------- %
							% HandoverÊ¨°Êï∏Ë®àÁ? %
							% ---------------- %
							n_HO_UE_TST(idx_UE)   = n_HO_UE_TST(idx_UE)   + 1;
							n_HO_BS_TST(idx_trgt) = n_HO_BS_TST(idx_trgt) + 1;	% Only for target cell

							% ----------------------------------- %
							% ?ãHandover?ØÂ?‰ª?∫ºCell?õÂà∞‰ª?∫ºCell  %
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
							% Ë®òÈ?Ë©≤UE?®Ë©≤?ÇÈ?ÈªûÊòØ?¶Âü∑Ë°å‰?Handover  %
							% ------------------------------------- %
							logical_HO(idx_UE) = 1;	% Handover success.
							Dis_Connect_Reason = 0; % ?™Ë??ØHnadover?êÂ?ÔºåDis_Connect_Reason‰∏??= 0 

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

							% HandoverÂ§±Ê?‰∫ÜÔ??ãÊòØHandoverË™∞Ë?Â§±Ê?ÔºåÈòø?∫‰?È∫ºÂ§±?óÔ?Ë®àÈ?‰∏ã‰?
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
							% Ë®òÈ?Ë©≤UE?®Ë©≤?ÇÈ?ÈªûÊòØ?¶Âü∑Ë°å‰?Handover  %
							% ------------------------------------- %
							logical_HO(idx_UE) = 0;	% Handover fail
						end
						% end
					end		
				else
					% Ê≤íÊ?Handover !!!
					logical_HO(idx_UE) = 0;

					% TTT Reset
					timer_TTT_TST(idx_UE) = t_TTT;
				end
				% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);

                % ----------------------------------------------------------- %
				% Â¶ÇÊ?(1)Ê≤íÊ??éA3 Event               __\  Â∞±Ê?Ëµ∞‰ª•‰∏ãÁ?ÊµÅÁ?   %
				%     (2)?é‰?‰ΩÜÊòØTarget CellÊ≤íÊ?Ë≥áÊ?    /	                  %
				% ----------------------------------------------------------- %			
				if logical_HO(idx_UE) == 0

					% ------------------------------------------------------ %
					% Â¶ÇÊ?Throughput < GBRÔºåÂ?‰æÜÊ??õÁ?ÔºåÈ?Ë£°Ê≥®?è‰?ÂÆöË??àÊ?   %
					% ------------------------------------------------------ %
					if UE_Throughput(idx_UE) < GBR
						if idx_UEcnct_TST(idx_UE) <= n_MC
							%  ?ãËÉΩ‰∏çËÉΩ?õÂ?RB ‰ΩçÁΩÆ 					
							if (isempty(find(UE_RB_used(idx_UE,:) == 1)) == 0) && (isempty(find(BS_RB_table(idx_UEcnct_TST(idx_UE),:) == 0)) == 0)
								[BS_RB_table, BS_RB_who_used, UE_RB_used, UE_Throughput(idx_UE)] = Non_CoMP_Serving_change_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
									                                                                                          idx_UE, idx_UEcnct_TST(idx_UE), UE_Throughput(idx_UE), GBR, BW_PRB);						                                                                                          
							end
						else
							%  ?ãËÉΩ‰∏çËÉΩ?õÂ?RB ‰ΩçÁΩÆ 					
							if (isempty(find(UE_RB_used(idx_UE, 1:Pico_part) == 1)) == 0) && (isempty(find(BS_RB_table(idx_UEcnct_TST(idx_UE),1:Pico_part) == 0)) == 0)
								[BS_RB_table, BS_RB_who_used, UE_RB_used, UE_Throughput(idx_UE)] = Non_CoMP_Serving_change_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
									                                                                                          idx_UE, idx_UEcnct_TST(idx_UE), UE_Throughput(idx_UE), GBR, BW_PRB);		                                                                                          
							end
						end

						% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);
					end

					% ------------------------------------ %
					% Â¶ÇÊ?Throughput >= GBRÔºåÁ??Ω‰??Ω‰?RB  %
					% ------------------------------------ %
					if UE_Throughput(idx_UE) >= GBR
						% ?äÈ†ªË≠úÊ???= 0?ÑRB‰∏üÊ?ÔºåÂ??úÈ??Ø‰ª•?ç‰?ÔºåÈÇ£Â∞±ÁπºÁ∫å‰?
						[BS_RB_table, BS_RB_who_used, UE_RB_used, UE_Throughput(idx_UE)] = Non_CoMP_throw_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
																										     idx_UE, idx_UEcnct_TST(idx_UE), GBR, BW_PRB);

						% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);
					else
						% SorryÔºåÂ??ú‰??ÑTarget?ØMacroÔºåÈÇ£‰Ω†Âè™?ΩÈ??™Â∑±‰∫?
						if idx_trgt <= n_MC
							[BS_RB_table, BS_RB_who_used, UE_RB_used, UE_Throughput(idx_UE), Dis_Connect_Reason] = Non_CoMP_take_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
																																	idx_UE, idx_UEcnct_TST(idx_UE), UE_Throughput(idx_UE), GBR, BW_PRB);	
							
							% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);

						% OK! Target?ØPicoÔºå‰??Ø‰ª•?´‰??öÈ?‰∫?
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

							% Pico?öÂ?Dynamic Resource Scheduling ?ºÁèæQoS?ÑÊòØ‰∏çÂ?ÔºåÂ∞±?ãÁ??Ω‰??ΩÂ?CoMP
							if UE_Throughput(idx_UE) < GBR
								[BS_RB_table, BS_RB_who_used, UE_RB_used, UE_Throughput(idx_UE), Dis_Connect_Reason] = Non_CoMP_take_RB(n_MC, n_PC, BS_RB_table, BS_RB_who_used, UE_RB_used, AMP_Noise, n_ttoffered, Pico_part, RsrpBS_Watt, ...
																																		idx_UE, idx_UEcnct_TST(idx_UE), UE_Throughput(idx_UE), GBR, BW_PRB);
									
								% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);
							end
						end						
					end	

					% ----------------------------------------------------------------- %
					% Á∏ΩÊñºË®???¢Ô?Throughput?âÈ?QoSÔºåÂ∞±?ØOK?¶Ô?Â¶ÇÊ?‰∏çokÂ∞±‰??ÉÈ?‰æÜÈ?‰∫?  %
					% ----------------------------------------------------------------- %
					if UE_Throughput(idx_UE) >= GBR
						Dis_Connect_Reason = 0;
					end
				end 


				% ---------------------------------- %
				% Ë®àÁ?UE Call Drop and BS Call Drop  %
				% ---------------------------------- %
				if Dis_Connect_Reason == 0          % ?ÉÈ?‰æÜÈ?‰ª?°® (1)UE handover?êÂ? (2)Ê≤íÊ?handover or handoverÂ§±Ê?Ôºå‰??ØUE?êÂ????Serving  Cell

					% Dropping timer ?çÁΩÆ??1sec					
					timer_Drop_OngoingCall_NoRB(idx_UE)      = t_T310;
					timer_Drop_OngoingCall_RBNotGood(idx_UE) = t_T310;

					% ?ÑÂ?
					Dis_Connect_Reason = 0;
				else
					if Dis_Connect_Reason == 1      % ?ÉÈ?‰æÜÈ?Ë£°Â∞±?? (1)?æServing CellË¶ÅË?Ê∫êÔ?Serving CellË™™Ë?Ê∫êÊ?‰∫?
						if timer_Drop_OngoingCall_NoRB(idx_UE) <= t_T310 && timer_Drop_OngoingCall_NoRB(idx_UE) > 0
							timer_Drop_OngoingCall_NoRB(idx_UE) = timer_Drop_OngoingCall_NoRB(idx_UE) - t_d;
							if timer_Drop_OngoingCall_NoRB(idx_UE) < 1e-5	% [SPECIAL CASE]
								timer_Drop_OngoingCall_NoRB(idx_UE) = 0;	% [SPECIAL CASE]
							end 

							% ?ÑÂ?
							Dis_Connect_Reason = 0;

						elseif timer_Drop_OngoingCall_NoRB(idx_UE) == 0

							% DropË®ò‰?‰∏??
							n_Drop_UE = n_Drop_UE + 1;

							% Ë©≤UE?†ÁÇ∫Cell?ÑË?Ê∫ê‰?Â§†Ë¢´?æÊ?						
							CDR_BS(idx_UEcnct_TST(idx_UE)) = CDR_BS(idx_UEcnct_TST(idx_UE)) + 1;

							% ?ãUE?ØË¢´Macro?ÑÊòØPicoË™™Ë?Ê∫ê‰?Â§†Ô??åÊ?‰Ω†Êñ∑?âÁ?
							if idx_UEcnct_TST(idx_UE) <= n_MC
								Drop_OngoingCall_NoRB_Macro = Drop_OngoingCall_NoRB_Macro + 1;								
							else
								Drop_OngoingCall_NoRB_Pico  = Drop_OngoingCall_NoRB_Pico + 1;
							end

							% ?äRB?ÑÁµ¶Serving Cell
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
							idx_UEcnct_TST(idx_UE) = 0; % ÁµêÊ????
							UE_Throughput(idx_UE)  = 0; % UE?ÑthroughputÊ≠∏Èõ∂

							% Dropping timer ?çÁΩÆ??1sec
							timer_Drop_OngoingCall_NoRB(idx_UE)      = t_T310;
							timer_Drop_OngoingCall_RBNotGood(idx_UE) = t_T310;

							% ?ÑÂ?
							Dis_Connect_Reason = 0;
						end

					elseif Dis_Connect_Reason == 2  % ?ÉÈ?‰æÜÈ?Ë£°Â∞±?? (1)?æServing CellË¶ÅË?Ê∫êÔ??ºÁèæServing Cell?ÑRBË≥™È?‰∏çÂ?

						if timer_Drop_OngoingCall_RBNotGood(idx_UE) <= t_T310 && timer_Drop_OngoingCall_RBNotGood(idx_UE) > 0
							% ?íÊï∏Drop timer 
							timer_Drop_OngoingCall_RBNotGood(idx_UE) = timer_Drop_OngoingCall_RBNotGood(idx_UE) - t_d;
							if timer_Drop_OngoingCall_RBNotGood(idx_UE) < 1e-5	% [SPECIAL CASE]
								timer_Drop_OngoingCall_RBNotGood(idx_UE) = 0;		% [SPECIAL CASE]
							end 

							% ?ÑÂ?
							Dis_Connect_Reason = 0;

						elseif timer_Drop_OngoingCall_RBNotGood(idx_UE) == 0

							% DropË®ò‰?‰∏??
							n_Drop_UE = n_Drop_UE + 1;

							% Ë©≤Ongoing Call?†ÁÇ∫?ãÂà∞?ÑRB‰πãÈ†ªË≠úÊ??áÈÉΩÂ§™‰?‰∫?  ‰∏¶‰??ÅÁ?1Áß? ??ª•Ë¢´Ê?Áµ?
							CDR_BS(idx_UEcnct_TST(idx_UE))  = CDR_BS(idx_UEcnct_TST(idx_UE)) + 1;

							% ?ôË£°?ØÂ??∫UE?™Â∑±Ëµ∞Â§™?†Ô?‰ΩÜÂú®‰πãÈ?Â¶ÇÊ??âÊÉ≥Handover‰ΩÜË¢´?íÁ?ÔºåÂ??¥‰?Ëµ∞Â§™?†Ê?‰∫∫Ê??ôÔ??ô‰?Ë¶ÅÁ?‰∏??							
							if idx_UEcnct_TST(idx_UE) <= n_MC
								Drop_OngoingCall_RBNotGood_Macro = Drop_OngoingCall_RBNotGood_Macro + 1;
							else
								Drop_OngoingCall_RBNotGood_Pico  = Drop_OngoingCall_RBNotGood_Pico + 1;
							end		

							% ?äRB?ÑÁµ¶Serving Cell
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
							idx_UEcnct_TST(idx_UE) = 0; % ÁµêÊ????
							UE_Throughput(idx_UE)  = 0; % UE?ÑthroughputÊ≠∏Èõ∂

							% Dropping timer ?çÁΩÆ??1sec
							timer_Drop_OngoingCall_NoRB(idx_UE)      = t_T310;
							timer_Drop_OngoingCall_RBNotGood(idx_UE) = t_T310;

							% ?ÑÂ?
							Dis_Connect_Reason = 0;
						end						
					end
				end
				% Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS);

				% --------------------------------- %
				% ‰∏ªË?Áµ±Ë?: Ê™¢Êü•Ping-Pong?âÊ??âÁôº??%
				% --------------------------------- %
				if logical_HO(idx_UE) == 1

					% ---------------------------------------------------- %
					% Ë®àÁ?Ping-Pong Effect?ØÂê¶?âÁôº?üÔ?Ë∑üPerformance ?ÑË?ÁÆ?%
					% ?âÂÖ©?ãKPI: (1) 1ÁßíÂÖß?ºÁ?Á¢∞Ê?   (2) 5ÁßíÂÖß?ºÁ?Á¢∞Ê?     %
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

					% ?ÑÂ?
					logical_HO(idx_UE) = 0;
				else
					if UE_CoMP_orNOT(idx_UE) == 1 % Â¶ÇÊ??ãÂ??∑Ë?CoMPÔºåÈ??ÇPing-pong  effect ‰∏çÂ???				
						state_PPE_TST(idx_UE,:) = 0;
					end
				end
			end	
		end

		% ========================================================================================================================== %
		% ‰ª•‰?Á≠âÁ??®‰?ÁÆóCell?ÑCBR                                                                                                    % 
		% CellËßíÂ∫¶?ÑCBR: ?•UEÊ≤íÊ?????êÊ??ÑÈ?Á∑öÁõÆÊ®ôÔ??çË??∞Ê?ÂæåUEËÆäÂ?Ê≤íÊ?Serving   CellÔºåÈ??ÇÈ??ãBlock CallÂ∞±Ê?ÁÆóÂú®?êÊ??ÑÈ?Á∑öCell‰∏? %
		% CellËßíÂ∫¶?ÑCDR: ?•UE?¨Ë∫´?âServing CellÔºå‰??∞Ê?ÂæåUE?¢È?Serving  CellÔºåÈ?Á≠ÜCall DropÂ∞±Á??®Serving Cell‰∏?                     %
		% ========================================================================================================================== %
		if temp_CoMP_state == 0
			if UE_CoMP_orNOT(idx_UE) == 0

				% ?üÊú¨Ê≤íÂ?CoMPÔºåÂ?‰æÜ‰?Ê≤íÊ??öCoMP				
				if idx_UEprey_TST(idx_UE) ~= 0     % Ë©≤UE?ØÊ??êÊ??ÑÈ?Á∑öÁõÆÊ®ôÔ?Ê≠?∏∏?ΩÊ???
					if idx_UEcnct_TST(idx_UE) == 0 % UE?âÈ??üÁõÆÊ®ôÔ?‰ΩÜÊ?ÂæåÂçªÊ≤íÊ?Serving  Cell
						n_DeadUE_BS(idx_UEprey_TST(idx_UE)) = n_DeadUE_BS(idx_UEprey_TST(idx_UE)) + 1;

					else % idx_UEcnct_TST(idx_UE) ~= 0
						n_LiveUE_BS(idx_UEcnct_TST(idx_UE)) = n_LiveUE_BS(idx_UEcnct_TST(idx_UE)) + 1;
					end
				else
					fprintf('BS_CBR calculation BUG\n');
				end	
			else
				% ?üÊú¨Ê≤íÂ?CoMPÔºåÂ?‰æÜÊ??öCoMP	
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

    % ÁµêÊ?Loop 2(UE?ÑLoop)
    % ======================== %
    % ÁÆóMacroË∑üPico?ÑÊ??ô‰∫∫?? %
    % ======================== %
    for idx_UE = 1:1:n_UE  
		Macro_Serving_Num_change(round(idx_t/t_d), 1)        = length(find(0 < idx_UEcnct_TST & idx_UEcnct_TST <= n_MC));
		Pico_NonCoMP_Serving_Num_change(round(idx_t/t_d), 1) = length(find(idx_UEcnct_TST > n_MC));
		Pico_CoMP_Serving_Num_change(round(idx_t/t_d), 1)    = length(nonzeros(UE_CoMP_orNOT)); 
    end

    % ============================== %
    % ÁÆóBS??Ωø?®Á?Resource Block?∏È? %
    % ============================== %
    for idx_BS = 1:1:n_BS
    	if idx_BS <= n_MC
    		BS_RB_consumption(idx_BS) = BS_RB_consumption(idx_BS) + length(nonzeros(BS_RB_table(idx_BS, :)));
    	else
    		BS_RB_consumption(idx_BS) = BS_RB_consumption(idx_BS) + length(nonzeros(BS_RB_table(idx_BS, 1:Pico_part)));
    	end    	
    end

	% ======================================== %
	% ÁÆóUE?ÑCall Block Rate and Call Drop Rate %
	% ======================================== %
	% UE Call Block Rate
	UE_CBR = UE_CBR + (n_Block_UE);

	% UE Call Drop Rate 
	Average_UE_CDR = Average_UE_CDR + n_Drop_UE*(UE_surviving/n_UE);
	
	UE_CDR  = UE_CDR + (n_Drop_UE);

	% UEÂπ≥Â?Â≠òÊ¥ª‰∫∫Êï∏	
	UE_survive = UE_survive + (n_UE - n_Block_UE - n_Drop_UE);
	
	% ?çÁΩÆ
	n_Block_UE  = 0;	
	n_Drop_UE   = 0;

	% ======================================== %
    % ÁÆóBS?ÑCall Block Rate and Call Drop Rate %
	% ======================================== %
	for idx_BS = 1:n_BS
		% BS Call Block Rate
		if n_DeadUE_BS(idx_BS) == 0 && n_LiveUE_BS(idx_BS) == 0    % Â¶ÇÊ?Ê≤íÊ?‰∫∫Ê?Ë©≤BS ?∂ÁõÆÊ®ôÔ?Ë©≤BS ?ÑCBR = 0
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

	% ?çÁΩÆ
	n_LiveUE_BS(1,:) = 0;
	n_DeadUE_BS(1,:) = 0;
	n_HO_BS_TST(1,:) = 0;
	CDR_BS(1,:)      = 0;

	% ----------- %
	% ?¥Êñ∞Loading %
	% ----------- %
	[Load_TST] = Update_Loading(n_BS, n_MC, BS_RB_table, n_ttoffered, Pico_part);	

	% ================================================ % % ====================================== %
	%          -          -------        --            % %   --------    --------      -------    %
	%          |          |      )      /  \           % %   |          /        \    /           %
	%          |          |------      /----\          % %   |------|  |        \ |  |            %
	%          |          |           /      \         % %   |          \        X    \           %
	%          -------    -          -        -        % %   -           -------- \    -------    %
	% ================================================ % % ====================================== %	
	% Loop 4: ?∫Âú∞?∞È?ÂßãÂ?Fuzzy Q (???Á¥∞Ë??ÑCIO, Loading, CBR, CDR)
	if (idx_t == t_start || rem(idx_t, FQ_BS_LI_TST) <= 0.01)
		for idx_BS = 1:n_BS			
			% Fuzzifier
			DoM_CIO_TSTc(idx_BS,:)      = FQc1_Fuzzifier(CIO_TST(idx_BS), 'C');  % CIO?Ñdegree of membership
			DoM_Load_TSTc(idx_BS,:)     = FQc1_Fuzzifier(Load_TST(idx_BS),'L');  % Loading?Ñdegree of membership
			DoT_Rule_New_TSTc(idx_BS,:) = FQc2_DegreeOfTruth(DoM_CIO_TSTc(idx_BS,:), DoM_Load_TSTc(idx_BS,:),'D');  %ÁÆódegree of truth?ÑÊñπÊ≥ïD (?∏‰?)

			if (idx_t ~= t_start)
				% ÁÆóQ Bonus
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
			%?ôÈ?GlobalAct?ØÁï∂‰ΩúË??ñÈ?ÔºåË??®Â?‰∏äÂ?‰∏?¨°?ÑCIOÔºåÁï∂‰Ωú‰?‰∏?¨°?üÊ≠£‰ΩøÁî®?ÑCIO    (?ÆÁ??ØÁÇ∫‰∫Ü‰?ËÆìCIOËÆäÂ?Â§™Â§ß) 
			% if     (CIO_TST(idx_BS) + GlobalAct_TSTc(idx_BS) < -5)
			% 	CIO_TST(idx_BS) = -5;
			% elseif (CIO_TST(idx_BS) + GlobalAct_TSTc(idx_BS) > 5)
			% 	CIO_TST(idx_BS) = 5;
			% else
			% 	CIO_TST(idx_BS) = CIO_TST(idx_BS) + GlobalAct_TSTc(idx_BS);
			% end
			CIO_TST(idx_BS) = GlobalAct_TSTc(idx_BS);

			% Ë®àÁ?Q-function 
			Q_fx_new_TSTc(idx_BS) = FQc4_Qfunction(DoT_Rule_New_TSTc(idx_BS,:), Q_Table_TSTc(:,:,idx_BS), ...
																	idx_subAct_choosed_new_TSTc(idx_BS,:));			
		end	
		% Recording for the different iteration of 'Q-function'
		Q_fx_old_TSTc               = Q_fx_new_TSTc;
		idx_subAct_choosed_old_TSTc = idx_subAct_choosed_new_TSTc;
		DoT_Rule_Old_TSTc           = DoT_Rule_New_TSTc;

	end
	% ÁµêÊ? Loop 4

end

toc
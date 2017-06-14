%% 2017.01.17 PM 07:30 TST / tToS by d_B2B (max V: 120 km/hr; D: DIRC Turn)
clc, clear, close all
load('ttSimuT');

%% Simulation Parameters Setting

MTS_1s = 1;		% [sec]														% Minimum Time-of-Stay from 3GPP Standard [sec]
MTS_5s = 5;		% [sec]
TST_HD = 0;

% ===/* Time Slot */===
t_d        = 0.1; % ONE MILLISECOND % it's UNIT: sec		% [[[ADJ]]]     % Simulation time duration [sec]
t_start    = t_d;
t_simu     = (t_d/t_d) * ttSimuT; % it's UNIT: sec				% [[[ADJ]]]     % Total Simulation Time [sec]
n_Measured = t_simu/t_d;												    % # measurements [# number of times]

% ===/* Base Station */===
% [Configuration/Deployment]
rectEdge = 4763;															% [Meter]
load('MC_lct_4sq');																% Load MC Deployment
% PC_lct_4sq = PPP_PC(rectEdge, n_PC, MC_lct_4sq);									% Load PC Deployment
load('PC_lct_4sq_n500m000');
BS_lct = [MC_lct_4sq ; PC_lct_4sq_n500m000];													% Integrate MC & PC Deployment
% [Power/EIRP]
P_MC_dBm    =  46;															% MacroCell total TX power [dBm]
P_PC_dBm    =  30;															% PicoCell total TX power [dBm]
P_minRsrpRQ = -100; % [dBm]                          		% [[[ADJ]]]     % Minimum Required power to provide services 
																			% sufficiently for UE accessing to BS [dBm]
																			% Requirement for accessing a particular cell
MACROCELL_RADIUS = (10^((P_MC_dBm-P_minRsrpRQ-128.1)/37.6))*1e+3;
PICOCELL_RADIUS  = (10^((P_PC_dBm-P_minRsrpRQ-140.7)/36.7))*1e+3;

n_MC = length(MC_lct_4sq);			% 2017.01.21
n_PC = length(PC_lct_4sq_n500m000);	% 2017.01.21

% [Number]
n_BS = n_MC + n_PC;															% The number of whole Base Stations
% ===/* Resource Parameter */===
sys_BW      = 5   * 1e+6;									% [[[ADJ]]]		% System Bandwidth is 5MHz
BW_PRB      = 180 * 1e+3;													% LTE PRB bandwidth is 180kHz
GBR         = 256 * 1024;													% Guaranteed Bit Rate is 256 kbit/sec
n_ttoffered = 25;											% [[[ADJ]]]     % #max cnct per BS i.e., PRB
																			% B E N: Max #PRB under BW = 10 Mhz per slot(0.5ms)
SINR_th     = -7;		% 2016.12.05										% Replace the fucking Qout (= -8 dB) n Forget about GBR.

% ===/* Channel */===
Gamma_MC            = 3.76;
Gamma_PC            = 3.67;
P_N_dBmHz           = -174; % [dBm/Hz]										% White Noise Power Density [dBm/Hz]
LTE_NoiseFloor_dBm  = P_N_dBmHz + 10*log10(BW_PRB);							% Noise Floor approximate -121.45 dBm
LTE_NoiseFloor_watt = 10^((LTE_NoiseFloor_dBm - 30)/10);					% Noise Floor approximate 7.1614 * 1e+16 watt
AMP_Noise           = LTE_NoiseFloor_watt * randn(1);		% [[[ADJ]]] 

% ===/* User Mobility */===
% UE_lct_n100 = PPP_UE(rectEdge, n_UE);											% (DGNI). UE_lct_n100 is n_UE x 2
load('UE_lct_n100');
n_UE = length(UE_lct_n100);			% 2017.01.21

% ===/* Handover Setting */===
HHM    = 3;	  % [dB]										% [[[ADJ]]]     % Handover Hysteresis Margin [dB]
t_TTT  = 0.1; % [sec]										% [[[ADJ]]]     % NYC
t_T310 = 1;   % [sec]

% ===/* Q-Learning */===
n_FuzzyDegree =  5;
n_Rule        = 25;
n_Act         =  5;

FQ_BS_DF_TST = 0.8;											% [[[INH]]]     % Discount Factor
FQ_BS_LR_TST = 0.2;											% [[[INH]]]     % Learning Rate
FQ_BS_LI_TST = 5  ;											% [[[INH]]]     % Learning Interval is 5 [sec]

% Display Beginning System Model
figure(), hold on;
plot(MC_lct_4sq(:,1), MC_lct_4sq(:,2), 'sk', 'MarkerFaceColor', 'k','MarkerSize',10);
plot(PC_lct_4sq_n500m000(:,1), PC_lct_4sq_n500m000(:,2), '^k', 'MarkerFaceColor', 'g','MarkerSize', 5);
plot(UE_lct_n100(:,1), UE_lct_n100(:,2), '*', 'Color',[0.8 0.0 0.2],'MarkerSize',5);
plot([+1,-1,-1,+1,+1]*rectEdge/2, [+1,+1,-1,-1,+1]*rectEdge/2, 'Color', [0.3 0.3 0.0]);
title('Beginning');
legend('Macrocell','Picocell','User');
set(gcf,'numbertitle','off');
set(gcf,'name','Environment');

%% METRICs METRICs METRICs METRICs METRICs METRICs 
% MC Setting
dist_MC    = zeros(1, n_MC);										% dist. btwn UE and MC
RsrpMC_dBm = zeros(1, n_MC);										% RSRP from MC
RsrpMC_dB  = zeros(1, n_MC);
idx_RsrpMC = 0;														% Just Initialization
% SC setting
dist_PC    = zeros(1, n_PC);										% dist. btwn PC and UE
RsrpPC_dBm = zeros(1, n_PC);										% RSRP from PC
RsrpPC_dB  = zeros(1, n_PC);
idx_RsrpPC = 0;														% Just Initialization
% UE setting
UE_v              = zeros(n_UE, 2);									% User's velocities on x-axis & y-axis respectively
UE_timer_RWP1step = zeros(n_UE, 1);									% The Timer of RandomWayPoint for changing DIRC
load('seedSpeedMDS'); 	% 1000 x 6666									% 2016.11.17
load('seedAngleDEG');   % 1000 x 6666								% 2016.11.24
load('seedEachStep'); 	% 1000 x 6666									% 2016.11.17
idx_SEED          = ones(n_UE, 1);	% seed index						% 2016.11.17
INT_SSL           = zeros(n_UE,1);	% Interference proposed by SSL

% ============================= %	% ================================== %
%   -------   -----   -------   %	%   ------  ------   ------  -   --	 %
%      |     (           |      %	%   |     ) |     \  |     )  \ /	 %
%      |      -----      |      %	%   ------  |      | ------    V 	 %
%      |           )     |      %	%   |     ) |     /  |     \   |	 %
%      -      -----      -      %	%   ------  ------   -     -   -	 %
% ============================= %	% ================================== %
% BS BS BS BS BS BS BS BS BS BS BS BS BS BS BS BS BS BS BS BS BS BS
n_RBoffer_TST   = zeros(1, n_BS);									% The number of RB a BS offer to UEs inside it
Load_TST        = zeros(1, n_BS);
CIO_TST         = zeros(1, n_BS);

n_HO_BS_TST     = zeros(1, n_BS);	% Only for target cell			% KPI: Handover Number of BS

who_Hunters_BS  = zeros(n_BS,n_UE);		% 2017.01.04	% Important that n_BS x n_UE !!!!!!!!
n_DeadUE_BS     = zeros(1, n_BS);		% 2017.01.04
n_LiveUE_BS     = zeros(1, n_BS);		% 2017.01.04
CBR_BS_TST 		= zeros(1, n_BS);									% KPI: Call Block Rate

n_Drop_BS_TST	= zeros(1, n_BS);									% 2017.01.04
CDR_BS_TST 		= zeros(1, n_BS);									% KPI: Outage Probability 2016.11.15 -> Call Drop Rate 2017.01.04

% UE UE UE UE UE UE UE UE UE UE UE UE UE UE UE UE UE UE UE UE UE UE
crntRSRP_TST    = zeros(n_UE, 1);		% [dBm]
crntSINR_TST    = zeros(n_UE, 1);		% [dB]

idx_UEcnct_TST  = zeros(1, n_UE);
idx_UEprey_TST  = zeros(1, n_UE);		% 2017.01.04

logical_Load    = zeros(n_UE, n_BS);
logical_HO      = zeros(1, n_UE);								% '1' if idx_UEcnct just changed; '0' if idx_UEcnct is same.
n_RBneed_TST 	= zeros(n_UE, 2);								% Present RB a UE needed and Previous RB a UE needed.
n_RB_ACQU_TST   = zeros(n_UE, 1);								% Real obtain from base station.

timer_Arrive    = zeros(1, n_UE);	  % 2017.01.04

INT_if_HO         = zeros(n_UE, 1);   % Measured Interference when TTT expired % 2016.12.29
crntSINR_ifHO_TST = zeros(n_UE, 1);   % Measured SINR when TTT expired % 2016.12.29
n_RBneed_ifHO_TST = zeros(n_UE, 1);   % 2016.12.29
logical_ifHO_Load = zeros(n_UE,n_BS); % 2016.12.29

timer_TTT_TST  = zeros(1, n_UE) + t_TTT;
n_HO_UE_TST    = zeros(1, n_UE);								% KPI: Handover Number of UE
n_HO_M2M       = 0;
n_HO_M2P       = 0;
n_HO_P2M       = 0;
n_HO_P2P       = 0;

state_PPE_TST  = zeros(n_UE, 5);
n_PPE_1s_TST   = zeros(1, n_UE);								% KPI: Ping-Pong Number
n_PPE_5s_TST   = zeros(1, n_UE);								% KPI: Ping-Pong Number
PPR_5s_TST     = zeros(1, n_UE);								% 2016.12.15

n_DeadUE_UE     = 0;				% 2017.01.04
n_LiveUE_UE     = 0;				% 2017.01.04
CBR_UE_TST      = 0;				% 2017.01.05	% Average Number Already about all Users.

timer_Drop_TST  = zeros(1, n_UE) + t_T310;						% Timer to count T310
n_Drop_UE_TST   = zeros(1, n_UE);								% 2017.01.04
CDR_UE_TST      = zeros(1, n_UE);								% KPI: Outage Probability 2016.11.15 -> Call Drop Rate 2017.01.04

DropReason           = zeros(1,n_UE);	% 2016.12.27	Drop Reason Range = [1,2,3,4] 
													%   1 : RB not enough
													%   2 : ToS limit
													%   3 : Connecting
													%   4 : TTT countdown

DropReason1_M2M___RB = zeros(1,n_UE);	% 2017.01.14	in A3, pass TST, but no RB 	% Drop Reason = 1
DropReason2_M2P___RB = zeros(1,n_UE);	% 2017.01.14								% Drop Reason = 1
DropReason3_P2M___RB = zeros(1,n_UE);	% 2017.01.14								% Drop Reason = 1
DropReason4_P2P___RB = zeros(1,n_UE);	% 2017.01.14								% Drop Reason = 1

DropReason5_M2M__ToS = zeros(1,n_UE);	% 2017.01.14	in A3, but TST resist		% Drop Reason = 2
DropReason6_M2P__ToS = zeros(1,n_UE);	% 2017.01.14								% Drop Reason = 2
DropReason7_P2M__ToS = zeros(1,n_UE);	% 2017.01.14								% Drop Reason = 2
DropReason8_P2P__ToS = zeros(1,n_UE);	% 2017.01.14								% Drop Reason = 2

DropReason9_MMM_Conn = zeros(1,n_UE);	% 2017.01.14	Just Connect				% Drop Reason = 3
DropReasonX_PPP_Conn = zeros(1,n_UE);	% 2017.01.14								% Drop Reason = 3

DropReasonY_M2M__TTT = zeros(1,n_UE);	% 2017.01.17	in TTT 						% Drop Reason = 4
DropReasonY_M2P__TTT = zeros(1,n_UE);	% 2017.01.17								% Drop Reason = 4
DropReasonY_P2M__TTT = zeros(1,n_UE);	% 2017.01.17								% Drop Reason = 4
DropReasonY_P2P__TTT = zeros(1,n_UE);	% 2017.01.17								% Drop Reason = 4

% UE TST UE TST UE TST UE TST UE TST UE TST UE TST UE TST UE TST UE
LPA_P1s = zeros(1,n_UE);	% ServCell
LPA_P2s = zeros(1,n_UE);
LPA_P3s = zeros(1,n_UE);
LPA_P1t = zeros(1,n_UE);	% TrgtCell
LPA_P2t = zeros(1,n_UE);
LPA_P3t = zeros(1,n_UE);
LPA_Ps  = 10^((P_minRsrpRQ-30)/10);	% [Watt]
LPA_t1  = zeros(1,n_UE);
LPA_t2  = zeros(1,n_UE);
LPA_t3  = zeros(1,n_UE);
LPA_idx_pkt      = zeros(1,n_UE);
LPA_pred_trgtToS = zeros(1,n_UE);
% SSL proposal for Case 1

	% =============================== %
	%   ------    ------    -         %
	%  |         |          |         %
	%   ------    ------    |         %
	%         |         |   |         %
	%   ------    ------    --------  %
	% =============================== %
	d_B2B = zeros(n_UE,4);	% d_B2B(idx_UE,1) = idx_trgt; d_B2B(idx_UE,2) = idx_crnt; d_B2B(idx_UE,3) = DIST btwn Boundary & trgtBS;  

% =============================== %
%  -------   -------    -------   %
%  |         |      )   |      )  %
%  |-----    |------    |------   %
%  |         |     \    |     \   %
%  -------   -      -   -      -  %
% =============================== %
GPSinTST_trgtToS = zeros(1,n_UE);

% FQ BS FQ BS FQ BS FQ BS FQ BS FQ BS FQ BS FQ BS FQ BS FQ BS FQ BS
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

% ============================================= %
%      ------   ------   ------   --    --      %
%      |     )  |     )  |        | \  / |      %
%      |-----   |-----   |----|   |  \/  |      %
%      |        |    \   |        |      |      %
%      -        -     -  -        -      -      %
% ============================================= %
% BS PRFM BS PRFM BS PRFM BS PRFM BS PRFM
PRFM_TST_BS_CBR   = zeros(1, n_Measured);
PRFM_TST_BS_CDR   = zeros(1, n_Measured);
PRFM_TST_BS_QoS   = zeros(1, n_Measured);

% UE PRFM UE PRFM UE PRFM UE PRFM UE PRFM
PRFM_TST_UE_nHO   = zeros(1, n_Measured);
PRFM_TST_UE_CBR   = zeros(1, n_Measured);	% 2017.01.05
PRFM_TST_UE_CDR   = zeros(1, n_Measured);
PRFM_TST_UE_1snPP = zeros(1, n_Measured);
PRFM_TST_UE_5snPP = zeros(1, n_Measured);
PRFM_TST_UE_5sPPR = zeros(1, n_Measured);

% LB
LB_Idle           = zeros(1, n_Measured);	% 2017.01.19
LB___PC           = zeros(1, n_Measured);	% 2017.01.19
LB___MC           = zeros(1, n_Measured);	% 2017.01.19

% Counter
PRFM_CTR          = 1;

%% SIMULATION START
% ======================================================== %
%       -----   -------      --      ------    -------     %
%      (           |        /  \     |     )      |        %
%       -----      |       /----\    |-----       |        %   
%            )     |      /      \   |     \      |        %
%       -----      -     -        -  -      -     -        %
% ======================================================== %
tic
% Loop 1: Time
for idx_t = t_start : t_d : t_simu											% [sec] % 0.001 sec per loop
	if (rem(idx_t,t_simu/100) < 1e-3)
		fprintf(' %.3f sec\n', idx_t)
	end

	AMP_Noise  = LTE_NoiseFloor_watt * randn(1);

	% Loop 2: Users
	for idx_UE = 1:n_UE
		for mc = 1:n_MC
			dist_MC(mc)    = norm(UE_lct_n100(idx_UE,:) - MC_lct_4sq(mc,:));			% [meter]
			RsrpMC_dBm(mc) = P_MC_dBm - PLmodel_3GPP(dist_MC(mc), 'M');		% [dBm]
		end
		for pc = 1:n_PC
			dist_PC(pc)    = norm(UE_lct_n100(idx_UE,:) - PC_lct_4sq_n500m000(pc,:));			% [meter]
			RsrpPC_dBm(pc) = P_PC_dBm - PLmodel_3GPP(dist_PC(pc), 'P');		% [dBm]
		end
		RsrpMC_dB   = RsrpMC_dBm - 30;										% [dB] DGNI
		RsrpPC_dB   = RsrpPC_dBm - 30;										% [dB] DGNI
		RsrpBS_dB   = [RsrpMC_dB RsrpPC_dB];								% [dB] DGNI
		RsrpBS_watt = 10.^(RsrpBS_dB/10);									% [Watt] DGNI
		% ===/* Influence by Thermal Noise */=== below
		RsrpBS_watt = (sqrt(RsrpBS_watt) + AMP_Noise).^2;	% With Thermal Noise, no Rayleigh (DGNI) */*/*/*/*/*
		RsrpBS_dB   = 10*log10(RsrpBS_watt);								% [dB] 
		% ===/* Influence by Thermal Noise */=== above
		RsrpBS_dBm  = RsrpBS_dB + 30;

		% === Get Max RSRP of MCs, PCs, BSs ===          
		[maxRsrpMC, idx_RsrpMC] = max(RsrpMC_dBm);                          % [dBm] DGNI
		[maxRsrpPC, idx_RsrpPC] = max(RsrpPC_dBm);                          % [dBm] DGNI

		[maxRsrpBS, idx_RsrpBS] = max(RsrpBS_dBm);                          % [dBm] DGNI
		% trgtRSRP = maxRsrpBS;                                               % Find the max RSRP... (DGNI) [dBm]
		% idx_trgt = idx_RsrpBS;                                              % ...and decide this BS. as Target (DGNI)

		[maxRSRPxCIO_BS, idx_RSRPxCIO_BS] = max(RsrpBS_dBm + CIO_TST);		% Hope it's BUG. 2016.12.29
		idx_trgt                          = idx_RSRPxCIO_BS;				% Hope it's BUG. 2016.12.29
		trgtRSRP                          = RsrpBS_dBm(idx_RSRPxCIO_BS);	% Hope it's BUG. 2016.12.29

		% ================================== %
		%	------  ------  ------ --   --   %
		%	|     ) |     ) |        \ /     %
		%	|-----  ------  -----     V      %
		%	|       |     \ |         |      %
		%	-       -     - ------   ---     %
		% ================================== %
		if     idx_UEcnct_TST(idx_UE) == 0						% 2017.01.04
			idx_UEprey_TST(idx_UE) = idx_trgt;					% 2017.01.04
		elseif idx_UEcnct_TST(idx_UE) ~= 0						% 2017.01.04
			idx_UEprey_TST(idx_UE) = idx_UEcnct_TST(idx_UE);	% 2017.01.04	% May be target, may be served.
		end


		idx_crnt_TST = idx_UEcnct_TST(idx_UE);	% current BS idx that idx_UE connect aka serving BS (DGNI)

		% ================================= %
		%	 -----  ----- --    - ------    %
		%	|         |   | \   | |     )   %
		%	 -----    |   |  \  | ------    %
		%	      |   |   |   \ | |     \   %
		%	 -----  ----- -    -- -     -   %
		% ================================= %
		if (idx_crnt_TST == 0)					% Only happened when simulation just begin 2016.11.14

			n_RBneed_TST(idx_UE,1) = 1;	% 2016.12.29
			crntSINR_TST(idx_UE)   = 0;	% 2017.01.05

		elseif (idx_crnt_TST > n_MC)
			crntRSRP_TST(idx_UE) = P_PC_dBm - PLmodel_3GPP(dist_PC(idx_crnt_TST - n_MC),'P'); 	% [dBm]
			[INT_SSL(idx_UE), logical_Load(idx_UE,:)] = INT_SSL_fx(idx_trgt, idx_crnt_TST, RsrpBS_watt(1,:), Load_TST(1,:), ...
																	logical_Load(idx_UE,:), logical_HO(idx_UE), n_MC, n_PC);
			crntSINR_TST(idx_UE) = (crntRSRP_TST(idx_UE)-30) - 10*log10(INT_SSL(idx_UE) + AMP_Noise^2);	% [dB] 2016.11.15
			n_RBneed_TST(idx_UE,1) = MCS_3GPP36942(crntSINR_TST(idx_UE), GBR, BW_PRB);
		else
			crntRSRP_TST(idx_UE) = P_MC_dBm - PLmodel_3GPP(dist_MC(idx_crnt_TST),'M');			% [dBm]
			[INT_SSL(idx_UE), logical_Load(idx_UE,:)] = INT_SSL_fx(idx_trgt, idx_crnt_TST, RsrpBS_watt(1,:), Load_TST(1,:), ...
																	logical_Load(idx_UE,:), logical_HO(idx_UE), n_MC, n_PC);
			crntSINR_TST(idx_UE) = (crntRSRP_TST(idx_UE)-30) - 10*log10(INT_SSL(idx_UE) + AMP_Noise^2);	% [dB] 2016.11.15
			n_RBneed_TST(idx_UE,1) = MCS_3GPP36942(crntSINR_TST(idx_UE), GBR, BW_PRB);
		end

		% % NEW CALL aka DEAD CALL (Including Waiting User and Arriving User)	% 2017.01.04
		if (idx_crnt_TST == 0)

			% Waiting Users:
			if (timer_Arrive(idx_UE) ~= 0)	% 2017.01.04
				timer_Arrive(idx_UE) = timer_Arrive(idx_UE) - t_d;	% Countdown
				if (timer_Arrive(idx_UE) < t_d)
					timer_Arrive(idx_UE) = 0;
				end

			% Arriving Users:
			elseif (timer_Arrive(idx_UE) == 0)	% 2017.01.04
			
				% Idle State, Would like to Access but Idle
				if (n_RBoffer_TST(idx_trgt) + n_RBneed_TST(idx_UE,1) > n_ttoffered)	% Overload.
					% LIVE or DEAD -> DEAD
					idx_UEcnct_TST(idx_UE)   = 0;	% 2016.11.14	Still Connect 	% 2017.01.04 Still DEAD
					% Cell Loading
					n_RB_ACQU_TST(idx_UE)    = 0;	% 2016.11.25
					Load_TST(idx_trgt)       = n_RBoffer_TST(idx_trgt) / n_ttoffered;
					% Call Block Rate (CBR)	% 2017.01.04

				% Idle State, Would like to Access and Connect
				elseif (n_RBoffer_TST(idx_trgt) + n_RBneed_TST(idx_UE,1) <= n_ttoffered)
					% LIVE or DEAD -> LIVE
					idx_UEcnct_TST(idx_UE)   = idx_trgt;
					% Cell Loading
					n_RBoffer_TST(idx_trgt)  = n_RBoffer_TST(idx_trgt) + n_RBneed_TST(idx_UE,1);
					n_RB_ACQU_TST(idx_UE)    = n_RBneed_TST(idx_UE,1);
					Load_TST(idx_trgt)       = n_RBoffer_TST(idx_trgt) / n_ttoffered;
				end

				% Give it waiting time first, no matter whether it DEAD or LIVE
				while timer_Arrive(idx_UE) == 0			% No matter UE keep dead or live up.
					timer_Arrive(idx_UE) = poissrnd(1);	% 2017.01.05 Not to be ZERO please.
				end

				% ============================= % 
				%   ------   ------   -------   %
				%   |     )  |     )  |         %
				%   |-----   |-----   ------    %	% 2016.10.12 / 2016.11.14 / 2017.01.04
				%   |        |        |         %
				%   -        -        -------   %
				% ============================= %
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

			% ================================== %
			%     -------  -------   -------     %	% 2017.01.05
			%    /         |      )  |      )    %	 % 2017.01.05
			%   |          -------   -------     %	  % 2017.01.05
			%    \         |      )  |     \     %	   % 2017.01.05
			%     -------  -------   -      -    %	    % 2017.01.05
			% ================================== %
			% Call Block Rate (CBR)	[UE]
			if idx_UEcnct_TST(idx_UE) == 0 
				n_DeadUE_UE = n_DeadUE_UE + 1;
			elseif idx_UEcnct_TST(idx_UE) ~= 0
				n_LiveUE_UE = n_LiveUE_UE + 1;
			end

		% % HANDOVER CALL aka LIVE CALL (Including Connecting User and Handover User)	% 2017.01.04
		elseif (idx_crnt_TST ~= 0)
			% ================================================ %
			%      -          -----        --      ------      %
			%      |         /     \      /  \     |     \     %
			%      |        |       |    /----\    |      |    %
			%      |         \     /    /      \   |     /     %
			%      -------    -----    -        -  ------      %
			% ================================================ %
			% idx_UE need less or same RBs than last time
			if (n_RBneed_TST(idx_UE,1) <= n_RBneed_TST(idx_UE,2))
				if (n_RBoffer_TST(idx_crnt_TST) - n_RBneed_TST(idx_UE,2) < 0)
					n_RBoffer_TST(idx_crnt_TST) = n_RBneed_TST(idx_UE,1);
				else
					n_RBoffer_TST(idx_crnt_TST) = n_RBoffer_TST(idx_crnt_TST) - n_RBneed_TST(idx_UE,2) + n_RBneed_TST(idx_UE,1);
				end
				n_RB_ACQU_TST(idx_UE)           = n_RBneed_TST(idx_UE,1);	% 2016.11.25
			% idx_UE need more RBs than last time
			elseif (n_RBneed_TST(idx_UE,1) >  n_RBneed_TST(idx_UE,2))
				if (n_RBoffer_TST(idx_crnt_TST) - n_RBneed_TST(idx_UE,2) < 0)
					n_RBoffer_TST(idx_crnt_TST) = n_RBneed_TST(idx_UE,1);
					n_RB_ACQU_TST(idx_UE)       = n_RBneed_TST(idx_UE,1);	% 2016.11.25
				elseif (n_RBoffer_TST(idx_crnt_TST) - n_RBneed_TST(idx_UE,2) + n_RBneed_TST(idx_UE,1) > n_ttoffered)
					n_RB_ACQU_TST(idx_UE)       = n_ttoffered - (n_RBoffer_TST(idx_crnt_TST) - n_RBneed_TST(idx_UE,2));	% 2016.11.25

					n_RBneed_TST(idx_UE,1)      = n_RB_ACQU_TST(idx_UE);	% 2016.12.30 % 2016.12.30

					n_RBoffer_TST(idx_crnt_TST) = n_ttoffered;	% It's totally makes no sense, But I don't give a shit. 2016.11.14
				else
					n_RBoffer_TST(idx_crnt_TST) = n_RBoffer_TST(idx_crnt_TST) - n_RBneed_TST(idx_UE,2) + n_RBneed_TST(idx_UE,1);
				end
			end
			Load_TST(idx_crnt_TST) = n_RBoffer_TST(idx_crnt_TST) / n_ttoffered; % Very Important for FQC Input Every Single Time.

			% =============================== %
			%   ------    ------    -         %
			%  |         |          |         %
			%   ------    ------    |         %
			%         |         |   |         %
			%   ------    ------    --------  %
			% =============================== %
			if (d_B2B(idx_UE,1) ~= idx_trgt)	% 2016.11.29
				d_B2B(idx_UE,1) = idx_trgt;
				d_B2B(idx_UE,2) = idx_crnt_TST;
				d_B2B(idx_UE,3) = norm(UE_lct_n100(idx_UE,:) - BS_lct(idx_trgt,:));
				if idx_trgt <= n_MC
					d_B2B(idx_UE,4) = 10^(((37.6*log10(d_B2B(idx_UE,3)/1e+3)+0*HHM)/37.6))*1e+3;
				elseif idx_trgt > n_MC
					d_B2B(idx_UE,4) = 10^(((36.7*log10(d_B2B(idx_UE,3)/1e+3)+0*HHM)/36.7))*1e+3;
				end
			end

			% Intend to Handover; A3 Event satisfied
			if (trgtRSRP + CIO_TST(idx_trgt) > crntRSRP_TST(idx_UE) + CIO_TST(idx_crnt_TST) + HHM)
				
				% TTT Timer start to count down: % TTT keep counting down:	
				if (timer_TTT_TST(idx_UE) <= t_TTT && timer_TTT_TST(idx_UE) > 0)
					% 0930
					% ================================================ % % =================================== %
					%          -          -------        --            % %    -------     -----      -----     %
					%          |          |      )      /  \           % %       |       /     \    (          %
					%          |          |------      /----\          % %       |      |       |    -----     %
					%          |          |           /      \         % %       |       \     /          )    %
					%          -------    -          -        -        % %       -        -----      -----     %
					% ================================================ % % =================================== %
					if (LPA_pred_trgtToS(idx_UE) == 0)	% aaaaaaaaaaaaaaaaaa whether reset every loop?
						LPA_idx_pkt(idx_UE) = LPA_idx_pkt(idx_UE) + 1;
						switch LPA_idx_pkt(idx_UE)
							case 1
								LPA_P1s(idx_UE) = 10.^((crntRSRP_TST(idx_UE)-30)/10);	% [Watt]
								LPA_P1t(idx_UE) = 10.^((trgtRSRP-30)/10);		% [Watt]
								LPA_t1(idx_UE)  = idx_t;
							case 2
								LPA_P2s(idx_UE) = 10.^((crntRSRP_TST(idx_UE)-30)/10);	% [Watt]
								LPA_P2t(idx_UE) = 10.^((trgtRSRP-30)/10);		% [Watt]
								LPA_t2(idx_UE)  = idx_t - LPA_t1(idx_UE);
							case 3
								LPA_P3s(idx_UE) = 10.^((crntRSRP_TST(idx_UE)-30)/10);	% [Watt]
								LPA_P3t(idx_UE) = 10.^((trgtRSRP-30)/10);		% [Watt]
								LPA_t3(idx_UE)  = idx_t - LPA_t1(idx_UE);

								% TrgtCell is Macro
								if     (idx_trgt <= n_MC)
									LPA_pred_trgtToS(idx_UE) = LPA_fx(Gamma_MC,LPA_P1t(idx_UE),LPA_P2t(idx_UE),LPA_P3t(idx_UE), ...
																		LPA_Ps,LPA_t2(idx_UE),LPA_t3(idx_UE),dist_MC(idx_trgt));
								% TrgtCell is Pico
								elseif (idx_trgt >  n_MC)
									LPA_pred_trgtToS(idx_UE) = LPA_fx(Gamma_PC,LPA_P1t(idx_UE),LPA_P2t(idx_UE),LPA_P3t(idx_UE), ...
											 							LPA_Ps,LPA_t2(idx_UE),LPA_t3(idx_UE),dist_PC(idx_trgt-n_MC)) ...
											 							- timer_TTT_TST(idx_UE); % 0930
								end

								% End or Repeat / Again / Next Group / ...
								LPA_idx_pkt(idx_UE) = 0;
						end
					end

					timer_TTT_TST(idx_UE) = timer_TTT_TST(idx_UE) - t_d;
					if (timer_TTT_TST(idx_UE) < 1e-5)	% [SPECIAL CASE] 0930
						timer_TTT_TST(idx_UE) = 0;		% [SPECIAL CASE]
					end 								% [SPECIAL CASE]
					
					% CDR Reason
					DropReason(idx_UE) = 4; % Reason 4: in TTT % 2017.01.17

				% TTT expired and Handover does execute, then UE handover to target cell and TTT re-set.	
				elseif (timer_TTT_TST(idx_UE) == 0)

					% 2016.12.29 FUCK
					[INT_if_HO(idx_UE), logical_ifHO_Load(idx_UE,:)] = INT_ifHO_fx(idx_trgt, idx_crnt_TST, RsrpBS_watt(1,:), ...
																				n_RBoffer_TST(idx_crnt_TST), n_RBneed_TST(idx_UE,1), ...
																				Load_TST(1,:), logical_Load(idx_UE,:), ...
																				n_MC, n_PC);
					crntSINR_ifHO_TST(idx_UE) = (trgtRSRP-30) - 10*log10(INT_if_HO(idx_UE) + AMP_Noise^2);	% [dB] 2016.12.29
					n_RBneed_ifHO_TST(idx_UE) = MCS_3GPP36942(crntSINR_ifHO_TST(idx_UE), GBR, BW_PRB);
					% 2016.12.29 FUCK

					% ==================================================================== %	% ================================== %
					%     -----    ------    -----             -------   -----   -------   %	%   ------  ------   ------  -   --	 %
					%    /         |     )  (                     |     (           |      %	%   |     ) |     \  |     )  \ /	 %
					%   |     ---  |-----    -----     o -_       |      -----      |      %	%   ------  |      | ------    V 	 %
					%    \     |   |              )    | | |      |           )     |      %	%   |     ) |     /  |     \   |	 %
					%     -----    -         -----     - - -      -      -----      -      %	%   ------  ------   -     -   -	 %
					% ==================================================================== %	% ================================== %
					
					% tToS by d_B2B
					if idx_trgt <= n_MC
						GPSinTST_trgtToS(idx_UE) = GPS_fx(BS_lct(idx_trgt,:), MACROCELL_RADIUS, UE_lct_n100(idx_UE,:), UE_v(idx_UE,:)) - t_TTT; % 2017.01.21
					elseif idx_trgt > n_MC
						GPSinTST_trgtToS(idx_UE) = GPS_fx(BS_lct(idx_trgt,:), d_B2B(idx_UE,3), UE_lct_n100(idx_UE,:), UE_v(idx_UE,:)) - t_TTT; % 2017.01.21
					end

					% OUR ALG 2016.12.19
					if GPSinTST_trgtToS(idx_UE) > TST_HD
						% Connect to Handover but Remain
						if (n_RBoffer_TST(idx_trgt) + n_RBneed_ifHO_TST(idx_UE) > n_ttoffered)	% 2016.12.29
							% Cell Selection
							idx_UEcnct_TST(idx_UE) = idx_crnt_TST;		% 2016.11.25 !!! Remain to serving cell. % 2016.12.27
							% Interference 
							logical_HO(idx_UE) = 0; % Handover failure because of insufficinet resource block.
							% CDR Reason
							DropReason(idx_UE) = 1; % Reason 1: RB not enough % 2017.01.17

						% Connect to Handover and Connect
						elseif (n_RBoffer_TST(idx_trgt) + n_RBneed_ifHO_TST(idx_UE) <= n_ttoffered)	% 2016.12.29
							% Cell Selection
							idx_UEcnct_TST(idx_UE)      = idx_trgt;
							% Cell Loading
							n_RBoffer_TST(idx_crnt_TST) = n_RBoffer_TST(idx_crnt_TST) - n_RBneed_TST(idx_UE,1);
							Load_TST(idx_crnt_TST)      = n_RBoffer_TST(idx_crnt_TST) / n_ttoffered;
							n_RBoffer_TST(idx_trgt)     = n_RBoffer_TST(idx_trgt)     + n_RBneed_ifHO_TST(idx_UE);	% 2016.12.29
							Load_TST(idx_trgt)          = n_RBoffer_TST(idx_trgt)     / n_ttoffered;
							n_RB_ACQU_TST(idx_UE)       = n_RBneed_ifHO_TST(idx_UE);	% 2016.12.29
							% Handover
							n_HO_UE_TST(idx_UE)         = n_HO_UE_TST(idx_UE)   + 1;
							n_HO_BS_TST(idx_trgt)       = n_HO_BS_TST(idx_trgt) + 1;	% Only for target cell
							% Call Drop Rate
							CDR_BS_TST(idx_trgt)        = n_Drop_BS_TST(idx_trgt) / (n_Drop_BS_TST(idx_trgt) + n_HO_BS_TST(idx_trgt));	% 2017.01.04
							CDR_UE_TST(idx_UE)          = n_Drop_UE_TST(idx_UE)   / (n_Drop_UE_TST(idx_UE)   + n_HO_UE_TST(idx_UE));	% 2017.01.04
							% Interference 
							logical_HO(idx_UE) = 1;	% Handover success.
							% CDR Reason
							DropReason(idx_UE) = 3;	% Reason 3: Just Connect % 2017.01.17
							% TTT Reset
							timer_TTT_TST(idx_UE) = t_TTT;	% 2016.12.28
							% Ping-Pong Rate UPDATE
							PPR_5s_TST(idx_UE)    = n_PPE_5s_TST(idx_UE) / n_HO_UE_TST(idx_UE);	% 2017.01.01
						end

					elseif GPSinTST_trgtToS(idx_UE) <= TST_HD
						% % TTT Reset
						% timer_TTT_TST(idx_UE)  = t_TTT;			% Cancel at 2017.01.17
						% Cell Selection
						idx_UEcnct_TST(idx_UE) = idx_crnt_TST;		% 2016.11.28 !!! Remain to serving cell.
						% CDR Reason
						DropReason(idx_UE) = 2; % Reason 2: ToS limit % 2017.01.17
					end

				% TTT CASE End
				end
					
			% TTT expired but Handover does not execute, then UE remains to serving cell and TTT may re-count down.
			elseif (trgtRSRP + CIO_TST(idx_trgt) <= crntRSRP_TST(idx_UE) + CIO_TST(idx_crnt_TST) + HHM)
				% TTT Reset
				timer_TTT_TST(idx_UE) = t_TTT;
				% Cell Selection
				idx_UEcnct_TST(idx_UE)      = idx_crnt_TST; % Unchanged But Significant Step (UBSS)
				% Load
				n_RBoffer_TST(idx_crnt_TST) = n_RBoffer_TST(idx_crnt_TST); % UBSS
				Load_TST(idx_crnt_TST)      = n_RBoffer_TST(idx_crnt_TST) / n_ttoffered;
				% CDR Reason
				DropReason(idx_UE) = 3; % Reason 3: Just Connect % 2017.01.17
			% A3 Event 2.0 END
			end

			% Check Ping-Pong & Dropping
			if logical_HO(idx_UE) == 1
				% ===================================== % 
				%   ------   ------   ------  -    --   %
				%   |     )  |     )  |        \  /     %
				%   ------   ------   -----     V       %
				%   |        |     \  |         |       %
				%   -        -     -  ------    -       %
				% ===================================== %
				idx_UEprey_TST(idx_UE) = idx_UEcnct_TST(idx_UE);	% 2017.01.04

				% ==================== % 
				%   -     -   ------   %
				%   |     |  |      |  %
				%   |-----|  |      |  %	% 2016.12.15
				%   |     |  |      |  %
				%   -     -   ------   %
				% ==================== %
				if     idx_crnt_TST <= n_MC && idx_trgt <= n_MC
					n_HO_M2M = n_HO_M2M + 1;
				elseif idx_crnt_TST <= n_MC && idx_trgt >  n_MC
					n_HO_M2P = n_HO_M2P + 1;
				elseif idx_crnt_TST >  n_MC && idx_trgt <= n_MC
					n_HO_P2M = n_HO_P2M + 1;
				elseif idx_crnt_TST >  n_MC && idx_trgt >  n_MC
					n_HO_P2P = n_HO_P2P + 1;
				end
				
				% ============================= % 
				%   ------   ------   -------   %
				%   |     )  |     )  |         %
				%   |-----   |-----   ------    %	% 2016.10.12 / 2016.11.14 / 2017.01.04
				%   |        |        |         %
				%   -        -        -------   %
				% ============================= %
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

				% ============================= %
				%   ------   -        -------   %	% Update CQI state:
				%   |     )  |        |         %
				%   ------   |        |-----    %	% Update Interference when idx_UEcnct changes
				%   |     \  |        |         %
				%   -     -  -------  -         %
				% ============================= %
				crntSINR_TST(idx_UE) = crntSINR_ifHO_TST(idx_UE); % 2016.12.29

				% Reset for INTerference Constraint !!!!!!!!!!!!!!!!!!!!!!
				logical_HO(idx_UE) = 0;	% 2016.11.25

				% ================================================ %
				%      -          -----        --      ------      %
				%      |         /     \      /  \     |     \     %
				%      |        |       |    /----\    |      |    %	% 2016.12.29
				%      |         \     /    /      \   |     /     %
				%      -------    -----    -        -  ------      %
				% ================================================ %
				n_RBneed_TST(idx_UE,2) = n_RBneed_ifHO_TST(idx_UE,1);	% n_RBneed_TST(idx_UE,2) saves the number of RB idx_UE needs after Handover.
				% Dice Have Rolled!!!!!
				logical_Load(idx_UE,:) = logical_ifHO_Load(idx_UE,:);	% 2016.12.29
			else
				% ================================================ %
				%      -          -----        --      ------      %
				%      |         /     \      /  \     |     \     %
				%      |        |       |    /----\    |      |    %	% 2016.12.29
				%      |         \     /    /      \   |     /     %
				%      -------    -----    -        -  ------      %
				% ================================================ %
				n_RBneed_TST(idx_UE,2) = n_RBneed_TST(idx_UE,1);		% n_RBneed_TST(idx_UE,2) saves the number of RB idx_UE needs
			end

			% ================================== %
			%     -------  -------   -------     %	% 2017.01.05
	 		%    /         |      \  |      )    %	 % 2017.01.05
	 		%   |          |       | -------     %	  % 2017.01.05
	 		%    \         |      /  |     \     %	   % 2017.01.05
	 		%     -------  -------   -      -    %	    % 2017.01.05
	 		% ================================== %

			if crntSINR_TST(idx_UE) > SINR_th
				timer_Drop_TST(idx_UE)   = t_T310; % Dropping timer reset to 1sec

			elseif crntSINR_TST(idx_UE) <= SINR_th

				if (timer_Drop_TST(idx_UE) <= t_T310 && timer_Drop_TST(idx_UE) > 0)
					timer_Drop_TST(idx_UE) = timer_Drop_TST(idx_UE) - t_d;
					if (timer_Drop_TST(idx_UE) < 1e-5)	% [SPECIAL CASE]
						timer_Drop_TST(idx_UE) = 0;		% [SPECIAL CASE]
					end 								% [SPECIAL CASE]
					
				elseif (timer_Drop_TST(idx_UE) == 0)

					% Cell Selection
					idx_UEcnct_TST(idx_UE) = 0;			% 2017.01.04
					idx_UEprey_TST(idx_UE) = idx_trgt; 	% 2017.01.05

					% Call Drop Rate (CDR)		% 2017.01.04
					n_Drop_BS_TST(idx_trgt) = n_Drop_BS_TST(idx_trgt) + 1;													% 2017.01.04
					CDR_BS_TST(idx_trgt)    = n_Drop_BS_TST(idx_trgt) / (n_Drop_BS_TST(idx_trgt) + n_HO_BS_TST(idx_trgt));	% 2017.01.04
					n_Drop_UE_TST(idx_UE)   = n_Drop_UE_TST(idx_UE)   + 1;													% 2017.01.04
					CDR_UE_TST(idx_UE)      = n_Drop_UE_TST(idx_UE)   / (n_Drop_UE_TST(idx_UE)   + n_HO_UE_TST(idx_UE));	% 2017.01.04

					% CDR Reason Record of UE UE UE
					switch DropReason(idx_UE)
						case 1 	% Reason 1: RB not enough
							if     idx_crnt_TST <= n_MC && idx_trgt <= n_MC
								DropReason1_M2M___RB(idx_UE) = DropReason1_M2M___RB(idx_UE) + 1;
							elseif idx_crnt_TST <= n_MC && idx_trgt >  n_MC
								DropReason2_M2P___RB(idx_UE) = DropReason2_M2P___RB(idx_UE) + 1;
							elseif idx_crnt_TST >  n_MC && idx_trgt <= n_MC
								DropReason3_P2M___RB(idx_UE) = DropReason3_P2M___RB(idx_UE) + 1;
							elseif idx_crnt_TST >  n_MC && idx_trgt >  n_MC
								DropReason4_P2P___RB(idx_UE) = DropReason4_P2P___RB(idx_UE) + 1;
							end
 						case 2 	% Reason 2: Tos limit
 							if     idx_crnt_TST <= n_MC && idx_trgt <= n_MC
 								DropReason5_M2M__ToS(idx_UE) = DropReason5_M2M__ToS(idx_UE) + 1;
							elseif idx_crnt_TST <= n_MC && idx_trgt >  n_MC
								DropReason6_M2P__ToS(idx_UE) = DropReason6_M2P__ToS(idx_UE) + 1;
							elseif idx_crnt_TST >  n_MC && idx_trgt <= n_MC
								DropReason7_P2M__ToS(idx_UE) = DropReason7_P2M__ToS(idx_UE) + 1;
							elseif idx_crnt_TST >  n_MC && idx_trgt >  n_MC
								DropReason8_P2P__ToS(idx_UE) = DropReason8_P2P__ToS(idx_UE) + 1;
							end
						case 3 	% Reason 3: Just Connect
							if     idx_crnt_TST <= n_MC
								DropReason9_MMM_Conn(idx_UE) = DropReason9_MMM_Conn(idx_UE) + 1;
							elseif idx_crnt_TST >  n_MC
								DropReasonX_PPP_Conn(idx_UE) = DropReasonX_PPP_Conn(idx_UE) + 1;
							end
						case 4 	% Reason 4: in TTT
							if     idx_crnt_TST <= n_MC && idx_trgt <= n_MC
								DropReasonY_M2M__TTT(idx_UE) = DropReasonY_M2M__TTT(idx_UE) + 1;
							elseif idx_crnt_TST <= n_MC && idx_trgt >  n_MC
								DropReasonY_M2P__TTT(idx_UE) = DropReasonY_M2P__TTT(idx_UE) + 1;
							elseif idx_crnt_TST >  n_MC && idx_trgt <= n_MC
								DropReasonY_P2M__TTT(idx_UE) = DropReasonY_P2M__TTT(idx_UE) + 1;
							elseif idx_crnt_TST >  n_MC && idx_trgt >  n_MC
								DropReasonY_P2P__TTT(idx_UE) = DropReasonY_P2P__TTT(idx_UE) + 1;
							end
					end

					% ============================= %
					%   ------   ------   -------   %
					%   |     )  |     )  |         %
					%   |-----   |-----   ------    %	% 2016.10.12 / 2016.11.14 / 2017.01.04
					%   |        |        |         %
					%   -        -        -------   %
					% ============================= %
					state_PPE_TST(idx_UE,:) = PingPong_Update(state_PPE_TST(idx_UE,:), idx_UEcnct_TST(idx_UE), idx_t);
					% % ===/* Ping Pong State Update [1 sec] */===
					if    (state_PPE_TST(idx_UE,1) == state_PPE_TST(idx_UE,3) ...
						&& state_PPE_TST(idx_UE,1) ~= state_PPE_TST(idx_UE,2) ...
						&& state_PPE_TST(idx_UE,4) -  state_PPE_TST(idx_UE,5) <= MTS_1s ...
						&& prod(state_PPE_TST(idx_UE,:)) ~= 0)	% 2017.01.04 Live 2 Dead 2 Live is not Ping-Pong, Dead 2 Live 2 Dead either.
						% Ping-Pong Effect Occur
						n_PPE_1s_TST(idx_UE) = n_PPE_1s_TST(idx_UE) + 1; % [PRFM]
					end
					% % ===/* Ping Pong State Update [5 sec] */===
					if    (state_PPE_TST(idx_UE,1) == state_PPE_TST(idx_UE,3) ...
						&& state_PPE_TST(idx_UE,1) ~= state_PPE_TST(idx_UE,2) ...
						&& state_PPE_TST(idx_UE,4) -  state_PPE_TST(idx_UE,5) <= MTS_5s ...
						&& prod(state_PPE_TST(idx_UE,:)) ~= 0)	% 2017.01.04 Live 2 Dead 2 Live is not Ping-Pong, Dead 2 Live 2 Dead either.
						% Ping-Pong Effect Occur
						n_PPE_5s_TST(idx_UE) = n_PPE_5s_TST(idx_UE) + 1; % [PRFM]
						PPR_5s_TST(idx_UE)   = n_PPE_5s_TST(idx_UE) / n_HO_UE_TST(idx_UE);	% 2016.12.15
					end

					% Dropping timer reset to 1sec
					timer_Drop_TST(idx_UE)   = t_T310;	% 2017.01.06 PM
				end
			end

			% ================================== %
			%     -------  -------   -------     %	% 2017.01.05
			%    /         |      )  |      )    %	 % 2017.01.05
			%   |          -------   -------     %	  % 2017.01.05
			%    \         |      )  |     \     %	   % 2017.01.05
			%     -------  -------   -      -    %	    % 2017.01.05
			% ================================== %
			% Call Block Rate (CBR)	[UE]
			if idx_UEcnct_TST(idx_UE) == 0
				n_DeadUE_UE = n_DeadUE_UE + 1;
			elseif idx_UEcnct_TST(idx_UE) ~= 0
				n_LiveUE_UE = n_LiveUE_UE + 1;
			end

		% STATE TRANSITION END
		end

		% ============================================================================================ %
		%      -      -   -------        -      -   -------   ------       --     -------  -------     %
		%      |      |   |              |      |   |      )  |     \     /  \       |     |           %
		%      |      |   |-----         |      |   |------   |      |   /----\      |     |-----      %
		%      |      |   |              |      |   |         |     /   /      \     |     |           %
		%       ------    -------         ------    -         ------   -        -    -     -------     %
		% ============================================================================================ %			
		% % ===/* UE UPDATE State */===
		% Mobility Model
		[lct_new, v_new, t_oneStep] = UMM_RWPmodel('V', idx_t, t_start, UE_lct_n100(idx_UE,:), ...
													UE_timer_RWP1step(idx_UE,1), t_d, rectEdge, UE_v(idx_UE,:), ...
													seedSpeedMDS(idx_UE,idx_SEED(idx_UE)), ...
													seedAngleDEG(idx_UE,idx_SEED(idx_UE)), ... 
													seedEachStep(idx_UE,idx_SEED(idx_UE)));
		UE_lct_n100(idx_UE, :) = lct_new;
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

		if idx_crnt_TST == 0
			% ================================================ %
			%      -          -----        --      ------      %
			%      |         /     \      /  \     |     \     %
			%      |        |       |    /----\    |      |    %	% 2016.12.29
			%      |         \     /    /      \   |     /     %
			%      -------    -----    -        -  ------      %
			% ================================================ %
			n_RBneed_TST(idx_UE,2) = n_RBneed_TST(idx_UE,1);	% n_RBneed_TST(idx_UE,2) saves the number of RB idx_UE needs
		end

		% % ===/* UE UPDATE End */===

	% Terminate 'for loop' for idx_UE
	end

	% ================================== %
	%     -------  -------   -------     %	% 2017.01.05
	%    /         |      )  |      )    %	 % 2017.01.05
	%   |          -------   -------     %	  % 2017.01.05
	%    \         |      )  |     \     %	   % 2017.01.05
	%     -------  -------   -      -    %	    % 2017.01.05
	% ================================== %

	% Reset for next idx_t
	n_DeadUE_BS(1,:) = 0;		% 2017.01.05
	n_LiveUE_BS(1,:) = 0;		% 2017.01.05
	who_Hunters_BS(:,:) = 0;	% 2017.01.05 PM

	% Call Block Rate (CBR)	[BS]
	for bs = 1:n_BS
		% ==   EMPTY   ==	% No Hunter is Preying 'this' Base Station
		if isempty(find(idx_UEprey_TST == bs, 1)) == 1
			who_Hunters_BS(bs,:) = 0;	% 1 x n_UE
			CBR_BS_TST(bs) = 0;			% For Fuck U Learning

		% == Not EMPTY == 	% More than one Hunter is Preying 'this' Base Station	
		elseif isempty(find(idx_UEprey_TST == bs, 1)) == 0
			who_Hunters_BS(bs,1:length(find(idx_UEprey_TST == bs))) = find(idx_UEprey_TST == bs);	% Hunters of the Prey BS.	% 1 x n_UE

			for idx_Hunters = 1:n_UE
				if who_Hunters_BS(bs, idx_Hunters) == 0 	% Fuck you bug 2017.01.05
					break; 
				end

				if idx_UEcnct_TST(who_Hunters_BS(bs, idx_Hunters)) == 0			% Fuck you bug 2017.01.05
					n_DeadUE_BS(bs) = n_DeadUE_BS(bs) + 1;
				elseif idx_UEcnct_TST(who_Hunters_BS(bs, idx_Hunters)) ~= 0		% Fuck you bug 2017.01.05
					n_LiveUE_BS(bs) = n_LiveUE_BS(bs) + 1; 
				end
			end

			if n_DeadUE_BS(bs) < 0 || n_LiveUE_BS(bs) < 0
				fprintf('BS CBR BUG\n');
			end

			% Call Block Rate (CBR)
			while n_DeadUE_BS(bs) + n_LiveUE_BS(bs) ~= length(find(idx_UEprey_TST == bs))
				fprintf('BS CBR BUG\n'); 
			end
			CBR_BS_TST(bs) = n_DeadUE_BS(bs) / (n_DeadUE_BS(bs) + n_LiveUE_BS(bs));				% For Fuck U Learning
		end
	end

	% Call Block Rate (CBR)	[UE]
	while n_DeadUE_UE + n_LiveUE_UE ~= n_UE, fprintf('UE CBR BUG\n'); end
	CBR_UE_TST = n_DeadUE_UE / (n_DeadUE_UE + n_LiveUE_UE);

	% Reset for next idx_t
	n_DeadUE_UE = 0;	% 2017.01.05 PM
	n_LiveUE_UE = 0;	% 2017.01.05 PM

	% ================================================ % % ====================================== %
	%          -          -------        --            % %   --------    --------      -------    %
	%          |          |      )      /  \           % %   |          /        \    /           %
	%          |          |------      /----\          % %   |------|  |        \ |  |            %
	%          |          |           /      \         % %   |          \        X    \           %
	%          -------    -          -        -        % %   -           -------- \    -------    %
	% ================================================ % % ====================================== %	
	% FQ End FQ End FQ End FQ End FQ End FQ End FQ End FQ End FQ End FQ End FQ End FQ End FQ End FQ End
	if (idx_t == t_start || rem(idx_t, FQ_BS_LI_TST) == 0)
		for idx_BS = 1:n_BS
			% Fuzzifier
			DoM_CIO_TSTc(idx_BS,:)      = FQc1_Fuzzifier(CIO_TST(idx_BS), 'C');
			DoM_Load_TSTc(idx_BS,:)     = FQc1_Fuzzifier(Load_TST(idx_BS),'L');
			DoT_Rule_New_TSTc(idx_BS,:) = FQc2_DegreeOfTruth(DoM_CIO_TSTc(idx_BS,:), DoM_Load_TSTc(idx_BS,:),'D');
			% Global Action
			[GlobalAct_TSTc(idx_BS),idx_subAct_choosed_new_TSTc(idx_BS,:)] = FQc3_GlobalAction(DoT_Rule_New_TSTc(idx_BS,:), ...
																									Q_Table_TSTc(:,:,idx_BS));
			if     (CIO_TST(idx_BS) + GlobalAct_TSTc(idx_BS) < -5)
				CIO_TST(idx_BS) = -5;
			elseif (CIO_TST(idx_BS) + GlobalAct_TSTc(idx_BS) > 5)
				CIO_TST(idx_BS) = 5;
			else
				CIO_TST(idx_BS) = CIO_TST(idx_BS) + GlobalAct_TSTc(idx_BS);
			end
			% Q-function
			Q_fx_new_TSTc(idx_BS) = FQc4_Qfunction(DoT_Rule_New_TSTc(idx_BS,:), Q_Table_TSTc(:,:,idx_BS), ...
																	idx_subAct_choosed_new_TSTc(idx_BS,:));
			% Enter the condition when it's the second learning!!!
			if (idx_t ~= t_start)
				% Q Bonus
				V_fx_new_TSTc(idx_BS) = FQc5_Vfunction(DoT_Rule_New_TSTc(idx_BS,:), Q_Table_TSTc(:,:,idx_BS));
				Q_reward_TSTc(idx_BS) = FQc6_Reward(Load_TST(idx_BS), CBR_BS_TST(idx_BS), CDR_BS_TST(idx_BS),'C');
				Q_bonus_TSTc(idx_BS)  = FQc7_Qbonus(Q_reward_TSTc(idx_BS), FQ_BS_DF_TST, V_fx_new_TSTc(idx_BS), ...
																						Q_fx_old_TSTc(idx_BS));
				% Q Update
				Q_Table_TSTc(:,:,idx_BS) = FQc8_Qupdate(Q_Table_TSTc(:,:,idx_BS), idx_subAct_choosed_old_TSTc(idx_BS,:), ...
														FQ_BS_LR_TST, Q_bonus_TSTc(idx_BS), DoT_Rule_Old_TSTc(idx_BS,:));
			end
		end	
		% Recording for the different iteration of 'Q-function'
		Q_fx_old_TSTc               = Q_fx_new_TSTc;
		idx_subAct_choosed_old_TSTc = idx_subAct_choosed_new_TSTc;
		DoT_Rule_Old_TSTc           = DoT_Rule_New_TSTc;
	end

	% ============================================= %	% =========================================== %
	%      ------   ------   ------   --    --      %	%	------- ------  ------ --    - ------	  %
	%      |     )  |     )  |        | \  / |      %	%	   |    |     ) |      | \   | |     \	  %
	%      |-----   |-----   |----|   |  \/  |      %	%	   |    ------  -----  |  \  | |      |   %
	%      |        |    \   |        |      |      %	%	   |    |     \ |      |   \ | |     /	  %
	%      -        -     -  -        -      -      %	%	   -    -     - ------ -    -- ------	  %
	% ============================================= %	% =========================================== %
	
	for bs = 1:n_BS
		PRFM_TST_BS_CBR(PRFM_CTR) = PRFM_TST_BS_CBR(PRFM_CTR) + CBR_BS_TST(bs);			% KPI: Call Block Rate
		PRFM_TST_BS_CDR(PRFM_CTR) = PRFM_TST_BS_CDR(PRFM_CTR) + CDR_BS_TST(bs);			% KPI: Call Drop Rate
	end
	PRFM_TST_BS_QoS(PRFM_CTR) = 1 - PRFM_TST_BS_CBR(PRFM_CTR)/n_BS - PRFM_TST_BS_CDR(PRFM_CTR)/n_BS;	% KPI: Quality of Service

	for ue = 1:n_UE
		PRFM_TST_UE_nHO(PRFM_CTR)   = PRFM_TST_UE_nHO(PRFM_CTR)   + n_HO_UE_TST(ue); 	% KPI: Handover Number
		PRFM_TST_UE_CDR(PRFM_CTR)   = PRFM_TST_UE_CDR(PRFM_CTR)   + CDR_UE_TST(ue);		% KPI: Call Drop Rate
		PRFM_TST_UE_1snPP(PRFM_CTR) = PRFM_TST_UE_1snPP(PRFM_CTR) + n_PPE_1s_TST(ue);	% KPI: Ping-Pong Number (MTS = 1s)
		PRFM_TST_UE_5snPP(PRFM_CTR) = PRFM_TST_UE_5snPP(PRFM_CTR) + n_PPE_5s_TST(ue);	% KPI: Ping-Pong Number (MTS = 5s)
		PRFM_TST_UE_5sPPR(PRFM_CTR) = PRFM_TST_UE_5sPPR(PRFM_CTR) + PPR_5s_TST(ue);		% KPI: Ping-Pong Rate   (MTS = 5s)
	end
	PRFM_TST_UE_CBR(PRFM_CTR)       = PRFM_TST_UE_CBR(PRFM_CTR)   + CBR_UE_TST;			% KPI: Call Block Rate

	LB_Idle(PRFM_CTR) = length(find(idx_UEcnct_TST == 0));											% 2017.01.19
	LB___PC(PRFM_CTR) = length(find(idx_UEcnct_TST >  n_MC));										% 2017.01.19
	LB___MC(PRFM_CTR) = length(find(idx_UEcnct_TST <= n_MC)) - length(find(idx_UEcnct_TST == 0));	% 2017.01.19

	PRFM_CTR = PRFM_CTR + 1;

% Terminate 'for loop' for idx_t	
end
toc

t_END  = idx_t; % The time once Q-table of UEs Converge!!!
n_CONV = fix(t_END/t_d);

% ============================================= %	% ======================== %
%      ------   ------   ------   --    --      %	%	------ -----   ----	   %
%      |     )  |     )  |        | \  / |      %	%	|		 |	  /		   %
%      |-----   |-----   |----|   |  \/  |      %	%	|----	 |	 |     -   %
%      |        |    \   |        |      |      %	%	|		 |	  \    |   %
%      -        -     -  -        -      -      %	%	-	   -----   ----	   %
% ============================================= %	% ======================== %

% ==================== %
%   ------     -----   %
%   |     )   (        %
%   ------     -----   %
%   |     )         )  %
%   ------     -----   %
% ==================== %

% [BS] Learning Trend of QoS
figure, box on, grid on, hold on;
t_QoS     = 1:n_CONV;
y_TST_QoS = PRFM_TST_BS_QoS(t_QoS);
plot(t_QoS*t_d, y_TST_QoS);
title('QoS_{BS} = 1 - CBR - CDR');
xlabel('Time (sec)');
ylabel('PRFM');
legend('BDRY-TST1');
set(gcf,'numbertitle','off');
set(gcf,'name','[BDRY-TST1] BS QoS Trend');
G4_TST0p500u100mp000pp000_BS_Trend_QoS = PRFM_TST_BS_QoS;
save G4_TST0p500u100mp000pp000_BS_Trend_QoS.mat G4_TST0p500u100mp000pp000_BS_Trend_QoS;

% [BS] Learning Trend of CBR
figure, box on, grid on, hold on;
t_CBR     = 1:n_CONV;
y_TST_CBR = PRFM_TST_BS_CBR(t_CBR)/n_BS;
plot(t_CBR*t_d, y_TST_CBR);
title('Call Block Rate of BS');
xlabel('Time (sec)');
ylabel('PRFM');
legend('BDRY-TST1');
set(gcf,'numbertitle','off');
set(gcf,'name','[BDRY-TST1] BS CBR Trend');
G4_TST0p500u100mp000pp000_BS_Trend_CBR = PRFM_TST_BS_CBR;
save G4_TST0p500u100mp000pp000_BS_Trend_CBR.mat G4_TST0p500u100mp000pp000_BS_Trend_CBR;

% [BS] Learning Trend of CDR
figure, box on, grid on, hold on;
t_cOP = 1:n_CONV;
y_TST_cOP = PRFM_TST_BS_CDR(t_cOP)/n_BS;
plot(t_cOP*t_d, y_TST_cOP);
title('Call Drop Rate of BS');
xlabel('Time (sec)');
ylabel('PRFM');
legend('BDRY-TST1');
set(gcf,'numbertitle','off');
set(gcf,'name','[BDRY-TST1] BS CDR Trend');
G4_TST0p500u100mp000pp000_BS_Trend_CDR = PRFM_TST_BS_CDR;
save G4_TST0p500u100mp000pp000_BS_Trend_CDR.mat G4_TST0p500u100mp000pp000_BS_Trend_CDR;

% [BS] Final CBR vs CDR vs QoS
figure(), box on, grid on, hold on;
x = [mean(CBR_BS_TST); mean(CDR_BS_TST); (1-mean(CBR_BS_TST)-mean(CDR_BS_TST))];
bar(x);
set(gca,'XTick',(1:1:3),'FontSize',16);
set(gca,'xticklabel',{'CBR','CDR','QoS'},'FontSize',16);
title('Quality of Service of BS');
% xlabel('PRFM');
ylabel('Rate');
legend('BDRY-TST1','location','Southeast');
set(gcf,'numbertitle','off');
set(gcf,'name','[BDRY-TST1] BS Final PRFM');
G4_TST0p500u100mp000pp000_BS_Final_CBR = CBR_BS_TST;
save G4_TST0p500u100mp000pp000_BS_Final_CBR.mat G4_TST0p500u100mp000pp000_BS_Final_CBR;
G4_TST0p500u100mp000pp000_BS_Final_CDR = CDR_BS_TST;
save G4_TST0p500u100mp000pp000_BS_Final_CDR.mat G4_TST0p500u100mp000pp000_BS_Final_CDR;

% ==================== %
%  -      -   -------  %
%  |      |   |        %
%  |      |   ------   %
%  |      |   |        %
%   ------    -------  %
% ==================== %

% [UE] Learning Trend of nHO
figure, box on, grid on, hold on;
t_nHO     = 1:n_CONV;
y_TST_nHO = PRFM_TST_UE_nHO(t_nHO)/n_UE;
plot(t_nHO*t_d, y_TST_nHO);
title('Handover Number of UE');
xlabel('Time (sec)');
ylabel('Number');
legend('BDRY-TST1');
set(gcf,'numbertitle','off');
set(gcf,'name','[BDRY-TST1] UE nHO Trend');
G4_TST0p500u100mp000pp000_UE_Trend_nHO = PRFM_TST_UE_nHO;
save G4_TST0p500u100mp000pp000_UE_Trend_nHO.mat G4_TST0p500u100mp000pp000_UE_Trend_nHO;

% [UE] Learning Trend of CDR
figure, box on, grid on, hold on;
t_uOP     = 1:n_CONV;
y_TST_uOP = PRFM_TST_UE_CDR(t_uOP)/n_UE;
plot(t_uOP*t_d, y_TST_uOP);
title('Call Drop Rate of UE');
xlabel('Time (sec)');
ylabel('PRFM');
legend('BDRY-TST1');
set(gcf,'numbertitle','off');
set(gcf,'name','[BDRY-TST1] UE CDR Trend');
G4_TST0p500u100mp000pp000_UE_Trend_CDR = PRFM_TST_UE_CDR;
save G4_TST0p500u100mp000pp000_UE_Trend_CDR.mat G4_TST0p500u100mp000pp000_UE_Trend_CDR;

% [UE] Learning Trend of 1s nPP
figure, box on, grid on, hold on;
t_1snPP     = 1:n_CONV;
y_TST_1snPP = PRFM_TST_UE_1snPP(t_1snPP)/n_UE;
plot(t_1snPP*t_d, y_TST_1snPP);
title('1sec Ping-Pong Number of UE');
xlabel('Time (sec)');
ylabel('PRFM');
legend('BDRY-TST1');
set(gcf,'numbertitle','off');
set(gcf,'name','[BDRY-TST1] UE 1snPP Trend');
G4_TST0p500u100mp000pp000_UE_Trend_1PP = PRFM_TST_UE_1snPP;
save G4_TST0p500u100mp000pp000_UE_Trend_1PP.mat G4_TST0p500u100mp000pp000_UE_Trend_1PP;

% [UE] Learning Trend of 5s nPP
figure, box on, grid on, hold on;
t_5snPP     = 1:n_CONV;
y_TST_5snPP = PRFM_TST_UE_5snPP(t_5snPP)/n_UE;
plot(t_5snPP*t_d, y_TST_5snPP);
title('5sec Ping-Pong Number of UE');
xlabel('Time (sec)');
ylabel('PRFM');
legend('BDRY-TST1');
set(gcf,'numbertitle','off');
set(gcf,'name','[BDRY-TST1] UE 5snPP Trend');
G4_TST0p500u100mp000pp000_UE_Trend_5PP = PRFM_TST_UE_5snPP;
save G4_TST0p500u100mp000pp000_UE_Trend_5PP.mat G4_TST0p500u100mp000pp000_UE_Trend_5PP;

% [UE] Learning Trend of 5s PPR
figure, box on, grid on, hold on;
t_5sPPR     = 1:n_CONV;
y_TST_5sPPR = PRFM_TST_UE_5sPPR(t_5sPPR)/n_UE;
plot(t_5sPPR*t_d, y_TST_5sPPR);
title('5sec Ping-Pong Rate of UE');
xlabel('Time (sec)');
ylabel('PRFM');
legend('BDRY-TST1');
set(gcf,'numbertitle','off');
set(gcf,'name','[BDRY-TST1] UE 5sPPR Trend');
G4_TST0p500u100mp000pp000_UE_Trend_5PPR = PRFM_TST_UE_5sPPR;
save G4_TST0p500u100mp000pp000_UE_Trend_5PPR.mat G4_TST0p500u100mp000pp000_UE_Trend_5PPR;

% [UE] Final nHO
figure(), box on, hold on;
x1 = 1:1;    % Case idx
y1 = mean(n_HO_UE_TST);
bar(x1,y1);
ylabel('Handover Number');
set(gca,'XTick',(1:1:1));
set(gca,'xticklabel',{'BDRY-TST1'});
set(gcf,'numbertitle','off');
set(gcf,'name','[BDRY-TST1] UE Final nHO');
G4_TST0p500u100mp000pp000_UE_Final_nHO = n_HO_UE_TST;
save G4_TST0p500u100mp000pp000_UE_Final_nHO.mat G4_TST0p500u100mp000pp000_UE_Final_nHO;

% [UE] Final CDR
figure(), box on, hold on;
x2 = 1:1;    % Case idx
y2 = mean(CDR_UE_TST);
bar(x2,y2);
ylabel('Call Drop Rate');
set(gca,'XTick',(1:1:1));
set(gca,'xticklabel',{'BDRY-TST1'});
set(gcf,'numbertitle','off');
set(gcf,'name','[BDRY-TST1] UE Final CDR');
G4_TST0p500u100mp000pp000_UE_Final_CDR = CDR_UE_TST;
save G4_TST0p500u100mp000pp000_UE_Final_CDR.mat G4_TST0p500u100mp000pp000_UE_Final_CDR;

% [UE] Final 1s nPP
figure(), box on, hold on;
x3 = 1:1;    % Case idx
y3 = mean(n_PPE_1s_TST);
bar(x3,y3);
ylabel('1sec Ping-Pong Number');
set(gca,'XTick',(1:1:1));
set(gca,'xticklabel',{'BDRY-TST1'});
set(gcf,'numbertitle','off');
set(gcf,'name','[BDRY-TST1] UE Final 1snPP');
G4_TST0p500u100mp000pp000_UE_Final_1PP = n_PPE_1s_TST;
save G4_TST0p500u100mp000pp000_UE_Final_1PP.mat G4_TST0p500u100mp000pp000_UE_Final_1PP;

% [UE] Final 5s nPP
figure(), box on, hold on;
x4 = 1:1;    % Case idx
y4 = mean(n_PPE_5s_TST);
bar(x4,y4);
ylabel('5sec Ping-Pong Number');
set(gca,'XTick',(1:1:1));
set(gca,'xticklabel',{'BDRY-TST1'});
set(gcf,'numbertitle','off');
set(gcf,'name','[BDRY-TST1] UE Final 5snPP');
G4_TST0p500u100mp000pp000_UE_Final_5PP = n_PPE_5s_TST;
save G4_TST0p500u100mp000pp000_UE_Final_5PP.mat G4_TST0p500u100mp000pp000_UE_Final_5PP;

% [UE] Final 5s PPR
figure(), box on, hold on;
x7 = 1:1;    % Case idx
y7 = mean(PPR_5s_TST);
bar(x7,y7);
ylabel('5sec Ping-Pong Rate');
set(gca,'XTick',(1:1:1));
set(gca,'xticklabel',{'BDRY-TST1'});
set(gcf,'numbertitle','off');
set(gcf,'name','[BDRY-TST1] UE Final 5sPPR');
G4_TST0p500u100mp000pp000_UE_Final_5PPR = PPR_5s_TST;
save G4_TST0p500u100mp000pp000_UE_Final_5PPR.mat G4_TST0p500u100mp000pp000_UE_Final_5PPR;

% Macro Cell Loading
figure(), box on, grid on, hold on;
x5 = 1:n_MC;
y5 = Load_TST(x5);
bar(x5, y5, 'FaceColor',[.5 .5 .5]);
hold off;
xlabel('Index of MC');			ylabel('Loading');
set(gcf,'Numbertitle','off');	set(gcf,'Name','[BDRY-TST1] MC Loading');
% Pico Cell Loading
figure(), box on, grid on, hold on;
x6 = 1:n_PC;
y6 = Load_TST(n_MC + x6);
bar(x6, y6, 'FaceColor',[.5 .5 .5]);
hold off;
xlabel('Index of PC');			ylabel('Loading');
set(gcf,'Numbertitle','off');	set(gcf,'Name','[BDRY-TST1] PC Loading');
G4_TST0p500u100mp000pp000_BS_Loading = Load_TST;
save G4_TST0p500u100mp000pp000_BS_Loading.mat G4_TST0p500u100mp000pp000_BS_Loading;

% Handover Index
figure, box on, grid on, hold on;
x8 = [n_HO_M2M n_HO_M2P n_HO_P2M n_HO_P2P];
y8 = bar(x8,'FaceColor',[.5 .5 .5]);
hold off;
title('N_{HO.index}');			ylabel('Handover Number');
set(gca,'XTick',(1:1:4),'FontSize',10);
set(gca,'XTickLabel',[]);		set(gca,'xticklabel',{'M2M','M2P','P2M','P2P'});
set(gcf,'Numbertitle','off');	set(gcf,'Name','[BDRY-TST1] Handover INDEX');
G4_TST0p500u100mp000pp000_nHO_M2M = n_HO_M2M;
save G4_TST0p500u100mp000pp000_nHO_M2M.mat G4_TST0p500u100mp000pp000_nHO_M2M;
G4_TST0p500u100mp000pp000_nHO_M2P = n_HO_M2P;
save G4_TST0p500u100mp000pp000_nHO_M2P.mat G4_TST0p500u100mp000pp000_nHO_M2P;
G4_TST0p500u100mp000pp000_nHO_P2M = n_HO_P2M;
save G4_TST0p500u100mp000pp000_nHO_P2M.mat G4_TST0p500u100mp000pp000_nHO_P2M;
G4_TST0p500u100mp000pp000_nHO_P2P = n_HO_P2P;
save G4_TST0p500u100mp000pp000_nHO_P2P.mat G4_TST0p500u100mp000pp000_nHO_P2P;


% [UE] Learning Trend of CBR 		% 2017.01.06
figure, box on, grid on, hold on;
t_uCBR     = 1:n_CONV;
y_TST_uCBR = PRFM_TST_UE_CBR(t_uCBR);
plot(t_uCBR*t_d, y_TST_uCBR);
title('Call Block Rate of UE');
xlabel('Time (sec)');
ylabel('PRFM');
legend('BDRY-TST1');
set(gcf,'numbertitle','off');
set(gcf,'name','[BDRY-TST1] UE CBR Trend');
G4_TST0p500u100mp000pp000_UE_Trend_CBR = PRFM_TST_UE_CBR;
save G4_TST0p500u100mp000pp000_UE_Trend_CBR.mat G4_TST0p500u100mp000pp000_UE_Trend_CBR;
% [UE] Learning Final of CBR
G4_TST0p500u100mp000pp000_UE_Final_CBR = CBR_UE_TST;
save G4_TST0p500u100mp000pp000_UE_Final_CBR.mat G4_TST0p500u100mp000pp000_UE_Final_CBR;


% Drop Reason / Outage Reason
G4_TST0p500u100mp000pp000_UE_DropReason1 = DropReason1_M2M___RB;	save G4_TST0p500u100mp000pp000_UE_DropReason1.mat G4_TST0p500u100mp000pp000_UE_DropReason1;	% Reason 1
G4_TST0p500u100mp000pp000_UE_DropReason2 = DropReason2_M2P___RB;	save G4_TST0p500u100mp000pp000_UE_DropReason2.mat G4_TST0p500u100mp000pp000_UE_DropReason2;
G4_TST0p500u100mp000pp000_UE_DropReason3 = DropReason3_P2M___RB;	save G4_TST0p500u100mp000pp000_UE_DropReason3.mat G4_TST0p500u100mp000pp000_UE_DropReason3;
G4_TST0p500u100mp000pp000_UE_DropReason4 = DropReason4_P2P___RB;	save G4_TST0p500u100mp000pp000_UE_DropReason4.mat G4_TST0p500u100mp000pp000_UE_DropReason4;
G4_TST0p500u100mp000pp000_UE_DropReason5 = DropReason5_M2M__ToS;	save G4_TST0p500u100mp000pp000_UE_DropReason5.mat G4_TST0p500u100mp000pp000_UE_DropReason5;	% Reason 2
G4_TST0p500u100mp000pp000_UE_DropReason6 = DropReason6_M2P__ToS;	save G4_TST0p500u100mp000pp000_UE_DropReason6.mat G4_TST0p500u100mp000pp000_UE_DropReason6;
G4_TST0p500u100mp000pp000_UE_DropReason7 = DropReason7_P2M__ToS;	save G4_TST0p500u100mp000pp000_UE_DropReason7.mat G4_TST0p500u100mp000pp000_UE_DropReason7;
G4_TST0p500u100mp000pp000_UE_DropReason8 = DropReason8_P2P__ToS;	save G4_TST0p500u100mp000pp000_UE_DropReason8.mat G4_TST0p500u100mp000pp000_UE_DropReason8;
G4_TST0p500u100mp000pp000_UE_DropReason9 = DropReason9_MMM_Conn;	save G4_TST0p500u100mp000pp000_UE_DropReason9.mat G4_TST0p500u100mp000pp000_UE_DropReason9;	% Reason 3
G4_TST0p500u100mp000pp000_UE_DropReasonX = DropReasonX_PPP_Conn;	save G4_TST0p500u100mp000pp000_UE_DropReasonX.mat G4_TST0p500u100mp000pp000_UE_DropReasonX;
G4_TST0p500u100mp000pp000_UE_DropReasonY1 = DropReasonY_M2M__TTT;	save G4_TST0p500u100mp000pp000_UE_DropReasonY1.mat G4_TST0p500u100mp000pp000_UE_DropReasonY1;	% Reason 4
G4_TST0p500u100mp000pp000_UE_DropReasonY2 = DropReasonY_M2P__TTT;	save G4_TST0p500u100mp000pp000_UE_DropReasonY2.mat G4_TST0p500u100mp000pp000_UE_DropReasonY2;
G4_TST0p500u100mp000pp000_UE_DropReasonY3 = DropReasonY_P2M__TTT;	save G4_TST0p500u100mp000pp000_UE_DropReasonY3.mat G4_TST0p500u100mp000pp000_UE_DropReasonY3;
G4_TST0p500u100mp000pp000_UE_DropReasonY4 = DropReasonY_P2P__TTT;	save G4_TST0p500u100mp000pp000_UE_DropReasonY4.mat G4_TST0p500u100mp000pp000_UE_DropReasonY4;

% Loading Situation								% 2017.01.06
G4_TST0p500u100mp000pp000_idx_UEcnct = idx_UEcnct_TST;				% 2017.01.06
save G4_TST0p500u100mp000pp000_idx_UEcnct.mat G4_TST0p500u100mp000pp000_idx_UEcnct;	% 2017.01.06

G4_TST0p500u100mp000pp000_LB_IDLE = LB_Idle;	save G4_TST0p500u100mp000pp000_LB_IDLE.mat G4_TST0p500u100mp000pp000_LB_IDLE;	% 2017.01.19
G4_TST0p500u100mp000pp000_LB___PC = LB___PC;	save G4_TST0p500u100mp000pp000_LB___PC.mat G4_TST0p500u100mp000pp000_LB___PC;	% 2017.01.19
G4_TST0p500u100mp000pp000_LB___MC = LB___MC;	save G4_TST0p500u100mp000pp000_LB___MC.mat G4_TST0p500u100mp000pp000_LB___MC;	% 2017.01.19



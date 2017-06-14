% UE_PingPongEffect_Update

function UE_PPE = PingPong_Update(UE_PPE, idx_UEcnct, idx_t)

	UE_PPE(3) = UE_PPE(2);	% UE_PPE(3) represent the BS_idx of the last two connect
	UE_PPE(2) = UE_PPE(1);	% UE_PPE(2) represent the BS_idx of the last one connect
	UE_PPE(1) = idx_UEcnct; % UE_PPE(1) represent the BS_idx of the Handover right now

	UE_PPE(5) = UE_PPE(4);  % UE_PPE(5) represent the time-point of the last one Handover
	UE_PPE(4) = idx_t;		% UE_PPE(4) represent the time-point of the Handover right now

end

% =============================================================
% | UE_PPE(1) | UE_PPE(2) | UE_PPE(3) | UE_PPE(4) | UE_PPE(5) |
% |===========|===========|===========|===========|===========|
% | The BSidx | The BSidx | The BSidx | Time-Pnt  | Time-Pnt  |
% |  of the   |  of the   |  of the   |  of the   |  of the   |
% |  present  | last one  | last two  |  present  | last one  |
% | access/HO | access/HO | access/HO | access/HO | access/HO | 
% -------------------------------------------------------------

% If UE_PPE(1) == UE_PPE(3) but UE_PPE(1) ~= UE_PPE(2) && UE_PPE(3) ~= UE_PPE(2)
% and also UE_PPE(4) - UE_PPE(5) <= 1[sec],
% then we call it Ping-Pong Effect.
%% 計算Q-function

function crntQfx = FQc4_Qfunction(DoT_Rule, Q_table, idx_subAct_choosed)

	% Initialization
	subQ_fx = zeros(1,25);
        
	for idx_rule = 1:25
		subQ_fx(idx_rule) = DoT_Rule(idx_rule) * Q_table(idx_rule, idx_subAct_choosed(idx_rule));
	end

	crntQfx = sum(subQ_fx);
	
end
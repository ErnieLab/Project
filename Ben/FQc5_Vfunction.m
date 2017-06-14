%%最佳action的Q-function

function V_fx = FQc5_Vfunction(DoT_Rule, Q_table)

	subV_fx = zeros(1,25);
	for idx_rule = 1:25
		subV_fx(idx_rule) = DoT_Rule(idx_rule) * max(Q_table(idx_rule,:));
	end

	V_fx = sum(subV_fx);
end
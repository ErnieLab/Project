%% 

function [GlobalAct, idx_subAct_choosed_crnt] = FQc3_GlobalAction(DoT_Rule, Q_table)

	% Initialization
    subGlobalAct = zeros(1,25);
    idx_subAct_choosed_crnt = zeros(1,25);

    % 
	prob_greedy = 0.2;	% There is 20% to choose Q-value randomly, 80% to choose the best Q-value.
	action = [-3, -1.5, 0, 1.5, 3];

	for idx_rule = 1:25
		greedyOrNot = rand(1);
		% Be greedy
		if (greedyOrNot < prob_greedy)
			randomAct = randi(5);
			subGlobalAct(idx_rule) = DoT_Rule(idx_rule) * action(randomAct);
			idx_subAct_choosed_crnt(idx_rule) = randomAct;
		% No greedy	
		elseif (greedyOrNot >= prob_greedy)
			if sum(Q_table(idx_rule,:)) == 0
				randomAct = randi(5);
				subGlobalAct(idx_rule) = DoT_Rule(idx_rule) * action(randomAct);	% 2016.10.27
				idx_subAct_choosed_crnt(idx_rule) = randomAct;
			else
				[maxQvalue,idxQvalue] = max(Q_table(idx_rule,:));
				subGlobalAct(idx_rule) = DoT_Rule(idx_rule) * action(idxQvalue);
				idx_subAct_choosed_crnt(idx_rule) = idxQvalue;
			end
		end
	end

	GlobalAct = sum(subGlobalAct);
end

% idx_subAct_choosed_crnt: will be like
%
% ===============================================================================
% |          | act_rule1_choose | act_rule2_choose | ...... | act_rule25_choose |
% |==========|==================|==================|========|===================|
% |   MC_1   | 	  action 1~5    | 	 action 1~5    | ...... |     action 1~5    |
% |----------|------------------|------------------|--------|-------------------|
% |   MC_2   | 	  action 1~5    | 	 action 1~5    | ...... |     action 1~5    |
% |----------|------------------|------------------|--------|-------------------|
% |    ~     |        ~         |        ~         |    ~   |         ~         |
% |----------|------------------|------------------|--------|-------------------|
% |  PC_105  | 	  action 1~5    | 	 action 1~5    | ...... |     action 1~5    |
% -------------------------------------------------------------------------------
%                                                                                n_BS x 25
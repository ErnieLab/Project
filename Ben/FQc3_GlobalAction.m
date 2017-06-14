%%不一定都是選Q值最大的action，也有考慮隨機選的時候

function [GlobalAct, idx_subAct_choosed_crnt] = FQc3_GlobalAction(DoT_Rule, Q_table)

    

	% Initialization
    subGlobalAct = zeros(1,25);
    idx_subAct_choosed_crnt = zeros(1,25);

    % 
	prob_greedy = 0.2;	% 20%的機率隨機選Q-value , 80%選最大的Q-value.
	action = [-5, -2.5, 0, 2.5, 5];

	for idx_rule = 1:25
		greedyOrNot = rand(1);
		% No greedy(隨機選)
		if (greedyOrNot < prob_greedy)
			randomAct = randi(5);
			subGlobalAct(idx_rule) = DoT_Rule(idx_rule) * action(randomAct); %所選的action*對應的degree of truth (原式分母的DoT總和為1)
			idx_subAct_choosed_crnt(idx_rule) = randomAct;
		% Be greedy(選最大)
		elseif (greedyOrNot >= prob_greedy)
			if sum(Q_table(idx_rule,:)) == 0  %若一開始Q-table都是0的情況，則仍隨機選
				randomAct = randi(5);
				subGlobalAct(idx_rule) = DoT_Rule(idx_rule) * action(randomAct);	% 2016.10.27
				idx_subAct_choosed_crnt(idx_rule) = randomAct;
			else
				[maxQvalue,idxQvalue] = max(Q_table(idx_rule,:));  %Q-table有值，則選最大的
				subGlobalAct(idx_rule) = DoT_Rule(idx_rule) * action(idxQvalue);
				idx_subAct_choosed_crnt(idx_rule) = idxQvalue;
			end
		end
	end

	GlobalAct = sum(subGlobalAct);%每個rule的總和 (原式的分子)
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
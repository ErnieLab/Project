%% Q_table is 25 x 5 matrix
% idx_subAct_choosed_old is 1 x 25 vector
%%更新Q-table

function Q_table = FQc8_Qupdate(Q_table, idx_subAct_choosed_old, LR, Q_bonus, DoT_rule_old)

    for idx_rule = 1:25
		Q_table(idx_rule,idx_subAct_choosed_old(idx_rule)) = Q_table(idx_rule,idx_subAct_choosed_old(idx_rule)) + LR * Q_bonus * DoT_rule_old(idx_rule);
    end
end

% Q-Table
%
% =====================================================
% |          | action 1 | action 2 | ...... | action 5 |
% |==========|==========|==========|========|==========|
% |  rule 1  | 	  q     |    q     | ...... |    q     |
% |----------|----------|----------|--------|----------|
% |  rule 2  | 	  q     |    q     | ...... |    q     |
% |----------|----------|----------|--------|----------|
% |    ~     |    ~     |    ~     |    ~   |    ~     |
% |----------|----------|----------|--------|----------|
% |  rule 25 | 	  q     |    q     | ...... |    q     |
% ------------------------------------------------------
%                                                       25 x 5 
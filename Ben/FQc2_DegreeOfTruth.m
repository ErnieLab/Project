%% 計算degree of truth的4種方法(我們只用第4種相乘的方法)

function DoT_Rule = FQc2_DegreeOfTruth(DoM_CIO, DoM_LOAD, type)

	% Initialization
    DoT_Rule = zeros(1,25);

    switch(type)
        case 'A'		% DoT = max(DoM_CIO, DoM_LOAD) % function 1
            for idx_cio = 1:5
                for idx_load = 1:5
                    DoT_Rule(idx_load+5*(idx_cio-1)) = max(DoM_CIO(idx_cio),DoM_LOAD(idx_load));
                end
            end

        case 'B'	% DoT = min(DoM_CIO, DoM_LOAD) % function 2
            for idx_cio = 1:5
                for idx_load = 1:5
                    DoT_Rule(idx_load+5*(idx_cio-1)) = min(DoM_CIO(idx_cio),DoM_LOAD(idx_load));
                end
            end

        case 'C'	% DoT = DoM_CIO + DoM_LOAD % function 3
            for idx_cio = 1:5
                for idx_load = 1:5
                    DoT_Rule(idx_load+5*(idx_cio-1)) = DoM_CIO(idx_cio) + DoM_LOAD(idx_load);
                end
            end

        case 'D'	% DoT = DoM_CIO * DoM_LOAD % function 4
            for idx_cio = 1:5
                for idx_load = 1:5
                    DoT_Rule(idx_load+5*(idx_cio-1)) = DoM_CIO(idx_cio) * DoM_LOAD(idx_load);
                end
            end
    end
end

% Degree of Truth : will be like
%
% ==========================================================
% |          | rule1_DoT | rule2_DoT | ...... | rule25_DoT |
% |==========|===========|===========|========|============|
% |   MC_1   | 	  mu_1   | 	  mu_2   | ...... |    mu_25   | --> sum = 1
% |----------|-----------|-----------|--------|------------|
% |   MC_2   | 	  mu_1   | 	  mu_2   | ...... |    mu_25   | --> sum = 1
% |----------|-----------|-----------|--------|------------|
% |    ~     |     ~     |     ~     |    ~   |      ~     |
% |----------|-----------|-----------|--------|------------|
% |  PC_105  | 	  mu_1   | 	  mu_2   | ...... |    mu_25   | --> sum = 1
% ----------------------------------------------------------
%                                                           n_BS x 25
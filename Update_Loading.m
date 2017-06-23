% ============================================== %
% 該function是用來更新全部Base  Station的Loading %
% ============================================== %
function [Load_TST] = Update_Loading(n_BS, n_MC, BS_RB_table, n_ttoffered, Pico_part)


for BS_index = 1:1:n_BS
    RB_used_Num = 0;

    if BS_index <= n_MC
    	RB_used_Num = length(nonzeros(BS_RB_table(BS_index, 1:n_ttoffered)))

	    Load_TST(BS_index) = RB_used_Num/n_ttoffered;
	else
		RB_used_Num = length(nonzeros(BS_RB_table(BS_index, 1:Pico_part)))

	    Load_TST(BS_index) = RB_used_Num/Pico_part;
	end
end
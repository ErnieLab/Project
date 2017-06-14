% ======================================================== %
% 該function是用來確認BS配出去的資源，都會有一個UE去接收   %
% ======================================================== %
function Check_RB_Function(UE_RB_used, BS_RB_table, BS_RB_who_used, UE_CoMP_orNOT, idx_UEcnct_TST, idx_UEcnct_CoMP, n_ttoffered, n_UE, n_BS)

% ------------------- %
% 檢查Resource的部分  %
% ------------------- %

% 首先數目要對
UE_RBcost = 0;
for UE_index = 1:1:n_UE
	if UE_CoMP_orNOT(UE_index) == 0
		UE_RBcost = UE_RBcost + length(nonzeros(UE_RB_used(UE_index,:)));
	else
		UE_RBcost = UE_RBcost + length(nonzeros(UE_RB_used(UE_index,:)))*2;
	end
end

BS_RBcost = 0;
for BS_index = 1:1:n_BS	
	BS_RBcost = BS_RBcost + length(nonzeros(BS_RB_table(BS_index,:)));	
end

if UE_RBcost ~= BS_RBcost
	bug = 1
end


% 再來是要1by1 mapping
for BS_index = 1:1:n_BS
	for RB_index = 1:1:n_ttoffered
		if BS_RB_table(BS_index, RB_index) == 1
			if UE_RB_used(BS_RB_who_used(BS_index, RB_index), RB_index) ~= 1
				a = BS_RB_who_used(BS_index, RB_index)
				b = BS_index;
				c = RB_index;
				bug = 2
			end
		end
	end
end






a = 1; 

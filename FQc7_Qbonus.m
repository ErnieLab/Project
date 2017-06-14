%%計算delta Q

function Q_bonus = FQc7_Qbonus(reward, DF, V_fx_crnt, Q_fx_old)

	Q_bonus = reward + DF*V_fx_crnt - Q_fx_old;

end
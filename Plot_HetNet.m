% ================================= %
% è©²Function?¯ç”¨ä¾†ç•«HetNet?„é??Œå?  %
% ================================= %
clc, clear, close all

rectEdge = 4763;
load('MC_lct_4sq'); load('PC_lct_4sq_n250_MP520_PP40');

n_MC = length(Macro_location);
n_PC = length(Pico_location);

P_MC_dBm = 46;
P_PC_dBm = 30;

% Display Beginning System Model
figure(), box on, hold on;
plot(Macro_location(:,1), Macro_location(:,2), 's', 'Color',[0.2 0.4 0.8],'MarkerFaceColor', [0.2 0.4 0.8], 'MarkerSize',12);
plot(Pico_location(:,1), Pico_location(:,2), '^', 'Color',[0.2 0.8 0.4],'MarkerFaceColor', [0.2 0.8 0.4], 'MarkerSize', 7);
% plot(UE_lct(:,1), UE_lct(:,2), '*', 'Color',[0.8 0.0 0.2],'MarkerSize',3);
plot([+1,-1,-1,+1,+1]*rectEdge/2, [+1,+1,-1,-1,+1]*rectEdge/2, 'Color', [0.0 0.0 0.0]);
title('Location of Base Stations');
legend('Macrocell','Picocell','RSRP_{targ} = RSRP_{serv}','location','Northeast');
% legend('Macrocell','Picocell','User');
xlabel('x-axis (meter)'); ylabel('y-axis (meter)');
set(gca,'FontSize',12);
set(gcf,'numbertitle','off');
set(gcf,'name','Heterogeneous Network');

%% Coverage regions
tic
dx = rectEdge/707; % = 11
dy = rectEdge/707; % = 11

crntBS    = -1;          % current BS
dist_MC   = zeros(1, n_MC);
RssMC_dBm = zeros(1, n_MC);
dist_PC   = zeros(1, n_PC);
RssPC_dBm = zeros(1, n_PC);

for y = rectEdge/2 : -dx : -rectEdge/2
    for x = rectEdge/2 : -dy : -rectEdge/2
        lct = [x, y];
        
        % Measure
        for mc = 1:n_MC
            dist_MC(mc) = norm(lct - Macro_location(mc,:));
            RssMC_dBm(mc) = P_MC_dBm - PLmodel_3GPP(dist_MC(mc), 'M');
        end

        for pc = 1:n_PC
            dist_PC(pc) = norm(lct - Pico_location(pc,:));
            RssPC_dBm(pc) = P_PC_dBm - PLmodel_3GPP(dist_PC(pc), 'P');
        end
        
        % Handover procedure
        [maxRssMC, idx_RssMC] = max(RssMC_dBm);
        [maxRssPC, idx_RssPC] = max(RssPC_dBm);
        
        if (maxRssMC > maxRssPC)        % Connect to MC
            HO = (crntBS ~= idx_RssMC);         % 0 if crntBS == idx_RssMC, 1 if crntBS ~= idx_RssMC
            crntBS = idx_RssMC;
        else                            % Connect to PC
            HO = (crntBS ~= idx_RssPC+n_MC);    % 0 if crntBS == idx_RssPC+n_MC, 1 if crntBS ~= idx_RssPC+n_MC
            crntBS = idx_RssPC+n_MC;
        end
        
        if (HO == 1 && x ~= rectEdge/2 && y ~= rectEdge/2)
            plot(x, y,'.k', 'MarkerSize',1)
        end
    end
end

crntBS    = -1;          % current BS
dist_PC   = zeros(1, n_PC);
RssPC_dBm = zeros(1, n_PC);

for x = rectEdge/2-dx/2 : -dx : -rectEdge/2
    for y = rectEdge/2-dy/2 : -dy : -rectEdge/2
        lct = [x, y];

        % Measure
        for mc = 1:n_MC
            dist_MC(mc) = norm(lct - Macro_location(mc,:));
            RssMC_dBm(mc) = P_MC_dBm - PLmodel_3GPP(dist_MC(mc), 'M');
        end

        for pc = 1:n_PC
            dist_PC(pc) = norm(lct - Pico_location(pc,:));
            RssPC_dBm(pc) = P_PC_dBm - PLmodel_3GPP(dist_PC(pc), 'P');
        end
        
        % Handover procedure
        [maxRssMC, idx_RssMC] = max(RssMC_dBm);
        [maxRssPC, idx_RssPC] = max(RssPC_dBm);
        
        if (maxRssMC > maxRssPC)       % Connect to MC
            HO = (crntBS ~= idx_RssMC);
            crntBS = idx_RssMC;
        else                            % Connect to PC
            HO = (crntBS ~= idx_RssPC+n_MC);
            crntBS = idx_RssPC+n_MC;
        end
        
        if (HO == 1 && x ~= rectEdge/2-dx/2 && y ~= rectEdge/2-dy/2)
            plot(x, y,'.k', 'MarkerSize',1)
        end
    end
end
% print -dpng fig_HetNet_SPSQ.png;

toc
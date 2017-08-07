% 2016.11.17 SSL proposed every Simulation's Mobility 

clc, clear ,close all

load('ttSimuT');

% load('n_UE');   % 2016.12.06	

n_UE = 1000;

seedSpeedMDS = zeros(n_UE, ttSimuT);	% Velocity include speed and direction, speed doesn't include direction. 2016.12.04
seedAngleDEG = zeros(n_UE, ttSimuT);
seedEachStep = zeros(n_UE, ttSimuT);

tic
for idx = 1:n_UE
	rand('seed',idx);
	seedSpeedMDS(idx,:) = rand(1, ttSimuT);
	seedAngleDEG(idx,:) = rand(1, ttSimuT) * 2 - 1;
	seedEachStep(idx,:) = randi([120 360], 1, ttSimuT);
end
toc

save ttSimuT.mat      ttSimuT;
save seedSpeedMDS.mat seedSpeedMDS;
save seedAngleDEG.mat seedAngleDEG;
save seedEachStep.mat seedEachStep;

% Following is for FIX SPEED SCENARIO

% ttSimuT_030  = 5400;
% ttSimuT_060  = 2700;
% ttSimuT_090  = 1800;
% ttSimuT_120  = 1350;

% seedEachStep_030 = seedEachStep/1;
% seedEachStep_060 = seedEachStep/2;
% seedEachStep_090 = seedEachStep/3;
% seedEachStep_120 = seedEachStep/4;

% save ttSimuT_030.mat  ttSimuT_030;
% save ttSimuT_060.mat  ttSimuT_060;
% save ttSimuT_090.mat  ttSimuT_090;
% save ttSimuT_120.mat  ttSimuT_120;

% save seedEachStep_030.mat seedEachStep_030;
% save seedEachStep_060.mat seedEachStep_060;
% save seedEachStep_090.mat seedEachStep_090;
% save seedEachStep_120.mat seedEachStep_120;

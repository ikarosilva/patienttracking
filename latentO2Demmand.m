function [net,tr,target,perTrue]=latentO2Demmand(trainData,trainComm,commorbidityNames,show,chckLatentDistFlag)
%
%
% Returns a trained NN, training performance metrics, and generated target 
% for estimation of O2 Delivery where a high value (1) represents high 02
% demands and a low value (0) represents low O2 demands

%Define the following variables as being indicative of an increase in O2
%demands
trueVar={'WEIGHT_LOSS',...
    'METASTATIC_CANCER',...
    'MALE',...
    'PSYCHOSES'};

falseVar={'OBESITY',...
         'PARALYSIS',...
         'OLD_AGE',...
         'PERIPHERAL_VASCULAR'};

[net,tr,target,perTrue]=latentNet(trainData,trainComm,commorbidityNames,trueVar,falseVar,show,chckLatentDistFlag);
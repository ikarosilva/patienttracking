%Script for predicting patient lactate value usign K-means
clear all;close all;clc


%The dataset, lact_db, will contain the features described by the variable
%'column_names, all measurements are from the interpolated series.
%The database is expected to have the input features starting after
%'lact_dxx'

%load lactate-kmeans-dataset-6hours-smoothed % 0.5 hours smoothed data, default
load lactate-interpolated-dataset-0hours-smoothed % 0.5 hours smoothed data, default
lact_db_1=lact_db;        % Prefix with 1...beacause notation is messy with 0.5

%Load smoothed timed series prefix the variables accordingly
smooth_set=[6 12 24];
Nsmooth=length(smooth_set);
for s=1:Nsmooth
    eval(['load lactate-interpolated-dataset-'   num2str(smooth_set(s)) 'hours-smoothed'])
    eval(['lact_db_' num2str(smooth_set(s)) '=lact_db;'])
end

%Normalize Urine by weight (apply quotient rule to derivative)
urine_ind=find(strcmp(column_names,'urine_val')==1);
weight_ind=find(strcmp(column_names,'weight_val')==1);
urine_dx_ind=find(strcmp(column_names,'urine_dx')==1);
weight_dx_ind=find(strcmp(column_names,'weight_dx')==1);

%Update smooth set to have default case and normalize urine over all interpolated sets
smooth_set=[1 6 12 24];
clrs=['krgm'];
Nsmooth=length(smooth_set);
for s=1:Nsmooth
    str=num2str(smooth_set(s));
    eval(['lact_db_' str  '(:,urine_ind)=lact_db_' str '(:,urine_ind)./lact_db_' str '(:,weight_ind);'])
    eval(['urine_dx=lact_db_' str '(:,urine_dx_ind);'])
    eval(['weigth_dx=lact_db_' str '(:,weight_dx_ind);'])
    eval(['urine_dx= ( urine_dx.*lact_db_' str '(:,weight_ind) - lact_db_' str '(:,urine_ind).*weigth_dx)./(lact_db_' str '(:,weight_ind).^2);'])
    eval(['lact_db_' str '(:,urine_dx_ind)=urine_dx;'])
end


%For now only use these columns (other features will be discarded
use_col={'map_val','map_dx','map_var','hr_val','hr_dx','hr_var','urine_val','urine_dx',...
         'urine_var','weight_val','weight_dx','weight_var','pressor_val','pressor_dx'};

Ncol=length(use_col);
del=[1:length(column_names)];
for n=1:Ncol
    ind=find(strcmp(column_names,use_col{n})==1);
    del(ind)=NaN;
end
del(isnan(del))=[];
if(~isempty(del))
    column_names(del)=[];
    for s=1:Nsmooth
        eval(['lact_db_' num2str(smooth_set(s)) '(:,del)=[];'])
    end
end

feat_offset=find(strcmp(column_names,'map_val')==1);
pid=unique(lact_db_1(:,1));
N=length(pid);

    LACT_HAT=[]; %stores prediction of each smoothed set
    lact_db=lact_db_1;
    for s=2:Nsmooth
        %set the dataset to the current smooothed dataset for processing
        eval(['tmp_lact_db=lact_db_' num2str(smooth_set(s)) ';'])
        lact_db=[lact_db tmp_lact_db(:,feat_offset:end)];
    end
      
    %Replace each NaN in the input features by their mean
    M=length(lact_db(1,:));
    Nfeature=M-feat_offset;
    for nf=0:Nfeature
        nans=find(isnan(lact_db(:,feat_offset+nf))==1);
        if(~isempty(nan))
            tmp_mean=nanmean(lact_db(:,feat_offset+nf));
            lact_db(nans,feat_offset+nf)=tmp_mean;
        end
    end 
      
    %Train Neural Net
    net = fitnet([100 8 4 2]);
    net = configure(net,lact_db(:,feat_offset:end)',raw_lact_measurements );
    net.inputs{1}.processFcns={'mapstd','mapminmax'};
    [net,tr] = train(net,lact_db(:,feat_offset:end)',raw_lact_measurements );
    nntraintool
    %plotperform(tr)
    
    %lact_hat = net(x(:,feat_offset:end)');
    %lact_points=lact_measurements{select_pid}; %Get actual lactate measurements  
    %plotregression(tmp_db(:,lact_ind)',lact_hat)
%     
%     if(~isempty(lact_hat))
%         %Plot measured lactate, interpolated lacate, and prediction
%         plot(lact_points(:,1),lact_points(:,2),'bo','LineWidth',3,'MarkerSize',6);hold on;grid on
%             plot(lact_points(:,1),lact_hat)
%         title(['subject= ' num2str(pid(n))])    
%     end

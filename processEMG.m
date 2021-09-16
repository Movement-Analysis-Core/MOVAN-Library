function [varargout]=processEMG(data,freq,file2,HR,varargin)

% [varargout]=processEMG(data,freq,file2,HR)
% inputs    - data, EMG time series
%           - freq, sampling frequency
%           - file2, filename to save figures to
%           - HR, true or false value if heart rate is present and should
%             be filtered
% outputs   - datout.gen, contains general measures of the EMG data
% [varargout]=processEMG(data,freq,file2,HR,Loc1)
% inputs    - data, EMG time series
%           - freq, sampling frequency
%           - file2, filename to save figures to
%           - HR, true or false value if heart rate is present and should
%             be filtered
%           - Loc1, events from which to calculate EMG measures
% outputs   - datout.gen, contains general measures of the EMG data
%           - datout.Loc1, contains measures found using the events.
% [varargout]=processEMG(data,freq,file2,HR,Loc1,Loc2)
% inputs    - data, EMG time series
%           - freq, sampling frequency
%           - file2, filename to save figures to
%           - HR, true or false value if heart rate is present and should
%             be filtered
%           - Loc1, events from which to calculate EMG measures
%           - Loc2, event from which to calculate EMG measures
% outputs   - datout.gen, contains general measures of the EMG data
%           - datout.Loc1, contains measures found using the events.
%           - datout.Loc2, contains measures found using the events.
% Remarks
% - This code was written to process EMG data. It produces general
%   measures, measures based on input events such as heel strikes and toe
%   offs, and measures based on events selected within a subroutine.
% - Processing is fairly quick when using input events. Using the
%   subroutines is slower as it involves automatic selection and manual
%   review of the selected events.
% - The EMG measures with units of volts are not normalized here. That can
%   be done elsewhere using the maximums of the signals or a different
%   signal.
% Subroutines
% - find_act_deact.m (included below)
% - PeakPicker_Boom.m (suplemental)
% Future Work
% - The bandwidth calculation could be improved as it is significantly
%  affected by spikes in the frequency spectrum. It could be changed to
%  calculate the frequency range including 95% of the spectrum above half
%  the maximum power.
% References
% - Bonato, P., Roy, S. H., Knaflitz, M., & De Luca, C. J. (2001). 
%   Time-frequency parameters of the surface myoelectric signal for 
%   assessing muscle fatigue during cyclic dynamic contractions. IEEE 
%   Transactions on Biomedical Engineering, 48(7), 745-753.
% Jan 2019 - Created by Ben Senderling, email unonbcf@unomaha.edu
% Jun 2019 - Modified by Ben Senderling, email unonbcf@unomaha.edu
%          - Added code to calculate instantaneous frequency using a
%            built-in MATLAB function. For application check references.
%
% Copyright 2020 Movement Analysis Core, Center for Human Movement
% Variability, University of Nebraska at Omaha
%
% Redistribution and use in source and binary forms, with or without 
% modification, are permitted provided that the following conditions are 
% met:
%
% 1. Redistributions of source code must retain the above copyright notice,
%    this list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright 
%    notice, this list of conditions and the following disclaimer in the 
%    documentation and/or other materials provided with the distribution.
%
% 3. Neither the name of the copyright holder nor the names of its 
%    contributors may be used to endorse or promote products derived from 
%    this software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS 
% IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
% THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
% PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR 
% CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
% EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
% PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
% PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
% LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
% NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%%

dbstop if error

%% Checks for the input events.

if length(varargin)==1
    Loc1=varargin{1};
elseif length(varargin)==2
    Loc1=varargin{1};
    Loc2=varargin{2};
end

%% Filtering

time=(0:length(data)-1)/freq;
frame=(1:length(data))';

data=data-mean(data); % removes offset

% Filters to remove low frequency movement artifact and hish frequency
% noise.
bp=[10,500]/(freq/2);
[b,a]=butter(4,bp,'bandpass');
data_filt=filtfilt(b,a,data);

% Notch filter to attempt to remove heart rate noise if the input HR is
% true.
if HR==1
    [b,a]=butter(4,[95,105]/(freq/2),'stop');
    data_filt=filtfilt(b,a,data_filt);
end

%% Frequency Spectrum

[data_fft_unfilt,freqs1]=periodogram(data,[],[],freq);
[data_fft,freqs2]=periodogram(data_filt,[],[],freq);

data_fft_cum=cumsum(data_fft);
ind=find(data_fft_cum>sum(data_fft)/2,1);
% Median frequency calculated as where the cumulative frequency spectrum 
% passes half the total area under the frequency spectrum.
medianfreq(1)=freqs2(ind);
% Mean frequency is a weighted average of the frequency spectrum.
meanfreq(1)=sum(data_fft.*freqs2)/sum(data_fft);
ind=find(data_fft>max(data_fft)/2);
% Bandwidth is the difference in frequency between the last and first 
% frequency with a power larger than half the max.
bandwidth=freqs2(ind(end))-freqs2(ind(1));

% Finds the mean and median frequency for the first, second, third and
% fourth quarters of the signal.
ind2=length(data_filt)*(0:0.25:1);
ind2(1)=1;
for i=2:length(ind2)
    [data_fft,freqs2]=periodogram(data_filt(round(ind2(i-1)):round(ind2(i))),[],[],freq);
    data_fft_cum=cumsum(data_fft);
    ind3=find(data_fft_cum>sum(data_fft)/2,1);
    medianfreq(i)=freqs2(ind3);
    meanfreq(i)=sum(data_fft.*freqs2)/sum(data_fft);
end

% Instantaneous frequency

[ifq,t]=instfreq(data_filt,freq);
instantfreq=[ifq,t];

% Windowing

data_rect=abs(data_filt); % rectified EMG

win=round(50/1000*freq); % 50 ms window for moving average
data_win=movmean(data_rect,win); % windowed EMG
data.gen.win=data_win;

data_rms=zeros(length(data_rect),1); % RMS EMG
for i=ceil(win/2)+1:length(data_filt)-ceil(win/2)
    data_rms(i-floor(win/2):i+floor(win/2))=sqrt(mean((data_rect(i-floor(win/2):i+floor(win/2)).^2)));
end
data.gen.rms=data_rms;

% This evelope is found using a butterworth filter. This is used in the
% calculations below.
cf=6/(freq/2);
[b,a]=butter(4,cf,'low');
data_env=filtfilt(b,a,data_rect);
data.gen.env=data_env;

%% Resampling for envelope plots

if exist('minLoc','var')
    for i=1:length(Loc1)-1
        temp=data_env(Loc1(i):Loc1(i+1));
        temp=resample(temp,101,length(temp));
        data_ave(1:101,i)=temp;
    end
end

%%

% Looks for a previous peakpicker file with saved events.
if exist([file2 '.mat'],'file')==2
    quest3=questdlg('A previous peakpicker file has been found. Would you like to use it?','','Yes','No','No');
end
if strcmp(quest3,'Yes')
    load(file2) % loads the file if it was found.
else
    
    emgON=[];
    emgOFF=[];
    quest='Yes';
    
    while any(emgOFF<emgON) || isempty(emgOFF) || isempty(emgON) || strcmp(quest,'Yes')
        
        % If neither is selected the code will still use the Loc1 and Loc2
        % events.
        quest2=questdlg('Which method would you like to use?','','Threshold','Minimum','Neither','Neither');
%         quest2='Neither'; % comment out the line above and uncomment this line to avoid the quest dialog.
        if strcmp(quest2,'Threshold')
            
            [emgON,emgOFF]=find_act_deact(data_env,freq); % runs a threshold based algorithm to find activations and deactivations.
            
            if emgON(1)>emgOFF(1)
                emgOFF(1)=[];
            end
            if any(emgOFF<emgON)
                quest=questdlg('Bad events detected. Reselect events?','','Yes','No','No');
                if strcmp(quest,'No')
                    error('The code cannot continue without properly sequenced events.')
                end
            else
                quest='No';
            end
            
        elseif strcmp(quest2,'Minimum')
            % Runs an algorithm to find extreama.
            if length(varargin)==1
                datout=PeakPicker_Boom(freq,data_env,file2,Loc1);
            elseif length(varargin)==2
                datout=PeakPicker_Boom(freq,data_env,file2,Loc1,Loc2);
            else
                datout=PeakPicker_Boom(freq,data_env,file2,Loc1,Loc2);
            end
            
            if isempty(datout)
                emgON=[0;0];
                emgOFF=[0;0];
                quest='No';
            end
            emgMin=datout.peaksmin(:,1); % the minima will be both the activations and deactivations
            emgpeak=datout.peaksmax;
            % Adjust the events to ensure they are sequenced and start with
            % a minima.
            while emgpeak(1,1)<emgMin(1)
                emgpeak(1,:)=[];
            end
            while emgMin(end-1)>emgpeak(end,1)
                emgMin(end)=[];
            end
            emgON=emgMin(1:end-1);
            emgOFF=emgMin(2:end);
            if length(emgON)~=length(emgpeak)
                quest=questdlg('Bad events detected. Reselect events?','','Yes','No','No');
                if strcmp(quest,'No')
                    error('The code cannot continue without properly sequenced events.')
                end
                continue
            end
            if (any(emgON>emgpeak(:,1)) || any(emgOFF<emgpeak(:,1)))
                quest=questdlg('Bad events detected. Reselect events?','','Yes','No','No');
                if strcmp(quest,'No')
                    error('The code cannot continue without properly sequenced events.')
                end
            else
                quest='No';
            end
        else
            emgON=[0;0];
            emgOFF=[0;0];
            quest='No';
        end
        
    end
    
    save([file2 '.mat'])
    
end

%% Calculate general measures

data_ave1=[];

datout.gen.medianfreq=medianfreq;
datout.gen.meanfreq=meanfreq;
datout.gen.instfreq=instantfreq;
datout.gen.bandwidth=bandwidth;
if ~(sum(emgON)==0 && sum(emgOFF)==0)
    for i=1:length(emgON)-1 % iterates through each activation-deactivation
        
        % Used for evelope plots.
        temp=data_env(emgON(i):emgON(i+1));
        temp=resample(temp,101,length(temp));
        data_ave1(1:101,i)=temp;
        
        datout.gen.mean(i,1)=mean(data_env(emgON(i):emgOFF(i)));
        datout.gen.maxVal(i,1)=emgpeak(i,2);
        datout.gen.maxTim(i,1)=(emgpeak(i,1)-emgON(i))/(emgON(i+1)-emgON(i));
        area=cumtrapz(emgON(i):emgOFF(i),data_env(emgON(i):emgOFF(i)));
        datout.gen.area(i,1)=area(end)/freq;
        datout.gen.duraON(i,1)=(emgOFF(i)-emgON(i))/(emgON(i+1)-emgON(i));
        datout.gen.duraOFF(i,1)=(emgON(i+1)-emgOFF(i))/(emgON(i+1)-emgON(i));
        
    end
end

%% Calculates Loc1 measures

if ~isempty(varargin)
    data_ave2=[];
    
    for i=1:length(Loc1)-1 % iterates through events
        datout.Loc1.mean(i,1)=mean(data_env(round(Loc1(i)):round(Loc1(i+1))));
        [datout.Loc1.maxVal(i,1),I]=max(data_env(round(Loc1(i)):round(Loc1(i+1))));
        datout.Loc1.maxTim(i,1)=(I+Loc1(i)-1-Loc1(i))/(Loc1(i+1)-Loc1(i));
        [datout.Loc1.minVal(i,1),I]=min(data_env(round(Loc1(i)):round(Loc1(i+1))));
        datout.Loc1.minTim(i,1)=(I+Loc1(i)-1-Loc1(i))/(Loc1(i+1)-Loc1(i));
        area=cumtrapz(round(Loc1(i)):round(Loc1(i+1)),data_env(round(Loc1(i)):round(Loc1(i+1))));
        datout.Loc1.area(i,1)=area(end)/freq;
        datout.Loc1.val(i,1)=data_env(round(Loc1(i)));
        
        % Used for evelope plots.
        if i==1
            temp=[zeros(5,1);data_env(Loc1(i):Loc1(i+1));zeros(5,1)];
        else
            temp=data_env(round(Loc1(i)-5):round(Loc1(i+1)+5));
        end
        temp=resample(temp,111,length(temp));
        data_ave2(1:101,i)=temp(6:106);
    end
    
    % If peakpicking was performed the code will calculate the relative
    % timing of the Loc1 events and the muscle activations/deactivations.
    if ~(sum(emgON)==0 && sum(emgOFF)==0)
        
        % Checks ordering of events and activations/deactivations.
        while emgON(1)<Loc1(1)
            emgON(1)=[];
        end
        while Loc1(2)<emgON(1)
            Loc1(1)=[];
        end
        while length(Loc1)>length(emgON)
            Loc1(end)=[];
        end
        for i=1:length(Loc1)-1
            
            emgONNorm(i,1)=(emgON(i)-Loc1(i))/(Loc1(i+1)-Loc1(i));
            % EMG activations can occur before or after events. These lines
            % attempt to adjust those values.
            if emgONNorm(i)<0
                emgONNorm(i)=emgONNorm(i)+1;
            end
            if emgONNorm(i)>1
                emgONNorm(i)=emgONNorm(i)-1;
            end
            emgOFFNorm(i,1)=(emgOFF(i)-Loc1(i))/(Loc1(i+1)-Loc1(i));
            if emgOFFNorm(i)<0
                emgOFFNorm(i)=emgOFFNorm(i)+1;
            end
            if emgOFFNorm(i)>1
                emgOFFNorm(i)=emgOFFNorm(i)-floor(emgOFFNorm(i));
            end
            
            datout.Loc1.timeON(i,1)=emgONNorm(i,1);
            datout.Loc1.timeOFF(i,1)=emgOFFNorm(i,1);
            
        end
    end
    
end

%% Calculates Loc2 measures

% Measures involving Loc2 also involve Loc1

if length(varargin)==2
    
    % Checks ordering of events
    while Loc2(1)<Loc1(1)
        Loc2(1)=[];
    end
    while length(Loc1)<length(Loc2)
        Loc2(end)=[];
    end
    for i=1:length(Loc1)-1 % iterates through Loc1 events
        
        Loc2norm(i,1)=(Loc2(i)-Loc1(i))/(Loc1(i+1)-Loc1(i));
        
        datout.Loc2.mean1(i,1)=mean(data_env(round(Loc1(i)):round(Loc2(i))));
        datout.Loc2.mean2(i,1)=mean(data_env(round(Loc2(i)):round(Loc1(i+1))));
        
        [datout.Loc2.maxVal1(i,1),I]=max(data_env(round(Loc1(i)):round(Loc2(i))));
        datout.Loc2.maxTim1(i,1)=(I+Loc1(i)-1-Loc1(i))/(Loc1(i+1)-Loc1(i));
        
        [datout.Loc2.maxVal2(i,1),I]=max(data_env(round(Loc2(i)):round(Loc1(i+1))));
        datout.Loc2.maxTim2(i,1)=(I+Loc2(i)-1-Loc1(i))/(Loc1(i+1)-Loc1(i));
        
        [datout.Loc2.minVal1(i,1),I]=min(data_env(round(Loc1(i)):round(Loc2(i))));
        datout.Loc2.minTim1(i,1)=(I+Loc1(i)-1-Loc1(i))/(Loc1(i+1)-Loc1(i));
        
        [datout.Loc2.minVal2(i,1),I]=min(data_env(round(Loc2(i)):round(Loc1(i+1))));
        datout.Loc2.minTim2(i,1)=(I+Loc2(i)-1-Loc1(i))/(Loc1(i+1)-Loc1(i));
        
        area=cumtrapz(round(Loc1(i)):round(Loc2(i)),data_env(round(Loc1(i)):round(Loc2(i))));
        datout.Loc2.area1(i,1)=area(end)/freq;
        area=cumtrapz(round(Loc2(i)):round(Loc1(i+1)),data_env(round(Loc2(i)):round(Loc1(i+1))));
        datout.Loc2.area2(i,1)=area(end)/freq;
        datout.Loc2.event2time(i,1)=Loc2norm(i,1);
        
        datout.Loc2.val(i,1)=data_env(round(Loc2(i)));
        
    end
end

%% Fancy figure

a=max([data_win;data_rms;data_env]);

H(1)=figure;
H(1).Visible='Off';
subplot(4,4,[9:10]),plot(time,data,'r--',time,data_filt,'b--')
xlabel('time (s)')
ylabel('voltage')
legend('raw','filtered'),axis tight
subplot(4,4,(11:12)),plot(freqs1,data_fft_unfilt,'r',freqs2,data_fft,'b')
xlabel('frequency (Hz)')
ylabel('power')
title('Frequency Spectrum')
axis tight
hold on
plot([datout.gen.medianfreq(1);datout.gen.medianfreq(1)],[ylim])
hold off
legend('unfiltered','filtered','median frequency')
subplot(4,4,(13:16)),plot(time,data_rect/max(data_rect),time,data_win/max(data_win),'r',time,data_rms/max(data_rms),'b',time,data_env/max(data_env),'g')
xlabel('time (s)')
ylabel('voltage')
title('Rectified EMG')
axis tight
hold on
if ~isempty(varargin)
    y=repmat([0,1],length(Loc1),1);
    plot([time(round(Loc1));time(round(Loc1))],y','k')
end
if length(varargin)==2
    y=repmat([0,1],length(Loc2),1);
    plot([time(round(Loc2));time(round(Loc2))],y','k--')
end
if sum(emgON)~=0 && sum(emgOFF)~=0
    y=repmat([0,1/2],length(emgON),1);
    plot([time(emgON);time(emgON)],y','r')
    y=repmat([1/2,1],length(emgOFF),1);
    plot([time(emgOFF);time(emgOFF)],y','b')
end
hold off

flag=1;
subplot(4,4,[3:4,7:8])
if isempty(varargin) && (sum(emgON)~=0 && sum(emgOFF)~=0)
    data_ave=data_ave1./max(max(data_ave1));
elseif ~isempty(varargin)
    data_ave=data_ave2./max(max(data_ave2));
else
    flag=0;
end

if flag==1
    
    subplot(4,4,[3:4,7:8])
    means=mean(data_ave,2);
    stds=std(data_ave,0,2);
    g(1)=fill([0:100,100:-1:0],[mean(data_ave,2)-stds;flipud(mean(data_ave,2)+stds)],[0.8,0.8,0.8]);
    hold on
    g(2)=plot(means,'k');
    axis tight
    
    subplot(4,4,[1:2,5:6])
    plot((0:100)',data_ave);
    hold on
    
    
    if isempty(varargin) && (sum(emgON)~=0 && sum(emgOFF)~=0)
        subplot(4,4,[3:4,7:8])
        emgOFFNorm_ave=mean(datout.gen.duraON);
        g(3)=plot([emgOFFNorm_ave';emgOFFNorm_ave']*101,[0,1]','b');
        axis tight
        legend(g(3),{'off'})
        
        subplot(4,4,[1:2,5:6])
        emgOFFNorm_ave=mean(datout.gen.duraON);
        plot([emgOFFNorm_ave';emgOFFNorm_ave']*101,[0,1]','b');
        axis tight
    end
    if ~isempty(varargin) && (sum(emgON)~=0 && sum(emgOFF)~=0)
        subplot(4,4,[3:4,7:8])
        emgONNorm_ave=mean(emgONNorm);
        g(4)=plot([emgONNorm_ave';emgONNorm_ave']*101,[0,1]','r');
        emgOFFNorm_ave=mean(emgOFFNorm);
        g(5)=plot([emgOFFNorm_ave';emgOFFNorm_ave']*101,[0,1]','b');
        legend(g(4:5),{'EMG On','EMG Off'})
        
        subplot(4,4,[1:2,5:6])
        emgONNorm_ave=mean(emgONNorm);
        plot([emgONNorm_ave';emgONNorm_ave']*101,[0,1]','r');
        emgOFFNorm_ave=mean(emgOFFNorm);
        plot([emgOFFNorm_ave';emgOFFNorm_ave']*101,[0,1]','b');
    end
    if length(varargin)==1
        subplot(4,4,[3:4,7:8])
        maxValNorm=mean(datout.Loc1.maxTim);
        g(6)=plot([maxValNorm';maxValNorm']*101,[0,1]','r');
        minValNorm=mean(datout.Loc1.minTim);
        g(7)=plot([minValNorm';minValNorm']*101,[0,1]','b');
        axis tight
        legend(g(6:7),{'Maximum','Minimum'})
        
        subplot(4,4,[1:2,5:6])
        maxValNorm=mean(datout.Loc1.maxTim);
        plot([maxValNorm';maxValNorm']*101,[0,1]','r');
        minValNorm=mean(datout.Loc1.minTim);
        plot([minValNorm';minValNorm']*101,[0,1]','b');
        axis tight
    elseif length(varargin)==2
        subplot(4,4,[3:4,7:8])
        means2=mean(Loc2norm);
        g(6)=plot([means2';means2']*101,[0,1]','k--');
        maxVal1Norm=mean(datout.Loc2.maxTim1);
        g(7)=plot([maxVal1Norm';maxVal1Norm']*101,[0,1]','r');
        minVal1Norm=mean(datout.Loc2.minTim1);
        g(8)=plot([minVal1Norm';minVal1Norm']*101,[0,1]','b');
        maxVal2Norm=mean(datout.Loc2.maxTim2);
        g(9)=plot([maxVal2Norm';maxVal2Norm']*101,[0,1]','r--');
        minVal2Norm=mean(datout.Loc2.minTim2);
        g(10)=plot([minVal2Norm';minVal2Norm']*101,[0,1]','b--');
        axis tight
        legend(g(6:10),{'Loc2','Max1','Min1','Max2','Min2'})
        
        subplot(4,4,[1:2,5:6])
        means2=mean(Loc2norm);
        plot([means2';means2']*101,[0,1]','k--');
        maxVal1Norm=mean(datout.Loc2.maxTim1);
        plot([maxVal1Norm';maxVal1Norm']*101,[0,1]','r');
        minVal1Norm=mean(datout.Loc2.minTim1);
        plot([minVal1Norm';minVal1Norm']*101,[0,1]','b');
        maxVal2Norm=mean(datout.Loc2.maxTim2);
        plot([maxVal2Norm';maxVal2Norm']*101,[0,1]','r--');
        minVal2Norm=mean(datout.Loc2.minTim2);
        plot([minVal2Norm';minVal2Norm']*101,[0,1]','b--');
        axis tight
    end
    subplot(4,4,[3:4,7:8])
    hold off
    xlabel('Percent Cycle (%)')
    ylabel('EMG Amplitude (V)')
    
    subplot(4,4,[1:2,5:6])
    hold off
    xlabel('Percent Cycle (%)')
    ylabel('EMG Amplitude (V)')
    a=ylim;
    
    subplot(4,4,[3:4,7:8])
    ylim(a)
    subplot(4,4,[1:2,5:6])
    ylim(a)
    
    savefig(H(1),[file2])
    
    %% Second fancy figure
    
    H(2)=figure;
    H(2).Visible='Off';
    if isempty(varargin) && (sum(emgON)~=0 && sum(emgOFF)~=0)
        data_ave=data_ave1./max(max(data_ave1));
    elseif ~isempty(varargin)
        data_ave=data_ave2./max(max(data_ave2));
    end
    means=mean(data_ave,2);
    stds=std(data_ave,0,2);
    
    g(1)=fill([1:101,101:-1:1],[mean(data_ave,2)-stds;flipud(mean(data_ave,2)+stds)],[0.8,0.8,0.8]);
    hold on
    g(2)=plot(means,'k');
    axis tight
    if isempty(varargin) && (sum(emgON)~=0 && sum(emgOFF)~=0)
        emgOFFNorm_ave=mean(datout.gen.duraON);
        g(3)=plot([emgOFFNorm_ave';emgOFFNorm_ave']*101,[0,1]','b');
        axis tight
        legend(g(3),{'off'})
    end
    if ~isempty(varargin) && (sum(emgON)~=0 && sum(emgOFF)~=0)
        emgONNorm_ave=mean(emgONNorm);
        g(4)=plot([emgONNorm_ave';emgONNorm_ave']*101,[0,1]','r');
        emgOFFNorm_ave=mean(emgOFFNorm);
        g(5)=plot([emgOFFNorm_ave';emgOFFNorm_ave']*101,[0,1]','b');
        legend(g(4:5),{'EMG On','EMG Off'})
    end
    if length(varargin)==1
        maxValNorm=mean(datout.Loc1.maxTim);
        g(6)=plot([maxValNorm';maxValNorm']*101,[0,1]','r');
        minValNorm=mean(datout.Loc1.minTim);
        g(7)=plot([minValNorm';minValNorm']*101,[0,1]','b');
        axis tight
        legend(g(6:7),{'Maximum','Minimum'})
    elseif length(varargin)==2
        means2=mean(Loc2norm);
        g(6)=plot([means2';means2']*101,[0,1]','k--');
        maxVal1Norm=mean(datout.Loc2.maxTim1);
        g(7)=plot([maxVal1Norm';maxVal1Norm']*101,[0,1]','r');
        minVal1Norm=mean(datout.Loc2.minTim1);
        g(8)=plot([minVal1Norm';minVal1Norm']*101,[0,1]','b');
        maxVal2Norm=mean(datout.Loc2.maxTim2);
        g(9)=plot([maxVal2Norm';maxVal2Norm']*101,[0,1]','r--');
        minVal2Norm=mean(datout.Loc2.minTim2);
        g(10)=plot([minVal2Norm';minVal2Norm']*101,[0,1]','b--');
        axis tight
        legend(g(6:10),{'Loc2','Max1','Min1','Max2','Min2'})
    end
    hold off
    xlabel('Percent Cycle (%)')
    ylabel('EMG Amplitude (V)')
    
    saveas(H(2),[file2 '_2.jpg']);
    savefig(H(2),[file2 '_2'])
    
    close(H(1))
    close(H(2))
    
end

%% Create output

varargout{1}=datout.gen;

if ~isempty(varargin)
    varargout{2}=datout.Loc1;
end
if length(varargin)==2
    varargout{3}=datout.Loc2;
end

end

%%

function [emgON,emgOFF]=find_act_deact(emg,freq)

% [emgON,emgOFF]=find_act_deact(emg,freq)
% inputs  - emg, time series
%         - freq, sampling frequency
% outputs - emgON, frames where EMG is activated
%         - emgOFF, frames where EMG is deactivated
% Remarks
% - This code create a GUI that allows automatic selection of events. Once 
%   that GUI is closed it is followed by a manual review.
% - This code works well for gait and other activities with clear
%   activations and deactivations. It does not work well for
%   cardiopulmonary resucitation. It was originally written for finding
%   heel strikes and toe offs from ground reaction forces.
% - This code has not be extensively tested.
% - The peakStepThrough.m subroutine is borrowed from PeakPicker.m.
% Subroutines
% - findextrema
% - peakStepThrough
% Future Work
% - More testing and use.
% Jan 2019 - Created by Ben Senderling, email unonbcf@unomaha.edu

emg=(emg-min(emg))/range(emg);
time=(0:length(emg)-1)/freq;

h.f=figure('Units','Normalized','Position',[0.1,0.1,0.8,0.8]);
h.p(1)=subplot(4,1,(1:3));plot([]);
h.p(2)=subplot(4,1,4);plot([]);

pos1=[(1-h.p(1).Position(1)-h.p(1).Position(3))/4+h.p(1).Position(1)+h.p(1).Position(3),...
    h.p(1).Position(2),...
    (1-h.p(1).Position(1)-h.p(1).Position(3))/4,...
    h.p(1).Position(4)];
pos2=[h.p(1).Position(1),0.05*h.p(1).Position(2),h.p(1).Position(3),(1-h.p(1).Position(1)-h.p(1).Position(3))/4];

h.s(1)=uicontrol('Style','slider',...
    'Min',0,'Max',1,'Value',0.5,...
    'Units','Normalized','Position',pos1,...
    'Callback', @findextrema);
h.s(2)=uicontrol('Style','slider',...
    'Min',1,'Max',freq,'Value',freq/2,...
    'Units','Normalized','Position',pos2,...
    'Callback', @findextrema);

findextrema

uiwait % waits until GUI is closed

[emgON]=peakStepThrough(emgON,data_env,ques1);
[emgOFF]=peakStepThrough(emgOFF,data_env,ques2);

    function findextrema(varargin)
        % findextrema(varargin)
        % inputs  - varargin
        %         - global variables
        % outputs - global variables
        % Remarks
        % - This subroutine shares the workspace with it's parent function.
        % - When sliders are adjusted in the parent function this code is
        %   executed to find the events.
        % Future Work
        % - More testing.
        % Jan 2019 - Created by Ben Senderling, email unonbcf@unomaha.edu
        
        % works out better not checking the slope for the toe offs
        emgON=find(emg(1:end-1)>h.s(1).Value);
        emgOFF=find(emg(1:end-1)<h.s(1).Value);
        
        demgON=diff(emgON);
        demgOFF=diff(emgOFF);
        
        ind=find((demgON<h.s(2).Value))+1;
        emgON(ind)=[];
        ind=find((demgOFF<h.s(2).Value))+1;
        emgOFF(ind)=[];
        
        demgON=diff(emgON);
        demgOFF=diff(emgOFF);
        ques1=emgON((demgON>mean(demgON)+std(demgON)) | (demgON<mean(demgON)-std(demgON)));
        ques2=emgOFF((demgOFF>mean(demgOFF)+std(demgOFF)) | (demgOFF<mean(demgOFF)-std(demgOFF)));
        
        h.p(1)=subplot(4,1,(1:3));plot(time,emg,time(emgON),emg(emgON),'rx',time(emgOFF),emg(emgOFF),'bo')
        h.p(2)=subplot(4,1,4);plot(emgON(1:end-1),diff(emgON),'r',emgOFF(1:end-1),diff(emgOFF),'b')
        hold on
        y=repmat([0,max([demgON;demgOFF])],length(ques1),1);
        plot([ques1,ques1]',y','r--')
        y=repmat([0,max([demgON;demgOFF])],length(ques2),1);
        plot([ques2,ques2]',y','b--')
        hold off
        
    end

end

function [peaksFinal]=peakStepThrough(peaks,X,ques)

% [peaksFinal]=peakStepThrough(peaks,X,ques)
% inputs  - peaks, indexes of the extrema
%         - X, time series
%         - ques, frames of questionable extrema
% outputs - peaksFinal, corrected indexes of the extrema
% Remarks
% - This code is largely borrowed from PeakPicker.m.
% - The left and right arrow keys move the graph left and right. Up zooms
%  in while down zooms out. Delete removes all point within a small window.
%  Enter adds a point at the maximum. The "n" key create a special event.
% Future Work
% - The ability to find questionable points could be improved.
% Jan 2019 - Created by Ben Senderling, email unonbcf@unomaha.edu

%%
close all;

windowSize = 250;
i = 1; i2 = 1;
counter = 0; counter1 = 0;
corrected = 0;
removed = 0;
NaNLoc=[];

h = figure;
set(h,'units','normalized','position',[0.2 0.2 0.6 0.6])
plot(X), hold on, grid on
scatter(peaks,X(peaks),'g*')
scatter(NaNLoc,X(NaNLoc),'m','filled');
y=repmat([0,max([X;X])],length(ques),1);
plot([ques,ques]',y','r--')
axis tight

k = 0;
while k ~= 27 %% Escape button
    if i > length(X)/windowSize
        i = length(X)/windowSize;
    else
    end
    
    axis([windowSize*(i-1)-50,windowSize*i+50,min(X)-abs(min(X))*0.1,max(X)+abs(max(X))*0.1]);
    
    waitforbuttonpress;
    k = get(h,'CurrentCharacter');
    k = uint8(k);
    % Check button pressed
    switch lower(k)
        case 28 % <- (left arrow key)
            if i > 1
                i = i-1;
            else
            end
            
        case 29 % <- (right arrow key)
            if i <= length(X)/windowSize
                i = i+1;
            else
            end
            
            
        case 8 % Delete
            if i >= (length(X)/windowSize)+windowSize
                
            else
                [x,~] = ginput(1);
                for i1 = 1:length(peaks)
                    if peaks(i1) + 10 > length(X)
                        window1 = length(X) - peaks(i1) - 1;
                    elseif peaks(i1) <= 11
                        window1 = peaks(i1) - 1;
                    else
                    end
                    window1 = 10;
                    if peaks(i1) < x + window1 && peaks(i1) > x - window1
                        scatter(peaks(i1),X(peaks(i1)),'r*');
                        removed(i2) = peaks(i1); i2 = i2+1;
                        peaks(i1) = 0;
                    end
                end
                
                for i1 = 1:length(corrected)
                    if peaks(i1) + 10 > length(X)
                        window1 = length(X) - peaks(i1) - 1;
                    elseif peaks(i1) <= 11
                        window1 = peaks(i1) - 1;
                    else
                    end
                    if corrected(i1) < x+window1 && corrected(i1) > x-window1
                        scatter(corrected(i1),X(corrected(i1)),'r*');
                        removed(i2) = corrected(i1); i2 = i2+1;
                        corrected(i1) = 0;
                    end
                end
            end
            
        case 13 % Return
            if exist('l','var') == 1
            else
                l = 1;
            end
            if i >= (length(X)/windowSize)+windowSize
                
            else
                [x,~] = ginput(1);
                x = round(x);
                if x < 1
                    x = 1;
                end
                if x > length(X)
                    x = length(X);
                end
                
                corrected(l) = x;
                scatter(corrected(l),X(corrected(l)),'b*');
                for i1 = 1:length(removed)
                    if corrected(l) == removed(i1)
                        removed(i1) = 0;
                    end
                end
            end
            l = l+1;
            
        case 30 % Down arrow
            windowSize = windowSize/2;
            fprintf('Zoomed in, decreased window size to %d\n',windowSize);
            
        case 31 % Up arrow
            windowSize = windowSize*2;
            fprintf('Zoomed out, increased window size to %d\n',windowSize);
            
        case 110 % n key
            [x,~] = ginput(1);
            x=round(x);
            NaNLoc(end+1,1)=x;
            scatter(NaNLoc,X(NaNLoc),'m','filled');
    end
end

combined = sort([corrected';peaks]);

for i = 1:length(combined)
    if combined(i) == 0
        counter = counter + 1;
    else
    end
end

peaksFinal = combined(1+counter:length(combined));
hold off
end








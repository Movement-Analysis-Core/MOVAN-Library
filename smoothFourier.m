function [varargout]=smoothFourier20200813(y,fs,varargin)
% [ys]=smoothFourier20200813(y,fs,'cutoff',fc,mplot)
% inputs  - y, time series
%         - fs, sampling frequency
%         - fc, cut-off frequency
%         - mplot, boolean indicating if the results should be plotted
% outputs - ys, smoothed time series
% [ys,fc]=smoothFourier20200813(y,fs,'power',p,mplot)
% inputs  - p, power at which to calculate the cut-off frequency
% outputs - fc, cut-off frequency
% Remarks
% - This code can be used to filter a time series in the frequency spectrum
%   using a low-pass filter cutoff or a target cummulative power over which
%   all frequency content will be removed.
%   spectrum.
% Future Work
% - Options to perform a high-pass, band-pass or band-stop filter could be
%   added.
% Oct 2016 - Created by Ben Senderling, bsenderling@unomaha.edu
% Jun 2018 - Modified by Ben Senderling, bsenderling@unomaha.edu
%          - The ifft could not handle negative values. The fft was
%            modified to make this easier.
% Apr 2019 - Modified by Ben Senderling, bsenderling@unomaha.edu
%          - Corrected error with plotting values against t.
% Aug 2020 - Modified by Ben Senderling, bmchmovan@unomaha.edu
%          - Added nfft input to fft and ifft functions to improve
%            performance. Added the use of fftshit and ifftshift to help
%            ensure the right frequencies are zeroed.
%          - Changed input to a varargin and separated the two methods for
%            using a cutoff frequency and using a cummulative power limit.
%            Made the plot optional.
%          - The method removes all frequency content with a power below
%            0.005.
%          - Updated comments.
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
%% Create example time series
% fs=1000;
% f=10;
% phase=10;
% t=(0:1/fs:10)';
% y=sin(2*pi*f/2*t+phase)+0.5*sin(2*pi*2*f*t+phase)+0.1*randn(length(t),1)+2; % 5Hz, 20Hz
% fc=12.5;
% [ys]=smoothFourier20200813(y,fs,'cutoff',fc,1);
% p=0.95;
% [ys2,fc]=smoothFourier20200813(y,fs,'power',p,0);
%% Begin Code

dbstop if error

%% Input handling

if strcmp(varargin{1},'cutoff')
    fc=varargin{2};
end
if strcmp(varargin{1},'power')
    p=varargin{2};
end

mplot=varargin{3};

%%

L=length(y);

t=(0:length(y)-1)/fs;

%% Compute frequency spectrum

% The n will help increase the performance of the fft function but it is
% not totally necessary. It is also used in the ifft and ends up with
% padded values in the smoothed time series that need to be removed,
n=2^nextpow2(L);
Y=fftshift(fft(y,n));
% Removed frequency content with a power below 0.005.
Y(abs(Y)/L<0.005)=0;
% This array of frequency values matches the effects of fftshift. This
% method uses both positive and negative frequencies.
f2=fs/2*(-1:2/n:1-2/n)';

a=find(f2>=0,1);

%% Cutoff based on cummulative power

if strcmp(varargin{1},'power')
    powY=cumsum(abs(Y(a:end))/L); % find cumulative power
    powY=powY/max(powY); % normalize power
    
    ind=find(powY>=p,1);
    % This a+ind is needed because both positive and negative frequencies 
    % are used.
    fc=f2(a+ind);
    
    filtY=Y;
    % This abs is needed to get both positive and negative frequencies.
    filtY(abs(f2)>fc)=0;
    filtpowY=cumsum(abs(filtY(a:end))/L); % find cumulative power
    filtpowY=filtpowY/max(filtpowY); % normalize power
    
    invY=ifft(ifftshift(filtY),n); % find inverse fourier
    
    varargout{2}=fc;
end

if strcmp(varargin{1},'cutoff')
    powY=cumsum(abs(Y(a:end))/L); % find cumulative power
    powY=powY/max(powY); % normalize power
    
    filtY=Y;
    % This abs is needed to get both positive and negative frequencies.
    filtY(abs(f2)>=fc)=0;
    filtpowY=cumsum(abs(filtY(a:end))/L); % find cumulative power
    filtpowY=filtpowY/max(filtpowY); % normalize power
    
    invY=ifft(ifftshift(filtY),n); % find inverse fourier
end

% In the final result the extra values resulting from the n input to fft
% are removed.
y_filt=invY(1:L);
varargout{1}=y_filt;

%% Make a fancy plot

if mplot==1
    
    % Compute an equivalent low pass filter.
    [b,c]=butter(4,2*fc/fs,'low');
    ybutter=filtfilt(b,c,y);
    
    H=figure;
    set(H,'visible','on')
    
    % The strict time series
    subplot(3,2,[1,2]),plot(t,y,'b')
    hold on
    plot(t,y_filt,'r','LineWidth',2)
    plot(t,ybutter,'g','LineWidth',1)
    hold off
    axis tight
    xlabel('time (s)')
    ylabel('signal')
    title('Time Series')
    legend('Original','Fourier','Butterworth')
    
    % Plot unfiltered frequency spectrum and cummulative power
    subplot(3,2,3),plot(f2(a:end),abs(Y(a:end))/L,[fc fc],[0 max(abs(Y(a:end))/L)])
    xlabel('frequency (Hz)')
    ylabel('Power')
    title('Unfiltered Power Spectrum')
    
    subplot(3,2,4),plot(f2(a:end),powY)
    hold on
    plot([fc fc],[0 1],'r')
    hold off
    xlabel('frequency (Hz)')
    ylabel('Power')
    title('Unfiltered Cummulative Power')
    
    % Plot filtered frequency spectrum and cummulative power
    subplot(3,2,5),plot(f2(a:end),abs(filtY(a:end))/L,[fc fc],[0 max(abs(filtY(a:end))/L)])
    xlabel('frequency (Hz)')
    ylabel('Power')
    title('Filtered Power Spectrum')
    
    subplot(3,2,6),plot(f2(a:end),filtpowY)
    hold on
    plot([fc fc],[0 1],'r')
    hold off
    xlabel('frequency (Hz)')
    ylabel('Power')
    title('Filtered Cummulative Power')
    
end

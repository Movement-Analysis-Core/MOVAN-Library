function [fc]=cutoffFourier20200813(y,fs,varargin)
% [fc]=cutoffFourier20200813(y,fs)
% inputs  - y, time series
%         - fs, sampling frequency
% outputs - fc, frequency at which 90% of the power is below
% [fc]=cutoffFourier20200813(y,fs,p)
% inputs  - y, time series
%         - fs, sampling frequency
%         - p, percent power at which to select the cutoff
% outputs - fc, frequency at which 90% of the power is below
% [fc]=cutoffFourier20200813(y,fs,p,plot)
% inputs  - y, time series
%         - fs, sampling frequency
%         - p, percent power at which to select the cutoff
%         - plot, boolean indicating true or false to create a plot
% outputs - fc, frequency at which 90% of the power is below
% Remarks
% - This code computes the power spectrum density of a signal and finds the
%   frequency where x% of the power is below that frequency. It is meant to
%   be used as an exploratory script, mainly because of the consequences of
%   removing frequencies with very small power.
% - The code uses variable length inputs which it will use to determine if
%   a custom percentage is used or if the plots are saved.
% - Periodogram and a similar function/object Spectrum.periodogram do not
%   allow an inverse transform to be performed. There are also questions on
%   what type of data this is appropriate for. Using fft() directly is
%   recommended.
% - This code does remove frequencies with a power below 0.005. These very
%   small values are consequences of the numrical calculation.
% Future Work
% - Incorporating taper windows or filtering another code should be 
%   written.
% - Better comments could be written over the application of periodogram()
%   verses fft().
% Example
% fs=1000;
% f=10;
% phase=10;
% t=(0:1/fs:1)';
% y=sin(2*pi*f*t+phase)+0.5*randn(length(t),1);
% [fc]=cutoffFourier20200813(y,fs)
%
% Oct 2016 - Created by Ben Senderling
% Apr 2019 - Modified by Ben Senderling
%          - Updated comments after comparing to fft() and researching
%            documentation for periodogram() and Spectrum.periodogram().
% Aug 2020 - Modified by Ben Senderling, bmchmovan@unomaha.edu
%          - Added in the removal of frequencies with power below 0.005.
%            Modified plot option to not save to file.
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
%% Get variable inputs

if isempty(varargin)
    p=0.95;
end
if length(varargin)>=1
    if ~isnumeric(varargin{1})
        error('p must be numeric')
    elseif varargin{1}>1 || varargin{1}<=0
        error('p must be on the interval (0,1]')
    end
    p=varargin{1};
end
if length(varargin)==2
    mplot=varargin{2};
else
    mplot=0;
end

%% Set time vector

t=(0:length(y)-1)/fs;

%% Get unfiltered cutoff

[pxx,freq]=periodogram(y,[],[],fs);
pxx(pxx<0.005)=0; % low amplitude frequencies are removed
pow=cumsum(pxx);
pow=pow/max(pow);
ind=find(pow>=p,1);

fc=freq(ind);

%% Get filtered cutoff

pxx2=pxx;
pxx2(pxx<0.005)=0; % low amplitude frequencies are removed
pow2=cumsum(pxx2);
pow2=pow2/max(pow2);
ind2=find(pow2>=p,1);

fc2=freq(ind2);

%% Plot results

if mplot==1

H=figure;
set(H,'visible','on')

subplot(3,2,[1,2]),plot(t,y)
xlabel('time (s)'), ylabel('signal'), axis tight

%%

subplot(3,2,3),plot(freq,pxx,[fc fc],[0 max(pxx)],'r')
xlabel('frequency (Hz)'), ylabel('Unfiltered'), axis tight
% xlim([0 freq(ind)*1.2])

subplot(3,2,5),plot(freq,pxx2,[fc2 fc2],[0 max(pxx)],'r')
xlabel('frequency (Hz)'), ylabel('Filtered'), axis tight
% xlim([0 freq(ind2)*1.2])

%%

subplot(3,2,4),plot(freq,pow,[fc fc],[0 1],'r')
xlabel('frequency (Hz)'), ylabel('Cum Pow'), axis tight
% xlim([0 freq(ind)*1.2])

subplot(3,2,6),plot(freq,pow2,[fc2 fc2],[0 1],'r')
xlabel('frequency (Hz)'), ylabel('Cum Pow'), axis tight
% xlim([0 freq(ind2)*1.2])

end































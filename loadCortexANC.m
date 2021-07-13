function datout=loadCortexANC(file)
% [output]=loadCortexADD
% inputs:  - filename, filepath
% outputs: - output, sructure containg data and file parameters.

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
%% Begin Code

datout=struct;

fid=fopen(file,'r');

line=fgetl(fid);
line2=textscan(line,'%s','delimiter','\t');
datout.(line2{1}{1}(1:end-1))=line2{1}{2};
datout.(line2{1}{3}(1:end-2))=str2double(line2{1}{4});

line=fgetl(fid);
line2=textscan(line,'%s','delimiter','\t');
datout.(line2{1}{1}(1:end-1))=line2{1}{2};
datout.(line2{1}{3}(1:end-1))=line2{1}{4};

line=fgetl(fid);
line2=textscan(line,'%s','delimiter','\t');
datout.(line2{1}{1}(1:end-1))=line2{1}{2};
datout.(line2{1}{3}(1:end-2))=str2double(line2{1}{4});
temp=line2{1}{5}(1:end-1);
temp(9)='_';
temp(13:14)=[];
datout.(temp)=str2double(line2{1}{6});
datout.(line2{1}{7}(2:end-1))=str2double(line2{1}{8});

line=fgetl(fid);
line2=textscan(line,'%s','delimiter','\t');
datout.(line2{1}{1}(1:end-1))=str2double(line2{1}{2});
datout.(line2{1}{3}(1:end-1))=str2double(line2{1}{4});

line=fgetl(fid);
while isempty(line)
    line=fgetl(fid);
end

channels=textscan(line,'%s','delimiter','\t');

if length(channels{1})-1~=datout.Channels
    error('Total channels does not match metadata')
end

line=fgetl(fid);
sampling=textscan(line,'%s','delimiter','\t');

line=fgetl(fid);
datrange=textscan(line,'%s','delimiter','\t');

for i=2:length(channels{1})
    channels{1}{i}=regexprep(channels{1}{i},' ','');
end

for i=2:length(channels{1})
    datout.(channels{1}{i}).sampling=str2double(sampling{1}{i});
    datout.(channels{1}{i}).range=str2double(datrange{1}{i});
    datout.(channels{1}{i}).data=zeros(round(datout.Duration_Sec*datout.PreciseRate)+1,1);
end

for i=1:round(datout.Duration_Sec*datout.PreciseRate)+1
    line=fgetl(fid);
    num=textscan(line,'%d','delimiter','\t');
    for j=2:length(channels{1})
        datout.(channels{1}{j}).data(i)=num{1}(j);
    end
end

for i=2:length(channels{1})
    if ~any(~(rem(datout.(channels{1}{i}).data,1)==0))
        datout.(channels{1}{i}).data=datout.(channels{1}{i}).data*datout.(channels{1}{i}).range/2^(datout.BitDepth-1);
    end
end
        




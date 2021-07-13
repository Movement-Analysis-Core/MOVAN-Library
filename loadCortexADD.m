function [output]=loadCortexADD(file)
% [output]=loadCortexADD
% inputs:  - filename, path and file to load
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

dbstop if error

fid=fopen(file);
line=fgetl(fid);
m=0;
while ischar(line)
    line=fgetl(fid);
    m=m+1;
end
fclose(fid);

%%
fid=fopen(file);

output=struct;

line=fgetl(fid);

line=strrep(line,' ','');
channels=textscan(line,'%s','delimiter',',');
nChannels=str2double(channels{1}(end));

%%

fprintf('Line 000%%')
msg=['000%'];

for i=2:m
    line=fgetl(fid);
    line=textscan(line,'%s','delimiter',',');
    name=line{1}{2};
    name=strrep(name,' ','');
    if i~=2 && any(strcmp(line{1}{1},fieldnames(output))) && any(strcmp(name,fieldnames(output.(line{1}{1}))))
        n=size(output.(line{1}{1}).(name),1);
    else
        n=0;
    end
    output.(line{1}{1}).(name)(n+1,1:2)=[str2double(line{1}{3}(2:end-1)),str2double(line{1}{4}(2:end-1))];
    for j=5:length(line{1})
        output.(line{1}{1}).(name)(n+1,j-2)=[str2double(line{1}{j})];
    end
    
    if rem(i,100)==0
        fprintf(repmat('\b',1,length(msg)));
        msg=sprintf('%3.0i',ceil(i/m*100));
        fprintf([msg]);
    end
    
end
fprintf('\n')



























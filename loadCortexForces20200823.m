function loadCortexForces20200823

% loadCortexForces
% inputs   - user selected .forces files
% outputs  - .dat files contain COP locations for each active force plate
%          - .dat files contain Fx, Fy, Fz and Mfree for each active force 
%            plate
% Remarks
% - This code takes .forces files from Cortex and saves the COP and force
%   data into seperate .dat files. All active force plates will have there
%   data saved. Inactive force plates will have continual columns of zeros
%   and are detected in this way. Force plates that are on and recieving
%   noise will also be saved.
% Future Work
% - None
%
% Dec 2015 - Created by Ben Senderling, email: bensenderling@gmail.com
%          - Originally created for PE9420.
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
%% Begin Code

clc
clear

[FileName,PathName]=uigetfile('*.forces','Please select the forces files','MultiSelect','on');

% if ~iscell(FileName) && FileName==0
%     fprintf('no files selected, program closed\n')
%     return
% end

FileName=cellstr(FileName)';

n=length(FileName);

%%

for i=1:n
    
    fprintf('processing %i/%i: %s\n',i,n,FileName{i})
    fid=fopen([PathName FileName{i}]);
    for j=1:5
        colheaders=fgetl(fid);
    end
    colheaders=textscan(colheaders,'%s','delimiter','\t');
    
    dataheaders=cell(length(colheaders{1}),1);
    m=length(colheaders{1});
    j=1;
    k=1;
    while j<=m
        
        % Concatenate marker names with dimensions
        if ~isempty(colheaders{1}{j})
            dataheaders{k,1}=colheaders{1}{j};
            k=k+1;
            j=j+1;
        else
            j=j+1;
        end
    end
    
    dataheaders{1}='Sample';
    data=dlmread([PathName FileName{i}],'\t',5,0);
     
    %%
    
    for j=2:7:length(dataheaders)-6
        
        if isempty(find(data(:,j)))
            continue
        end
        
        For=[data(:,1) data(:,j:j+2) data(:,j+6)];
        COP=[data(:,1) data(:,j+3:j+5)];
        
        save([PathName FileName{i}(1:end-7) '_' dataheaders{j}(1) 'P' dataheaders{j}(3) '.dat'],'For','-ascii')
        save([PathName FileName{i}(1:end-7) '_COP' dataheaders{j}(3) '.dat'],'COP','-ascii')
        fprintf('data saved\n')
    end
    
    %%
    
    fclose(fid);
    
    
end






































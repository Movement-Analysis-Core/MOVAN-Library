function output=loadPedar
%% output=loadPedar
% inputs  - user selected asc or fgt files.
% outputs - Structure containing metadata and data from the selected files.
% Remarks
% - This code was only written to import data from a limited number of test
%   files. It is intended to only be used to import the data and not to
%   process it.
% 2019 Dec - Created by Ben Senderling, unobiomechanics@unomaha.edu
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
[files,pathname]=uigetfile({'*.asc';'*.fgt'},'Please select Pedar files','Multiselect','On');

if ~iscell(files)
    filename{1}=files;
end

for i=1:length(files)
    if contains(files{i},'.asc')
        
        fid=fopen([pathname,files{i}]);
        
        line=fgetl(fid);
        ind=strfind(line,'.sol');
        file=regexprep(files{i}(1:end-4),'\.','_');
        output.(file).subject=line(13:ind-1);
        ind=strfind(line,'date/time');
        y=str2double(line(ind+11:ind+12));
        m=str2double(line(ind+14:ind+15));
        d=str2double(line(ind+17:ind+18));
        h=str2double(line(ind+20:ind+21));
        m=floor(str2double(line(ind+23:ind+24))/100*60);
        output.(file).timestamp=datetime(y,m,d,h,m,0);
        
        line=fgetl(fid);
        output.(file).sensor=line(15:end);
        
        line=fgetl(fid);
        output.(file).duration=str2double(line(19:26));
        output.(file).dt=str2double(line(50:58));
        output.(file).sampfreq=str2double(line(80:84));
        
        line=fgetl(fid);
        output.(file).units=line(21:23);
        
        for j=1:3
            line=fgetl(fid);
        end
        
        headers1=textscan(line(14:end),'%s','Delimiter',',');
        line=fgetl(fid);
        headers2=textscan(line(14:end),'%s','Delimiter',',');
        for j=1:length(headers1{1})
            headers1{1}{j}=['ls',headers1{1}{j}];
        end
        for j=1:length(headers2{1})
            headers2{1}{j}=['rs',headers2{1}{j}];
        end
        headers={headers1{1}{:},headers2{1}{:}};
        
        line=fgetl(fid);
        line=fgetl(fid);
        line=fgetl(fid);
        
        fprintf('counting lines')
        fprintf(': 000000000')
        count=1;
        while ~feof(fid) % load untill end of file is detected
            line=fgetl(fid);
            count=count+1;
            if rem(count,10000)==0 % updates command window with the line count
                string=repmat('\b',1,length(num2str(count)));
                fprintf(string)
                fprintf('%i',count)
            end
        end
        frewind(fid) % rewinds line indicator to the top of the file
        for i=1:10 % runs for as many lines of headers were detected before
            line=fgetl(fid);
        end
        fprintf('\ntotal lines: %i\n',count-1)
        
        for j=1:length(headers)+1
            if j==1
                field='time';
            else
                field=headers{j-1};
            end
            output.(file).data.(field)=zeros(count-1,1);
        end
        
        for j=1:count-1
            line=fgetl(fid);
            dat=textscan(line,'%f','Delimiter',' ','MultipleDelimsAsOne',1);
            for k=1:length(dat{1})
                if k==1
                    output.(file).data.time(j)=dat{1}(k);
                else
                    output.(file).data.(headers{k-1})(j)=dat{1}(k);
                end
            end
        end
        
    elseif contains(files{i},'.fgt')
        
        fid=fopen([pathname,files{i}]);
        
        line=fgetl(fid);
        ind=strfind(line,'.sol');
        file=regexprep(files{i}(1:end-4),'\.','_');
        output.(file).subject=line(13:ind-1);
        ind=strfind(line,'date/time');
        y=str2double(line(ind+11:ind+12));
        m=str2double(line(ind+14:ind+15));
        d=str2double(line(ind+17:ind+18));
        h=str2double(line(ind+20:ind+21));
        m=floor(str2double(line(ind+23:ind+24))/100*60);
        output.(file).timestamp=datetime(y,m,d,h,m,0);
        
        line=fgetl(fid);
        output.(file).sensor=line(15:end);
        
        line=fgetl(fid);
        output.(file).forceTimeIntegral(1)=str2double(line(26:39));
        output.(file).forceTimeIntegral(2)=str2double(line(40:end));
        
        line=fgetl(fid);
        output.(file).pressureTimeIntegral(1)=str2double(line(32:44));
        output.(file).pressureTimeIntegral(2)=str2double(line(45:end));
        
        line=fgetl(fid);
        output.(file).duration=str2double(line(19:26));
        output.(file).dt=str2double(line(50:58));
        output.(file).sampfreq=str2double(line(80:84));
        
        for j=1:3
            line=fgetl(fid);
        end
        
        headers=textscan(line,'%s','Delimiter',' ','MultipleDelimsAsOne',1);
        for j=1:length(headers{1})
            ind=strfind(headers{1}{j},'[');
            headers{1}{j}(ind)='_';
            headers{1}{j}(end)='';
        end
        
        line=fgetl(fid);
        line=fgetl(fid);
        
        fprintf('counting lines')
        fprintf(': 000000000')
        count=1;
        while ~feof(fid) % load untill end of file is detected
            line=fgetl(fid);
            count=count+1;
            if rem(count,10000)==0 % updates command window with the line count
                string=repmat('\b',1,length(num2str(count)));
                fprintf(string)
                fprintf('%i',count)
            end
        end
        frewind(fid) % rewinds line indicator to the top of the file
        for i=1:9 % runs for as many lines of headers were detected before
            line=fgetl(fid);
        end
        fprintf('\ntotal lines: %i\n',count-1)
        
        for j=1:length(headers{1})
            output.(file).data.(headers{1}{j})=zeros(count-1,1);
        end
        
        for j=1:count-1
            line=fgetl(fid);
            dat=textscan(line,'%f','Delimiter',' ','MultipleDelimsAsOne',1);
            for k=1:length(dat{1})
                output.(file).data.(headers{1}{k})(j)=dat{1}(k);
            end
        end
        
    end
end
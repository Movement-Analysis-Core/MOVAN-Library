function [dataout]=loadTRC20200823(file)
% [dataout]=loadTRC20200823(file)
% inputs    - file, filepath of the trc file to be loaded
% outputs   - dataout, structure containing data from the trc file
% Remarks
% - This code loads a trc file from Vicon Nexus or Cortex, pulls the data
%   out and stores it within a structure. Data stored includes marker
%   trajectories and sampling information. The names of the structure
%   fields are pulled from the column names of the trc file.
% Future Work
% - none currently
% Dec 2015 - Created by Ben Senderling, email: bensenderling@gmail.com
%          - Created for easier input of Vicon trc files into Matlab,
%            primarily for use in the Spatiotemporal code.
% Jan 2017 - Updated by Will Denton, email: 21denton@gmail.com
%          - Added functionality for Cortex and Vicon.
% Aug 2018 - Updated by Ben Senderling, email: bensenderling@gmail.com
%          - The code will remove periods or spaces from Cortex marker
%            names.
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

fid=fopen([file]); % open file

datain=dlmread([file],'\t',5,0); % get marker trajectory data

dataout=struct; % create structure

%% Get lines containing sampling information

fgetl(fid); % first line is not needed but still needs to be loaded for sequential calling of the fgetl command

% load second line containing sampling parameter headers
line2=fgetl(fid);
line2b = textscan(line2,'%s %s %s %s %s %s %s %s','delimiter','\t');
for i=1:length(line2b)
    line2b{i}=line2b{i}(1);
end
line2b=cellfun(@cellstr,line2b);

% load third line containing sampling parameters
line3=fgetl(fid);
line3b = textscan(line3,'%f %f %f %f %s %f %f %f','delimiter','\t');
for i=1:length(line3b)
    line3b{i}=line3b{i}(1);
end

% store sampling parameters within the output structure
for j=1:length(line2b)
    dataout.(line2b{j})=line3b{j};
%     fprintf('saved %s\n',line2b{j})
end

% load fourth line containing trajectory headers
line4=fgetl(fid);
line4b = textscan(line4,'%s','delimiter','\t');
line4b=line4b{1};

%%

if length(line4b)>2 && ~isempty(strfind(line4b{3},':')) %Vicon
    dataout.(line4b{1}(1:end-1))=datain(:,1); % frame numbers
%     fprintf('saved %s\n',line4b{1}(1:end-1))
    dataout.(line4b{2})=datain(:,2); % sample times
%     fprintf('saved %s\n',line4b{2})
    count=3;
    for j=3:length(line4b)
        if ~isempty(line4b{j})
            ind=strfind(line4b{j},':')+1;
            dataout.(line4b{j}(ind:end))=datain(:,count:count+2);
            count=count+3;
            %         dataout.(line4b{j}(ind:end))=datain(:,(j-2-floor((j-2)/2))*3:(j-2-floor((j-2)/2))*3+2);
%             fprintf('saved %s\n',line4b{j}(ind:end))
        end
    end
else %Cortex
    dataout.(line4b{1}(1:end-1))=datain(:,1); % frame numbers
%     fprintf('saved %s\n',line4b{1}(1:end-1))
    dataout.(line4b{2})=datain(:,2); % sample times
%     fprintf('saved %s\n',line4b{2})
    count=3;
    for j=3:length(line4b)
        if ~isempty(line4b{j})
            temp=line4b{j};
            if ~isempty(strfind(temp,'.'))
                temp(strfind(temp,'.'))=[];
            end
            if ~isempty(strfind(temp,' '))
                temp(strfind(temp,' '))=[];
            end
            dataout.(temp)=datain(:,count:count+2);
            count=count+3;
%             fprintf('saved %s\n',temp)
        end
    end
end

fclose(fid);

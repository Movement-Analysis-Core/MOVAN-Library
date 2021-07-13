function [dataout]=loadCortexANP(file)
% [dataout]=loadCortexANP20200824(file)
% inputs    - file, filepath of the .anp file to be loaded
% outputs   - dataout, structure containing data from the anp file
% Remarks
% - This code was originally written to load EMG data from an ANP file. It 
%   has since been adapted to be more generic.
% - This code loads an ANP file from Cortex, pulls the data out and stores
%   it within a structure. Data stored includes analog information. The
%   names of the structure fields are pulled from the column names of the 
%   ANP file.
% Future Work
% - If Motion Analysis updates their ANP file format this code will likely
%   need to be changed as well.
% Dec 2015 - Created by Will Denton
% Feb 2015 - Modified by Ben Senderling
%          - The code was made more generic. The use of dlmread was changed
%            to fgetl.
% Aug 2020 - Modified by Ben Senderling, email bmchmovan@unomaha.edu
%          - Removed fprintf commands that print what line of the file the
%            code is on. Tested on 3 example files from Cortex.
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
%% Identify filename

ind=strfind(file,'\');

%% Get information from header lines

fid=fopen(file); % open file
count=1;
line=fgetl(fid);
while ~strcmp(line(1:7),'Channel') % for each line
    ind=strfind(line,':'); % look for a colon
    structfield=line(1:ind-1); % before the colon is the field name
    structfield=regexprep(structfield,' ',''); % remove spaces to make it a valid field name
    if strcmp(structfield,'BoardType') % the BoardType will be a character, the rest are numbers
        fieldval=line(ind+2:end); % after the colon is the field value
    else
        fieldval=str2num(line(ind+2:end)); % after the colon is the field value
    end
    dataout.(structfield)=fieldval; % assign the value to the field
    line=fgetl(fid);
    count=count+1;
end

%% Continue reading lines until empty line above column headers is found

while ~isempty(line)
    line=fgetl(fid);
    count=count+1;
end

%% Read column headers

line=fgetl(fid);

headers=textscan(line,'%s','delimiter','\t');
headers=headers{1};

%% Process headers

columnNames=cell(dataout.NumberofChannels,1); % preallocation
columnTypes=cell(dataout.NumberofChannels,1); % preallocation
columnNames{1}='Frame'; % since we look for ' (' below the first column will get missed.
for i=2:length(headers)
    ind=strfind(headers{i},' ('); % look for ' (' in the header
    temp=headers{i}(1:ind-1);
    columnNames{i,1}=regexprep(temp,' ',''); % remove spaces and assign
    columnTypes{i,1}=headers{i}(ind+2:end-1); %  save "Raw" "Processed" data specification
    dataout.(columnTypes{i}).(columnNames{i})=zeros(dataout.NumberofSamples,1); % preallocate
end
dataout.Raw.Frame=zeros(dataout.NumberofSamples,1); % preallocate frames
dataout.Processed.Frame=zeros(dataout.NumberofSamples,1); % preallocate frames

%% Read data

for i=1:dataout.NumberofSamples
    line=fgetl(fid);
    line=regexprep(line,'<no_value>','0'); % all "<no_value>" entries are replaced with 0s
    line=textscan(line,'%f','delimiter','\t');
    line=line{1};
    dataout.Raw.Frame(i)=line(1); % assign frame number
    dataout.Processed.Frame(i)=line(1); % assign frame number
    for j=2:length(line)
        dataout.(columnTypes{j}).(columnNames{j})(i)=line(j); % assign each number in the line to the respective field
    end
end

fclose(fid);







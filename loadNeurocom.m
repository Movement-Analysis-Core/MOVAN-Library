function [output] = loadNeurocom20170906(filename)
% [dataout] = loadNeurocom20170906
% inputs:  - filename, the path and file to load.
% outputs: - output, sructure containg data and file parameters.
% Remarks
% - This function will load data from a text or Excel file from a Neurocom.
% - The data is dynamically identified and should work for a variety of
%   files.
% - This code was written to be compatible with Mac and Windows operating
%   systems.
% Future Work
% - Neurocoms seem to have different file formats. This code should
%   continually updated to accomadate all those formats.
% Prior 2015 - Created by Troy Rand
% Apr 2015 - Commented by Ben Senderling, email bensenderling@gmail.com
% May 2017 - Modified by  Ben Senderling, email bensenderling@gmail.com
%          - Renamed from NeuroCOPLoad to LoadNeurocom to be consistent
%            with the Load... naming format.
%          - Converted output to a structure.
%          - Added in loading for Excel files from a Neurocom
% Aug 2017 - Reworked by Will Denton, 21denton@gmail.com
%          - Modified to pull out the trial information from the file in
%            addition to the data from text files.
%          - This file was renamed LoadNeurocomV1.m
% Sep 2017 - Modified by Ben Senderling, email bensenderling@gmail.com
%          - Added a section to do the same with Excel files as in the Aug
%            2017 revision.
% Jul 2020 - Modified by Cory Frederick, email cmfrederick@unomaha.edu
%          - Changed function to include timestamp for last update.
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
dbstop if error;

if ~isempty(strfind(filename,'.txt')) % checks if the file is a txt file
    
    %%
    
    fid = fopen(filename);
    txt = strsplit(fgetl(fid),' ');
    while 1
        try
            temp = fgetl(fid);
            if ~iscell(temp) && ~ischar(temp) && temp == -1
                break;
            else
                if contains(temp,'DP')
                    [r,~] = size(txt); r = r+1;
                end
                try
                    txt = [txt; strsplit(temp,' ')];
                catch
                    try
                        temp = strsplit(temp,' ');
                        [R,~] = size(txt);
                        for i = 1:length(temp)
                            txt{R,i} = temp{i};
                        end
                    end
                end
            end
        end
    end
    [~,c] = size(txt);
    for i = 1:r-2
        try
            field = txt{i,1};
            for exclude = ['(',')']
                field(strfind(txt{i,1},exclude)) = '_';
            end
            field(strfind(txt{i,1},':')) = '';
            output(:,1).(field) = txt{i,2};
        end
    end
    for i = 2:c
        txt{r,i}(strfind(txt{r,i},'(')) = '_';
        txt{r,i}(strfind(txt{r,i},')')) = '';
        temp = strsplit(txt{r,i},'.');
        output(:,1).(temp{1}).(temp{2}) = table2array(cell2table(cellfun(@str2num,{txt{r+1:end,i}},'un',0).'));
    end
    
elseif ~isempty(strfind(filename,'.xls')) % checks if the file is an Excel file
    
    %%
    
    [~,~,raw]=xlsread(filename);
    
    [~,n]=size(raw);
    
    i=1;
    while 1
        field=raw{i};
        if ~isempty(strfind(field,'DP'))
            break
        end
        if isnan(field)
            i=i+1;
            continue
        end
        for exclude = ['(',')']
            field(strfind(field,exclude)) = '_';
        end
        field(strfind(field,':')) = '';
        txt=raw(i,2:end);
        for j=length(txt):-1:1
            if isnan(txt{j})
                txt(j)=[];
            end
        end
        if length(txt)<=1
            output(:,1).(field)=raw{i,2};
        else
            temp=txt{1};
            for j=2:length(txt)
                temp=[temp ',' txt{j}];
            end
            output(:,1).(field)=temp;
        end
        i=i+1;
    end
    
    for j=2:n
        if ~contains(raw{i,j},'.')
            output.FP.(raw{i,j})=cell2mat(raw(i+1:end,j));
        else
            temp = strsplit(raw{i,j},'.');
            output.(temp{1}).(temp{2})=cell2mat(raw(i+1:end,j));
        end
    end
        
end

end

function [dataout]=loadv3d20200825(file)
% [dataout]=loadv3d20200825(file)
% inputs  - file, file path and name of a V3D text file
% outputs - dataout, structure containing file from V3D text file
%
% Remarks
% - This function takes a text file from V3D and creates a structure. The
%   headers (data source, types, folders, components, signal names) are
%   used to name the fields in the structure. The frames are not imported.
% - If more than one subject's data is contained in the text file the data
%   for each subject will be stored within that subject's field.
% - This code is written to work with V3D files that have NaN exported for
%   frames with no data.
% Future Work
% - None.
%
% Oct 2016 - Created by Ben Senderling, bensenderling@gmail.com
% Jul 2017 - Modified by Ben Senderling, email bensenderling@gmail.com
%          - A bug was found where columns with the same names but
%            different data would be overwritten. The code now checks for
%            similar files names used previously and adds a number to the
%            filename to prevent overwrites.
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

fid = fopen(file); % opens file

% get first five header lines
data{1,:}=fgetl(fid);
data{2,:}=fgetl(fid);
data{3,:}=fgetl(fid);
data{4,:}=fgetl(fid);
data{5,:}=fgetl(fid);

fclose(fid); % close file

%% Parse headers

% Read in lines as delimeted text
sources=textscan(data{1,:},'%s','delimiter','\t');
measure=textscan(data{2,:},'%s','delimiter','\t');
type=textscan(data{3,:},'%s','delimiter','\t');
folder=textscan(data{4,:},'%s','delimiter','\t');
dimension=textscan(data{5,:},'%s','delimiter','\t');

% adjust matrixes to be more accessable
sources=sources{1};
sources(1)=[];
measure=measure{1};
measure(1)=[];
type=type{1};
type(1)=[];
folder=folder{1};
folder(1)=[];
dimension=dimension{1};
dimension(1)=[];

clear data;

% this if statement has not been tested
if ~isempty(strfind(sources{1},'\')) %checks if long file names are used on the headers
    for i=1:length(sources)
        ind=strfind(sources{1},'\');
        sources{i}=sources{i}(ind(end)+1:end); % trims headers
    end
end

%% Inport numeric data

data=dlmread(file,'\t',5,0);

%% Assign data to fields

nlast=inf;
lasttype='boom';
fields=cell(length(sources),1);
for j=1:length(sources)
    
    temp=data(:,j+1);
    
    ind=find(~isnan(temp),1,'last');
    
    if isempty(ind)
        continue
    end
    
    temp(ind+1:end)=[];
    
    if ismember(type(j),{'LINK_MODEL_BASED' 'FORCE' 'COFP'})
        if abs(length(temp)-nlast)<10 && strcmp(lasttype,type(j))
            temp=data(1:nlast,j+1);
        end
        nlast=length(temp);
        lasttype=type{j};
    end
    
    fieldname=[sources{j}(1:end-4) '_' type{j} '_' measure{j} '_' dimension{j}];
    sources=strrep(sources,' ','_');
    type=strrep(type,' ','_');
    measure=strrep(measure,' ','_');
    dimension=strrep(dimension,' ','_');
    num=sum(strcmp(fieldname,fields))+1;
    
%     if strcmp(
    dataout.(sources{j}(1:end-4)).(type{j}).(folder{j}).(measure{j}).(dimension{j})(num,1)={temp};
    
    fields{j}=fieldname;
    
end

end

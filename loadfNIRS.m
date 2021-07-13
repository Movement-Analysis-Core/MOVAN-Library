function [channelData, marks, timeStamp]  = loadfNIRS(fileName)
% loads Hb data from specified file (Hitachi ETS-4000 format)
%
%   Format of input file:
%       Index -> fNIRSdata{1,1}
%       Channels 1:24 -> fNIRSdata{1,2:25}
%       Mark -> fNIRSdata{1,26}
%       Timestamp -> fNIRSdata{1,27}
%       Body movement -> fNIRSdata{1,28}
%       Removal mark -> fNIRSdata{1,29}
%       Prescan -> fNIRSdata{1,30}
%
%   Format of output:
%       Channels 1:24 -> channelData(:,1:24)
%       Mark -> marks(:)
%       Timestamp -> timeStamp(:)
%
%   marks and timeStamp output vectors are optional
%
%   add additional output vectors as required

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

% open file
fprintf('READING: %s ... ', fileName)
fileID = fopen(fileName);

% skip headers (TODO: check if headers exist first) and read formatted data
formatSpec = '%d %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f %s %s %u8 %u8 %u8';
fNIRSdata = textscan(fileID, formatSpec,'headerlines', 41,'delimiter', ',');

% close file
fclose(fileID);
fprintf('COMPLETE\n\n')

% extract channel data
dataLength = length(fNIRSdata{1,1});
channelData = zeros(dataLength,24);
for j = 1:24
    channelData(:,j) = fNIRSdata{1,j + 1}(:,1);
end

% extract time vector
timeStamp = fNIRSdata{1,27}(:,1);

% extract marks vector
marks = fNIRSdata{1,26}(:,1);
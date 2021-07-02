function [channelData, marks, timeStamp]  = loadfNIRS20200824(fileName)
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
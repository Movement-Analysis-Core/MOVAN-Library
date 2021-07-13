function data=loadCosmed(fileName)
% [data]=loadCosmed
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
%% Import data

[dat,text,~] = xlsread(fileName); % might have to be replaced by csv read

%% Pull out data.

data.sub.lastName=text{2,2};
data.sub.firstName=text{3,2};
data.sub.gender=text{4,2};
data.sub.age=dat(5,1);
data.sub.height=dat(6,1);
data.sub.mass=dat(7,1);
data.sub.dob=text{8,2};
data.sub.file=fileName;

data.test.date=text{1,5};
data.test.time=text{2,5};
data.test.numSteps=dat(3,4);
data.test.duration=dat(4,4)*24*60*60;
data.test.bsa=dat(5,4);
data.test.bmi=dat(6,4);
data.test.hrMax=dat(7,4);

data.atmosphere.baroPressure=dat(1,7);
data.atmosphere.ambTemp=dat(2,7);
data.atmosphere.ambRelHumidity=dat(3,7);
data.atmosphere.flowmeterTemp=dat(4,7);
data.atmosphere.flowmeterRelHumidity=dat(5,7);
data.atmosphere.stpd=dat(6,7);
data.atmosphere.btpsIns=dat(7,7);
data.atmosphere.btpsExp=dat(8,7);
data.atmosphere.user1=dat(9,7);
data.atmosphere.user2=dat(10,7);
data.atmosphere.user3=dat(11,7);

for i=10:80
    str=text{1,i};
    str=replace(str,'.','');
    str=replace(str,' ','');
    str=replace(str,'/','_');
    str=replace(str,'%','Per');
    if strcmp(str,'Marker')
        data.data.(str).x=~cellfun(@isempty,text(4:end,i));
        data.data.(str).u=text{2,i};
    else
        data.data.(str).x=dat(4:end,i-1);
        data.data.(str).u=text{2,i};
    end
    if strcmp(str,'t')
        data.data.(str).x=data.data.(str).x*24*60*60;
    end
end



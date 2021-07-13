function data=loadCosmed20210224(fileName)

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



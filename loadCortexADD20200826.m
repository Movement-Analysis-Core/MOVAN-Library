function [output]=loadCortexADD20200826(file)
%%

dbstop if error

fid=fopen(file);
line=fgetl(fid);
m=0;
while ischar(line)
    line=fgetl(fid);
    m=m+1;
end
fclose(fid);

%%
fid=fopen(file);

output=struct;

line=fgetl(fid);

line=strrep(line,' ','');
channels=textscan(line,'%s','delimiter',',');
nChannels=str2double(channels{1}(end));

%%

fprintf('Line 000%%')
msg=['000%'];

for i=2:m
    line=fgetl(fid);
    line=textscan(line,'%s','delimiter',',');
    name=line{1}{2};
    name=strrep(name,' ','');
    if i~=2 && any(strcmp(line{1}{1},fieldnames(output))) && any(strcmp(name,fieldnames(output.(line{1}{1}))))
        n=size(output.(line{1}{1}).(name),1);
    else
        n=0;
    end
    output.(line{1}{1}).(name)(n+1,1:2)=[str2double(line{1}{3}(2:end-1)),str2double(line{1}{4}(2:end-1))];
    for j=5:length(line{1})
        output.(line{1}{1}).(name)(n+1,j-2)=[str2double(line{1}{j})];
    end
    
    if rem(i,100)==0
        fprintf(repmat('\b',1,length(msg)));
        msg=sprintf('%3.0i',ceil(i/m*100));
        fprintf([msg]);
    end
    
end
fprintf('\n')



























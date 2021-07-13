function dataout=loadDFlow20200806(path)

data=csvread(path,1,0);

fid = fopen(path);
line=fgetl(fid);
fclose(fid);

headers=textscan(line,'%s','delimiter',','); % path in trc file

for j=1:length(headers{1})
    dataout.(headers{1}{j})=data(:,j);
end

end

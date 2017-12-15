cd ~/Desktop/faces
fprintf('converting faces rings \n');
fn=dir('faces01_rings_*');
for i=1:length(fn)
    fprintf([num2str(i) ' ']);
    tmp_img=importdata(fn(i).name);
    for j=1:length(tmp_img)
        ret_vid(i).img{j} = tmp_img(j).cdata;
        ret_vid(i).fps=30;
    end
end
fprintf ('\nsaving mat file\n\n')
save('faces01_rings_.mat','ret_vid');

clear ret_vid

fprintf('converting faces wedge \n');
fn=dir('faces01_wedge_*');
for i=1:length(fn)
    fprintf([num2str(i) ' ']);
    tmp_img=importdata(fn(i).name);
    for j=1:length(tmp_img)
        ret_vid(i).img{j} = tmp_img(j).cdata;
        ret_vid(i).fps=30;
    end
end
fprintf ('\nsaving mat file\n\n')
save('faces01_wedge.mat','ret_vid');

clear ret_vid

cd ~/Desktop/walkers
fprintf('converting walkers rings \n');
fn=dir('walker01_rings_*');
for i=1:length(fn)
    fprintf([num2str(i) ' ']);
    tmp_img=importdata(fn(i).name);
    for j=1:length(tmp_img)
        ret_vid(i).img{j} = tmp_img(j).cdata;
        ret_vid(i).fps=30;
    end
end
fprintf ('\nsaving mat file\n\n')
save('walker01_rings.mat','ret_vid');

clear ret_vid

fprintf('converting walkers wedge \n');
fn=dir('walker01_wedge_*');
for i=1:length(fn)
    fprintf([num2str(i) ' ']);
    tmp_img=importdata(fn(i).name);
    for j=1:length(tmp_img)
        ret_vid(i).img{j} = tmp_img(j).cdata;
        ret_vid(i).fps=30;
    end
end
fprintf ('\nsaving mat file\n\n')
save('walker01_wedge.mat','ret_vid');

cd ~/Desktop
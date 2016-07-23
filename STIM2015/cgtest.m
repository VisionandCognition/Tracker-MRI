%open cogent
cgopen(3,0,0,0)

%%
%test flipping wait for vertical refresh
T = zeros(100,1);
for i = 1: 100
    T(i) = cgflip('V');
end

figure
hist(diff(T))

%%
%same or different???
for i = 1: 100
    T(i) = cgflip();
end

figure
hist(diff(T))


%%
gpd = cggetdata('GPD');

%%
cgshut
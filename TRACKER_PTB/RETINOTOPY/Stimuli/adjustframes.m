<<<<<<< Updated upstream
for rv=1:length(ret_vid)
    for i=1:length(ret_vid(rv).img)
            for rgb=1:3
                temp_img=ret_vid(rv).img{i}(:,:,rgb);
                temp_img(temp_img==87)=88;
                ret_vid(rv).img{i}(:,:,rgb)=temp_img;
            end
    end
=======
for rv=1:length(ret_vid)
    for i=1:length(ret_vid(rv).img)
            for rgb=1:3
                temp_img=ret_vid(rv).img{i}(:,:,rgb);
                temp_img(temp_img==87)=88;
                ret_vid(rv).img{i}(:,:,rgb)=temp_img;
            end
    end
>>>>>>> Stashed changes
end
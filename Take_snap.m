function [img] = Take_snap()
%takes a picture using my phone
url='http://192.168.43.1:8080/shot.jpg';%your own ip address of the server of ip webcam should be used.
ss=imread(url);
img=image(ss);
set(img,'CData',ss);
end


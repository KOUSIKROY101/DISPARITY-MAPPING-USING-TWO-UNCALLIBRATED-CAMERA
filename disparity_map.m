
img1=snapshot(cam);
img2=Take_snap();
figure();
imshowpair(img1,img2,'montage');
imgl=rgb2gray(img1);
imgr=rgb2gray(img2);
figure();
imshowpair(imgl,imgr,'ColorChannels','red-cyan');
title('Composite Image (Red - Left Image, Cyan - Right Image)');

blobs1 = detectSURFFeatures(imgl, 'MetricThreshold', 200);
blobs2 = detectSURFFeatures(imgr, 'MetricThreshold', 200);

figure;
imshow(imgl);
hold on;
plot(selectStrongest(blobs1, 30));
title('Thirty strongest SURF features in imgl');

figure();
imshow(imgr);
hold on;
plot(selectStrongest(blobs2, 30));
title('Thirty strongest SURF features in I2');


[features1, validBlobs1] = extractFeatures(imgl, blobs1);
[features2, validBlobs2] = extractFeatures(imgr, blobs2);

indexPairs = matchFeatures(features1, features2, 'Metric', 'SAD', ...
  'MatchThreshold', 20);

matchedPoints1 = validBlobs1(indexPairs(:,1),:);
matchedPoints2 = validBlobs2(indexPairs(:,2),:);


figure;
showMatchedFeatures(imgl, imgr, matchedPoints1, matchedPoints2);
legend('Putatively matched points in imgl', 'Putatively matched points in imgr');


[fMatrix, epipolarInliers, status] = estimateFundamentalMatrix(...
  matchedPoints1, matchedPoints2, 'Method', 'Norm8Point', ...
  'NumTrials', 10000, 'DistanceThreshold', 0.1, 'Confidence', 99.99);

if status ~= 0 || isEpipoleInImage(fMatrix, size(imgl)) ...
  || isEpipoleInImage(fMatrix', size(imgr))
  error(['Either not enough matching points were found or '...
      'the epipoles are inside the images. You may need to '...
        'inspect and improve the quality of detected features ',...
        'and/or improve the quality of your images.']);
end

inlierPoints1 = matchedPoints1(epipolarInliers, :);
inlierPoints2 = matchedPoints2(epipolarInliers, :);

figure;
showMatchedFeatures(imgl, imgr, inlierPoints1, inlierPoints2);
legend('Inlier points in imgl', 'Inlier points in imgr');



[t1, t2] = estimateUncalibratedRectification(fMatrix, ...
  inlierPoints1.Location, inlierPoints2.Location, size(imgr));
tform1 = projective2d(t1);
tform2 = projective2d(t2);

imglRect = imwarp(imgl, tform1, 'OutputView', imref2d(size(imgl)));
imgrRect = imwarp(imgr, tform2, 'OutputView', imref2d(size(imgr)));

% transform the points to visualize them together with the rectified images
pts1Rect = transformPointsForward(tform1, inlierPoints1.Location);
pts2Rect = transformPointsForward(tform2, inlierPoints2.Location);

figure;
showMatchedFeatures(imglRect, imgrRect, pts1Rect, pts2Rect);
legend('Inlier points in rectified imgl', 'Inlier points in rectified imgr');


Irectified = cvexTransformImagePair(imgl, tform1, imgr, tform2);
figure;
imshow(Irectified);
title('Rectified Stereo Images (Red - Left Image, Cyan - Right Image)');



figure();
imshow(stereoAnaglyph(imglRect,imgrRect));
title('Red-cyan composite view of the stereo images');
disparityrange=[-6,+10];
disparitymap=disparity(imglRect,imgrRect,'BlockSize',...
    35,'DisparityRange',disparityrange);

imshow(disparitymap,disparityrange);

title('DISPARITY MAP');
colormap(gca,jet);
colorbar;
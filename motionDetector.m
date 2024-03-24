% Specify the video file to process
videoFile = 'motion.mp4';
% Create a VideoReader object to read the video
videoReader = VideoReader(videoFile);
% Parameters for the audio alert
fs = 44100;
t = 0:1/fs:1;
alertSound = sin(2*pi*1000*t); % Generate an audio alert as a sinusoidal wave
% Read the first frame and convert it to grayscale
prevFrame = rgb2gray(readFrame(videoReader));
% Create figures to display the original and edited videos
figure('Name', 'Original Video');
originalAxes = gca;
title('Original Video');
axis off;
originalFigHandle = gcf; % Create a figure for the original video
figure('Name', 'Edited Video with Motion Detection');
editedAxes = gca;
title('Edited Video with Motion Detection');
axis off;
editedFigHandle = gcf; % Create a figure for the edited video with motion detection
% Variable to track motion detection (False by default)
motionDetected = false;
% Parameters for capturing images and calculating speed and direction
captureInterval = 10;
captureTimer = tic; % Initialize a timer for capturing images at regular intervals
% Previous centroid for calculating speed and direction
prevCentroid = [];
% Processing each frame of the video
while hasFrame(videoReader)
   % Read the current frame and convert it to grayscale
   currentFrame = rgb2gray(readFrame(videoReader));
   % Calculate the absolute difference between consecutive frames
   diffFrame = imabsdiff(currentFrame, prevFrame);
   % Apply a threshold to the difference image to create a binary mask
   threshold = 30;
   binaryDiff = diffFrame > threshold;
   % Perform morphological operations to clean the binary mask
   se = strel('disk', 5);
   binaryDiff = imopen(binaryDiff, se);
   % Label connected components (objects) in the binary mask
   labeledMask = bwlabel(binaryDiff);
  
   % Check if there is any motion
   if any(labeledMask(:))
       % Display a message when motion is detected
       disp('Motion detected!');   
       % Play the audio alert continuously if motion is detected
       if ~motionDetected
           sound(alertSound, fs);
           motionDetected = true;
       end
      
       % Check if it's time to capture an image
       if toc(captureTimer) >= captureInterval
           % Capture an image from the original video
           captureImage = currentFrame;
          
           % Display the captured image in a new figure
           figure('Name', 'Captured Image');
           imshow(captureImage);
           title('Captured Image');
          
           % Reset the capture timer
           captureTimer = tic;
       end
   else
       % Stop the audio alert if there is no motion
       if motionDetected
           soundsc(zeros(size(alertSound)), fs);
           motionDetected = false;
       end
   end
  
   % Calculate and display the speed and direction of motion
   stats = regionprops(labeledMask, 'Centroid', 'Area');
  
   if ~isempty(stats)
       % Find the region with the largest area
       [~, index] = max([stats.Area]);
       centroid = stats(index).Centroid;
      
       % Calculate speed and direction if there is a previous centroid
       if ~isempty(prevCentroid)
           speed = norm(centroid - prevCentroid) / (1/fs);
           direction = atan2d(centroid(2) - prevCentroid(2), centroid(1) - prevCentroid(1));
           disp(['Speed: ', num2str(speed), ' pixels/second | Direction: ', num2str(direction), ' degrees']);
       end
      
       % Update the previous centroid
       prevCentroid = centroid;
   end
  
   % Update the original frame in the original video figure
   figure(originalFigHandle);
   imshow(currentFrame);
   drawnow; % Force MATLAB to display the image immediately
  
   % Update the edited frame in the edited video figure
   figure(editedFigHandle);
   imshow(label2rgb(labeledMask, 'jet', 'k', 'shuffle'));
   drawnow; % Force MATLAB to display the image immediately
  
   % Update the previous frame
   prevFrame = currentFrame;
end
% Release resources
release(videoReader);

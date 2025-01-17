if ~exist('result', 'dir'), mkdir('result'); end
if ~exist('tmp', 'dir'), mkdir('tmp'); end

nTrain = 110756; %need to replace nTrain with number of train samples
trainData = ones(48, 48, 3, nTrain);
trainLabels = ones(1, nTrain);

files = dir('data');
directoryNames = {files([files.isdir]).name};
directoryNames = directoryNames(~ismember(directoryNames,{'.','..'}));
currentIdx = 1;
for i = 1:length(directoryNames)
        files = dir(strcat('data/', directoryNames{i}, '/*.jpg'));
        for j = 1:length(files)
            im = imread(char(fullfile('data', directoryNames(i), files(j).name)));
            im_ = imresize(im, [48, 48]);
            %imshow(im_);
            trainData(:,:,:,currentIdx) = im_;
            trainLabels(:, currentIdx) = i;
            currentIdx = currentIdx + 1;
            
        end
end

save(fullfile('tmp', 'train.mat'), 'trainData', 'trainLabels');

normalizedTrainData = int8(normalize(double(trainData)));
save(fullfile('tmp', 'normalizedTrain.mat'), 'normalizedTrainData', 'trainLabels');

%normalizedStandardizedTrainData = standardize(normalizedTrainData);
%save(fullfile('result', 'normalizedStandardizedTrainData.mat'), ...
%    'normalizedStandardizedTrainData', 'trainLabels');

clear trainData;

initW = 1e-2;
initB = 1e-1;

addpath(genpath(fullfile('toolbox', 'matconvnet-1.0-beta16')));
addpath(genpath(fullfile('toolbox', 'cnn')));

run neuralNetworkSmall.m;

%opts need to be changed
opts.continue = true;
opts.gpus = [];
opts.expDir = fullfile('tmp', 'trained_facial_identification_nn');
if exist(opts.expDir, 'dir') ~= 7, mkdir(opts.expDir); end

opts.learningRate = 1e-2;
opts.batchSize = 500;
opts.numEpochs = 30;

%[selected, ignored] = crossvalind('HoldOut', nTrain, 0.3);
%normalizedTrainData(:, :, :, ignored) = [];
%trainLabels(ignored) = [];
[trainIdx, valIdx] = crossvalind('HoldOut', nTrain, 0.15);
trained_facial_identification_nn = cnnTrain(normalizedTrainData(:,:,:,trainIdx),...
    trainLabels(:, trainIdx), ...
    normalizedTrainData(:,:,:, valIdx), trainLabels(:, valIdx),...
    face_identification_nn, opts) ;
copyfile(fullfile(opts.expDir, 'net-train.pdf'), ...
    fullfile('result', 'trained_facial_identification_nn.pdf'));

save(fullfile('result', 'trained_facial_identification_nn.mat'),...
    'trained_facial_identification_nn');

%-------------------------------------------------------------------

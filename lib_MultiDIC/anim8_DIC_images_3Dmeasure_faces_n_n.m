function [] = anim8_DIC_images_3Dmeasure_faces_n_n(ImSet,DIC2DpairResults,DIC3DpairResults,faceMeasureString,varargin)
%% function for plotting 2D-DIC results imported from Ncorr in step 2
% called inside plotNcorrPairResults
% plotting the images chosen for stereo DIC (2 views) with the
% correlated points results plotted on top, colored as their correlation
% coefficient.
% on the left side the images from the reference camera (reference image and current images), and on the right side the
% images from the deformed camera
% requirements: GIBBON toolbox
%
% calling options:
% [] = anim8_DIC_images_3Dmeasure_points_n_n(IMset,DIC2DpairResults,DIC3DpairResults,pointMeasureStr);
% [] = anim8_DIC_images_3Dmeasure_points_n_n(IMset,DIC2DpairResults,DIC3DpairResults,pointMeasureStr,optStruct);
%
% INPUT:
% * IMset - a 2nX1 cell array containing 2n grayscale images. The first n
% images are from camera A (the "reference" camera), and the last n images
% are from camera B (the "deformed" camera). The first image in the set is
% considered as the reference image, on which the reference grid of points
% is defined, and all the correlated points and consequent displacements
% and strains, are relative to this image.
% * DIC_2Dpair_results - containig the correlated points, correlation
% coefficients, faces..
% * optional: CorCoeffCutOff - - maximal correlation coefficient to plot
% points
% * optional: CorCoeffDispMax - maximal correlation coefficient in colorbar

%%
Points=DIC2DpairResults.Points;
nCamRef=DIC2DpairResults.nCamRef;
nCamDef=DIC2DpairResults.nCamDef;
nImages=DIC2DpairResults.nImages;
F=DIC2DpairResults.Faces;
FaceCorr=DIC3DpairResults.FaceCorrComb;

switch nargin
    case 4 % in case no results were entered
        optStruct=struct;
    case 5
        optStruct=varargin{1};
    otherwise
        error('wrong number of input arguments');
end

%% cut out point with large correlation coefficient
if ~isfield(optStruct,'CorCoeffCutOff')
    CorCoeffCutOff=max(cell2mat(FaceCorr));
else
    CorCoeffCutOff=optStruct.CorCoeffCutOff;
end

for ii=1:nImages
    FaceCorr{ii}(FaceCorr{ii}>CorCoeffCutOff)=NaN;
end

%%
switch faceMeasureString
    case {'J','Lamda1','Lamda2'}
        FC=DIC3DpairResults.Deform.(faceMeasureString);
        cMap=coldwarm;
        if ~isfield(optStruct,'FClimits')
            FCmax=0;
            for ii=1:nImages
                FCmax=max([max(abs(FC{ii}(~isnan(FaceCorr{ii}))-1)) FCmax]);
            end
            FClimits=[1-FCmax 1+FCmax];
        else
            FClimits=optStruct.FClimits;
        end
    case {'Emgn','emgn'}
        FC=DIC3DpairResults.Deform.(faceMeasureString);
        cMap='parula';
        if ~isfield(optStruct,'FClimits')
            FCmax=0;
            for ii=1:nImages
                FCmax=max([max(FC{ii}(~isnan(FaceCorr{ii}))) FCmax]);
            end
            FClimits=[0 FCmax];
        else
            FClimits=optStruct.FClimits;
        end
    case {'Epc1','Epc2','epc1','epc2'}
        FC=DIC3DpairResults.Deform.(faceMeasureString);
        cMap=coldwarm;
        if ~isfield(optStruct,'FClimits')
            FCmax=0;
            for ii=1:nImages
                FCmax=max([max(abs(FC{ii}(~isnan(FaceCorr{ii})))) FCmax]);
            end
            FClimits=[-FCmax FCmax];
        else
            FClimits=optStruct.FClimits;
        end
    otherwise
        error('unexpected face measure string. plots not created');      
end

for ii=1:nImages
    FC{ii}(isnan(FaceCorr{ii}))=NaN;
end
%%
hf=cFigure;
hf.Units='normalized'; hf.OuterPosition=[.05 .05 .9 .9]; hf.Units='pixels';

% Ref
ii=1;
subplot(1,2,1)
hp1=imagesc(repmat(ImSet{ii},1,1,3)); hold on;
hp2=gpatch(F,Points{1},FC{ii},'none',0.5);
pbaspect([size(ImSet{ii},2) size(ImSet{ii},1) 1])
hs1=title(['Ref (Cam ' num2str(nCamRef) ' frame ' num2str(1) ')']);
colormap(cMap);
hc1=colorbar;
caxis(FClimits)
title(hc1, faceMeasureString);
hc1.FontSize=16;
axis off

% Cur
ii=nImages+1;
subplot(1,2,2)
hp3=imagesc(repmat(ImSet{ii},1,1,3)); hold on
hp4=gpatch(F,Points{1},FC{ii-nImages},'none',0.5);
pbaspect([size(ImSet{ii},2) size(ImSet{ii},1) 1])
hs2=title(['Cur ' num2str(ii) ' (Cam ' num2str(nCamDef) ' frame ' num2str(1) ')']);
colormap(cMap);
hc2=colorbar;
caxis(FClimits);
title(hc2, faceMeasureString);
hc2.FontSize=16;
axis off

drawnow

%Create the time vector
animStruct.Time=linspace(0,1,nImages);

for ii=1:nImages
    Pnow1=Points{ii};
    Pnow2=Points{ii+nImages};
    
    cNow1=FC{ii};
    cNow2=FC{ii};
    
    TitleNow1=['Cur ' num2str(ii) ' (Cam ' num2str(nCamRef) ' frame ' num2str(ii) ')'];
    TitleNow2=['Cur ' num2str(ii) ' (Cam ' num2str(nCamDef) ' frame ' num2str(ii) ')'];
    
    %Set entries in animation structure
    animStruct.Handles{ii}=[hp1,hp3,hp2,hp2,hp4,hp4,hs1,hs2]; %Handles of objects to animate
    animStruct.Props{ii}={'CData','CData','Vertices','CData','Vertices','CData','String','String'}; %Properties of objects to animate
    animStruct.Set{ii}={repmat(ImSet{ii},1,1,3),repmat(ImSet{ii+nImages},1,1,3),Pnow1,cNow1,Pnow2,cNow2,TitleNow1,TitleNow2}; %Property values for to set in order to animate
    
end

anim8(hf,animStruct);

end

%% 
% MultiDIC: a MATLAB Toolbox for Multi-View 3D Digital Image Correlation
% 
% License: <https://github.com/MultiDIC/MultiDIC/blob/master/LICENSE.txt>
% 
% Copyright (C) 2018  Dana Solav
% 
% If you use the toolbox/function for your research, please cite our paper:
% <https://engrxiv.org/fv47e>
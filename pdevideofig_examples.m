clear all
close all
clc

%% Obtain the solution for the wave equation (inspired by Matlab's pdedemo6.m)

c = 1; a = 0; f = 0; m = 1;

numberOfPDE = 1;
model = createpde(numberOfPDE);
geometryFromEdges(model,@squareg);
specifyCoefficients(model,'m',m,'d',0,'c',c,'a',a,'f',f);
applyBoundaryCondition(model,'dirichlet','Edge',[2,4],'u',0);
applyBoundaryCondition(model,'neumann','Edge',([1 3]),'g',0);

generateMesh(model);
u0 = @(location) atan(cos(pi/2*location.x));
ut0 = @(location) 3*sin(pi*location.x).*exp(sin(pi/2*location.y));
setInitialConditions(model,u0,ut0);

n = 11;
tlist = linspace(0,1,n);
result = solvepde(model,tlist);
u = result.NodalSolution;


%% Default 
fig = pdevideofig(model, u, tlist) ;

%% Pass additional function that enhances post-processing capabilities
fig = pdevideofig(model, u, tlist, @additionalPostProcessing) ;


%% Pass additional function that enhances post-processing capabilities
addPostProcessingDummyFun = @(varargin) disp('') ;
fig = pdevideofig(model, u, tlist, addPostProcessingDummyFun, 2, 11 ) ;

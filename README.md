This code implements the single-image illumination estimation technique
introduced in 

J.-F. Lalonde, A. A. Efros, and S. G. Narasimhan, "Estimating the Natural 
Illumination Conditions from a Single Outdoor Image," International 
Journal of Computer Vision, vol. 98, no. 2, pp. 123--145, Jun. 2012.


*** THIS IS NOT YET FULLY-FUNCTIONAL! USE AT YOUR OWN RISK! ***


See function demoEstimateIllumination.m


Requirements
============

* MATLAB's optimization toolbox

* My [utils package](http://www.github.com/jflalonde/utils), available on github;
* My [skyModel](http://www.github.com/jflalonde/skyModel) package, available on github;
* My [shadowDetection](http://www.github.com/jflalonde/shadowDetection) package, available on github;

* [LibSVM](http://www.csie.ntu.edu.tw/~cjlin/libsvm), included in `3rd_party/libsvm-mat-3.0-1`;
* [Felzenszwalb et al. object detector](http://www.cs.uchicago.edu/~pff/latent) [1], included in `3rd_party/voc-release3.1`;
* [Piotr Dollar's image processing toolbox](http://vision.ucsd.edu/~pdollar/toolbox/doc/), included in `3rd_party/piotr_toolbox`.
* [Video Compass code from Derek Hoiem](http://www.cs.illinois.edu/homes/dhoiem/), included in `3rd_party/hoiemVideoCompass`;

Compilation
===========

Compile the object detector: 
* go to 3rd_party/voc-release3.1 from inside matlab, and run 'compile'

Compile the lib-svm
* go to 3rd_party/libsvm-mat-3.0-1 from inside matlab, and run 'make'

This has been tested with matlab version XXX or greater
* TODO: get CMU's matlab version

Information needed 
------------------

* focal length (can be obtained from EXIF)
* geometric context results (see )
* detected ground shadow boundaries (see ).
* pedestrian detector (see ).


References
==========

[1]	P. Felzenszwalb, D. McAllester, and D. Ramanan, "A discriminatively 
trained, multiscale, deformable part model," presented at the IEEE 
Conference on Computer Vision and Pattern Recognition, 2008.
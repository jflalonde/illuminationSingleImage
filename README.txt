This code implements the single-image illumination estimation technique
introduced in 

J.-F. Lalonde, A. A. Efros, and S. G. Narasimhan, ?Estimating the Natural 
Illumination Conditions from a Single Outdoor Image,? International 
Journal of Computer Vision, vol. 98, no. 2, pp. 123?145, Jun. 2012.



See function demoEstimateIllumination.m


-- Requirements --

My 'utils' package, available on github:
    http://www.github.com/jflalonde/utils

My 'skyModel' package, available on github:
    http://www.github.com/jflalonde/skyModel

LibSVM (included in 3rd_party/libsvm-mat-3.0-1)
    see http://www.csie.ntu.edu.tw/~cjlin/libsvm

Felzenszwalb et al. object detector [1] (included in 3rd_party/voc-release3.1)
    see http://www.cs.uchicago.edu/~pff/latent

Piotr Dollar's image processing toolbox (included in 3rd_party/piotr_toolbox)
    see ...


-- Compilation --

Compile the object detector: 
    go to 3rd_party/voc-release3.1 from inside matlab, and run 'compile'

Compile the lib-svm
    go to 3rd_party/libsvm-mat-3.0-1 from inside matlab, and run 'make'




This has been tested with matlab version XXX or greater
TODO: get CMU's matlab version

Needs: 

- focal length (can be obtained from EXIF)

- geometric context results (see )

- detected ground shadow boundaries (see ).

- pedestrian detector (see ).


-- References --

[1]	P. Felzenszwalb, D. McAllester, and D. Ramanan, ?A discriminatively 
trained, multiscale, deformable part model,? presented at the IEEE 
Conference on Computer Vision and Pattern Recognition, 2008.
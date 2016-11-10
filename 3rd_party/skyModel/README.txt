This is a MATLAB implementation of the Perez sky model [1] that we've 
re-parameterized as a function of common camera parameters, as explained in 
our IJCV 2010 paper [2].

See the following website for more information:

http://graphics.cs.cmu.edu/projects/sky/


=== TEST FILE ===

Use the file 'synthesizeSky.m' as a starting point. 


=== SKY MODEL ===

These files synthesize the sky model based on camera parameters as inputs:
- exactSkyModel.m: Synthesizes the full sky model;
- exactGradientModel.m: Synthesizes only the "gradient" part of the sky model;
- exactSunModel.m: Synthesizes only the "sun" part of the sky model.

These files synthesize the sky model based on angles as inputs (Perez sky model):
- perezSkyModel.m: Synthesizes the full sky model;
- perezGradientModel.m: Synthesizes only the "gradient" part of the sky model;
- perezSunModel.m: Synthesizes only the "sun" part of the sky model.

Useful files that convert from pixel coordinates to angles:
- pixelAzimuthAngle.m: Converts from pixels to azimuth angle;
- pixelZenithAngle.m: Converts from pixels to zenith angle.


=== TURBIDITY ===

These files deal with converting the turbidity to the Perez weather 
coefficients (in 3 channels in xyY color space, as in [3]):

- convertTurbidityToSkyParams.m: Converts turbidity to the weather 
  coefficients;
- getTurbidityMapping.m: Returns the turbidity mapping between the weather 
  coefficients in each channel.

=== REFERENCES ===

[1]	R. Perez, R. Seals, and J. Michalsky, "All-weather model for sky 
luminance distribution -- preliminary configuration and validation," Solar 
Energy, vol. 50, no. 3, pp. 235--245, Mar. 1993.

[2]	J.-F. Lalonde, S. G. Narasimhan, and A. A. Efros, "What do the sun and 
the sky tell us about the camera?," International Journal of Computer
Vision, vol. 88, no. 1, pp. 24--51, May 2010.

[3]	A. J. Preetham, P. Shirley, and B. Smits, "A practical analytic model 
for daylight," presented at the Proceedings of ACM SIGGRAPH 1999, 1999.


=== CHANGELOG ===

09/18/12: Now using github! See commit messages for changelogs. 
09/21/11: Added missing file 'exactGradientModelRatio.m'. Thanks to A. 
Ravichandran for pointing this out!

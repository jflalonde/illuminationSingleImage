function G = createGabor(or, n)
%
% G = createGabor(numberOfOrientationsPerScale, n);
%
% Precomputes filter transfer functions. All computations are done on the
% Fourier domain. 
%
% If you call this function without output arguments it will show the
% tiling of the Fourier domain.
%
% Input
%     numberOfOrientationsPerScale = vector that contains the number of
%                                orientations at each scale (from HF to BF)
%     n = imagesize (square images)
%
% output
%     G = transfer functions for a jet of gabor filters


Nscales = length(or);
Nfilters = sum(or);

l=0;
for i=1:Nscales
    for j=1:or(i)
        l=l+1;
        param(l,:)=[.35 .3/(1.85^(i-1)) 16*or(i)^2/32^2 pi/(or(i))*(j-1)];
    end
end

% Frequencies:
[fx, fy] = meshgrid(-n/2:n/2-1);
fr = fftshift(sqrt(fx.^2+fy.^2));
t = fftshift(angle(fx+sqrt(-1)*fy));

% Transfer functions:
G=zeros([n n Nfilters]);
for i=1:Nfilters
    par=param(i,:);
    tr=t+param(i,4); 
    tr=tr+2*pi*(tr<-pi)-2*pi*(tr>pi);

    G(:,:,i)=exp(-10*param(i,1)*(fr/n/param(i,2)-1).^2-2*param(i,3)*pi*tr.^2);
end


if nargout == 0
    figure
    for i=1:Nfilters
        max(max(G(:,:,i)))
        contour(fftshift(G(:,:,i)),[1 .7 .6],'r');
        hold on
        drawnow
    end
    axis('on')
    axis('square')
    axis('ij')
end


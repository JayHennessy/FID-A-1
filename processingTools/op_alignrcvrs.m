% op_alignrcvrs.m
% Jamie Near, McGill University 2014.
% 
% USAGE:
% [out,ph,sig]=op_alignrcvrs(in,point,mode,coilcombos);
% 
% DESCRIPTION:
% phase align the receiver channels without combining them.
% 
% INPTUS:
% in            = input spectrum in matlab structure format.
% point         = Index of point in time domain to use for phase refernece.  
% coilcombos	= (optional)  The predetermined coil phases and amplitudes as
%                 generated by the op_getcoilcombos.m function.  If this
%                 argument is provided, the 'point', and 'mode', arguments
%                 will be ignored.

function [out,ph]=op_alignrcvrs(in,point,coilcombos);

if in.flags.addedrcvrs
    error('ERROR:  Receivers have already been combined!  Aborting!');
end

%To get best possible SNR, add the averages together (if it hasn't already been done):
if in.dims.averages>0
    av=op_averaging(in);
else
    av=in;
end

%also, for best results, we will combine all subspectra:
if nargin<3
    if in.flags.isISIS
        av=op_ISIScombine(av);
    end
    if in.dims.subSpecs>0
        av=op_combinesubspecs(av,'summ');
    end
end
avfids=av.fids;
avspecs=av.specs;

%initialize phase matrix and the amplitude maxtrix that are the size of nPoints x Coils
ph=ones(in.sz(in.dims.t),in.sz(in.dims.coils));
sig=ones(in.sz(in.dims.t),in.sz(in.dims.coils));

mode='w';
%now start finding the relative phases between the channels and populate
%the ph matrix
for n=1:in.sz(in.dims.coils)
    if nargin<3
        ph(:,n)=phase(avfids(point,n,1,1))*ph(:,n);
        switch mode
            case 'w'
                sig(:,n)=abs(avfids(point,n,1,1))*sig(:,n);
            case 'h'
                S=max(abs(avfids(:,n,1,1)));
                N=std(avfids(end-100:end,n,1,1));
                sig(:,n)=(S/(N.^2))*sig(:,n);
        end
    else
        ph(:,n)=coilcombos.ph(n)*ph(:,n);
        sig(:,n)=coilcombos.sig(n)*sig(:,n);
    end
end

%now replicate the phase matrix to equal the size of the original matrix:
replicate=in.sz;
replicate(1)=1;
replicate(2)=1;
ph=repmat(ph,replicate);
%sig=repmat(sig,replicate);
%sig=sig/max(max(max(max(sig))));


%now apply the phases by multiplying the data by exp(-i*ph);
fids=in.fids.*exp(-i*ph);
fids_presum=fids;
specs_presum=fftshift(ifft(fids,[],in.dims.t),in.dims.t);


%FILLING IN DATA STRUCTURE
out=in;
out.fids=fids_presum;
out.specs=specs_presum;




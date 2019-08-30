function [f,X,f_max,X_max] = PSD(signal,dt)
    % Calculates the PSD of a signal
    % By Igor Kavrakov
    signal(:)=signal;
    if mod(length(signal),2)==1
        signal=signal(1:end-1);
    end

    NSign=length(signal);
    Fs=1/((NSign)*dt);
    f=Fs.*(0:1:floor(NSign)-1);

    % Twiddle factor = W_NSignal^{kn}=exp(-j*2pi/NSignal*k*n)
    X=fft(signal); %X[k]=sum_n_Nsignal(x[n]*W_Nsignal^{kn})=sum_n_Nsignal(x[n]*(-j)^nk) %TWO SIDED!

    % Division by L. x(t) - Fourier is X(w). Butt we assume periodicity; hence
    % we hve x(nT), T is the sampling period, for n periods. Take FFT of x(nT)
    % we get Y(w). The relationship between is X(w)=T*Y(w). Now since matlab
    % does only x(n*1) we need to take the T into account. therefore to get
    % X(w) we need to multiply Y(w) with T. Since the sampling period
    % T=1/NSignal - we need to scale the X HENCE:

    % Single sided
    f=f(1:ceil((NSign+1)/2));
    X=X(1:ceil((NSign+1)/2));

    % Now we take one sided spectrum, compute the power (abs) and we multiply by two so that we take
    % into account the energy on the right side. DC component (mean) is unique
    % - therefore we start from the second value;
    X=abs(X);
    X=X.^2;
    X(1:end-1)=dt./NSign.*X(1:end-1)*2;

    [X_max,ind]=max(X);
    f_max=f(ind);
    X=X(:);
    f=f(:);
end

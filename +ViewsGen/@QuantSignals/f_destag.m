function u = f_destag(x,X,tvectf,seas_f) % uguale ad f_destag ma con X e tvectf caricati con load
% funzione che serve a destagionalizzare i prezzi power
% in generale alfa*sin(lambda*t) + beta*sin(lambda*t), con periodo oscillazione
% pari a : P = 2*pi/lambda e quindi lambda = 2*pi/P (se ragiono in termini
% di frazioni di anno un periodo di sei mesi vuol dire P = 0.5 e quindi
% lambda = 4*pi. (lambda deve ovviamente essere compreso in [0;pi] ed è la
% frequenza angolare). alfa e beta determinano l'ampiezza
% dell'oscillazione: A = (alfa^2 + beta^2).^0.5
    
    f = seas_f(x,tvectf); 
    u = sum((X-f).^2);
end 





%FILE DEL PROGETTO DI TATA
% 
% 
% ASCOLTO DEI SEGNALI:
% Si pu� usare la funzione "sound(vettore,freq.camp)" 
% 
%DIVERSA NORMALIZZAZIONE FASI 
%
% Carlo Fortini   Roberto Calandrini


clear all;
close all;

time=cputime;

%creazione finestra
win=hamming(256);
%%
%SEGNALI IMPORTATI --> Creare un file script da richiamare, o una funzione
%che restituisca i segnali da utilizzare...

%definita anche la frequenza di campionamnto per come viene importato il file audio

% [signal1,Fs1]=wavread('A_maschile.wav');
% [signal2,Fs2]=wavread('Bella_Casa.wav');
% [signal3,Fs3]=wavread('Brutta_Casa.wav');

[signal1,Fs1]=wavexread('3personePCM.wav');
[signal2,Fs2]=wavexread('Toms_diner.wav');
[signal3,Fs3]=wavexread('voce_maschile.wav');

%PORTO TUTTI E TRE I SEGNALI ALLO STESSO VOLUME
signal1=signal1*(1/max(signal1));
signal2=signal2*(1/max(signal2));
signal3=signal3*(1/max(signal3));

%segnali

%%
%PADDING

%definizione segnali

lunghezza=max(length(signal1),length(signal2));
lunghezza=max(lunghezza,length(signal3));

signal1=cat(1,signal1,zeros(lunghezza-length(signal1),1));
signal2=cat(1,signal2,zeros(lunghezza-length(signal2),1));
signal3=cat(1,signal3,zeros(lunghezza-length(signal3),1));


%Ritardo dei segnali per il secondo microfono (in numero di campioni)
rit1=50;
rit2=90;        %prima erano 160,560,800...provo per vedere...!!!
rit3=10;        %da capire bene per la geometria del problema...

%definizione segnali
signal1r=[zeros(rit1,1); signal1];
signal2r=[zeros(rit2,1); signal2];
signal3r=[zeros(rit3,1); signal3];

%calcolo la lunghezza massima
lunghezzar=max(length(signal1r),length(signal2r));
lunghezzar=max(lunghezzar,length(signal3r));

%padding
signal1r=cat(1,signal1r,zeros(lunghezzar-length(signal1r),1));
signal2r=cat(1,signal2r,zeros(lunghezzar-length(signal2r),1));
signal3r=cat(1,signal3r,zeros(lunghezzar-length(signal3r),1));

padd=max(lunghezza,lunghezzar);

signal1=cat(1,signal1,zeros(padd-length(signal1),1));
signal2=cat(1,signal2,zeros(padd-length(signal2),1));
signal3=cat(1,signal3,zeros(padd-length(signal3),1));
signal1r=cat(1,signal1r,zeros(padd-length(signal1r),1));
signal2r=cat(1,signal2r,zeros(padd-length(signal2r),1));
signal3r=cat(1,signal3r,zeros(padd-length(signal3r),1));

%%
%SEGNALI AI DUE MICROFONI
%creo il segnale totale al primo microfono
mic1=signal1+signal2+signal3;
%creo il segnale totale al secondo microfono
mic2=signal1r+signal2r+signal3r;

%%
%SPLICING/FOURIER

%CALCOLO LE STFT DEI SEGNALI DEI DUE MICROFONI

STFT1=STFT(mic1,win);
STFT2=STFT(mic2,win);

figure(1);
subplot(2,2,1); surf(10*log10(abs(STFT1)));
subplot(2,2,2); surf(10*log10(abs(STFT2)));
subplot(2,2,3); imagesc(10*log10(abs(STFT1)));
subplot(2,2,4); imagesc(10*log10(abs(STFT2)));

%%
% %RAPPORTO DIAGRAMMI STFT E CLASSIFICAZIONE

quoziente=STFT2./STFT1;

moduli=abs(quoziente);
fasi=angle(quoziente);

%NORMALIZZAZIONE DELLE FASI
for a=1:size(fasi,1);
    Norm=2*pi*a*8000/length(win);   %giusta normalizzazione delle frequenze
end;

for a=1:size(fasi,2);
    fasi(:,a)=fasi(:,a)./Norm;
end;

%EQUALIZZAZIONE DELLE FEATURES

%fasi
den=1/340*0.04;   %1/c^(-1)*d    c=velocit� prop.  d=distanza microfoni
fasi=fasi/den;

%moduli
energiaNorm=sum(abs(reshape(STFT1,1,[])));  %+sum(abs(reshape(STFT2,1,[])))
moduli=moduli/sqrt(energiaNorm);



moduli=reshape(moduli,size(moduli,1)*size(moduli,2),1);
fasi=reshape(fasi,size(fasi,1)*size(fasi,2),1);


matrix=[moduli,fasi];

%Utilizzo una metrica in norma L1 per "proteggermi" da errori di stima
%degli outliers presenti
[IDX Cen]= kmeans(matrix,3);     %capire bene se ha funzionato ai fini della separazione....vedi diverse metriche di distanza


%conto gli elementi di ogni cluster (PER CONTROLLO!!!)

sorg1=0;sorg2=0;sorg3=0;

for i=1:length(IDX);
    if IDX(i,1)==1;
        sorg1=sorg1+1;
    else
        if IDX(i,1)==2;
            sorg2=sorg2+1;
        else
            if IDX(i,1)==3;
                sorg3=sorg3+1;
            end;
        end;
    end;
end;

sorg1
sorg2
sorg3

%Disegno dei tre cluster sul grafico dello spazio delle features...
%  [...]
disp('coordinate dei centroidi');
Cen

%%
%CREAZIONE DELLE MASCHERE BINARIE

%per ogni punto della matrice mi dice il bin a che cluster � stato
%assegnato
class=reshape(IDX,length(win),[]);

masc1=zeros(size(STFT1,1),size(STFT1,2));
masc2=zeros(size(STFT1,1),size(STFT1,2));
masc3=zeros(size(STFT1,1),size(STFT1,2));

for i=1:size(masc1,1);
    for t=1:size(masc1,2);
        if (class(i,t)==1);
            masc1(i,t)=1;
        else
            if (class(i,t)==2);
                masc2(i,t)=1;
            else
                masc3(i,t)=1;
            end;
        end;
    end;
end;

%%
%ISFT --> dai vettori della stft (opportunamente "filtarti" con le maschere binarie create dalla classificazione)
%devo ricreare i segnali nel tempo
%PHASE UNWRAPPING
%IFFT

%APPLICAZIONE DELLE MASCHERE BINARIE AI DIAGRAMMI Spazio-Tempo

sig1masc=STFT1.*masc1;
sig2masc=STFT1.*masc2;
sig3masc=STFT1.*masc3;

%IFFT e RICOSTRUZIONE

sig1ric=ISTFT(sig1masc,win);
sig2ric=ISTFT(sig2masc,win);
sig3ric=ISTFT(sig3masc,win);

%TRASFORMATE DEI SEGNALI RICOSTRUITI
tra1=STFT(sig1ric',win);
tra2=STFT(sig2ric',win);
tra3=STFT(sig3ric',win);

figure; imagesc(10*log10(abs(tra1))); title('Prima Sorgente ricostruita');
figure; imagesc(10*log10(abs(tra2))); title('Seconda Sorgente ricostruita');
figure; imagesc(10*log10(abs(tra3))); title('Terza Sorgente ricostruita')

%%
%TEMPO DI ELABORAZIONE

disp('Tempo impiegato per elaborare')
time=cputime-time

%%
% %RICORDARE LE RELAZIONI DI SIMMETRIA DELLA TRASFORMATA DI FOURIER:
% %
% %   SEQUENZA             TRASFORMATA
% %
% %   Real and Even        Real and Even
% %   Real and Odd         Imaginary and Odd
% %   Imaginary and Even   Imaginary and Even
% %   Imaginary and Odd    Real and Odd 
% 
% 
% 
% % Bisognerebbe provare a fare la classificazione con solamnte due sorgenti 
% % e poi provare a farla con sorgenti piu facili
% %Capire bene anche il discorso delle fasi....
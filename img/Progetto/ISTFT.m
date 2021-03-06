%Inverse STFT

% FORMULA PER IL CALCOLO DELLA LUNGHEZZA DEL SEGNALE A PARTIRE DALLA STFT
% 
% length(signal)=(length(win)/2)*#splice-length(win)/2+length(win);
% 

function [signal]=ISTFT(matrix,win)


lun1=size(matrix,1); %numero di righe (lunghezza finestra)
lun2=size(matrix,2); %numero di colonne della matrice


for i=1:lun2;  %cio� faccio la trsformata inversa di tutte le colonne
    
    sigIFFT(:,i)=ifft(matrix(:,i),'symmetric'); %al massimo reinserire 'symmetric'
        
end;

%ora devo ricostruire al contrario dello splicing
%per semplicit� utilizzo le trasposte delle matrici IFFT

%sigIFFT=sigIFFT';

%prealloco lo spazio necessario (formula all'inizio)
lunghezza=(lun1/2)*lun2-lun1/2+lun1; %2 al posto dei diviso4
signal=zeros(1,lunghezza);

%preparo il primo splice del seganle ricostruito
signal(1,1:lun1)=(sigIFFT(:,1))';

for n=2:lun2;
    
    start=1+(n-1)*(lun1/2); %diviso 2 al posto che diviso 4
    fin=start+lun1-1;
    
    signal(1,start:fin)=(sigIFFT(:,n))'+signal(1,start:fin);
         
end;

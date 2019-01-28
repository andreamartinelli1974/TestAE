% here we need to provide the informatrion needed to properly classify
% portfolio items that do not have a correct bloomberg field for the needed
% classification (e.g. there is no sector info for futures on utilities or
% energy etc..)
% this script is called by Universe.GetLastDate 

IndexSectorTable{1,1}='Generic 1st ''IT'' Future'; IndexSectorTable{1,2}='Utilities'; IndexSectorTable{1,3}='Utilities';
IndexSectorTable{2,1}='Generic 1st ''EB'' Future'; IndexSectorTable{2,2}='Consumer, Cyclical'; IndexSectorTable{2,3}='Auto Manufacturers';
IndexSectorTable{3,1}='Generic 1st ''WZ'' Future'; IndexSectorTable{3,2}='Communications'; IndexSectorTable{3,3}='Telecommunications';

save IndexSectorTable IndexSectorTable
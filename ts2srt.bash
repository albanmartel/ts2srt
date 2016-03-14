# ----------------------------------------------------
# Script''ts2srt''
# ----------------------------------------------------

# Par ''Alban MARTEL''
# Courriel : albanmartel(POINT)developpeur(AT)gmail(POINT)com
# Utilisant comme base de travail le script de beguam
# http://doc.ubuntu-fr.org/tutoriel/vobsub_srt
# License : GNU GPL
# Ce script permet d'extraire les sous-titres d'une video TS et de les transformer en SRT éditable.
#
# Depends : 
# ffmpeg est une collection de logiciels libres destinés au traitement de flux audio ou vidéo
# mkvToolnix (interface graphique pour mkvmerge) est un ensemble d'outils permettant de créer, de modifier et d'inspecter des fichiers Matroska 
# cuneiform - Système de reconnaissance optique de caractères multi-langue
# ogmrip - Application pour extraire et encoder des DVDs
#
# Date : 26/08/2015
# version : 0.1
# Mise-à-jour : 
# ----------------------------------------------------

# !/bin/bash
# OUTPUT-COLORING
red=$( tput setaf 1 )
green=$( tput setaf 2 )
NC=$( tput sgr0 )      # or perhaps: tput sgr0
#NC=$( tput setaf 0 )      # or perhaps: tput sgr0


function readDirectoryPath(){
  echo -n "chemin absolu du répertoire des vidéos où extraire les sous-titres : "
  read directory;
  courant_directory=$(pwd);
  if [[ ! -e "$directory" ]]; then
    echo "incorrect";
    readDirectoryPath;    
  fi
  cd $directory;
  directory=$(pwd);
  cd $courant_directory;
  echo $directory;
  #testIfAnyFileIsPresent=$(find . -maxdepth 1 -iname "*.$extension" | wc -l);
}


function presentationOfFileDirectory(){
  message=$("<<"$directory">> contient les fichiers suivants :  ");
  files=$(ls $directory/*.*);
  print "%$\n" "${green}$message${NC}";
  print "%$\n" "${green}$files${NC}";
}


function readVideoExtension(){
  echo -n "Extension des fichiers vidéos à traiter ("$((4-$count))" tentatives restantes) : "
  read extension;
  testIfAnyFileIsPresent=$(find $directory -maxdepth 1 -iname "*.$extension" | wc -l);
}


function choiseTypeOfVideo(){
  
  local tmp_videos=""
  count=0;
  readDirectoryPath;
  presentationOfFileDirectory;
  testIfAnyFileIsPresent=0;
  while [ $testIfAnyFileIsPresent = 0 ] && [ $count != 3 ] ; do
    count=$(($count+1));
    readVideoExtension;
  done

  if [ $count = 3 ] ; then
    print "%$\n" "${red}""3 mauvaises tentatives entrainent l\'arrêt du programme""${NC}";
    print "%$\n" "${red}""Abandon""${NC}";
    exit 100;
  fi
  #/home/alban/Vidéos/fr3/annez.ts" | sed "s/\(.*\)\/\([Aa-Zz]*.$extension\)/\2/g"
  #Example : data0001.ts data0002.ts data0003.ts
  echo -e "##choiseTypeOfVideo"> $directory"/CommandConversion.sh"
  cd $directory;
  videoFiles=($( ls *.$extension ));
  extract_work_files=($(echo ${videoFiles[@]} | sed "s/.$extension//g"));
  echo -e '#videoFiles : '${videoFiles[@]}"\n#extract_work_files: "${extract_work_files[@]}>> $directory"/CommandConversion.sh"
  cd $courant_directory;
}  


function cleanVideoInformations() {
    echo -e "## cleanVideoInformations " >> $directory"/CommandConversion.sh"
    cat $1 | grep Imput > $2;
    echo -e "cat "$1" | grep Imput > "$2 >> $directory"/CommandConversion.sh"    
    cat $1 | grep Duration >> $2;
    echo -e "cat "$1" | grep Duration >> "$2 >> $directory"/CommandConversion.sh" 
    cat $1 | grep Stream >> $2;
    echo -e "cat "$1" | grep Stream >> "$2 >> $directory"/CommandConversion.sh"
    rm $1
    echo -e "rm "$1 >> $directory"/CommandConversion.sh"
}


function prepareCommandToObtainSubtitlesTrackNumber(){
  local a;
  #local j=0;
  echo -e "## prepareCommandToObtainSubtitlesTrackNumer " >> $directory"/CommandConversion.sh"
  for (( i=0 ; i < ${#videoFiles[@]} ; i++ )) ; do
    #/home/alban/Vidéos/fr3/ENEMY/data0003.ts
    data_videos_files[i]=$(echo $directory"/"${videoFiles[i]});
    echo -e "#"${data_videos_files[i]} >> $directory"/CommandConversion.sh"
    #/tmp/data0001_subtitle_infos.txt
    tmp_video_info[i]=$(echo "/tmp/"${videoFiles[i]} | sed "s/.$extension/_subtitle_infos.txt/g");
    echo -e "#"${tmp_video_info[i]} >> $directory"/CommandConversion.sh"
    #/tmp/data0003.ts.info
    video_info_file[i]=$(echo /tmp/${videoFiles[i]}.info);
    echo -e "#"${video_info_file[i]} >> $directory"/CommandConversion.sh"
    #ffprobe /home/alban/Vidéos/fr3/ENEMY/data0003.ts 2>&1 | ffmpeg -i EnnemyMine.ts -vn -an 2>&1 | grep '[A-Z][a-z]\{4\}' | sed "s/\(^[ ]*\)\([[:alnum:]]\)/\2/g" >/tmp/data0001_subtitle_infos.txt 
    ffprobe ${data_videos_files[i]} -hide_banner 2>&1 | grep '[A-Z][a-z]\{4\}' | sed "s/\(^[ ]*\)\([[:alnum:]]\)/\2/g" >${tmp_video_info[i]};
    echo -e "ffprobe "${data_videos_files[i]}" -hide_banner 2>&1 | grep '[A-Z][a-z]\{4\}' | sed \"s/\(^[ ]*\)\([[:alnum:]]\)/\2/g\" >\${tmp_video_info[i]}">> $directory"/CommandConversion.sh"
    echo -e "#Avant Nettoyage : "${tmp_video_info[i]} >> $directory"/CommandConversion.sh"
    #create a cleanning file  of video information
    echo -e "#cleanVideoInformations "${tmp_video_info[i]}" "${video_info_file[i]}  >> $directory"/CommandConversion.sh"
    cleanVideoInformations "${tmp_video_info[i]}" "${video_info_file[i]}";
    echo -e "#Resultat Nettoyage : "${video_info_file[i]} >> $directory"/CommandConversion.sh"
  done
}


function createDirectoryIfNotExist(){
  echo -e "## createDirectoryIfNotExist" >> $directory"/CommandConversion.sh"
  if [[ ! -e $1 ]] ; then
    mkdir $1;
    echo -e "mkdir "$1>> $directory"/CommandConversion.sh"
  fi
  
}


function ExtractSubtitleFromVideoInMKV(){
  local i=0;
  local j=0;
  local k=0;
  echo -e "## ExtractSubtitleFromVideoInMKV " >> $directory"/CommandConversion.sh"
    #cat /tmp/video-info.txt | grep Subtitle | sed "s/\(^.* \#\)\([0-9]:[0-9]\)(\([[:alnum:]]\{3\}\))\(.*\)/\2#\3/g"
    # tracks_Info[1] =Stream #0:5(fra): Subtitle: dvd_subtitle (default) Stream #0:6(ger): Subtitle: dvd_subtitle Stream #0:7(fra): Subtitle: dvd_subtitle    
    #tracks_Info[i]=$(cat ${video_info_file[i]} | grep Subtitle | sed "s/\(^.* \#\)\([0-9]:[0-9]\)(\([[:alnum:]]\{3\}\))\(.*\)/\2#\3/g" );
    #echo -e "#Track info : \n"${tracks_Info[i]} >> $directory"/CommandConversion.sh"
    #rm ${video_info_file[i]};
    #echo -e "rm "${video_info_file[i]} >> $directory"/CommandConversion.sh"
  #echo  'tracks_Info: '${video_info_file[@]};
  echo  'tracks_Info: '${videoFiles[@]}" tracks_video Info: "${#video_info_file[@]}" extract_work_files: "${extract_work_files[@]};
  echo -e 'tracks_Info: '${videoFiles[@]}" tracks_video Info: "${#video_info_file[@]}" extract_work_files: "${extract_work_files[@]}>> $directory"/CommandConversion.sh"
  for (( i=0 ; i < ${#video_info_file[@]} ; i++ )) ; do
    array_number=($(cat ${video_info_file[i]} | grep subtitle | cut -d"#" -f2 | cut -d'[' -f1))
    array_lang=($(cat ${video_info_file[i]} | grep subtitle | cut -d"#" -f2 | cut -d')' -f1 | cut -d'(' -f2))
    echo "rm "${video_info_file[i]} >> $directory"/CommandConversion.sh"
    rm ${video_info_file[i]};
    echo -e "#createDirectoryIfNotExist "${directory}/${extract_work_files[i]} >> $directory"/CommandConversion.sh"
    createDirectoryIfNotExist "${directory}/${extract_work_files[i]}";

    for (( j=0 ; j < ${#array_number[@]} ; j++ )) ; do
      echo -e "ffmpeg -threads 4 -i "${directory}/${videoFiles[i]}"-hide_banner -map "${array_number[j]}" -vn -an -scodec dvdsub "${directory}/${extract_work_files[i]}/${extract_work_files[i]}_${array_lang[j]}_${array_number[j]}".mkv" >> $directory"/CommandConversion.sh"
      ffmpeg -threads 4 -i ${directory}/${videoFiles[i]} -hide_banner -map ${array_number[j]} -vn -an -scodec dvdsub ${directory}/${extract_work_files[i]}/${extract_work_files[i]}_${array_lang[j]}_${array_number[j]}.mkv;
      mkv_files[${#mkv_files[*]}]=$(echo ${directory}/${extract_work_files[i]}/${extract_work_files[i]}_${array_lang[j]}_${array_number[j]}.mkv);
      echo -e "#mkv_files :\n#"${directory}/${extract_work_files[i]}/${extract_work_files[i]}_${array_lang[j]}_${array_number[j]}".mkv" >> $directory"/CommandConversion.sh"
      mkv_directories[${#mkv_directories[*]}]=$(echo ${directory}/${extract_work_files[i]});
      echo -e "#mkv_directories :\n#"${directory}/${extract_work_files[i]} >> $directory"/CommandConversion.sh"
      subtitle_sub_id[${#subtitle_sub_id[*]}]=$(echo ${extract_work_files[i]}_${array_lang[j]}_${array_number[j]});
      echo -e "#subtitle_sub_id :\n#"${extract_work_files[i]}_${array_lang[j]}_${array_number[j]} >> $directory"/CommandConversion.sh"
      subtitle_lang[${#subtitle_lang[*]}]=$(echo ${array_lang[j]});
      echo -e "#subtitle__lang :\n#"${array_lang[j]} >> $directory"/CommandConversion.sh"
    done
  done
}



function OpticalRecognitionCharacterOfTiff(){
  echo -e "## OpticalRecognitionCharacterOfTiff " >> $directory"/CommandConversion.sh"
  for eachTiff in $1*.tif; do
    echo -e "cuneiform -l "$2" -f text -o "$eachTiff".txt "$eachTiff >> $directory"/CommandConversion.sh"
    cuneiform -l $2 -f text -o $eachTiff.txt $eachTiff;     
  done 

}


function convertMKVSubtitle(){
  local j=0
  echo -e "## convertMKVSubtitleInSRT " >> $directory"/CommandConversion.sh"
  for (( i=0 ; i < ${#mkv_files[@]}; i++ )); do 
    #mkvextract tracks /home/alban/Vidéos/fr3/EnnemyMine/EnnemyMine_0_fra.mkv -c ISO8859-1 0:/home/alban/Vidéos/fr3/EnnemyMine/EnnemyMine_0_fra
    cd ${mkv_directories[i]}
    echo -e "cd "${mkv_directories[i]} >> $directory"/CommandConversion.sh"
    mkvextract tracks ${mkv_files[i]} -c ISO8859-1 0:${subtitle_sub_id[i]};
    echo -e "mkvextract tracks "${mkv_files[i]}" -c ISO8859-1 0:"${subtitle_sub_id[i]} >> $directory"/CommandConversion.sh"
    # if sub file existe and has a size equal to 0 than erase sub and idx files
    if [ ! -s ${mkv_directories[i]}/${subtitle_sub_id[i]}.sub ]; then 
      rm ${mkv_directories[i]}/${subtitle_sub_id[i]}.sub;
      rm ${mkv_directories[i]}/${subtitle_sub_id[i]}.idx;
      echo -e "rm "${mkv_directories[i]}/${subtitle_sub_id[i]}".sub;\nrm "${mkv_directories[i]}/${subtitle_sub_id[i]}".idx;"  >> $directory"/CommandConversion.sh";
    fi
    
   done
   cd ${directory}
   echo -e "cd "${directory} >> $directory"/CommandConversion.sh"
}


function tif2SRT(){
  local i=0
  for (( i=0 ; i < ${#mkv_files[@]}; i++ )); do 
    if [ -s ${mkv_directories[i]}/${subtitle_sub_id[i]}.sub ]; then 
      cd ${mkv_directories[i]}
      echo -e "subp2tiff --sid=0 -n "${subtitle_sub_id[i]}  >> $directory"/CommandConversion.sh";
      subp2tiff --sid=0 -n ${subtitle_sub_id[i]};
      echo -e "OpticalRecognitionCharacterOfTiff "${subtitle_sub_id[i]}" "${subtitle_lang[i]}  >> $directory"/CommandConversion.sh";
      OpticalRecognitionCharacterOfTiff "${subtitle_sub_id[i]}" "${subtitle_lang[i]}";
      echo -e "#commande subptools : \nsubptools -s -w -t srt -i ${subtitle_sub_id[i]}.xml -o ${directory}/${subtitle_sub_id[i]}.srt" >> $directory"/CommandConversion.sh";
      subptools -s -w -t srt -i ${subtitle_sub_id[i]}.xml -o ${directory}/${subtitle_sub_id[i]}.srt
    fi  
    
  done
  cd ${directory}
  echo -e "cd "${directory} >> $directory"/CommandConversion.sh"
  for each in ${mkv_directories[@]}; do
    echo -e "rm -rf "$each >> $directory"/CommandConversion.sh";
    rm -rf $each;
    
  done
}


choiseTypeOfVideo;
prepareCommandToObtainSubtitlesTrackNumber;
ExtractSubtitleFromVideoInMKV
convertMKVSubtitle;
tif2SRT;
exit 0;
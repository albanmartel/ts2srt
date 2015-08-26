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
  cd $directory;
  videoFiles=($( ls *.$extension ));
  cd $courant_directory;
}  


function cleanVideoInformations() {
    cat $1 | grep Imput > $2;
    cat $1 | grep Duration >> $2;
    cat $1 | grep Stream >> $2;
    rm $1;  
}


function prepareCommandToObtainSubtitlesTrackNumer(){
  local a;
  #local j=0;
  for (( i=0 ; i < ${#videoFiles[@]} ; i++ )) ; do
    #/home/alban/Vidéos/fr3/ENEMY/data0003.ts
    data_videos_files[i]=$(echo $directory"/"${videoFiles[i]});
    #/tmp/data0001_subtitle_infos.txt
    tmp_video_info[i]=$(echo "/tmp/"${videoFiles[i]} | sed "s/.$extension/_subtitle_infos.txt/g");
    #/tmp/data0003.ts.info
    video_info_file[i]=$(echo /tmp/${videoFiles[i]}.info);
    #ffprobe /home/alban/Vidéos/fr3/ENEMY/data0003.ts 2>&1 | ffmpeg -i EnnemyMine.ts -vn -an 2>&1 | grep '[A-Z][a-z]\{4\}' | sed "s/\(^[ ]*\)\([[:alnum:]]\)/\2/g" >/tmp/data0001_subtitle_infos.txt 
    ffprobe ${data_videos_files[i]} 2>&1 | grep '[A-Z][a-z]\{4\}' | sed "s/\(^[ ]*\)\([[:alnum:]]\)/\2/g" >${tmp_video_info[i]};
    #create a cleanning file  of video information
    cleanVideoInformations "${tmp_video_info[i]}" "${video_info_file[i]}";
    #cat /tmp/video-info.txt | grep Subtitle | sed "s/\(^.* \#\)\([0-9]:[0-9]\)(\([[:alnum:]]\{3\}\))\(.*\)/\2#\3/g"
    # tracks_Info[1] =Stream #0:5(fra): Subtitle: dvd_subtitle (default) Stream #0:6(ger): Subtitle: dvd_subtitle Stream #0:7(fra): Subtitle: dvd_subtitle
    tracks_Info[i]=$(cat ${video_info_file[i]} | grep Subtitle | sed "s/\(^.* \#\)\([0-9]:[0-9]\)(\([[:alnum:]]\{3\}\))\(.*\)/\2#\3/g" );
    rm ${video_info_file[i]};
  done
}


function createDirectoryIfNotExist(){
  if [[ ! -e $1 ]] ; then
    mkdir $1;
  fi
  
}

function ExtractSubtitleFromVideoInMKV(){
  local j=0;
  local k=0;
  $1
  echo  'tracks_Info: '${tracks_Info[@]};
  for ((i=0 ; i< ${#tracks_Info[@]}; i++)); do
      #From : data0001.ts to: data0001
      extract_work_files[i]=$(echo ${videoFiles[i]} | sed "s/.$extension//g");
      #echo ${directory}/${extract_work_files[i]};
      createDirectoryIfNotExist "${directory}/${extract_work_files[i]}";
      tmp=($(echo ${tracks_Info[i]}));
      for each in ${tmp[@]};do
	# De : 0:4#fra à : 0.4 fra
	#0:4
	track_number=$(echo $each | cut -d'#' -f1);
	#fra
	track_lang=$(echo $each | cut -d'#' -f2);
	#ffmpeg -threads 4 -i /home/alban/Vidéos/fr3/ENEMY/data0001.ts -map 0:5 -vn -an -scodec dvdsub /home/alban/Vidéos/fr3/ENEMY/data0001/data0001_0_fra.mkv
	ffmpeg -threads 4 -i ${directory}/${videoFiles[i]} -map $track_number -vn -an -scodec dvdsub ${directory}/${extract_work_files[i]}/${extract_work_files[i]}\_$j\_$track_lang.mkv;	
	mkv_files[k]=$(echo ${directory}/${extract_work_files[i]}/${extract_work_files[i]}\_$j\_$track_lang.mkv);
	mkv_directories[k]=$(echo ${directory}/${extract_work_files[i]});
	subtitle_sub_id[k]=$(echo ${extract_work_files[i]}\_$j\_$track_lang);
	subtitle_lang[k]=$(echo $track_lang);
	j=$(($j + 1));
	k=$(($k + 1))
      done
  done
}



function OpticalRecognitionCharacterOfTiff(){
  for eachTiff in $1*.tif; do 
    cuneiform -l $2 -f text -o $eachTiff.txt $eachTiff; 
  done 

}


function convertMKVSubtitleInSRT(){
  local j=0
  for (( i=0 ; i < ${#mkv_files[@]}; i++ )); do 
    #mkvextract tracks /home/alban/Vidéos/fr3/EnnemyMine/EnnemyMine_0_fra.mkv -c ISO8859-1 0:/home/alban/Vidéos/fr3/EnnemyMine/EnnemyMine_0_fra
    mkvextract tracks ${mkv_files[i]} -c ISO8859-1 0:${mkv_directories[i]}/${subtitle_sub_id[i]};
    # if sub file existe and has a size equal to 0 than erase sub and idx files
    if [ ! -s ${mkv_directories[i]}/${subtitle_sub_id[i]}.sub ]; then 
      rm ${mkv_directories[i]}/${subtitle_sub_id[i]}.sub;
      rm ${mkv_directories[i]}/${subtitle_sub_id[i]}.idx;
    fi
  done

  for (( i=0 ; i < ${#videoFiles[@]} ; i++ )) ; do
    work_directories=$(echo ${videoFiles[i]} | sed "s/.$extension//g") ;
    #mkv_directories=$(echo $directory/work_directories  kv_directories${videoFiles[i]} | sed "s/.$extension//g");
    for each in $directory/$work_directories"/*.idx"; do
      subtitle_sub=($(echo $each));
      for filesub in ${subtitle_sub[@]}; do
	#id_file=/home/alban/Vidéos/clanDesSabresVollants/de/Le_Secret_des_poignards_Volants_base/Le_Secret_des_poignards_Volants_base__fra
	id_file=$(echo $filesub | sed "s/.idx//g");
	subp2tiff --sid=0 -n $id_file;
	#fra
	sub_lang=$(echo $filesub | sed "s/\(.*\)\([a-z]\{3\}\)\(.idx\)/\2/g");
	#subtitle_file_name : /home/alban/Vidéos/clanDesSabresVollants/de/Le_Secret_des_poignards_Volants_base/Le_Secret_des_poignards_Volants_base__fra.srt
	subtitle_file_name=$(echo $filesub |  sed "s/.idx//g");
	echo "subtitle_file_name : "$subtitle_file_name;
	#sub_id=$directory/$work_directories$(echo $filesub | sed "s/\(.*\)\(\_[0-9]\_\)\([a-z]\{3\}\)\(.idx\)/\2\3/g");
	#OpticalRecognitionCharacterOfTiff "$sub_id" "$sub_lang";
	OpticalRecognitionCharacterOfTiff "$subtitle_file_name" "$sub_lang";
	#echo $directory/$(echo ${videoFiles[i]} | sed "s/.$extension//g")/;
	# tmp= Le_Secret_des_poignards_Volants_base__fra
	tmp=$(echo $filesub | sed "s/\(.*\)\/\(.*\)\(.idx\)/\2/g" );
	echo "commande subptools : subptools -s -w -t srt -i $id_file.xml -o $directory/$tmp.srt";
	subptools -s -w -t srt -i $id_file.xml -o $directory/$tmp.srt
      done
      rm -rf $directory/$work_directories;
    done
  done
}

choiseTypeOfVideo;
prepareCommandToObtainSubtitlesTrackNumer;
ExtractSubtitleFromVideoInMKV
convertMKVSubtitleInSRT;
exit 0;

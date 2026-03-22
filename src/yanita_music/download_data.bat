@echo off
set "DIR=assets\training_data"
if not exist "%DIR%" mkdir "%DIR%"

echo Descargando MusicXML (Partituras)...
curl.exe -L "https://raw.githubusercontent.com/musetrainer/library/master/scores/Ave_Maria_D839_-_Schubert_-_Solo_Piano_Arrg..mxl" -o "%DIR%\schubert_ave_maria.mxl"
curl.exe -L "https://raw.githubusercontent.com/musetrainer/library/master/scores/Bach_Minuet_in_G_Major_BWV_Anh._114.mxl" -o "%DIR%\bach_minuet_g.mxl"
curl.exe -L "https://raw.githubusercontent.com/musetrainer/library/master/scores/Bach_Toccata_and_Fugue_in_D_Minor_Piano_solo.mxl" -o "%DIR%\bach_toccata_d_minor.mxl"
curl.exe -L "https://raw.githubusercontent.com/musetrainer/library/master/scores/Beethoven_Symphony_No._5_1st_movement_Piano_solo.mxl" -o "%DIR%\beethoven_5th_symphony.mxl"
curl.exe -L "https://raw.githubusercontent.com/musetrainer/library/master/scores/Canon_in_D.mxl" -o "%DIR%\pachelbel_canon_d.mxl"
curl.exe -L "https://raw.githubusercontent.com/musetrainer/library/master/scores/Chopin_-_Nocturne_Op_9_No_2_E_Flat_Major.mxl" -o "%DIR%\chopin_nocturne_op9_2.mxl"
curl.exe -L "https://raw.githubusercontent.com/musetrainer/library/master/scores/Carol_of_the_Bells.mxl" -o "%DIR%\carol_of_the_bells.mxl"
curl.exe -L "https://raw.githubusercontent.com/musetrainer/library/master/scores/Arabesque_L._66_No._1_in_E_Major.mxl" -o "%DIR%\debussy_arabesque_1.mxl"
curl.exe -L "https://raw.githubusercontent.com/musetrainer/library/master/scores/12_Variations_of_Twinkle_Twinkle_Little_Star.mxl" -o "%DIR%\twinkle_twinkle.mxl"
curl.exe -L "https://raw.githubusercontent.com/musetrainer/library/master/scores/Bella_Ciao_-_La_Casa_de_Papel.mxl" -o "%DIR%\bella_ciao.mxl"

echo Descargando MP3 (Audio de Piano)...
curl.exe -L "https://upload.wikimedia.org/wikipedia/commons/transcoded/a/a3/Franz_Schubert_-_Ellens_dritter_Gesang.oga/Franz_Schubert_-_Ellens_dritter_Gesang.oga.mp3" -o "%DIR%\schubert_ave_maria.mp3"
curl.exe -L "https://upload.wikimedia.org/wikipedia/commons/transcoded/1/18/Bach%%2C_JS_-_Minuet_in_G_%%28Piano_Performance_by_eld%%C3%%BCendes%%C3%%BCarez%%29.wav/Bach%%2C_JS_-_Minuet_in_G_%%28Piano_Performance_by_eld%%C3%%BCendes%%C3%%BCarez%%29.wav.mp3" -o "%DIR%\bach_minuet_g.mp3"
curl.exe -L "https://upload.wikimedia.org/wikipedia/commons/transcoded/d/d4/Toccata_and_Fugue_in_D_minor%%2C_BWV_565.mp3/Toccata_and_Fugue_in_D_minor%%2C_BWV_565.mp3.mp3" -o "%DIR%\bach_toccata_d_minor.mp3"
curl.exe -L "https://upload.wikimedia.org/wikipedia/commons/7/7b/Ludwig_van_Beethoven_-_Symphony_5%%2C_Op._67_-_I._Allegro_con_brio.mp3" -o "%DIR%\beethoven_5th_symphony.mp3"
curl.exe -L "https://upload.wikimedia.org/wikipedia/commons/transcoded/1/15/Pachelbel%%27s_Canon.ogg/Pachelbel%%27s_Canon.ogg.mp3" -o "%DIR%\pachelbel_canon_d.mp3"
curl.exe -L "https://upload.wikimedia.org/wikipedia/commons/8/82/Nocturne_in_E_flat_major%%2C_Op._9_no._2.mp3" -o "%DIR%\chopin_nocturne_op9_2.mp3"
curl.exe -L "https://upload.wikimedia.org/wikipedia/commons/f/f6/Carol_of_the_Bells_piano.mp3" -o "%DIR%\carol_of_the_bells.mp3"
curl.exe -L "https://upload.wikimedia.org/wikipedia/commons/transcoded/0/0f/Claude_Debussy_-_Premi%%C3%%A8re_Arabesque_-_Patrizia_Prati.ogg/Claude_Debussy_-_Premi%%C3%%A8re_Arabesque_-_Patrizia_Prati.ogg.mp3" -o "%DIR%\debussy_arabesque_1.mp3"
curl.exe -L "https://upload.wikimedia.org/wikipedia/commons/d/d9/Mozart_-_12_Variations_K._265_-_Simone_Renzi.mp3" -o "%DIR%\twinkle_twinkle.mp3"
curl.exe -L "https://upload.wikimedia.org/wikipedia/commons/d/d3/Bella_Ciao_-_Piano_Solo.mp3" -o "%DIR%\bella_ciao.mp3"

REM Adicionales para asegurar calidad (Fur Elise, Gymnopedie)
curl.exe -L "https://upload.wikimedia.org/wikipedia/commons/3/3e/Audionautix-com-ccby-furelise.mp3" -o "%DIR%\beethoven_fur_elise.mp3"
curl.exe -L "https://upload.wikimedia.org/wikipedia/commons/2/2a/Gymnopedie_No._1_%%28ISRC_USUAN1100787%%29.mp3" -o "%DIR%\satie_gymnopedie_1.mp3"

echo Descargas completadas.

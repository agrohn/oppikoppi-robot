# Asennusohjeet

Tässä dokumentissa kuvataan tarvitavat järjestelmät ja palvelimet, sekä konfiguroinnit Oppikopin käyttöönottoon.


## 1. Linux-palvelin (oppikoppi)

- Ubuntu LTS-18.04.5 server. 20.04.x ei ole yhteensopiva toistaiseksi (1.6.2021).  
- Lataa https://ubuntu.com/download/alternative-downloads,  

### 1.1 Palvelimen vaatimukset  
- 16GB keskusmuistia
- 8 CPU
- Datalle riittävästi tilaa (esim. 100GB). Varmista, että levytilaa voi tarpeen mukaan kasvattaa oppimisanalytiikkadataa varten (lvm) 
- MongoDB:tä varten paras tiedostojärjestelmä on XFS tehokkuuden kannalta,
- Uudempi mongodb on syytä asentaa (käsin) parempaa aggregaatioputkea varten (esim. mongodb-org-4.4) 
- https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/

### 1.2 Tunnukset ja etäyhteydet

- Lisää paikallinen käyttäjä root-tunnuksen lisäksi
- Asenna OpenSSH-palvelin 
- Asenna xfreerdp ohjelmistorobotin käyttöä varten (windows-palvelin vaatii avoimein yhteyden) 

```
$ sudo apt-get install freedrp-x11
```

- Asenna ldap-utils AD-palvelimeen tehtäviä käyttäjätunnustietoja varten

```
$ sudo apt-get install ldap-tools
```

- Asenna X-ikkunointi, kevyt työpöytä ja Firefox-selain 

```
$ sudo apt install fluxbox firefox 
```

- Automaattinen X-kirjautuminen palvelimeen (esimerkiksi login managerin avulla)

```
$ sudo apt install slim 
$ sudo nano /etc/slim/slim.conf 
```

johon muokataan:

```
    default_user = <paikallinen käyttäjä> 

    auto_login = yes
```    

- asenna Linux-palvelimen työpöydän etäkäyttö 

VNC-palvelin
```
$ sudo apt install x11vnc tightvncserver 
```

Salasana VNC-yhteydellä kirjautuimista varten:
```
$ vncpasswd -f > /home/<paikallinen käyttäjä>/.vnc/passwd 
```


### 1.3 Sähköpostiasiakasohjelma

- `sudo apt install msmtp`
- Konfiguroi ~/.msmtprc-tiedosto ohjeen mukaan tukemaan organisaatiosi ympäristöä (lisätietoja komennolla `man msmtp`).
- Esimerkiksi O365-pilveen konfigurointi

```
host smtp.office365.com
port 587
user "sähköposti@edu.organisaatio.fi"
from "sähköposti@edu.organisaatio.fi"
password ""
auth on
tls_fingerprint	FINGERPRINT-SHA265-AVAIN
tls on
tls_starttls on
```

Ja tls_fingerprint-saadaan msmtp-komennolla seuraavan ohjeen mukaisesti:
```
tls_fingerprint [fingerprint]
              Set the fingerprint of a single certificate to accept for TLS. This certificate will be trusted regardless of its contents. The fingerprint should be  of
              type  SHA256,  but can for backwards compatibility also be of type SHA1 or MD5 (please avoid this).  The format should be 01:23:45:67:....  Use --server‐
              info --tls --tls-certcheck=off --tls-fingerprint= to get the server certificate fingerprint.
```

Eli ajamalla

```
$ msmtp --serverinfo --tls --tls-certcheck=off --tls-fingerprint=
```
Jonka palauttamasta listauksesta kohdan SHA256: jälkeen oleva merkkijono kopioidaan merkkijonon FINGERPRINT-SHA265-AVAIN tilalle.
Päivitä tls_fingerprint tarvittaessa, jos se muuttuu.


### 1.4 Oppimisen tietovarasto Learning Locker 

- Tarkempi ohjeistus saatavilla http://docs.learninglocker.net/guides-installing/ 
- ClamAV ei ole tarpeellinen 
- Ajamalla yhden komennon skripti, learning locker asentuu oikein 
- Lopussa skripti kysyy oletusorganisaatiota ja adminin tunnuksia, nämä on syytä olla valmiina 
- Organisaatio on ylemmän tason käsite, jonka sisälle luodaan oppimisen tietovarastoja. Organisaatio voi olla esimerkiksi ammattikorkeakoulu. Tarvitset myös sähköpostiosoitteen ja salasanan learning lockeriin kirjautumista varten. 
- Sähköpostin lähetys learning lockerista itsestään ei välttämättä toimi. Se ei tosin ole tässä tapauksessa tarpeellinen.  

### 1.5 XAPI-converter lokitedostojen muunnosta varten

Asenna ohjelma, joka muuntaa loki- ja arvosanatiedostot xAPI-lausekkeiksi ja lähettää learning lockeriin.
Ohjelma tarvitsee muutaman uudemman kirjaston, jotka ovat saatavilla focal-distron reposta.

```
$ nano –w /etc/apt/sources.list
```

Lisää rivi jolla saa focal-distron paketit mukaan 
```
$ echo ‘deb http://nl.archive.ubuntu.com/ubuntu focal main restricted universe multiverse’ >> /etc/apt/sources.list
```

Päivitä repo ja asenna paketit

```
$ sudo apt update 
$ sudo apt install nlohmann-json3-dev libb64-dev libcurlpp-dev cmake build-essential pkg-config libcurl4 libcurl4-gnutls-dev libboost-program-options-dev libcurl4-gnutls-dev libcurlpp0 
```

xapi_converter-sovelluksen asentaminen ja kääntäminen lähdekoodista

```
$ git clone https://github/agrohn/xapi_converter 
$ cd xapi_converter 
$ mkdir build 
$ cd build; cmake .. 
$ make -j$(nproc) 
```

### 1.6 Ohjelmistorobotin ja sen riippuvuuksien asentaminen

```
$ sudo apt install python3 python3-pip 
$ pip3 install –user robotframework  
$ pip3 install –user robotframework-seleniumlibrary 
$ git clone https://github.com/agrohn/oppikoppi-robot 
$ cd oppikoppi-robot 
$ wget https://github.com/mozilla/geckodriver/releases/download/v0.28.0/geckodriver-v0.28.0-linux64.tar.gz 
$ tar xvzf geckodriver-v0.28.0-linux64.tar.gz 
```



## 2. Palvelimen konfigurointi 

### 2.1 Hakemistorakenteen luominen 
Luo oletushakemistot tulevia skriptejä varten paikallisen tunnuksen avulla.
```
$ cd ~
$ mkdir Conversion Staging 
```

Paikallisen käyttäjän kotihakemistoon on syytä lisätä hakemisto powerbi-data, jonne tallennetaan koostetiedostot.

```
$ mkdir ~/powerbi-data
```
Koostetiedostojen puutuessa, Power BI Desktop-työkirja käyttää oletusdataa, joka on tallennettuna XXXX_-alkuisiin json-tiedostoihin. Ne on kopioitava
luomaasi powerbi-data-hakemistoon.

```
$ cp oppikoppi-robot/powerbi-data-base/*.json ~/powerbi-data
```

### 2.2 Learning Lockerin organisaatio ja tunnukset

Jos et luonut vielä organisaatiota ja adminia, nyt sen voi tehdä komentoriviltä Ubuntussa 

```
$ cd /usr/local/learninglocker/current/webapp/ 
$ node ./cli/dist/server createSiteAdmin [options] [email] [organisation] [password]  
```

### 2.3 Learning Lockerin tapahtumavaraston (Store) määritys dataa varten 

Että learning lockeriin voi tallentaa jotain, täytyy luoda ensin tapahtumavarasto (store). 

1. Kirjaudu learning lockeriin koneen domain-nimellä tai ip-osoitteella, ja paikallisen adminin tunnuksella, jonka loit learning lockeriin.  
2. Sen jälkeen avaa vasemmanpuoleisesta paneelista Settings->Stores ja klikkaa Add new-painiketta. 
3. Anna tapahtumavarastolle nimi ja kuvaus.  

### 2.4 Learning Lockerin asiakasrajapinnan määrittely datan tallentamiselle  

Tämän rajapinnan avulla voi lisätä, poistaa ja hakea tietoa learning lockerin tietovarastosta. Rajapinnan tunnisteet on syytä pitää ainoastaan luotetun joukon (ylläpitäjien) tiedossa.  

1.  Siirry Learning lockerissa Settings-> Clients. 
2.  Klikkaa add new. 
3.  Anna kuvaava nimi (esim. my-store-write) 
4.   Varmista, että “Enabled“ on ruksitettu.  

Key ja Secret muodostavat tämän asiakasrajapinnan tunnisteen ja salasanan, jotka myöhemmin tarvitaan xapi_converterin asetuksissa.  

5. Varmista, että Overall Scopes -> Delete statements (not coverted by All scope) on ruksittuna, mikäli haluat että tämän rajapinnan kautta myös poistot ovat mahdollisia. 
6.  Rajaa rajanpinnan pääsy haluttuun tietovarastoon (esim. my-store) 
7.  Helpointa on asettaa Scopes ALL(xAPI).  
8.  Authority voi olla yhä email.  Authority name sekä authority Email ovat tunnisteita. Ne tallentuvat kaikkiin xAPI-tapahtumiin, joka syötetään tämän asiakasrajapinnan kautta. Näiden avulla voi esimerkiksi jäljittää, mistä tietyt tapahtumat ovat tietovarastoon siirtyneet.  

### 2.5 Learning Lockerin asiakasrajapinnan määrittely datan hakemiselle 

Itse datan noutamiselle oppimisanalytiikkaa varten tarvitaan pelkkä lukuoikeus. Siihen kannatta hyöyntää erillistä rajapintaa, joka puolestaan annetaan visualisoinnin kehittäjille.  

1. Siirry Learning lockerissa Settings-> Clients. 
2. Klikkaa add new. 
3. Anna kuvaava nimi (esim. my-store-read) 
4. Varmista, että “Enabled“ on ruksitettu. Key ja Secret muodostavat tämän asiakasrajapinnan tunnisteen ja salasanan, jotka myöhemmin tarvitaan xapi_converterin asetuksissa.  

5. Rajaa rajanpinnan pääsy haluttuun tietovarastoon (esim. my-store-read) 
6. Aseta scopes 

-    Read all, Access state, Access profiles. 
-    Näiden avulla pääsee lukemaan kaikki lauseet, sekä kaikki mahdolliset luodut profiilt.  

### 2.6 Learning Lockerin mukana tulevan Nginx-palvelimen säätö 

Palvelin muokataan tukemaan myös koostetiedostojen sisältöjä pelkän Learning Lockerin palvelun sijaan. 
HUOM: Määritä polut (/path/to...) vastaamaan todellista polkua, esimerkiksi käyttäjän kotihakemistoa! 

Muokkaa tiedostoa
```
$ nano /etc/nginx/conf.d/learninglocker.conf 
```

Lisää uusi sääntö :

```
    server { 

    …  

    location /powerbi { 

           alias /path/to/powerbi-data; 

           autoindex on; 

             auth_basic "Restricted area"; 

           auth_basic_user_file /path/to/.htpasswd-nginx; 

      } 

    ... 
```

Sekä muokkaa sääntöä 

```
    # All other traffic directed to statics or Node server 

    location & { 

        try_files $uri @node_server;

    } 
```

muotoon

```
    # All other traffic directed to statics or Node server 

     location ~ ^/$ { 

             try_files $uri @node_server; 

      } 
```

Jolloin nginx-palvelin jakaa powerbi-hakemiston. Koostetiedostojen jakohakemisto (powerbi-data) on myös suojattava.
Tiedosto /path/to/.htpasswd-nginx on mahdollista tehdä vaikkapa htpasswd-komennolla. 
```
$ sudo apt install apache2-utils 
$ htpasswd /path/to/.htpasswd-nginx <käyttäjänimi> <salasana> 
```


### 2.7 SSL-sertifikaatti ja suojattu liikenne 

Tiedon siirtoa varten on syytä suojata http-liikenne oppikoppi-palvelimelta SSL-sertifikaatin avulla.
Mikäli palvelin on pelkästään sisäverkossa (mikä on järkevää), oman sertifikaatin allekirjoittaminen käy.  

Prosessia on avattu esimerkiksi täällä: https://develike.com/en/articles/adding-a-trusted-self-signed-ssl-certificate-to-nginx-on-debian-ubuntu 
Sertifikaatti tarvitaan myös oppikoppi-pbi–palvelimelle, niin asennettuna kuin erillisenä tiedostonakin.

### 2.8 Firefox-selaimen konfigurointi ohjelmistorobottia varten

1. Profiilin luominen robotframeworkia varten 

```
 $ firefox –P 
```
   Luo profiili Robot, jolle hakemisto Robot.Robot
   

2. Automaattinen tallennus kysymättä hakemistoon 

- Avaa firefox Robot-profiililla.  
- Avaa välilehti: about:preferences 
- Files and Applications-kohdasta, valitse Save files to Conversion (eli paikallisen käyttäjän kotihakemistossa oleva Conversion-hakemisto)
- Luo profiilihakemistoon Robot.Robot/handlers.json, johon sisältö: 
```
     {"defaultHandlersVersion":{"en-CA":1,"en-US":4},"mimeTypes":{"application/pdf":{"action":3,"extensions":["pdf"]},"application/json":{"action":0,"extensions":["json"]},"text/xml":{"action":3,"extensions":["xml"]},"image/svg+xml":{"action":3,"extensions":["svg"]},"image/webp":{"action":3,"extensions":["webp"]}},"schemes":{"ircs":{"action":2,"ask":true,"handlers":[null,{"name":"Mibbit","uriTemplate":"https://www.mibbit.com/?url=%s"}]},"mailto":{"action":4,"handlers":[null,{"name":"Yahoo! Mail","uriTemplate":"https://compose.mail.yahoo.com/?To=%s"},{"name":"Gmail","uriTemplate":"https://mail.google.com/mail/?extsrc=mailto&url=%s"}]},"irc":{"action":2,"ask":true,"handlers":[null,{"name":"Mibbit","uriTemplate":"https://www.mibbit.com/?url=%s"}]}}} 
```
    Tärkein on kohta `"application/json":{"action":0,"extensions":["json"]}`, joka sallii json-tyyppisten tietojen suoran tallentamisen ilman kysymistä. 

3. Itse kirjoitetu sertifikaatti on hyväksyttävä Firefox-selaimessa

### 2.9 xapi_converter-ohjelmiston säätäminen

Moodle-palvelimen osoite ja etuliitteet, sekä learning lockering client-avaimet ja salasanat. Sovelluksen konfigurointi 

```
$ cd .. 
$ ./build/moodle/xapi_moodler –generate-config 
$ mv config.json.template config.json 
$ nano config.json 
```

- Kopioi Learning Lockerin my-store-write-asiakasrajapintamäärityksestä key ja secret config.json -tiedoston “key”ja “secret”- kenttien oikealle puolelle lainausmerkkien sisään. 

-Aseta lms.baseURL-kentän arvoksi moodle-palvelimen osoite. Tätä arvoa käytettään xapi-lauseiden muodostamisessa ja yksilöllisten URL-osoitteiden muodostamisessa moodlen eri aktiviteetteja varten. Osoitteella ei sinällään ole merkitystä tapahtumien tallentamisen kannalta, mutta xAPI-tapahtumien linkit on helpompi visualisoinnissa saada osoittamaan oikeaan paikaan, mikäli tämäkin on valmiiksi oikein.  

### 2.10 Oppikoppi-robotframework-skriptit 

```    
$ cd /home/<paikallinen tunnus> 
$ cp credentials.robot.example credentials.robot 
```
Muokkaa credentials.robot-tiedostoon oikeat tunnukset, salasanat, tiedostopolut ja osoitteet kommenteissa olevien ohjeiden perusteella.

Huomoitavia mahdolliset muutokset:

`snap.robot` -  Suurelta osin sovitettu snap-teemalla toimivaksi, joten jos Moodlen teema on erilainen, se ei todennäköisesti toimi erilaisten css-luokkamääritysten yms. takia. 

`login.robot` - Kirjautumislogiikka, muokattava. Liikkeelle kannattaa lähteä skriptin lopussa olevista Log in to Moodle / Login in to Moodle Local –taskeista. 

`powerbi-service-rs.robot` - Tunnustenasetuslogiikka, muokattava ainakin opiskelijaryhmien AD-nimen osalta (STUDENT_GROUP_NAME). 

### 2.11 Ajastetut cronjob-skriptit 

Saatavilla hakemistosta cron. `crontab` sisältää ajastusmääritykset hakemistoittain. Merkittävimmät ajastukset crontab-tiedostossa ovat  

1. cron.fetch(ajetaan 0:30 öisin) 

`fetch-logs-to-learninglocker` hakee eilisen tapahtumat käyttäjän hallinoimista moodle-työtiloista ja siirtää ne xAPI-tapahtumina learning lockeriin.

2. cron.staging (ajetaan joka tunti, paitsi klo 0.00,ja 3.00-5.00) 

`handle-staging-events` ajaa tarvittavat datansiirtokomennot Staging-hakemistosta (eli siirtää luodut tapahtumat learning lockeriin). 

3. cron.transform (ajetaan klo 2:00 öisin) 

`powerbi-data-update` tekee tarvittavat koosteet learninglockerin tapahtumavarastosta kaikille käytössä oleville kursseille, ja tallentaa ne skriptissä määriteltyyn datadir-muuttujan määrittämään hakemistoon.  

4. cron.publish(ajetaan klo 5:00) 

`powerbi-service-publish` asettaa powerbi report serverin visualisointien käyttäjät ja jakoasetukset käyttäjätietojen perustella.  Tämän jälkeen pitäisi kaikkien moodle-työtilassa olevien organisaation käyttäjien päästä katsomaan visualisointia, mikäli muut asetukset ovat kunnossa.  Skripti koostaa HTML-sivun merkiksi julkaisusta. 

5. cron.oppikoppi-pbi-session-open (ajetaan klo 3.25)

Avaa windows-palvelimelle etäyhteyden, että objelmistorobotti toimii. 

6. cron.oppikoppi-pbi-session-close (ajetaan klo 4.55)

Sulkee etäyhteydet windows-palvelimelle lopettamalla kaikkien xfreerdp-ohjelmien suorituksen. Tarvittavat muutokset:

|cron-skripti|päivitettävät kohdat|
|---|---|
|cron.fetch|ajohakemiston polku ennen suorittamista (cd /path/to/oppikoppi-robot), merkkijono LOCAL_USER vastaamaan paikallista käyttäjää|
|cron.staging|ajohakemiston polku ennen suorittamista (/path/to/Staging/oppikoppi_send_all_events.sh)|
|cron.transform|datadir-muuttuja, sekä ajohakemiston polku (cd /path/to/oppikoppi-robot)|
|cron.publish|ajohakemiston polku ennen suorittamista (cd /path/to/oppikoppi-robot), publishdir-muuttuja (/path/to/publish-dir), sekä datadir-muuttuja ("/path/to/powerbi-data")|
|cron.oppikoppi-pbi-session-open|kirjautumistiedot (käyttäjänimi, salasana) sekä palvelimen ip-osoite|
|cron.oppikoppi-pbi-session-close|ei päivityksiä|

### 2.12 Apuskriptien muokkaus

Oppikoppi hyödyntää apuskriptejä koostetiedostojen luomisessa.

|Skripti|Päivitettävät kohdat|
|---|---|
|get-emails.sh |datadir-muuttuja osoittamaan powerbi-data-hakemistoon|
|ll-coursename.sh|/path/to -alkuiset polut vastaamaan oikeaa sijaintia. moodle-server-merkkijonot vastaamaan oikeaa palvelimen osoitetta. auth_oppikoppi-muuttujaan tiedon lukemisrajapinnan avain.server-muuttujaan learning locker-palvelimen ip-osoite.|
|send-publish-email.sh|CreateMessage-funktion sisältöön haluttu viesti  msg-muuttujaan. /path/to/ -alkuiset polut vastaamaan oikeaa sijaintia|
|utf8ascii_fix_sed.sh| ei päivityksiä|
|ll-courses.sh|/path/to -alkuiset polut vastaamaan oikeaa sijaintia. moodle-server-merkkijonot vastaamaan oikeaa palvelimen osoitetta. auth_oppikoppi-muuttujaan tiedon lukemisrajapinnan avain.server-muuttujaan learning locker-palvelimen ip-osoite.|
|ll-delete.sh|moodle-server-merkkijonot vastaamaan oikeaa palvelimen osoitetta. auth_oppikoppi-muuttujaan tiedon lukemisrajapinnan avain.server-muuttujaan learning locker-palvelimen ip-osoite.|
|ll-submissions.sh|moodle-server-merkkijonot vastaamaan oikeaa palvelimen osoitetta (huomioi myös pisteiden enkoodaus kyselyissä). auth_oppikoppi-muuttujaan tiedon lukemisrajapinnan avain.server-muuttujaan learning locker-palvelimen ip-osoite.|

## 3. Windows-palvelin (Oppikoppi-pbi)

Oppikoppi-pbi tarvitaan nimenomaan Power BI Desktop ja Power BI Desktop Report Serverin visualisointien rakentamiseen automaattisesti.  
Palvelimelle on asennettava tähän tarkoitukseen Power BI Desktop (Report Server version). 

### 3.1 oppikoppi-palvelimen sertifikaatin asentaminen  

- Oppikoppi-palvelimelle luotu SSL-sertifikaatin on tuotava tiedostona Windows-palvelimelle  
- Käyttöoikeudet myönnettävä Powerbi Report Serverin asetuksista.

Palvelimelle on asennettava Python3.x, sekä pakettienhallintasovellus pip, jonka jälkeen voidaan asentaa robotframework ja seleniumlibrary.
Lisäksi myös Git-versionhallintatyökalu on asennettava. 

### 3.2 Robot framework

```
pip install robotframework  robotframework-seleniumlibrary 
```

Tässä vaiheessa on syytä varmistaa, että PATH-ympäristömuuttujaan on asetettu poluksi Pythonin asennushakemistossa oleva Script-alihakemisto. Mikäli Python on asennettu esimerkiksi hakemistoon `C:\Tools\Python38`, PATH-muuttujassa pitää olla polku `C:\Tools\Python38\Scripts\`. Tällöin on `robot.exe` on suoritettavissa komentoriviltä mistä tahansa, ja ohjelmistorobotin skriptit ovat ajettavissa helpommin myös manuaalisesti.  

```
git clone https://github.com/agrohn/oppikoppi-robot 
```


### 3.3 PowerBI Desktop app for Report server 

1. https://powerbi.microsoft.com/en-us/report-server/ 
2. Klikkaa: Advanced download options 
3. Valitse kieli (english) ja download.  
4. Asennus kannattaa tehdä johonkin yksinkertaiseen polkuun, esim,. C:\Tools\PowerBIDesktop_RS, jolloin suoritustiedoston polun saa helpommin määriteltyä skripteihin.  

### 3.4 Ohjelmistorobotin tuen kytkeminen päälle Power BI Desktopista 

- File -> Options and settings -> Options, Report settings. otsikon Accessibility alta "Always run Power BI Desktop with improved narrator support."  
- Power BI Desktop for report server vaatii aina saman version niin Desktop-versiosta kuin on-premise palvelimestakin.  

### 3.5 Power BI Desktop-pohjien valmistelu 

Skriptin powerbi-desktop-rs.robot tarkoitus on luoda työtiloille powerbi-visualisointi työkirjapohjan avulla. Power BI –pohjat sisältävät parametrit palvelimen sekä kurssin asettamiseen, mutta tiedon noutamisessa tarvitaan kirjautuminen tarvittaville palvelimelle käsipelissä, tai tietolähdeasetusten säätäminen palvelinta vastaaviksi ennen automatisoidun skriptin suorittamista. 

1. Avaa `powerbi-templates/oppikoppi-template-rs.pbix` Power BI Desktop for Report Server-versiolla. Valitse Transform data -> Edit parameters. Aseta oppikoppi-palvelimen nimi oikein. Oppikoppi-palvelimen powerbi-hakemistossa pitäisi olla XXXX_-alkuiset JSON-tiedostot.

2. Klikkaa Refresh, jolloin powerbi hakee pohjaan määritetyistä tietolähteen osoitteista datan tauluihin, ja kysyy samalla tunnuksia. Joudut syöttämään oikeat tunnukset jokaiselle tietolähteelle erikseen, mutta onneksi vain kerran. Tämän jälkeen tunnukset ovat tallessa pohjassa, ja sinun ei tarvitse enää syöttää niitä. Voit tarkastella tietolähteiden tunnuksia File -> Data Options and setttings -> Data source settings.

### 3.6 Ajastus uusien työtilojen raporttien luomiseen. 

1. Avaa Windows-palvelimen Task Scheduler järjestelmänvalvojan oikeuksin.  

2. Valitse Create Task 

3. Avaa general välilehti 

4. Nimeä task

- Skripti tarvitsee kirjautuneen käyttäjän Power BI Desktop-sovelluksen vuoksi, joten valitse "Run only when user is logged on". 

5. Valitse Triggers-välilehti. 

6. Lisää uusi trigger, eli skriptin käynnistävä ehto 

- Begin the task: on a schedule 
- Settings: Daily 
- Start: kellonaika 03:30 - päiväys määrittää aloituspäivän. HUOM! Tämän on oltava cron.oppikoppi-pbi-session-open-cronjobin ajamisen jälkeen, että etäyhteys muodostuu palvelimelle ennen objelmistorobotin ajamista.
- Recur every: 1 days 

7.   Valitse Actions-välilehti 
-  Klikkaa New-painiketta 
-  Action: Start a program 
-  Program/script: polku robot.exe -tiedostoon. Esim. `C:\Tools\Python37\Scripts\robot.exe`
- Add arguments (optional): powerbi-desktop-rs.robot 
-  Start in (optional): polku oppikoppi-robot –repositoryn kloonaushakemistoon, esim.  `C:\Users\kayttaja.nimi\Documents\oppikoppi-robot`

8. Valitse Settings-välilehti: 

-  Stop the task if it runs longs than: 12h. Asetusta voi olla tarpeen säätää suuremmaksi, mikäli kerralla tulee paljon uusia työtilavisualisointeja siirrettäväksi (yli 100 kpl), ja yhden siirtäminen vie enemmän kuin 5 min. Huomioi kuitenkin, että tämän taskin on tarkoitus suorittua kerran päivässä, joten suoritusaika ei periaattessa voi olla suurempi kuin 1 vrk. 

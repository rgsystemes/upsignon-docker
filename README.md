![UpSignOn](logo.png)

# UpSignOn by Septeo

## Configuration minimale requise

Pour assurer de bonnes performances de la stack, la machine doit disposer au **minimum** des ressources suivantes :

* **vCPU :** 4
* **RAM :** 8 Go
* **Stockage :** 50 Go SSD

## Tableau des flux

| Source                         | Destination   | Protocole / Port | Description                                              |
|--------------------------------|-------------- |------------------|----------------------------------------------------------|
| Internet                       | Traefik       | TCP 443          | Applications uniquement en HTTPS                         |
| Traefik                        | Let’s Encrypt | TCP 443          | Génération et renouvellement automatique des certificats |
| Traefik                        | Server        | TCP 3000         | UpSignOn Server                                          |
| Traefik                        | Dashboard     | TCP 3001         | UpSignOn Dashboard                                       |
| Server & Dashboard & DB backup | PostgreSQL    | TCP 5432         | Connexion à la base de données                           |

Chaque **composant du service UpSignOn PRO** joue un rôle spécifique. Voici une description de chacun :
* **Traefik :** Sécurise et dirige le trafic Internet vers les différentes parties du service, en veillant à ce que toutes les connexions soient chiffrées en HTTPS.
* **Let’s Encrypt :** Service qui génère et renouvelle automatiquement les certificats pour sécuriser les connexions. L’utilisation de Let’s Encrypt est **optionnelle**, vous pouvez choisir d’utiliser vos propres [certificats personnalisés](README.md#certificats-ssl).
* **UpSignOn PRO Server :** Traite les données et assure le fonctionnement principal du service.
* **UpSignOn PRO Dashboard :** Interface d’administration qui permet de gérer et superviser le service facilement.
* **PostgreSQL :** Base de données qui stocke toutes les informations nécessaires au fonctionnement du service.

## Configuration DNS

Avant la mise en service, veuillez configurer le(s) enregistrement(s) DNS de type **A** de votre domaine vers l’adresse IP de votre machine. Vous pouvez choisir soit :
* **Un enregistrement unique** pour accéder aux services **UpSignOn server PRO** et **UpSignOn dashboard PRO** de type :
  * `https://upsignonpro.votre-domaine.fr`
  * `https://upsignonpro.votre-domaine.fr/admin`
* **Deux enregistrements distincts**, un pour chaque application, de type :
  * `https://upsignonpro.votre-domaine.fr`
  * `https://upsignonpro-admin.votre-domaine.fr`

Nous devons déclarer vos urls dans notre base de données pour qu'elles soit **autorisées**. Envoyez-nous **les deux urls** que vous aurez choisies, chemin compris, par email [BS-SEPTEOITSOLUTIONS-Support@septeo.com](mailto:BS-SEPTEOITSOLUTIONS-Support@septeo.com) avant de commencer l'installation pour ne pas perdre de temps.

## Prérequis d’installation

L'application nécessite les éléments suivants :
* **Git :** Consultez la [documentation officielle](https://git-scm.com/downloads) correspondant à votre système d'exploitation
* **Docker :** Consultez la [documentation officielle](https://docs.docker.com/engine/install) correspondant à votre système d'exploitation
* **Crontab :** Nécessaire pour planifier les mises à jour automatiques du code via [le script de déploiement](scripts/update.sh). Vérifiez que le service cron est installé et actif sur votre système.

## Récupération du projet

Lors de la première installation, clonez le **dépôt Git** à l’aide de la commande suivante :
```bash
git clone https://github.com/rgsystemes/upsignon-pro-server.git
```

## Certificats SSL

L’application prend en charge **l’utilisation de certificats SSL** afin de sécuriser les communications.  
Les clients peuvent soit utiliser des certificats générés automatiquement via **Let’s Encrypt**, soit fournir leurs **certificats personnalisés** (certificat et clé privée).  
Pour **Let's Encrypt**, aucune action n'est requise de votre part.  
En ce qui concerne les **certificats personnalisés**, plusieurs règles sont à respecter :
* Les fichiers doivent être placés dans le dossier [certs](certs).
* Le certificat et la clé privée doivent porter **le même nom**.
* Les extensions doivent être respectivement `.crt` pour le certificat et `.key` pour la clé privée. Exemple : 
  * `upsignonpro.crt`
  * `upsignonpro.key`
* Le fichier .crt doit contenir la **chaîne de certification complète** (fullchain) :
  * Le certificat du serveur
  * Suivi du ou des certificats intermédiaires
* Il est possible d’ajouter **plusieurs certificats personnalisés** dans le dossier [certs](certs) (un couple certificat/clé par nom), afin de prendre en charge plusieurs domaines ou sous-domaines.

## Configuration des variables d'environnement

L’application s’appuie sur un fichier `.env` pour charger ses variables de configuration. **Un fichier modèle** [.env.example](.env.example) est mis à disposition afin de présenter toutes les variables de configuration attendues par l’application.  
Avant de lancer le script de démarrage [init.sh](init.sh), vous devez **copier ce fichier modèle** et le renommer en `.env`, puis renseigner les valeurs adaptées à votre environnement :
```bash
cp .env.example .env
```
Assurez-vous ensuite d’avoir correctement défini toutes les variables nécessaires dans le fichier `.env` avant de démarrer l’application.

### Base de données

| Variable            | Valeur par défaut | Description                                                                                                                    |
|---------------------|-------------------|--------------------------------------------------------------------------------------------------------------------------------|
| DB_PASSWORD         | ✗                 | Doit contenir le mot de passe utilisé pour accéder à la base de données. Veillez à utiliser un **mot de passe fort** et à ne pas le partager. |
| DB_BACKUP_FREQUENCY | `1d`              | Définit la **fréquence** à laquelle les sauvegardes automatiques de la base de données sont effectuées. Le format attendu est un nombre suivi d’une unité : **s** → secondes, **m** → minutes, **h** → heures, **d** → jours. Exemple : **12h** pour une sauvegarde toutes les 12 heures. |
| MAX_DB_BACKUPS      | `7`               | Spécifie le **nombre maximal de sauvegardes** conservées. Lorsque cette limite est atteinte, les sauvegardes les plus anciennes sont automatiquement supprimées. |
| DB_BACKUPS_PATH     | `./backup`        | Indique le chemin du répertoire où seront **stockées les sauvegardes** de la base de données. |

### Application

| Variable                  | Valeur par défaut           | Description                                                                                                 |
|---------------------------|-----------------------------|-------------------------------------------------------------------------------------------------------------|
| SESSION_SECRET            | ✗                           | **Clé secrète** utilisée pour sécuriser les sessions utilisateur. Elle est générée automatiquement lors de l’exécution du script [init.sh](init.sh) et ne doit pas être modifiée manuellement. |
| SERVER_DOMAIN             | `server-uso.example.com`    | **Domaine ou sous-domaine** permettant d’accéder à le service **UpSignOn Server**. Ce domaine doit être correctement configuré dans votre DNS. Dans le cas de l’utilisation de **certificats personnalisés**, il doit également être associé à un certificat SSL valide. |
| DASHBOARD_DOMAIN          | `dashboard-uso.example.com` | **Domaine ou sous-domaine** permettant d’accéder à le service **UpSignOn Dashboard**. Comme pour le serveur, ce domaine doit être correctement configuré dans votre DNS. |
| DASHBOARD_URL_PATH_PREFIX | `/`                         | Définit **le chemin** sous lequel le service **UpSignOn Dashboard** est accessible. Par exemple : `/` → accessible à la racine du domaine, `/dashboard` → accessible via `https://<domain>/dashboard`. |
| ACCESS_ALLOWED_IPS        | `0.0.0.0/0,::/0`            | **Liste des adresses IP ou plages CIDR autorisées** à accéder au **service UpSignOn Dashboard**, séparées par des virgules. Par défaut, toutes les adresses sont autorisées. Il est recommandé de restreindre cette liste en production pour renforcer la sécurité. |
| HTTP_PROXY                | ✗                           | Définit un **proxy HTTP sortant**. Format : `http://user:pass@host:port`. À définir si votre environnement réseau l’exige. |

### Envoi d'emails

| Variable               | Valeur par défaut | Description                                                                              |
|------------------------|-------------------|------------------------------------------------------------------------------------------|
| SMTP_HOST              | ✗                 | **Adresse du serveur SMTP** utilisé pour l’envoi des emails de l’application. Ce serveur doit être accessible depuis l’environnement où l’application est déployée. |
| SMTP_PORT              | ✗                 | **Port du serveur SMTP**. Les ports les plus courants sont : **25** → SMTP non chiffré, **465** → SMTP avec SSL/TLS implicite, **587** → SMTP avec STARTTLS (recommandé)                         |
| SMTP_USER              | ✗                 | **Identifiant** utilisé pour **l’authentification** auprès du serveur SMTP. Il s’agit généralement de l’adresse email complète ou d’un nom d’utilisateur fourni par votre service de messagerie. |
| SMTP_PASSWORD          | ✗                 | **Mot de passe** associé au compte SMTP. |
| SMTP_SENDING_USER      | ✗                 | **Adresse email affichée comme expéditeur** des messages envoyés par l’application. |
| SMTP_ALLOW_INVALID_CRT | `false`           | Autorise **l’utilisation de certificats SSL/TLS invalides** lors de la connexion au serveur SMTP. Par défaut, seuls les certificats valides sont acceptés. |

> ℹ️ Note : Toutes ces variables sont optionnelles. Vous pouvez les configurer plus tard directement via le [dashboard de l’application](README.md#configuration-de-lenvoi-de-mails).

### Certificats Let's Encrypt

| Variable          | Valeur par défaut | Description                                                                              |
|-------------------|-------------------|------------------------------------------------------------------------------------------|
| LETSENCRYPT_EMAIL | ✗                 | **Adresse email** utilisée par Let’s Encrypt pour **l’enregistrement du compte et la gestion des certificats SSL**. Aucune autre configuration n’est nécessaire si vous utilisez Let’s Encrypt : **la génération et le renouvellement des certificats** sont entièrement pris en charge automatiquement par Traefik. Cette variable est uniquement requise si vous choisissez d’utiliser **Let’s Encrypt**. Si vous utilisez des **certificats personnalisés**, elle peut être ignorée. |

## Mise en route du service UpSignOn PRO

* Vérifier que le(s) **enregistrement(s) DNS** ont bien été [déclarés](README.md#configuration-dns).
* S’assurer que **Docker est installé et en cours d’exécution** sur la machine.
* Configurer les **variables d'environnement** dans le fichier `.env`.
* Uniquement si vous utilisez des **certificats personnalisés**, déposer vos certificats dans le dossier [certs](certs).
* Le script init.sh permet d’initialiser et de démarrer automatiquement l’application **UpSignOn Pro** via Docker. Il doit impérativement être exécuté dans son **dossier courant** avec les droits **root**. Lors de son exécution, vous devez choisir **le mode de gestion des certificats** en passant l’un des paramètres obligatoires suivants :
  * `-le` → utilisation de **Let’s Encrypt** (aucune action manuelle requise, gestion assurée automatiquement par Traefik)
  * `-certs` → utilisation de **certificats personnalisés**
```bash
./init.sh -le     # Let's Encrypt (gestion automatique par Traefik)
./init.sh -certs  # Certificats personnalisés
```
> ⚠️ Important! Le script [init.sh](init.sh) doit être exécuté uniquement lors de la première installation de l’application ou en cas de réinstallation complète. Une fois l’application initialisée et démarrée, le script ne doit pas être relancé.

### Première connexion à la console d'administration

À la fin de l’exécution du script, un **lien vers la console d’administration** sera généré avec les droits de superadministrateur. Ce lien sera valide durant **5 minutes**. Une fois ce délai dépassé, vous pourrez regénérer un lien de connexion temporaire à la console d'administration en exécutant le script [tmp_super_admin.sh](scripts/tmp_super_admin.sh) :
```bash
./scripts/tmp_super_admin.sh
```

### Configuration de l'envoi de mails

Lors du premier démarrage de l’application, [la configuration de l'envoi d'email](README.md#envoi-demails) est automatiquement initialisée à partir des variables définies dans le fichier `.env`.  
Vous pouvez **modifier ces paramètres** à tout moment depuis la console d’administration, dans l’onglet *Paramètres* -> *Paramètres*. Il est également possible de **tester l’envoi d’emails** en renseignant une adresse de destination. Un email test sera alors envoyé afin de valider la configuration de l'envoi d'emails.

### Ajout d'une première banque de coffres-fort

Dans la console d'administration, vous pouvez ajouter votre première banque de coffre-forts :
* Dans l'onglet *Paramètres* -> *Paramètres*, vérifiez que votre serveur UpSignOn PRO est en cours d'exécution.
* Dans l'onglet *Paramètres* -> *Banques de coffres-fort*, vous pouvez créer votre première banque. En cliquant sur le **bloc Super-Admin orange**, situé en haut à gauche de la page, vous accéderez à la liste de vos banques. Ouvrez la banque que vous venez de créer et naviguez ensuite vers l'onglet *Paramètres* de cette banque.
* Vous voyez alors un **lien de configuration**. Ce lien devra être utilisé par tous vos utilisateurs pour configurer leur application.

### Création de votre coffre-fort UpSignOn PRO

Toujours dans la console d'administration :
* Ouvrez la banque que vous venez de créer et naviguez ensuite dans l'onglet *Paramètres* -> *Autorisations*. Ajoutez **votre adresse email** (ou ***@votre-domaine.fr**) à la liste des adresses email autorisées pour cette banque.
* Installez [l'application UpSignOn](https://upsignon.eu/fr/downloads) sur votre poste.
* Dans l'onglet *Lien de configuration*, cliquez sur le **lien de configuration** ou scannez le **QR code**.
* Si tout est bien configuré, vous devriez pouvoir **créer votre coffre-fort UpSignOn PRO** dans l'application en suivant les instructions.

### Configuration de la connexion à la console directement via UpSignOn

Le lien que vous avez utilisé précédemment pour vous connecter était **temporaire**. Grâce à UpSignOn, vous allez pouvoir vous connecter très simplement à votre console d'administration :
* Lorsque votre coffre-fort aura été correctement créé, revenez sur la page *Super-Admin* dans votre console d'administration. Dans l'onglet *Paramètres* -> *Administrateurs*, utilisez le **formulaire d'ajout d'un administrateur** pour ajouter votre adresse email (en vous laissant le **rôle Super-Admin**), puis cliquez sur *(R)envoyer un email d'invitation*.
* Vous devriez alors recevoir **un email** (vérifiez éventuellement vos spams) qui vous permettra d'importer votre compte super-admin dans UpSignOn.
* Ouvrez le lien que vous aurez reçu par mail puis **suivez les instructions** dans l'application.

Grâce à UpSignOn, vous pouvez maintenant vous connecter en un clic à votre **compte super-admin**.  
Il ne vous reste plus qu'à configurer UpSignOn via votre dashboard selon vos besoins, à inviter d'autres administrateurs et à diffuser le lien de configuration à tous vos collègues.

## Gestion du service UpSignOn

### Backup de la base de données

Le container Docker `uso.pg_backup` est utilisé pour réaliser des backups de votre base de données. [La configuration des backups](README.md#base-de-données) est automatiquement initialisée à partir des variables définies dans le fichier `.env`.  
Vous pouvez **modifier ces paramètres** à tout moment, à l’exception de `DB_PASSWORD`, en mettant à jour les variables dans le fichier `.env`. Ensuite, redéployez les services en fonction du mode de gestion des certificats utilisé avec la commande appropriée :
```bash
docker compose -f docker-compose-le.yml up -d # Let's Encrypt (gestion automatique par Traefik)
docker compose -f docker-compose-certs.yml up -d # Certificats personnalisés
```

Vous pouvez lancer un **backup de la base de données** à tout moment en exécutant le script [pg_backup.sh](scripts/pg_backup.sh) avec les droits root :
```bash
./scripts/pg_backup.sh
```
> ℹ️ Lors de l’exécution du script, il vous sera demandé de saisir le mot de passe de la base de données afin d’autoriser la sauvegarde.

### Restauration de la base de données

Le script `pg_restore.sh` permet de **restaurer une sauvegarde de la base de données** pour l’application **UpSignOn Pro.** Le script doit être exécuté avec les droits root.
```bash
./scripts/pg_restore.sh
```

> ℹ️ Lors de l'exécution du script, suivez les instructions à l’écran :
> * Choisissez si vous souhaitez restaurer dans la **base existante** ou créer une **nouvelle base**.
> * Sélectionnez le **fichier de sauvegarde** à restaurer.
> * Si nécessaire, indiquez le **nom de la nouvelle base de données**.
> *  il vous sera demandé de saisir le **mot de passe de la base de données** afin d’autoriser la restauration. 

### Modification des certificats personnalisés

Vous pouvez modifier à tout moment les certificats TLS personnalisés de votre application.  
Ajoutez les nouveaux certificats en respectant les mêmes exigences que celles décrites [ici](README.md#certificats-ssl), puis exécutez le script [certificats.sh](scripts/certificats.sh).  
Ce script appliquera la nouvelle configuration TLS et redémarrera Traefik afin de prendre en compte les changements :
```bash
./scripts/certificates.sh
```
> ⚠️  Le redémarrage de Traefik entraîne une courte interruption de l’accès aux services.

## Mise à jour du service UpSignOn PRO

Le script [init.sh](init.sh) configure automatiquement une tâche planifiée (cron) qui met à jour le code chaque jour à 1h00. Lorsqu’une mise à jour est détectée, le script [update.sh](scripts/update.sh) est exécuté pour déployer la nouvelle version du service UpSignOn PRO.

> ⚠️ Le déploiement de la nouvelle version du service UpSignOn PRO provoque une **interruption de service**.

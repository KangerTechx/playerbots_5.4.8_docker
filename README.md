# Pandaria 5.4.8 – Serveur Dockerisé

## Vue d'ensemble

Ce projet fournit une **installation basée sur Docker** pour Pandaria 5.4.8, destinée comme **outil d’apprentissage** pour les serveurs de jeux conteneurisés.  
Il n’est pas conçu pour l’hébergement public ou une utilisation en production, mais permet de construire, configurer et exécuter Pandaria 5.4.8 localement de manière rapide.

---

## Objectif

Avec ce projet, vous pouvez :
- Construire et lancer rapidement un serveur Pandaria 5.4.8 sans gérer manuellement les dépendances.  
- Expérimenter avec des ajustements SQL, du contenu personnalisé et des configurations serveur.  
- Apprendre les workflows Docker pour des setups multi-services.

Ce projet est principalement destiné à **un usage personnel, test et éducatif**, et non pour un déploiement commercial ou à grande échelle.

---

## Fonctionnalités principales

- Compilation et configuration de base de données **automatisées** avec `make`.  
- Support pour **MariaDB interne** ou **connexions à une base externe**.  
- Services modulaires : chaque composant (authserver, worldserver, base de données, phpMyAdmin, utilitaires) fonctionne dans son propre conteneur.  
- Outils pour **configuration du client**, sauvegardes, et application de SQL personnalisé ou overrides de configuration.  
- Personnalisation via `/app/custom_sql` et `/app/custom_conf`.

Cette configuration est testée sur **Linux** avec Docker et Docker Compose.  
Windows et macOS sont supportés mais peuvent nécessiter des ajustements manuels, notamment pour MariaDB et les chemins de fichiers.

---

## Préparation du client

Avant de démarrer le serveur, votre **client World of Warcraft: Mists of Pandaria (5.4.8)** doit être patché correctement.  
Suivez les instructions fournies par le projet SkyFire ou Pandaria 5.4.8 pour votre version de client.  
Sans patch approprié, le client peut ne pas se connecter ou se comporter de manière imprévisible.

---

## Limitations

- Destiné à **un usage privé et éducatif uniquement**.  
- Non optimisé pour des **serveurs publics ou de production**.

---

## Guide d’installation rapide (Linux)

### 1. Prérequis

Assurez-vous que les éléments suivants sont installés :

- Docker  
- Docker Compose  
- Git  
- Client Telnet  

Installez-les via le gestionnaire de paquets de votre distribution (ex : `apt`, `dnf`, ou `pacman`).

---

### 2. Configuration de l’environnement

Copiez le fichier `.env` exemple et configurez-le :

```bash
cp env.dist .env
```

Éditez .env pour définir ::
- REALM_ADDRESS – votre IP ou hostname du serveur
- WOW_PATH – chemin vers votre client MoP 5.4.8
- Paramètres de base de données – mettez EXTERNAL_DB=true si vous souhaitez utiliser une base existante, sinon le conteneur MariaDB interne sera utilisé.


### 3. Installer et lancer le serveur

```bash
make install
````

Cette commande :
	1. Récupère ou met à jour le code source
	2. Construit tous les conteneurs Docker (utility, authserver, worldserver, base si interne)
	3. Compile le serveur Pandaria 5.4.8
	4. Extrait maps, DBC, VMaps et MMaps dans /app/data
	5. Initialise et configure la base de données
	6. Génère worldserver.conf et authserver.conf
	7. Démarre automatiquement tous les services

### 4. Configurer le client WoW

```bash
make configure_client
````

Cette commande met à jour automatiquement :
	•	realmlist.wtf
	•	Config.wtf

### 5. Connexion et jeu

Utilisez le compte administrateur par défaut (GM Level 3 – privilèges complets) :
```bash
Nom d’utilisateur : admin
Mot de passe : admin
```

### 6. Création de comptes supplémentaires

Utilisez la console d’administration à distance (RA) via Telnet, connecté avec le compte admin par défaut (GM Level 3) :

```bash
make telnet
```

This will connect to the RA console using REALM_ADDRESS and RA_PORT from your .env.
Log in with: admin pass: admion


```bash
account create <nom_utilisateur> <mot_de_passe>
account set gmlevel <nom_utilisateur> <gmlevel> <realmID>
```

GmLevels
	•	1 = Joueur normal (accès par défaut)
	•	3 = Privilèges GM les plus élevés

RealmID
	•	Le dernier argument est le realmID.
	•	Par défaut, le realm principal utilise l’ID 1.
	•	Utilisez -1 pour appliquer les mêmes permissions GM à tous les realms.

## Installation manuelle (sans make install)

Vous pouvez exécuter chaque étape manuellement avec Docker Compose :

```bash
# 1. Construire le conteneur utilitaire (compile SkyFire et fournit les outils)
docker compose build utility

# 2.  Compiler le core Pandaria 5.4.8
docker compose run --rm utility compile

# 3. Extraire maps, DBC, VMaps et MMaps
docker compose run --rm utility extract_data

# 4. Initialiser et remplir la base de données
docker compose run --rm utility init_db
docker compose run --rm utility populate_db
docker compose run --rm utility update_db
docker compose run --rm utility finalize_db

# 5. Générer les fichiers de configuration
docker compose run --rm utility configure

# 6. Démarrer les serveurs (authserver, worldserver, et DB si interne)
docker compose up -d

# 7. Suivre les logs
docker compose logs -f
```



## Aperçu des répertoires

This project uses several directories to organize source code, configuration, and runtime data.  
Below is an overview of each important directory and its purpose. Once connected, you can create accounts with:


## Directory Overview

| Directory                          | Purpose                                                                 |
|------------------------------------|-------------------------------------------------------------------------|
| `app/bin`                          | Binaries compilés (authserver, worldserver, outils de données)          |
| `app/custom_conf`                  | Overrides de configuration utilisateur, fusionnés après les defaults    |
| `app/data`                         | Données extraites du jeu (maps, DBC, VMaps, MMaps) utilisées par le serveur |
| `app/etc`                          | Fichiers de config par défaut (authserver.conf, etc.)                   |
| `app/lib`                          | Librairies requises par les binaires (si non installées système)        |
| `app/logs`                         | Logs des services (`authserver`, `worldserver`, etc.)                   |
| `app/sql/backup`                   | Sauvegardes de la base de données                                       |
| `app/sql/custom`                   | Scripts SQL personnalisés appliqués après toutes les mises à jour       |
| `app/sql/fixes`                    | Scripts de corrections appliqués après les updates mais avant les patches mineurs |
| `app/sql/install`                  | Scripts d’installation de base pour auth, world, characters             |
| `app/sql/misc`                     | Scripts SQL non appliqués automatiquement (expérimentations manuelles)  |
| `app/sql/templates`                | Templates pour bases ou realms de test                                  |
| `app/wow`                          | Copie locale du client MoP 5.4.8 (utilisée pour l’extraction de données) |
| `docker/authserver`                | Dockerfile et configs pour le conteneur `authserver`                    |
| `docker/utility`                   | Dockerfile pour compilation, outils et tâches de données                |
| `docker/worldserver`               | Dockerfile et configs pour le conteneur `worldserver`                   |
| `misc`                             | Scripts d’aide (configurateurs client, maintenance)                     |
| `src`                              | Code source du core Pandaria 5.4.8 et dépendances                       |


## Ordre d’exécution SQL

Lors de `make install` et de l’initialisation de la base, les scripts SQL de `/app/sql` sont exécuté dans l'ordre suivant:

1. **`install/`** – Schéma de base et données pour `auth`, `characters`, et `world`.  
2. **Mises à jour officielles** – Updates incrémentales depuis le dépôt core.  
3. **`fixes/`** – Correctifs appliqués **après les updates officiels mais avant les ajustements finaux** (e.g., bug fixes, structural corrections).  
4. **`custom/`** – Modifications gameplay personnalisées (mounts, vendors, rates) appliquées **en dernier**, après toutes les mises à jour et fixes.  
5. **`misc/`** – Non exécuté automatiquement, à utiliser pour tests manuels
6. **`backup/`** – Contient dumps pour rollback ou migration, non exécutés automatiquement.
7. **`templates/`**  – Fournit structures ou realms de test, non appliqué sauf appel explicite.

Cet ordre garantit :
	•	La base est construite à partir d’un état propre
	•	OLes updates officiels sont appliqués en premier
	•	Les correctifs et personnalisations ne créent pas de conflits
	•	Les scripts expérimentaux restent séparés jusqu’à exécution explicite


## Application de SQL et overrides de config

Vous pouvez exécuter les scripts SQL ou overrides de config sans réinstaller tout le serveur.  
**Note:** Après toute modification SQL ou config, redémarrez `worldserver` (et `authserver` si les configs onnt été mmodifiées) pour que les changements prennent effet.


### Exécution de scripts SQL

La commande `make apply_sql` exécute les fichiers SQL sur la base choisie.  
Usage:
```bash
make apply_sql <directory> [FILE=<filename.sql>] [DB=<database>]
```

Paramètres :
	•	<directory> – un des dossiers SQL sous /app/sql (misc, custom, fixes, etc.).
	•	FILE – (Optionnel) Fichier SQL unique à exécuter, sinon tous les fichiers du répertoire
	•	DB – (Optionnel) Base cible (auth, characters, or world).
	•	Si omis, la base est inférée depuis le nom du fichier (e.g., auth_*.sql → auth DB).

```bash
# Appliquer un seul fichier à la base inférée
make apply_sql misc FILE=my_script.sql

# Appliquer un fichier spécifique à une base
make apply_sql custom FILE=my_custom_world.sql DB=world

# Appliquer tous les scripts de fixes
make apply_sql fixes
```


### Application des overrides de configuration

```bash
make apply_custom_config [FILE=<filename.conf>]
```

Parameters:
	•	FILE – (Optionnel) Appliquer un seul fichier
	•	Si omis, tous les fichiers de /app/custom_conf sont appliqués.


```bash
# Appliquer tous les overrides
make apply_custom_config

# Appliquer un override spécifique
make apply_custom_config FILE=worldserver.conf
```

Reminder: Après les application des overrides de configuration, redémarrer worldserver (et authserver si affectté) pour les appliquer.



### Notes:
- Les fichiers `.keep` servent à préserver les dossiers vides dans Git.
- La plupart des répertoires (`/app/sql`, `/app/data`, `/src`, `/backup`) sont ignorés par Git sauf `.keep` ou dossiers custom spécifiques.
- Les scripts SQL dans `custom_sql/fixes` et `custom_sql/custom` sont exécutés automatiquement pendant `make setup_db`.  
  Les scripts dans `custom_sql/misc` **oivent être exécutés manuellement** si besoin.

  ### Disclaimer

Ce projet est **uniquement destiné à l’exploration et à l’apprentissage privé.**.  
Il n’est pas conçu pour l’hébergement public, l’usage commercial, ou comme serveur de production.
L’objectif est de permettre aux utilisateurs de découvrir Docker, expérimenter Pandaria 5.4.8 et explorer les configurations serveur dans un environnement privé et contrôlé.
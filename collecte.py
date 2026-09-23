import requests
import csv
import os
from dotenv import load_dotenv
import psycopg2
from datetime import date

# On charge les variables du fichier .env dans l'environnement Python
load_dotenv()

aujourdhui = date.today().isoformat()

url = "https://opendata.reseaux-energies.fr/api/records/1.0/search/"

fichier = "eco2mix_national.csv"



with open(fichier, "w", newline="", encoding="utf-8") as fichier_csv:

    ecrivain = None

    parametres = {
        "dataset": "eco2mix-national-tr",
        "rows" : 10000,
        "start": 0
    }

    response = requests.get(url, params=parametres)
    response.raise_for_status()

    donnee = response.json()

    records = donnee["records"]

    #On récupère les clés présent dans fields pour s'en servir comme nom de colonne
    colonnes = list(records[0]["fields"].keys())

    print("\nColonnes récupérées :")
    for i in colonnes:
        print("-", i)

    ecrivain = csv.DictWriter(
        fichier_csv,
        fieldnames=colonnes
    )

    #On écrit les nom des colonnes
    ecrivain.writeheader()

    # Écriture des données
    for i in records:
        if (i.get("fields")).get("consommation") is not None:
            ecrivain.writerow(i["fields"])

print("\nTerminé !")
print("Fichier créé :", fichier)

# On se connecte à PostgreSQL en récupérant les identifiants depuis les variables chargées
connexion = psycopg2.connect(
    host=os.getenv("DB_HOST"),
    port=os.getenv("DB_PORT"),
    dbname=os.getenv("DB_NAME"),
    user=os.getenv("DB_USER"),
    password=os.getenv("DB_PASSWORD")
)

print("Connexion à PostgreSQL réussie !")

# On récupère les données récentes de l'API
parametres = {
    "dataset": "eco2mix-national-tr",
    "rows": 100,
    "q": f"date_heure >= {aujourdhui}"
}
reponse = requests.get(url, params=parametres).json()

# On trouve l'enregistrement le plus récent avec une consommation non nulle
records_valides = [i for i in reponse["records"] if i["fields"].get("consommation") is not None]
enregistrement_recent = max(records_valides, key=lambda e: e["fields"]["date_heure"])

# On crée un curseur, l'outil qui permet d'exécuter des commandes SQL
curseur = connexion.cursor()

# On insère la ligne, en ignorant si date_heure existe déjà
curseur.execute("""
    INSERT INTO eco2mix_national (
        eolien, prevision_j1, bioenergies, consommation, nucleaire, ech_comm_angleterre,
        eolien_offshore, taux_co2, ech_comm_italie, hydraulique_fil_eau_eclusee, gaz,
        perimetre, date, hydraulique, ech_comm_allemagne_belgique, eolien_terrestre,
        hydraulique_step_turbinage, gaz_tac, ech_comm_suisse, stockage_batterie, pompage,
        fioul_autres, nature, ech_comm_espagne, gaz_ccg, fioul_tac, gaz_autres, fioul,
        bioenergies_dechets, bioenergies_biogaz, bioenergies_biomasse, solaire, heure,
        destockage_batterie, fioul_cogen, date_heure, hydraulique_lacs, charbon,
        prevision_j, ech_physiques
    )
    VALUES (
        %(eolien)s, %(prevision_j1)s, %(bioenergies)s, %(consommation)s, %(nucleaire)s, %(ech_comm_angleterre)s,
        %(eolien_offshore)s, %(taux_co2)s, %(ech_comm_italie)s, %(hydraulique_fil_eau_eclusee)s, %(gaz)s,
        %(perimetre)s, %(date)s, %(hydraulique)s, %(ech_comm_allemagne_belgique)s, %(eolien_terrestre)s,
        %(hydraulique_step_turbinage)s, %(gaz_tac)s, %(ech_comm_suisse)s, %(stockage_batterie)s, %(pompage)s,
        %(fioul_autres)s, %(nature)s, %(ech_comm_espagne)s, %(gaz_ccg)s, %(fioul_tac)s, %(gaz_autres)s, %(fioul)s,
        %(bioenergies_dechets)s, %(bioenergies_biogaz)s, %(bioenergies_biomasse)s, %(solaire)s, %(heure)s,
        %(destockage_batterie)s, %(fioul_cogen)s, %(date_heure)s, %(hydraulique_lacs)s, %(charbon)s,
        %(prevision_j)s, %(ech_physiques)s
    )
    ON CONFLICT (date_heure) DO NOTHING
""", enregistrement_recent["fields"])

# On valide définitivement les changements dans la base
connexion.commit()

print("Insertion terminée.")
curseur.close()
connexion.close()
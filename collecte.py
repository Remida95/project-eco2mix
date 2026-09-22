import requests
import csv

url = "https://opendata.reseaux-energies.fr/api/records/1.0/search/"

fichier = "eco2mix_national.csv"

start = 0
rows = 10000

with open(fichier, "w", newline="", encoding="utf-8") as fichier_csv:

    ecrivain = None

    parametres = {
        "dataset": "eco2mix-national-tr",
        "rows" : rows,
        "start": start
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
-- ============================================
-- Analyses SQL — Projet eco2mix
-- ============================================

-- 1. Répartition de la production par filière (en %)
WITH moyennes AS (
    SELECT
        AVG(nucleaire) AS moy_nucleaire,
        AVG(eolien) AS moy_eolien,
        AVG(solaire) AS moy_solaire,
        AVG(hydraulique) AS moy_hydraulique,
        AVG(gaz) AS moy_gaz,
        AVG(charbon) AS moy_charbon,
        AVG(bioenergies) AS moy_bioenergies,
        AVG(fioul) AS moy_fioul
    FROM eco2mix_national
),
totaux AS (
    SELECT
        *,
        (moy_nucleaire + moy_eolien + moy_solaire + moy_hydraulique + moy_gaz + moy_charbon + moy_bioenergies + moy_fioul) AS total
    FROM moyennes
)
SELECT
    ROUND(100.0 * moy_nucleaire / total, 1) AS pct_nucleaire,
    ROUND(100.0 * moy_eolien / total, 1) AS pct_eolien,
    ROUND(100.0 * moy_solaire / total, 1) AS pct_solaire,
    ROUND(100.0 * moy_hydraulique / total, 1) AS pct_hydraulique,
    ROUND(100.0 * moy_gaz / total, 1) AS pct_gaz,
    ROUND(100.0 * moy_charbon / total, 1) AS pct_charbon,
    ROUND(100.0 * moy_bioenergies / total, 1) AS pct_bioenergies,
    ROUND(100.0 * moy_fioul / total, 1) AS pct_fioul
FROM totaux;

-- 2. Renouvelable vs Non-renouvelable

WITH moyennes AS (
    SELECT
        AVG(nucleaire) AS moy_nucleaire,
        AVG(eolien) AS moy_eolien,
        AVG(solaire) AS moy_solaire,
        AVG(hydraulique) AS moy_hydraulique,
        AVG(gaz) AS moy_gaz,
        AVG(charbon) AS moy_charbon,
        AVG(bioenergies) AS moy_bioenergies,
        AVG(fioul) AS moy_fioul
    FROM eco2mix_national
)
SELECT
    (moy_eolien + moy_solaire + moy_hydraulique + moy_bioenergies) AS renouvelable,
    (moy_nucleaire + moy_gaz + moy_charbon + moy_fioul) AS non_renouvelable,
    ROUND(100.0 * (moy_eolien + moy_solaire + moy_hydraulique + moy_bioenergies)
        / (moy_nucleaire + moy_eolien + moy_solaire + moy_hydraulique + moy_gaz + moy_charbon + moy_bioenergies + moy_fioul), 1) AS pct_renouvelable,
    ROUND(100.0 * (moy_nucleaire + moy_gaz + moy_charbon + moy_fioul)
        / (moy_nucleaire + moy_eolien + moy_solaire + moy_hydraulique + moy_gaz + moy_charbon + moy_bioenergies + moy_fioul), 1) AS pct_non_renouvelable
FROM moyennes;

-- 3. Carboné vs Décarboné

WITH moyennes AS (
    SELECT
        AVG(nucleaire) AS moy_nucleaire,
        AVG(eolien) AS moy_eolien,
        AVG(solaire) AS moy_solaire,
        AVG(hydraulique) AS moy_hydraulique,
        AVG(gaz) AS moy_gaz,
        AVG(charbon) AS moy_charbon,
        AVG(bioenergies) AS moy_bioenergies,
        AVG(fioul) AS moy_fioul
    FROM eco2mix_national
)
SELECT
    (moy_nucleaire + moy_eolien + moy_solaire + moy_hydraulique + moy_bioenergies) AS decarbone,
    (moy_gaz + moy_charbon + moy_fioul) AS carbone,
    ROUND(100.0 * (moy_nucleaire + moy_eolien + moy_solaire + moy_hydraulique + moy_bioenergies)
        / (moy_nucleaire + moy_eolien + moy_solaire + moy_hydraulique + moy_gaz + moy_charbon + moy_bioenergies + moy_fioul), 1) AS pct_decarbone,
    ROUND(100.0 * (moy_gaz + moy_charbon + moy_fioul)
        / (moy_nucleaire + moy_eolien + moy_solaire + moy_hydraulique + moy_gaz + moy_charbon + moy_bioenergies + moy_fioul), 1) AS pct_carbone
FROM moyennes;

-- 4. Évolution de la consommation dans le temps (par jour)

with production as (
	select 
	*,
	(nucleaire + eolien + solaire + hydraulique + gaz + charbon + bioenergies + fioul) as production_total
	from eco2mix_national
)
SELECT
    date,
    ROUND(AVG(consommation), 0) AS consommation_moyenne,
    ROUND(AVG(production_total), 0) as production_moyenne
FROM production
GROUP BY date
ORDER BY date;

-- 5. Production solaire et éolienne selon l'heure de la journée

SELECT
    heure,
    ROUND(AVG(solaire), 0) AS production_solaire,
    ROUND(AVG(eolien), 0) as production_eolien
FROM eco2mix_national
GROUP BY heure
ORDER BY heure;

-- 6. Échanges (imports/exports) avec les pays voisins

SELECT
    date,
    ROUND(AVG(ech_physiques ), 0) AS echange_physiques,
    ROUND(AVG(ech_comm_allemagne_belgique ), 0) as importation_allemagne_belgique,
    ROUND(AVG(ech_comm_angleterre  ), 0) as importation_angleterre,
    ROUND(AVG(ech_comm_espagne  ), 0) as importation_espagne,
    ROUND(AVG(ech_comm_italie  ), 0) as importation_italie,
    ROUND(AVG(ech_comm_suisse   ), 0) as importation_suisse
FROM eco2mix_national
GROUP BY date
ORDER BY date DESC;

-- 7 A. Détection d'anomalies (méthode IQR) sur la consommation

with quartile as (
	select
		percentile_cont(0.5) within group(order by consommation) as mediane,
		percentile_cont(0.25) within group(order by consommation) as Q1,
		percentile_cont(0.75) within group(order by consommation) as Q3
	from eco2mix_national
),
bornes as (
	select
		(Q1-(1.5*(Q3 - Q1))) as borne_basse,
		(Q3+(1.5*(Q3 - Q1))) as borne_haute
	from quartile
)
select 
	consommation, 
	date_heure
from eco2mix_national
cross join bornes
where consommation < borne_basse or consommation > borne_haute;

-- 7 A BIS. Coefficient de variation de la consommation

select 
	avg(consommation) as moyenne,
	stddev_pop(consommation) as ecart_type,
	(stddev_pop(consommation) / avg(consommation)) as coef_variation
from eco2mix_national;

-- 7 B. Détection d'anomalies (méthode IQR) sur l'éolien

with quartile as (
	select
		percentile_cont(0.5) within group(order by eolien ) as mediane,
		percentile_cont(0.25) within group(order by eolien) as Q1,
		percentile_cont(0.75) within group(order by eolien) as Q3
	from eco2mix_national
),
bornes as (
	select
		(Q1-(1.5*(Q3 - Q1))) as borne_basse,
		(Q3+(1.5*(Q3 - Q1))) as borne_haute
	from quartile
)
select 
	eolien, 
	date_heure
from eco2mix_national
cross join bornes
where eolien < borne_basse or eolien > borne_haute;

-- 7 B BIS. On verifie que tous les outliers sont bien au-dessus de la borne haute
WITH quartile AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY eolien) AS Q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY eolien) AS Q3
    FROM eco2mix_national
),
bornes AS (
    SELECT
        (Q1 - (1.5 * (Q3 - Q1))) AS borne_basse,
        (Q3 + (1.5 * (Q3 - Q1))) AS borne_haute
    FROM quartile
)
SELECT
    CASE
        WHEN eolien < borne_basse THEN 'outlier bas'
        WHEN eolien > borne_haute THEN 'outlier haut'
    END AS type_outlier,
    COUNT(*) AS nombre
FROM eco2mix_national
CROSS JOIN bornes
WHERE eolien < borne_basse OR eolien > borne_haute
GROUP BY type_outlier;

-- 7 B TER. Coefficient de variation de l'éolien 

select 
	avg(eolien) as moyenne,
	stddev_pop(eolien) as ecart_type,
	(stddev_pop(eolien) / avg(eolien)) as coef_variation
from eco2mix_national;

-- 8. Évolution du taux de CO2 dans le temps, comparé à l'usage des énergies carbonées

select 
	ROUND(AVG(taux_co2 ), 1) as rejet_co2,
	date,
	ROUND((AVG(charbon) + AVG(fioul) + AVG(gaz)), 1) as utilisation_energie_carbonne
from eco2mix_national emn 
group by date
order by date;
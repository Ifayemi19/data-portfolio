/* =====================================================================
   Leçon SQL 2 — Compter et calculer
   ---------------------------------------------------------------------
   Auteure  : Géneviève AMAGBEGNON
   Date     : 21/10/2026
   Base     : assurance_entrainement.db (SQLite, données fictives)
              - clients   : 200 clients (identité, ville, département)
              - contrats  : 339 contrats (type, dates, prime annuelle, statut)
              - sinistres : 260 sinistres (date, type, montants, statut)
   Notions  : COUNT, SUM, AVG, MIN, MAX, ROUND, alias (AS),
              GROUP BY, HAVING, calcul d'un taux
   Outil    : DB Browser for SQLite
   ===================================================================== */


/* ---------------------------------------------------------------------
   1. Compter des lignes : COUNT
   - COUNT(*)                : compte toutes les lignes
   - COUNT(colonne)          : ignore les valeurs NULL
   - COUNT(DISTINCT colonne) : compte les valeurs différentes
   --------------------------------------------------------------------- */

-- Question : combien l'assureur a-t-il de clients ?
SELECT COUNT(*) AS nb_clients      -- AS = alias : nom donné à la colonne du résultat
FROM clients;
-- Résultat : 200

-- Question : combien de contrats, de primes renseignées et de clients différents ?
SELECT COUNT(*)                  AS nb_lignes,
       COUNT(prime_annuelle)     AS nb_primes_renseignees,   -- ignore les NULL
       COUNT(DISTINCT id_client) AS nb_clients_differents    -- sans doublons
FROM contrats;
-- Résultat : 339 contrats, 324 primes renseignées (donc 15 manquantes), 200 clients

--  combien y a-t-il de sinistres au total ?
SELECT COUNT(*) AS nb_sinistres
FROM sinistres;

-- Résultat : 260


/* ---------------------------------------------------------------------
   2. Additionner, faire la moyenne, trouver les extrêmes
   SUM, AVG, MIN, MAX ignorent les valeurs NULL.
   ROUND(valeur, 2) arrondit à 2 décimales.
   --------------------------------------------------------------------- */

-- Question : quel est le total des primes, la prime moyenne, la plus petite et la plus grande ?
SELECT ROUND(SUM(prime_annuelle), 2) AS total_primes,
       ROUND(AVG(prime_annuelle), 2) AS prime_moyenne,
       MIN(prime_annuelle)           AS prime_min,
       MAX(prime_annuelle)           AS prime_max
FROM contrats;
-- Résultat : 232 156,49 € au total ; 716,53 € en moyenne ; de 150,49 € à 1 772,22 €

-- quel est le montant total et le montant moyen déclaré des sinistres clos ?
SELECT ROUND(SUM(montant_declare), 2) AS montant_total_sinistres,
       ROUND(AVG(montant_declare), 2) AS montant_moyen_sinistres
FROM sinistres
WHERE statut = 'Clos';


-- Résultat : montant_total_sinistres = 653519,88 et montant_moyen_sinistres = 4216,26


/* ---------------------------------------------------------------------
   3. Compter par catégorie : GROUP BY
   GROUP BY range les lignes en paquets (un par valeur),
   puis la fonction d'agrégation calcule sur chaque paquet.
   Règle d'or : toute colonne du SELECT qui n'est pas dans une
   fonction (COUNT, SUM...) doit être dans le GROUP BY.
   --------------------------------------------------------------------- */

-- Question : combien de contrats y a-t-il par type ?
SELECT type_contrat,
       COUNT(*) AS nb_contrats
FROM contrats
GROUP BY type_contrat              -- un paquet par type de contrat
ORDER BY nb_contrats DESC;         -- on peut trier sur l'alias
-- Résultat : Santé 88, Habitation 88, Prévoyance 83, Auto 80

-- combien y a-t-il de clients par ville, de la plus grande à la plus petite ?
SELECT ville,
       COUNT(*) AS nb_clients
FROM clients
GROUP BY ville
ORDER BY nb_clients DESC;

-- Résultat : 12 villes, avec Évry en tête (23 clients), puis Argenteuil (20), Paris et Nanterre (19). Cergy, Saint-Denis et Versailles ferment la marche avec 11 clients.


/* ---------------------------------------------------------------------
   4. Plusieurs indicateurs par catégorie (tableau de KPI)
   --------------------------------------------------------------------- */

-- Question : pour chaque type de contrat, quel nombre de contrats,
-- quel total de primes et quelle prime moyenne ?
SELECT type_contrat,
       COUNT(*)                      AS nb_contrats,
       ROUND(SUM(prime_annuelle), 2) AS total_primes,
       ROUND(AVG(prime_annuelle), 2) AS prime_moyenne
FROM contrats
GROUP BY type_contrat
ORDER BY total_primes DESC;
-- Résultat : Santé en tête (99 084,93 € ; moyenne 1 152,15 €),
--            Habitation dernière (moyenne 373,42 €)

-- pour chaque type de sinistre, quel nombre de sinistres
-- et quel montant moyen déclaré, du plus coûteux au moins coûteux ?
SELECT type_sinistre,
       COUNT(*) AS nb_sinistres,
	   ROUND(AVG(montant_declare), 2) AS montant_moyen
FROM sinistres
GROUP BY type_sinistre
ORDER BY montant_moyen DESC;

-- Résultat : Cambriolage en tête (19 sinistres, 5 465,96 € en moyenne), et Hospitalisation en dernier (3 638,61 €).


/* ---------------------------------------------------------------------
   5. Filtrer les groupes : HAVING
   WHERE  : filtre les LIGNES, avant le regroupement (pas de COUNT, SUM...)
   HAVING : filtre les GROUPES, après le regroupement (COUNT, SUM... autorisés)
   --------------------------------------------------------------------- */

-- Question : quelles villes comptent au moins 20 clients ?
SELECT ville,
       COUNT(*) AS nb_clients
FROM clients
GROUP BY ville
HAVING COUNT(*) >= 20              -- WHERE COUNT(*) >= 20 provoquerait une erreur
ORDER BY nb_clients DESC;
-- Résultat : Évry (23) et Argenteuil (20)

-- quels clients ont au moins 3 contrats ? Combien sont-ils ?
SELECT id_client,
       COUNT(*) AS nb_contrats
FROM contrats
GROUP BY id_client 
HAVING COUNT(*) >= 3
ORDER BY nb_contrats DESC; 

-- Résultat : 33 clients ont 3 contrats


/* ---------------------------------------------------------------------
   Bonus. Un KPI d'assurance : le taux de remboursement
   --------------------------------------------------------------------- */

-- Question : sur les sinistres clos, quelle part du montant déclaré a été remboursée ?
SELECT COUNT(*)                                                        AS nb_sinistres_clos,
       ROUND(SUM(montant_declare), 2)                                  AS total_declare,
       ROUND(SUM(montant_rembourse), 2)                                AS total_rembourse,
       ROUND(100.0 * SUM(montant_rembourse) / SUM(montant_declare), 1) AS taux_remboursement_pct
FROM sinistres
WHERE statut = 'Clos';
-- 100.0 et non 100 : une division entre entiers donnerait un entier (7 / 2 = 3)
-- Résultat : 155 sinistres clos ; taux de remboursement de 76,5 %


/* ---------------------------------------------------------------------
   À retenir : ordre d'écriture d'une requête
   SELECT → FROM → WHERE → GROUP BY → HAVING → ORDER BY → LIMIT
   --------------------------------------------------------------------- */

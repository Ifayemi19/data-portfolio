/* =====================================================================
   Leçon SQL 1 — Lire et filtrer une table
   ---------------------------------------------------------------------
   Auteure  : Géneviève AMAGBEGNON
   Date     : 20/10/2026
   Base     : assurance_entrainement.db (SQLite, données fictives)
              - clients   : 200 clients (identité, ville, département)
              - contrats  : 339 contrats (type, dates, prime annuelle, statut)
              - sinistres : 260 sinistres (date, type, montants, statut)
   Notions  : SELECT, FROM, WHERE, ORDER BY, LIMIT, DISTINCT,
              AND / OR / IN, BETWEEN, IS NULL / IS NOT NULL, COUNT
   Outil    : DB Browser for SQLite
   ===================================================================== */


/* ---------------------------------------------------------------------
   1. Découvrir une table : SELECT * ... LIMIT
   Réflexe : regarder quelques lignes avant toute analyse,
   pour connaître les colonnes et le format des données.
   --------------------------------------------------------------------- */

-- Question : à quoi ressemblent les 10 premiers clients ?
SELECT *                -- * = toutes les colonnes
FROM clients
LIMIT 10;               -- n'affiche que 10 lignes

-- Question : à quoi ressemblent les 5 premiers contrats ?
SELECT * FROM contrats LIMIT 5;

-- Question : à quoi ressemblent les 10 premiers sinistres ?
SELECT * FROM sinistres LIMIT 10;


/* ---------------------------------------------------------------------
   2. Choisir ses colonnes, filtrer (WHERE) et trier (ORDER BY)
   Ordre d'écriture : SELECT → FROM → WHERE → ORDER BY → LIMIT
   --------------------------------------------------------------------- */

-- Question : quels clients habitent le Val-d'Oise (95) ?
SELECT nom, prenom, ville
FROM clients
WHERE departement = '95'    -- texte entre apostrophes
ORDER BY nom;               -- tri alphabétique croissant (A → Z)
-- Résultat : 31 clients

-- Question : quelles sont les clientes, de la plus âgée à la plus jeune ?
SELECT nom, prenom, date_naissance
FROM clients
WHERE sexe = 'F'
ORDER BY date_naissance;    -- date la plus ancienne en premier
-- Attention : le nom exact de la colonne est date_naissance (sans espace)


/* ---------------------------------------------------------------------
   3. Supprimer les doublons : DISTINCT
   --------------------------------------------------------------------- */

-- Question : dans quelles villes avons-nous des clients ?
SELECT DISTINCT ville       -- chaque ville n'apparaît qu'une fois
FROM clients;
-- Résultat : 12 villes (au lieu de 200 lignes sans DISTINCT)

-- Question : quels types de contrats propose l'assureur ?
SELECT DISTINCT type_contrat
FROM contrats;
-- Résultat : Santé, Prévoyance, Auto, Habitation


/* ---------------------------------------------------------------------
   4. Le « top N » : filtrer → trier → limiter
   --------------------------------------------------------------------- */

-- Question : quels sont les 5 contrats Santé les plus chers ?
SELECT id_contrat, id_client, prime_annuelle
FROM contrats
WHERE type_contrat = 'Santé'
ORDER BY prime_annuelle DESC    -- DESC = du plus grand au plus petit
LIMIT 5;
-- Résultat : contrat n° 146 en tête (1 772,22 €)

-- Question : quels sont les 3 contrats Auto les moins chers ?
-- Version 1 (piège) : syntaxe correcte, mais résultat faux
SELECT id_contrat, id_client, prime_annuelle
FROM contrats
WHERE type_contrat = 'Auto'
ORDER BY prime_annuelle         -- sans DESC = tri croissant
LIMIT 3;
-- Problème constaté : les 3 lignes ont une prime NULL (manquante).
-- En SQLite, les NULL sont placés en premier dans un tri croissant.

-- Version 2 (corrigée) : on exclut les primes manquantes
SELECT id_contrat, id_client, prime_annuelle
FROM contrats
WHERE type_contrat = 'Auto'
  AND prime_annuelle IS NOT NULL    -- on garde seulement les primes renseignées
ORDER BY prime_annuelle
LIMIT 3;
-- Résultat : contrats n° 11 (376,48 €), 164 (402,81 €), 339 (427,53 €)
-- Leçon : une requête sans erreur n'est pas forcément juste → toujours vérifier le résultat.


/* ---------------------------------------------------------------------
   5. Combiner plusieurs conditions : AND, OR, IN, BETWEEN
   --------------------------------------------------------------------- */

-- Question : quels gros sinistres (> 5 000 €) ont été déclarés en 2025 ?
SELECT *
FROM sinistres
WHERE date_sinistre BETWEEN '2025-01-01' AND '2025-12-31'   -- intervalle, bornes comprises
  AND montant_declare > 5000                                -- AND : les 2 conditions vraies
ORDER BY montant_declare DESC;
-- Résultat : 26 sinistres

-- Question : quels sinistres sont des vols ou des cambriolages ?
-- Méthode 1 : OR (répéter le nom de la colonne à chaque fois)
SELECT *
FROM sinistres
WHERE type_sinistre = 'Vol'
   OR type_sinistre = 'Cambriolage';

-- Méthode 2 : IN (même résultat, plus court et plus lisible)
SELECT *
FROM sinistres
WHERE type_sinistre IN ('Vol', 'Cambriolage');
-- À retenir : BETWEEN = un intervalle ; IN = une liste de valeurs précises.


/* ---------------------------------------------------------------------
   Bonus. Contrôle qualité : repérer les valeurs manquantes
   --------------------------------------------------------------------- */

-- Question : combien de contrats n'ont pas de prime renseignée ?
SELECT COUNT(*)                 -- COUNT(*) compte les lignes
FROM contrats
WHERE prime_annuelle IS NULL;   -- on écrit IS NULL, jamais = NULL
-- Résultat : 15 contrats sans prime → anomalie à signaler

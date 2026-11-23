/* =====================================================================
   Leçon SQL 3 — Croiser les tables : les jointures (JOIN)
   ---------------------------------------------------------------------
   Auteure  : Géneviève AMAGBEGNON
   Date     : 17/11/2026
   Base     : assurance_entrainement.db (SQLite, données fictives)
              - clients   : 200 clients (identité, ville, département)
              - contrats  : 339 contrats (type, dates, prime annuelle, statut)
              - sinistres : 260 sinistres (date, type, montants, statut)
   Notions  : INNER JOIN, LEFT JOIN, ON, alias de tables,
              jointure sur 3 tables, jointure + GROUP BY,
              recherche des lignes sans correspondance (IS NULL)
   Outil    : DB Browser for SQLite
   ===================================================================== */


/* ---------------------------------------------------------------------
   Pourquoi des jointures ?
   Les informations sont réparties dans plusieurs tables, reliées
   par des identifiants communs (les « clés ») :

     clients.id_client   ←→  contrats.id_client
     contrats.id_contrat ←→  sinistres.id_contrat

   Une jointure recolle les tables le long de ces clés, pour répondre
   à des questions qui mélangent leurs informations
   (ex. : quelle ville déclare le plus de sinistres ?).
   --------------------------------------------------------------------- */


/* ---------------------------------------------------------------------
   1. Première jointure : INNER JOIN ... ON
   - INNER JOIN : garde uniquement les lignes qui ont une correspondance
     dans les deux tables.
   - ON : indique la condition de raccordement (la clé commune).
   - Alias de tables : co = contrats, cl = clients. On écrit ensuite
     co.colonne ou cl.colonne pour préciser de quelle table vient
     chaque colonne (obligatoire quand le nom existe dans les deux,
     comme id_client).
   --------------------------------------------------------------------- */

-- Question : quel client a souscrit chaque contrat ?
SELECT cl.nom,
       cl.prenom,
       co.type_contrat,
       co.prime_annuelle
FROM contrats AS co
INNER JOIN clients AS cl
        ON co.id_client = cl.id_client      -- la clé commune
LIMIT 10;
-- Résultat : Roux Lea (Santé, 1 662,37 €) en premier ;
--            Richard Ines apparaît 3 fois car elle a 3 contrats.
-- Point clé : une ligne par contrat, enrichie des informations du client.

-- Question : la jointure garde-t-elle bien tous les contrats ?
SELECT COUNT(*) AS nb_lignes
FROM contrats AS co
INNER JOIN clients AS cl
        ON co.id_client = cl.id_client;
-- Résultat : 339 → chaque contrat a trouvé son client, aucune perte.
-- Réflexe qualité : toujours compter les lignes après une jointure.


/* ---------------------------------------------------------------------
   2. Jointure + GROUP BY : des indicateurs par information d'une autre table
   La ville est dans clients, la prime dans contrats :
   il faut joindre avant de regrouper.
   --------------------------------------------------------------------- */

-- Question : quel est le nombre de contrats et le total des primes par ville ?
SELECT cl.ville,
       COUNT(*)                         AS nb_contrats,
       ROUND(SUM(co.prime_annuelle), 2) AS total_primes
FROM contrats AS co
INNER JOIN clients AS cl
        ON co.id_client = cl.id_client
GROUP BY cl.ville
ORDER BY total_primes DESC;
-- Résultat : Nanterre en tête (36 contrats ; 27 282,85 €),
--            alors qu'Évry a plus de contrats (42 ; 25 315,61 €).
-- Lecture métier : à Nanterre, les clients souscrivent des contrats plus chers.


/* ---------------------------------------------------------------------
   3. Joindre contrats et sinistres
   Le type de contrat est dans contrats, les montants dans sinistres.
   --------------------------------------------------------------------- */

-- Question : combien de sinistres et quel montant moyen déclaré par type de contrat ?
SELECT co.type_contrat,
       COUNT(*)                          AS nb_sinistres,
       ROUND(AVG(s.montant_declare), 2)  AS montant_moyen
FROM sinistres AS s
INNER JOIN contrats AS co
        ON s.id_contrat = co.id_contrat
GROUP BY co.type_contrat
ORDER BY nb_sinistres DESC;
-- Résultat : Santé 78 sinistres (4 271,13 €), Auto 67 (4 455,89 €),
--            Habitation 59 (4 744,78 €), Prévoyance 56 (4 379,45 €)
-- Lecture métier : la Santé génère le plus de sinistres,
--                  l'Habitation les plus coûteux en moyenne.


/* ---------------------------------------------------------------------
   4. Jointure sur 3 tables
   On enchaîne les JOIN, comme des maillons :
   sinistres → contrats (par id_contrat) → clients (par id_client)
   --------------------------------------------------------------------- */

-- Question : quelles villes déclarent le plus de sinistres, et pour quel montant ?
SELECT cl.ville,
       COUNT(*)                          AS nb_sinistres,
       ROUND(SUM(s.montant_declare), 2)  AS total_declare
FROM sinistres AS s
INNER JOIN contrats AS co
        ON s.id_contrat = co.id_contrat     -- maillon 1
INNER JOIN clients AS cl
        ON co.id_client = cl.id_client      -- maillon 2
GROUP BY cl.ville
ORDER BY nb_sinistres DESC;
-- Résultat : Évry en tête (30 sinistres ; 132 623,00 €),
--            Versailles dernière (9 sinistres ; 33 733,16 €)
-- Point clé : la table sinistres ne contient pas id_client ;
--             on passe obligatoirement par contrats pour atteindre clients.


/* ---------------------------------------------------------------------
   5. LEFT JOIN : garder aussi les lignes sans correspondance
   - INNER JOIN : seulement les lignes présentes des deux côtés.
   - LEFT JOIN  : toutes les lignes de la table de GAUCHE (celle du FROM),
                  même sans correspondance ; les colonnes de droite
                  valent alors NULL.

   Schéma :  INNER JOIN = intersection     LEFT JOIN = tout le gauche
   --------------------------------------------------------------------- */

-- Question : combien de lignes donne chaque type de jointure entre contrats et sinistres ?
SELECT COUNT(*) AS nb_lignes_inner
FROM contrats AS co
INNER JOIN sinistres AS s
        ON co.id_contrat = s.id_contrat;
-- Résultat : 260 → seulement les contrats qui ont au moins un sinistre

SELECT COUNT(*) AS nb_lignes_left
FROM contrats AS co
LEFT JOIN sinistres AS s
       ON co.id_contrat = s.id_contrat;
-- Résultat : 404 → les 260 lignes précédentes + 144 contrats sans sinistre

-- Question : combien de contrats n'ont jamais eu de sinistre ?
SELECT COUNT(*) AS nb_contrats_sans_sinistre
FROM contrats AS co
LEFT JOIN sinistres AS s
       ON co.id_contrat = s.id_contrat
WHERE s.id_sinistre IS NULL;               -- pas de correspondance = NULL
-- Résultat : 144 contrats
-- Point clé : LEFT JOIN + IS NULL est LA méthode pour trouver
--             « ce qui n'a pas de correspondance ». Très demandé en entretien.

-- Question : combien de lignes et de clients différents après la jointure ?
SELECT COUNT(*)                     AS nb_lignes,
       COUNT(DISTINCT cl.id_client) AS nb_clients
FROM contrats AS co
INNER JOIN clients AS cl
        ON co.id_client = cl.id_client;
-- Résultat : 339 lignes ; 200 clients


/* ---------------------------------------------------------------------
   Bonus. Combien de clients n'ont déclaré aucun sinistre ?
   On compte les clients DIFFÉRENTS qui ont au moins un sinistre,
   puis on déduit les autres.
   --------------------------------------------------------------------- */

-- Question : combien de clients ont déclaré au moins un sinistre ?
SELECT COUNT(DISTINCT cl.id_client) AS nb_clients_sinistres
FROM clients AS cl
INNER JOIN contrats AS co
        ON cl.id_client = co.id_client
INNER JOIN sinistres AS s
        ON co.id_contrat = s.id_contrat;
-- Résultat : 136 clients → donc 200 − 136 = 64 clients sans aucun sinistre
-- DISTINCT est indispensable : un client avec 3 sinistres
-- apparaît 3 fois après la jointure.


/* ---------------------------------------------------------------------
   À retenir
   - Toujours écrire la condition ON avec la clé commune.
   - Préfixer les colonnes par l'alias de leur table (cl., co., s.).
   - INNER JOIN : les correspondances seulement.
   - LEFT JOIN  : tout le côté gauche ; IS NULL repère les absences.
   - Après une jointure, compter les lignes pour vérifier le résultat.
   - Ordre : SELECT → FROM → JOIN ... ON → WHERE → GROUP BY → HAVING
             → ORDER BY → LIMIT
   --------------------------------------------------------------------- */

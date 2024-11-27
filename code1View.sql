-- Personne(NP, Nom, Adresse, CP, ville, pays, mail, phone)
-- Courrier(NC, libelle, texte, DateEnvoie)
-- Dons(ND, montant, DateDon, DateRecu, #NP, #NC)
-- Recevoir(#NP, #NC)


--1 Nombre de dons et montant total des dons pour chaque donateur sur l'année en cours.

    CREATE VIEW BilanAnneeEnCoursParDonnateur AS
    SELECT ND , count(*) AS nbDonsAnneeEnCours , sum(montant) AS sumMontantAnneeEnCours 
    FROM Dons 
    WHERE (EXTRACT('YEAR' from DateDon ) = EXTRACT('YEAR' FROM current_date) )
    GROUP BY ND ;

--2 Moyenne annuelle du nombre de dons et des montants pour chaque donateur.

    CREATE VIEW BilanAnnuelParDonnateur AS
    SELECT
        ND , 
        EXTRACT('YEAR' from DateDon ) AS anneeDon ,
        AVG(count(*)) AS moyenneDonsParAnnee ,
        AVG(sum(montant)) AS moyenneMontantParAnnee
    FROM 
        Dons 
    GROUP BY
        ND ,
        EXTRACT('YEAR' from DateDon )  ;

--3 le totale des dons effectue par personne

    CREATE VIEW total AS
    SELECT 
        D.ND, 
        count(*) AS nbDonstotal,
        SUM(D.montant) AS totalMontant,  
        B.moyenneDonsParAnnee,  
        B.moyenneMontantParAnnee, 
        BEC.nbDonsAnneeEnCours
    FROM 
        Dons D
    JOIN 
        BilanAnnuelParDonnateur B ON D.ND = B.ND
    JOIN 
        BilanAnneeEnCoursParDonnateur BEC ON D.ND = BEC.ND
    GROUP BY D.ND
   
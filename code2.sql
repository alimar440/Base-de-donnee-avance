-- Personne(#numPers, nomPers , prenomPers ,sexePers)
-- PereDe(#numPersEnfant , numPersPere)
-- MereDe(#numPersEnfant , numPersMere)

--1 Personnes avec au moins deux enfants ?

    SELECT prenomPers , nomPers
    FROM Personne P , PereDe 
    WHERE P.numPers = numPersPere
    GROUP BY numPersEnfant 
    HAVING count(numPersEnfant) > 2

--2 Les grandes-meres 

    SELECT 
        G.nomPers 
    FROM
        Personne G
    JOIN 
        MereDe M ON M.numPersMere = G.numPers 
    JOIN 
        MereDe M2 ON M.numPersEnfant = M2.numPersMere ;

--3 le Pere de Pape Diallo

    SELECT
        Per.nomPers 
    FROM
        Personne Per , PereDe P 
    WHERE 
        P.numPersPere = Per.numPers
         and
        P.numPersEnfant IN (SELECT 
                                numPers 
                            FROM 
                                Personne  
                            WHERE 
                                nomPers = "Diallo" &&  prenomPers = "Pape")
--4 les frere et soeurs uterins(ayant la meme mere) de Fatou ndiaye


--5 Les femmes avec le plus d'enfant  

    SELECT 
        nomPers ,
        prenomPers
    FROM
        Personne
    JOIN
        MereDe M ON M.numPersMere = numPers 
    GROUP BY
        numPersMere
    HAVING count(numPersEnfant) >= ALL (SELECT count(numPersEnfant) 
                                    FROM MereDe 
                                    GROUP BY numPersMere
                                    )


--6 les personnes sans enfant 

    SELECT
        nomPers ,
        prenomPers
    FROM
        Personne
    WHERE
        numPers NOT IN (
                        (SELECT numPersMere 
                        FROM MereDe )
                            UNION  
                        (SELECT numPersPere 
                        FROM PereDe) )


        



    

    

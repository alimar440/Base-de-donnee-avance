EXERCICE 1: 

  1) Creer une fonction simple permettant de convertir une temperatur de degres Fah-renheit en Celsius (F - 32)* 5/9 = C
	
   -en SQL 
   	
   	CREATE FUNCTION convertion (f float) RETURNS float 							-- float , numeric ,decimal											
   	AS $$
   		SELECT (f - 32 ) * (5/9) ;
   	$$ language SQL ;
   	
   -en PGSQL
   
   	CREATE FUNCTION convertion (f float) RETURNS float 
   	AS $$
   	DECLARE	
   	r float ;
   	begin 
   	
   		r:= (f - 32)*(5.0 /9.0) ;
   		return r 
   	end
   	$$ language  ’PGSQL ’ ;
  
  2)fonction inverse qui inverse une chaine a l aide d une boucle while et des fonctions char_length et substring(chaine from start for length ) {comme en js , recuper une parti un chaine )
  
  	CREATE FUNCTION inverse (s text ) RETURNS text 
  	AS $$
	   	DECLARE	
	   	  
	   	  res text = '' ;
	   	BEGIN
	   		long := char_length(s) ;   
	   		WHILE(long !- 0 ) loop 
		   		res = res || char_substring(s from start long for 1 ) ;			(OU BIEN  concat (res , char_substring(s from start long for 1 ) )
		   		long := long -1 ;
		   	END loop;
		   	
		   	RETURN res ;
		END ;
		
	$$ language  ’PGSQL ’;
	



 EXERCICE 2 :
 
   Bibiotheque.Oeuvres( ISBN , titre , Editeur , Auteur  ,   primary key(ISB) ) ;
   Bibiotheque.Tarifs(NbEmpruntsAutorises ( >0 ) , caution ( > 0) , primary key(id)) ;
   Bibiotheque.Adherents(Id  primary key(Id) , Nom , Prenom , NbEmpruntsAutorises ( referencing  Bibiotheque.Tarifs.NbEmpruntsAutorises)) ;
    
   1) a) DF declarer de Bibiotheque.Adherents  Id->> Nom , Prenom , NbEmpruntsAutorises 
      b) la cle etrangere permet d eviter d attribut une NbEmpruntsAutorises á Bibiotheque.Adherents qui n est pas dans  Bibiotheque.Tarifs
      
   2)
   		
   	Bibiotheque.Livre(d primary key(Id) , ISBN  foreign key(ISBN) , DateAchat );
   	a) DF declarer de Bibiotheque.Adherents  Id->> ISBN , DateAchat 
        b) la cle etrangere permet d eviter d attribut un ISBN á Bibiotheque.Livre qui n est pas dans Bibiotheque.Oeuvres
        
   3) Bibiotheque.Emprunt(Livre  foreign key ,  dateEmprunt primary key(Livre , dateEmprunt ) , dateRetour , Adherent   foreign key , UNIQUE (Libre , DateRetour) );
   	
   	a) DF declarer de Bibiotheque.Emprunt    
   		(Livre , DateRetour )  ->> dateEmprunt , Adherent ; 
   		(Livre , dateEmprunt )  ->> dateRetour , Adherent ; 
        b) la cle etrangere (Adherent et Livre ) permettent d eviter d attribut un livre á un Adherent qui est dans  Bibiotheque.Emprunt 
        	--Adherent 
        	    assure que l adherent dans Bibiotheque.Emprunt existe Bibiotheque.Adherents
        	 --Livre
         	    assure que le Livre dans Bibiotheque.Emprunt existe Bibiotheque.Livre
        c) la contrainte UNIQUE(livre , DateRetour) 
   		impossibilite de multiple emprunt d un livre á la meme date         (dateRetour = dateEmprunt + x) 
   	d) l objectif des deux containte d integrite (les 2 check)
   		
   		CHECK (dateRetour > dateEmprunt) ->> cette contrainte assure que la dateEmprunt soit inferieur a la dateRetour . 
   		
   		CHECK(Bibiotheque.DateEmpruntRetourCorrect(livre , dateEmprunt , dateRetour )    --Permet d'empecher le chevauchement  entre les dateEmprunt et dateRetour
   							    $1		$2	     $3
   		
   		exemple:  	DE			DR
   				|------------------------|
   			$2		$3
   			|----------------|  X
   				   $2				      $3
   				   |----------------------------------|  X
   
   				   				$2	    $3
   				   				|------------|  autoriser 
   				   				
   pour qu ´il est pas chevauchement:
   	
   		New.dateDebut > dateFin
   	ou	
   		New.dateFin < dateDebut 
   		
   		 
   			
   4) Objectif des 2 contrainte
   	
      a)FUNCTION Bibliotheque.DatesEmpruntAchatConnections (integer, date)
   	
   	Create FUNCTION Bibliotheque.DatesEmpruntAchatConnections (integer, date)
   	RETURNS boolean AS $$ 
   	SELECT EXISTS(
   		SELECT *
   		FROM Bibliotheque.Livres
   		WHERE ($1 = Id AND $2 > DateAchat ) )
   	$$ language ’SQL’; 
   	
   	ALTER TABLE Bibliotheque.Emprunts ADD CONSTRAINT DateEmpruntAchatPossibles
   	CHECK (Bibliotheque.DatesEmpruntAchatConnections(livre , DateEmprunt) = TRUE ) ;
   	
   	
   	--Reponse
   		cette contraint garantit que la DateEmprunt d un livre soit superieur á la DateAchat
   	
      b)FUNCTION Bibliotheque.NombreEmpruntCorrect (integer, date)
        
        Create FUNCTION Bibliotheque.NombreEmpruntCorrect (integer, date)
   	RETURNS boolean AS $$ 
   	SELECT NOT EXISTS (
   		SELECT Adherent
   		FROM Bibliotheque.Emprunts , Bibliotheque.Adherents
   		WHERE ($1 = Adherent AND $1 = Id )
   		AND ($2 >= DateEmprunt AND $2 <= DateRetour )
   		GROUP BY (count(*) >= NbEmpruntAutorises )) 
   	$$ language ’SQL’; 
   	
      
   	ALTER TABLE Bibliotheque.Emprunts ADD CONSTRAINT NombreEmpruntCorrect
   	CHECK (Bibliotheque.NombreEmpruntCorrect(Adherent , DateEmprunt) = TRUE ) ;
   			
   	--Reponse
   		cette contraint garantit que le nombre de livre emprunter par l´ adherent de ne depasse pas le nombre de livre autorisé 
   	
   5) Requete SQL qui caracterise les identifiants , noms , prenom des adherent en retard(á la date du jour  ,current_date ) pour un emprunt  . duree emprunt = 30 jours 	 	
   			
   			
   	SELECT Id , Nom  Prenom	
   	FROM Adherent am Emprunt e
   	WHERE a.Id = c.Adherent 
   	AND DateRetour = infinity 			-- dateRetour > current_date
   	AND current_date > DateEmprunt + 30 ;
   	
   6) Requete SQL qui liste les identifiants , noms , prenom des adherents qui , á la date du jour , ont la possibilité d´ emprunter
   			
   	SELECT Id , Nom , Prenom
   	FROM Adherent a 
   	LEFT JOIN (select Adherent ,count(*) as nb from Emprunts WHERE current_date >= e.DateEmprunt AND current_date < e.DateRetour group by Adherent) as Tab 
   	ON a.Id = Tab.adherent
   	WHERE COALESCE(Tab.nb ,0 )< nbEmpruntAupriser ;
   	
   7) 
   	CREATE VIEW OeuvresLues AS 
   	SELECT ISBN , Adherent 
   	FROM Lives l , Emprunt e 
   	WHERE l.Id = e.livre 
   	
   8) Livreas lues par tous les adherents
   	SELECT ISBN
   	FROM Oeuvres O
   	WHERE NOT EXISTS (SELECT Id FROM Adherents WHERE (O.ISBN , Id) NOT IN (SELECT * FROM OeuvresLues ))
     ou bien :
     	
     	SELECT ISBN
   	FROM Oeuvres O
   	WHERE (SELECT Adherent FROM OeuvreLues ) CONTAINS (SELECT Id FROM Adherent )	
 	
 
 
EXERCICE 3:
	
   1) 	
   	create function Horaire(timestamp , timestamp)
   	return bool as $$ 
   		select $2 - $1 >0 AND extract(epoch from ($2 - $1)) < 7200
   	$$language 'sql' ;	
   4) 
   	CREATE VIEW listeCasse AS
   	SELECT caisser
   	FROM Caille C1 
   	WHERE NOT EXISTS(SELECT numCaisse 
   			 FROM Caisse 
   			 WHERE numCaisse NOT IN (SELECT numCaisse 
   			 			 FROM Caisse C2 
   			 			 WHERE C2.numCaisse = C1.numCaisse)
   			 			 
   
EXERCICE 4: 

   1) Creation de la base de donnée 
   	   			
	  
	CREATE TABLE Matiere (
	    idm INT PRIMARY KEY,
	    intitule VARCHAR(50),
	    nbs INT
	);

	
	CREATE TABLE Intervenant (
	    idi INT PRIMARY KEY,
	    nom VARCHAR(50),
	    prenom VARCHAR(50),
	    statut CHAR(1) CHECK (statut IN ('V', 'P'))
	);

	
	CREATE TABLE Etudiant (
	    id INT PRIMARY KEY,
	    nom VARCHAR(50),
	    prenom VARCHAR(50),
	    groupe VARCHAR(5)
	);

	
	CREATE TABLE Salle (
	    nos VARCHAR(5) PRIMARY KEY,
	    typs INT, CHECK (typs IN (1 , 2)),
	    contenance INT
	);

	

	CREATE TABLE Cours (
	    idm INT,
	    nums INT,
	    ide INT,
	    nos VARCHAR(5),
	    groupe VARCHAR(5),
	    dates DATE,
	    phor VARCHAR(2) CHECK (phor IN ('AM', 'PM')),
	    PRIMARY KEY (idm, nums, ide, nos, groupe, dates, phor),
	    FOREIGN KEY (idm) REFERENCES Matiere(idm),
	    FOREIGN KEY (nums) REFERENCES Intervenant(idi),
	    FOREIGN KEY (nos) REFERENCES Salle(nos)
	);

	


	CREATE TABLE Evaluation (
	    idm INT,
	    ide INT,
	    note INT,
	    PRIMARY KEY (idm, ide),
	    FOREIGN KEY (idm) REFERENCES Matiere(idm),
	    FOREIGN KEY (ide) REFERENCES Etudiant(id)
	);
	
	ALTER TABLE Salle
	ADD CONSTRAINT typs_constaint CHECK (typs IN ( 1 , 2));		
	
   2)Definition d´une relation moyenne
   
   	CREATE VIEW relation_moyenne AS
	Select s.groupe ,  s.idm, AVG(E.note)
	FROM cours s
	JOIN Evaluation E on s.idm = E.idm 
	group by s.groupe ,  s.idm

	select * from relation_moyenne
   			
   3) 
   
   	CREATE TABLE Seance (
	    nums INT,
	    dateSeance date,
	    nos VARCHAR(5) ,
	    PRIMARY KEY (nums) ,
	    FOREIGN KEY (nos) REFERENCES Salle(nos)
	);
	
	ALTER TABLE Cours
	ADD CONSTRAINT fr_seance  FOREIGN KEY (nums) REFERENCES Seance(nums);
	
	ALTER TABLE Cours
	DELETE nos ;	
   	
   	
   	
   	
   	
   	
   5) 
   
   	create or replace function is_group_exist() returns trigger as
	declare
		 v_du Adherent.du%TYPE;
		 v_nb_emprunts integer;
		 v_sorti Livre.sorti%TYPE;
		 begin
		 select count(*) into v_du
		 from Etudiant E
		 where E.groupe =  NEW.groupe;
		 
		 if v_du <> 0 then
		 	raise notice ’L adherent doit %’, v_du;
			return null;
		 end if;
	end;
	$$ language plpgsql;
	 
	create trigger ajout_cours 
	before inserton table Cours
	for each row
	execute procedure ajout_emprunt ();

   	
   	
EXERCICE 5: 
 
 --1 creation des tables 
 
 CREATE TABLE Departements (
    nomDept VARCHAR(50),
    localisation VARCHAR(50),
    PRIMARY KEY (nomDept, localisation)
);

CREATE TABLE Employes (
    idEmp INT PRIMARY KEY,
    nom VARCHAR(50)
);

CREATE TABLE Travaille (
    employe INT,
    dept VARCHAR(50),
    localisation VARCHAR(50),
    pourcentage INT CHECK (pourcentage >= 0 AND pourcentage <= 100),
    PRIMARY KEY (employe, dept, localisation),
    FOREIGN KEY (employe) REFERENCES Employes(idEmp),
    FOREIGN KEY (dept, localisation) REFERENCES Departements(nomDept, localisation)
);

--2 assertion pour eviter de travailler 100%

 CREATE ASSERTION check_pourcentage_total
CHECK (
    NOT EXISTS (
        SELECT employe
        FROM Travaille
        GROUP BY employe
        HAVING SUM(pourcentage) > 100
    )
);
--3 trigger 

CREATE OR REPLACE FUNCTION verifier_pourcentage_travail()
RETURNS TRIGGER AS $$
DECLARE
    total_pourcentage INT;
    surplus INT;
BEGIN
     SELECT COALESCE(SUM(pourcentage), 0)
    INTO total_pourcentage
    FROM Travaille
    WHERE employe = NEW.employe;

-- SELECT SUM(pourcentage)
--INTO total_pourcentage
--FROM Travaille
--WHERE employe = NEW.employe;


--IF total_pourcentage IS NULL THEN
 --   total_pourcentage := 0;
--END IF;
*/
    IF (total_pourcentage + NEW.pourcentage) > 100 THEN
        surplus := 100 - total_pourcentage;
        
        IF surplus > 0 THEN
             NEW.pourcentage := surplus;
        ELSE
            RAISE EXCEPTION 'Impossible d''ajouter : l''employé a déjà 100%% de son temps attribué.';
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Création du trigger
CREATE TRIGGER trigger_verifier_pourcentage
BEFORE INSERT OR UPDATE ON Travaille
FOR EACH ROW
EXECUTE FUNCTION verifier_pourcentage_travail();

--4 

SELECT DISTINCT e.nom
FROM Employes e
WHERE e.idEmp IN (
    SELECT t1.employe
    FROM Travaille t1
    WHERE t1.dept = 'vente' AND t1.localisation = 'Dakar'
      AND EXISTS (
          SELECT 1
          FROM Travaille t2
          WHERE t2.employe = t1.employe
            AND (t2.dept != 'vente' OR t2.localisation != 'Dakar')
      )
);

--5


Exercice 7

-- 1. Fonction pour compter le nombre d'employés embauchés une année donnée
CREATE OR REPLACE FUNCTION nombre_embauches_par_annee(annee INT)
RETURNS INT AS $$
DECLARE
    nb_embauches INT;
BEGIN
    SELECT COUNT(*) INTO nb_embauches
    FROM employes
    WHERE EXTRACT(YEAR FROM date_embauche) = annee;
    RETURN nb_embauches;
END;
$$ LANGUAGE plpgsql;

-- 2. Utilisation de generate_series() pour lister les embauches entre 2000 et 2020
SELECT annee, nombre_embauches_par_annee(annee) AS nb_embauches
FROM generate_series(2000, 2020) AS annee;

-- 3. Fonction avec boucle FOR - LOOP pour retourner les embauches entre deux années
CREATE OR REPLACE FUNCTION embauches_entre_annees(d INT, f INT)
RETURNS TABLE(annee INT, nb_embauches INT) AS $$
BEGIN
    FOR annee IN d..f LOOP
        nb_embauches := nombre_embauches_par_annee(annee);
        RETURN NEXT;
    END LOOP;
    RETURN;
END;
$$ LANGUAGE plpgsql;

-- 4. Fonction pour retourner le nom du département d'un employé
CREATE OR REPLACE FUNCTION departement_employe(matricule_employe INT)
RETURNS VARCHAR AS $$
DECLARE
    nom_departement VARCHAR;
BEGIN
    SELECT s.nom_service INTO nom_departement
    FROM employes e
    JOIN services s ON e.num_service = s.num_service
    WHERE e.matricule = matricule_employe;
    RETURN nom_departement;
END;
$$ LANGUAGE plpgsql;

-- 5. Fonction pour retourner les collègues d'un employé (même département)
CREATE OR REPLACE FUNCTION collegues(matricule_employe INT)
RETURNS TABLE(nom VARCHAR, prenom VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT e.nom, e.prenom
    FROM employes e
    JOIN services s ON e.num_service = s.num_service
    WHERE s.num_service = (SELECT num_service FROM employes WHERE matricule = matricule_employe)
    AND e.matricule != matricule_employe;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION collegues(matricule_employe INT)
RETURNS TABLE(nom VARCHAR, prenom VARCHAR) AS $$
WITH departement_employe AS (
    SELECT num_service
    FROM employes
    WHERE matricule = matricule_employe
)
SELECT e.nom, e.prenom
FROM employes e
JOIN departement_employe de ON e.num_service = de.num_service
WHERE e.matricule != matricule_employe;
$$ LANGUAGE sql;


EXERCICE 8 : 


 
   	
   	
   	
   	
   	
   	
   	  
   	  
   	  
   	
   	
   	
   	
   	
   	
   	
   	
   	
   	
   	
   	
   	
   	

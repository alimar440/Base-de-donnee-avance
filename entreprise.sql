CREATE TABLE departements (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    budget NUMERIC(15, 2) NOT NULL,
    parent_id INT REFERENCES departements(id)
);

CREATE TABLE employes (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    prenom VARCHAR(255) NOT NULL,
    fonction VARCHAR(255) NOT NULL,
    date_embauche DATE NOT NULL,
    salaire NUMERIC(15, 2) NOT NULL,
    departement_id INT REFERENCES departements(id),
    manager_id INT REFERENCES employes(id)
);

CREATE TABLE projets (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    budget NUMERIC(15, 2) NOT NULL,
    duree INT NOT NULL,
    departement_id INT REFERENCES departements(id)
);

CREATE TABLE participation (
    employe_id INT REFERENCES employes(id),
    projet_id INT REFERENCES projets(id),
    heures_travaillees NUMERIC(10, 2) NOT NULL,
    PRIMARY KEY (employe_id, projet_id)
);

CREATE TABLE evaluations (
    id SERIAL PRIMARY KEY,
    employe_id INT REFERENCES employes(id),
    date_evaluation DATE NOT NULL,
    score NUMERIC(5, 2) CHECK (score >= 0 AND score <= 100),
    commentaires TEXT
);

CREATE TABLE log (
    id SERIAL PRIMARY KEY,
    nom_table VARCHAR(255) NOT NULL,
    operation VARCHAR(50) NOT NULL,
    date_modification TIMESTAMP NOT NULL DEFAULT NOW()
);


--2. Ajouter des contraintes 
--○ Empêchez les dates d’embauche futures dans la table employes. 
    ALTER TABLE employes ADD CONSTRAINT CHECK (date_embauche <= current_date)
--○ Assurez que le budget d’un projet ne dépasse pas celui de son département. 
create function BudgetConstraint( budget1 numeric , departement_id integer )
returns bool AS 
$$
	return not exists (SELECT *  
	FROM departements
	WHERE  id = departement_id  and budget < budget1)

$$ language SQL	
	
ALTER TABLE projets ADD CONSTRAINT const1 CHECK ( BudgetConstraint(budget , departement_id ) = TRUE ) ;

--○ Limitez chaque employé à trois projets actifs au maximum. 
create or replace function projetsConstraint( employe_id integer )
returns bool AS 
$$
    select not exists (SELECT  employe_id
	FROM participation
	WHERE  employe_id = $1  
    GROUP BY employe_id
    HAVING count(*) > 3)

$$ language SQL	

ALTER TABLE participation ADD CONSTRAINT const3 CHECK ( projetsConstraint(employe_id) = TRUE ) ;

--○ Assurez qu’aucun département ne dépasse un budget total de 10 millions. 
ALTER TABLE departements ADD CONSTRAINT const4 CHECK ( budget <= 10000000) ;
--○ Interdisez les scores d’évaluation hors de la plage 0-100. 
ALTER TABLE evaluations ADD CONSTRAINT const4 CHECK ( score >= 0  and score<=100) ;

--Partie 2 : Triggers 

--1. Créer un trigger de journalisation automatique 
--Implémentez un trigger qui insère une entrée dans la table log à chaque 
--modification (INSERT, UPDATE ou DELETE) des tables employes, departements et 
--projets. 

CREATE OR REPLACE FUNCTION OperationLogTrigger()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO log (nom_table, date_modification)
    VALUES (TG_TABLE_NAME, 'INSERT', current_timestamp);   
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO log (nom_table, date_modification)
    VALUES (TG_TABLE_NAME, 'INSERT', current_timestamp);   
  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO log (nom_table, date_modification)
    VALUES (TG_TABLE_NAME, 'INSERT', current_timestamp);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER InsertLogTriggerCompany
AFTER INSERT ON participation
FOR EACH ROW
EXECUTE FUNCTION OperationLogTrigger();

CREATE TRIGGER UPDATELogTriggerCompany
AFTER UPDATE ON participation
FOR EACH ROW
EXECUTE FUNCTION OperationLogTrigger();

CREATE TRIGGER DELETELogTriggerCompany
AFTER DELETE ON participation
FOR EACH ROW
EXECUTE FUNCTION OperationLogTrigger();



--2. Créer un trigger pour valider les salaires 


--○ Interdisez toute réduction de salaire sans autorisation explicite. 
CREATE OR REPLACE FUNCTION reductionSalaireTrigger()
RETURNS TRIGGER AS $$
DECLARE 
monSalaire integer;
BEGIN
    select salaire into monSalaire
    FROM employes 
    WHERE employe_id = NEW.employee_id ;
    IF NEW.salaire < monSalaire THEN            -- IF NEW.salaire < OLD.salaire THEN
        return NULL ;
    END IF ;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER UPDATELogTriggerCompany
BEFORE UPDATE ON employes
FOR EACH ROW
EXECUTE FUNCTION reductionSalaireTrigger();


--○ Empêchez qu’un employé gagne plus que ses collègues du même 
--département occupant la même fonction.

CREATE OR REPLACE FUNCTION maxSalaireTrigger()
RETURNS TRIGGER AS $$
DECLARE 
maxSalaire integer;
BEGIN
    select max(salaire ) into maxSalaire
    FROM employes
    WHERE departement_id = NEW.departement_id AND fonction = NEW.fonction ;

    IF maxSalaire < NEW.maxSalaire THEN
      RETURN NULL;
    END IF ;

    RETURN NEW ; 
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER InsertLogTriggerCompany
BEFORE INSERT ON employes
FOR EACH ROW
EXECUTE FUNCTION maxSalaireTrigger();



CREATE OR REPLACE FUNCTION maxSalaireTrigger()
RETURNS TRIGGER AS $$
DECLARE 
maxSalaire integer;
BEGIN
    select max(salaire ) into maxSalaire
    FROM employes
    WHERE departement_id = NEW.departement_id AND fonction = NEW.fonction ;

    IF maxSalaire < NEW.maxSalaire THEN
    	 RETURN NULL;
	END IF ;
    RETURN NEW ; 
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER InsertLogTriggerCompany
AFTER INSERT ON employes
FOR EACH ROW
EXECUTE FUNCTION maxSalaireTrigger();

--3. Créer un trigger de mise à jour automatique 
--○ Ajustez automatiquement le budget d’un département lorsqu’un projet y est 
--ajouté ou supprimé. 
CREATE OR REPLACE FUNCTION updateBudget()
RETURNS TRIGGER AS $$
DECLARE 
totalBudget numeric;
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE departements
        SET budget = budget + NEW.budget
        WHERE id = NEW.departement_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE departements
        SET budget = budget - OLD.budget
        WHERE id = OLD.departement_id;
    END IF;
END
$$LANGUAGE plpgsql ;

CREATE TRIGGER InserteBudgetTrigger
AFTER INSERT ON projets
FOR EACH ROW
EXECUTE FUNCTION updateBudget();



CREATE TRIGGER DELETEBudgetTrigger
AFTER DELETE ON projets
FOR EACH ROW
EXECUTE FUNCTION updateBudget();

--○ Assurez-vous qu’aucun projet ne dépasse une durée de 5 ans.
CREATE OR REPLACE FUNCTION controleDureProjet()
RETURNS TRIGGER AS $$
DECLARE 
BEGIN
    IF NEW.duree > 5 THEN
        RAISE EXCEPTION 'Duree > 5ans';
    END IF;
    RETURN NEW;
END
$$LANGUAGE plpgsql ;

CREATE TRIGGER InsertControleDureeTrigger
BEFORE INSERT ON evaluations
FOR EACH ROW
EXECUTE FUNCTION controleDureProjet();



--4. Créer un trigger pour valider les évaluations

--Empêchez qu’un employé puisse déclarer plus de 60 heures par semaine sur 
--l’ensemble des projets auxquels il participe. 

CREATE OR REPLACE FUNCTION InsertControleHeureTravail()
RETURNS TRIGGER AS $$
DECLARE 
totalHeures integer;
BEGIN
    SELECT employe_id , SUM(heures_travaillees) INTO totalHeures
    FROM participation
    WHEN NEW.id = employe_id 
    GROUP BY employe_id;

    IF totalHeures > 60 THEN
        RAISE EXCEPTION 'Heures > 60';
    END IF ;
    RETURN NEW ;
END 
LANGUAGE 'plpgsql' ;

CREATE TRIGGER InsertControleHeureTrigger
AFTER INSERT ON participation
FOR EACH ROW
EXECUTE FUNCTION InsertControleHeureTravail();


--Partie 3 : Fonctions 
--1. Afficher la hiérarchie d’un département 

--Créez une fonction qui retourne tous les sous-départements d’un département 
--donné.

CREATE OR REPLACE FUNCTION lesSousDepartement(id_parent integer)
RETURNS TABLE(id integer, nom VARCHAR ) AS $$
BEGIN
    RETURN QUERY 
    SELECT d.id, d.nom
    FROM departements d
    WHERE parent_id = $1;
END;
$$ LANGUAGE 'plpgsql';

SELECT * FROM lesSousDepartement(13);
SELECT * FROM departements;
OU BIEN:

CREATE OR REPLACE FUNCTION lesSousDepartement2(id_parent integer)
RETURNS SETOF departements AS $$
DECLARE
Dep departements;
BEGIN
    	FOR Dep IN (SELECT * FROM departements WHERE parent_id = $1) LOOP
         RETURN NEXT Dep;
        END LOOP;
        --RETURN;
END;
$$ LANGUAGE 'plpgsql';
--test
SELECT * FROM lesSousDepartement2(13);



--2. Calculer la masse salariale d’un département 
--Écrivez une fonction qui calcule la masse salariale totale d’un département, y 
--compris les employés des sous-départements.



CREATE OR REPLACE FUNCTION masseSalarialeDepartement(id_departement integer)
RETURNS NUMERIC AS $$
DECLARE 
    total_salaire NUMERIC;
BEGIN
    
    SELECT SUM(salaire) INTO total_salaire
    FROM employes e
    WHERE e.departement_id IN (SELECT id_departement FROM departements id_departement   WHERE id = $1
                                UNION SELECT id_departement FROM departements id_departement   WHERE parentid = $1)

    RETURN total_salaire;
END;
LANGUAGE plpgsql ;



ou bien 

CREATE OR REPLACE FUNCTION masseSalarialeDepartement(id_departement integer)
RETURNS NUMERIC AS $$
DECLARE
    total_salaire NUMERIC;
BEGIN
    WITH RECURSIVE sous_departements AS (
        SELECT id
        FROM departements
        WHERE id = id_departement 

        UNION ALL

        SELECT d.id
        FROM departements d
        INNER JOIN sous_departements sd ON d.parent_id = sd.id
    )
   
    SELECT COALESCE(SUM(e.salaire), 0) INTO total_salaire
    FROM employes e
    WHERE e.departement_id IN (SELECT id FROM sous_departements);

    RETURN total_salaire;
END;
$$ LANGUAGE plpgsql;

select masseSalarialeDepartement(00) ;
SELECT * FROM departements
--3. Attribuer des primes aux employés 
--Attribuez une prime à un employé en fonction de : 

    --○ Une performance moyenne supérieure à 80. 
    CREATE OR REPLACE FUNCTION AttribuerPrime(salaire integer ) 
    RETURNS void AS $$
    DECLARE 
        performance_moyenne INTEGER;
    BEGIN
        SELECT employe_id , AVG(score) INTO performance_moyenne
        FROM evaluations
        GROUP BY employe_id  ;

        IF performance_moyenne > 80 THEN
            UPDATE employes
            SET salaire = salaire + $1 ;
		END IF;
    END;
   $$ LANGUAGE plpgsql;

SELECT * FROM AttribuerPrime(100000) ;
    --○ Le nombre de projets terminés par l’employé. 

--○ Une ancienneté supérieure à 5 ans.
CREATE OR REPLACE FUNCTION BestEmployeByAnciennete2()
RETURNS TABLE(nom VARCHAR , prenom VARCHAR) AS $$
BEGIN
    RETURN QUERY 
    SELECT e.nom , e.prenom
    FROM employes e
    WHERE date_embauche < CURRENT_DATE - INTERVAL '5 years';
END;
$$ LANGUAGE plpgsql;

--test
SELECT * from bestemployebyanciennete2() ;

##4. Analyser les projets 
--Créez une fonction qui retourne pour chaque projet : 
    --○ Le total des heures travaillées. 
        CREATE OR REPLACE FUNCTION TotalHeuresTravaillees1()
        RETURNS TABLE(projet_id integer, total_heures NUMERIC) AS $$
        BEGIN
            RETURN QUERY
            SELECT  e.projet_id , SUM(heures_travaillees)
            FROM participation e
            GROUP BY e.projet_id;
        END;
        $$ LANGUAGE plpgsql;

        --test 
        SELECT * FROM TotalHeuresTravaillees1() ;


    --○ Le budget restant. 
    CREATE OR REPLACE FUNCTION BudgetProjetRestant()
    RETURNS TABLE(departement_id integer , budgetRestant NUMERIC) AS $$
    BEGAN 
        RETURN QUERY
        SELECT 
        FROM 
    END ;
    $$ LANGUAGE PLPGSQL ;

    --○ La liste des meilleurs employés participant au projet.
    CREATE OR REPLACE FUNCTION BestEmployeProjet()
    RETURNS TABLE(projet_id integer, nom VARCHAR, prenom VARCHAR) AS $$
    BEGIN
        RETURN QUERY
        SELECT p.projet_id, e.nom, e.prenom
        FROM participation p
        JOIN employes e ON e.id = p.employe_id
        WHERE p.heures_travaillees = (SELECT MAX(heures_travaillees) FROM participation);
    END;
    $$ LANGUAGE plpgsql;

     SELECT * FROM bestemployeprojet();

--5. Lister les employés proches de la retraite 
    --Créez une fonction qui identifie les employés à moins de 2 ans de l’âge de la 
    --retraite, en supposant un âge de retraite de 60 ans.
--6. Analyser les performances d’un département 
    --Créez une fonction qui retourne le score moyen des employés d’un département 
    --donné sur une période définie. 
    CREATE OR REPLACE FUNCTION ScoreMoyenDepartement(id_departement integer, date_debut DATE, date_fin DATE)
    RETURNS NUMERIC AS $$
    BEGIN
        RETURN AVG(e.score) 
        FROM evaluations e
        JOIN employes emp ON e.employe_id = emp.id
        WHERE emp.departement_id = id_departement
        AND e.date_evaluation BETWEEN date_debut AND date_fin;    
    END;
    $$ LANGUAGE plpgsql;

    --test
    SELECT ScoreMoyenDepartement(13, '2023-10-10', '2023-12-16');

##7. Analyser les promotions internes 
    --Implémentez une fonction qui retourne le pourcentage d’employés ayant été 
    --promus au sein de leur département.
    
###Partie 4 : Vues 
##1. Vue des performances des employés 
--Créez une vue qui affiche pour chaque employé : 
    --○ Son département. 
    CREATE OR REPLACE VIEW departementEmploye AS
    SELECT e.nom , e.prenom , d.nom as departement
    FROM employes e
    JOIN departements d ON e.departement_id = d.id;
    --test 
    SELECT * FROM departementemploye ;


    --○ Sa performance moyenne.
    CREATE OR REPLACE VIEW VuePerformancesEmployes AS
    SELECT e.id AS employe_id, e.nom,  e.prenom,  AVG(ev.score) AS score_moyen
    FROM employes e
    JOIN evaluations ev ON e.id = ev.employe_id
    GROUP BY e.id, e.nom, e.prenom;

    --test 
    SELECT * FROM VuePerformancesEmployes ;
   
    
    --○ Le nombre de projets auxquels il a participé.
    CREATE OR REPLACE VIEW vueNombreProjet AS 

##2. Vue des budgets des départements 
--Élaborez une vue qui montre pour chaque département : 
    --○ Le budget initial. 
○ Le budget utilisé. 
○ Le pourcentage d’économies ou de dépassement.
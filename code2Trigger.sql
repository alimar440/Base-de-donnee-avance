
--Une contrainte qui affecte le nombre d'enfants a la capacite d'un lieu ( en gros un lieu doit contenir qu'un nombre d'enfants equivalent a sa capacite)


CREATE TRIGGER IsAffectationFull 
BEFORE INSERT ON Affectation 
WHEN (
    EXISTS (SELECT * 
            FROM 
                Sejour S
            WHERE 
                capacite < =(SELECT 
                                COUNT(*)
                            FROM 
                                Affectation
                            WHERE 
                                lieu =S.lieu
                            AND 
                                semaine = S.semaine

                            ) 
                )
            )
    )
THEN FOR EACH ROW 
ABORT ;

ou bien 

CREATE OR REPLACE FUNCTION check_affectation_capacity()
RETURNS TRIGGER AS $$
DECLARE
    nbAffectation INT;
    nbCapacity INT;
BEGIN
    -- Count the current number of affectations for the given location and week
    SELECT COUNT(*) INTO nbAffectation
    FROM Affectation
    WHERE lieu = NEW.lieu AND semaine = NEW.semaine;
    
    -- Get the capacity of the location for the given week
    SELECT capacite INTO nbCapacity
    FROM Sejour
    WHERE lieu = NEW.lieu AND semaine = NEW.semaine;
    
    -- Check if adding this new affectation would exceed the capacity
    IF nbAffectation >= nbCapacity THEN
        RAISE EXCEPTION 'Affectation capacity exceeded for lieu: %, semaine: %', NEW.lieu, NEW.semaine;
    END IF;
    
    RETURN NEW; -- Allow the insert if capacity is not exceeded
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER IsAffectationFull
BEFORE INSERT ON Affectation
FOR EACH ROW
EXECUTE FUNCTION check_affectation_capacity();

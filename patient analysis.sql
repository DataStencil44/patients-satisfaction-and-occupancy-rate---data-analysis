DROP TABLE IF EXISTS patient;

SET datestyle = 'ISO, DMY';

CREATE TABLE patient(
    patient_id SERIAL PRIMARY KEY,
	patient_unique_id VARCHAR(150),
    age INTEGER,
    arrival_date DATE,
    departure_date DATE,
    service VARCHAR(150),
    satisfaction INTEGER
);

DROP TABLE IF EXISTS services_weekly;
CREATE TABLE services_weekly(
	last_date_of_week DATE,
	service VARCHAR(150),
	available_beds INTEGER,
	patients_request INTEGER,
	patients_admitted INTEGER,
	patients_refused INTEGER,
	patient_satisfaction INTEGER,
	staff_morale INTEGER,
	event_ VARCHAR(150)
);

SELECT COUNT(*) FROM patient;
SELECT * FROM patient;

--avg patient age
SELECT AVG(age) 
FROM patient;

-- longest duration
SELECT *
FROM patient
ORDER BY (departure_date - arrival_date) DESC
LIMIT 10;

 -- duration and age
SELECT 
    CASE 
        WHEN age BETWEEN 0 AND 17 THEN '< 18'
        WHEN age BETWEEN 18 AND 29 THEN '18-29'
        WHEN age BETWEEN 30 AND 44 THEN '30-44'
        WHEN age BETWEEN 45 AND 59 THEN '45-59'
        WHEN age >= 60 THEN '60+'
    END AS age_category,

    AVG(departure_date - arrival_date) AS avg_duration,
    AVG(satisfaction) AS avg_satisfaction

FROM patient
GROUP BY age_category
ORDER BY age_category;

-- age cathegory and ssatisfaction
SELECT 
    CASE 
        WHEN age < 18 THEN 'Under 18'
        WHEN age BETWEEN 18 AND 29 THEN '18-29'
        WHEN age BETWEEN 30 AND 44 THEN '30-44'
        WHEN age BETWEEN 45 AND 59 THEN '45-59'
        WHEN age >= 60 THEN '60+'
    END AS age_category,
    AVG(satisfaction) AS avg_satisfaction
FROM patient
GROUP BY age_category
ORDER BY age_category;

-- service and duration
SELECT service, AVG(EXTRACT(DAY FROM departure_date::timestamp - arrival_date::timestamp)) AS duration
FROM patient 
GROUP BY service;

-- service and satisfaction
SELECT service, AVG(satisfaction)
FROM patient
GROUP BY service;

-- avg available beds
SELECT 
service,
AVG(available_beds)
FROM services_weekly
GROUP BY service;

-- refusal rate per service
SELECT service,
SUM(patients_refused) * 100.0 / SUM(patients_request) AS refusal_rate
FROM services_weekly
GROUP BY service
ORDER BY refusal_rate DESC;

-- staff_morale and satisfaction of patients
SELECT 
    CASE 
        WHEN staff_morale < 19 THEN '< 20'
        WHEN staff_morale BETWEEN 20 AND 39 THEN '20 - 39'
        WHEN staff_morale BETWEEN 40 AND 59 THEN '40 - 59'
        WHEN staff_morale BETWEEN 60 AND 79 THEN '60 - 79'
        WHEN staff_morale >= 80 THEN '80 - 100'
    END AS staff_morale_category,
    AVG(patient_satisfaction) AS avg_patient_satisfaction
	
FROM services_weekly 
GROUP BY staff_morale_category
ORDER BY staff_morale_category;

-- average requests per event
SELECT event_,
AVG(patients_request) AS avg_patients_request,
AVG(patients_refused) AS avg_patients_refused,
AVG(patient_satisfaction) AS avg_patient_satisfaction
FROM services_weekly
GROUP BY event_;

-- Bed occupancy rate
SELECT last_date_of_week, service, patients_admitted, available_beds, 
ROUND(patients_admitted::numeric / available_beds, 2) AS occupancy_rate
FROM services_weekly
ORDER BY last_date_of_week DESC;

--Overcrowding and service and event
SELECT last_date_of_week, service, patients_request, available_beds, event_, patients_request - available_beds AS shortage
FROM services_weekly
WHERE patients_request > available_beds
ORDER BY shortage DESC;

-- Recomended amount of beds
SELECT service,
    event_,
    EXTRACT(MONTH FROM last_date_of_week) AS month,
    ROUND(AVG(patients_request), 2) AS mean_demand,
    ROUND(COALESCE(STDDEV(patients_request), 0), 2) AS std_demand,
    ROUND(
        AVG(patients_request) + 
        2 * COALESCE(STDDEV(patients_request), 0), 2) AS recommended_beds,
    ROUND(
        (AVG(patients_request) * 100 / NULLIF(AVG(patients_request) + 2 * COALESCE(STDDEV(patients_request), 0), 0)), 2) AS recommended_beds_percentage
FROM services_weekly
GROUP BY service, event_, month
ORDER BY service, month;
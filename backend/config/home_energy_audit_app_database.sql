CREATE DATABASE IF NOT EXISTS home_energy_audit_app_database;
USE home_energy_audit_app_database;

CREATE TABLE IF NOT EXISTS LeakageTask (
    taskID VARCHAR(64) PRIMARY KEY,
    userID VARCHAR(64) NOT NULL,
    title VARCHAR(255),
    type ENUM('window', 'door', 'wall'),
    state ENUM('open', 'closed', 'draft'),
    decision ENUM('no_decision', 'archived', 'todo') DEFAULT 'no_decision',
    closedResult VARCHAR(255),
    insideTemp FLOAT,
    outsideTemp FLOAT,
    RGBphotoIDs JSON,
    thermalPhotoIDs JSON,
    leakSeverity VARCHAR(255),
    energyLossValue FLOAT,
    energyLossCost FLOAT,
    savingsPercent FLOAT,
    savingsCost FLOAT,
    reportPhotoID VARCHAR(64),
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS Suggestion (
    suggestionID VARCHAR(64) PRIMARY KEY,
    taskID VARCHAR(64),
    title VARCHAR(255),
    subtitle VARCHAR(255),
    difficulty VARCHAR(255),
    costRange VARCHAR(255),
    estimatedReduction VARCHAR(255),
    lifetime VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS UserData (
    userID VARCHAR(64) PRIMARY KEY,
    zipCode VARCHAR(16),
    energyCompany VARCHAR(255),
    retrofitBudget VARCHAR(255),
    ownership VARCHAR(100),
    appliances JSON,
    suggestedBudget FLOAT,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

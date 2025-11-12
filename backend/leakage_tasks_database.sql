CREATE DATABASE IF NOT EXISTS leakage_tasks_database;
USE leakage_tasks_database;

CREATE TABLE LeakageTask (
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

CREATE TABLE Suggestion (
    suggestionID VARCHAR(64) PRIMARY KEY,
    taskID VARCHAR(64),
    title VARCHAR(255),
    subtitle VARCHAR(255),
    difficulty VARCHAR(255),
    costRange VARCHAR(255),
    estimatedReduction VARCHAR(255),
    lifetime VARCHAR(255)
);
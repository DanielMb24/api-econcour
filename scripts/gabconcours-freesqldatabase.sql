-- Compatible FreeSQLDatabase / anciennes versions MySQL
-- Emails limites a VARCHAR(191) pour les index utf8mb4.
-- Un seul TIMESTAMP automatique maximum par table; les autres dates automatiques deviennent DATETIME NULL.
-- Les colonnes JSON sont stockees en LONGTEXT et les collations MySQL 8 sont remplacees.
-- Aucun TRIGGER ni routine stockee : ces privileges sont interdits sur FreeSQLDatabase.
-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Hôte : 127.0.0.1:3306
-- Généré le : sam. 13 juin 2026 à 01:14
-- Version du serveur : 8.4.7
-- Version de PHP : 8.3.28

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET FOREIGN_KEY_CHECKS = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `gabconcours`
--

-- --------------------------------------------------------

--
-- Structure de la table `administrateurs`
--

DROP TABLE IF EXISTS `administrateurs`;
CREATE TABLE IF NOT EXISTS `administrateurs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nom` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `prenom` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `role` enum('super_admin','admin_etablissement','sub_admin') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'admin_etablissement',
  `admin_role` enum('notes','documents') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `etablissement_id` int DEFAULT NULL,
  `statut` enum('actif','inactif','suspendu') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'actif',
  `derniere_connexion` timestamp NULL DEFAULT NULL,
  `password_reset_token` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `password_reset_expires` timestamp NULL DEFAULT NULL,
  `created_by` int DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  KEY `etablissement_id` (`etablissement_id`),
  KEY `created_by` (`created_by`),
  KEY `idx_email` (`email`),
  KEY `idx_role` (`role`),
  KEY `idx_statut` (`statut`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `administrateurs`
--

INSERT INTO `administrateurs` (`id`, `nom`, `prenom`, `email`, `password`, `role`, `admin_role`, `etablissement_id`, `statut`, `derniere_connexion`, `password_reset_token`, `password_reset_expires`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 'Super', 'Admin', 'supadmin@gabconcours.ga', '$2b$12$LfrNmfUfuOR8FKNNlDUx9e0oMmt1RmoEmRGPOReavmIkaa3wM6QfC', 'super_admin', NULL, NULL, 'actif', '2026-06-13 00:45:46', NULL, NULL, NULL, '2025-11-07 18:22:00', '2026-06-13 00:45:46'),
(7, 'makosso', 'daniel', 'mb.daniel241@gmail.com', '$2b$12$9GqzvSqVb6ETEp0hC/5DWeC.QIZ4nI/p3YaCqrUfBjUokSUt5FScK', 'admin_etablissement', NULL, 1, 'actif', '2026-06-12 23:50:28', NULL, NULL, 1, '2026-06-12 23:49:01', '2026-06-12 23:50:28');

-- --------------------------------------------------------

--
-- Structure de la table `admin_actions`
--

DROP TABLE IF EXISTS `admin_actions`;
CREATE TABLE IF NOT EXISTS `admin_actions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `admin_id` int NOT NULL,
  `action_type` enum('validation_document','rejet_document','ajout_note','reponse_message','creation_admin','modification_concours','autre') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `entity_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Type d entité (document, note, message, etc.)',
  `entity_id` int DEFAULT NULL COMMENT 'ID de l entité concernée',
  `candidat_nupcan` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'NUPCAN du candidat concerné',
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `details` longtext DEFAULT NULL COMMENT 'Détails supplémentaires en JSON',
  `ip_address` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_admin` (`admin_id`),
  KEY `idx_action_type` (`action_type`),
  KEY `idx_candidat` (`candidat_nupcan`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `admin_logs`
--

DROP TABLE IF EXISTS `admin_logs`;
CREATE TABLE IF NOT EXISTS `admin_logs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `admin_id` int NOT NULL,
  `action` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `table_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `record_id` int DEFAULT NULL,
  `old_values` longtext DEFAULT NULL,
  `new_values` longtext DEFAULT NULL,
  `ip_address` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `user_agent` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `admin_id` (`admin_id`),
  KEY `table_name` (`table_name`),
  KEY `created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `candidats`
--

DROP TABLE IF EXISTS `candidats`;
CREATE TABLE IF NOT EXISTS `candidats` (
  `id` int NOT NULL AUTO_INCREMENT,
  `niveau_id` int DEFAULT NULL,
  `concours_id` int DEFAULT NULL,
  `filiere_id` int DEFAULT NULL,
  `nipcan` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nupcan` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `nomcan` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `prncan` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `maican` varchar(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `dtncan` date DEFAULT NULL,
  `telcan` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ldncan` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phtcan` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `proorg` int DEFAULT NULL,
  `proact` int DEFAULT NULL,
  `proaff` int DEFAULT NULL,
  `statut` enum('en_attente','valide','rejete') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'en_attente',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `nupcan` (`nupcan`),
  KEY `niveau_id` (`niveau_id`),
  KEY `idx_nipcan` (`nipcan`),
  KEY `idx_nupcan` (`nupcan`),
  KEY `idx_concours` (`concours_id`),
  KEY `idx_statut` (`statut`),
  KEY `idx_candidats_concours_statut` (`concours_id`,`statut`),
  KEY `idx_filiere` (`filiere_id`),
  KEY `idx_created` (`created_at`),
  KEY `idx_candidat_statut` (`statut`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `candidats`
--

INSERT INTO `candidats` (`id`, `niveau_id`, `concours_id`, `filiere_id`, `nipcan`, `nupcan`, `nomcan`, `prncan`, `maican`, `dtncan`, `telcan`, `ldncan`, `phtcan`, `proorg`, `proact`, `proaff`, `statut`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 1, 'NIP2026000004', '20260613-2', 'makosso', 'daniel', 'daniel@gmail.com', '2004-01-24', '+24101234569', 'port-gentil', 'photo-1781311615752-553525202.png', 1, 1, 3, 'en_attente', '2026-06-13 00:46:55', '2026-06-13 00:46:55');

-- --------------------------------------------------------

--
-- Structure de la table `concours`
--

DROP TABLE IF EXISTS `concours`;
CREATE TABLE IF NOT EXISTS `concours` (
  `id` int NOT NULL AUTO_INCREMENT,
  `etablissement_id` int DEFAULT NULL,
  `niveau_id` int DEFAULT NULL,
  `libcnc` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Nom du concours',
  `fracnc` decimal(10,2) DEFAULT '0.00' COMMENT 'Frais d''inscription',
  `agecnc` int DEFAULT NULL COMMENT 'Age maximum pour participer',
  `sescnc` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Session du concours (ex: 2025/2026)',
  `debcnc` date DEFAULT NULL COMMENT 'Date de début des inscriptions',
  `fincnc` date DEFAULT NULL COMMENT 'Date de fin des inscriptions',
  `stacnc` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '1' COMMENT 'Statut (1=Ouvert, 0=Fermé)',
  `is_gorri` tinyint(1) DEFAULT '0' COMMENT 'Statut Gorri (1=Gratuit, 0=Payant)',
  `etddos` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT '0' COMMENT 'État du dossier (ex: 0=non validé, 1=validé)',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_etablissement` (`etablissement_id`),
  KEY `idx_niveau` (`niveau_id`),
  KEY `idx_statut` (`stacnc`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Liste des concours ouverts';

--
-- Déchargement des données de la table `concours`
--

INSERT INTO `concours` (`id`, `etablissement_id`, `niveau_id`, `libcnc`, `fracnc`, `agecnc`, `sescnc`, `debcnc`, `fincnc`, `stacnc`, `is_gorri`, `etddos`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 'concours d\'entrée à BBS', 20000.00, 25, '2025-2026', '2025-11-07', '2025-12-07', '1', 0, '0', '2025-11-07 18:24:22', '2025-11-07 18:31:44');

-- --------------------------------------------------------

--
-- Structure de la table `concours_filieres`
--

DROP TABLE IF EXISTS `concours_filieres`;
CREATE TABLE IF NOT EXISTS `concours_filieres` (
  `id` int NOT NULL AUTO_INCREMENT,
  `concours_id` int NOT NULL,
  `filiere_id` int NOT NULL,
  `places_disponibles` int DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_concours_filiere` (`concours_id`,`filiere_id`),
  KEY `filiere_id` (`filiere_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `concours_filieres`
--

INSERT INTO `concours_filieres` (`id`, `concours_id`, `filiere_id`, `places_disponibles`, `created_at`, `updated_at`) VALUES
(3, 1, 1, 100, '2025-11-07 18:27:36', '2025-11-07 18:27:36');

-- --------------------------------------------------------

--
-- Structure de la table `documents`
--

DROP TABLE IF EXISTS `documents`;
CREATE TABLE IF NOT EXISTS `documents` (
  `id` int NOT NULL AUTO_INCREMENT,
  `candidat_id` int DEFAULT NULL,
  `concours_id` int DEFAULT NULL,
  `nomdoc` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `nom_fichier` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `chemin_fichier` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `statut` enum('en_attente','valide','rejete') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'en_attente',
  `commentaire_validation` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `validated_by` int DEFAULT NULL,
  `validated_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `concours_id` (`concours_id`),
  KEY `idx_candidat` (`candidat_id`),
  KEY `idx_statut` (`statut`),
  KEY `idx_documents_candidat_statut` (`candidat_id`,`statut`),
  KEY `idx_document_statut` (`statut`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `documents`
--

INSERT INTO `documents` (`id`, `candidat_id`, `concours_id`, `nomdoc`, `type`, `nom_fichier`, `chemin_fichier`, `statut`, `commentaire_validation`, `validated_by`, `validated_at`, `created_at`, `updated_at`) VALUES
(1, NULL, NULL, 'Acte de naissance', 'pdf', '1781312028718-746329538.pdf', NULL, 'en_attente', NULL, NULL, NULL, '2026-06-13 00:53:48', '2026-06-13 00:53:48');

-- --------------------------------------------------------

--
-- Structure de la table `dossiers`
--

DROP TABLE IF EXISTS `dossiers`;
CREATE TABLE IF NOT EXISTS `dossiers` (
  `id` int NOT NULL AUTO_INCREMENT,
  `candidat_id` int DEFAULT NULL,
  `concours_id` int DEFAULT NULL,
  `document_id` int DEFAULT NULL,
  `nupcan` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `docdsr` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `concours_id` (`concours_id`),
  KEY `document_id` (`document_id`),
  KEY `idx_candidat_id` (`candidat_id`),
  KEY `idx_nipcan` (`nupcan`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `dossiers`
--

INSERT INTO `dossiers` (`id`, `candidat_id`, `concours_id`, `document_id`, `nupcan`, `docdsr`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 1, '20260613-2', 'uploads\\documents\\1781312028718-746329538.pdf', '2026-06-13 00:53:48', '2026-06-13 00:53:48');

-- --------------------------------------------------------

--
-- Structure de la table `etablissements`
--

DROP TABLE IF EXISTS `etablissements`;
CREATE TABLE IF NOT EXISTS `etablissements` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nomets` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `adretes` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `telefs` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `maiets` varchar(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `photo` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `province_id` int DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_province` (`province_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `etablissements`
--

INSERT INTO `etablissements` (`id`, `nomets`, `adretes`, `telefs`, `maiets`, `photo`, `province_id`, `created_at`, `updated_at`) VALUES
(1, 'BBS', 'Libreville, Gabon', '074604327', 'danimb241@gmail.com', '', 1, '2025-11-07 18:23:06', '2025-11-07 18:23:37');

-- --------------------------------------------------------

--
-- Structure de la table `filieres`
--

DROP TABLE IF EXISTS `filieres`;
CREATE TABLE IF NOT EXISTS `filieres` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nomfil` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `niveau_id` int DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_niveau` (`niveau_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `filieres`
--

INSERT INTO `filieres` (`id`, `nomfil`, `description`, `niveau_id`, `created_at`, `updated_at`) VALUES
(1, 'Droit', 'Sciences juridiques', 1, '2025-11-07 18:25:31', '2025-11-07 18:25:31');

-- --------------------------------------------------------

--
-- Structure de la table `filiere_matieres`
--

DROP TABLE IF EXISTS `filiere_matieres`;
CREATE TABLE IF NOT EXISTS `filiere_matieres` (
  `id` int NOT NULL AUTO_INCREMENT,
  `filiere_id` int NOT NULL,
  `matiere_id` int NOT NULL,
  `coefficient` decimal(3,1) NOT NULL DEFAULT '1.0',
  `obligatoire` tinyint(1) DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_filiere_matiere` (`filiere_id`,`matiere_id`),
  KEY `matiere_id` (`matiere_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `filiere_matieres`
--

INSERT INTO `filiere_matieres` (`id`, `filiere_id`, `matiere_id`, `coefficient`, `obligatoire`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 3.0, 1, '2025-11-07 18:27:01', '2025-11-07 18:27:01');

-- --------------------------------------------------------

--
-- Structure de la table `matieres`
--

DROP TABLE IF EXISTS `matieres`;
CREATE TABLE IF NOT EXISTS `matieres` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nom_matiere` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `coefficient` decimal(3,1) DEFAULT NULL,
  `duree` int DEFAULT NULL COMMENT 'Durée en heures',
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `matieres`
--

INSERT INTO `matieres` (`id`, `nom_matiere`, `coefficient`, `duree`, `description`, `created_at`, `updated_at`) VALUES
(1, 'Anglais', 3.0, NULL, NULL, '2025-11-07 18:26:33', '2025-11-07 18:26:33');

-- --------------------------------------------------------

--
-- Structure de la table `messages`
--

DROP TABLE IF EXISTS `messages`;
CREATE TABLE IF NOT EXISTS `messages` (
  `id` int NOT NULL AUTO_INCREMENT,
  `candidat_nupcan` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `admin_id` int DEFAULT NULL,
  `sujet` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `message` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `expediteur` enum('candidat','admin') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `statut` enum('lu','non_lu') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'non_lu',
  `parent_id` int DEFAULT NULL COMMENT 'Pour les réponses',
  `parent_message_id` int DEFAULT NULL COMMENT 'Référence utilisée par la messagerie temps réel',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `candidat_nupcan` (`candidat_nupcan`),
  KEY `admin_id` (`admin_id`),
  KEY `parent_id` (`parent_id`),
  KEY `parent_message_id` (`parent_message_id`),
  KEY `statut` (`statut`),
  KEY `idx_message_statut_expediteur` (`statut`,`expediteur`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `messages`
--

INSERT INTO `messages` (`id`, `candidat_nupcan`, `admin_id`, `sujet`, `message`, `expediteur`, `statut`, `parent_id`, `created_at`, `updated_at`) VALUES
(1, '20251107-1', NULL, 'Documents', 'Je n\'arrive pas à televerser mes documents rejetés', 'candidat', 'non_lu', NULL, '2025-11-07 19:42:55', '2025-11-07 19:42:55');

-- --------------------------------------------------------

--
-- Structure de la table `nipcan_counters`
--

DROP TABLE IF EXISTS `nipcan_counters`;
CREATE TABLE IF NOT EXISTS `nipcan_counters` (
  `id` int NOT NULL AUTO_INCREMENT,
  `year` int NOT NULL,
  `counter` int NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `year` (`year`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `nipcan_counters`
--

INSERT INTO `nipcan_counters` (`id`, `year`, `counter`, `created_at`, `updated_at`) VALUES
(1, 2026, 4, '2026-04-02 23:35:21', '2026-06-13 00:46:55');

-- --------------------------------------------------------

--
-- Structure de la table `niveaux`
--

DROP TABLE IF EXISTS `niveaux`;
CREATE TABLE IF NOT EXISTS `niveaux` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nomniv` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `niveaux`
--

INSERT INTO `niveaux` (`id`, `nomniv`, `description`, `created_at`, `updated_at`) VALUES
(1, 'Licence 1', 'Première année de licence', '2025-10-05 06:14:48', '2025-10-05 06:14:48'),
(2, 'Licence 2', 'Deuxième année de licence', '2025-10-05 06:14:48', '2025-10-05 06:14:48'),
(3, 'Licence 3', 'Troisième année de licence', '2025-10-05 06:14:48', '2025-10-05 06:14:48'),
(4, 'Master 1', 'Première année de master', '2025-10-05 06:14:48', '2025-10-05 06:14:48'),
(5, 'Master 2', 'Deuxième année de master', '2025-10-05 06:14:48', '2025-10-05 06:14:48'),
(6, 'Doctorat', 'Études doctorales', '2025-10-05 06:14:48', '2025-10-05 06:14:48'),
(7, 'Terminale C', 'Terminale série C (Mathématiques et Sciences Physiques)', '2025-10-05 06:14:48', '2025-10-05 06:14:48'),
(8, 'Terminale D', 'Terminale série D (Mathématiques et Sciences de la Nature)', '2025-10-05 06:14:48', '2025-10-05 06:14:48'),
(9, 'Terminale A', 'Terminale série A (Littéraire)', '2025-10-05 06:14:48', '2025-10-05 06:14:48'),
(10, 'BTS', 'Brevet de Technicien Supérieur', '2025-10-05 06:14:48', '2025-10-05 06:14:48');

-- --------------------------------------------------------

--
-- Structure de la table `notes`
--

DROP TABLE IF EXISTS `notes`;
CREATE TABLE IF NOT EXISTS `notes` (
  `id` int NOT NULL AUTO_INCREMENT,
  `candidat_id` int NOT NULL,
  `concours_id` int NOT NULL,
  `matiere_id` int NOT NULL,
  `note` decimal(5,2) NOT NULL,
  `coefficient` decimal(3,1) DEFAULT '1.0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_note` (`candidat_id`,`concours_id`,`matiere_id`),
  KEY `idx_candidat` (`candidat_id`),
  KEY `idx_concours` (`concours_id`),
  KEY `idx_matiere` (`matiere_id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `notes`
--

INSERT INTO `notes` (`id`, `candidat_id`, `concours_id`, `matiere_id`, `note`, `coefficient`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 1, 15.00, 3.0, '2025-11-07 19:41:19', '2025-11-07 19:41:19');

-- --------------------------------------------------------

--
-- Structure de la table `notifications`
--

DROP TABLE IF EXISTS `notifications`;
CREATE TABLE IF NOT EXISTS `notifications` (
  `id` int NOT NULL AUTO_INCREMENT,
  `candidat_nupcan` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `candidat_id` int DEFAULT NULL,
  `type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `titre` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `message` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `reference_id` int DEFAULT NULL,
  `reference_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `statut` enum('lu','non_lu') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'non_lu',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NULL DEFAULT NULL,
  `priority` enum('low','normal','high') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'normal',
  PRIMARY KEY (`id`),
  KEY `idx_nupcan` (`candidat_nupcan`),
  KEY `idx_statut` (`statut`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_notifications_date` (`candidat_nupcan`,`created_at`),
  KEY `idx_candidat` (`candidat_id`),
  KEY `idx_reference` (`reference_type`,`reference_id`)
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `notifications`
--

INSERT INTO `notifications` (`id`, `candidat_nupcan`, `candidat_id`, `type`, `titre`, `message`, `reference_id`, `reference_type`, `statut`, `created_at`, `updated_at`, `priority`) VALUES
(1, '20251107-1', NULL, 'document_validation', 'Document rejeté', 'Votre document \"doc2.jpg\" a été rejeté.', NULL, NULL, 'non_lu', '2025-11-07 19:30:46', '2025-11-07 19:30:46', 'high'),
(2, '20251107-1', NULL, 'document_validation', 'Document rejeté', 'Votre document \"doc2.jpg\" a été rejeté. Motif: Mauvais document veuillez remplacer ce document', NULL, NULL, 'non_lu', '2025-11-07 19:30:46', '2025-11-07 19:30:46', 'normal'),
(3, '20251107-1', NULL, 'document_validation', 'Document validé', 'Votre document \"doc2.jpg\" a été validé.', NULL, NULL, 'non_lu', '2025-11-07 19:32:13', '2025-11-07 19:32:13', 'normal'),
(4, '20251107-1', NULL, 'document_validation', 'Document validé', 'Votre document \"doc2.jpg\" a été validé avec succès.', NULL, NULL, 'non_lu', '2025-11-07 19:32:13', '2025-11-07 19:32:13', 'normal'),
(5, '20251107-1', NULL, 'document_validation', 'Document validé', 'Votre document \"doc1.pdf\" a été validé.', NULL, NULL, 'non_lu', '2025-11-07 19:32:17', '2025-11-07 19:32:17', 'normal'),
(6, '20251107-1', NULL, 'document_validation', 'Document validé', 'Votre document \"doc1.pdf\" a été validé avec succès.', NULL, NULL, 'non_lu', '2025-11-07 19:32:17', '2025-11-07 19:32:17', 'normal'),
(7, '20251107-1', NULL, 'document_validation', 'Document validé', 'Votre document \"doc1.pdf\" a été validé avec succès.', NULL, NULL, 'non_lu', '2025-11-07 19:32:20', '2025-11-07 19:32:20', 'normal'),
(8, '20251107-1', NULL, 'document_validation', 'Document validé', 'Votre document \"doc1.pdf\" a été validé avec succès.', NULL, NULL, 'non_lu', '2025-11-07 19:32:26', '2025-11-07 19:32:26', 'normal'),
(9, '20251107-1', NULL, 'document_validation', 'Document validé', 'Votre document \"doc4.png\" a été validé.', NULL, NULL, 'non_lu', '2025-11-07 19:32:29', '2025-11-07 19:32:29', 'normal'),
(10, '20251107-1', NULL, 'document_validation', 'Document validé', 'Votre document \"doc4.png\" a été validé avec succès.', NULL, NULL, 'non_lu', '2025-11-07 19:32:29', '2025-11-07 19:32:29', 'normal'),
(11, '20251107-1', NULL, 'document_validation', 'Document validé', 'Votre document \"doc1.pdf\" a été validé avec succès.', NULL, NULL, 'non_lu', '2025-11-07 19:32:36', '2025-11-07 19:32:36', 'normal'),
(12, '20251107-1', NULL, 'document_validation', 'Document validé', 'Votre document \"doc1.pdf\" a été validé avec succès.', NULL, NULL, 'non_lu', '2025-11-07 19:32:57', '2025-11-07 19:32:57', 'normal'),
(13, '20251107-1', NULL, 'document_validation', 'Document validé', 'Votre document \"doc1.pdf\" a été validé avec succès.', NULL, NULL, 'non_lu', '2025-11-07 19:34:34', '2025-11-07 19:34:34', 'normal'),
(14, '20251107-1', NULL, 'document_validation', 'Document validé', 'Votre document \"doc3.jpg\" a été validé.', NULL, NULL, 'non_lu', '2025-11-07 19:34:38', '2025-11-07 19:34:38', 'normal'),
(15, '20251107-1', NULL, 'document_validation', 'Document validé', 'Votre document \"doc3.jpg\" a été validé avec succès.', NULL, NULL, 'non_lu', '2025-11-07 19:34:38', '2025-11-07 19:34:38', 'normal'),
(16, '', 1, 'paiement', 'Paiement confirmé', 'Votre paiement de 20000 FCFA a été validé avec succès. Un reçu a été envoyé à votre email.', NULL, NULL, '', '2025-11-07 19:40:16', '2025-11-07 19:40:16', 'normal'),
(17, '', 1, 'resultats', 'Bulletin de notes disponible', 'Votre bulletin de notes pour concours d\'entrée à BBS est maintenant disponible. Moyenne: 15.00/20', NULL, NULL, '', '2025-11-07 19:42:12', '2025-11-07 19:42:12', 'normal'),
(18, '', 6, 'paiement', 'Paiement confirmé', 'Votre paiement de 20000 FCFA a été validé avec succès. Un reçu a été envoyé à votre email.', NULL, NULL, '', '2026-04-23 23:14:03', '2026-04-23 23:14:03', 'normal'),
(20, '20260613-1', NULL, 'document_validation', 'Document validé', 'Votre document \"Proposition technique et financiere LAPADI.pdf\" a été validé.', NULL, NULL, 'non_lu', '2026-06-13 00:10:18', '2026-06-13 00:10:18', 'normal'),
(21, '20260613-1', NULL, 'document_validation', 'Document validé', 'Votre document \"cartes de visites.png\" a été validé.', NULL, NULL, 'non_lu', '2026-06-13 00:12:02', '2026-06-13 00:12:02', 'normal'),
(22, '20260613-1', NULL, 'document_validation', 'Document rejeté', 'Votre document \"Capture d\'Ã©cran 2026-06-11 105016.png\" a été rejeté.', NULL, NULL, 'non_lu', '2026-06-13 00:12:18', '2026-06-13 00:12:18', 'high'),
(23, '20260613-1', NULL, 'document_validation', 'Document validé', 'Votre document \"Capture d\'Ã©cran 2026-06-11 105016.png\" a été validé.', NULL, NULL, 'non_lu', '2026-06-13 00:13:49', '2026-06-13 00:13:49', 'normal'),
(24, '20260613-1', NULL, 'document_validation', 'Document validé', 'Votre document \"Projet panorama des SI (Phase 2).pdf\" a été validé.', NULL, NULL, 'non_lu', '2026-06-13 00:14:24', '2026-06-13 00:14:24', 'normal'),
(25, '20260613-1', NULL, 'document_validation', 'Document validé', 'Votre document \"00000229-Jeunesse Akanda 2025.3.pdf\" a été validé.', NULL, NULL, 'non_lu', '2026-06-13 00:14:28', '2026-06-13 00:14:28', 'normal'),
(26, '20260613-1', NULL, 'document_validation', 'Document rejeté', 'Votre document \"Proposition technique et financiere LAPADI.pdf\" a été rejeté.', NULL, NULL, 'non_lu', '2026-06-13 00:15:03', '2026-06-13 00:15:03', 'high'),
(27, '20260613-1', NULL, 'document_validation', 'Document validé', 'Votre document \"Proposition technique et financiere LAPADI.pdf\" a été validé.', NULL, NULL, 'non_lu', '2026-06-13 00:15:29', '2026-06-13 00:15:29', 'normal');

-- --------------------------------------------------------

--
-- Structure de la table `nupcan_counters`
--

DROP TABLE IF EXISTS `nupcan_counters`;
CREATE TABLE IF NOT EXISTS `nupcan_counters` (
  `id` int NOT NULL AUTO_INCREMENT,
  `date_key` varchar(10) NOT NULL,
  `counter` int NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `date_key` (`date_key`)
) ENGINE=MyISAM AUTO_INCREMENT=7 DEFAULT CHARSET=latin1;

--
-- Déchargement des données de la table `nupcan_counters`
--

INSERT INTO `nupcan_counters` (`id`, `date_key`, `counter`, `created_at`, `updated_at`) VALUES
(1, '20251107', 1, '2025-11-07 18:50:00', '2025-11-07 18:50:00'),
(2, '20260402', 1, '2026-04-02 20:28:14', '2026-04-02 20:28:14'),
(3, '20260403', 3, '2026-04-02 23:35:21', '2026-04-03 00:34:52'),
(4, '20260424', 3, '2026-04-23 23:12:49', '2026-04-24 01:11:28'),
(5, '20260612', 2, '2026-06-12 18:33:55', '2026-06-12 18:54:19'),
(6, '20260613', 2, '2026-06-12 23:32:21', '2026-06-13 00:46:55');

-- --------------------------------------------------------

--
-- Structure de la table `paiements`
--

DROP TABLE IF EXISTS `paiements`;
CREATE TABLE IF NOT EXISTS `paiements` (
  `id` int NOT NULL AUTO_INCREMENT,
  `candidat_id` int DEFAULT NULL,
  `concours_id` int DEFAULT NULL,
  `nupcan` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `montant` decimal(10,2) NOT NULL,
  `methode` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `statut` enum('en_attente','valide','rejete') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'en_attente',
  `reference_paiement` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `numero_telephone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `recu_path` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_nipcan` (`nupcan`),
  KEY `idx_statut` (`statut`),
  KEY `idx_paiements_candidat_statut` (`candidat_id`,`statut`),
  KEY `idx_nupcan` (`nupcan`),
  KEY `idx_candidat_id` (`candidat_id`),
  KEY `idx_concours_id` (`concours_id`),
  KEY `idx_paiement_statut` (`statut`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `participations`
--

DROP TABLE IF EXISTS `participations`;
CREATE TABLE IF NOT EXISTS `participations` (
  `id` int NOT NULL AUTO_INCREMENT,
  `candidat_id` int NOT NULL,
  `concours_id` int NOT NULL,
  `filiere_id` int NOT NULL,
  `statut` enum('en_attente','admis','non_admis','liste_attente') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'en_attente',
  `moyenne_generale` decimal(5,2) DEFAULT NULL,
  `rang` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_participation` (`candidat_id`,`concours_id`),
  KEY `filiere_id` (`filiere_id`),
  KEY `idx_concours` (`concours_id`),
  KEY `idx_statut` (`statut`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `participations`
--

INSERT INTO `participations` (`id`, `candidat_id`, `concours_id`, `filiere_id`, `statut`, `moyenne_generale`, `rang`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 1, 'en_attente', NULL, NULL, '2026-06-13 00:46:55', '2026-06-13 00:46:55');

-- --------------------------------------------------------

--
-- Structure de la table `provinces`
--

DROP TABLE IF EXISTS `provinces`;
CREATE TABLE IF NOT EXISTS `provinces` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nompro` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `cdepro` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `provinces`
--

INSERT INTO `provinces` (`id`, `nompro`, `cdepro`, `created_at`, `updated_at`) VALUES
(1, 'Estuaire', 'EST', '2025-10-05 06:14:48', '2025-10-05 06:14:48'),
(2, 'Haut-Ogooué', 'HO', '2025-10-05 06:14:48', '2025-10-05 06:14:48'),
(3, 'Moyen-Ogooué', 'MO', '2025-10-05 06:14:48', '2025-10-05 06:14:48'),
(4, 'Ngounié', 'NGO', '2025-10-05 06:14:48', '2025-10-05 06:14:48'),
(5, 'Nyanga', 'NYA', '2025-10-05 06:14:48', '2025-10-05 06:14:48'),
(6, 'Ogooué-Ivindo', 'OI', '2025-10-05 06:14:48', '2025-10-05 06:14:48'),
(7, 'Ogooué-Lolo', 'OL', '2025-10-05 06:14:48', '2025-10-05 06:14:48'),
(8, 'Ogooué-Maritime', 'OM', '2025-10-05 06:14:48', '2025-10-05 06:14:48'),
(9, 'Woleu-Ntem', 'WN', '2025-10-05 06:14:48', '2025-10-05 06:14:48');

-- --------------------------------------------------------

--
-- Structure de la table `sessions`
--

DROP TABLE IF EXISTS `sessions`;
CREATE TABLE IF NOT EXISTS `sessions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `candidat_id` int NOT NULL,
  `token` varchar(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `expires_at` datetime NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `token` (`token`),
  KEY `candidat_id` (`candidat_id`),
  KEY `idx_token` (`token`),
  KEY `idx_expires_at` (`expires_at`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `support_requests`
--

DROP TABLE IF EXISTS `support_requests`;
CREATE TABLE IF NOT EXISTS `support_requests` (
  `id` int NOT NULL AUTO_INCREMENT,
  `candidat_nupcan` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `sujet` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `message` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `statut` enum('nouveau','en_cours','resolu','ferme') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'nouveau',
  `priorite` enum('basse','normale','haute','urgente') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'normale',
  `assigned_to` int DEFAULT NULL COMMENT 'Super admin assigné',
  `createdAt` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` datetime NULL DEFAULT NULL,
  `resolved_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `assigned_to` (`assigned_to`),
  KEY `idx_candidat` (`candidat_nupcan`),
  KEY `idx_statut` (`statut`),
  KEY `idx_priorite` (`priorite`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `support_responses`
--

DROP TABLE IF EXISTS `support_responses`;
CREATE TABLE IF NOT EXISTS `support_responses` (
  `id` int NOT NULL AUTO_INCREMENT,
  `support_request_id` int NOT NULL,
  `admin_id` int NOT NULL,
  `message` text NOT NULL,
  `is_internal_note` tinyint(1) DEFAULT '0',
  `createdAt` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_support_request` (`support_request_id`),
  KEY `idx_admin` (`admin_id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `administrateurs`
--
ALTER TABLE `administrateurs`
  ADD CONSTRAINT `administrateurs_ibfk_1` FOREIGN KEY (`etablissement_id`) REFERENCES `etablissements` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `administrateurs_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `administrateurs` (`id`) ON DELETE SET NULL;

--
-- Contraintes pour la table `admin_actions`
--
ALTER TABLE `admin_actions`
  ADD CONSTRAINT `admin_actions_ibfk_1` FOREIGN KEY (`admin_id`) REFERENCES `administrateurs` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `admin_logs`
--
ALTER TABLE `admin_logs`
  ADD CONSTRAINT `fk_log_admin` FOREIGN KEY (`admin_id`) REFERENCES `administrateurs` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `candidats`
--
ALTER TABLE `candidats`
  ADD CONSTRAINT `candidats_ibfk_1` FOREIGN KEY (`niveau_id`) REFERENCES `niveaux` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `candidats_ibfk_2` FOREIGN KEY (`concours_id`) REFERENCES `concours` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `candidats_ibfk_3` FOREIGN KEY (`filiere_id`) REFERENCES `filieres` (`id`) ON DELETE SET NULL;

--
-- Contraintes pour la table `concours`
--
ALTER TABLE `concours`
  ADD CONSTRAINT `fk_concours_etablissement` FOREIGN KEY (`etablissement_id`) REFERENCES `etablissements` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_concours_niveau` FOREIGN KEY (`niveau_id`) REFERENCES `niveaux` (`id`) ON DELETE SET NULL;

--
-- Contraintes pour la table `concours_filieres`
--
ALTER TABLE `concours_filieres`
  ADD CONSTRAINT `concours_filieres_ibfk_1` FOREIGN KEY (`concours_id`) REFERENCES `concours` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `concours_filieres_ibfk_2` FOREIGN KEY (`filiere_id`) REFERENCES `filieres` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `documents`
--
ALTER TABLE `documents`
  ADD CONSTRAINT `documents_ibfk_1` FOREIGN KEY (`candidat_id`) REFERENCES `candidats` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `documents_ibfk_2` FOREIGN KEY (`concours_id`) REFERENCES `concours` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `dossiers`
--
ALTER TABLE `dossiers`
  ADD CONSTRAINT `dossiers_ibfk_1` FOREIGN KEY (`candidat_id`) REFERENCES `candidats` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `dossiers_ibfk_2` FOREIGN KEY (`concours_id`) REFERENCES `concours` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `dossiers_ibfk_3` FOREIGN KEY (`document_id`) REFERENCES `documents` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `etablissements`
--
ALTER TABLE `etablissements`
  ADD CONSTRAINT `etablissements_ibfk_1` FOREIGN KEY (`province_id`) REFERENCES `provinces` (`id`) ON DELETE SET NULL;

--
-- Contraintes pour la table `filieres`
--
ALTER TABLE `filieres`
  ADD CONSTRAINT `filieres_ibfk_1` FOREIGN KEY (`niveau_id`) REFERENCES `niveaux` (`id`) ON DELETE SET NULL;

--
-- Contraintes pour la table `filiere_matieres`
--
ALTER TABLE `filiere_matieres`
  ADD CONSTRAINT `filiere_matieres_ibfk_1` FOREIGN KEY (`filiere_id`) REFERENCES `filieres` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `filiere_matieres_ibfk_2` FOREIGN KEY (`matiere_id`) REFERENCES `matieres` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `messages`
--
ALTER TABLE `messages`
  ADD CONSTRAINT `fk_message_admin` FOREIGN KEY (`admin_id`) REFERENCES `administrateurs` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_message_parent` FOREIGN KEY (`parent_id`) REFERENCES `messages` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_message_parent_realtime` FOREIGN KEY (`parent_message_id`) REFERENCES `messages` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `paiements`
--
ALTER TABLE `paiements`
  ADD CONSTRAINT `paiements_ibfk_1` FOREIGN KEY (`candidat_id`) REFERENCES `candidats` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `paiements_ibfk_2` FOREIGN KEY (`concours_id`) REFERENCES `concours` (`id`) ON DELETE SET NULL;

--
-- Contraintes pour la table `participations`
--
ALTER TABLE `participations`
  ADD CONSTRAINT `participations_ibfk_1` FOREIGN KEY (`candidat_id`) REFERENCES `candidats` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `participations_ibfk_2` FOREIGN KEY (`concours_id`) REFERENCES `concours` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `participations_ibfk_3` FOREIGN KEY (`filiere_id`) REFERENCES `filieres` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `sessions`
--
ALTER TABLE `sessions`
  ADD CONSTRAINT `sessions_ibfk_1` FOREIGN KEY (`candidat_id`) REFERENCES `candidats` (`id`) ON DELETE CASCADE;

--
-- Contraintes pour la table `support_requests`
--
ALTER TABLE `support_requests`
  ADD CONSTRAINT `support_requests_ibfk_1` FOREIGN KEY (`assigned_to`) REFERENCES `administrateurs` (`id`) ON DELETE SET NULL;
COMMIT;
SET FOREIGN_KEY_CHECKS = 1;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;



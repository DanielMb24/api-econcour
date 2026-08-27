-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Hôte : 127.0.0.1:3306
-- Généré le : jeu. 27 août 2026 à 11:57
-- Version du serveur : 8.4.7
-- Version de PHP : 8.5.0

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `gabconcours`
--

DELIMITER $$
--
-- Fonctions
--
DROP FUNCTION IF EXISTS `has_role`$$
CREATE DEFINER=`root`@`localhost` FUNCTION `has_role` (`_user_id` INT, `_role` VARCHAR(50)) RETURNS TINYINT(1) DETERMINISTIC READS SQL DATA BEGIN
    DECLARE role_exists BOOLEAN;

    SELECT EXISTS(
        SELECT 1
        FROM user_roles
        WHERE user_id = _user_id
        AND role = _role
    ) INTO role_exists;

    RETURN role_exists;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `administrateurs`
--

DROP TABLE IF EXISTS `administrateurs`;
CREATE TABLE IF NOT EXISTS `administrateurs` (
  `id` int NOT NULL AUTO_INCREMENT,
  `nom` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `prenom` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
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
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`),
  KEY `etablissement_id` (`etablissement_id`),
  KEY `created_by` (`created_by`),
  KEY `idx_email` (`email`),
  KEY `idx_role` (`role`),
  KEY `idx_statut` (`statut`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `administrateurs`
--

INSERT INTO `administrateurs` (`id`, `nom`, `prenom`, `email`, `password`, `role`, `admin_role`, `etablissement_id`, `statut`, `derniere_connexion`, `password_reset_token`, `password_reset_expires`, `created_by`, `created_at`, `updated_at`) VALUES
(1, 'Super', 'Admin', 'supadmin@gabconcours.ga', '$2b$12$LfrNmfUfuOR8FKNNlDUx9e0oMmt1RmoEmRGPOReavmIkaa3wM6QfC', 'super_admin', NULL, NULL, 'actif', '2026-07-07 12:51:45', NULL, NULL, NULL, '2025-11-07 18:22:00', '2026-07-07 12:51:45'),
(11, 'MAKOSSO', 'Daniel', 'mb.daniel241@gmail.com', '$2b$12$f0G4nNMJnBUqt4yd6B.D6.jGSeDJzUsqJclQmEA.9Tv9bQv3P485a', 'admin_etablissement', NULL, 1, 'actif', '2026-07-07 13:10:51', NULL, NULL, 1, '2026-07-07 13:05:45', '2026-07-07 13:10:51');

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
  `details` json DEFAULT NULL COMMENT 'Détails supplémentaires en JSON',
  `ip_address` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_admin` (`admin_id`),
  KEY `idx_action_type` (`action_type`),
  KEY `idx_candidat` (`candidat_nupcan`),
  KEY `idx_created_at` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `admin_actions`
--

INSERT INTO `admin_actions` (`id`, `admin_id`, `action_type`, `entity_type`, `entity_id`, `candidat_nupcan`, `description`, `details`, `ip_address`, `created_at`) VALUES
(5, 1, 'validation_document', 'document', 2, '20260614-1', 'Validation du document: Attestation', '{\"statut\": \"valide\", \"commentaire\": null, \"type_document\": \"pdf\"}', NULL, '2026-06-16 15:39:06'),
(6, 1, 'validation_document', 'document', 2, '20260614-1', 'Validation du document: Attestation', '{\"statut\": \"valide\", \"commentaire\": null, \"type_document\": \"pdf\"}', '::ffff:127.0.0.1', '2026-06-16 15:39:06'),
(7, 1, 'validation_document', 'document', 3, '20260619-1', 'Validation du document: Attestation ', '{\"statut\": \"valide\", \"commentaire\": null, \"type_document\": \"pdf\"}', NULL, '2026-06-19 23:03:32'),
(8, 1, 'validation_document', 'document', 3, '20260619-1', 'Validation du document: Attestation ', '{\"statut\": \"valide\", \"commentaire\": null, \"type_document\": \"pdf\"}', '::1', '2026-06-19 23:03:32'),
(9, 1, 'validation_document', 'document', 4, '20260620-1', 'Validation du document: Attestation ', '{\"statut\": \"valide\", \"commentaire\": null, \"type_document\": \"pdf\"}', NULL, '2026-06-20 09:44:31'),
(10, 1, 'validation_document', 'document', 4, '20260620-1', 'Validation du document: Attestation ', '{\"statut\": \"valide\", \"commentaire\": null, \"type_document\": \"pdf\"}', '::1', '2026-06-20 09:44:31'),
(11, 1, 'validation_document', 'document', 5, '20260707-1', 'Validation du document: Attestation ', '{\"statut\": \"valide\", \"commentaire\": null, \"type_document\": \"pdf\"}', NULL, '2026-07-07 12:03:08'),
(12, 1, 'validation_document', 'document', 5, '20260707-1', 'Validation du document: Attestation ', '{\"statut\": \"valide\", \"commentaire\": null, \"type_document\": \"pdf\"}', '::1', '2026-07-07 12:03:08');

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
  `old_values` json DEFAULT NULL,
  `new_values` json DEFAULT NULL,
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
  `maican` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `dtncan` date DEFAULT NULL,
  `telcan` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ldncan` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `phtcan` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `proorg` int DEFAULT NULL,
  `proact` int DEFAULT NULL,
  `proaff` int DEFAULT NULL,
  `statut` enum('en_attente','valide','rejete') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'en_attente',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
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
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `candidats`
--

INSERT INTO `candidats` (`id`, `niveau_id`, `concours_id`, `filiere_id`, `nipcan`, `nupcan`, `nomcan`, `prncan`, `maican`, `dtncan`, `telcan`, `ldncan`, `phtcan`, `proorg`, `proact`, `proaff`, `statut`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 1, 'NIP2026000004', '20260613-2', 'makosso', 'daniel', 'daniel@gmail.com', '2004-01-24', '+24101234569', 'port-gentil', 'photo-1781311615752-553525202.png', 1, 1, 3, 'en_attente', '2026-06-13 00:46:55', '2026-06-13 00:46:55'),
(2, 1, 1, 1, 'NIP2026000005', '20260614-1', 'makosso', 'daniela', 'daniel@gmail.com', '2004-01-24', '+24101234569', 'port-gentil', 'photo-1781476867810-594385194.png', 1, 1, 1, 'en_attente', '2026-06-14 22:41:08', '2026-06-14 22:41:08'),
(3, 1, 1, 1, 'NIP2026000006', '20260619-1', 'makosso', 'danie', 'daniel@gmail.com', '2004-01-24', '+24101234569', 'port-gentil', 'photo-1781909870478-201153322.png', 1, 1, 1, 'en_attente', '2026-06-19 22:57:50', '2026-06-19 22:57:50'),
(4, 1, 1, 1, 'NIP2026000007', '20260620-1', 'makosso', 'Dan', 'mb.daniel241@gmail.com', '2004-01-24', '074604327', 'port-gentil', 'photo-1781948529963-620456219.png', 3, 8, 7, 'en_attente', '2026-06-20 09:42:10', '2026-06-20 09:42:10'),
(5, 1, 1, 1, 'NIP2026000008', '20260707-1', 'MAKOSSO', 'Pierre', 'daniel.makosso@devgroup.ga', '2004-01-24', '074604327', 'POG', 'photo-1783425538549-897369857.jpg', 1, 1, 1, 'en_attente', '2026-07-07 11:58:58', '2026-07-07 11:58:58'),
(6, 1, 1, 1, 'NIP2026000009', '20260707-2', 'MAKOSSO', 'Pie', 'daniel.makosso@devgroup.ga', '2004-01-24', '074604327', 'POG', 'photo-1783432658357-377027907.png', 1, 1, 1, 'en_attente', '2026-07-07 13:57:38', '2026-07-07 13:57:38');

--
-- Déclencheurs `candidats`
--
DROP TRIGGER IF EXISTS `after_candidat_insert`;
DELIMITER $$
CREATE TRIGGER `after_candidat_insert` AFTER INSERT ON `candidats` FOR EACH ROW BEGIN
    IF NEW.concours_id IS NOT NULL AND NEW.filiere_id IS NOT NULL THEN
        INSERT INTO participations (candidat_id, concours_id, filiere_id, statut, created_at)
        VALUES (NEW.id, NEW.concours_id, NEW.filiere_id, 'en_attente', NOW())
        ON DUPLICATE KEY UPDATE updated_at = NOW();
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Doublure de structure pour la vue `compose`
-- (Voir ci-dessous la vue réelle)
--
DROP VIEW IF EXISTS `compose`;
CREATE TABLE IF NOT EXISTS `compose` (
`id` int
,`candidat_id` int
,`concours_id` int
,`matiere_id` int
,`notcomp` decimal(5,2)
,`coefficient` decimal(3,1)
,`nomcan` varchar(255)
,`prncan` varchar(255)
,`concours_nom` varchar(255)
,`nom_matiere` varchar(255)
);

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
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `type_concours` enum('premiere_annee','master','doctorat','autre') COLLATE utf8mb4_unicode_ci DEFAULT 'autre',
  `description_concours` text COLLATE utf8mb4_unicode_ci,
  `nombre_places_total` int DEFAULT '0',
  `duree_formation` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `diplome_delivre` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `date_publication_resultats` date DEFAULT NULL,
  `date_debut_cours` date DEFAULT NULL,
  `series_bac_acceptees` json DEFAULT NULL,
  `documents_requis` json DEFAULT NULL,
  `criteres_selection` json DEFAULT NULL,
  `modalites_inscription` json DEFAULT NULL,
  `conditions_eligibilite` json DEFAULT NULL,
  `contact_email` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `contact_telephone` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `lieu_examen` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `informations_complementaires` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id`),
  KEY `idx_etablissement` (`etablissement_id`),
  KEY `idx_niveau` (`niveau_id`),
  KEY `idx_statut` (`stacnc`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Liste des concours ouverts';

--
-- Déchargement des données de la table `concours`
--

INSERT INTO `concours` (`id`, `etablissement_id`, `niveau_id`, `libcnc`, `fracnc`, `agecnc`, `sescnc`, `debcnc`, `fincnc`, `stacnc`, `is_gorri`, `etddos`, `created_at`, `updated_at`, `type_concours`, `description_concours`, `nombre_places_total`, `duree_formation`, `diplome_delivre`, `date_publication_resultats`, `date_debut_cours`, `series_bac_acceptees`, `documents_requis`, `criteres_selection`, `modalites_inscription`, `conditions_eligibilite`, `contact_email`, `contact_telephone`, `lieu_examen`, `informations_complementaires`) VALUES
(1, 1, 1, 'concours d\'entrée à BBS', 100.00, 25, '2025-2026', '2026-06-07', '2026-07-07', '1', 0, '0', '2025-11-07 18:24:22', '2026-07-07 12:52:10', 'autre', NULL, 0, NULL, NULL, NULL, NULL, 'null', '[{\"nom\": \"Attestation \", \"description\": \"Attestation\", \"obligatoire\": true}]', 'null', 'null', 'null', NULL, NULL, NULL, NULL),
(2, 1, 1, 'Concours Entrée en Master', 0.00, 28, '2026', '2026-06-15', '2026-06-20', '1', 0, '0', '2026-06-16 16:24:37', '2026-06-16 16:24:37', 'master', 'Concours d\'entrée en Master', 0, NULL, NULL, NULL, NULL, NULL, '[{\"nom\": \"Acte de naissance\", \"description\": \"Acte de naissance original ou copie certifiée\", \"obligatoire\": true}, {\"nom\": \"Certificat de nationalité\", \"description\": \"Certificat de nationalité gabonaise\", \"obligatoire\": true}, {\"nom\": \"Diplôme du Baccalauréat\", \"description\": \"Diplôme du Baccalauréat ou équivalent\", \"obligatoire\": true}, {\"nom\": \"Relevé de notes du Baccalauréat\", \"description\": \"Relevé de notes complet\", \"obligatoire\": true}, {\"nom\": \"Photo d\'identité\", \"description\": \"Photo d\'identité récente (format 4x4)\", \"obligatoire\": true}, {\"nom\": \"Certificat médical\", \"description\": \"Certificat médical de moins de 3 mois\", \"obligatoire\": true}, {\"nom\": \"Casier judiciaire\", \"description\": \"Bulletin n°3 du casier judiciaire\", \"obligatoire\": true}]', '[]', '[{\"etape\": 1, \"titre\": \"Inscription en ligne\", \"description\": \"Créer un compte et remplir le formulaire\"}, {\"etape\": 2, \"titre\": \"Paiement des frais\", \"description\": \"Payer les frais d\'inscription\"}, {\"etape\": 3, \"titre\": \"Téléchargement des documents\", \"description\": \"Scanner et télécharger tous les documents requis\"}, {\"etape\": 4, \"titre\": \"Validation du dossier\", \"description\": \"Attendre la validation par l\'administration\"}, {\"etape\": 5, \"titre\": \"Récépissé d\'inscription\", \"description\": \"Télécharger et imprimer le récépissé\"}]', '[{\"condition\": \"Nationalité gabonaise\", \"obligatoire\": true}, {\"condition\": \"Âge maximum respecté\", \"obligatoire\": true}, {\"condition\": \"Diplôme requis obtenu\", \"obligatoire\": true}]', NULL, NULL, NULL, NULL);

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
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
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
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `concours_id` (`concours_id`),
  KEY `idx_candidat` (`candidat_id`),
  KEY `idx_statut` (`statut`),
  KEY `idx_documents_candidat_statut` (`candidat_id`,`statut`),
  KEY `idx_document_statut` (`statut`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `documents`
--

INSERT INTO `documents` (`id`, `candidat_id`, `concours_id`, `nomdoc`, `type`, `nom_fichier`, `chemin_fichier`, `statut`, `commentaire_validation`, `validated_by`, `validated_at`, `created_at`, `updated_at`) VALUES
(1, NULL, NULL, 'Acte de naissance', 'pdf', '1781312028718-746329538.pdf', NULL, 'en_attente', NULL, NULL, NULL, '2026-06-13 00:53:48', '2026-06-13 00:53:48'),
(2, NULL, NULL, 'Attestation', 'pdf', 'doc-1781619021069-923969740.pdf', 'uploads\\documents\\doc-1781619021069-923969740.pdf', 'valide', NULL, 1, '2026-06-16 15:39:06', '2026-06-16 13:58:38', '2026-06-16 15:39:06'),
(3, NULL, NULL, 'Attestation ', 'pdf', 'documents-1781909912619-251550528.pdf', NULL, 'valide', NULL, 1, '2026-06-19 23:03:32', '2026-06-19 22:58:32', '2026-06-19 23:03:32'),
(4, NULL, NULL, 'Attestation ', 'pdf', 'documents-1781948581020-778249664.pdf', NULL, 'valide', NULL, 1, '2026-06-20 09:44:31', '2026-06-20 09:43:01', '2026-06-20 09:44:31'),
(5, NULL, NULL, 'Attestation ', 'pdf', 'documents-1783425557660-893372411.pdf', NULL, 'valide', NULL, 1, '2026-07-07 12:03:08', '2026-07-07 11:59:17', '2026-07-07 12:03:08');

--
-- Déclencheurs `documents`
--
DROP TRIGGER IF EXISTS `after_document_update`;
DELIMITER $$
CREATE TRIGGER `after_document_update` AFTER UPDATE ON `documents` FOR EACH ROW BEGIN
    DECLARE v_nupcan VARCHAR(100);

    IF NEW.statut != OLD.statut AND NEW.statut IN ('valide', 'rejete') THEN
        SELECT dos.nupcan
        INTO v_nupcan
        FROM dossiers dos
        WHERE dos.document_id = NEW.id
        LIMIT 1;

        IF v_nupcan IS NOT NULL THEN
            INSERT INTO notifications (
                candidat_nupcan,
                type,
                titre,
                message,
                statut,
                priority,
                created_at
            ) VALUES (
                v_nupcan,
                'document_validation',
                CONCAT('Document ', IF(NEW.statut = 'valide', 'validé', 'rejeté')),
                CONCAT('Votre document "', NEW.nomdoc, '" a été ', IF(NEW.statut = 'valide', 'validé', 'rejeté'), '.'),
                'non_lu',
                IF(NEW.statut = 'valide', 'normal', 'high'),
                NOW()
            );
        END IF;
    END IF;
END
$$
DELIMITER ;
DROP TRIGGER IF EXISTS `after_document_validation`;
DELIMITER $$
CREATE TRIGGER `after_document_validation` AFTER UPDATE ON `documents` FOR EACH ROW BEGIN
    DECLARE v_nupcan VARCHAR(100);

    IF NEW.statut != OLD.statut
       AND NEW.statut IN ('valide', 'rejete')
       AND NEW.validated_by IS NOT NULL THEN

        SELECT dos.nupcan
        INTO v_nupcan
        FROM dossiers dos
        WHERE dos.document_id = NEW.id
        LIMIT 1;

        INSERT INTO admin_actions (
            admin_id,
            action_type,
            entity_type,
            entity_id,
            candidat_nupcan,
            description,
            details,
            created_at
        ) VALUES (
            NEW.validated_by,
            IF(NEW.statut = 'valide', 'validation_document', 'rejet_document'),
            'document',
            NEW.id,
            v_nupcan,
            CONCAT(IF(NEW.statut = 'valide', 'Validation', 'Rejet'), ' du document: ', NEW.nomdoc),
            JSON_OBJECT(
                'statut', NEW.statut,
                'commentaire', NEW.commentaire_validation,
                'type_document', NEW.type
            ),
            NOW()
        );
    END IF;
END
$$
DELIMITER ;

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
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `concours_id` (`concours_id`),
  KEY `document_id` (`document_id`),
  KEY `idx_candidat_id` (`candidat_id`),
  KEY `idx_nipcan` (`nupcan`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `dossiers`
--

INSERT INTO `dossiers` (`id`, `candidat_id`, `concours_id`, `document_id`, `nupcan`, `docdsr`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 1, '20260613-2', 'uploads\\documents\\1781312028718-746329538.pdf', '2026-06-13 00:53:48', '2026-06-13 00:53:48'),
(2, 2, 1, 2, '20260614-1', 'uploads\\documents\\doc-1781619021069-923969740.pdf', '2026-06-16 13:58:38', '2026-06-16 14:10:21'),
(3, 3, 1, 3, '20260619-1', 'uploads\\documents\\documents-1781909912619-251550528.pdf', '2026-06-19 22:58:32', '2026-06-19 22:58:32'),
(4, 4, 1, 4, '20260620-1', 'uploads\\documents\\documents-1781948581020-778249664.pdf', '2026-06-20 09:43:01', '2026-06-20 09:43:01'),
(5, 5, 1, 5, '20260707-1', 'uploads\\documents\\documents-1783425557660-893372411.pdf', '2026-07-07 11:59:17', '2026-07-07 11:59:17');

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
  `maiets` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `photo` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `province_id` int DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
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
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
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
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_filiere_matiere` (`filiere_id`,`matiere_id`),
  KEY `matiere_id` (`matiere_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `filiere_matieres`
--

INSERT INTO `filiere_matieres` (`id`, `filiere_id`, `matiere_id`, `coefficient`, `obligatoire`, `created_at`, `updated_at`) VALUES
(2, 1, 1, 3.0, 1, '2026-06-16 21:33:26', '2026-06-16 21:33:26'),
(3, 1, 2, 5.0, 1, '2026-06-16 21:33:26', '2026-06-16 21:33:26');

-- --------------------------------------------------------

--
-- Structure de la table `gabconcours`
--

DROP TABLE IF EXISTS `gabconcours`;
CREATE TABLE IF NOT EXISTS `gabconcours` (
  `C1` text COLLATE utf8mb4_unicode_ci
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `gabconcours`
--

INSERT INTO `gabconcours` (`C1`) VALUES
('-- phpMyAdmin SQL Dump'),
('-- version 5.2.3'),
('-- https://www.phpmyadmin.net/'),
('--'),
('-- Hôte : 127.0.0.1:3306'),
('-- Généré le : sam. 13 juin 2026 à 01:14'),
('-- Version du serveur : 8.4.7'),
('-- Version de PHP : 8.3.28'),
(NULL),
('SET SQL_MODE = \"NO_AUTO_VALUE_ON_ZERO\";'),
('START TRANSACTION;'),
('SET time_zone = \"+00:00\";'),
(NULL),
(NULL),
('/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;'),
('/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;'),
('/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;'),
('/*!40101 SET NAMES utf8mb4 */;'),
(NULL),
('--'),
('-- Base de données : `gabconcours`'),
('--'),
(NULL),
('DELIMITER $$'),
('--'),
('-- Fonctions'),
('--'),
('DROP FUNCTION IF EXISTS `has_role`$$'),
('CREATE DEFINER=`root`@`localhost` FUNCTION `has_role` (`_user_id` INT, `_role` VARCHAR(50)) RETURNS TINYINT(1) DETERMINISTIC READS SQL DATA BEGIN'),
('    DECLARE role_exists BOOLEAN;'),
(NULL),
('    SELECT EXISTS('),
('        SELECT 1'),
('        FROM user_roles'),
('        WHERE user_id = _user_id'),
('        AND role = _role'),
('    ) INTO role_exists;'),
(NULL),
('    RETURN role_exists;'),
('END$$'),
(NULL),
('DELIMITER ;'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la table `administrateurs`'),
('--'),
(NULL),
('DROP TABLE IF EXISTS `administrateurs`;'),
('CREATE TABLE IF NOT EXISTS `administrateurs` ('),
('  `id` int NOT NULL AUTO_INCREMENT,'),
('  `nom` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `prenom` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `role` enum(\'super_admin\',\'admin_etablissement\',\'sub_admin\') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT \'admin_etablissement\','),
('  `admin_role` enum(\'notes\',\'documents\') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,'),
('  `etablissement_id` int DEFAULT NULL,'),
('  `statut` enum(\'actif\',\'inactif\',\'suspendu\') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT \'actif\','),
('  `derniere_connexion` timestamp NULL DEFAULT NULL,'),
('  `password_reset_token` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,'),
('  `password_reset_expires` timestamp NULL DEFAULT NULL,'),
('  `created_by` int DEFAULT NULL,'),
('  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,'),
('  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,'),
('  PRIMARY KEY (`id`),'),
('  UNIQUE KEY `email` (`email`),'),
('  KEY `etablissement_id` (`etablissement_id`),'),
('  KEY `created_by` (`created_by`),'),
('  KEY `idx_email` (`email`),'),
('  KEY `idx_role` (`role`),'),
('  KEY `idx_statut` (`statut`)'),
(') ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'),
(NULL),
('--'),
('-- Déchargement des données de la table `administrateurs`'),
('--'),
(NULL),
('INSERT INTO `administrateurs` (`id`, `nom`, `prenom`, `email`, `password`, `role`, `admin_role`, `etablissement_id`, `statut`, `derniere_connexion`, `password_reset_token`, `password_reset_expires`, `created_by`, `created_at`, `updated_at`) VALUES'),
('(1, \'Super\', \'Admin\', \'supadmin@gabconcours.ga\', \'$2b$12$LfrNmfUfuOR8FKNNlDUx9e0oMmt1RmoEmRGPOReavmIkaa3wM6QfC\', \'super_admin\', NULL, NULL, \'actif\', \'2026-06-13 00:45:46\', NULL, NULL, NULL, \'2025-11-07 18:22:00\', \'2026-06-13 00:45:46\'),'),
('(7, \'makosso\', \'daniel\', \'mb.daniel241@gmail.com\', \'$2b$12$9GqzvSqVb6ETEp0hC/5DWeC.QIZ4nI/p3YaCqrUfBjUokSUt5FScK\', \'admin_etablissement\', NULL, 1, \'actif\', \'2026-06-12 23:50:28\', NULL, NULL, 1, \'2026-06-12 23:49:01\', \'2026-06-12 23:50:28\');'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la table `admin_actions`'),
('--'),
(NULL),
('DROP TABLE IF EXISTS `admin_actions`;'),
('CREATE TABLE IF NOT EXISTS `admin_actions` ('),
('  `id` int NOT NULL AUTO_INCREMENT,'),
('  `admin_id` int NOT NULL,'),
('  `action_type` enum(\'validation_document\',\'rejet_document\',\'ajout_note\',\'reponse_message\',\'creation_admin\',\'modification_concours\',\'autre\') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `entity_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT \'Type d entité (document, note, message, etc.)\','),
('  `entity_id` int DEFAULT NULL COMMENT \'ID de l entité concernée\','),
('  `candidat_nupcan` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT \'NUPCAN du candidat concerné\','),
('  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `details` json DEFAULT NULL COMMENT \'Détails supplémentaires en JSON\','),
('  `ip_address` varchar(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,'),
('  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,'),
('  PRIMARY KEY (`id`),'),
('  KEY `idx_admin` (`admin_id`),'),
('  KEY `idx_action_type` (`action_type`),'),
('  KEY `idx_candidat` (`candidat_nupcan`),'),
('  KEY `idx_created_at` (`created_at`)'),
(') ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la table `admin_logs`'),
('--'),
(NULL),
('DROP TABLE IF EXISTS `admin_logs`;'),
('CREATE TABLE IF NOT EXISTS `admin_logs` ('),
('  `id` int NOT NULL AUTO_INCREMENT,'),
('  `admin_id` int NOT NULL,'),
('  `action` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `table_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,'),
('  `record_id` int DEFAULT NULL,'),
('  `old_values` json DEFAULT NULL,'),
('  `new_values` json DEFAULT NULL,'),
('  `ip_address` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,'),
('  `user_agent` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,'),
('  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,'),
('  PRIMARY KEY (`id`),'),
('  KEY `admin_id` (`admin_id`),'),
('  KEY `table_name` (`table_name`),'),
('  KEY `created_at` (`created_at`)'),
(') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la table `candidats`'),
('--'),
(NULL),
('DROP TABLE IF EXISTS `candidats`;'),
('CREATE TABLE IF NOT EXISTS `candidats` ('),
('  `id` int NOT NULL AUTO_INCREMENT,'),
('  `niveau_id` int DEFAULT NULL,'),
('  `concours_id` int DEFAULT NULL,'),
('  `filiere_id` int DEFAULT NULL,'),
('  `nipcan` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,'),
('  `nupcan` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `nomcan` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `prncan` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `maican` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `dtncan` date DEFAULT NULL,'),
('  `telcan` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,'),
('  `ldncan` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,'),
('  `phtcan` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,'),
('  `proorg` int DEFAULT NULL,'),
('  `proact` int DEFAULT NULL,'),
('  `proaff` int DEFAULT NULL,'),
('  `statut` enum(\'en_attente\',\'valide\',\'rejete\') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT \'en_attente\','),
('  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,'),
('  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,'),
('  PRIMARY KEY (`id`),'),
('  UNIQUE KEY `nupcan` (`nupcan`),'),
('  KEY `niveau_id` (`niveau_id`),'),
('  KEY `idx_nipcan` (`nipcan`),'),
('  KEY `idx_nupcan` (`nupcan`),'),
('  KEY `idx_concours` (`concours_id`),'),
('  KEY `idx_statut` (`statut`),'),
('  KEY `idx_candidats_concours_statut` (`concours_id`,`statut`),'),
('  KEY `idx_filiere` (`filiere_id`),'),
('  KEY `idx_created` (`created_at`),'),
('  KEY `idx_candidat_statut` (`statut`)'),
(') ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'),
(NULL),
('--'),
('-- Déchargement des données de la table `candidats`'),
('--'),
(NULL),
('INSERT INTO `candidats` (`id`, `niveau_id`, `concours_id`, `filiere_id`, `nipcan`, `nupcan`, `nomcan`, `prncan`, `maican`, `dtncan`, `telcan`, `ldncan`, `phtcan`, `proorg`, `proact`, `proaff`, `statut`, `created_at`, `updated_at`) VALUES'),
('(1, 1, 1, 1, \'NIP2026000004\', \'20260613-2\', \'makosso\', \'daniel\', \'daniel@gmail.com\', \'2004-01-24\', \'+24101234569\', \'port-gentil\', \'photo-1781311615752-553525202.png\', 1, 1, 3, \'en_attente\', \'2026-06-13 00:46:55\', \'2026-06-13 00:46:55\');'),
(NULL),
('--'),
('-- Déclencheurs `candidats`'),
('--'),
('DROP TRIGGER IF EXISTS `after_candidat_insert`;'),
('DELIMITER $$'),
('CREATE TRIGGER `after_candidat_insert` AFTER INSERT ON `candidats` FOR EACH ROW BEGIN'),
('    IF NEW.concours_id IS NOT NULL AND NEW.filiere_id IS NOT NULL THEN'),
('        INSERT INTO participations (candidat_id, concours_id, filiere_id, statut, created_at)'),
('        VALUES (NEW.id, NEW.concours_id, NEW.filiere_id, \'en_attente\', NOW())'),
('        ON DUPLICATE KEY UPDATE updated_at = NOW();'),
('    END IF;'),
('END'),
('$$'),
('DELIMITER ;'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Doublure de structure pour la vue `compose`'),
('-- (Voir ci-dessous la vue réelle)'),
('--'),
('DROP VIEW IF EXISTS `compose`;'),
('CREATE TABLE IF NOT EXISTS `compose` ('),
('`candidat_id` int'),
(',`coefficient` decimal(3,1)'),
(',`concours_id` int'),
(',`concours_nom` varchar(255)'),
(',`id` int'),
(',`matiere_id` int'),
(',`nom_matiere` varchar(255)'),
(',`nomcan` varchar(255)'),
(',`notcomp` decimal(5,2)'),
(',`prncan` varchar(255)'),
(');'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la table `concours`'),
('--'),
(NULL),
('DROP TABLE IF EXISTS `concours`;'),
('CREATE TABLE IF NOT EXISTS `concours` ('),
('  `id` int NOT NULL AUTO_INCREMENT,'),
('  `etablissement_id` int DEFAULT NULL,'),
('  `niveau_id` int DEFAULT NULL,'),
('  `libcnc` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL COMMENT \'Nom du concours\','),
('  `fracnc` decimal(10,2) DEFAULT \'0.00\' COMMENT \'Frais d\'\'inscription\','),
('  `agecnc` int DEFAULT NULL COMMENT \'Age maximum pour participer\','),
('  `sescnc` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT \'Session du concours (ex: 2025/2026)\','),
('  `debcnc` date DEFAULT NULL COMMENT \'Date de début des inscriptions\','),
('  `fincnc` date DEFAULT NULL COMMENT \'Date de fin des inscriptions\','),
('  `stacnc` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT \'1\' COMMENT \'Statut (1=Ouvert, 0=Fermé)\','),
('  `is_gorri` tinyint(1) DEFAULT \'0\' COMMENT \'Statut Gorri (1=Gratuit, 0=Payant)\','),
('  `etddos` char(1) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT \'0\' COMMENT \'État du dossier (ex: 0=non validé, 1=validé)\','),
('  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,'),
('  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,'),
('  PRIMARY KEY (`id`),'),
('  KEY `idx_etablissement` (`etablissement_id`),'),
('  KEY `idx_niveau` (`niveau_id`),'),
('  KEY `idx_statut` (`stacnc`)'),
(') ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT=\'Liste des concours ouverts\';'),
(NULL),
('--'),
('-- Déchargement des données de la table `concours`'),
('--'),
(NULL),
('INSERT INTO `concours` (`id`, `etablissement_id`, `niveau_id`, `libcnc`, `fracnc`, `agecnc`, `sescnc`, `debcnc`, `fincnc`, `stacnc`, `is_gorri`, `etddos`, `created_at`, `updated_at`) VALUES'),
('(1, 1, 1, \'concours d\\\'entrée à BBS\', 20000.00, 25, \'2025-2026\', \'2025-11-07\', \'2025-12-07\', \'1\', 0, \'0\', \'2025-11-07 18:24:22\', \'2025-11-07 18:31:44\');'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la table `concours_filieres`'),
('--'),
(NULL),
('DROP TABLE IF EXISTS `concours_filieres`;'),
('CREATE TABLE IF NOT EXISTS `concours_filieres` ('),
('  `id` int NOT NULL AUTO_INCREMENT,'),
('  `concours_id` int NOT NULL,'),
('  `filiere_id` int NOT NULL,'),
('  `places_disponibles` int DEFAULT \'0\','),
('  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,'),
('  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,'),
('  PRIMARY KEY (`id`),'),
('  UNIQUE KEY `unique_concours_filiere` (`concours_id`,`filiere_id`),'),
('  KEY `filiere_id` (`filiere_id`)'),
(') ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'),
(NULL),
('--'),
('-- Déchargement des données de la table `concours_filieres`'),
('--'),
(NULL),
('INSERT INTO `concours_filieres` (`id`, `concours_id`, `filiere_id`, `places_disponibles`, `created_at`, `updated_at`) VALUES'),
('(3, 1, 1, 100, \'2025-11-07 18:27:36\', \'2025-11-07 18:27:36\');'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la table `documents`'),
('--'),
(NULL),
('DROP TABLE IF EXISTS `documents`;'),
('CREATE TABLE IF NOT EXISTS `documents` ('),
('  `id` int NOT NULL AUTO_INCREMENT,'),
('  `candidat_id` int DEFAULT NULL,'),
('  `concours_id` int DEFAULT NULL,'),
('  `nomdoc` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `nom_fichier` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `chemin_fichier` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,'),
('  `statut` enum(\'en_attente\',\'valide\',\'rejete\') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT \'en_attente\','),
('  `commentaire_validation` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,'),
('  `validated_by` int DEFAULT NULL,'),
('  `validated_at` timestamp NULL DEFAULT NULL,'),
('  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,'),
('  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,'),
('  PRIMARY KEY (`id`),'),
('  KEY `concours_id` (`concours_id`),'),
('  KEY `idx_candidat` (`candidat_id`),'),
('  KEY `idx_statut` (`statut`),'),
('  KEY `idx_documents_candidat_statut` (`candidat_id`,`statut`),'),
('  KEY `idx_document_statut` (`statut`)'),
(') ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'),
(NULL),
('--'),
('-- Déchargement des données de la table `documents`'),
('--'),
(NULL),
('INSERT INTO `documents` (`id`, `candidat_id`, `concours_id`, `nomdoc`, `type`, `nom_fichier`, `chemin_fichier`, `statut`, `commentaire_validation`, `validated_by`, `validated_at`, `created_at`, `updated_at`) VALUES'),
('(1, NULL, NULL, \'Acte de naissance\', \'pdf\', \'1781312028718-746329538.pdf\', NULL, \'en_attente\', NULL, NULL, NULL, \'2026-06-13 00:53:48\', \'2026-06-13 00:53:48\');'),
(NULL),
('--'),
('-- Déclencheurs `documents`'),
('--'),
('DROP TRIGGER IF EXISTS `after_document_update`;'),
('DELIMITER $$'),
('CREATE TRIGGER `after_document_update` AFTER UPDATE ON `documents` FOR EACH ROW BEGIN'),
('    DECLARE v_nupcan VARCHAR(100);'),
(NULL),
('    IF NEW.statut != OLD.statut AND NEW.statut IN (\'valide\', \'rejete\') THEN'),
('        SELECT dos.nupcan'),
('        INTO v_nupcan'),
('        FROM dossiers dos'),
('        WHERE dos.document_id = NEW.id'),
('        LIMIT 1;'),
(NULL),
('        IF v_nupcan IS NOT NULL THEN'),
('            INSERT INTO notifications ('),
('                candidat_nupcan,'),
('                type,'),
('                titre,'),
('                message,'),
('                statut,'),
('                priority,'),
('                created_at'),
('            ) VALUES ('),
('                v_nupcan,'),
('                \'document_validation\','),
('                CONCAT(\'Document \', IF(NEW.statut = \'valide\', \'validé\', \'rejeté\')),'),
('                CONCAT(\'Votre document \"\', NEW.nomdoc, \'\" a été \', IF(NEW.statut = \'valide\', \'validé\', \'rejeté\'), \'.\'),'),
('                \'non_lu\','),
('                IF(NEW.statut = \'valide\', \'normal\', \'high\'),'),
('                NOW()'),
('            );'),
('        END IF;'),
('    END IF;'),
('END'),
('$$'),
('DELIMITER ;'),
('DROP TRIGGER IF EXISTS `after_document_validation`;'),
('DELIMITER $$'),
('CREATE TRIGGER `after_document_validation` AFTER UPDATE ON `documents` FOR EACH ROW BEGIN'),
('  IF NEW.statut != OLD.statut AND (NEW.statut = \'valide\' OR NEW.statut = \'rejete\') THEN'),
('    IF NEW.validated_by IS NOT NULL THEN'),
('      INSERT INTO admin_actions ('),
('        admin_id,'),
('        action_type,'),
('        entity_type,'),
('        entity_id,'),
('        candidat_nupcan,'),
('        description,'),
('        details'),
('      ) VALUES ('),
('        NEW.validated_by,'),
('        IF(NEW.statut = \'valide\', \'validation_document\', \'rejet_document\'),'),
('        \'document\','),
('        NEW.id,'),
('        CONCAT(IF(NEW.statut = \'valide\', \'Validation\', \'Rejet\'), \' du document: \', NEW.nomdoc),'),
('        JSON_OBJECT('),
('          \'statut\', NEW.statut,'),
('          \'commentaire\', NEW.commentaire_validation,'),
('          \'type_document\', NEW.type'),
('        )'),
('      );'),
('    END IF;'),
('  END IF;'),
('END'),
('$$'),
('DELIMITER ;'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la table `dossiers`'),
('--'),
(NULL),
('DROP TABLE IF EXISTS `dossiers`;'),
('CREATE TABLE IF NOT EXISTS `dossiers` ('),
('  `id` int NOT NULL AUTO_INCREMENT,'),
('  `candidat_id` int DEFAULT NULL,'),
('  `concours_id` int DEFAULT NULL,'),
('  `document_id` int DEFAULT NULL,'),
('  `nupcan` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,'),
('  `docdsr` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,'),
('  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,'),
('  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,'),
('  PRIMARY KEY (`id`),'),
('  KEY `concours_id` (`concours_id`),'),
('  KEY `document_id` (`document_id`),'),
('  KEY `idx_candidat_id` (`candidat_id`),'),
('  KEY `idx_nipcan` (`nupcan`)'),
(') ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'),
(NULL),
('--'),
('-- Déchargement des données de la table `dossiers`'),
('--'),
(NULL),
('INSERT INTO `dossiers` (`id`, `candidat_id`, `concours_id`, `document_id`, `nupcan`, `docdsr`, `created_at`, `updated_at`) VALUES'),
('(1, 1, 1, 1, \'20260613-2\', \'uploads\\\\documents\\\\1781312028718-746329538.pdf\', \'2026-06-13 00:53:48\', \'2026-06-13 00:53:48\');'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la table `etablissements`'),
('--'),
(NULL),
('DROP TABLE IF EXISTS `etablissements`;'),
('CREATE TABLE IF NOT EXISTS `etablissements` ('),
('  `id` int NOT NULL AUTO_INCREMENT,'),
('  `nomets` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `adretes` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,'),
('  `telefs` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,'),
('  `maiets` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,'),
('  `photo` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,'),
('  `province_id` int DEFAULT NULL,'),
('  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,'),
('  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,'),
('  PRIMARY KEY (`id`),'),
('  KEY `idx_province` (`province_id`)'),
(') ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'),
(NULL),
('--'),
('-- Déchargement des données de la table `etablissements`'),
('--'),
(NULL),
('INSERT INTO `etablissements` (`id`, `nomets`, `adretes`, `telefs`, `maiets`, `photo`, `province_id`, `created_at`, `updated_at`) VALUES'),
('(1, \'BBS\', \'Libreville, Gabon\', \'074604327\', \'danimb241@gmail.com\', \'\', 1, \'2025-11-07 18:23:06\', \'2025-11-07 18:23:37\');'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la table `filieres`'),
('--'),
(NULL),
('DROP TABLE IF EXISTS `filieres`;'),
('CREATE TABLE IF NOT EXISTS `filieres` ('),
('  `id` int NOT NULL AUTO_INCREMENT,'),
('  `nomfil` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,'),
('  `niveau_id` int DEFAULT NULL,'),
('  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,'),
('  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,'),
('  PRIMARY KEY (`id`),'),
('  KEY `idx_niveau` (`niveau_id`)'),
(') ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'),
(NULL),
('--'),
('-- Déchargement des données de la table `filieres`'),
('--'),
(NULL),
('INSERT INTO `filieres` (`id`, `nomfil`, `description`, `niveau_id`, `created_at`, `updated_at`) VALUES'),
('(1, \'Droit\', \'Sciences juridiques\', 1, \'2025-11-07 18:25:31\', \'2025-11-07 18:25:31\');'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la table `filiere_matieres`'),
('--'),
(NULL),
('DROP TABLE IF EXISTS `filiere_matieres`;'),
('CREATE TABLE IF NOT EXISTS `filiere_matieres` ('),
('  `id` int NOT NULL AUTO_INCREMENT,'),
('  `filiere_id` int NOT NULL,'),
('  `matiere_id` int NOT NULL,'),
('  `coefficient` decimal(3,1) NOT NULL DEFAULT \'1.0\','),
('  `obligatoire` tinyint(1) DEFAULT \'1\','),
('  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,'),
('  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,'),
('  PRIMARY KEY (`id`),'),
('  UNIQUE KEY `unique_filiere_matiere` (`filiere_id`,`matiere_id`),'),
('  KEY `matiere_id` (`matiere_id`)'),
(') ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'),
(NULL),
('--'),
('-- Déchargement des données de la table `filiere_matieres`'),
('--'),
(NULL),
('INSERT INTO `filiere_matieres` (`id`, `filiere_id`, `matiere_id`, `coefficient`, `obligatoire`, `created_at`, `updated_at`) VALUES'),
('(1, 1, 1, 3.0, 1, \'2025-11-07 18:27:01\', \'2025-11-07 18:27:01\');'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la table `matieres`'),
('--'),
(NULL),
('DROP TABLE IF EXISTS `matieres`;'),
('CREATE TABLE IF NOT EXISTS `matieres` ('),
('  `id` int NOT NULL AUTO_INCREMENT,'),
('  `nom_matiere` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `coefficient` decimal(3,1) DEFAULT NULL,'),
('  `duree` int DEFAULT NULL COMMENT \'Durée en heures\','),
('  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,'),
('  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,'),
('  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,'),
('  PRIMARY KEY (`id`)'),
(') ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'),
(NULL),
('--'),
('-- Déchargement des données de la table `matieres`'),
('--'),
(NULL),
('INSERT INTO `matieres` (`id`, `nom_matiere`, `coefficient`, `duree`, `description`, `created_at`, `updated_at`) VALUES'),
('(1, \'Anglais\', 3.0, NULL, NULL, \'2025-11-07 18:26:33\', \'2025-11-07 18:26:33\');'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la table `messages`'),
('--'),
(NULL),
('DROP TABLE IF EXISTS `messages`;'),
('CREATE TABLE IF NOT EXISTS `messages` ('),
('  `id` int NOT NULL AUTO_INCREMENT,'),
('  `candidat_nupcan` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `admin_id` int DEFAULT NULL,'),
('  `sujet` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `message` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `expediteur` enum(\'candidat\',\'admin\') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `statut` enum(\'lu\',\'non_lu\') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT \'non_lu\','),
('  `parent_id` int DEFAULT NULL COMMENT \'Pour les réponses\','),
('  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,'),
('  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,'),
('  PRIMARY KEY (`id`),'),
('  KEY `candidat_nupcan` (`candidat_nupcan`),'),
('  KEY `admin_id` (`admin_id`),'),
('  KEY `parent_id` (`parent_id`),'),
('  KEY `statut` (`statut`),'),
('  KEY `idx_message_statut_expediteur` (`statut`,`expediteur`)'),
(') ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'),
(NULL),
('--'),
('-- Déchargement des données de la table `messages`'),
('--'),
(NULL),
('INSERT INTO `messages` (`id`, `candidat_nupcan`, `admin_id`, `sujet`, `message`, `expediteur`, `statut`, `parent_id`, `created_at`, `updated_at`) VALUES'),
('(1, \'20251107-1\', NULL, \'Documents\', \'Je n\\\'arrive pas à televerser mes documents rejetés\', \'candidat\', \'non_lu\', NULL, \'2025-11-07 19:42:55\', \'2025-11-07 19:42:55\');'),
(NULL),
('--'),
('-- Déclencheurs `messages`'),
('--'),
('DROP TRIGGER IF EXISTS `after_admin_message_response`;'),
('DELIMITER $$'),
('CREATE TRIGGER `after_admin_message_response` AFTER INSERT ON `messages` FOR EACH ROW BEGIN'),
('  IF NEW.expediteur = \'admin\' THEN'),
('    INSERT INTO notifications ('),
('      user_type,'),
('      user_id,'),
('      type,'),
('      titre,'),
('      message,'),
('      action_url,'),
('      priority'),
('    ) VALUES ('),
('      \'candidat\','),
('      NEW.candidat_nupcan,'),
('      \'message\','),
('      \'Nouvelle réponse à votre message\','),
('      CONCAT(\'Vous avez reçu une réponse concernant: \', NEW.sujet),'),
('      \'/candidat/messages\','),
('      \'high\''),
('    );'),
('    '),
('    INSERT INTO admin_actions ('),
('      admin_id,'),
('      action_type,'),
('      entity_type,'),
('      entity_id,'),
('      candidat_nupcan,'),
('      description'),
('    ) VALUES ('),
('      NEW.admin_id,'),
('      \'reponse_message\','),
('      \'message\','),
('      NEW.id,'),
('      NEW.candidat_nupcan,'),
('      CONCAT(\'Réponse au message: \', NEW.sujet)'),
('    );'),
('  END IF;'),
('END'),
('$$'),
('DELIMITER ;'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la table `nipcan_counters`'),
('--'),
(NULL),
('DROP TABLE IF EXISTS `nipcan_counters`;'),
('CREATE TABLE IF NOT EXISTS `nipcan_counters` ('),
('  `id` int NOT NULL AUTO_INCREMENT,'),
('  `year` int NOT NULL,'),
('  `counter` int NOT NULL DEFAULT \'1\','),
('  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,'),
('  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,'),
('  PRIMARY KEY (`id`),'),
('  UNIQUE KEY `year` (`year`)'),
(') ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'),
(NULL),
('--'),
('-- Déchargement des données de la table `nipcan_counters`'),
('--'),
(NULL),
('INSERT INTO `nipcan_counters` (`id`, `year`, `counter`, `created_at`, `updated_at`) VALUES'),
('(1, 2026, 4, \'2026-04-02 23:35:21\', \'2026-06-13 00:46:55\');'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la table `niveaux`'),
('--'),
(NULL),
('DROP TABLE IF EXISTS `niveaux`;'),
('CREATE TABLE IF NOT EXISTS `niveaux` ('),
('  `id` int NOT NULL AUTO_INCREMENT,'),
('  `nomniv` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `description` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,'),
('  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,'),
('  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,'),
('  PRIMARY KEY (`id`)'),
(') ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'),
(NULL),
('--'),
('-- Déchargement des données de la table `niveaux`'),
('--'),
(NULL),
('INSERT INTO `niveaux` (`id`, `nomniv`, `description`, `created_at`, `updated_at`) VALUES'),
('(1, \'Licence 1\', \'Première année de licence\', \'2025-10-05 06:14:48\', \'2025-10-05 06:14:48\'),'),
('(2, \'Licence 2\', \'Deuxième année de licence\', \'2025-10-05 06:14:48\', \'2025-10-05 06:14:48\'),'),
('(3, \'Licence 3\', \'Troisième année de licence\', \'2025-10-05 06:14:48\', \'2025-10-05 06:14:48\'),'),
('(4, \'Master 1\', \'Première année de master\', \'2025-10-05 06:14:48\', \'2025-10-05 06:14:48\'),'),
('(5, \'Master 2\', \'Deuxième année de master\', \'2025-10-05 06:14:48\', \'2025-10-05 06:14:48\'),'),
('(6, \'Doctorat\', \'Études doctorales\', \'2025-10-05 06:14:48\', \'2025-10-05 06:14:48\'),'),
('(7, \'Terminale C\', \'Terminale série C (Mathématiques et Sciences Physiques)\', \'2025-10-05 06:14:48\', \'2025-10-05 06:14:48\'),'),
('(8, \'Terminale D\', \'Terminale série D (Mathématiques et Sciences de la Nature)\', \'2025-10-05 06:14:48\', \'2025-10-05 06:14:48\'),'),
('(9, \'Terminale A\', \'Terminale série A (Littéraire)\', \'2025-10-05 06:14:48\', \'2025-10-05 06:14:48\'),'),
('(10, \'BTS\', \'Brevet de Technicien Supérieur\', \'2025-10-05 06:14:48\', \'2025-10-05 06:14:48\');'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la table `notes`'),
('--'),
(NULL),
('DROP TABLE IF EXISTS `notes`;'),
('CREATE TABLE IF NOT EXISTS `notes` ('),
('  `id` int NOT NULL AUTO_INCREMENT,'),
('  `candidat_id` int NOT NULL,'),
('  `concours_id` int NOT NULL,'),
('  `matiere_id` int NOT NULL,'),
('  `note` decimal(5,2) NOT NULL,'),
('  `coefficient` decimal(3,1) DEFAULT \'1.0\','),
('  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,'),
('  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,'),
('  PRIMARY KEY (`id`),'),
('  UNIQUE KEY `unique_note` (`candidat_id`,`concours_id`,`matiere_id`),'),
('  KEY `idx_candidat` (`candidat_id`),'),
('  KEY `idx_concours` (`concours_id`),'),
('  KEY `idx_matiere` (`matiere_id`)'),
(') ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'),
(NULL),
('--'),
('-- Déchargement des données de la table `notes`'),
('--'),
(NULL),
('INSERT INTO `notes` (`id`, `candidat_id`, `concours_id`, `matiere_id`, `note`, `coefficient`, `created_at`, `updated_at`) VALUES'),
('(1, 1, 1, 1, 15.00, 3.0, \'2025-11-07 19:41:19\', \'2025-11-07 19:41:19\');'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la table `notifications`'),
('--'),
(NULL),
('DROP TABLE IF EXISTS `notifications`;'),
('CREATE TABLE IF NOT EXISTS `notifications` ('),
('  `id` int NOT NULL AUTO_INCREMENT,'),
('  `candidat_nupcan` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `candidat_id` int DEFAULT NULL,'),
('  `type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `titre` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `message` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `reference_id` int DEFAULT NULL,'),
('  `reference_type` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,'),
('  `statut` enum(\'lu\',\'non_lu\') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT \'non_lu\','),
('  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,'),
('  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,'),
('  `priority` enum(\'low\',\'normal\',\'high\') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT \'normal\','),
('  PRIMARY KEY (`id`),'),
('  KEY `idx_nupcan` (`candidat_nupcan`),'),
('  KEY `idx_statut` (`statut`),'),
('  KEY `idx_created_at` (`created_at`),'),
('  KEY `idx_notifications_date` (`candidat_nupcan`,`created_at`),'),
('  KEY `idx_candidat` (`candidat_id`),'),
('  KEY `idx_reference` (`reference_type`,`reference_id`)'),
(') ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'),
(NULL),
('--'),
('-- Déchargement des données de la table `notifications`'),
('--'),
(NULL),
('INSERT INTO `notifications` (`id`, `candidat_nupcan`, `candidat_id`, `type`, `titre`, `message`, `reference_id`, `reference_type`, `statut`, `created_at`, `updated_at`, `priority`) VALUES'),
('(1, \'20251107-1\', NULL, \'document_validation\', \'Document rejeté\', \'Votre document \\\"doc2.jpg\\\" a été rejeté.\', NULL, NULL, \'non_lu\', \'2025-11-07 19:30:46\', \'2025-11-07 19:30:46\', \'high\'),'),
('(2, \'20251107-1\', NULL, \'document_validation\', \'Document rejeté\', \'Votre document \\\"doc2.jpg\\\" a été rejeté. Motif: Mauvais document veuillez remplacer ce document\', NULL, NULL, \'non_lu\', \'2025-11-07 19:30:46\', \'2025-11-07 19:30:46\', \'normal\'),'),
('(3, \'20251107-1\', NULL, \'document_validation\', \'Document validé\', \'Votre document \\\"doc2.jpg\\\" a été validé.\', NULL, NULL, \'non_lu\', \'2025-11-07 19:32:13\', \'2025-11-07 19:32:13\', \'normal\'),'),
('(4, \'20251107-1\', NULL, \'document_validation\', \'Document validé\', \'Votre document \\\"doc2.jpg\\\" a été validé avec succès.\', NULL, NULL, \'non_lu\', \'2025-11-07 19:32:13\', \'2025-11-07 19:32:13\', \'normal\'),'),
('(5, \'20251107-1\', NULL, \'document_validation\', \'Document validé\', \'Votre document \\\"doc1.pdf\\\" a été validé.\', NULL, NULL, \'non_lu\', \'2025-11-07 19:32:17\', \'2025-11-07 19:32:17\', \'normal\'),'),
('(6, \'20251107-1\', NULL, \'document_validation\', \'Document validé\', \'Votre document \\\"doc1.pdf\\\" a été validé avec succès.\', NULL, NULL, \'non_lu\', \'2025-11-07 19:32:17\', \'2025-11-07 19:32:17\', \'normal\'),'),
('(7, \'20251107-1\', NULL, \'document_validation\', \'Document validé\', \'Votre document \\\"doc1.pdf\\\" a été validé avec succès.\', NULL, NULL, \'non_lu\', \'2025-11-07 19:32:20\', \'2025-11-07 19:32:20\', \'normal\'),'),
('(8, \'20251107-1\', NULL, \'document_validation\', \'Document validé\', \'Votre document \\\"doc1.pdf\\\" a été validé avec succès.\', NULL, NULL, \'non_lu\', \'2025-11-07 19:32:26\', \'2025-11-07 19:32:26\', \'normal\'),'),
('(9, \'20251107-1\', NULL, \'document_validation\', \'Document validé\', \'Votre document \\\"doc4.png\\\" a été validé.\', NULL, NULL, \'non_lu\', \'2025-11-07 19:32:29\', \'2025-11-07 19:32:29\', \'normal\'),'),
('(10, \'20251107-1\', NULL, \'document_validation\', \'Document validé\', \'Votre document \\\"doc4.png\\\" a été validé avec succès.\', NULL, NULL, \'non_lu\', \'2025-11-07 19:32:29\', \'2025-11-07 19:32:29\', \'normal\'),'),
('(11, \'20251107-1\', NULL, \'document_validation\', \'Document validé\', \'Votre document \\\"doc1.pdf\\\" a été validé avec succès.\', NULL, NULL, \'non_lu\', \'2025-11-07 19:32:36\', \'2025-11-07 19:32:36\', \'normal\'),'),
('(12, \'20251107-1\', NULL, \'document_validation\', \'Document validé\', \'Votre document \\\"doc1.pdf\\\" a été validé avec succès.\', NULL, NULL, \'non_lu\', \'2025-11-07 19:32:57\', \'2025-11-07 19:32:57\', \'normal\'),'),
('(13, \'20251107-1\', NULL, \'document_validation\', \'Document validé\', \'Votre document \\\"doc1.pdf\\\" a été validé avec succès.\', NULL, NULL, \'non_lu\', \'2025-11-07 19:34:34\', \'2025-11-07 19:34:34\', \'normal\'),'),
('(14, \'20251107-1\', NULL, \'document_validation\', \'Document validé\', \'Votre document \\\"doc3.jpg\\\" a été validé.\', NULL, NULL, \'non_lu\', \'2025-11-07 19:34:38\', \'2025-11-07 19:34:38\', \'normal\'),'),
('(15, \'20251107-1\', NULL, \'document_validation\', \'Document validé\', \'Votre document \\\"doc3.jpg\\\" a été validé avec succès.\', NULL, NULL, \'non_lu\', \'2025-11-07 19:34:38\', \'2025-11-07 19:34:38\', \'normal\'),'),
('(16, \'\', 1, \'paiement\', \'Paiement confirmé\', \'Votre paiement de 20000 FCFA a été validé avec succès. Un reçu a été envoyé à votre email.\', NULL, NULL, \'\', \'2025-11-07 19:40:16\', \'2025-11-07 19:40:16\', \'normal\'),'),
('(17, \'\', 1, \'resultats\', \'Bulletin de notes disponible\', \'Votre bulletin de notes pour concours d\\\'entrée à BBS est maintenant disponible. Moyenne: 15.00/20\', NULL, NULL, \'\', \'2025-11-07 19:42:12\', \'2025-11-07 19:42:12\', \'normal\'),'),
('(18, \'\', 6, \'paiement\', \'Paiement confirmé\', \'Votre paiement de 20000 FCFA a été validé avec succès. Un reçu a été envoyé à votre email.\', NULL, NULL, \'\', \'2026-04-23 23:14:03\', \'2026-04-23 23:14:03\', \'normal\'),'),
('(20, \'20260613-1\', NULL, \'document_validation\', \'Document validé\', \'Votre document \\\"Proposition technique et financiere LAPADI.pdf\\\" a été validé.\', NULL, NULL, \'non_lu\', \'2026-06-13 00:10:18\', \'2026-06-13 00:10:18\', \'normal\'),'),
('(21, \'20260613-1\', NULL, \'document_validation\', \'Document validé\', \'Votre document \\\"cartes de visites.png\\\" a été validé.\', NULL, NULL, \'non_lu\', \'2026-06-13 00:12:02\', \'2026-06-13 00:12:02\', \'normal\'),'),
('(22, \'20260613-1\', NULL, \'document_validation\', \'Document rejeté\', \'Votre document \\\"Capture d\\\'Ã©cran 2026-06-11 105016.png\\\" a été rejeté.\', NULL, NULL, \'non_lu\', \'2026-06-13 00:12:18\', \'2026-06-13 00:12:18\', \'high\'),'),
('(23, \'20260613-1\', NULL, \'document_validation\', \'Document validé\', \'Votre document \\\"Capture d\\\'Ã©cran 2026-06-11 105016.png\\\" a été validé.\', NULL, NULL, \'non_lu\', \'2026-06-13 00:13:49\', \'2026-06-13 00:13:49\', \'normal\'),'),
('(24, \'20260613-1\', NULL, \'document_validation\', \'Document validé\', \'Votre document \\\"Projet panorama des SI (Phase 2).pdf\\\" a été validé.\', NULL, NULL, \'non_lu\', \'2026-06-13 00:14:24\', \'2026-06-13 00:14:24\', \'normal\'),'),
('(25, \'20260613-1\', NULL, \'document_validation\', \'Document validé\', \'Votre document \\\"00000229-Jeunesse Akanda 2025.3.pdf\\\" a été validé.\', NULL, NULL, \'non_lu\', \'2026-06-13 00:14:28\', \'2026-06-13 00:14:28\', \'normal\'),'),
('(26, \'20260613-1\', NULL, \'document_validation\', \'Document rejeté\', \'Votre document \\\"Proposition technique et financiere LAPADI.pdf\\\" a été rejeté.\', NULL, NULL, \'non_lu\', \'2026-06-13 00:15:03\', \'2026-06-13 00:15:03\', \'high\'),'),
('(27, \'20260613-1\', NULL, \'document_validation\', \'Document validé\', \'Votre document \\\"Proposition technique et financiere LAPADI.pdf\\\" a été validé.\', NULL, NULL, \'non_lu\', \'2026-06-13 00:15:29\', \'2026-06-13 00:15:29\', \'normal\');'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la table `nupcan_counters`'),
('--'),
(NULL),
('DROP TABLE IF EXISTS `nupcan_counters`;'),
('CREATE TABLE IF NOT EXISTS `nupcan_counters` ('),
('  `id` int NOT NULL AUTO_INCREMENT,'),
('  `date_key` varchar(10) NOT NULL,'),
('  `counter` int NOT NULL DEFAULT \'1\','),
('  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,'),
('  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,'),
('  PRIMARY KEY (`id`),'),
('  UNIQUE KEY `date_key` (`date_key`)'),
(') ENGINE=MyISAM AUTO_INCREMENT=7 DEFAULT CHARSET=latin1;'),
(NULL),
('--'),
('-- Déchargement des données de la table `nupcan_counters`'),
('--'),
(NULL),
('INSERT INTO `nupcan_counters` (`id`, `date_key`, `counter`, `created_at`, `updated_at`) VALUES'),
('(1, \'20251107\', 1, \'2025-11-07 18:50:00\', \'2025-11-07 18:50:00\'),'),
('(2, \'20260402\', 1, \'2026-04-02 20:28:14\', \'2026-04-02 20:28:14\'),'),
('(3, \'20260403\', 3, \'2026-04-02 23:35:21\', \'2026-04-03 00:34:52\'),'),
('(4, \'20260424\', 3, \'2026-04-23 23:12:49\', \'2026-04-24 01:11:28\'),'),
('(5, \'20260612\', 2, \'2026-06-12 18:33:55\', \'2026-06-12 18:54:19\'),'),
('(6, \'20260613\', 2, \'2026-06-12 23:32:21\', \'2026-06-13 00:46:55\');'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la table `paiements`'),
('--'),
(NULL),
('DROP TABLE IF EXISTS `paiements`;'),
('CREATE TABLE IF NOT EXISTS `paiements` ('),
('  `id` int NOT NULL AUTO_INCREMENT,'),
('  `candidat_id` int DEFAULT NULL,'),
('  `concours_id` int DEFAULT NULL,'),
('  `nupcan` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,'),
('  `montant` decimal(10,2) NOT NULL,'),
('  `methode` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `statut` enum(\'en_attente\',\'valide\',\'rejete\') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT \'en_attente\','),
('  `reference_paiement` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,'),
('  `numero_telephone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,'),
('  `recu_path` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,'),
('  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,'),
('  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,'),
('  PRIMARY KEY (`id`),'),
('  KEY `idx_nipcan` (`nupcan`),'),
('  KEY `idx_statut` (`statut`),'),
('  KEY `idx_paiements_candidat_statut` (`candidat_id`,`statut`),'),
('  KEY `idx_nupcan` (`nupcan`),'),
('  KEY `idx_candidat_id` (`candidat_id`),'),
('  KEY `idx_concours_id` (`concours_id`),'),
('  KEY `idx_paiement_statut` (`statut`)'),
(') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la table `participations`'),
('--'),
(NULL),
('DROP TABLE IF EXISTS `participations`;'),
('CREATE TABLE IF NOT EXISTS `participations` ('),
('  `id` int NOT NULL AUTO_INCREMENT,'),
('  `candidat_id` int NOT NULL,'),
('  `concours_id` int NOT NULL,'),
('  `filiere_id` int NOT NULL,'),
('  `statut` enum(\'en_attente\',\'admis\',\'non_admis\',\'liste_attente\') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT \'en_attente\','),
('  `moyenne_generale` decimal(5,2) DEFAULT NULL,'),
('  `rang` int DEFAULT NULL,'),
('  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,'),
('  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,'),
('  PRIMARY KEY (`id`),'),
('  UNIQUE KEY `unique_participation` (`candidat_id`,`concours_id`),'),
('  KEY `filiere_id` (`filiere_id`),'),
('  KEY `idx_concours` (`concours_id`),'),
('  KEY `idx_statut` (`statut`)'),
(') ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'),
(NULL),
('--'),
('-- Déchargement des données de la table `participations`'),
('--'),
(NULL),
('INSERT INTO `participations` (`id`, `candidat_id`, `concours_id`, `filiere_id`, `statut`, `moyenne_generale`, `rang`, `created_at`, `updated_at`) VALUES'),
('(1, 1, 1, 1, \'en_attente\', NULL, NULL, \'2026-06-13 00:46:55\', \'2026-06-13 00:46:55\');'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la table `provinces`'),
('--'),
(NULL),
('DROP TABLE IF EXISTS `provinces`;'),
('CREATE TABLE IF NOT EXISTS `provinces` ('),
('  `id` int NOT NULL AUTO_INCREMENT,'),
('  `nompro` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `cdepro` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,'),
('  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,'),
('  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,'),
('  PRIMARY KEY (`id`)'),
(') ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'),
(NULL),
('--'),
('-- Déchargement des données de la table `provinces`'),
('--'),
(NULL),
('INSERT INTO `provinces` (`id`, `nompro`, `cdepro`, `created_at`, `updated_at`) VALUES'),
('(1, \'Estuaire\', \'EST\', \'2025-10-05 06:14:48\', \'2025-10-05 06:14:48\'),'),
('(2, \'Haut-Ogooué\', \'HO\', \'2025-10-05 06:14:48\', \'2025-10-05 06:14:48\'),'),
('(3, \'Moyen-Ogooué\', \'MO\', \'2025-10-05 06:14:48\', \'2025-10-05 06:14:48\'),'),
('(4, \'Ngounié\', \'NGO\', \'2025-10-05 06:14:48\', \'2025-10-05 06:14:48\'),'),
('(5, \'Nyanga\', \'NYA\', \'2025-10-05 06:14:48\', \'2025-10-05 06:14:48\'),'),
('(6, \'Ogooué-Ivindo\', \'OI\', \'2025-10-05 06:14:48\', \'2025-10-05 06:14:48\'),'),
('(7, \'Ogooué-Lolo\', \'OL\', \'2025-10-05 06:14:48\', \'2025-10-05 06:14:48\'),'),
('(8, \'Ogooué-Maritime\', \'OM\', \'2025-10-05 06:14:48\', \'2025-10-05 06:14:48\'),'),
('(9, \'Woleu-Ntem\', \'WN\', \'2025-10-05 06:14:48\', \'2025-10-05 06:14:48\');'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la table `sessions`'),
('--'),
(NULL),
('DROP TABLE IF EXISTS `sessions`;'),
('CREATE TABLE IF NOT EXISTS `sessions` ('),
('  `id` int NOT NULL AUTO_INCREMENT,'),
('  `candidat_id` int NOT NULL,'),
('  `token` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `expires_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,'),
('  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,'),
('  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,'),
('  PRIMARY KEY (`id`),'),
('  UNIQUE KEY `token` (`token`),'),
('  KEY `candidat_id` (`candidat_id`),'),
('  KEY `idx_token` (`token`),'),
('  KEY `idx_expires_at` (`expires_at`)'),
(') ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'),
(NULL),
('--'),
('-- Déchargement des données de la table `sessions`'),
('--'),
(NULL),
('INSERT INTO `sessions` (`id`, `candidat_id`, `token`, `expires_at`, `created_at`, `updated_at`) VALUES'),
('(1, 1, \'e6a1522a-3676-458c-b566-e637188f84f3\', \'2025-11-08 17:50:05\', \'2025-11-07 18:50:04\', \'2025-11-07 18:50:04\'),'),
('(2, 2, \'08cd2626-0177-41e0-b510-feb613798bbb\', \'2026-04-03 19:28:14\', \'2026-04-02 20:28:14\', \'2026-04-02 20:28:14\'),'),
('(3, 3, \'759eae39-9cf8-4091-8b9b-aebc10718e2f\', \'2026-04-03 22:35:25\', \'2026-04-02 23:35:24\', \'2026-04-02 23:35:24\'),'),
('(4, 4, \'4c161593-e6a4-4f03-b34d-dc27572c1816\', \'2026-04-03 23:04:54\', \'2026-04-03 00:04:54\', \'2026-04-03 00:04:54\'),'),
('(5, 5, \'a1d92aa9-f783-41b1-bd90-8caa9a633fb8\', \'2026-04-03 23:34:55\', \'2026-04-03 00:34:55\', \'2026-04-03 00:34:55\'),'),
('(6, 6, \'4971c6d3-9c06-4072-9e8b-817c1ec9f28f\', \'2026-04-24 22:12:52\', \'2026-04-23 23:12:52\', \'2026-04-23 23:12:52\'),'),
('(7, 9, \'3433a603-84af-48a8-829c-fa2f9f6ecc9b\', \'2026-06-13 17:33:59\', \'2026-06-12 18:33:59\', \'2026-06-12 18:33:59\'),'),
('(8, 10, \'eaa0bb3d-362e-442b-bbb9-7aa628b3fa87\', \'2026-06-13 17:54:22\', \'2026-06-12 18:54:22\', \'2026-06-12 18:54:22\'),'),
('(9, 11, \'3b4cfb2f-7167-4292-9e67-afce6d76cc33\', \'2026-06-13 22:32:25\', \'2026-06-12 23:32:24\', \'2026-06-12 23:32:24\'),'),
('(10, 1, \'c25b1ddb-02b3-4bb1-abb4-a4cf0250765c\', \'2026-06-13 23:47:00\', \'2026-06-13 00:46:59\', \'2026-06-13 00:46:59\');'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la table `support_requests`'),
('--'),
(NULL),
('DROP TABLE IF EXISTS `support_requests`;'),
('CREATE TABLE IF NOT EXISTS `support_requests` ('),
('  `id` int NOT NULL AUTO_INCREMENT,'),
('  `candidat_nupcan` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,'),
('  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `sujet` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `message` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,'),
('  `statut` enum(\'nouveau\',\'en_cours\',\'resolu\',\'ferme\') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT \'nouveau\','),
('  `priorite` enum(\'basse\',\'normale\',\'haute\',\'urgente\') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT \'normale\','),
('  `assigned_to` int DEFAULT NULL COMMENT \'Super admin assigné\','),
('  `createdAt` timestamp NULL DEFAULT CURRENT_TIMESTAMP,'),
('  `updatedAt` timestamp NULL DEFAULT CURRENT_TIMESTAMP,'),
('  `resolved_at` timestamp NULL DEFAULT NULL,'),
('  PRIMARY KEY (`id`),'),
('  KEY `assigned_to` (`assigned_to`),'),
('  KEY `idx_candidat` (`candidat_nupcan`),'),
('  KEY `idx_statut` (`statut`),'),
('  KEY `idx_priorite` (`priorite`)'),
(') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la table `support_responses`'),
('--'),
(NULL),
('DROP TABLE IF EXISTS `support_responses`;'),
('CREATE TABLE IF NOT EXISTS `support_responses` ('),
('  `id` int NOT NULL AUTO_INCREMENT,'),
('  `support_request_id` int NOT NULL,'),
('  `admin_id` int NOT NULL,'),
('  `message` text NOT NULL,'),
('  `is_internal_note` tinyint(1) DEFAULT \'0\','),
('  `createdAt` timestamp NULL DEFAULT CURRENT_TIMESTAMP,'),
('  PRIMARY KEY (`id`),'),
('  KEY `idx_support_request` (`support_request_id`),'),
('  KEY `idx_admin` (`admin_id`)'),
(') ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Doublure de structure pour la vue `vue_candidatures_completes`'),
('-- (Voir ci-dessous la vue réelle)'),
('--'),
('DROP VIEW IF EXISTS `vue_candidatures_completes`;'),
('CREATE TABLE IF NOT EXISTS `vue_candidatures_completes` ('),
('`concours_frais` decimal(10,2)'),
(',`concours_nom` varchar(255)'),
(',`created_at` timestamp'),
(',`dtncan` date'),
(',`etablissement_nom` varchar(255)'),
(',`filiere_nom` varchar(255)'),
(',`id` int'),
(',`ldncan` varchar(255)'),
(',`maican` varchar(255)'),
(',`niveau_nom` varchar(255)'),
(',`nomcan` varchar(255)'),
(',`nupcan` varchar(100)'),
(',`phtcan` varchar(255)'),
(',`prncan` varchar(255)'),
(',`statut` enum(\'en_attente\',\'valide\',\'rejete\')'),
(',`telcan` varchar(20)'),
(');'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Doublure de structure pour la vue `vue_stats_etablissements`'),
('-- (Voir ci-dessous la vue réelle)'),
('--'),
('DROP VIEW IF EXISTS `vue_stats_etablissements`;'),
('CREATE TABLE IF NOT EXISTS `vue_stats_etablissements` ('),
('`id` int'),
(',`nb_candidatures` bigint'),
(',`nb_concours` bigint'),
(',`nb_en_attente` bigint'),
(',`nb_rejetees` bigint'),
(',`nb_validees` bigint'),
(',`nomets` varchar(255)'),
(');'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Doublure de structure pour la vue `v_admin_activity`'),
('-- (Voir ci-dessous la vue réelle)'),
('--'),
('DROP VIEW IF EXISTS `v_admin_activity`;'),
('CREATE TABLE IF NOT EXISTS `v_admin_activity` ('),
('`derniere_action` timestamp'),
(',`id` int'),
(',`nom` varchar(100)'),
(',`prenom` varchar(100)'),
(',`role` enum(\'super_admin\',\'admin_etablissement\',\'sub_admin\')'),
(',`total_actions` bigint'),
(');'),
(NULL);
INSERT INTO `gabconcours` (`C1`) VALUES
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Doublure de structure pour la vue `v_documents_stats`'),
('-- (Voir ci-dessous la vue réelle)'),
('--'),
('DROP VIEW IF EXISTS `v_documents_stats`;'),
('CREATE TABLE IF NOT EXISTS `v_documents_stats` ('),
(');'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Doublure de structure pour la vue `v_messages_stats`'),
('-- (Voir ci-dessous la vue réelle)'),
('--'),
('DROP VIEW IF EXISTS `v_messages_stats`;'),
('CREATE TABLE IF NOT EXISTS `v_messages_stats` ('),
('`candidats_uniques` bigint'),
(',`expediteur` enum(\'candidat\',\'admin\')'),
(',`statut` enum(\'lu\',\'non_lu\')'),
(',`total` bigint'),
(');'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la vue `compose`'),
('--'),
('DROP TABLE IF EXISTS `compose`;'),
(NULL),
('DROP VIEW IF EXISTS `compose`;'),
('CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `compose`  AS SELECT `n`.`id` AS `id`, `n`.`candidat_id` AS `candidat_id`, `n`.`concours_id` AS `concours_id`, `n`.`matiere_id` AS `matiere_id`, `n`.`note` AS `notcomp`, `n`.`coefficient` AS `coefficient`, `c`.`nomcan` AS `nomcan`, `c`.`prncan` AS `prncan`, `co`.`libcnc` AS `concours_nom`, `m`.`nom_matiere` AS `nom_matiere` FROM (((`notes` `n` join `candidats` `c` on((`n`.`candidat_id` = `c`.`id`))) join `concours` `co` on((`n`.`concours_id` = `co`.`id`))) join `matieres` `m` on((`n`.`matiere_id` = `m`.`id`))) ;'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la vue `vue_candidatures_completes`'),
('--'),
('DROP TABLE IF EXISTS `vue_candidatures_completes`;'),
(NULL),
('DROP VIEW IF EXISTS `vue_candidatures_completes`;'),
('CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vue_candidatures_completes`  AS SELECT `c`.`id` AS `id`, `c`.`nupcan` AS `nupcan`, `c`.`nomcan` AS `nomcan`, `c`.`prncan` AS `prncan`, `c`.`maican` AS `maican`, `c`.`telcan` AS `telcan`, `c`.`dtncan` AS `dtncan`, `c`.`ldncan` AS `ldncan`, `c`.`phtcan` AS `phtcan`, `c`.`statut` AS `statut`, `c`.`created_at` AS `created_at`, `co`.`libcnc` AS `concours_nom`, `co`.`fracnc` AS `concours_frais`, `f`.`nomfil` AS `filiere_nom`, `e`.`nomets` AS `etablissement_nom`, `n`.`nomniv` AS `niveau_nom` FROM ((((`candidats` `c` left join `concours` `co` on((`c`.`concours_id` = `co`.`id`))) left join `filieres` `f` on((`c`.`filiere_id` = `f`.`id`))) left join `etablissements` `e` on((`co`.`etablissement_id` = `e`.`id`))) left join `niveaux` `n` on((`c`.`niveau_id` = `n`.`id`))) ;'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la vue `vue_stats_etablissements`'),
('--'),
('DROP TABLE IF EXISTS `vue_stats_etablissements`;'),
(NULL),
('DROP VIEW IF EXISTS `vue_stats_etablissements`;'),
('CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vue_stats_etablissements`  AS SELECT `e`.`id` AS `id`, `e`.`nomets` AS `nomets`, count(distinct `co`.`id`) AS `nb_concours`, count(distinct `c`.`id`) AS `nb_candidatures`, count((case when (`c`.`statut` = \'valide\') then 1 end)) AS `nb_validees`, count((case when (`c`.`statut` = \'en_attente\') then 1 end)) AS `nb_en_attente`, count((case when (`c`.`statut` = \'rejete\') then 1 end)) AS `nb_rejetees` FROM ((`etablissements` `e` left join `concours` `co` on((`e`.`id` = `co`.`etablissement_id`))) left join `candidats` `c` on((`co`.`id` = `c`.`concours_id`))) GROUP BY `e`.`id`, `e`.`nomets` ;'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la vue `v_admin_activity`'),
('--'),
('DROP TABLE IF EXISTS `v_admin_activity`;'),
(NULL),
('DROP VIEW IF EXISTS `v_admin_activity`;'),
('CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_admin_activity`  AS SELECT `a`.`id` AS `id`, `a`.`nom` AS `nom`, `a`.`prenom` AS `prenom`, `a`.`role` AS `role`, count(distinct `aa`.`id`) AS `total_actions`, max(`aa`.`created_at`) AS `derniere_action` FROM (`administrateurs` `a` left join `admin_actions` `aa` on((`a`.`id` = `aa`.`admin_id`))) GROUP BY `a`.`id`, `a`.`nom`, `a`.`prenom`, `a`.`role` ;'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la vue `v_documents_stats`'),
('--'),
('DROP TABLE IF EXISTS `v_documents_stats`;'),
(NULL),
('DROP VIEW IF EXISTS `v_documents_stats`;'),
('CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_documents_stats`  AS SELECT `d`.`statut` AS `statut`, count(0) AS `total`, count(distinct `dos`.`nipcan`) AS `candidats_concernes` FROM (`documents` `d` left join `dossiers` `dos` on((`d`.`id` = `dos`.`document_id`))) GROUP BY `d`.`statut` ;'),
(NULL),
('-- --------------------------------------------------------'),
(NULL),
('--'),
('-- Structure de la vue `v_messages_stats`'),
('--'),
('DROP TABLE IF EXISTS `v_messages_stats`;'),
(NULL),
('DROP VIEW IF EXISTS `v_messages_stats`;'),
('CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_messages_stats`  AS SELECT `messages`.`expediteur` AS `expediteur`, `messages`.`statut` AS `statut`, count(0) AS `total`, count(distinct `messages`.`candidat_nupcan`) AS `candidats_uniques` FROM `messages` GROUP BY `messages`.`expediteur`, `messages`.`statut` ;'),
(NULL),
('--'),
('-- Contraintes pour les tables déchargées'),
('--'),
(NULL),
('--'),
('-- Contraintes pour la table `administrateurs`'),
('--'),
('ALTER TABLE `administrateurs`'),
('  ADD CONSTRAINT `administrateurs_ibfk_1` FOREIGN KEY (`etablissement_id`) REFERENCES `etablissements` (`id`) ON DELETE SET NULL,'),
('  ADD CONSTRAINT `administrateurs_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `administrateurs` (`id`) ON DELETE SET NULL;'),
(NULL),
('--'),
('-- Contraintes pour la table `admin_actions`'),
('--'),
('ALTER TABLE `admin_actions`'),
('  ADD CONSTRAINT `admin_actions_ibfk_1` FOREIGN KEY (`admin_id`) REFERENCES `administrateurs` (`id`) ON DELETE CASCADE;'),
(NULL),
('--'),
('-- Contraintes pour la table `admin_logs`'),
('--'),
('ALTER TABLE `admin_logs`'),
('  ADD CONSTRAINT `fk_log_admin` FOREIGN KEY (`admin_id`) REFERENCES `administrateurs` (`id`) ON DELETE CASCADE;'),
(NULL),
('--'),
('-- Contraintes pour la table `candidats`'),
('--'),
('ALTER TABLE `candidats`'),
('  ADD CONSTRAINT `candidats_ibfk_1` FOREIGN KEY (`niveau_id`) REFERENCES `niveaux` (`id`) ON DELETE SET NULL,'),
('  ADD CONSTRAINT `candidats_ibfk_2` FOREIGN KEY (`concours_id`) REFERENCES `concours` (`id`) ON DELETE SET NULL,'),
('  ADD CONSTRAINT `candidats_ibfk_3` FOREIGN KEY (`filiere_id`) REFERENCES `filieres` (`id`) ON DELETE SET NULL;'),
(NULL),
('--'),
('-- Contraintes pour la table `concours`'),
('--'),
('ALTER TABLE `concours`'),
('  ADD CONSTRAINT `fk_concours_etablissement` FOREIGN KEY (`etablissement_id`) REFERENCES `etablissements` (`id`) ON DELETE SET NULL,'),
('  ADD CONSTRAINT `fk_concours_niveau` FOREIGN KEY (`niveau_id`) REFERENCES `niveaux` (`id`) ON DELETE SET NULL;'),
(NULL),
('--'),
('-- Contraintes pour la table `concours_filieres`'),
('--'),
('ALTER TABLE `concours_filieres`'),
('  ADD CONSTRAINT `concours_filieres_ibfk_1` FOREIGN KEY (`concours_id`) REFERENCES `concours` (`id`) ON DELETE CASCADE,'),
('  ADD CONSTRAINT `concours_filieres_ibfk_2` FOREIGN KEY (`filiere_id`) REFERENCES `filieres` (`id`) ON DELETE CASCADE;'),
(NULL),
('--'),
('-- Contraintes pour la table `documents`'),
('--'),
('ALTER TABLE `documents`'),
('  ADD CONSTRAINT `documents_ibfk_1` FOREIGN KEY (`candidat_id`) REFERENCES `candidats` (`id`) ON DELETE CASCADE,'),
('  ADD CONSTRAINT `documents_ibfk_2` FOREIGN KEY (`concours_id`) REFERENCES `concours` (`id`) ON DELETE CASCADE;'),
(NULL),
('--'),
('-- Contraintes pour la table `dossiers`'),
('--'),
('ALTER TABLE `dossiers`'),
('  ADD CONSTRAINT `dossiers_ibfk_1` FOREIGN KEY (`candidat_id`) REFERENCES `candidats` (`id`) ON DELETE CASCADE,'),
('  ADD CONSTRAINT `dossiers_ibfk_2` FOREIGN KEY (`concours_id`) REFERENCES `concours` (`id`) ON DELETE CASCADE,'),
('  ADD CONSTRAINT `dossiers_ibfk_3` FOREIGN KEY (`document_id`) REFERENCES `documents` (`id`) ON DELETE CASCADE;'),
(NULL),
('--'),
('-- Contraintes pour la table `etablissements`'),
('--'),
('ALTER TABLE `etablissements`'),
('  ADD CONSTRAINT `etablissements_ibfk_1` FOREIGN KEY (`province_id`) REFERENCES `provinces` (`id`) ON DELETE SET NULL;'),
(NULL),
('--'),
('-- Contraintes pour la table `filieres`'),
('--'),
('ALTER TABLE `filieres`'),
('  ADD CONSTRAINT `filieres_ibfk_1` FOREIGN KEY (`niveau_id`) REFERENCES `niveaux` (`id`) ON DELETE SET NULL;'),
(NULL),
('--'),
('-- Contraintes pour la table `filiere_matieres`'),
('--'),
('ALTER TABLE `filiere_matieres`'),
('  ADD CONSTRAINT `filiere_matieres_ibfk_1` FOREIGN KEY (`filiere_id`) REFERENCES `filieres` (`id`) ON DELETE CASCADE,'),
('  ADD CONSTRAINT `filiere_matieres_ibfk_2` FOREIGN KEY (`matiere_id`) REFERENCES `matieres` (`id`) ON DELETE CASCADE;'),
(NULL),
('--'),
('-- Contraintes pour la table `messages`'),
('--'),
('ALTER TABLE `messages`'),
('  ADD CONSTRAINT `fk_message_admin` FOREIGN KEY (`admin_id`) REFERENCES `administrateurs` (`id`) ON DELETE SET NULL,'),
('  ADD CONSTRAINT `fk_message_parent` FOREIGN KEY (`parent_id`) REFERENCES `messages` (`id`) ON DELETE CASCADE;'),
(NULL),
('--'),
('-- Contraintes pour la table `paiements`'),
('--'),
('ALTER TABLE `paiements`'),
('  ADD CONSTRAINT `paiements_ibfk_1` FOREIGN KEY (`candidat_id`) REFERENCES `candidats` (`id`) ON DELETE SET NULL,'),
('  ADD CONSTRAINT `paiements_ibfk_2` FOREIGN KEY (`concours_id`) REFERENCES `concours` (`id`) ON DELETE SET NULL;'),
(NULL),
('--'),
('-- Contraintes pour la table `participations`'),
('--'),
('ALTER TABLE `participations`'),
('  ADD CONSTRAINT `participations_ibfk_1` FOREIGN KEY (`candidat_id`) REFERENCES `candidats` (`id`) ON DELETE CASCADE,'),
('  ADD CONSTRAINT `participations_ibfk_2` FOREIGN KEY (`concours_id`) REFERENCES `concours` (`id`) ON DELETE CASCADE,'),
('  ADD CONSTRAINT `participations_ibfk_3` FOREIGN KEY (`filiere_id`) REFERENCES `filieres` (`id`) ON DELETE CASCADE;'),
(NULL),
('--'),
('-- Contraintes pour la table `sessions`'),
('--'),
('ALTER TABLE `sessions`'),
('  ADD CONSTRAINT `sessions_ibfk_1` FOREIGN KEY (`candidat_id`) REFERENCES `candidats` (`id`) ON DELETE CASCADE;'),
(NULL),
('--'),
('-- Contraintes pour la table `support_requests`'),
('--'),
('ALTER TABLE `support_requests`'),
('  ADD CONSTRAINT `support_requests_ibfk_1` FOREIGN KEY (`assigned_to`) REFERENCES `administrateurs` (`id`) ON DELETE SET NULL;'),
('COMMIT;'),
(NULL),
('/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;'),
('/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;'),
('/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;');

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
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `matieres`
--

INSERT INTO `matieres` (`id`, `nom_matiere`, `coefficient`, `duree`, `description`, `created_at`, `updated_at`) VALUES
(1, 'Anglais', 3.0, NULL, NULL, '2025-11-07 18:26:33', '2025-11-07 18:26:33'),
(2, 'MATHS', 1.0, 2, '', '2026-06-16 21:32:56', '2026-06-16 21:32:56');

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
  `pieces_jointes` json DEFAULT NULL,
  `expediteur` enum('candidat','admin') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `statut` enum('lu','non_lu') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'non_lu',
  `parent_message_id` int DEFAULT NULL,
  `parent_id` int DEFAULT NULL COMMENT 'Pour les réponses',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `candidat_nupcan` (`candidat_nupcan`),
  KEY `admin_id` (`admin_id`),
  KEY `parent_id` (`parent_id`),
  KEY `statut` (`statut`),
  KEY `idx_message_statut_expediteur` (`statut`,`expediteur`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `messages`
--

INSERT INTO `messages` (`id`, `candidat_nupcan`, `admin_id`, `sujet`, `message`, `pieces_jointes`, `expediteur`, `statut`, `parent_message_id`, `parent_id`, `created_at`, `updated_at`) VALUES
(1, '20251107-1', NULL, 'Documents', 'Je n\'arrive pas à televerser mes documents rejetés', NULL, 'candidat', 'non_lu', NULL, NULL, '2025-11-07 19:42:55', '2025-11-07 19:42:55'),
(2, '20260614-1', NULL, 'Attestation', 'Erreur lors de la requête vers /document-validation/2: \nObject { message: \"Request failed with status code 500\", name: \"AxiosError\", code: \"ERR_BAD_RESPONSE\", config: {…}, request: XMLHttpRequest, response: {…}, status: 500, stack: \"\", … }\napi.ts:79:21\nAdminDocumentService: Erreur validation document: Error: Erreur lors de la validation du document\n    validateDocument adminDocumentService.ts:67\nadminDocumentService.ts:74:21\n    validateDocument adminDocumentService.ts:74\nAdminDocumentService: Validation document: 2 valide adminDocumentService.ts:64:21\nErreur lors de la requête vers /document-validation/2: \nObject { message: \"Request failed with status code 500\", name: \"AxiosError\", code: \"ERR_BAD_RESPONSE\", config: {…}, request: XMLHttpRequest, response: {…}, status: 500, stack: \"\", … }\napi.ts:79:21\nAdminDocumentService: Erreur validation document: Error: Erreur lors de la validation du document\n    validateDocument adminDocumentService.ts:67', NULL, 'candidat', 'lu', NULL, NULL, '2026-06-16 14:11:09', '2026-06-16 14:11:55'),
(3, '20260614-1', NULL, 'at', '\nErreur validation document: Error: Column count doesn\'t match value count at row 1\n    at PromisePool.execute (C:\\Users\\LENOVO\\OneDrive\\Pictures\\gabonconcoursv2-main\\gabonconcoursv2-main\\backend\\node_modules\\mysql2\\lib\\promise\\pool.js:54:22)\n    at C:\\Users\\LENOVO\\OneDrive\\Pictures\\gabonconcoursv2-main\\gabonconcoursv2-main\\backend\\routes\\documentValidation.js:54:45\n    at process.processTicksAndRejections (node:internal/process/task_queues:105:5) {\n  code: \'ER_WRONG_VALUE_COUNT_ON_ROW\',\n  errno: 1136,\n  sql: \'\\n\' +\n    \'      UPDATE documents \\n\' +\n    \'      SET statut = ?, commentaire_validation = ?, validated_by = ?, validated_at = NOW(), updated_at = NOW()\\n\' +\n    \'      WHERE id = ?\\n\' +\n    \'    \',\n  sqlState: \'21S01\',\n  sqlMessage: \"Column count doesn\'t match value count at row 1\"\n}\n', NULL, 'candidat', 'lu', NULL, NULL, '2026-06-16 14:38:10', '2026-06-16 14:38:35');

--
-- Déclencheurs `messages`
--
DROP TRIGGER IF EXISTS `after_admin_message_response`;
DELIMITER $$
CREATE TRIGGER `after_admin_message_response` AFTER INSERT ON `messages` FOR EACH ROW BEGIN
  IF NEW.expediteur = 'admin' THEN
    INSERT INTO notifications (
      user_type,
      user_id,
      type,
      titre,
      message,
      action_url,
      priority
    ) VALUES (
      'candidat',
      NEW.candidat_nupcan,
      'message',
      'Nouvelle réponse à votre message',
      CONCAT('Vous avez reçu une réponse concernant: ', NEW.sujet),
      '/candidat/messages',
      'high'
    );
    
    INSERT INTO admin_actions (
      admin_id,
      action_type,
      entity_type,
      entity_id,
      candidat_nupcan,
      description
    ) VALUES (
      NEW.admin_id,
      'reponse_message',
      'message',
      NEW.id,
      NEW.candidat_nupcan,
      CONCAT('Réponse au message: ', NEW.sujet)
    );
  END IF;
END
$$
DELIMITER ;

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
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `year` (`year`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `nipcan_counters`
--

INSERT INTO `nipcan_counters` (`id`, `year`, `counter`, `created_at`, `updated_at`) VALUES
(1, 2026, 9, '2026-04-02 23:35:21', '2026-07-07 13:57:38');

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
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
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
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_note` (`candidat_id`,`concours_id`,`matiere_id`),
  KEY `idx_candidat` (`candidat_id`),
  KEY `idx_concours` (`concours_id`),
  KEY `idx_matiere` (`matiere_id`)
) ENGINE=MyISAM AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `notes`
--

INSERT INTO `notes` (`id`, `candidat_id`, `concours_id`, `matiere_id`, `note`, `coefficient`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 1, 15.00, 3.0, '2025-11-07 19:41:19', '2026-06-16 22:08:40'),
(2, 2, 1, 1, 15.00, 3.0, '2026-06-16 15:45:20', '2026-06-16 22:08:40'),
(3, 2, 1, 2, 2.00, 5.0, '2026-06-16 21:34:47', '2026-06-16 22:08:40'),
(4, 5, 1, 1, 15.00, 3.0, '2026-07-07 13:34:01', '2026-07-07 13:34:01'),
(5, 5, 1, 2, 16.00, 5.0, '2026-07-07 13:34:01', '2026-07-07 13:34:01');

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
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `priority` enum('low','normal','high') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'normal',
  PRIMARY KEY (`id`),
  KEY `idx_nupcan` (`candidat_nupcan`),
  KEY `idx_statut` (`statut`),
  KEY `idx_created_at` (`created_at`),
  KEY `idx_notifications_date` (`candidat_nupcan`,`created_at`),
  KEY `idx_candidat` (`candidat_id`),
  KEY `idx_reference` (`reference_type`,`reference_id`)
) ENGINE=InnoDB AUTO_INCREMENT=40 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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
(27, '20260613-1', NULL, 'document_validation', 'Document validé', 'Votre document \"Proposition technique et financiere LAPADI.pdf\" a été validé.', NULL, NULL, 'non_lu', '2026-06-13 00:15:29', '2026-06-13 00:15:29', 'normal'),
(28, '20260614-1', NULL, 'document_validation', 'Document validé', 'Votre document \"Attestation\" a été validé.', NULL, NULL, 'non_lu', '2026-06-16 15:39:06', '2026-06-16 15:39:06', 'normal'),
(29, '20260614-1', NULL, 'document_validation', 'Document validé', 'Votre document \"Attestation\" a été validé avec succès.', NULL, NULL, 'non_lu', '2026-06-16 15:39:06', '2026-06-16 15:39:06', 'normal'),
(30, '20260619-1', NULL, 'document_validation', 'Document validé', 'Votre document \"Attestation \" a été validé.', NULL, NULL, 'non_lu', '2026-06-19 23:03:32', '2026-06-19 23:03:32', 'normal'),
(31, '20260619-1', NULL, 'document_validation', 'Document validé', 'Votre document \"Attestation \" a été validé avec succès.', NULL, NULL, 'non_lu', '2026-06-19 23:03:32', '2026-06-19 23:03:32', 'normal'),
(32, '20260620-1', NULL, 'document_validation', 'Document validé', 'Votre document \"Attestation \" a été validé.', NULL, NULL, 'non_lu', '2026-06-20 09:44:31', '2026-06-20 09:44:31', 'normal'),
(33, '20260620-1', NULL, 'document_validation', 'Document validé', 'Votre document \"Attestation \" a été validé avec succès.', NULL, NULL, 'non_lu', '2026-06-20 09:44:31', '2026-06-20 09:44:31', 'normal'),
(34, '', 4, 'paiement', 'Paiement confirmé', 'Votre paiement de 550.00 FCFA a été validé. Votre reçu est disponible dans votre espace candidat.', NULL, NULL, '', '2026-06-20 09:44:54', '2026-06-20 09:44:54', 'normal'),
(35, '20260707-1', NULL, 'document_validation', 'Document validé', 'Votre document \"Attestation \" a été validé.', NULL, NULL, 'non_lu', '2026-07-07 12:03:08', '2026-07-07 12:03:08', 'normal'),
(36, '20260707-1', NULL, 'document_validation', 'Document validé', 'Votre document \"Attestation \" a été validé avec succès.', NULL, NULL, 'non_lu', '2026-07-07 12:03:08', '2026-07-07 12:03:08', 'normal'),
(37, '', 5, 'paiement', 'Paiement confirmé', 'Votre paiement de 100.00 FCFA a été validé. Votre reçu est disponible dans votre espace candidat.', NULL, NULL, '', '2026-07-07 12:53:24', '2026-07-07 12:53:24', 'normal'),
(38, '', 5, 'resultats', 'Bulletin de notes disponible', 'Votre bulletin de notes pour concours d\'entrée à BBS est maintenant disponible. Moyenne: 15.63/20', NULL, NULL, '', '2026-07-07 13:34:08', '2026-07-07 13:34:08', 'normal'),
(39, '', 5, 'resultats', 'Bulletin de notes disponible', 'Votre bulletin de notes pour concours d\'entrée à BBS est maintenant disponible. Moyenne: 15.63/20', NULL, NULL, '', '2026-07-07 13:46:30', '2026-07-07 13:46:30', 'normal');

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
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `date_key` (`date_key`)
) ENGINE=MyISAM AUTO_INCREMENT=11 DEFAULT CHARSET=latin1;

--
-- Déchargement des données de la table `nupcan_counters`
--

INSERT INTO `nupcan_counters` (`id`, `date_key`, `counter`, `created_at`, `updated_at`) VALUES
(1, '20251107', 1, '2025-11-07 18:50:00', '2025-11-07 18:50:00'),
(2, '20260402', 1, '2026-04-02 20:28:14', '2026-04-02 20:28:14'),
(3, '20260403', 3, '2026-04-02 23:35:21', '2026-04-03 00:34:52'),
(4, '20260424', 3, '2026-04-23 23:12:49', '2026-04-24 01:11:28'),
(5, '20260612', 2, '2026-06-12 18:33:55', '2026-06-12 18:54:19'),
(6, '20260613', 2, '2026-06-12 23:32:21', '2026-06-13 00:46:55'),
(7, '20260614', 1, '2026-06-14 22:41:07', '2026-06-14 22:41:07'),
(8, '20260619', 1, '2026-06-19 22:57:50', '2026-06-19 22:57:50'),
(9, '20260620', 1, '2026-06-20 09:42:10', '2026-06-20 09:42:10'),
(10, '20260707', 2, '2026-07-07 11:58:58', '2026-07-07 13:57:38');

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
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_nipcan` (`nupcan`),
  KEY `idx_statut` (`statut`),
  KEY `idx_paiements_candidat_statut` (`candidat_id`,`statut`),
  KEY `idx_nupcan` (`nupcan`),
  KEY `idx_candidat_id` (`candidat_id`),
  KEY `idx_concours_id` (`concours_id`),
  KEY `idx_paiement_statut` (`statut`)
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `paiements`
--

INSERT INTO `paiements` (`id`, `candidat_id`, `concours_id`, `nupcan`, `montant`, `methode`, `statut`, `reference_paiement`, `numero_telephone`, `recu_path`, `created_at`, `updated_at`) VALUES
(1, 2, 1, '20260614-1', 20000.00, 'moov', 'valide', 'PAY-1781624422468', '060189503', '/uploads/recus/recu_20260614-1_1781624424186.pdf', '2026-06-16 15:40:22', '2026-06-16 15:40:24'),
(2, 3, 1, '20260619-1', 20000.00, 'moov', 'rejete', 'GABC-202606191-1781910244256-10F7E032', '060189503', NULL, '2026-06-19 23:04:04', '2026-06-19 23:04:04'),
(3, 3, 1, '20260619-1', 20000.00, 'moov', 'rejete', 'GABC-202606191-1781910256894-49F8FEA4', '060189503', NULL, '2026-06-19 23:04:16', '2026-06-19 23:04:16'),
(4, 3, 1, '20260619-1', 20000.00, 'moov', 'rejete', 'GABC-202606191-1781911092871-3D786A95', '060189503', NULL, '2026-06-19 23:18:12', '2026-06-19 23:18:14'),
(5, 3, 1, '20260619-1', 20000.00, 'airtel_money', 'rejete', 'GABC-202606191-1781912227915-9E218EDA', '074604327', NULL, '2026-06-19 23:37:07', '2026-06-19 23:37:09'),
(6, 3, 1, '20260619-1', 20000.00, 'airtel_money', 'rejete', 'GABC-202606191-1781912369816-27D7D774', '074604327', NULL, '2026-06-19 23:39:29', '2026-06-19 23:39:30'),
(7, 3, 1, '20260619-1', 20000.00, 'airtel_money', 'rejete', 'GABC-202606191-1781913120990-C3F2D18A', '074604327', NULL, '2026-06-19 23:52:01', '2026-06-19 23:52:02'),
(8, 3, 1, '20260619-1', 100.00, 'mypvit_airtel_money', 'rejete', 'GCMQLVAKMTCA78', '074604327', NULL, '2026-06-20 04:38:22', '2026-06-20 04:38:23'),
(9, 3, 1, '20260619-1', 550.00, 'mypvit_airtel_money', 'rejete', 'GCMQLVFGI400DD', '074604327', NULL, '2026-06-20 04:42:09', '2026-06-20 04:42:11'),
(10, 3, 1, '20260619-1', 550.00, 'mypvit_airtel_money', 'rejete', 'GCMQLVHOMT8599', '074604327', NULL, '2026-06-20 04:43:53', '2026-06-20 04:43:55'),
(11, 3, 1, '20260619-1', 550.00, 'mypvit_airtel_money', 'rejete', 'GCMQLVIRFH5A00', '074383720', NULL, '2026-06-20 04:44:43', '2026-06-20 04:44:44'),
(12, 3, 1, '20260619-1', 550.00, 'mypvit_moov', 'rejete', 'GCMQLVJ5GV7BB7', '060189503', NULL, '2026-06-20 04:45:02', '2026-06-20 04:45:02'),
(13, 3, 1, '20260619-1', 550.00, 'mypvit_moov', 'valide', 'GCMQLVN3UD0FA2', '060189503', '/uploads/recus/recu_20260619-1_1781932267953.pdf', '2026-06-20 04:48:06', '2026-06-20 05:11:08'),
(14, 4, 1, '20260620-1', 550.00, 'mypvit_airtel_money', 'valide', 'GCMQM68K0REF13', '074604327', '/uploads/recus/recu_20260620-1_1781948688996.pdf', '2026-06-20 09:44:43', '2026-06-20 09:44:49'),
(15, 5, 1, '20260707-1', 550.00, 'mypvit_airtel_money', 'rejete', 'GCMRALOS7DC02C', '074604327', NULL, '2026-07-07 12:03:43', '2026-07-07 12:03:44'),
(16, 5, 1, '20260707-1', 550.00, 'airtel_money', 'rejete', 'GCMRALUYLZF27C', '074604327', NULL, '2026-07-07 12:08:31', '2026-07-07 12:08:33'),
(17, 5, 1, '20260707-1', 550.00, 'airtel_money', 'rejete', 'GCMRAM1NPJ859A', '074604327', NULL, '2026-07-07 12:13:43', '2026-07-07 12:13:45'),
(18, 5, 1, '20260707-1', 550.00, 'airtel_money', 'rejete', 'GCMRAM2JU08630', '074604327', NULL, '2026-07-07 12:14:25', '2026-07-07 12:14:26'),
(19, 5, 1, '20260707-1', 550.00, 'airtel_money', 'rejete', 'GCMRAMHQ736F5D', '074604327', NULL, '2026-07-07 12:26:13', '2026-07-07 12:38:33'),
(20, 5, 1, '20260707-1', 100.00, 'airtel_money', 'rejete', 'GCMRANFKOX8082', '074604327', NULL, '2026-07-07 12:52:32', '2026-07-07 12:52:49'),
(21, 5, 1, '20260707-1', 100.00, 'airtel_money', 'valide', 'GCMRANG9OEB615', '074604327', '/uploads/recus/recu_20260707-1_1783428803261.pdf', '2026-07-07 12:53:05', '2026-07-07 12:53:23');

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
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_participation` (`candidat_id`,`concours_id`),
  KEY `filiere_id` (`filiere_id`),
  KEY `idx_concours` (`concours_id`),
  KEY `idx_statut` (`statut`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `participations`
--

INSERT INTO `participations` (`id`, `candidat_id`, `concours_id`, `filiere_id`, `statut`, `moyenne_generale`, `rang`, `created_at`, `updated_at`) VALUES
(1, 1, 1, 1, 'en_attente', NULL, NULL, '2026-06-13 00:46:55', '2026-06-13 00:46:55'),
(2, 2, 1, 1, 'en_attente', NULL, NULL, '2026-06-14 22:41:08', '2026-06-14 22:41:08'),
(4, 3, 1, 1, 'en_attente', NULL, NULL, '2026-06-19 22:57:50', '2026-06-19 22:57:50'),
(6, 4, 1, 1, 'en_attente', NULL, NULL, '2026-06-20 09:42:10', '2026-06-20 09:42:10'),
(8, 5, 1, 1, 'en_attente', NULL, NULL, '2026-07-07 11:58:58', '2026-07-07 11:58:58'),
(10, 6, 1, 1, 'en_attente', NULL, NULL, '2026-07-07 13:57:38', '2026-07-07 13:57:38');

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
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
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
  `token` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `expires_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `token` (`token`),
  KEY `candidat_id` (`candidat_id`),
  KEY `idx_token` (`token`),
  KEY `idx_expires_at` (`expires_at`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `sessions`
--

INSERT INTO `sessions` (`id`, `candidat_id`, `token`, `expires_at`, `created_at`, `updated_at`) VALUES
(1, 1, 'e6a1522a-3676-458c-b566-e637188f84f3', '2025-11-08 17:50:05', '2025-11-07 18:50:04', '2025-11-07 18:50:04'),
(2, 2, '08cd2626-0177-41e0-b510-feb613798bbb', '2026-04-03 19:28:14', '2026-04-02 20:28:14', '2026-04-02 20:28:14'),
(3, 3, '759eae39-9cf8-4091-8b9b-aebc10718e2f', '2026-04-03 22:35:25', '2026-04-02 23:35:24', '2026-04-02 23:35:24'),
(4, 4, '4c161593-e6a4-4f03-b34d-dc27572c1816', '2026-04-03 23:04:54', '2026-04-03 00:04:54', '2026-04-03 00:04:54'),
(5, 5, 'a1d92aa9-f783-41b1-bd90-8caa9a633fb8', '2026-04-03 23:34:55', '2026-04-03 00:34:55', '2026-04-03 00:34:55'),
(6, 6, '4971c6d3-9c06-4072-9e8b-817c1ec9f28f', '2026-04-24 22:12:52', '2026-04-23 23:12:52', '2026-04-23 23:12:52'),
(7, 9, '3433a603-84af-48a8-829c-fa2f9f6ecc9b', '2026-06-13 17:33:59', '2026-06-12 18:33:59', '2026-06-12 18:33:59'),
(8, 10, 'eaa0bb3d-362e-442b-bbb9-7aa628b3fa87', '2026-06-13 17:54:22', '2026-06-12 18:54:22', '2026-06-12 18:54:22'),
(9, 11, '3b4cfb2f-7167-4292-9e67-afce6d76cc33', '2026-06-13 22:32:25', '2026-06-12 23:32:24', '2026-06-12 23:32:24'),
(10, 1, 'c25b1ddb-02b3-4bb1-abb4-a4cf0250765c', '2026-06-13 23:47:00', '2026-06-13 00:46:59', '2026-06-13 00:46:59'),
(11, 2, '6d1aa1ab-74f6-477c-bde9-ded53a50eed2', '2026-06-15 21:41:30', '2026-06-14 22:41:29', '2026-06-14 22:41:29'),
(12, 3, '4689a60b-88ce-4475-9122-c1f2434417ff', '2026-06-20 21:58:12', '2026-06-19 22:58:11', '2026-06-19 22:58:11'),
(13, 4, '0fb44ab8-d525-4a98-b4cc-090f835207f0', '2026-06-21 08:42:35', '2026-06-20 09:42:34', '2026-06-20 09:42:34'),
(14, 5, '848814a2-35d3-448b-9896-db85b7f1d10a', '2026-07-08 10:59:00', '2026-07-07 11:59:00', '2026-07-07 11:59:00'),
(15, 6, '1782ff10-49b1-4dca-a102-199aee0b2f01', '2026-07-08 12:57:41', '2026-07-07 13:57:41', '2026-07-07 13:57:41');

-- --------------------------------------------------------

--
-- Structure de la table `support_requests`
--

DROP TABLE IF EXISTS `support_requests`;
CREATE TABLE IF NOT EXISTS `support_requests` (
  `id` int NOT NULL AUTO_INCREMENT,
  `candidat_nupcan` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `sujet` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `message` text CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `statut` enum('nouveau','en_cours','resolu','ferme') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'nouveau',
  `priorite` enum('basse','normale','haute','urgente') CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT 'normale',
  `assigned_to` int DEFAULT NULL COMMENT 'Super admin assigné',
  `createdAt` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `resolved_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `assigned_to` (`assigned_to`),
  KEY `idx_candidat` (`candidat_nupcan`),
  KEY `idx_statut` (`statut`),
  KEY `idx_priorite` (`priorite`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Déchargement des données de la table `support_requests`
--

INSERT INTO `support_requests` (`id`, `candidat_nupcan`, `email`, `name`, `sujet`, `message`, `statut`, `priorite`, `assigned_to`, `createdAt`, `updatedAt`, `resolved_at`) VALUES
(1, NULL, 'mb.daniel241@gmail.com', 'panorama des systèmes d\'informations : securisation d\'une infrastructure Active Directory', '', 'panorama des systèmes d\'informations : securisation d\'une infrastructure Active Directory', 'nouveau', 'normale', NULL, '2026-06-15 14:55:01', '2026-06-15 15:55:01', NULL);

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
) ENGINE=MyISAM DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- --------------------------------------------------------

--
-- Doublure de structure pour la vue `vue_candidatures_completes`
-- (Voir ci-dessous la vue réelle)
--
DROP VIEW IF EXISTS `vue_candidatures_completes`;
CREATE TABLE IF NOT EXISTS `vue_candidatures_completes` (
`id` int
,`nupcan` varchar(100)
,`nomcan` varchar(255)
,`prncan` varchar(255)
,`maican` varchar(255)
,`telcan` varchar(20)
,`dtncan` date
,`ldncan` varchar(255)
,`phtcan` varchar(255)
,`statut` enum('en_attente','valide','rejete')
,`created_at` timestamp
,`concours_nom` varchar(255)
,`concours_frais` decimal(10,2)
,`filiere_nom` varchar(255)
,`etablissement_nom` varchar(255)
,`niveau_nom` varchar(255)
);

-- --------------------------------------------------------

--
-- Doublure de structure pour la vue `vue_stats_etablissements`
-- (Voir ci-dessous la vue réelle)
--
DROP VIEW IF EXISTS `vue_stats_etablissements`;
CREATE TABLE IF NOT EXISTS `vue_stats_etablissements` (
`id` int
,`nomets` varchar(255)
,`nb_concours` bigint
,`nb_candidatures` bigint
,`nb_validees` bigint
,`nb_en_attente` bigint
,`nb_rejetees` bigint
);

-- --------------------------------------------------------

--
-- Doublure de structure pour la vue `v_admin_activity`
-- (Voir ci-dessous la vue réelle)
--
DROP VIEW IF EXISTS `v_admin_activity`;
CREATE TABLE IF NOT EXISTS `v_admin_activity` (
`id` int
,`nom` varchar(100)
,`prenom` varchar(100)
,`role` enum('super_admin','admin_etablissement','sub_admin')
,`total_actions` bigint
,`derniere_action` timestamp
);

-- --------------------------------------------------------

--
-- Doublure de structure pour la vue `v_documents_stats`
-- (Voir ci-dessous la vue réelle)
--
DROP VIEW IF EXISTS `v_documents_stats`;

-- --------------------------------------------------------

--
-- Doublure de structure pour la vue `v_messages_stats`
-- (Voir ci-dessous la vue réelle)
--
DROP VIEW IF EXISTS `v_messages_stats`;
CREATE TABLE IF NOT EXISTS `v_messages_stats` (
`expediteur` enum('candidat','admin')
,`statut` enum('lu','non_lu')
,`total` bigint
,`candidats_uniques` bigint
);

-- --------------------------------------------------------

--
-- Structure de la vue `compose`
--
DROP TABLE IF EXISTS `compose`;

DROP VIEW IF EXISTS `compose`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `compose`  AS SELECT `n`.`id` AS `id`, `n`.`candidat_id` AS `candidat_id`, `n`.`concours_id` AS `concours_id`, `n`.`matiere_id` AS `matiere_id`, `n`.`note` AS `notcomp`, `n`.`coefficient` AS `coefficient`, `c`.`nomcan` AS `nomcan`, `c`.`prncan` AS `prncan`, `co`.`libcnc` AS `concours_nom`, `m`.`nom_matiere` AS `nom_matiere` FROM (((`notes` `n` join `candidats` `c` on((`n`.`candidat_id` = `c`.`id`))) join `concours` `co` on((`n`.`concours_id` = `co`.`id`))) join `matieres` `m` on((`n`.`matiere_id` = `m`.`id`))) ;

-- --------------------------------------------------------

--
-- Structure de la vue `vue_candidatures_completes`
--
DROP TABLE IF EXISTS `vue_candidatures_completes`;

DROP VIEW IF EXISTS `vue_candidatures_completes`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vue_candidatures_completes`  AS SELECT `c`.`id` AS `id`, `c`.`nupcan` AS `nupcan`, `c`.`nomcan` AS `nomcan`, `c`.`prncan` AS `prncan`, `c`.`maican` AS `maican`, `c`.`telcan` AS `telcan`, `c`.`dtncan` AS `dtncan`, `c`.`ldncan` AS `ldncan`, `c`.`phtcan` AS `phtcan`, `c`.`statut` AS `statut`, `c`.`created_at` AS `created_at`, `co`.`libcnc` AS `concours_nom`, `co`.`fracnc` AS `concours_frais`, `f`.`nomfil` AS `filiere_nom`, `e`.`nomets` AS `etablissement_nom`, `n`.`nomniv` AS `niveau_nom` FROM ((((`candidats` `c` left join `concours` `co` on((`c`.`concours_id` = `co`.`id`))) left join `filieres` `f` on((`c`.`filiere_id` = `f`.`id`))) left join `etablissements` `e` on((`co`.`etablissement_id` = `e`.`id`))) left join `niveaux` `n` on((`c`.`niveau_id` = `n`.`id`))) ;

-- --------------------------------------------------------

--
-- Structure de la vue `vue_stats_etablissements`
--
DROP TABLE IF EXISTS `vue_stats_etablissements`;

DROP VIEW IF EXISTS `vue_stats_etablissements`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vue_stats_etablissements`  AS SELECT `e`.`id` AS `id`, `e`.`nomets` AS `nomets`, count(distinct `co`.`id`) AS `nb_concours`, count(distinct `c`.`id`) AS `nb_candidatures`, count((case when (`c`.`statut` = 'valide') then 1 end)) AS `nb_validees`, count((case when (`c`.`statut` = 'en_attente') then 1 end)) AS `nb_en_attente`, count((case when (`c`.`statut` = 'rejete') then 1 end)) AS `nb_rejetees` FROM ((`etablissements` `e` left join `concours` `co` on((`e`.`id` = `co`.`etablissement_id`))) left join `candidats` `c` on((`co`.`id` = `c`.`concours_id`))) GROUP BY `e`.`id`, `e`.`nomets` ;

-- --------------------------------------------------------

--
-- Structure de la vue `v_admin_activity`
--
DROP TABLE IF EXISTS `v_admin_activity`;

DROP VIEW IF EXISTS `v_admin_activity`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_admin_activity`  AS SELECT `a`.`id` AS `id`, `a`.`nom` AS `nom`, `a`.`prenom` AS `prenom`, `a`.`role` AS `role`, count(distinct `aa`.`id`) AS `total_actions`, max(`aa`.`created_at`) AS `derniere_action` FROM (`administrateurs` `a` left join `admin_actions` `aa` on((`a`.`id` = `aa`.`admin_id`))) GROUP BY `a`.`id`, `a`.`nom`, `a`.`prenom`, `a`.`role` ;

-- --------------------------------------------------------

--
-- Structure de la vue `v_documents_stats`
--
DROP TABLE IF EXISTS `v_documents_stats`;

DROP VIEW IF EXISTS `v_documents_stats`;


-- --------------------------------------------------------

--
-- Structure de la vue `v_messages_stats`
--
DROP TABLE IF EXISTS `v_messages_stats`;

DROP VIEW IF EXISTS `v_messages_stats`;
CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `v_messages_stats`  AS SELECT `messages`.`expediteur` AS `expediteur`, `messages`.`statut` AS `statut`, count(0) AS `total`, count(distinct `messages`.`candidat_nupcan`) AS `candidats_uniques` FROM `messages` GROUP BY `messages`.`expediteur`, `messages`.`statut` ;

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `administrateurs`
--

--
-- Contraintes pour la table `admin_actions`
--

--
-- Contraintes pour la table `admin_logs`
--

--
-- Contraintes pour la table `candidats`
--

--
-- Contraintes pour la table `concours`
--

--
-- Contraintes pour la table `concours_filieres`
--

--
-- Contraintes pour la table `documents`
--

--
-- Contraintes pour la table `dossiers`
--

--
-- Contraintes pour la table `etablissements`
--

--
-- Contraintes pour la table `filieres`
--

--
-- Contraintes pour la table `filiere_matieres`
--

--
-- Contraintes pour la table `messages`
--

--
-- Contraintes pour la table `paiements`
--

--
-- Contraintes pour la table `participations`
--

--
-- Contraintes pour la table `sessions`
--

--
-- Contraintes pour la table `support_requests`
--
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

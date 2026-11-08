CREATE DATABASE  IF NOT EXISTS `nexo_db` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `nexo_db`;
-- MySQL dump 10.13  Distrib 8.0.46, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: nexo_db
-- ------------------------------------------------------
-- Server version	8.0.46

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `auth_group`
--

DROP TABLE IF EXISTS `auth_group`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_group` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_group`
--

LOCK TABLES `auth_group` WRITE;
/*!40000 ALTER TABLE `auth_group` DISABLE KEYS */;
/*!40000 ALTER TABLE `auth_group` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `auth_group_permissions`
--

DROP TABLE IF EXISTS `auth_group_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_group_permissions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `group_id` int NOT NULL,
  `permission_id` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `auth_group_permissions_group_id_permission_id_0cd325b0_uniq` (`group_id`,`permission_id`),
  KEY `auth_group_permissio_permission_id_84c5c92e_fk_auth_perm` (`permission_id`),
  CONSTRAINT `auth_group_permissio_permission_id_84c5c92e_fk_auth_perm` FOREIGN KEY (`permission_id`) REFERENCES `auth_permission` (`id`),
  CONSTRAINT `auth_group_permissions_group_id_b120cbf9_fk_auth_group_id` FOREIGN KEY (`group_id`) REFERENCES `auth_group` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_group_permissions`
--

LOCK TABLES `auth_group_permissions` WRITE;
/*!40000 ALTER TABLE `auth_group_permissions` DISABLE KEYS */;
/*!40000 ALTER TABLE `auth_group_permissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `auth_permission`
--

DROP TABLE IF EXISTS `auth_permission`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_permission` (
  `id` int NOT NULL AUTO_INCREMENT,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `content_type_id` int NOT NULL,
  `codename` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `auth_permission_content_type_id_codename_01ab375a_uniq` (`content_type_id`,`codename`),
  CONSTRAINT `auth_permission_content_type_id_2f476e4b_fk_django_co` FOREIGN KEY (`content_type_id`) REFERENCES `django_content_type` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=53 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_permission`
--

LOCK TABLES `auth_permission` WRITE;
/*!40000 ALTER TABLE `auth_permission` DISABLE KEYS */;
INSERT INTO `auth_permission` VALUES (1,'Can add log entry',1,'add_logentry'),(2,'Can change log entry',1,'change_logentry'),(3,'Can delete log entry',1,'delete_logentry'),(4,'Can view log entry',1,'view_logentry'),(5,'Can add permission',2,'add_permission'),(6,'Can change permission',2,'change_permission'),(7,'Can delete permission',2,'delete_permission'),(8,'Can view permission',2,'view_permission'),(9,'Can add group',3,'add_group'),(10,'Can change group',3,'change_group'),(11,'Can delete group',3,'delete_group'),(12,'Can view group',3,'view_group'),(13,'Can add user',4,'add_user'),(14,'Can change user',4,'change_user'),(15,'Can delete user',4,'delete_user'),(16,'Can view user',4,'view_user'),(17,'Can add content type',5,'add_contenttype'),(18,'Can change content type',5,'change_contenttype'),(19,'Can delete content type',5,'delete_contenttype'),(20,'Can view content type',5,'view_contenttype'),(21,'Can add session',6,'add_session'),(22,'Can change session',6,'change_session'),(23,'Can delete session',6,'delete_session'),(24,'Can view session',6,'view_session'),(25,'Can add company profile',7,'add_companyprofile'),(26,'Can change company profile',7,'change_companyprofile'),(27,'Can delete company profile',7,'delete_companyprofile'),(28,'Can view company profile',7,'view_companyprofile'),(29,'Can add product',8,'add_product'),(30,'Can change product',8,'change_product'),(31,'Can delete product',8,'delete_product'),(32,'Can view product',8,'view_product'),(33,'Can add sale',9,'add_sale'),(34,'Can change sale',9,'change_sale'),(35,'Can delete sale',9,'delete_sale'),(36,'Can view sale',9,'view_sale'),(37,'Can add sale item',10,'add_saleitem'),(38,'Can change sale item',10,'change_saleitem'),(39,'Can delete sale item',10,'delete_saleitem'),(40,'Can view sale item',10,'view_saleitem'),(41,'Can add team member',11,'add_teammember'),(42,'Can change team member',11,'change_teammember'),(43,'Can delete team member',11,'delete_teammember'),(44,'Can view team member',11,'view_teammember'),(45,'Can add category',12,'add_category'),(46,'Can change category',12,'change_category'),(47,'Can delete category',12,'delete_category'),(48,'Can view category',12,'view_category'),(49,'Can add client',13,'add_client'),(50,'Can change client',13,'change_client'),(51,'Can delete client',13,'delete_client'),(52,'Can view client',13,'view_client');
/*!40000 ALTER TABLE `auth_permission` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `auth_user`
--

DROP TABLE IF EXISTS `auth_user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_user` (
  `id` int NOT NULL AUTO_INCREMENT,
  `password` varchar(128) COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_login` datetime(6) DEFAULT NULL,
  `is_superuser` tinyint(1) NOT NULL,
  `username` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `first_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(254) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_staff` tinyint(1) NOT NULL,
  `is_active` tinyint(1) NOT NULL,
  `date_joined` datetime(6) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_user`
--

LOCK TABLES `auth_user` WRITE;
/*!40000 ALTER TABLE `auth_user` DISABLE KEYS */;
INSERT INTO `auth_user` VALUES (1,'pbkdf2_sha256$1000000$EKlKWHaYxY4Nyre9MIr2cS$B+kTOSfEzCCjd6Y5Oj+ikOAtKnp9eMDaZ1xpvRiFZZ0=','2026-11-08 00:03:03.133117',0,'ana@novacomercial.mx','Ana Martínez','','ana@novacomercial.mx',0,1,'2026-10-14 22:07:11.491784'),(2,'pbkdf2_sha256$1000000$wqICoVy9GL70GzOIEdsBZ5$fD1NH2kPE+BgGoLARcOGOrSTANibjhtbyfSf4XXQE6E=',NULL,0,'danielpola16@gmail.com','daniel polania','','danielpola16@gmail.com',0,1,'2026-10-14 22:30:53.880821'),(6,'pbkdf2_sha256$1000000$WSas6oHQ6sAEWswY8M4qYD$6PQ7Hs9AL7SMlbfKLko4ir2az+YIFIsKKwXzAZNkI10=','2026-10-19 13:23:59.889467',0,'ramos@gmail.com','Juan Ramos','','ramos@gmail.com',0,1,'2026-10-19 13:23:58.555864'),(7,'pbkdf2_sha256$1000000$I1Bl7naAvgVWWuTyVyOZ3y$jAi0sP2TRl25NdAZOGwIlIqhjilo4z2ja9q9WjDMJi4=','2026-11-08 00:04:23.242877',0,'superadmin@magnussig.com','Superadministrador','','superadmin@magnussig.com',0,1,'2026-10-22 03:30:51.855518'),(8,'pbkdf2_sha256$1000000$RWPMu5LBru8Kse5uvi7iI4$IMwdKCzhrb52cfgoQhxg/Gw+re+Abs+ukOVT1HJ+i5w=','2026-10-22 03:42:22.334607',0,'danielpola@gmail.com','Daniel Polania','','danielpola@gmail.com',0,1,'2026-10-22 03:42:21.632719'),(9,'pbkdf2_sha256$1000000$KHm5LukE1yNpcr2WJeXx7q$7YKfJr/MEC69WGU5sAzSGTDDVQ2arq+d57w3GrMxIqE=','2026-10-22 03:43:42.930602',0,'sofia@gmail.com','sofia','','sofia@gmail.com',0,1,'2026-10-22 03:43:42.183932'),(10,'pbkdf2_sha256$1000000$cg2Qyi2lUrBRv2CoGc4Tn0$Mi8yEMahyf98DKoJJbWUPglHb2yfifgUCdgt+Hs0InA=','2026-10-22 03:50:18.029578',0,'balon@gmail.com','samuel','','balon@gmail.com',0,1,'2026-10-22 03:48:38.466737'),(11,'pbkdf2_sha256$1000000$pBcF1Yb6xf0rM8cHVXdQgz$nQJMWWLJHI0Gk1+9T/YXh2lSpKIaxp5Y3jXkyJ0RJuI=','2026-10-22 03:49:54.539708',0,'ramo@gmail.com','sofi','','ramo@gmail.com',0,1,'2026-10-22 03:49:53.838277'),(12,'pbkdf2_sha256$1000000$6W7IqGvC8jJsPmWgDqDMCI$EoDRLm3WPk4orqohs67rbxp++Vjj743GgltLrdAfz4k=','2026-10-22 12:57:08.347840',0,'calderon@gmail.com','Daniel Polania','','calderon@gmail.com',0,1,'2026-10-22 12:57:07.133641'),(14,'pbkdf2_sha256$1000000$B9uDIb49hbWkFd0B4Ax76c$Z7TTYpZa6vKMRRo9AxS2qwA3oqwB/WNvDLPUVHoh3Q0=','2026-10-22 22:21:33.212743',0,'hola@gmail.com','Daniel Polania','','hola@gmail.com',0,1,'2026-10-22 22:21:32.490290'),(15,'pbkdf2_sha256$1000000$J9gN2L7STqL6BoBBtxcA3Z$cgmtixSiUU4upkxOs2frQ4dsIUQUUEgRTROgaRg6xmA=','2026-11-07 23:45:11.519498',0,'camacho@gmail.com','karen camacho','','camacho@gmail.com',0,1,'2026-10-26 12:48:15.204533'),(16,'pbkdf2_sha256$1000000$qWin0B6XNiCaFgFCpZCNip$mXldkgllr+8dACJ+7RdjttRfXv+/JWKOv1LqEKt/Wk8=','2026-11-07 23:49:34.472509',0,'jose@gmail.com','jose ardila','','jose@gmail.com',0,1,'2026-10-26 12:52:23.103709'),(17,'pbkdf2_sha256$1000000$O9nS77UVdOkKUUw8sHeL7g$3NRvS3EghdmsVn0TqGVXcn+B8M7nCx7ahg/u4T15KO8=','2026-11-03 05:22:18.999136',0,'rolver@gmail.com','rolver','','rolver@gmail.com',0,1,'2026-11-03 05:22:17.727265'),(19,'pbkdf2_sha256$1000000$gNNkFvi1dnt5aRnwohs9rO$tyrWWI+PBgxLyBZQr2aYPtjp9Y3mzAauswa3/XWOciM=','2026-11-05 13:16:52.819066',0,'pruebasdev771@gmail.com','juan parra','','pruebasdev771@gmail.com',0,1,'2026-11-05 13:16:51.538786'),(21,'pbkdf2_sha256$1000000$iaSSdMZH2OufYPjJRRMxab$rGLmuCnW4HD8DqbNyf8Sm9aS/NTOYHnweK0BEN7kFsw=','2026-11-05 13:31:00.546458',0,'wiston@gmail.com','wiston','','wiston@gmail.com',0,1,'2026-11-05 13:30:59.247041'),(22,'pbkdf2_sha256$1000000$LBbYrI7qFdajTxjMhJb8xk$PPix3PM8zB1OjIWswUk+/rnKyc4taLsSkPIAF3nK0eE=','2026-11-05 23:29:47.734671',0,'magnolia@gmail.com','magnolia','','magnolia@gmail.com',0,1,'2026-11-05 23:19:55.200766'),(23,'pbkdf2_sha256$1000000$ZP6yyuCbTBHEQF2DCXliUl$8V+cFbMQXf3Ep57D4YouYsi+S+FZbqrSVBeE9P/PqzE=','2026-11-06 00:18:57.746835',0,'estudiante@gmail.com','Estudiante','','estudiante@gmail.com',0,1,'2026-11-06 00:08:23.468713'),(24,'pbkdf2_sha256$1000000$XoDqRP9QTYe7gr5xAgw34J$kZ+aInlha3+9QII2sRGruv5872kB02QGmVMQskg9J4Y=','2026-11-06 00:18:30.462328',0,'fet@gmail.com','fet','','fet@gmail.com',0,1,'2026-11-06 00:17:31.493284'),(25,'pbkdf2_sha256$1000000$52AdKEwFLI8cCB9zEh8P2s$ogMhl6ZaYkUjJR4aQpL31cvj7uqc/KObHJOF0jlfPQ8=','2026-11-07 23:33:31.794834',0,'alexis@gmail.com','daniel alexis','','alexis@gmail.com',0,1,'2026-11-06 00:28:08.718347'),(26,'pbkdf2_sha256$1000000$2DVmp5k5dkxRJiq9wBJyaj$ZSw2G/De7wJZVy3aX/dQFiTqBCVzeYNxfWIqViFyqws=','2026-11-06 01:10:37.387440',0,'cr7@gmail.com','Daniel Polania','','cr7@gmail.com',0,1,'2026-11-06 01:10:36.326155'),(27,'pbkdf2_sha256$1000000$A9dX9rxux2LcLJUkSLX3tm$UwK5rpLjCccGQMWxV4LxwTyG3mnVh3ZBzajl6yEuqdU=','2026-11-06 01:56:56.597252',0,'tubb@gmail.com','Soytubb','','tubb@gmail.com',0,1,'2026-11-06 01:28:46.596894'),(28,'pbkdf2_sha256$1000000$qoXuUzgbLFwyBCc8CrSIxL$UMu9REuLsw8HS5lYjDKVXs7baP2ZbKG8FybbStYzWAw=','2026-11-06 02:04:04.631200',0,'botero@gamil.com','Santiago botero','','botero@gamil.com',0,1,'2026-11-06 01:56:56.940361'),(29,'pbkdf2_sha256$1000000$FjJ5AO3GffuqrYqZWEporn$VahQll3oCBXp0VUWo1ByJoUTj+HpqrQw2StOmv1g40A=','2026-11-07 23:36:38.689741',0,'supapa@gmail.com','supapa','','supapa@gmail.com',0,1,'2026-11-06 13:45:18.566970'),(30,'pbkdf2_sha256$1000000$WgvplXZXxcvQzQFvQpVHqi$n8dqH0oVN1vFmQI+ON6dSlOkxOn8tKKBxidbSMQHnuQ=',NULL,0,'m123@gmail.com','Miguel Ardila','','m123@gmail.com',0,1,'2026-11-06 14:32:13.260270'),(31,'pbkdf2_sha256$1000000$6ddR0eihvsUowRjNjtrlny$1GpviVpn0jYjjzotOhV8ltjtVM3WLeQWBvC7NsIP+Tg=','2026-11-07 23:49:17.556998',0,'universidad@gmail.com','Universidad','','universidad@gmail.com',0,1,'2026-11-07 23:47:55.419547');
/*!40000 ALTER TABLE `auth_user` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `auth_user_groups`
--

DROP TABLE IF EXISTS `auth_user_groups`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_user_groups` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `group_id` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `auth_user_groups_user_id_group_id_94350c0c_uniq` (`user_id`,`group_id`),
  KEY `auth_user_groups_group_id_97559544_fk_auth_group_id` (`group_id`),
  CONSTRAINT `auth_user_groups_group_id_97559544_fk_auth_group_id` FOREIGN KEY (`group_id`) REFERENCES `auth_group` (`id`),
  CONSTRAINT `auth_user_groups_user_id_6a12ed8b_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_user_groups`
--

LOCK TABLES `auth_user_groups` WRITE;
/*!40000 ALTER TABLE `auth_user_groups` DISABLE KEYS */;
/*!40000 ALTER TABLE `auth_user_groups` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `auth_user_user_permissions`
--

DROP TABLE IF EXISTS `auth_user_user_permissions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `auth_user_user_permissions` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `permission_id` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `auth_user_user_permissions_user_id_permission_id_14a6b632_uniq` (`user_id`,`permission_id`),
  KEY `auth_user_user_permi_permission_id_1fbb5f2c_fk_auth_perm` (`permission_id`),
  CONSTRAINT `auth_user_user_permi_permission_id_1fbb5f2c_fk_auth_perm` FOREIGN KEY (`permission_id`) REFERENCES `auth_permission` (`id`),
  CONSTRAINT `auth_user_user_permissions_user_id_a95ead1b_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `auth_user_user_permissions`
--

LOCK TABLES `auth_user_user_permissions` WRITE;
/*!40000 ALTER TABLE `auth_user_user_permissions` DISABLE KEYS */;
/*!40000 ALTER TABLE `auth_user_user_permissions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `django_content_type`
--

DROP TABLE IF EXISTS `django_content_type`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `django_content_type` (
  `id` int NOT NULL AUTO_INCREMENT,
  `app_label` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `model` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `django_content_type_app_label_model_76bd3d3b_uniq` (`app_label`,`model`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `django_content_type`
--

LOCK TABLES `django_content_type` WRITE;
/*!40000 ALTER TABLE `django_content_type` DISABLE KEYS */;
INSERT INTO `django_content_type` VALUES (1,'admin','logentry'),(3,'auth','group'),(2,'auth','permission'),(4,'auth','user'),(5,'contenttypes','contenttype'),(12,'productos','category'),(13,'productos','client'),(7,'productos','companyprofile'),(8,'productos','product'),(9,'productos','sale'),(10,'productos','saleitem'),(11,'productos','teammember'),(6,'sessions','session');
/*!40000 ALTER TABLE `django_content_type` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `django_migrations`
--

DROP TABLE IF EXISTS `django_migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `django_migrations` (
  `id` int NOT NULL AUTO_INCREMENT,
  `app` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `applied` datetime(6) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `django_migrations`
--

LOCK TABLES `django_migrations` WRITE;
/*!40000 ALTER TABLE `django_migrations` DISABLE KEYS */;
INSERT INTO `django_migrations` VALUES (1,'contenttypes','0001_initial','2026-10-14 22:07:07.638097'),(2,'auth','0001_initial','2026-10-14 22:07:08.851528'),(3,'admin','0001_initial','2026-10-14 22:07:09.382409'),(4,'admin','0002_logentry_remove_auto_add','2026-10-14 22:07:09.391433'),(5,'admin','0003_logentry_add_action_flag_choices','2026-10-14 22:07:09.401241'),(6,'contenttypes','0002_remove_content_type_name','2026-10-14 22:07:09.562905'),(7,'auth','0002_alter_permission_name_max_length','2026-10-14 22:07:09.675143'),(8,'auth','0003_alter_user_email_max_length','2026-10-14 22:07:09.723494'),(9,'auth','0004_alter_user_username_opts','2026-10-14 22:07:09.735663'),(10,'auth','0005_alter_user_last_login_null','2026-10-14 22:07:09.843371'),(11,'auth','0006_require_contenttypes_0002','2026-10-14 22:07:09.845832'),(12,'auth','0007_alter_validators_add_error_messages','2026-10-14 22:07:09.855478'),(13,'auth','0008_alter_user_username_max_length','2026-10-14 22:07:09.949989'),(14,'auth','0009_alter_user_last_name_max_length','2026-10-14 22:07:10.131820'),(15,'auth','0010_alter_group_name_max_length','2026-10-14 22:07:10.190644'),(16,'auth','0011_update_proxy_permissions','2026-10-14 22:07:10.213221'),(17,'auth','0012_alter_user_first_name_max_length','2026-10-14 22:07:10.406786'),(18,'productos','0001_initial','2026-10-14 22:07:11.453012'),(19,'productos','0002_demo_data','2026-10-14 22:07:12.883829'),(20,'productos','0003_teammember','2026-10-14 22:07:13.083454'),(21,'productos','0004_companyprofile_role','2026-10-14 22:07:13.148199'),(22,'sessions','0001_initial','2026-10-14 22:07:13.194311'),(23,'productos','0005_magnus_sig','2026-10-22 03:30:51.823166'),(24,'productos','0006_datos_magnus','2026-10-22 03:30:52.977992'),(25,'productos','0007_sale_delivery','2026-10-22 03:30:53.186503'),(26,'productos','0008_limpieza','2026-11-06 00:05:26.466262'),(27,'productos','0009_un_solo_superadmin','2026-11-07 23:28:55.964232');
/*!40000 ALTER TABLE `django_migrations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `productos_category`
--

DROP TABLE IF EXISTS `productos_category`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `productos_category` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `productos_category`
--

LOCK TABLES `productos_category` WRITE;
/*!40000 ALTER TABLE `productos_category` DISABLE KEYS */;
INSERT INTO `productos_category` VALUES (8,'Auditorías'),(2,'Botiquines'),(1,'Camillas'),(7,'Capacitaciones'),(4,'Dotaciones'),(5,'Elementos de protección personal'),(9,'Evaluaciones y análisis'),(3,'Extintores'),(6,'Gestión del SG-SST');
/*!40000 ALTER TABLE `productos_category` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `productos_client`
--

DROP TABLE IF EXISTS `productos_client`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `productos_client` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `document` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`),
  CONSTRAINT `productos_client_user_id_f6f4bbc7_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `productos_client`
--

LOCK TABLES `productos_client` WRITE;
/*!40000 ALTER TABLE `productos_client` DISABLE KEYS */;
INSERT INTO `productos_client` VALUES (1,'Público general','—','',NULL),(2,'Constructora Andina S.A.S','900123456-1','608 871 2345',NULL),(3,'Transportes del Huila Ltda','891234567-4','608 875 4410',NULL),(4,'Clínica Los Rosales S.A.S','901234567-8','310 456 7821',NULL),(5,'Agroindustrias del Sur S.A.S','900765432-2','320 118 4490',NULL),(6,'Daniel Polania','1076505401','302 295 9136',8),(7,'samuel','1076505408','302 295 9136',10),(8,'Daniel Polania','1081398143','302 295 9136',12),(9,'Daniel Polania','1076505409','302 295 9136',14),(10,'karen camacho','1076505407','302 295 9136',15),(11,'rolver','1076505402','302 295 9136',17),(12,'wiston','1076505400','302 295 9136',21),(13,'magnolia','1234567891','302 295 9136',22),(14,'Estudiante','1076505505','302 295 9136',23),(15,'fet','1076505404','302 295 9136',24),(16,'Daniel Polania','1076505403','302 295 9136',26),(17,'Soytubb','36065208','310 290 2807',27),(18,'Santiago botero','1076505108','318 419 7432',28),(19,'sofia','—','',9),(20,'Universidad','1075505407','318 419 7432',31);
/*!40000 ALTER TABLE `productos_client` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `productos_companyprofile`
--

DROP TABLE IF EXISTS `productos_companyprofile`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `productos_companyprofile` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `company` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` int NOT NULL,
  `role` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `dual` tinyint(1) NOT NULL,
  `granted_by_id` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_id` (`user_id`),
  KEY `productos_companyprofile_granted_by_id_57b4e4ae_fk_auth_user_id` (`granted_by_id`),
  CONSTRAINT `productos_companyprofile_granted_by_id_57b4e4ae_fk_auth_user_id` FOREIGN KEY (`granted_by_id`) REFERENCES `auth_user` (`id`),
  CONSTRAINT `productos_companyprofile_user_id_9866556f_fk_auth_user_id` FOREIGN KEY (`user_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `productos_companyprofile`
--

LOCK TABLES `productos_companyprofile` WRITE;
/*!40000 ALTER TABLE `productos_companyprofile` DISABLE KEYS */;
INSERT INTO `productos_companyprofile` VALUES (1,'Magnus SIG S.A.S',1,'Administrador',1,NULL),(2,'Magnus SIG S.A.S',2,'Administrador',0,NULL),(5,'Magnus SIG S.A.S',6,'Administrador',0,7),(6,'Magnus SIG S.A.S',7,'Superadministrador',0,NULL),(7,'Magnus SIG S.A.S',8,'Cliente',0,NULL),(8,'Magnus SIG S.A.S',9,'Cliente',0,7),(9,'Magnus SIG S.A.S',10,'Cliente',0,NULL),(10,'Magnus SIG S.A.S',11,'Asesor de ventas',0,NULL),(11,'Magnus SIG S.A.S',12,'Cliente',0,NULL),(12,'Magnus SIG S.A.S',14,'Cliente',0,NULL),(13,'Magnus SIG S.A.S',15,'Cliente',0,7),(14,'Magnus SIG S.A.S',16,'Asesor de ventas',0,NULL),(15,'Magnus SIG S.A.S',17,'Cliente',0,NULL),(16,'Magnus SIG S.A.S',19,'Administrador',0,NULL),(17,'Magnus SIG S.A.S',21,'Cliente',0,NULL),(18,'Magnus SIG S.A.S',22,'Cliente',0,NULL),(19,'Magnus SIG S.A.S',23,'Cliente',0,NULL),(20,'Magnus SIG S.A.S',24,'Asesor de ventas',0,7),(21,'Magnus SIG S.A.S',25,'Asesor de ventas',0,7),(22,'Magnus SIG S.A.S',26,'Cliente',0,NULL),(23,'Magnus SIG S.A.S',27,'Cliente',0,NULL),(24,'Magnus SIG S.A.S',28,'Cliente',0,NULL),(25,'Magnus SIG S.A.S',29,'Supervisor',0,7),(26,'Magnus SIG S.A.S',30,'Asesor de ventas',0,7),(27,'Magnus SIG S.A.S',31,'Cliente',0,NULL);
/*!40000 ALTER TABLE `productos_companyprofile` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `productos_product`
--

DROP TABLE IF EXISTS `productos_product`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `productos_product` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `name` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `sku` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `category` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `cost` decimal(12,2) DEFAULT NULL,
  `price` decimal(12,2) NOT NULL,
  `stock` int unsigned NOT NULL,
  `minimum_stock` int unsigned NOT NULL,
  `active` tinyint(1) NOT NULL,
  `image` longtext COLLATE utf8mb4_unicode_ci,
  `icon` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `updated_at` datetime(6) NOT NULL,
  `owner_id` int NOT NULL,
  `kind` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_product_sku_per_owner` (`owner_id`,`sku`),
  CONSTRAINT `productos_product_owner_id_222995fb_fk_auth_user_id` FOREIGN KEY (`owner_id`) REFERENCES `auth_user` (`id`),
  CONSTRAINT `productos_product_chk_1` CHECK ((`stock` >= 0)),
  CONSTRAINT `productos_product_chk_2` CHECK ((`minimum_stock` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=47 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `productos_product`
--

LOCK TABLES `productos_product` WRITE;
/*!40000 ALTER TABLE `productos_product` DISABLE KEYS */;
INSERT INTO `productos_product` VALUES (1,'Mouse inalámbrico M240','ELE-001','Accesorios','',15.00,25.00,48,10,0,NULL,'mouse','2026-10-14 22:07:12.863713','2026-11-08 00:07:38.900655',1,'product'),(2,'Teclado compacto K380','ELE-002','Accesorios','',23.40,39.00,31,10,0,NULL,'keyboard','2026-10-14 22:07:12.869419','2026-11-08 00:07:38.903937',1,'product'),(7,'anillo','12345','Accesorios','oro',23000.00,5777.00,11,33,0,'img/audifonos.png','box','2026-10-14 23:51:33.744775','2026-11-08 00:07:38.914525',1,'product'),(8,'TELEVISOR 4K','67','Pantallas','',1500.00,1700.00,2,5,0,'img/audifonos.png','box','2026-10-19 13:15:41.562946','2026-11-08 00:07:38.912066',1,'product'),(9,'Camilla rígida de rescate con inmovilizador','CAM-001','Camillas','Camilla rígida en polietileno con correas de sujeción e inmovilizador de cabeza, para rescate y traslado de lesionados.',390000.00,549900.00,8,3,1,NULL,'box','2026-10-22 03:30:52.841331','2026-10-22 03:30:52.841350',1,'product'),(10,'Camilla plegable de emergencia','CAM-002','Camillas','Camilla plegable en aluminio, liviana y fácil de almacenar, con capacidad de hasta 150 kg.',260000.00,389900.00,6,2,1,NULL,'box','2026-10-22 03:30:52.844563','2026-10-22 03:30:52.844580',1,'product'),(11,'Botiquín portátil de primeros auxilios','BOT-001','Botiquines','Botiquín portátil con gasas, vendas, antisépticos, guantes y demás elementos básicos de primeros auxilios.',85000.00,129900.00,25,8,1,NULL,'box','2026-10-22 03:30:52.846809','2026-10-22 03:30:52.846826',1,'product'),(12,'Botiquín de pared con tapa metálica','BOT-002','Botiquines','Botiquín fijo en lámina metálica para áreas de trabajo, dotado con insumos de primeros auxilios.',150000.00,229900.00,14,5,1,NULL,'box','2026-10-22 03:30:52.852045','2026-10-26 13:49:09.370771',1,'product'),(13,'Extintor multipropósito ABC 10 lb','EXT-001','Extintores','Extintor de polvo químico seco ABC de 10 libras, para fuegos de sólidos, líquidos y equipos eléctricos.',55000.00,89900.00,30,10,1,NULL,'box','2026-10-22 03:30:52.855924','2026-10-22 03:30:52.855942',1,'product'),(14,'Extintor de CO2 10 lb','EXT-002','Extintores','Extintor de dióxido de carbono, ideal para equipos eléctricos y electrónicos sin dejar residuos.',210000.00,319900.00,12,4,1,NULL,'box','2026-10-22 03:30:52.858158','2026-10-22 03:30:52.858174',1,'product'),(15,'Extintor multipropósito ABC 20 lb','EXT-003','Extintores','Extintor de polvo químico seco ABC de 20 libras, para bodegas, talleres y áreas industriales.',85000.00,129900.00,14,5,1,NULL,'box','2026-10-22 03:30:52.860724','2026-10-22 03:30:52.860741',1,'product'),(16,'Overol industrial de dotación','DOT-001','Dotaciones','Overol en tela drill, resistente, con bolsillos y cierre frontal. Disponible en varias tallas.',65000.00,99900.00,40,10,1,NULL,'box','2026-10-22 03:30:52.862812','2026-10-22 03:30:52.862826',1,'product'),(17,'Botas de seguridad con punta de acero','DOT-002','Dotaciones','Botas de cuero con puntera de acero y suela antideslizante, para trabajo industrial y construcción.',90000.00,139900.00,34,10,1,NULL,'box','2026-10-22 03:30:52.864795','2026-10-26 13:49:09.374965',1,'product'),(18,'Casco de seguridad con barbuquejo','EPP-001','Elementos de protección personal','Casco industrial de polietileno con suspensión de 4 puntos y barbuquejo ajustable.',18000.00,29900.00,59,15,1,NULL,'box','2026-10-22 03:30:52.871570','2026-11-05 13:35:29.583056',1,'product'),(19,'Gafas de seguridad antiempañantes','EPP-002','Elementos de protección personal','Gafas de policarbonato con protección UV y tratamiento antiempañante.',6000.00,12900.00,80,20,1,NULL,'box','2026-10-22 03:30:52.874843','2026-10-22 03:30:52.874862',1,'product'),(20,'Guantes de nitrilo (caja x 100)','EPP-003','Elementos de protección personal','Guantes desechables de nitrilo sin polvo, caja de 100 unidades.',28000.00,44900.00,20,6,1,NULL,'box','2026-10-22 03:30:52.877114','2026-10-22 03:30:52.877130',1,'product'),(21,'Mascarilla N95 (caja x 20)','EPP-004','Elementos de protección personal','Respirador desechable N95 con filtración de partículas, caja de 20 unidades.',45000.00,69900.00,0,10,1,NULL,'box','2026-10-22 03:30:52.879194','2026-10-22 03:30:52.879211',1,'product'),(22,'Protector auditivo tipo copa','EPP-005','Elementos de protección personal','Protector auditivo de copa con diadema ajustable, para ambientes con alto nivel de ruido.',22000.00,36900.00,9,10,1,NULL,'box','2026-10-22 03:30:52.881402','2026-10-22 03:30:52.881418',1,'product'),(23,'Diagnóstico inicial del SG-SST','SER-001','Gestión del SG-SST','Evaluación del estado actual del Sistema de Gestión de Seguridad y Salud en el Trabajo frente a los estándares mínimos.',NULL,1200000.00,0,0,1,NULL,'box','2026-10-22 03:30:52.888640','2026-10-22 03:30:52.888660',1,'service'),(24,'Diseño del SG-SST','SER-002','Gestión del SG-SST','Diseño del sistema: políticas, objetivos, matrices, procedimientos y formatos adaptados a la empresa.',NULL,2800000.00,0,0,1,NULL,'box','2026-10-22 03:30:52.891373','2026-10-22 03:30:52.891390',1,'service'),(25,'Implementación del SG-SST','SER-003','Gestión del SG-SST','Puesta en marcha del SG-SST con acompañamiento en sitio y capacitación al equipo responsable.',NULL,4500000.00,0,0,1,NULL,'box','2026-10-22 03:30:52.893531','2026-10-22 03:30:52.893549',1,'service'),(26,'Mantenimiento del SG-SST (mensual)','SER-004','Gestión del SG-SST','Seguimiento mensual al sistema: actualización de documentos, indicadores y planes de acción.',NULL,900000.00,0,0,1,NULL,'box','2026-10-22 03:30:52.895809','2026-10-22 03:30:52.895826',1,'service'),(27,'Administración del SG-SST (mensual)','SER-005','Gestión del SG-SST','Administración completa del SG-SST por parte de Magnus SIG, con informes periódicos a la gerencia.',NULL,1500000.00,0,0,1,NULL,'box','2026-10-22 03:30:52.897904','2026-10-22 03:30:52.897919',1,'service'),(28,'Asesoría en la implementación del SG-SST','SER-006','Gestión del SG-SST','Sesión de asesoría especializada para resolver dudas y orientar la implementación (por sesión).',NULL,350000.00,0,0,1,NULL,'box','2026-10-22 03:30:52.904908','2026-10-22 03:30:52.904926',1,'service'),(29,'Capacitación en primeros auxilios','CAP-001','Capacitaciones','Formación teórico-práctica en atención básica de emergencias y primeros auxilios (por grupo).',NULL,650000.00,0,0,1,NULL,'box','2026-10-22 03:30:52.907523','2026-10-22 03:30:52.907540',1,'service'),(30,'Capacitación en control de incendios','CAP-002','Capacitaciones','Uso de extintores, evacuación y respuesta ante conatos de incendio, con práctica (por grupo).',NULL,650000.00,0,0,1,NULL,'box','2026-10-22 03:30:52.909981','2026-10-22 03:30:52.910000',1,'service'),(31,'Capacitación en diagnóstico psicosocial','CAP-003','Capacitaciones','Formación para identificar y valorar los factores de riesgo psicosocial en la empresa (por grupo).',NULL,780000.00,0,0,1,NULL,'box','2026-10-22 03:30:52.912317','2026-10-22 03:30:52.912334',1,'service'),(32,'Intervención del riesgo psicosocial','CAP-004','Capacitaciones','Diseño y ejecución de acciones de intervención a partir de los resultados de la batería psicosocial.',NULL,1350000.00,0,0,1,NULL,'box','2026-10-22 03:30:52.914697','2026-10-22 03:30:52.914712',1,'service'),(33,'Capacitación en PESV','CAP-005','Capacitaciones','Formación en el Plan Estratégico de Seguridad Vial para conductores y responsables (por grupo).',NULL,700000.00,0,0,1,NULL,'box','2026-10-22 03:30:52.921380','2026-10-22 03:30:52.921401',1,'service'),(34,'Aplicación de batería de riesgo psicosocial','CAP-006','Capacitaciones','Aplicación y análisis de la batería de instrumentos de riesgo psicosocial (precio por trabajador).',NULL,45000.00,0,0,1,NULL,'box','2026-10-22 03:30:52.924139','2026-10-22 03:30:52.924158',1,'service'),(35,'Capacitaciones y entrenamientos en SST','CAP-007','Capacitaciones','Programa de capacitación y entrenamiento en seguridad y salud en el trabajo según las necesidades de la empresa.',NULL,800000.00,0,0,1,NULL,'box','2026-10-22 03:30:52.926451','2026-10-22 03:30:52.926467',1,'service'),(36,'Auditoría ISO 9001:2026','AUD-001','Auditorías','Auditoría del sistema de gestión de la calidad frente a la norma ISO 9001:2026.',NULL,3200000.00,0,0,1,NULL,'box','2026-10-22 03:30:52.928760','2026-10-22 03:30:52.928779',1,'service'),(37,'Auditoría ISO 14001:2026','AUD-002','Auditorías','Auditoría del sistema de gestión ambiental frente a la norma ISO 14001:2026.',NULL,3200000.00,0,0,1,NULL,'box','2026-10-22 03:30:52.931116','2026-10-22 03:30:52.931134',1,'service'),(38,'Auditoría ISO 45001:2026','AUD-003','Auditorías','Auditoría del sistema de gestión de seguridad y salud en el trabajo frente a la norma ISO 45001:2026.',NULL,3500000.00,0,0,1,NULL,'box','2026-10-22 03:30:52.937961','2026-10-22 03:30:52.937981',1,'service'),(39,'Auditoría a proveedores','AUD-004','Auditorías','Verificación del cumplimiento de requisitos de SST y calidad en proveedores y contratistas.',NULL,1600000.00,0,0,1,NULL,'box','2026-10-22 03:30:52.941482','2026-10-22 03:30:52.941503',1,'service'),(40,'Auditoría del PESV','AUD-005','Auditorías','Revisión del cumplimiento y la eficacia del Plan Estratégico de Seguridad Vial.',NULL,1800000.00,0,0,1,NULL,'box','2026-10-22 03:30:52.945188','2026-10-22 03:30:52.945207',1,'service'),(41,'Auditoría interna del SG-SST','AUD-006','Auditorías','Auditoría interna anual del SG-SST con informe de hallazgos y plan de mejora.',NULL,2100000.00,0,0,1,NULL,'box','2026-10-22 03:30:52.947403','2026-10-22 03:30:52.947420',1,'service'),(42,'Evaluación de riesgos laborales','EVA-001','Evaluaciones y análisis','Identificación de peligros, valoración de riesgos y definición de controles por área y cargo.',NULL,1900000.00,0,0,1,NULL,'box','2026-10-22 03:30:52.955193','2026-10-22 03:30:52.955220',1,'service'),(43,'Análisis de puesto de trabajo','EVA-002','Evaluaciones y análisis','Estudio del puesto para identificar exigencias, riesgos y recomendaciones ergonómicas (por puesto).',NULL,450000.00,0,0,1,NULL,'box','2026-10-22 03:30:52.958246','2026-10-22 03:30:52.958267',1,'service'),(44,'Profesiograma','EVA-003','Evaluaciones y análisis','Documento que define requisitos, exigencias y exámenes médicos por cargo (por cargo).',NULL,380000.00,0,0,1,NULL,'box','2026-10-22 03:30:52.961730','2026-10-22 03:30:52.961747',1,'service'),(45,'Gestión de exámenes médicos ocupacionales','EVA-004','Evaluaciones y análisis','Coordinación y seguimiento de exámenes de ingreso, periódicos y de egreso (precio por trabajador).',NULL,85000.00,0,0,1,NULL,'box','2026-10-22 03:30:52.964505','2026-10-22 03:30:52.964522',1,'service'),(46,'Asesoria','990909','Gestión del SG-SST','Si',1500000.00,2000000.00,0,0,1,NULL,'box','2026-11-06 14:26:42.480995','2026-11-06 14:26:42.481028',1,'service');
/*!40000 ALTER TABLE `productos_product` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `productos_sale`
--

DROP TABLE IF EXISTS `productos_sale`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `productos_sale` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `folio` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `customer` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `subtotal` decimal(14,2) NOT NULL,
  `tax` decimal(14,2) NOT NULL,
  `total` decimal(14,2) NOT NULL,
  `created_at` datetime(6) NOT NULL,
  `owner_id` int DEFAULT NULL,
  `advisor_email` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `advisor_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `advisor_role` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `attended_by` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `customer_doc` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `customer_phone` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `payment` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` varchar(15) COLLATE utf8mb4_unicode_ci NOT NULL,
  `client_id` bigint DEFAULT NULL,
  `delivery_method` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `delivery_city` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `delivery_address` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `notes` varchar(300) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_sale_folio_per_owner` (`owner_id`,`folio`),
  KEY `productos_sale_client_id_a35502a3_fk_productos_client_id` (`client_id`),
  CONSTRAINT `productos_sale_client_id_a35502a3_fk_productos_client_id` FOREIGN KEY (`client_id`) REFERENCES `productos_client` (`id`),
  CONSTRAINT `productos_sale_owner_id_b0a0faae_fk_auth_user_id` FOREIGN KEY (`owner_id`) REFERENCES `auth_user` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `productos_sale`
--

LOCK TABLES `productos_sale` WRITE;
/*!40000 ALTER TABLE `productos_sale` DISABLE KEYS */;
INSERT INTO `productos_sale` VALUES (2,'V-1047','Público general',5139.00,822.24,5961.24,'2026-10-19 13:24:53.473938',6,'','','','','','','Efectivo','Entregado',NULL,'','','',''),(5,'V-1005','Daniel Polania',406554.00,77245.26,483799.26,'2026-10-22 03:43:14.663032',8,'','Tienda en línea','Autoservicio','sofia','1076505401','302 295 9136','Nequi / Daviplata','Entregado',6,'ship','Neiva','carrera 38A #21a-68',''),(6,'V-1006','samuel',2595000.00,493050.00,3088050.00,'2026-10-22 03:49:03.110716',10,'','Tienda en línea','Autoservicio','sofi','1076505408','302 295 9136','Nequi / Daviplata','Entregado',7,'service','Neiva','carrera 38A #21a-68',''),(7,'V-1007','Daniel Polania',700777.00,133147.63,833924.63,'2026-10-22 12:58:39.346509',12,'','Tienda en línea','Autoservicio','','1081398143','302 295 9136','Nequi / Daviplata','Pendiente',8,'pickup','neiva','carrera 38A #21a-68',''),(8,'V-1008','Daniel Polania',1950000.00,370500.00,2320500.00,'2026-10-22 22:22:15.182778',14,'','Tienda en línea','Autoservicio','','1076505409','302 295 9136','Efectivo','Pendiente',9,'service','Neiva','carrera 38A #21a-68',''),(9,'V-1009','karen camacho',3750000.00,712500.00,4462500.00,'2026-10-26 12:48:54.960473',15,'','Tienda en línea','Autoservicio','jose ardila','1076505407','302 295 9136','Transferencia bancaria','Entregado',10,'service','neiva','carrera 38A #21a-68',''),(10,'V-1010','karen camacho',375577.00,71359.63,446936.63,'2026-10-26 13:49:09.347129',15,'','Tienda en línea','Autoservicio','jose ardila','1076505407','302 295 9136','Nequi / Daviplata','Entregado',10,'pickup','','',''),(13,'V-1013','karen camacho',1995000.00,379050.00,2374050.00,'2026-11-03 02:01:08.098315',15,'','Tienda en línea','Autoservicio','jose ardila','1076505407','302 295 9136','Nequi / Daviplata','Entregado',10,'service','neiva','carrera 38A #21a-68',''),(14,'V-1014','Público general',1500000.00,285000.00,1785000.00,'2026-11-05 13:23:29.909928',19,'pruebasdev771@gmail.com','juan parra','Administrador','juan parra','—','','Transferencia bancaria','Entregado',1,'','','',''),(15,'V-1015','wiston',829900.00,157681.00,987581.00,'2026-11-05 13:35:29.570310',21,'','Tienda en línea','Autoservicio','daniel alexis','1076505400','302 295 9136','Transferencia bancaria','Entregado',12,'pickup','Ninguna','carrera 38A #21a-68','74'),(16,'V-1016','magnolia',1950000.00,370500.00,2320500.00,'2026-11-05 23:20:49.074368',22,'','Tienda en línea','Autoservicio','jose ardila','1234567891','302 295 9136','Transferencia bancaria','Entregado',13,'service','neiva','carrera 38A #21a-68',''),(17,'V-1017','Estudiante',1950000.00,370500.00,2320500.00,'2026-11-06 00:16:42.618500',23,'','Tienda en línea','Autoservicio','fet','1076505505','302 295 9136','Transferencia bancaria','Entregado',14,'service','Ninguna','carrera 38A #21a-68',''),(18,'V-1018','Soytubb',1800000.00,342000.00,2142000.00,'2026-11-06 01:53:47.013268',27,'','Tienda en línea','Autoservicio','daniel alexis','36065208','310 290 2807','Transferencia bancaria','Entregado',17,'service','Neiva','Carrera 38 A#21a-68',''),(19,'V-1019','Santiago botero',1500000.00,285000.00,1785000.00,'2026-11-06 01:57:38.265461',28,'','Tienda en línea','Autoservicio','daniel alexis','1076505108','318 419 7432','Transferencia bancaria','Entregado',18,'service','Neiva','Carrera 51A 29-23',''),(21,'V-1021','Universidad',1850000.00,351500.00,2201500.00,'2026-11-07 23:48:27.307175',31,'','Tienda en línea','Autoservicio','jose ardila','1075505407','318 419 7432','Transferencia bancaria','Entregado',20,'service','Ibague','carrera 38A #21a-68','');
/*!40000 ALTER TABLE `productos_sale` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `productos_saleitem`
--

DROP TABLE IF EXISTS `productos_saleitem`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `productos_saleitem` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `quantity` int unsigned NOT NULL,
  `unit_price` decimal(12,2) NOT NULL,
  `product_id` bigint NOT NULL,
  `sale_id` bigint NOT NULL,
  `name` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `sku` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  KEY `productos_saleitem_product_id_9c895006_fk_productos_product_id` (`product_id`),
  KEY `productos_saleitem_sale_id_e79ac339_fk_productos_sale_id` (`sale_id`),
  CONSTRAINT `productos_saleitem_product_id_9c895006_fk_productos_product_id` FOREIGN KEY (`product_id`) REFERENCES `productos_product` (`id`),
  CONSTRAINT `productos_saleitem_sale_id_e79ac339_fk_productos_sale_id` FOREIGN KEY (`sale_id`) REFERENCES `productos_sale` (`id`),
  CONSTRAINT `productos_saleitem_chk_1` CHECK ((`quantity` >= 0))
) ENGINE=InnoDB AUTO_INCREMENT=44 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `productos_saleitem`
--

LOCK TABLES `productos_saleitem` WRITE;
/*!40000 ALTER TABLE `productos_saleitem` DISABLE KEYS */;
INSERT INTO `productos_saleitem` VALUES (3,1,39.00,2,2,'',''),(4,3,1700.00,8,2,'',''),(8,2,5777.00,7,5,'anillo','12345'),(9,1,350000.00,28,5,'Asesoría en la implementación del SG-SST','SER-006'),(10,1,45000.00,34,5,'Aplicación de batería de riesgo psicosocial','CAP-006'),(11,1,45000.00,34,6,'Aplicación de batería de riesgo psicosocial','CAP-006'),(12,1,2100000.00,41,6,'Auditoría interna del SG-SST','AUD-006'),(13,1,450000.00,43,6,'Análisis de puesto de trabajo','EVA-002'),(14,1,5777.00,7,7,'anillo','12345'),(15,1,650000.00,30,7,'Capacitación en control de incendios','CAP-002'),(16,1,45000.00,34,7,'Aplicación de batería de riesgo psicosocial','CAP-006'),(17,1,1500000.00,27,8,'Administración del SG-SST (mensual)','SER-005'),(18,1,450000.00,43,8,'Análisis de puesto de trabajo','EVA-002'),(19,1,350000.00,28,9,'Asesoría en la implementación del SG-SST','SER-006'),(20,1,1600000.00,39,9,'Auditoría a proveedores','AUD-004'),(21,1,1800000.00,40,9,'Auditoría del PESV','AUD-005'),(22,1,5777.00,7,10,'anillo','12345'),(23,1,229900.00,12,10,'Botiquín de pared con tapa metálica','BOT-002'),(24,1,139900.00,17,10,'Botas de seguridad con punta de acero','DOT-002'),(29,1,1500000.00,27,13,'Administración del SG-SST (mensual)','SER-005'),(30,1,45000.00,34,13,'Aplicación de batería de riesgo psicosocial','CAP-006'),(31,1,450000.00,43,13,'Análisis de puesto de trabajo','EVA-002'),(32,1,1500000.00,27,14,'Administración del SG-SST (mensual)','SER-005'),(33,1,29900.00,18,15,'Casco de seguridad con barbuquejo','EPP-001'),(34,1,800000.00,35,15,'Capacitaciones y entrenamientos en SST','CAP-007'),(35,1,350000.00,28,16,'Asesoría en la implementación del SG-SST','SER-006'),(36,1,1600000.00,39,16,'Auditoría a proveedores','AUD-004'),(37,1,1500000.00,27,17,'Administración del SG-SST (mensual)','SER-005'),(38,1,450000.00,43,17,'Análisis de puesto de trabajo','EVA-002'),(39,1,1800000.00,40,18,'Auditoría del PESV','AUD-005'),(40,1,1500000.00,27,19,'Administración del SG-SST (mensual)','SER-005'),(42,1,1500000.00,27,21,'Administración del SG-SST (mensual)','SER-005'),(43,1,350000.00,28,21,'Asesoría en la implementación del SG-SST','SER-006');
/*!40000 ALTER TABLE `productos_saleitem` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping events for database 'nexo_db'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-11-07 19:29:53

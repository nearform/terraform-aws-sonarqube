Feature: Test AWS RDS

    Scenario: Ensure db instance is postgresql
        Given I have aws_db_instance defined
        Then it must contain engine
        And its value must be postgres

    Scenario: Ensure db instance is v16
        Given I have aws_db_instance defined
        Then it must contain engine_version
        And its value must be 16

    Scenario: Ensure db instance is not publicly accessible
        Given I have aws_db_instance defined
        Then it must contain publicly_accessible
        And its value must be false

    Scenario: Ensure db instance is protected against deletion
        Given I have aws_db_instance defined
        Then it must contain deletion_protection
        And its value must be true

    Scenario: Ensure db storage is encrypted
        Given I have aws_db_instance defined
        Then it must contain storage_encrypted
        And its value must be true

    Scenario: Ensure db storage uses own kms key for encryption
        Given I have aws_db_instance defined
        Then it must contain kms_key_id
        And its value must be module.sonarqube.aws_kms_key.sonarqube

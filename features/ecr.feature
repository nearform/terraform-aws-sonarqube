Feature: Test AWS Elastic Container Registry (ECR)

    Scenario: Ensure image tags are immutable
        Given I have aws_ecr_repository defined
        Then it must contain image_tag_mutability
        And its value must be IMMUTABLE

    Scenario: Ensure images are scanned on push
        Given I have aws_ecr_repository defined
        Then it must contain scan_on_push
        And its value must be true

    Scenario: Ensure the encryption type used for the repository is AES256 
        Given I have aws_ecr_repository defined
        Then it must contain encryption_type
        And its value must be AES256

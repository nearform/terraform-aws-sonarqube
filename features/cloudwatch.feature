Feature: Test CloudWatch

    Scenario: Ensure the log group has a proper name
        Given I have aws_cloudwatch_log_group defined
        Then it must contain name
        And its value must match the "^/aws/ecs/+" regex

    Scenario: Ensure the log group has a proper expiration period
        Given I have aws_cloudwatch_log_group defined
        Then it must contain retention_in_days
        And its value must be 7

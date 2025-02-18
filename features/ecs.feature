Feature: Test AWS ECS

    Scenario: Ensure the tasks are based on Fargate
        Given I have aws_ecs_task_definition defined
        Then it must contain requires_compatibilities
        And its value must be FARGATE

    Scenario: Ensure the network mode is awsvpc
        Given I have aws_ecs_task_definition defined
        Then it must contain network_mode
        And its value must be awsvpc

    Scenario: Ensure the runtime platform is Linux
        Given I have aws_ecs_task_definition defined
        When it contains runtime_platform
        Then it must contain operating_system_family
        And its value must be LINUX

    Scenario: Ensure the runtime platform is ARM64
        Given I have aws_ecs_task_definition defined
        When it contains runtime_platform
        Then it must contain cpu_architecture
        And its value must be ARM64

    Scenario: Ensure the volumes are defined
        Given I have aws_ecs_task_definition defined
        When it contains volume
        Then it must contain name
        And its value must must match the "^(sonar-data|sonar-extensions|sonar-logs)" regex

Feature: Test AWS ECS

    Scenario: Ensure ecs task definition is based on fargate
        Given I have aws_ecs_task_definition defined
        Then it must contain requires_compatibilities
        And its value must be FARGATE

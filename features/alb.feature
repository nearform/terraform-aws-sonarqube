Feature: Test AWS ALB

    Scenario: Ensure the load balancer is an ALB
        Given I have aws_lb defined
        Then it must contain load_balancer_type
        And its value must be application

    Scenario: Ensure the target group uses plain HTTP
        Given I have aws_lb_target_group defined
        Then it must contain protocol
        And its value must be HTTP

    Scenario: Ensure the target group's type is ip
        Given I have aws_lb_target_group defined
        Then it must contain target_type
        And its value must be ip

    Scenario: Ensure the listener uses plain HTTP
        Given I have aws_lb_listener defined
        Then it must contain protocol
        And its value must be HTTP

    Scenario: Ensure the listener uses port 80
        Given I have aws_lb_listener defined
        Then it must contain port
        And its value must be 80

    Scenario: Ensure the listener's default action is forward
        Given I have aws_lb_listener defined
        When it contains default_action
        Then it must contain type
        And its value must be forward

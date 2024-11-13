# Terraform Configuration for Incident Manager

This document provides an overview of how to define individual values in the `terraform.tfvars` file for the Incident Manager module. It also explains the significance of each configuration parameter.

## Table of Contents

1. [Introduction](#introduction)
2. [Configuration Parameters](#configuration-parameters)
   - [Contacts](#contacts)
   - [Schedule](#schedule)
   - [On-call Schedule Contacts](#on-call-schedule-contacts)
   - [Escalation Plans](#escalation-plans)
   - [Response Plan](#response-plan)
3. [Example `terraform.tfvars`](#example-terraformtfvars)

## Introduction

The `terraform.tfvars` file is used to define variable values for the Terraform configuration. This file allows you to customize the behavior of the Incident Manager module by specifying contact details, schedules, escalation plans, and response plans.

![Incidents Manager Work Flow](image.png)

# Terraform AWS Infrastructure Overview

This Terraform code configures and manages **AWS Incident Manager resources**, including **contacts**, **on-call schedules**, **escalation plans**, and **response plans**. The resources are currently structured within a single module to ensure smooth functionality and quick deployment. In the future, the resources will be modularized.

  
**Example**:
- Contacts with emails are configured for email delivery.
- Contacts with mobile numbers are configured for SMS and voice channels.

## Configuration Parameters

### Contacts
- **Personal Contacts**: Each contact is defined with an alias, email, and mobile number. Terraform dynamically generates a unique alias for each contact.
- **Contact Channels**: Email, SMS, and phone channels are assigned to each contact based on the available information. Only contacts with valid email or mobile numbers are included.
- **Description**: A map of contacts with their details.
- **Structure**:
  ```hcl
  contacts = {
    contact_name = {
      name          = "string"
      email         = "string"
      mobile_number = "string"
    }
  }
  ```
- **Significance**: Defines the individuals who will be contacted during incidents. Each contact must have a name, and optionally an email or mobile number.

### Schedule
- **On-call Rotations**: The configuration includes on-call schedules for different shifts (morning, evening, night). The schedule dynamically assigns contacts based on the shift configuration.
- **Time Zones & Hand-off**: Each shift specifies the timezone and hand-off time between contacts to ensure smooth transition and coverage.
- **Description**: A mapping of schedules to contacts.
- **Structure**:
  ```hcl
  schedule = {
    shift_name = {
      contacts          = ["contact_name"]
      shift_change_time = { hour = number, minute = number }
      shift_hours       = { start_hour = number, start_minute = number, end_hour = number, end_minute = number }
      time_zone         = "string"
    }
  }
  ```
- **Significance**: Defines the shift schedules and associates them with contacts. This is crucial for managing who is on-call during specific times.

### On-call Schedule Contacts

- **Description**: A list of on-call schedule contacts.
- **Structure**:
  ```hcl
  oncall_schedule_contacts = {
    schedule_name = {
      schedule = ["shift_name"]
      name     = "string"
    }
  }
  ```
- **Significance**: Maps on-call schedules to specific shifts, allowing for organized and efficient incident response.

### Escalation Plans
- **Escalation Stages**: Each escalation plan has multiple stages with contacts dynamically assigned to each stage. The duration of each stage is configurable.
- **Target Contacts**: Contacts for escalation stages are sourced based on predefined schedules and mapped to their respective stages automatically.
- **Description**: Defines the escalation plan for incidents.
- **Structure**:
  ```hcl
  escalation_plans = [
    {
      name   = "string"
      stages = [
        {
          target_contacts = ["contact_name"]
          stage_duration  = number
          stop_the_alert  = bool
        }
      ]
    }
  ]
  ```
- **Significance**: Specifies the sequence of actions and contacts to engage during an incident, ensuring timely and appropriate responses.

### Response Plan
- **Incident Response Plans**: Response plans are created to manage incidents with specific templates, including incident titles, descriptions, and impact levels.
- **Engagement Plans**: Each response plan can trigger engagement through escalation plans, ensuring key contacts are notified during incidents.
- **Description**: List of response plans.
- **Structure**:
  ```hcl
  response_plan = [
    {
      name                   = "string"
      incident_title         = "string"
      incident_description   = "string"
      impact                 = number
      slack_chat_enable      = bool
      target_engagement_plan = ["escalation_plan_name"]
    }
  ]
  ```
- **Significance**: Outlines the response strategy for incidents, including the engagement of escalation plans and communication channels.

## Example `terraform.tfvars`

```hcl
contacts = {
  john_doe = {
    name          = "John Doe"
    email         = "john.doe@example.com"
    mobile_number = "+1234567890"
  }
}

schedule = {
  morning_shift = {
    contacts          = ["john_doe"]
    shift_change_time = { hour = 9, minute = 0 }
    shift_hours       = { start_hour = 8, start_minute = 30, end_hour = 17, end_minute = 0 }
    time_zone         = "Asia/Kolkata"
  }
}

oncall_schedule_contacts = {
  primary_schedule = {
    schedule = ["morning_shift"]
    name     = "Primary On-call"
  }
}

escalation_plans = [
  {
    name   = "primary_escalation"
    stages = [
      {
        target_contacts = ["primary_schedule"]
        stage_duration  = 30
        stop_the_alert  = true
      }
    ]
  }
]

response_plan = [
  {
    name                   = "primary_response"
    incident_title         = "Server Down"
    incident_description   = "Critical server outage"
    impact                 = 0
    slack_chat_enable      = false
    target_engagement_plan = ["primary_escalation"]
  }
]
```

This readme.md file provides a structured guide to understanding and configuring the `terraform.tfvars` file for your Terraform setup.

## Usage
This Terraform configuration manages critical resources within **AWS Incident Manager**, ensuring rapid response and escalation during incidents. All resources are designed to ensure effective communication and escalation, dynamically sourcing contact ARNs and mapping them into the appropriate schedules or escalation plans.

To deploy the infrastructure:

1. Define the input variables for **contacts**, **on-call schedules**, **escalation plans**, and **response plans** in your `.tfvars` file.
2. Run `terraform apply` to deploy the infrastructure and configure the resources.
3. Output values such as contact ARNs, on-call schedules, and escalation mappings are automatically generated for use within the incident management workflow.

## Future Enhancements
The current structure is optimized for quick deployment and functional testing. Moving forward, the configuration will be modularized for better scalability and management, but the core functionality will remain unchanged.


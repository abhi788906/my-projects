##################
# Contacts
##################

# Generates a random string for unique aliases for each contact.
resource "random_string" "alias_random" {
  for_each = { for contact in local.valid_contacts : contact.name => contact }

  length  = 4
  special = false  # Generates a string with only alphabets and numbers.
  upper   = false  # Ensures the alias uses only lowercase letters.
}

resource "aws_ssmcontacts_contact" "incident_contacts" {
  for_each = { for contact in local.valid_contacts : contact.name => contact }
  
  type        = "PERSONAL"  # Defines the contact type as personal.
  alias       = "${lower(each.key)}-${random_string.alias_random[each.key].result}"  # Creates a unique alias for each contact.
  display_name = lower(each.value.name)  # Sets the display name to the lowercase contact name.
}

resource "aws_ssmcontacts_contact_channel" "email_channels" {
  for_each = {
    for contact in local.valid_contacts :
    contact.name => contact if contact.email != ""  # Only include valid contacts with an email address.
  }

  contact_id = aws_ssmcontacts_contact.incident_contacts[each.key].id  # Links the contact channel to the contact.

  name  = "EMAIL"
  type  = "EMAIL"
  
  delivery_address {
    simple_address = each.value.email  # Uses the email address defined for the contact.
  }
}

resource "aws_ssmcontacts_contact_channel" "sms_channels" {
  for_each = {
    for contact in local.valid_contacts :
    contact.name => contact if contact.mobile_number != ""  # Only include valid contacts with a mobile number.
  }

  contact_id = aws_ssmcontacts_contact.incident_contacts[each.key].id  # Links the contact channel to the contact.

  name  = "SMS"
  type  = "SMS"
  
  delivery_address {
    simple_address = each.value.mobile_number  # Uses the mobile number defined for the contact.
  }
}

resource "aws_ssmcontacts_contact_channel" "phone_channels" {
  for_each = {
    for contact in local.valid_contacts :
    contact.name => contact if contact.mobile_number != ""  # Only include valid contacts with a mobile number.
  }

  contact_id = aws_ssmcontacts_contact.incident_contacts[each.key].id  # Links the contact channel to the contact.

  name  = "VOICE"
  type  = "VOICE"
  
  delivery_address {
    simple_address = each.value.mobile_number  # Uses the mobile number for voice channel communication.
  }
}


# NOTE: All resources have been written in this module only for testing purposes. Later, they will be defined in their own modules.


####################################
# Oncall Schedule
####################################

# Morning Shift On-call Schedule
resource "awscc_ssmcontacts_contact" "oncall_schedule" {
  for_each = local.oncall_schedule_mapped

  alias        = lower(each.value.name)
  display_name = lower(each.value.name)
  type         = "ONCALL_SCHEDULE"
  plan = [{
    rotation_ids = local.rotation_ids[each.key]
  }]
}

resource "aws_ssmcontacts_rotation" "shift_rotations" {
  for_each = { for idx, shift in local.shift_configurations : idx => shift }

  contact_ids  = each.value.contact_ids
  name         = each.value.name
  time_zone_id = each.value.time_zone_id

  recurrence {
    number_of_on_calls    = 1
    recurrence_multiplier = 1

    weekly_settings {
      day_of_week = "MON"
      hand_off_time {
        hour_of_day    = each.value.hand_off_time.hour
        minute_of_hour = each.value.hand_off_time.minute
      }
    }

    dynamic "shift_coverages" {
      for_each = ["MON", "TUE", "WED", "THU", "FRI"]

      content {
        map_block_key = shift_coverages.value
        coverage_times {
          start {
            hour_of_day    = each.value.coverage.start_hour
            minute_of_hour = each.value.coverage.start_minute
          }
          end {
            hour_of_day    = each.value.coverage.end_hour
            minute_of_hour = each.value.coverage.end_minute
          }
        }
      }
    }
  }
}



####################################
# Escalation Plan
####################################

### The following section is currently a work in progress. ### 

resource "aws_ssmcontacts_contact" "escalation_plan" {
  for_each = { for plan in var.escalation_plans : plan.name => plan }  # Iterates through defined escalation plans.
  type = "ESCALATION"  # Sets the contact type to escalation.
  display_name = lower(each.key)  # Ensures the display name is lowercase.
  alias = lower(each.key)  # Creates a lowercase alias for each escalation plan.
}

resource "aws_ssmcontacts_plan" "escalation_stages" {
  for_each = local.mapped_stages

  contact_id = each.value.stages[0].source_arn  // Uses the source ARN from the mapped stages.

  dynamic "stage" {
    for_each = each.value.stages  // Iterates over the stages defined in each mapped escalation plan.
    content {
      duration_in_minutes = stage.value.duration_in_minutes  // Sets the duration for each stage.

      // Create target blocks for each stage.
      dynamic "target" {
        for_each = stage.value.targets  // Iterates over target contacts for the stage.
        content {
          contact_target_info {
            is_essential = false  // Indicates whether the contact is essential.
            contact_id   = target.value.target_arn  // Uses the target ARN from the mapped stages.
          }
        }
      }
    }
  }
}



####################################
# Response Plan
####################################

# The following response plan section is commented out and pending further development.

resource "aws_ssmincidents_response_plan" "example" {
  for_each = { for idx, plan in local.response_plan : idx => plan }

  name         = each.value.name
  display_name = "Response Plan - ${each.value.name}"

  incident_template {
    title   = each.value.incident_title
    impact  = each.value.impact
    summary = each.value.incident_description
  }

  engagements = each.value.target_engagement_plan
}

// If you need to configure a chat channel, consider using a separate resource or method
// Example: aws_sns_topic or another relevant AWS service

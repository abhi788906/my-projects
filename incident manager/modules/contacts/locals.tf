// Valid Contacts
locals {
  valid_contacts = [
    for contact_key, contact in var.contacts :
    contact if (contact.email != "" || (contact.mobile_number != "" && contact.mobile_number != null))
  ]
}

// Shift Contacts
locals {
  shift_contacts = {
    for shift_key, shift_details in var.schedule : shift_key => [
      for contact in local.valid_contacts : contact if contains(shift_details.contacts, contact.name)
    ]
  }
}

// Oncall Schedule Contacts
locals {
  oncall_schedule_mapped = {
    for schedule_key, schedule_details in var.oncall_schedule_contacts : schedule_key => {
      name = schedule_details.name
      contacts = flatten([
        for shift in schedule_details.schedule : local.shift_contacts[shift]
      ])
    }
  }
}

// Shift Configurations
locals {
  shift_configurations = {
    for shift_name, shift_details in var.schedule : shift_name => {
      name          = shift_name
      contact_ids   = local.shift_contacts_arns[shift_name]
      time_zone_id  = shift_details.time_zone
      hand_off_time = shift_details.shift_change_time
      coverage      = shift_details.shift_hours
    }
  }
}

// Shift Contacts ARNs
locals {
  shift_contacts_arns = {
    for shift_key, shift_details in var.schedule : shift_key => [
      for contact in local.valid_contacts : aws_ssmcontacts_contact.incident_contacts[contact.name].arn
      if contact != null && contains(shift_details.contacts, contact.name) && contains(keys(aws_ssmcontacts_contact.incident_contacts), contact.name)
    ]
  }
}

// Rotation IDs
locals {
  rotation_ids = {
    for schedule_key, schedule_details in var.oncall_schedule_contacts : schedule_key => flatten([
      for shift in schedule_details.schedule : aws_ssmcontacts_rotation.shift_rotations[shift].id
      if contains(keys(aws_ssmcontacts_rotation.shift_rotations), shift)
    ])
  }
}

// Escalation Plan ARNs
locals {
  escalation_plan_arns = {
    for plan in var.escalation_plans :
    plan.name => aws_ssmcontacts_contact.escalation_plan[plan.name].arn
  }
}

// Mapped Stages
locals {
  mapped_stages = {
    for idx, plan in var.escalation_plans : plan.name => {
      name   = plan.name
      stages = [
        for stage in plan.stages : {
          source_arn = local.escalation_plan_arns[plan.name]
          targets = [
            for contact in stage.target_contacts : {
              target_arn = contains(keys(var.oncall_schedule_contacts), contact) ? awscc_ssmcontacts_contact.oncall_schedule[contact].arn : null
            }
          ]
          duration_in_minutes = stage.stage_duration
        }
      ]
    }
  }
}

// Response Plan
locals {
  response_plan = [
    for plan in var.response_plan : {
      name                   = plan.name
      incident_title         = plan.incident_title
      incident_description   = plan.incident_description
      impact                 = plan.impact
      slack_chat_enable      = plan.slack_chat_enable
      target_engagement_plan = [
        for tep in plan.target_engagement_plan : local.escalation_plan_arns[tep]
      ]
    }
    if plan.slack_chat_enable == false
  ]
}
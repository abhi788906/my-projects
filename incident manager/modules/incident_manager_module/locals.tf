locals {
  # Valid Contacts
  # Filter valid contacts from the input variable `var.contacts`.
  # Only include contacts that have either a non-empty email or a valid mobile number (not null).
  valid_contacts = [
    for contact_key, contact in var.contacts :
    contact if (contact.email != "" || (contact.mobile_number != "" && contact.mobile_number != null))
  ]

  # Shift Contacts
  # Mapping of contacts to their respective shifts (morning, evening, night).
  # Each shift is linked to a list of valid contacts, filtered based on the `var.schedule` definitions.
  shift_contacts = {
    for shift_key, shift_details in var.schedule : shift_key => [
      for contact in local.valid_contacts : contact if contains(shift_details.contacts, contact.name)
    ]
  }

  # Shift Configurations
  # Prepare shift configurations for on-call rotations.
  # Generates the necessary data for creating SSM on-call rotations, including contact ARNs, timezones, and shift details.
  shift_configurations = [
    for shift_name, shift_details in var.schedule : {
      name          = shift_name
      contact_ids   = local.shift_contacts_arns[shift_name]  # Fetch contact ARNs dynamically from `local.shift_contacts_arns`.
      time_zone_id  = shift_details.time_zone            # Timezone for the shift (e.g., UTC, PST).
      hand_off_time = shift_details.shift_change_time           # Time for hand-off between contacts.
      coverage      = shift_details.shift_hours                # Coverage duration for the shift.
    #   shift_coverages = shift_details.shift_coverages      # Work in progress: Coverage details will be added later.
    }
  ]

  # Shift Contacts ARNs
  # Map contact ARNs to their respective shifts for use in rotation schedules.
  # Ensures only valid contacts (part of the shift and found in SSM Contacts) are included.
  shift_contacts_arns = {
    for shift_key, shift_details in var.schedule : shift_key => [
      for contact in local.valid_contacts : aws_ssmcontacts_contact.incident_contacts[contact.name].arn
      if contact != null && contains(shift_details.contacts, contact.name) && contains(keys(aws_ssmcontacts_contact.incident_contacts), contact.name)
    ]
  }

  # Collect rotation IDs from the created SSM on-call rotations.
  # This list will contain the unique IDs of each on-call rotation, useful for managing or tracking rotations.
  rotation_ids = [for rotation in aws_ssmcontacts_rotation.shift_rotations : rotation.id]

  # Map escalation plan ARNs by name.
  # For each escalation plan, the corresponding ARN is stored in a map for later use (e.g., in stages or incident workflows).
  escalation_plan_arns = {
    for plan in var.escalation_plans :
    plan.name => aws_ssmcontacts_contact.escalation_plan[plan.name].arn  # Use the ARN of each escalation plan.
  }

  # Define the stages and their respective contacts for the escalation plan.
  # This map specifies which contacts will be targeted at each stage of an escalation.

  mapped_stages = {
  for idx, plan in var.escalation_plans : plan.name => {
    name   = plan.name
    stages = [
      for stage in plan.stages : {
        source_arn = local.escalation_plan_arns[plan.name]
        targets = [
          for contact in stage.target_contacts : {
            target_arn = contains(var.oncall_schedule_contacts, contact) ? awscc_ssmcontacts_contact.oncall_schedule[contact].arn : null
          }
        ]
        duration_in_minutes = stage.stage_duration
      }
    ]
  }
}

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

# Outputs for various shift contacts and rotations

# output "morning_shift_contacts" {
#   value = local.morning_shift_contact_ids
# }

# output "evening_shift_contacts" {
#   value = local.evening_shift_contact_ids
# }

# output "night_shift_contacts" {
#   value = local.night_shift_contact_ids
# }

# output "morning_shift_contact_ids" {
#   value = local.morning_shift_contacts
# }

# output "morning_oncall_rotation" {
#   value = aws_ssmcontacts_rotation.morning_contacts_rotation.arn
# }

# output "rotation_schedules" {
#   value = local.rotation_schedules
# }

output "escalation_mapping" {
  value = local.escalation_plan_arns
}

output "mapped_stages" {
  value = local.mapped_stages
}

output "response_plan" {
  value = local.response_plan
}

output "oncall_schedule_contact_details" {
  value = local.oncall_schedule_contact_details
}



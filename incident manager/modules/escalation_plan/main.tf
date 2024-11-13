# Locals for escalation plans
# locals {
#   escalation_plans = var.escalation_plans
# }

# ### Escalation Plan
# The following resource creates contacts for the escalation plans.
# resource "aws_ssmcontacts_contact" "escalation_plans" {
#   for_each     = { for idx, contact in local.escalation_plans : idx => contact }
#   display_name = each.value.name
#   alias        = each.value.alias
#   type         = "ESCALATION"
# }

# ### Configure Escalation Plan Stages
# The following resource configures the stages for the escalation plan.
# resource "aws_ssmcontacts_plan" "escalation_plan_config" {
#   for_each   = { for idx, contact in local.escalation_plans : idx => contact }
#   depends_on = [aws_ssmcontacts_contact.escalation_plans]

#   contact_id = aws_ssmcontacts_contact.escalation_plans[each.key].arn

#   dynamic "stage" {
#     for_each = each.value.stages
#     content {
#       duration_in_minutes = stage.value.duration_in_minutes

#       dynamic "target" {
#         for_each = stage.value.target
#         content {
#           # Configure contact targets
#           dynamic "contact_target_info" {
#             for_each = [for t in [target.value] : t if t.type == "personal"]
#             content {
#               is_essential = target.value.is_essential
#               contact_id   = target.value.contact_id
#             }
#           }

#           # Configure channel targets
#           dynamic "channel_target_info" {
#             for_each = [for t in [target.value] : t if t.type == "channel"]
#             content {
#               retry_interval_in_minutes = target.value.retry_interval_in_minutes
#               contact_channel_id = target.value.contact_id
#             }
#           }
#         }
#       }
#     }
#   }

#   # Add more stages dynamically if needed by extending the code
# }



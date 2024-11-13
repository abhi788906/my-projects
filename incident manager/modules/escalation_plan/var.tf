# variable "escalation_plans" {
#   description = "Defines the ESCALATION Plan for Incident Management"
#   type = map(list(object({
#     name    = string
#     stages  = list(object({
#       duration_in_minutes = string
#       target              = list(object({
#         # Define the fields for the target as needed
#         # Example fields:
#         # contact_id   = string   # The ID of the contact to notify
#         # is_essential = bool     # Indicates if this target is essential for the escalation
#       }))
#     }))
#   })))
# }

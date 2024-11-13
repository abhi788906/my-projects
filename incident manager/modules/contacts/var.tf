# Variable Definitions

variable "contacts" {
  description = "A map of contacts with their details including name, email, and mobile number."
  
  type = map(object({
    name          = string
    email         = string
    mobile_number = string
  }))
}

# Variable for the on-call schedule contacts
variable "oncall_schedule_contacts" {
  description = "A list of on-call schedule contacts."
  type        = map(object({
    schedule = list(string)
    name = string
  }))
}

variable "schedule" {
  description = "A mapping of schedules to contacts."
  type = map(object({
    contacts          = list(string)
    shift_change_time = object({ hour = number, minute = number })
    shift_hours       = object({ start_hour = number, start_minute = number, end_hour = number, end_minute = number })
    time_zone         = string
    # shift_coverages = list(string)
  }))
}


variable "escalation_plans" {
  description = "Defines the ESCALATION Plan for the Incident Manager."
  type = list(object({
    name             = string
    stages           = list(object({
      target_contacts = list(string)
      stage_duration  = number
      stop_the_alert  = bool
    }))
  }))
}

   variable "response_plan" {
     description = "List of response plans"
     type = list(object({
       name                   = string
       incident_title         = string
       incident_description   = string
       impact                 = number
       slack_chat_enable      = bool
       target_engagement_plan = list(string)
     }))
   }
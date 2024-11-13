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
variable "oncallScheduleContacts" {
  description = "List of on-call schedules with their associated contacts"
  type = list(object({
    name     = string
    contacts = list(string)
  }))
}

variable "schedule" {
  description = "A mapping of schedules to contacts."
  type = map(object({
    contacts          = list(string)
    oncallStartTime = object({ hour = number, minute = number })
    workingHours       = object({ start_hour = number, start_minute = number, end_hour = number, end_minute = number })
    time_zone         = string
    # shift_coverages = list(string)
  }))
}


variable "escalation_plans" {
  description = "Defines the ESCALATION Plan for the Incident Manager."
  type = list(object({
    name             = string
    stages           = list(object({
      escalationChannel = list(string)
      alertTriggerMinutes  = number
      stopAlertProgression  = bool
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
       escalationChannel_engagement_plan = list(string)
     }))
   }
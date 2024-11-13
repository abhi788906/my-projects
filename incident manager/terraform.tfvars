#######################################################
#  Individual Contact Information
#######################################################

contacts = {
  contact_1 = {
    name          = "contact_1"
    email         = ""
    mobile_number = "+917777777777"
  },
  contact_2 = {
    name          = "contact_2"
    email         = "contact2@example.com"
    mobile_number = ""
  },
  contact_3 = {
    name          = "contact_3"
    email         = ""
    mobile_number = "+919898989898"
  },
  contact_4 = {
    name          = "contact_4"
    email         = ""
    mobile_number = "+91888888888"
  }
}

#######################################################
#  Schedule Mapping
#######################################################

schedule = {
  morning = {
    contacts          = ["contact_1", "contact_2", "contact_3"] # Morning shift contacts
    shift_change_time = { hour = 9, minute = 0 }
    shift_hours       = { start_hour = 8, start_minute = 30, end_hour = 17, end_minute = 0 }
    time_zone         = "Asia/Kolkata"
    
    # shift_coverages = ["MON", "TUE", "WED", "THU", "FRI"]
  },
  evening = {
    contacts          = ["contact_3"] # Evening shift contacts
    shift_change_time = { hour = 9, minute = 0 }
    shift_hours       = { start_hour = 8, start_minute = 30, end_hour = 17, end_minute = 0 }
    time_zone         = "Asia/Kolkata"
    # shift_coverages = ["MON", "TUE", "WED", "THU", "FRI"]
  },
  night = {
    contacts          = ["contact_4", "contact_1"] # Night shift contacts
    shift_change_time = { hour = 9, minute = 0 }
    shift_hours       = { start_hour = 8, start_minute = 30, end_hour = 17, end_minute = 0 }
    time_zone         = "Asia/Kolkata"
    # shift_coverages = ["MON", "TUE", "WED", "THU", "FRI"]
  }
}

oncall_schedule_contacts = {
  oncall_schedule_1 = {
    schedule = ["morning", "evening"]
    name = "oncall_schedule_1"
  },
  oncall_schedule_2 = {
    schedule = ["night", "morning"]
    name = "oncall_schedule_2"
  }
}

#######################################################
#  Escalation Plan
#######################################################

escalation_plans = [
  {
    name = "escalation_plan_1"
    stages = [
      {
        target_contacts = ["oncall_schedule_1"] # Specifies the contacts being engaged during the incident.
        stage_duration  = 0                    # The duration is the amount of time until the next stage begins (In minutes)
        stop_the_alert  = true                 # Determining if the contact's acknowledgement stops the progress of stages in the plan.
      }
    ]
  },
  {
    name = "escalation_plan_2"
    stages = [
      {
        target_contacts = ["oncall_schedule_2"] # Specifies the contacts being engaged during the incident.
        stage_duration  = 1                      # The duration is the amount of time until the next stage begins (In minutes)
        stop_the_alert  = true                   # Determining if the contact's acknowledgement stops the progress of stages in the plan.
      },
      {
        target_contacts = ["oncall_schedule_2"] # Specifies the contacts being engaged during the incident.
        stage_duration  = 0                      # The duration is the amount of time until the next stage begins (In minutes)
        stop_the_alert  = true                   # Determining if the contact's acknowledgement stops the progress of stages in the plan.
      }
    ]
  }
]

#######################################################
#  Response Plan
#######################################################

response_plan = [
  {
    name                   = "response_plan_1"
    incident_title         = "EC2 Instance alert"
    incident_description   = "Purpose of the Alert"
    impact                 = 1 # 0 - Critical, 1 - High
    slack_chat_enable      = false
    target_engagement_plan = ["escalation_plan_1"]
  },
  {
    name                   = "response_plan_2"
    incident_title         = "EC2 Instance alert"
    incident_description   = "Purpose of the Alert"
    impact                 = 1 # 0 - Critical, 1 - High
    slack_chat_enable      = false
    target_engagement_plan = ["escalation_plan_2"]
  }
]
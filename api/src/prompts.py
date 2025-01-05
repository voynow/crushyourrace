from string import Template

PSEUDO_TRAINING_WEEK_PROMPT = Template(
    """${COACH_ROLE}

Your athlete has provided the following preferences:
${user_preferences}

Here is the athlete's activity for the past ${n_days} days:
${last_n_days_of_activity}

The athlete has completed ${miles_completed_this_week} miles this week and has ${miles_remaining_this_week} miles remaining (if we are halfway through the week and this goal is no longer realistic, that is fine just ensure the athlete finished out the week safely)

Additionally, here are some notes you have written on recommendations for the week in question:
${mileage_recommendation}

Lets generate a pseudo-training week for the next ${n_remaining_days} days:
${rest_of_week}"""
)

TRAINING_WEEK_PROMPT = Template(
    """${COACH_ROLE}

Your athlete has provided the following preferences:
${preferences}

Here is the pseudo-training week you created for your athlete:
${pseudo_training_week}

Here are some notes you have written on recommendations for the week in question:
${mileage_recommendation}

Please create a proper training week for the next ${n_days} days based on the information provided."""
)

COACHES_NOTES_PROMPT = Template(
    """${COACH_ROLE}
                                
Your athlete has provided the following preferences:
${user_preferences}

Your client's past 7 days of activity:
${past_7_days}

Your client's activity from today:
${activity_of_interest}

Now write a comment (2-3 sentences) to your client about their activity from today (${day_of_week}) in the context of their recent activity and goals. Make assumptions if necessary about their behavior and goals based on their activity."""
)

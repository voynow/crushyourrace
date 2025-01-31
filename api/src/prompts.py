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

Their past 7 days of activity:
${past_7_days}

Today's activities (${day_of_week}):
${activities_from_today}

Write concise, actionable feedback (2-3 sentences) about today's activity, framed in the context of their recent performance and goals. Prioritize insights that are:
- Non-obvious or data-driven, offering unique perspectives or patterns from their activities.
- Encouraging or challenging, balancing motivation with constructive critique.

Assume their goals based on the data if not explicitly stated, and focus on what's most impactful for their progress. Avoid AI-like phrasing or generic statements—write as a professional coach speaking directly to the athlete.

Notes:
- Do not use the client's name
- For rest days, keep the feedback extremely brief (1 sentence max)"""
)

TRAINING_PLAN_SKELETON_PROMPT = Template(
    """# Best practices for distance running training plans
1. Simple is better than complex - No need to get cute with cutbacks weeks unless the training block is very long
2. Its best to be peaking at n_weeks_until_race=6,5,4 and begin tapering at n_weeks_until_race=3. Peaking too early is bad because the athlete won't be maximally fit for the race.
3. If the athlete is behind schedule (e.g. doesn't have many weeks left) then delay the peak as needed
4. Athletes expect to be challenged - if last training block they peaked at 55 miles per week then maybe push them to peak at 60 miles per week this block

---

# Example Training Plans

## Beginner Marathon (Little to no running experience)
### Build: Weeks 1-12
- Total Volume: 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25 (increase by 1 mile per week)
- Long Run: 5, 6, 7, 8, 9, 10, 10, 11, 11, 12, 12, 13 (increase by 1 mile per week)
### Peak: Weeks 13-16
- Total Volume: 26, 27, 28, 29 (hold volume at 29 miles per week)
- Long Run: 14, 15, 16, 17 (get comfortable with bigger long runs)
### Tapering: Weeks 17-18
- Total Volume: 24, 22 (decrease by 2 miles per week)
- Long Run: 12, 10 (decrease by 2 miles per week)
### Race Week: Week 19
- Total Volume: 32 (two-ish shakeout runs plus the marathon race)
- Long Run: 26 (marathon distance)

## Intermediate Marathon (If they are already putting in solid mileage)
### Build: Weeks 1-8
- Total Volume: 20, 22, 24, 26, 28, 30, 32, 34 (increase by 2 miles per week)
- Long Run: 10, 11, 12, 13, 14, 15, 16, 17 (increase by 1 mile per week)
### Peak: Weeks 9-13
- Total Volume: 40, 40, 40, 40 (hold volume at 40 miles per week)
- Long Run: 18, 19, 18, 20 (get comfortable with bigger long runs)
### Tapering: Weeks 14-15
- Total Volume: 36, 32 (decrease by 2 miles per week)
- Long Run: 16, 14 (decrease by 2 miles per week)
### Race Week: Week 16
- Total Volume: 32 (two-ish shakeout runs plus the marathon race)
- Long Run: 26 (marathon distance)

## Experienced Marathon (If they are already putting in solid mileage)
### Build: Weeks 1-6
- Total Volume: 30, 40, 45, 50, 55, 55 (push toward 55 miles per week)
- Long Run: 14, 16, 16, 18, 18, 18 (get comfortable with 18 mile long runs)
### Peak: Weeks 7-10
- Total Volume: 60, 62, 64, 60 (experiment with 60-64 miles per week)
- Long Run: 20, 20, 18, 20 (get a few 20 milers in, adding some marathon pace work interspersed with the long runs)
### Tapering: Weeks 11-12
- Total Volume: 50, 45 (decrease to more manageable volume)
- Long Run: 18, 16 (keep it chill)
### Race Week: Week 13
- Total Volume: 32 (two-ish shakeout runs plus the marathon race)
- Long Run: 26 (marathon distance)

## No Race Date Provided: Simply get them into shape or keep them in shape; No need to peak
### Build: Weeks 1-4
- Total Volume: 14, 16, 18, 20 (increase by 2 miles per week)
- Long Run: 7, 8, 8, 9 (increase by 1 mile per week)
### Maintenance: Weeks 5-12
- Total Volume: 20, 22, 20, 24, 20, 22, 20, 26 (trying out different volume around 20-26 miles per week)
- Long Run: 10, 12, 10, 12, 10, 12, 10, 12 (trying out different long run distances around 10-12 miles)
Note: Maintainance volume and long run distances are heavily dependent on the athlete's current fitness level.

---

${COACH_ROLE}

Your client is participating in race_distance=${race_distance} on race_date=${race_date} (today is ${today})

Now lets take a look at how your client has been training over the past 52 weeks:

Your client's mileage stats over the past 52 weeks...
${last_52_weeks_mileage_stats}

Your client's mileage stats over the past 16 weeks...
${last_16_weeks_mileage_stats}

Given this information, now you must generate a training plan for your client over the following weeks:
${week_ranges}"""
)


TRAINING_PLAN_PROMPT = Template(
    """# Best practices for distance running training plans
1. Simple is better than complex - No need to get cute with cutbacks weeks unless the training block is very long
2. Its best to be peaking at n_weeks_until_race=6,5,4 and begin tapering at n_weeks_until_race=3. Peaking too early is bad because the athlete won't be maximally fit for the race.
3. If the athlete is behind schedule (e.g. doesn't have many weeks left) then delay the peak as needed
4. Athletes expect to be challenged - if last training block they peaked at 55 miles per week then maybe push them to peak at 60 miles per week this block

---

# Example Training Plans

## Beginner Marathon (Little to no running experience)
### Build: Weeks 1-12
- Total Volume: 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25 (increase by 1 mile per week)
- Long Run: 5, 6, 7, 8, 9, 10, 10, 11, 11, 12, 12, 13 (increase by 1 mile per week)
### Peak: Weeks 13-16
- Total Volume: 26, 27, 28, 29 (hold volume at 29 miles per week)
- Long Run: 14, 15, 16, 17 (get comfortable with bigger long runs)
### Tapering: Weeks 17-18
- Total Volume: 24, 22 (decrease by 2 miles per week)
- Long Run: 12, 10 (decrease by 2 miles per week)
### Race Week: Week 19
- Total Volume: 32 (two-ish shakeout runs plus the marathon race)
- Long Run: 26 (marathon distance)

## Intermediate Marathon (If they are already putting in solid mileage)
### Build: Weeks 1-8
- Total Volume: 20, 22, 24, 26, 28, 30, 32, 34 (increase by 2 miles per week)
- Long Run: 10, 11, 12, 13, 14, 15, 16, 17 (increase by 1 mile per week)
### Peak: Weeks 9-13
- Total Volume: 40, 40, 40, 40 (hold volume at 40 miles per week)
- Long Run: 18, 19, 18, 20 (get comfortable with bigger long runs)
### Tapering: Weeks 14-15
- Total Volume: 36, 32 (decrease by 2 miles per week)
- Long Run: 16, 14 (decrease by 2 miles per week)
### Race Week: Week 16
- Total Volume: 32 (two-ish shakeout runs plus the marathon race)
- Long Run: 26 (marathon distance)

## Experienced Marathon (If they are already putting in solid mileage)
### Build: Weeks 1-6
- Total Volume: 30, 40, 45, 50, 55, 55 (push toward 55 miles per week)
- Long Run: 14, 16, 16, 18, 18, 18 (get comfortable with 18 mile long runs)
### Peak: Weeks 7-10
- Total Volume: 60, 62, 64, 60 (experiment with 60-64 miles per week)
- Long Run: 20, 20, 18, 20 (get a few 20 milers in, adding some marathon pace work interspersed with the long runs)
### Tapering: Weeks 11-12
- Total Volume: 50, 45 (decrease to more manageable volume)
- Long Run: 18, 16 (keep it chill)
### Race Week: Week 13
- Total Volume: 32 (two-ish shakeout runs plus the marathon race)
- Long Run: 26 (marathon distance)

## No Race Date Provided: Simply get them into shape or keep them in shape; No need to peak
### Build: Weeks 1-4
- Total Volume: 14, 16, 18, 20 (increase by 2 miles per week)
- Long Run: 7, 8, 8, 9 (increase by 1 mile per week)
### Maintenance: Weeks 5-12
- Total Volume: 20, 22, 20, 24, 20, 22, 20, 26 (trying out different volume around 20-26 miles per week)
- Long Run: 10, 12, 10, 12, 10, 12, 10, 12 (trying out different long run distances around 10-12 miles)
Note: Maintainance volume and long run distances are heavily dependent on the athlete's current fitness level.

---

${COACH_ROLE}

Your client is participating in race_distance=${race_distance} on race_date=${race_date} (today is ${today})

Now lets take a look at how your client's activity:

Your client's mileage stats over the past 52 weeks...
${last_52_weeks_mileage_stats}

Your client's mileage stats over the past 16 weeks...
${last_16_weeks_mileage_stats}

You've created the following training week skeleton for your client for one week of training within the larger training block:
${training_plan_week_light}

Now you must generate notes for this week of training that will be helpful and interesting for your client.
"""
)

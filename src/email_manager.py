import os
import uuid
from datetime import datetime
from typing import Dict

import sib_api_v3_sdk
from dotenv import load_dotenv

from src.types.mid_week_analysis import MidWeekAnalysis
from src.types.training_week import TrainingWeekWithCoaching, TrainingWeekWithPlanning

load_dotenv()

configuration = sib_api_v3_sdk.Configuration()
configuration.api_key["api-key"] = os.environ["EMAIL_API_KEY"]

api_instance = sib_api_v3_sdk.TransactionalEmailsApi(
    sib_api_v3_sdk.ApiClient(configuration)
)


def space(n: int = 1):
    return "&nbsp;" * n


def training_week_update_to_html(
    mid_week_analysis: MidWeekAnalysis,
    training_week_update_with_planning: TrainingWeekWithPlanning,
) -> str:
    """
    Convert updated training week data to HTML content for email.

    :param mid_week_analysis: MidWeekAnalysis object containing completed activities.
    :param training_week_update_with_planning: TrainingWeekWithPlanning object containing updated plan.
    :return: HTML content for email.
    """
    uid = str(uuid.uuid4())

    completed_sessions = {}
    for activity in mid_week_analysis.activities:
        activity_datetime = datetime.strptime(
            activity.date_and_time, "%A, %B %d, %Y %I:%M %p"
        )
        completed_sessions[activity_datetime.strftime("%A").lower()] = activity

    total_miles = round(mid_week_analysis.miles_target, 1)
    miles_remaining = round(mid_week_analysis.miles_remaining, 1)

    html_content = """
    <html>
    <head>
        <style>
            body {
                font-family: Arial, sans-serif;
                background-color: #f4f4f4;
                color: #333;
                margin: 0;
                padding: 0;
            }
            .container {
                width: 100%;
                max-width: 600px;
                margin: 20px auto;
                background-color: #ffffff;
                border-radius: 10px;
                box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
                overflow: hidden;
            }
            .header {
                background-color: #6495ED;
                color: #ffffff;
                text-align: center;
                padding: 20px;
            }
            .header h1 {
                margin: 0;
                font-size: 24px;
            }
            .content {
                padding: 20px;
            }
            .content h2 {
                color: #6495ED;
                font-size: 20px;
                margin-bottom: 10px;
            }
            .content ul {
                list-style-type: none;
                padding: 0;
                margin: 0;
            }
            .content li {
                margin-bottom: 10px;
                padding: 15px;
                border-left: 5px solid #6495ED;
                border-radius: 5px;
                color: #333;
            }
            .content li.completed {
                background-color: #f9f9f9;
                border-left-color: #28a745;
            }
            .content li.upcoming {
                background-color: #f9f9f9;
                border-left-color: #6495ED;
            }
            .content li strong {
                display: block;
                font-size: 16px;
                margin-bottom: 5px;
                color: #333;
            }
            .miles-summary {
                display: flex;
                justify-content: space-between;
                align-items: center;
                background-color: #6495ED;
                padding: 20px 30px;
                margin-top: 20px;
                border-radius: 10px;
                box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
                text-align: center;
            }
            .miles-info {
                flex: 1;
            }
            .miles-label {
                font-size: 18px;
                color: #ffffff;
                margin-bottom: 5px;
            }
            .footer {
                background-color: #f1f1f1;
                text-align: center;
                padding: 10px;
                font-size: 9px;
                color: #777;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Updated Training Schedule</h1>
            </div>
            <div class="content">
                <ul>
    """
    # Add completed activities
    for day, activity in completed_sessions.items():
        html_content += f"""
                <li class="completed">
                    <strong>{day.capitalize()}</strong>
                    <span>Completed: {activity.distance_in_miles} miles</span><br>
                    <span>Pace: {activity.pace_minutes_per_mile} min/mile</span><br>
                    <span>Elevation Gain: {activity.elevation_gain_in_feet} feet</span>
                </li>
        """

    html_content += """
                </ul>
                <ul>
    """
    # Add upcoming training plan
    for session in training_week_update_with_planning.training_week:
        html_content += f"""
                <li class="upcoming">
                    <strong>{session.day.capitalize()}</strong>
                    <span>{session.session_type.value} {session.distance} miles</span><br>
                    <span>Planned: {session.notes}</span>
                </li>
        """

    html_content += f"""
                </ul>
                <div class="miles-summary" style="text-align: center;">
                    <div class="miles-info" style="margin: 0 auto;">
                        <span class="miles-label">Total Miles Planned: {total_miles}{space(8)}Miles Remaining: {miles_remaining}</span>
                    </div>
                </div>
            </div>
            <div class="footer">
                <p style="font-size: 15px; color: #777;">Powered by the Strava API and OpenAI</p>
                <p>{uid}</p>
            </div>
        </div>
    </body>
    </html>
    """
    return html_content


def training_week_to_html(training_week_with_coaching: TrainingWeekWithCoaching) -> str:
    """
    Convert a TrainingWeek object to HTML content for email

    :param training_week: TrainingWeek object
    :return: HTML content for email
    """
    uid = str(uuid.uuid4())
    total_miles = sum(
        [session.distance for session in training_week_with_coaching.training_week]
    )

    html_content = """
    <html>
    <head>
        <style>
            body {
                font-family: Arial, sans-serif;
                background-color: #f4f4f4;
                color: #333;
                margin: 0;
                padding: 0;
            }
            .container {
                width: 100%;
                max-width: 600px;
                margin: 20px auto;
                background-color: #ffffff;
                border-radius: 10px;
                box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
                overflow: hidden;
            }
            .header {
                background-color: #6495ED;
                color: #ffffff;
                text-align: center;
                padding: 20px;
            }
            .header h1 {
                margin: 0;
                font-size: 24px;
            }
            .content {
                padding: 20px;
            }
            .content h2 {
                color: #6495ED;
                font-size: 20px;
                margin-bottom: 10px;
            }
            .content ul {
                list-style-type: none;
                padding: 0;
                margin: 0;
            }
            .content li {
                background-color: #f9f9f9;
                margin-bottom: 10px;
                padding: 15px;
                border-left: 5px solid #6495ED;
                border-radius: 5px;
                color: #333;
            }
            .content li strong {
                display: block;
                font-size: 16px;
                margin-bottom: 5px;
                color: #333;
            }
           .miles-summary {
                display: flex;
                justify-content: space-between;
                align-items: center;
                background-color: #6495ED;
                padding: 20px 30px;
                margin-top: 20px;
                border-radius: 10px;
                box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
                text-align: center;
            }
            .miles-info {
                flex: 1;
            }
            .miles-label {
                font-size: 18px;
                color: #ffffff;
                margin-bottom: 5px;
            }
            .mileage-target-section {
                margin-top: 30px;
                padding: 20px;
                background-color: #f9f9f9;
                border-radius: 10px;
                box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
            }
            .footer {
                background-color: #f1f1f1;
                text-align: center;
                padding: 10px;
                font-size: 9px;
                color: #777;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h1>Your Training Schedule</h1>
            </div>
            <div class="content">
                <h2>Get pumped for this week's training.</h2>
                <ul>
    """
    for session in training_week_with_coaching.training_week:
        html_content += f"""
                <li>
                    <strong>{session.day.capitalize()}</strong>
                    <span>{session.session_type.value} {session.distance} miles</span><br>
                    <span>Notes: {session.notes}</span>
                </li>
        """
    html_content += f"""
                </ul>
                <div class="miles-summary" style="text-align: center;">
                    <div class="miles-info" style="margin: 0 auto;">
                        <span class="miles-label">Total Miles Planned: {total_miles}</span>
                    </div>
                </div>
                <div class="mileage-target-section">
                    <h2>Coach's Recommendation</h2>
                    <p>{training_week_with_coaching.weekly_mileage_target}</p>
                </div>
            </div>
            <div class="footer">
                <p style="font-size: 15px; color: #777;">Powered by the Strava API and OpenAI</p>
                <p>{uid}</p>
            </div>
        </div>
    </body>
    </html>
    """
    return html_content


def send_email(
    subject: str,
    html_content: str,
    to: list = [{"email": "voynow99@gmail.com", "name": "Jamie Voynow"}],
    sender: Dict[str, str] = {
        "name": "Jamie Voynow",
        "email": "voynowtestaddress@gmail.com",
    },
) -> sib_api_v3_sdk.CreateSmtpEmail:
    send_smtp_email = sib_api_v3_sdk.SendSmtpEmail(
        to=to, html_content=html_content, sender=sender, subject=subject
    )
    return api_instance.send_transac_email(send_smtp_email)

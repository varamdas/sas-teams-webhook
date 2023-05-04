# teams-webhook-test
Test repository to use with SAS program and MS Teams webhook.
Process involves SAS program that makes API call to GitHub (GET request using PROC  HTTP) and pulls out desired information before making a post call to a webhook configured Microsoft Teams Team channel. The webhook posts a Teams card with information regarding activity for this project.

The information posted includes the list of contributors, the number of pushes, the number of issues raise, and the number of additional events that occurred. Moreover, a list of the commit messages is included as well. Information included on this card will be adjusted over time.

As of now, the goal is to have the information described above constrained to just the day the request is made. This can be easily adjusted so the card provides a view of weekly or even lifetime activity.

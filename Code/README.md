# sas-teams-webhook: Code
This folder contains the code used to make the API call to GitHub for this project as well as the POST call to the webhook. This specific ReadMe will include the most up-to-date information on the program, how it works and how to use it, and the macro variables used in the program.

# Macro Variables
- user: The username of the repository owner. In this case it is "varamd" for this repository.
- repo: The name of the repository whose information is being accssed. In this case it is "sas-teams-webhook".
- token: The token associated with your git profile. The main README contains instructions for generating this token.
- weekly_wind: Value that determines if the data is filtered to only include activity from this past week. Meant to be either "Y" (case insensitive) or "N", but any value that is not "Y" or "y" will result in the filter not being applied.
- runDate: Holds the value for the date the program was run (equivalently, the date the GitHub API was called and information was collected).
- push: Holds the value for the number of push events for the repository during either the current week or the past 90 days.
- issue: Holds the value for the number of issues raised for the repository during either the currrent week or the past 90 days.
- misc: Holds the value for the number of non-push and non-issue events for the repository during either the current week or the past 90 days.
- contributors: Holds the list of contributors to the repository during the current week or the past 90 days.
- commitMessage: Holds a list of commit messages associated with any commits that have happened during the current week or the past 90 days.
- issueTitle: Holds a list of commit messages associated with any commits that have happened during the current week or the past 90 days.
- json: Holds the initial json that is sent as part of the POST request in order to create the Teams card. All macro variables are surrounded by %bquote().
- qjson: Takes the json stored in the macro above and uses two other marco functions in %superq and %tslit to ensure proper resolution of macro variables in the json being submitted in the PROC HTTP request.

# Usage

## Setting up Macros, JSON, and Webhook URL
Setting up and using this program is fairly straightforward. Once the prerequsite steps, outlined in the main README file, are complete, a user only needs to populate the values for some of the above macros and make some small changes to run the program. First, users must populate the macro variables for user, repo, and token. Users must specify their GitHub username, the repository they want information from, and the token created in the prerequisite steps. It is also easy to apply this program to different repositories, so long as the appropriate values for the user and repo macro variables are specified and users have permissions to get information from that repository. The only other macro variable left to specify is the weekly_wind variable, which will filter the data down to the current week's activity if provided a "y" value (case insensitive). The logical other value is "N", but the way the program is written any non-Y value will result in no time-based filtering. 

Another thing users should look over is the URLs included in the JSON for the repository itself, the issues page, and the commits page. These are currently set to the appropriate URLs for this repository. If you want the buttons in the resulting Teams card to lead to the appropriate repository and its associated pages, you must update those URLs.

The final thing users must provide is the URL for the webhook and make sure they paste that URL into the second PROC HTTP step at the end of the program. Note that the process for getting that webhook URL is outlined in the prequisite steps in the main README file.

For more information on where these variables and URLs are used, refer to the images below.  
- Macro variables for user, repo, and token.  
    !["Image of API call to GitHub with user-specific macros"](./Images/Call_Macros.png)  
- Macro variable for time window.
    !["Image of time window macro variable and code using it"](./Images/Time_Macro.png) 
- URLs that should be updated in JSON.
    !["Image of repository-specific URLs"](./Images/JSON_URLs.png)
- URL for webhook accepting POST request.
    !["Image of where to specify Teams webhook URL"](./Images/Webhook_URL.png)  

Once those macros are specified and the webhook URL is included, the program should be ready to run. The other macro variables are created as part of the program and will have values based on the repository and time frame specified. There is a lot of room for flexibility with this program to adapt it as well. 

## Potential Changes, Notes, and Use in Workflow
Some potential changes may involved changing the the types of time windows you are interested in and creating one for daily or maybe monthly acitivty. The filtering for the time window occurs in the data step where the activity table is created, so users could create a new time-related macro and make changes to the code here to update the time filter being applied. Note that if specifiying a time window that is not a week, you will have to make some changes to the variables that are created and used in the conditional logic in this code block. Also keep in mind that the GitHub API will only keep up to 90 days of information, so any window longer than that will not return any additional information. 

Users may also want to include other information in the Teams card and can examine the data returned by the API call to GitHub to find other useful data. Moreover, GitHub has API documentation covering other APIs one can call out to. Thus, one could adapt this program to hit other GithUb APIs. Additionally, users may want to format the Teams card differently and can leverage Microsoft's card-building sandbox to see what the card would look like as they make changes. Links to the GitHub API documentation and cards playground are included in the main README.

Finally, after getting the program to run users might be interested in how to use this program in a workflow. At a high level, the program is making a call to GitHub's API to grab some information, is processing that information, and then sending that information to a Teams webhook that takes that information and creates a Teams card. This SAS program could be scheduled as a SAS job and run at some consistent interval (daily, weekly, etc.) to automate these updates. For example, taking the program on this repository and scheudling it to run every Friday afternoon in order to send a weekly activity report to a Teams channel. If there is a need for more automatic or real-time updates for a busy repository, the SAS job with this program could run more regularly (every couple of minutes or so) and code could be added to check for any new additions to the repository. If additional pushes, issues, or other events occured, then a card could be sent out to users. Keep in mind the resources being utilized to run that job so often and consider how quickly information updates on GitHub's end when new events occur.

# Future Improvements
- Plans to handle case where there are no events of a given type during a given time window, and returning blank values or a value that indicates no new issues of these types have occurred.

# Resources
- [Resources section on main ReadMe](https://github.com/varamdas/sas-teams-webhook/blob/main/README.md#resources) 
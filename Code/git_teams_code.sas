/* Program containing necessary code for making the API call to GitHub and then the call to the Teams Webhook.
    Code includes API calls and the intermediate steps to get the information needed to generate the Teams card.
    Please consult the README file in the Code folder for information on the macro variables used in the program. */

/* Creates temporary file reference to store JSON output from API call. */
filename resp temp;

/* GET call to GitHub API for repository data. Provide arguments in URL using
	macro variables for user and repository name. Provide authentication token 
	via macro variable. Output stored in resp file. */
proc http url="https://api.github.com/repos/&user/&repo/events"
	oauth_bearer="&token"
	out=resp;
run;

/* Use JSON library engine to take output from API call and convert into SAS datasets
	stored in "git" library. */
libname git json fileref=resp;

/* Takes the dataset that includes all the users who have interacted with the repository
	and joins this with the root dataset that includes a lot of information, but mainly
	the date of various actions on the repository. */
data actor_date;
	merge git.actor(drop=gravatar_id avatar_url) git.root(rename=(id=root_id));
	by ordinal_root;
run;

/* Takes the merged dataset from the previous step and merges with the payload dataset
	to bring in the payload identifier variable, ordinal_payload. */
data date_payload;
	merge actor_date git.payload(keep=ordinal_root ordinal_payload);
	by ordinal_root;
run;

/* Deletes dataset that is not needed going forward. */
proc delete data=actor_date;

/* Merges the dataset created in the prior data step with the dataset containing the content 
	of any commits that have occurred in the past 90 days (as per GitHub documentation). */
data date_commit;
	merge date_payload git.payload_commits(rename=(url=commit_url));
	by ordinal_payload;
run;

/* Deletes dataset that is not needed going forward. */
proc delete data=date_payload;

/* Merges dataset from prior data step with dataset containing content of any issues that have
	been raised in the past 90 days. Additionally, creates variables for filtering by date if
	the macro controlling the week window is activated. If the macro is activated, conditional 
	logic is applied to filter the final table used for building the JSON. If not, all information
	from the past 90 days is included. */
data activity_table;
	merge date_commit git.payload_issue(rename=(url=issue_url id=issue_id));
	by ordinal_payload;
	date = input(scan(created_at, 1, 'T'),YYMMDD10.);
	wk = week(date, 'u');
	yr = year(date);
	format date YYMMDD10.;
	if upcase(&weekly_wind) = 'Y' then do;
		if wk = week(today()) & yr = year(today()) then output;
	end;
	else output;
run;

/* Deletes dataset that is not needed going forward. */
proc delete data=date_commit;

/* Creates dataset containing metrics for number of events grouped by type. If an event does not
	fall into a push or issue category, it is in the misc category. */
data gitstats;
	set activity_table end=last;
	keep pushCount issueCount miscCount;
	if type="PushEvent" then
		pushCount + 1;
	else if type = "IssuesEvent" then
		issueCount + 1;
	else miscCount + 1;
	if last then output;
run;

/* Takes the pushCount value from gitStats and assigns it to a macro variable that will be passed 
	into the input JSON. */
proc sql noprint;
	select pushCount into :push separated by ''
	from gitstats;
quit;
%Put &push;

/* Takes the issueCount value from gitStats and assigns it to a macro variable that will be passed 
	into the input JSON. */
proc sql noprint;
	select issueCount into :issue separated by ''
	from gitstats;
quit;
%Put &issue;

/* Takes the miscCount value from gitStats and assigns it to a macro variable that will be passed 
	into the input JSON. */
proc sql noprint;
	select miscCount into :misc separated by ''
	from gitstats;
quit;
%Put &misc;

/* Takes the names of contributors from the activity table dataset and createst a list macro variable
	that will be passed into the input JSON. This list only contains a name once, even if a user has 
	contributed multiple times in the specified time window. */
proc sql noprint;
	select distinct(display_login) into :contributors separated by ', '
	from activity_table;
quit;
%put &contributors;

/* Takes the commit messages from the activity table dataset and createst a list macro variable
	that will be passed into the input JSON. */
proc sql noprint;
	select message into :commitMessage separated by ', '
	from activity_table
	where not missing(message);
quit;
%put &commitMessage;

/* Takes the titles of any raised issues from the activity table dataset and createst a list macro variable
	that will be passed into the input JSON. */
proc sql noprint;
	select title into :issueTitle separated by ', '
	from activity_table
	where not missing(title);
quit;
%put &issueTitle;

/* Creates macro variable to hold input JSON for the Teams webhook. All macro variables are wrapped in
	%bquote() to ensure the macro variables are processed properly. */
%let json={
	"@type": "MessageCard",
	"@context": "https://schema.org/extensions",
	"summary": "Issue 176715375",
	"themeColor": "0078D7",
	"title": "Repository %bquote(&repo) Summary",
	"sections": [
		{
			"activityTitle": "Activity Report",
			"activitySubtitle": "Week of Activity",
			"activityImage": "https://github.githubassets.com/images/modules/logos_page/GitHub-Mark.png",
			"facts": [
				{
					"name": "Contributors:",
					"value": "%bquote(&contributors)"
				},
				{
					"name": "Number of Pushes:",
					"value": "%bquote(&push)"
				},
                {
                    "name": "Number of Issues Raised:",
                    "value": "%bquote(&issue)"
                },
                {
                    "name": "Number of Misc. Events:",
                    "value": "%bquote(&misc)"
                },
                {
                    "name": "List of Commit Messages:",
                    "value": "%bquote(&commitMessage)"
                },
                {
                    "name": "List of Issue Topics:",
                    "value": "%bquote(&issueTitle)"
                }
			],
			"text": "Summary of activity for the past week for %bquote(&repo) repository."
		}
	],
	"potentialAction": [
        {
            "@type": "OpenUri",
            "name": "Open Repository",
            "targets": [
                {
                    "os": "default",
                    "uri": "https://github.com/varamdas/teams-webhook-test"
                }
            ]
        },
		{
			"@type": "OpenUri",
			"name": "View Issues",
			"targets": [
				{
					"os": "default",
					"uri": "https://github.com/varamdas/teams-webhook-test/issues"
				}
			]
		},
        {
            "@type": "OpenUri",
            "name": "View Commits",
            "targets": [
                {
                    "os": "default",
                    "uri": "https://github.com/varamdas/teams-webhook-test/commits"
                }
            ]
        }
	]
};
/* Takes the json macro we created above and applies other functions to process the macro variables. Thus,
	the resulting json stored in the "qjson" macro has all macro variables resolved and
	is populated with the appropriate values. */
%let qjson = %tslit(%superq(json));

/* POST call to a configured Microsoft Teams webhook. The provided input is the json referenced in the macro
	created above. If everything is done correctly, the code should run with no errors and output will be
	visible in the Teams channel the webhook is configured for. */
filename msg temp;
options noquotelenmax;
proc http
	url="https://sasoffice365.webhook.office.com/webhookb2/82e7c9e4-2973-4e89-a995-4252cf007120@b1c14d5c-3625-45b3-a430-9552373a0c2f/IncomingWebhook/ba47491c0a444397a8b5cae56f40e31f/f2c464fa-8936-43e3-9eeb-05c5d3d88956"
	method="POST"
  	in=&qjson
	out=msg;
	headers "Content-Type" ="text/plain";
run;
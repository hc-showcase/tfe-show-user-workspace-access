#!/bin/sh

#set -x

#At least org token needed
TOKEN=hZRgTAa8m3fV6w.atlasv1.0QeUyKVYySQuoSTDnNWZomqPuD3kyTp23VEOgzokyUMFUJuWLfiwjLY4XxnN0ap0boI
ORG_NAME=mkaesz-dev

# Get all workspaces
all_workspaces=$(curl -s\
  --header "Authorization: Bearer $TOKEN" \
  --header "Content-Type: application/vnd.api+json" \
  https://app.terraform.io/api/v2/organizations/$ORG_NAME/workspaces)

# Extract the workspace ids
workspace_ids=$(echo $all_workspaces | jq -r .data[].id)

# Iterate over all workspaces via workspace id
for workspace in $workspace_ids
do
  # Which teams can access this workspace
  team_access_to_ws=$(curl -s\
    --header "Authorization: Bearer $TOKEN" \
    --header "Content-Type: application/vnd.api+json" \
    https://app.terraform.io/api/v2/team-workspaces?filter%5Bworkspace%5D%5Bid%5D=$workspace | jq -r .data[].relationships.team.data.id)
  
  # Extract the workspace name from the variable with all workspace data
  workspace_name=$(echo $all_workspaces | jq -r --arg workspace "$workspace" '.data[] | select(.id==$workspace) | .attributes.name')

  # If no team can access the workspace then skip this workspace.
  if [ "" != "$team_access_to_ws" ]; then
    for team in $team_access_to_ws
    do
        # Get all user ids that belong to the team	
 	team_data=$(curl -s\
          --header "Authorization: Bearer $TOKEN" \
          --header "Content-Type: application/vnd.api+json" \
	  https://app.terraform.io/api/v2/teams/$team?include=users)

	all_user_ids=$(echo $team_data | jq -r .data.relationships.users.data[].id)
	team_name=$(echo $team_data | jq -r .data.attributes.name)
    
	# Get username via user id. Email is NOT available
        for user in $all_user_ids
        do
	    user_name=$(curl -s\
              --header "Authorization: Bearer $TOKEN" \
              --header "Content-Type: application/vnd.api+json" \
              https://app.terraform.io/api/v2/users/$user | jq -r .data.attributes.username)

	    echo "User \"$user_name\" ($user) can access workspace \"$workspace_name\" ($workspace) via team \"$team_name\" ($team)."
        done
    done
  fi

done

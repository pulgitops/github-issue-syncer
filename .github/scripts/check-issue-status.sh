PROJECT_NODE_ID="$1"
ISSUE_NUMBER="$2"

echo "Checking status of issue #$ISSUE_NUMBER in project node $PROJECT_NODE_ID"

PROJECT_ITEM_ID=$(gh api graphql -f query='
  query($projectNodeId: ID!, $issueNumber: Int!) {
    node(id: $projectNodeId) {
      ... on ProjectV2 {
        items(first: 100, query: $issueNumber) {
          nodes {
            id
            content {
              ... on Issue {
                number
              }
            }
          }
        }
      }
    }
  }' -f projectNodeId="$PROJECT_NODE_ID" -f issueNumber="$ISSUE_NUMBER" --jq '.data.node.items.nodes[] | select(.content.number == '"$ISSUE_NUMBER"') | .id')

  echo "Project item ID: $PROJECT_ITEM_ID"

if [ -z "$PROJECT_ITEM_ID" || "$PROJECT_ITEM_ID" == "null" ]; then
  echo "Issue #$ISSUE_NUMBER not found in project $PROJECT_NODE_ID"
  exit 1
else
  echo "Issue #$ISSUE_NUMBER found in project $PROJECT_NODE_ID"
  exit 0
fi

# Get the status of the issue in the project using the project item ID

ISSUE_STATUS=$(gh api graphql -f query='
  query($projectItemId: ID!) {
    node(id: $projectItemId) {
      ... on ProjectV2Item {
        fieldValues(first: 100) {
          nodes {
            __typename
            ... on ProjectV2ItemFieldTextValue {
                field {
                  ... on ProjectV2SingleSelectField {
                    name
                  }
                }
                name
            }
          }
        }
      }
    }
  }' -f projectItemId="$PROJECT_ITEM_ID" --jq '
    .data.node.fieldValues.nodes
    | map(select(.__typename == "ProjectV2ItemFieldTextValue" and .field.name == "Status"))
    | .[0].name
    ')

if [ -z "$ISSUE_STATUS" || "$ISSUE_STATUS" == "null" ]; then
  echo "Status field not found for issue #$ISSUE_NUMBER in project $PROJECT_NODE_ID"
  exit 1
else
  echo "Issue #$ISSUE_NUMBER status in project $PROJECT_NODE_ID: $ISSUE_STATUS"
  exit 0
fi

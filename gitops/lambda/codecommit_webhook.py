import boto3
import json
import urllib3

codecommit = boto3.client('codecommit')
http = urllib3.PoolManager()

def lambda_handler(event, context):
    # 1. Get metadata from the CodeCommit trigger event

    repo_name = event['Records'][0]['eventSourceARN'].split(':')[-1]
    commit_id = event['Records'][0]['codecommit']['references'][0]['commit']
    full_ref = event['Records'][0]['codecommit']['references'][0]['ref']
    branch = full_ref.split('/')[-1]
    hostname = event['Records'][0].get('customData')
    
    
    # 2. Get the parent commit to find differences
    commit_info = codecommit.get_commit(repositoryName=repo_name, commitId=commit_id)
    parent_id = commit_info['commit']['parents'][0] if commit_info['commit']['parents'] else None
    
    # 3. Find modified files
    changed_files = []
    if parent_id:
        differences = codecommit.get_differences(
            repositoryName=repo_name,
            beforeCommitSpecifier=parent_id,
            afterCommitSpecifier=commit_id
        )
        for diff in differences.get('differences', []):
            # Case: File was Added or Modified
            if 'afterBlob' in diff:
                changed_files.append(diff['afterBlob']['path'])
            # Case: File was Deleted (No afterBlob, but beforeBlob exists)
            elif 'beforeBlob' in diff:
                changed_files.append(diff['beforeBlob']['path'])

    # 4. Construct GitHub-compatible payload for Argo CD
    region = event['Records'][0]['awsRegion']
    payload = {
        "ref": "refs/heads/main",
        "repository": {
            "html_url": f"https://git-codecommit.{region}.amazonaws.com/v1/repos/{repo_name}",           
            "default_branch": branch
        },
        "commits": [{
            "id": commit_id,
            "modified": changed_files
        }]
    }

    # 5. Send to Argo CD
    argo_url = hostname+"/api/webhook"
    encoded_data = json.dumps(payload).encode('utf-8')
    
    response = http.request(
        'POST', 
        argo_url,
        body=encoded_data,
        headers={'Content-Type': 'application/json', 'X-GitHub-Event': 'push'}
    )

    return {"status": response.status}

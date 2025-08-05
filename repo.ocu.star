ocuroot("0.3.0")

# Repository owner and name from the repo URL
owner = "ocuroot"
repo = "vps-demo"

repo_alias("github.com/{}/{}".format(owner, repo))

def init_repo():
    origin_url = host.shell("git remote get-url origin").stdout.strip()

    # Default to ssh for local testing
    repo_url = "ssh://git@github.com/{}/{}.git".format(owner, repo)

    # Always use https for checkout with GitHub actions
    env_vars = host.env()
    if "GH_TOKEN" in env_vars:
        repo_url = "https://x-access-token:{}@github.com/{}/{}.git".format(env_vars["GH_TOKEN"], owner, repo)

    if "OCUROOT_LOCAL_MODE" in env_vars:
        store.set(
            store.fs("./.store"),
        )
        return

    store.set(
        store.git(repo_url, branch="state"),
        intent=store.git(repo_url, branch="intent"),
    )

init_repo()

def do_trigger(commit):
    print("Triggering work for repo at commit " + commit)
    
    # Get environment variables
    env_vars = host.env()
    
    if "GH_TOKEN" in env_vars:
        gh_token = env_vars["GH_TOKEN"]
        
        # GitHub API endpoint for workflow dispatch
        workflow_id = "ocuroot-work-continue.yml"
        url = "https://api.github.com/repos/{}/{}/actions/workflows/{}/dispatches".format(owner, repo, workflow_id)
        
        # Payload with the commit to check out
        payload = json.encode({"ref": "main", "inputs": {"commit_sha": commit}})
        
        # Headers for authentication
        headers = {
            "Accept": "application/vnd.github+json",
            "Authorization": "token " + gh_token,
            "X-GitHub-Api-Version": "2022-11-28"
        }
        
        print("Triggering workflow via GitHub API")
        response = http.post(url=url, body=payload, headers=headers)
        
        if response["status_code"] == 204:
            print("Successfully triggered workflow")
        else:
            print("Failed to trigger workflow. Status code: " + str(response["status_code"]))
            print("Response: " + response["body"])
    else:
        print("GH_TOKEN not available. Cannot trigger GitHub workflow.")

trigger(do_trigger)
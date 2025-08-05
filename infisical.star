ocuroot("0.3.0")

def install_infisical():
    # Alpine
    if host.shell("which apk", continue_on_error=True).exit_code == 0:
        host.shell("apk add --no-cache bash sudo")
        host.shell("curl -1sLf 'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.alpine.sh' | bash")
        host.shell("apk update")
        host.shell("sudo apk add infisical")
    # Debian/Ubuntu
    elif host.shell("which apt-get", continue_on_error=True).exit_code == 0:
        host.shell("curl -1sLf 'https://dl.cloudsmith.io/public/infisical/infisical-cli/setup.deb.sh' | sudo -E bash")
        host.shell("sudo apt-get update && sudo apt-get install -y infisical")
    # MacOS
    elif host.shell("which brew", continue_on_error=True).exit_code == 0:
        host.shell("brew install infisical/get-cli/infisical")
    # Unsupported environment
    else:
        fail("Could not install infisical")

def setup_infisical(project_id, default_env="prod"):
    has_infisical = host.shell("which infisical", continue_on_error=True).exit_code == 0
    if not has_infisical:
        print("Installing infisical")
        install_infisical()

    tokenCheck = host.shell(
            "infisical user get token",
            mute=True,
            continue_on_error=True,
        )
    token = ""
    if tokenCheck.exit_code == 0:
        token = tokenCheck.stdout.strip()
        lines = tokenCheck.stdout.splitlines()
        for line in lines:
            if line.startswith("Token: "):
                token = line[7:].strip()

    # If we don't have a token, authenticate with env vars
    if token == "":
        envs = host.env()
        if "INFISICAL_CLIENT_ID" not in envs or "INFISICAL_CLIENT_SECRET" not in envs:
            fail("INFISICAL_CLIENT_ID and INFISICAL_CLIENT_SECRET must be set")

        print("Logging in with credentials in INFISICAL_CLIENT_ID and INFISICAL_CLIENT_SECRET")
        token = host.shell(
            "infisical login --method=universal-auth --client-id=$INFISICAL_CLIENT_ID --client-secret=$INFISICAL_CLIENT_SECRET --silent --plain",
            env={
                "INFISICAL_CLIENT_ID": envs["INFISICAL_CLIENT_ID"],
                "INFISICAL_CLIENT_SECRET": envs["INFISICAL_CLIENT_SECRET"],
            },
            mute=True
        ).stdout.strip()

    def get_key(id, project_id=project_id, env=default_env):
        v = host.shell(
            'infisical --token=$TOKEN secrets get --projectId=$PROJECT_ID --env=$ENV --plain --silent $ID',
            env={
                "TOKEN": token,
                "PROJECT_ID": project_id,
                "ENV": env,
                "ID": id,
            },
            mute=True
        ).stdout
        return v.strip()

    def set_key(id, value, project_id=project_id, env=default_env):
        host.shell(
            "infisical --token=$TOKEN secrets set --projectId=$PROJECT_ID --env=$ENV \"$ID=$VALUE\"",
            env={
                "TOKEN": token,
                "PROJECT_ID": project_id,
                "ENV": env,
                "ID": id,
                "VALUE": value,
            },
            mute=True
        )

    def delete_key(id, project_id=project_id, env=default_env):
        return host.shell(
            "infisical --token=$TOKEN secrets delete --projectId=$PROJECT_ID --env=$ENV $ID",
            env={
                "TOKEN": token,
                "PROJECT_ID": project_id,
                "ENV": env,
                "ID": id,
            },
            mute=True,
            continue_on_error=True,
        )

    return struct(
        get=get_key,
        set=set_key,
        delete=delete_key,
    )
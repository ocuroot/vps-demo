ocuroot("0.3.0")

def install_terraform():
    # Debian/Ubuntu
    if host.shell("which apt-get", continue_on_error=True).exit_code == 0:
        host.shell("""
            sudo apt-get update && \
            sudo apt-get install -y gnupg software-properties-common && \
            wget -O- https://apt.releases.hashicorp.com/gpg | \
            gpg --dearmor | \
            sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null && \
            gpg --no-default-keyring \
            --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
            --fingerprint && \
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
            https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
            sudo tee /etc/apt/sources.list.d/hashicorp.list && \
            sudo apt update && \
            sudo apt-get install terraform
        """)
    # MacOS
    elif host.shell("which brew", continue_on_error=True).exit_code == 0:
        host.shell("brew tap hashicorp/tap && brew install hashicorp/tap/terraform")
    # Unsupported environment
    else:
        fail("Could not install terraform")

def setup_tf(env, environment, statefile, infisical):
    has_terraform = host.shell("which terraform", continue_on_error=True).exit_code == 0
    if not has_terraform:
        install_terraform()

    pwd = host.shell("pwd").stdout.strip()
    cache_path = "{}/../.ocuroot/terraform/cache/terraform_data_{}_{}".format(pwd,environment.name, statefile)

    host.shell("mkdir -p {}/../.ocuroot/credentials".format(pwd))
    gcp_creds_path = "{}/../.ocuroot/credentials/terraform_state.json".format(pwd)
    gcp_creds = infisical.get("GCP_TERRAFORM_SERVICE_ACCOUNT_KEY")
    if gcp_creds != "":
        host.shell(
            "printenv gcp_creds > $gcp_creds_path",
            env={"gcp_creds": gcp_creds, "gcp_creds_path": gcp_creds_path},
        )

    envs = {
        "TF_VAR_environment": environment.name,
        "TF_DATA_DIR": cache_path,
        "GOOGLE_APPLICATION_CREDENTIALS": gcp_creds_path,
    }

    def exec(cmd, env={}, mute=False, continue_on_error=False):
        newenv = env
        for k, v in envs.items():
            newenv[k] = v

        return host.shell(cmd, env=newenv, mute=mute, continue_on_error=continue_on_error)

    exec("terraform providers lock -platform=linux_amd64")
    exec("""
sh -c '
terraform init \
  --backend-config="prefix={env}/{statefile}" \
-reconfigure'
    """.format(env=environment.name, statefile=statefile))

    def apply(vars={}):
        env_vars = envs
        for k, v in vars.items():
            env_vars["TF_VAR_{}".format(k)] = v

        exec("terraform apply -auto-approve")

        # Get outputs
        tfo = exec("terraform output -json", mute=True)
        tfo_out = json.decode(tfo.stdout)
        
        out = {}
        for k, v in tfo_out.items():
            out[k] = v["value"]
        return out

    def destroy(vars={}):
        env_vars = envs
        for k, v in vars.items():
            env_vars["TF_VAR_{}".format(k)] = v

        exec("terraform destroy -auto-approve")

    def validate(vars={}):
        env_vars = envs
        for k, v in vars.items():
            env_vars["TF_VAR_{}".format(k)] = v

        exec("terraform validate")

    return struct(
        exec=exec,
        apply=apply,
        destroy=destroy,
        validate=validate,
    )
ocuroot("0.3.0")

load("ssh.star", "setup_ssh")
load("infisical.star", "setup_infisical")

def ssh_from_ctx(ctx):
    infisical = setup_infisical(project_id="f7b78b62-9edc-4b41-bc87-37c80b350c10")
    ie = ctx.inputs.environment["attributes"]["infisical_env"]
    
    secret_name = ctx.inputs.ssh_private_key_secret
    priv = infisical.get(secret_name, env=ie)

    return setup_ssh(hostname=ctx.inputs.ip, private_key=priv)
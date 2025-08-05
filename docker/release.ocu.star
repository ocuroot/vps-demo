ocuroot("0.3.0")

load("../infisical.star", "setup_infisical")
load("../ssh.star", "setup_ssh")

# Get all environments
envs = environments()

def _deploy(ctx):
    infisical = setup_infisical(project_id="f7b78b62-9edc-4b41-bc87-37c80b350c10")
    ie = ctx.inputs.environment["attributes"]["infisical_env"]
    
    secret_name = ctx.inputs.ssh_private_key_secret
    priv = infisical.get(secret_name, env=ie)

    ssh = setup_ssh(hostname=ctx.inputs.ip, private_key=priv)
    # Check if docker is already installed
    result = ssh.exec("which docker")
    if result.exit_code != 0:
        # Install docker
        ssh.exec("apt update && apt install docker.io -y")

    result = ssh.exec("docker ps -q -f name=nginx --no-trunc | grep -q .")
    if result.exit_code != 0:
        print("Nginx is currently running.")
    else:
        ssh.exec("docker run -d -p 80:80 nginx")

    return done()

def _destroy(ctx):
    infisical = setup_infisical(project_id="f7b78b62-9edc-4b41-bc87-37c80b350c10")
    ie = ctx.inputs.environment["attributes"]["infisical_env"]
    
    secret_name = ctx.inputs.ssh_private_key_secret
    priv = infisical.get(secret_name, env=ie)

    ssh = setup_ssh(hostname=ctx.inputs.ip, private_key=priv)
    ssh.exec("docker stop nginx")
    ssh.exec("apt remove docker.io -y")
    return done()

# Staging deployment phase
phase(
    name="staging",
    work=[
        deploy(
            up=_deploy,
            down=_destroy,
            environment=environment,
            inputs={
                "ssh_private_key_secret": ref("./-/vps/release.ocu.star/@/deploy/{}#output/ssh_private_key_secret".format(environment.name)),
                "ip": ref("./-/vps/release.ocu.star/@/deploy/{}#output/ip".format(environment.name)),
            }
        ) for environment in envs if environment.attributes["type"] == "staging"
    ],
)

# Production deployment phase
phase(
    name="production",
    work=[
        deploy(
            up=_deploy,
            down=_destroy,
            environment=environment,
            inputs={
                "ssh_private_key_secret": ref("./-/vps/release.ocu.star/@/deploy/{}#output/ssh_private_key_secret".format(environment.name)),
                "ip": ref("./-/vps/release.ocu.star/@/deploy/{}#output/ip".format(environment.name)),
            }
        ) for environment in envs if environment.attributes["type"] == "prod"
    ],
)

ocuroot("0.3.0")

load("../terraform.star", "setup_tf")
load("../infisical.star", "setup_infisical")
load("../ssh.star", "setup_ssh")

# Get all environments
envs = environments()
# Filter environments by type
staging = [e for e in envs if e.attributes["type"] == "staging"]
prod = [e for e in envs if e.attributes["type"] == "prod"]

def review(ctx):
    infisical = setup_infisical(project_id="f7b78b62-9edc-4b41-bc87-37c80b350c10")
    dev_env = struct(
        name = "dev",
    )
    tf = setup_tf({}, dev_env, "vps", infisical)

    tf.validate(
        vars = {
            "do_token": infisical.get("K8S_DEMO_DO_TOKEN"),
        }
    )
    return done()

phase(
    name="review",
    work=[call(review, name="review")],
)

def _deploy(ctx):
    infisical = setup_infisical(project_id="f7b78b62-9edc-4b41-bc87-37c80b350c10")
    ie = ctx.inputs.environment["attributes"]["infisical_env"]
    tf = setup_tf({}, environment_from_dict(ctx.inputs.environment), "vps", infisical)
    outputs = tf.apply(vars = {
        "do_token": infisical.get("K8S_DEMO_DO_TOKEN"),
    })

    secret_name = "VPS_DEMO_SSH_PRIVATE_KEY"
    pub = outputs["public_key"].rstrip()
    priv = secret(outputs["private_key"].rstrip())
    infisical.set(secret_name, priv, env=ie)

    return done(
        outputs={
            "ssh_private_key_secret": secret_name,
            "ssh_public_key": pub,
            "ip": outputs["ip"],
        },
    )

def _destroy(ctx):
    infisical = setup_infisical(project_id="f7b78b62-9edc-4b41-bc87-37c80b350c10")
    ie = ctx.inputs.environment["attributes"]["infisical_env"]
    tf = setup_tf({}, environment_from_dict(ctx.inputs.environment), "vps", infisical)
    outputs = tf.destroy(vars = {
        "do_token": infisical.get("K8S_DEMO_DO_TOKEN"),
    })
    # Clear the secret
    res = infisical.delete("VPS_DEMO_SSH_PRIVATE_KEY", env=ie)
    if res.exit_code != 0:
        print("Failed to delete secret")
        print(res.stdout)
    return done()

# Staging deployment phase
phase(
    name="staging",
    work=[
        deploy(
            up=_deploy,
            down=_destroy,
            environment=environment,
        ) for environment in staging
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
        ) for environment in prod
    ],
)

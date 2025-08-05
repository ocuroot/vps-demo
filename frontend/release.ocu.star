ocuroot("0.3.0")

load("tasks.ocu.star", "build", "up", "down", "noop")

phase(
    name="build",
    work=[
        call(
            build,
            name="build",
            inputs={
                "version": input("./@/call/build#output/version", default=0),
            }
        )
    ],
)

# Get all environments
envs = environments()

# Deploy to all staging environments
phase(
    name="staging",
    work=[
        deploy(
            up=up,
            down=down,
            environment=environment,
            inputs={
                "ssh_private_key_secret": ref("./-/vps/release.ocu.star/@/deploy/{}#output/ssh_private_key_secret".format(environment.name)),
                "ip": ref("./-/vps/release.ocu.star/@/deploy/{}#output/ip".format(environment.name)),
            }
        ) for environment in envs if environment.attributes["type"] == "staging"
    ],
)

phase(
    name="approval",
    work=[
        call(
            noop,
            name="approval",
            inputs={
                "approved": input("./custom/approved"),
            }
        )
    ],
)

# Deploy to all production environments
phase(
    name="production",
    work=[
        deploy(
            up=up,
            down=down,
            environment=environment,
            inputs={
                "ssh_private_key_secret": ref("./-/vps/release.ocu.star/@/deploy/{}#output/ssh_private_key_secret".format(environment.name)),
                "ip": ref("./-/vps/release.ocu.star/@/deploy/{}#output/ip".format(environment.name)),
            }
        ) for environment in envs if environment.attributes["type"] == "prod"
    ],
)

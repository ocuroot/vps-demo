ocuroot("0.3.0")

load("../ssh.star", "setup_ssh")
load("../ssh_wrapper.star", "ssh_from_ctx")

def build(ctx):
    version = ctx.inputs.version + 1
    
    host.shell(
        "go build -ldflags '-X main.Version={}' -o dist/frontend main.go".format(version),
        env={
            "GOOS": "linux",
            "GOARCH": "amd64",
        },
    )
    
    return done(
        outputs={
            "version": version,
        }
    )

def up(ctx):
    ssh = ssh_from_ctx(ctx)

    ssh.copy("dist/frontend", "/usr/local/bin/frontend")
    
    # Kill existing instances of the frontend service
    # Note that this will introduce downtime
    ssh.exec("pkill frontend", continue_on_error=True)

    ssh.exec("nohup /usr/local/bin/frontend > frontend.log 2>&1 &")

    ssh.exec("ufw allow 8081", continue_on_error=True)
    return done(
        outputs={
            "url": "http://{}:8081".format(ctx.inputs.ip),
        }
    )

def down(ctx):
    ssh = ssh_from_ctx(ctx)
    ssh.exec("ufw delete allow 8081", continue_on_error=True)
    ssh.exec("pkill frontend", continue_on_error=True)
    ssh.exec("rm /usr/local/bin/frontend", continue_on_error=True)
    return done()

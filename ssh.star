ocuroot("0.3.0")

def setup_ssh(hostname, username="root", private_key=None):
    def exec(cmd):
        if private_key == None:
            return host.shell("ssh -o StrictHostKeyChecking=accept-new {}@{} \"{}\"".format(username, hostname, cmd))
        else:
            return host.shell(
                "ssh-agent bash -c 'ssh-add - <<< \"$PRIVATE_KEY_CONTENT\"; ssh -o StrictHostKeyChecking=accept-new {}@{} \"{}\"'".format(
                    username, 
                    hostname, 
                    cmd,
                ),
                env={"PRIVATE_KEY_CONTENT": private_key},
            )

    return struct(
        exec = exec,
    )
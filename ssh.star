ocuroot("0.3.0")

def setup_ssh(hostname, username="root", private_key=None):
    def exec(cmd, mute=False, continue_on_error=False, env={}):
        if private_key == None:
            return host.shell("ssh -o StrictHostKeyChecking=accept-new {}@{} \"{}\"".format(username, hostname, cmd), env=env, mute=mute, continue_on_error=continue_on_error)
        else:
            return host.shell(
                "ssh-agent bash -c 'ssh-add - <<< \"$PRIVATE_KEY_CONTENT\"; ssh -o StrictHostKeyChecking=accept-new {}@{} \"{}\"'".format(
                    username, 
                    hostname, 
                    cmd,
                ),
                env={"PRIVATE_KEY_CONTENT": private_key, **env},
                mute=mute,
                continue_on_error=continue_on_error,
            )

    return struct(
        exec = exec,
    )
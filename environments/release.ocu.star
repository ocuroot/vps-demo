ocuroot("0.3.0")

register_environment(
    environment(
        "staging",
        {
            "type": "staging",
            "infisical_env": "staging",
        }
    )
)

register_environment(
    environment(
        "production",
        {
            "type": "prod",
            "infisical_env": "prod",
        }
    )
)

`$ nile run --network goerli realms_cli/8_deploy_AMM.py`


### Adding a plugin

Add your logic to `realms_cli/realms_cli/main.py`
Add you cli entro to `realms_cli/pyproject.toml`
Reinstall the plugin cli `pip install realms_cli/`


----


1. Export PK from Argent
2. Save as STARKNET_PRIVATE_KEY in env
3. `source realms_cli/.env.nile`
4. `python scripts/script.py`
5. Save the printed public key in the goerli.accounts.json in address-1
6. Copy your address from argent and save it in both goerli.accounts.json and in goerli.deployments.txt (replacing the account-1 address)
7. `pip install realms_cli/`
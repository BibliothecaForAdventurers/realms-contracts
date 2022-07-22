[![Discord](https://badgen.net/badge/icon/discord?icon=discord&label)](https://discord.gg/uQnjZhZPfu)
[![Twitter](https://badgen.net/badge/icon/twitter?icon=twitter&label)](https://twitter.com/LootRealms)

<!-- badges -->
<p>
  <a href="https://starkware.co/">
    <img src="https://img.shields.io/badge/powered_by-StarkWare-navy">
  </a>
  <a href="https://github.com/dontpanicdao/starknet-burner/blob/main/LICENSE/">
    <img src="https://img.shields.io/badge/license-MIT-black">
  </a>
</p>

![Realms x Bibliotheca header](/static/realmsxbibliotheca.jpg)

# 📝 Realms Contracts

Realms is an ever-expanding on-chain permission-less gaming Lootverse built on StarkNet. 

This monorepo contains all of the Contracts (StarkNet/Cairo Ethereum/Solidity) for BibliothecaDAO, $LORDS, and Realms.

## Contracts
| Directory | Title | Description                     |
| --------- | ----- | ------------------------------- |
| **[/settling_game](./contracts/settling_game)** | The Realms Settling Game | A modular game engine architecture built on StarkNet. |
| [/desiege](./contracts/desiege) | Desiege | A web-based team game built on Starknet. |
| [/token](./contracts/token) | Standard Tokens | Standard tokens (ERC721, ERC1155, ERC20) written in Cairo. |
| [/L1-Solidity](./contracts/L1-Solidity/) | L1 contracts | A set of L1 contracts including the $LORDS, Realms, and the Journey (Realms staking). |
| [/game_utils](./contracts/game_utils) | Game Utils | Game utility contracts such as grid positions written in Cairo. |
| [/loot](./contracts/loot/) | Loot | Loot contracts ported to Cairo. |
| [/exchange](./contracts/exchange/) | Exchange | Allows trades between pairs of ERC20 and ERC1155 contract tokens. |
| [/nft_marketplace](./contracts/nft_marketplace/) | NFT Marketplace | A marketplace for Realms, Dungeons, etc. built on Starknet. |
| [/utils](./contracts/utils) | Cairo utility contracts | Helper contracts such as safemath written in Cairo. |


## Learn more about Realms

First, visit the [Bibliotheca DAO Site](https://bibliothecadao.xyz/) for an overview of our ecosystem.

Next, read the [Master Scroll](https://docs.bibliothecadao.xyz/lootverse-master-scroll/). This is our deep dive into everything about the game. The Master Scroll is the source of truth before this readme.

Finally, visit [The Atlas](https://atlas.bibliothecadao.xyz/) to see the Settling game in action.

If you want to get involved, join the [Realms x Bibliotheca Discord](https://discord.gg/uQnjZhZPfu).

## Development

We've placed individual development documentation inside each project's README and included general documentation for loading the monorepo in VSCode with our container in this file:

<details><summary>Development Workflow</summary>
If you are using VSCode, we provide a development container with all required dependencies.  (Note: this requires [Docker](https://docs.docker.com/get-docker/) and the [Remote - Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)).

When opening VS Code, it should ask you to re-open the project in a container, if it finds
the .devcontainer folder. If not, you can open the Command Palette (`cmd + shift + p`),
and run “Remote-Containers: Rebuild and Reopen in Container”.

<details><summary>Logging into your dev container</summary>
The development container loads settings and the repository information on your local computer but cannot read your GitHub login credentials from your local computer.

Instead, you can use the [Github CLI](https://cli.github.com/) to auth from your dev container:

1. Download the [Github CLI](https://github.com/cli/cli/blob/trunk/docs/install_linux.md#debian-ubuntu-linux-raspberry-pi-os-apt).
2. Visit the [Github Tokens page](https://github.com/settings/tokens) and click `Generate New Token` to create a new token that will be used in your dev container. Make sure to save it somewhere as the token is only visible upon creation.
3. With the container loaded, open the dev container terminal in vscode.
4. Run `gh auth login` and follow the steps, pasting in your new access token when asked.
</details>

<details><summary>OSX ARM chips: Running without a container</summary>
Docker performance on ARM chips is pretty poor, so we recommend running without a container until these perf issues are resolved:
1. Pull down the repository
2. Install homebrew: https://brew.sh/
3. Install gmp: `brew install gmp`
4. Install dependencies: `pip3 install -r ./requirements.txt`
5. Install realms cli: `pip3 install ./realms_cli`
</details>

If you have further questions about the development workflow, please ask in [#builders-chat in the Realms Discord](https://discord.gg/yP4BCbRjUs).

## Contributing

<details><summary>How to contribute</summary>

We encourage pull requests.

1. **Create an [issue](https://github.com/BibliothecaForAdventurers/realms-contracts/issues)** to describe the improvement you're making. Provide as much detail as possible in the beginning so the team understands your improvement.
2. **Fork the repo** so you can make and test changes in your local repository.
3. **Test your changes** Follow the procedures for testing in each contract sub-directory (e.g. [/contracts/settling_game](./contracts/settling_game/) and make sure your tests (manual and/or automated) pass.
4. **Create a pull request** and describe the changes you made. Include a reference to the Issue you created.
5. **Verify cairo lint warnings** run through the 'Files Changed' tab for your PR and resolve any warnings. These do not show up locally so you need to view them on GitHub.
5. **Monitor and respond to comments** made by the team around code standards and suggestions. Most pull requests will have some back and forth.

If you have further questions, visit [#builders-chat in our discord](https://discord.gg/yP4BCbRjUs) and make sure to reference your issue number.

Thank you for taking the time to make our project better!

</details>
<hr>

## Realms Repositories

The Realms Settling Game spans a number of repositories:

| Content         | Repository       | Description                                              |
| --------------- | ---------------- | -------------------------------------------------------- |
| **contracts**       | [realms-contracts](https://github.com/BibliothecaForAdventurers/realms-contracts) | StarkNet/Cairo and Ethereum/solidity contracts.          |
| **ui, atlas**       | [realms-react](https://github.com/BibliothecaForAdventurers/realms-react)     | All user-facing react code (website, Atlas, ui library). |
| **indexer**         | [starknet-indexer](https://github.com/BibliothecaForAdventurers/starknet-indexer) | A graphql endpoint for the Lootverse on StarkNet.        |
| **bot**             | [squire](https://github.com/BibliothecaForAdventurers/squire)           | A Twitter/Discord bot for the Lootverse.                 |
| **subgraph**        | [loot-subgraph](https://github.com/BibliothecaForAdventurers/loot-subgraph)    | A subgraph (TheGraph) for the Lootverse on Eth Mainnet.  |

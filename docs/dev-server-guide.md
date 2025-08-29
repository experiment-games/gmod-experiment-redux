# 🏗 Dev Server Guide

**Although the below information can be found online, we've compiled it here for your convenience.**

This guide will help you setup a dedicated server for development purposes. This is useful if you want to test whether your changes work in a multiplayer environment, or if you want to test the server performance.

In this guide you'll find instructions on how to:

1. Install SteamCMD
2. Install the Garry's Mod Dedicated Server software
3. Clone the Helix base gamemode and Experiment Redux gamemode
4. Start the server
5. (Optional) Setup FastDL locally

Additionally you should consider this for a production server:

* (Recommended) Authenticate your server
* (Optional) Enable MySQL

## Step-by-Step Guide

1. Follow these instructions to install SteamCMD:
    * [Linux](https://developer.valvesoftware.com/wiki/SteamCMD#Linux)
    * [Windows](https://developer.valvesoftware.com/wiki/SteamCMD#Windows)

2. Install the Garry's Mod Dedicated Server software using SteamCMD:

    ```sh
    steamcmd +login anonymous +force_install_dir /path/to/gmod +app_update 4020 validate +quit
    ```

    *Replace `/path/to/gmod` with the path to where you want to install the server.*

    *Replace `steamcmd` with the path to the SteamCMD executable on Windows (e.g: C:\steamcmd.exe)*

3. Navigate to the Garry's Mod server's `garrysmod/gamemodes` directory:

    ```sh
    cd /path/to/gmod/garrysmod/gamemodes
    ```

4. Clone the helix base gamemode and ensure it is named `helix`:

    ```sh
    git clone https://github.com/NebulousCloud/helix helix
    ```

5. Clone this repository into the `garrysmod/gamemodes` directory and ensure the directory is named `experiment-redux`:

    ```sh
    git clone https://github.com/experiment-games/gmod-experiment-redux experiment-redux
    ```

6. (Optional) If you have content other than the default content you will want to create a Workshop Collection for your server, following [the instructions on the official Garry's Mod documentation](https://wiki.facepunch.com/gmod/Workshop_for_Dedicated_Servers). When creating the collection:

    * **The following workshop items are required:**
        * [Content for the `heavy_duty_armor` plugin](https://steamcommunity.com/sharedfiles/filedetails/?id=355101935)

    * We recommend including these, but you can choose alternatives if you prefer:
        * [A map like `rp_c18_v2`](https://steamcommunity.com/sharedfiles/filedetails/?id=132937160)

    **Make note of the collection ID, you'll need it later.**

7. Start the server so you can test it. Run the following server start command:

    ```bash
    /path/to/gmod/srcds -console -game garrysmod -tickrate 100 +maxplayers 64 +gamemode experiment-redux +map rp_c18_v2 +host_workshop_collection 3215035081
    ```

    *Replace `3215035081` with the ID of the Workshop Collection you created. You can use `3215035081` for the default content and `exp_c18_v1_alpha034` map*

8. Open Garry's Mod and connect to the server by typing `connect <server ip>:27015` in the console. Replace `<server-ip>` with the IP of the server:

    * If the server is remote you have to use the public IP (which is listed towards the end of the server start output) and ensure the port is open in the firewall.

    * If the server is local you have to use the `Network IP` which is listed in the server start output directly after:

      ```bash
      Changing gamemode to Experiment Redux (experiment-redux)
      Network: IP 192.168.x.x, mode MP, dedicated Yes, ports 27015 SV / 27005 CL
      ```

9. (Optional) Setup FastDL locally by following [the instructions on the official Garry's Mod documentation](https://wiki.facepunch.com/gmod/Serving_Content). This is useful to test if you're using `resource.AddFile` correctly in your code:

    1. Use the following tool to apply `bzip2` compression to all contents of the content folder:

        ```bash
        # Run this in root
        ./tools/compress-content.sh
        ```

    2. Host the content folder using a local web server. We use VSCode for development, so using the [`Live Server` extension by Ritwick Dey](https://marketplace.visualstudio.com/items?itemName=ritwickdey.LiveServer) is a good option: Click `Go Live` in the bottom right corner of VSCode after opening this repository.

    3. Open `path/to/gmod/garrysmod/cfg/server.cfg` and add the following lines:

        ```cfg
        hostname "Experiment (Redux) | Testing"
        sv_location eu
        sv_allowupload "0"
        sv_allowdownload "0"
        sv_downloadurl "http://127.0.0.1:5500/content/"
        sv_password "4123"
        lua_log_sv "1"
        ```

    4. Now when you start the server, content should be downloaded from the local web server quickly.

10. To easily start the server with the required command line arguments we use a `start-srcds.bat` and `start-srcds.sh` for Windows and Linux respectively. These scripts are located in [the `tools/dev` directory of this project](../tools/dev).

### Authenticating your server (Recommended)

Next you'll want to generate a GLST login token for your server. This is required to authenticate your server and have it show up in the server browser. You can generate a token [here](https://steamcommunity.com/dev/managegameservers):

1. Enter App ID `4000` (Garry's Mod)

2. Choose any name so you can identify the token later (e.g: `My Experiment Redux Server`)

3. Click "Create"

4. From now on start the server by adding the following to the server start command:

    ```bash
    +sv_setsteamaccount <glst-token>
    ```

    *Replace `<glst-token>` with the token you generated.*

### Enabling MySQL (Optional)

After the above you'll likely want to [install and use MySQL as per the Helix documentation](https://docs.gethelix.co/manual/getting-started/#Installing). This can be helpful if you want to access the database from outside the server, or if you want to run multiple servers off the same database.

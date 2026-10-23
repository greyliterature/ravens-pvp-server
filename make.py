##### IF YOU RUN THIS CODE WITHOUT KNOWING WHAT YOU'RE DOING, YOU MIGHT DELETE YOUR GARRYS MOD DIRECTORY. ONLY RUN THIS CODE IN THE REPO FOLDER, DO NOT PUT THIS IN YOUR GAME DIRECTORY
######
########
from dulwich import porcelain
import os
from dotenv import load_dotenv
import traceback

load_dotenv()

GITHUB_TOKEN=os.getenv("GITHUB_TOKEN")
PRIVATE_REPO_ACCESS_TOKEN=os.getenv("PRIVATE_REPO_ACCESS_TOKEN")

repositories = {
    "public": [
        # [url, relativepath, branch]
        ["https://github.com/greyliterature/ravens-pvp-server", "./garrysmod", None],
        ["https://github.com/TeamUlysses/ulx", "./garrysmod/addons/ulx", None],
        ["https://github.com/TeamUlysses/ulib", "./garrysmod/addons/ulib", None],
        ["https://github.com/greyliterature/map_vote", "./garrysmod/addons/mapvote", "hotloading_concept"],
        ["https://github.com/greyliterature/FSpectate", "./garrysmod/addons/fspectate"],
        #["https://github.com/greyliterature/garrysmod/", "./garrysmod/addons/rv_extra/lua/autorun/client", None, True], # this doesnt work, overwrites it, unfortunate

    ],
    "private": { # all of these should be main branch, so converting this into a list right now isnt necessary
        "https://github.com/greyliterature/splot": "./garrysmod/addons/splot"
    }
}
gitbloat = [
    ".git",
    ".github",
    ".editorconfig",
    ".gitattributes",
    ".gitignore",
    "addon.json",
    "addon.txt",
    "CHANGELOG.md",
    "LICENSE.md",
    "README.md",
    "ulx.build",
    "ulib.build",
    "fspectate.jpg"
]

#porcelain.clone("https://example.com/a-private-repo.git", "a-private-repo-clone", username="test", password=PUBLIC_GITHUB_TOKEN)
###### repo stuff
import shutil
addonspath = "./garrysmod"
if os.path.isdir(addonspath):
    shutil.rmtree(addonspath)

for tbl in repositories["public"]:
    url, relativepath, branch = tbl[0], tbl[1], tbl[2] if len(tbl) >= 2 + 1 else None

    print(f"cloning {url} into {relativepath}")
    try:
        if os.path.isdir(relativepath):
            shutil.rmtree(relativepath)
        os.makedirs(relativepath)
        with porcelain.clone(url, relativepath, branch=branch):
           pass
        for pathtodelete in gitbloat:
            newpath = relativepath + "/" + pathtodelete
            if os.path.isdir(newpath):
                print("Deleting dir " + newpath)
                shutil.rmtree(newpath)
            elif os.path.isfile(newpath):
                print("Deleting file " + newpath)
                os.remove(newpath)
    except Exception:
        print(traceback.format_exc())

for url, relativepath in repositories["private"].items():
    print(f"cloning {url} into {relativepath}")
    try:
        if os.path.isdir(relativepath):
            shutil.rmtree(relativepath)
        with porcelain.clone(url, relativepath, username="hi", password=PRIVATE_REPO_ACCESS_TOKEN):
           pass
        for pathtodelete in gitbloat:
            newpath = relativepath + "/" + pathtodelete
            print("Attempting to delete " + newpath + "\n")
            if os.path.isdir(newpath):
                shutil.rmtree(newpath)
            elif os.path.isfile(newpath):
                os.remove(newpath)
    except Exception:
        print(traceback.format_exc())

###### steamcmd
from pysteamcmd.steamcmd import Steamcmd # this also requires the vdf package, for whatever reason
APP_ID = 4000
addons = {
    "3755694976",
    "3755379782",
    "3751896133",
    "3667352947",
    "577145478",
    "3544600901",
    "2020654310", 
    "2020654310",
    "3432497883",
    "3449941064",
    "3044754921",
    "2842498361",
    "2232524667",
    "837792151",
    "3705916707",
    "3751311698",
    "3751308439",
    "3769721895",
}

#https://github.com/f0rkz/pysteamcmd/blob/ab33e35fd05c3160e0d3fee3b28878d516438d7e/src/pysteamcmd/steamcmd.py#L147
STEAMCMD_PATH = "./steamcmd"
os.makedirs(STEAMCMD_PATH, exist_ok=True)

steamcmd = Steamcmd(STEAMCMD_PATH)
try:
    steamcmd.install()
except:
    pass

wsidfolderpath = "./garrysmod/addons/"
#if os.path.isdir(wsidfolderpath):
    #shutil.rmtree(wsidfolderpath)
os.makedirs(wsidfolderpath, exist_ok=True) # exist_ok probably not needed because of last line but its fine

for workshop_id in addons:
    #if os.path.isfile(gmapath): # sigh, https://docs.python.org/3/library/shutil.html#:~:text=The%20destination%20path%20in%20that%20directory%20must%20not%20already%20exist 
        #os.remove(gmapath)
    steamcmd.install_workshopfiles(APP_ID, workshop_id, "./")
    workpath = "./steamcmd/steamapps/workshop/content/4000/" + workshop_id
    files = os.listdir(workpath)
    try:
        gmapath = workpath + "/" + files[0] # do it again after the file installs
        #os.remove(gmapath) # handling past conflicts
        shutil.move(gmapath, "./garrysmod/addons/" + files[0])
    except Exception:
        print(traceback.format_exc())


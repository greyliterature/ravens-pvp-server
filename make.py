from dulwich import porcelain
import os
from dotenv import load_dotenv
import traceback

load_dotenv()

GITHUB_TOKEN=os.getenv("GITHUB_TOKEN")
PRIVATE_REPO_ACCESS_TOKEN=os.getenv("PRIVATE_REPO_ACCESS_TOKEN")

repositories = {
    "public": {
        "https://github.com/TeamUlysses/ulx": "./addons/ulx",
        "https://github.com/TeamUlysses/ulib": "./addons/ulib"
    },
    "private": {
        "https://github.com/greyliterature/splot": "./addons/splot"
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
]

#porcelain.clone("https://example.com/a-private-repo.git", "a-private-repo-clone", username="test", password=PUBLIC_GITHUB_TOKEN)
###### repo stuff
import shutil
for url, relativepath in repositories["public"].items():
    print(f"cloning {url} into {relativepath}")
    try:
        if os.path.isdir(relativepath):
            shutil.rmtree(relativepath)
        with porcelain.clone(url, relativepath):
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

for workshop_id in addons:
    steamcmd.install_workshopfiles(APP_ID, workshop_id, "./")
    os.makedirs("./addons/" + workshop_id, exist_ok=True)
    workpath = "./steamcmd/steamapps/workshop/content/4000/" + workshop_id
    files = os.listdir(workpath)
    gmapath = workpath + "/" + files[0] # "3822502910"/gm_scrapland.gma, steamcmd should only download at most 1 gma per addon so this is probably safe?
    os.remove(gmapath)
    shutil.move(gmapath, "./addons/")


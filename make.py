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


###### steamcmd
from pysteamcmd.steamcmd import Steamcmd # this also requires the vdf package, for whatever reason
APP_ID = 4000
addons = {
    "3822502910",
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
    shutil.move(gmapath, "./addons/")


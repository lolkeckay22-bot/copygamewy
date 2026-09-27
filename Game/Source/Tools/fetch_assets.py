from pathlib import Path
import urllib.request,concurrent.futures,json
root=Path('source/assets/external/su27');root.mkdir(parents=True,exist_ok=True)
paths=['LICENSE','README.md','Models/Su-27.ac','Models/Su-27_Flanker_P01.png','Models/Glass_Cockpit.png','Models/su-27gears.png','Models/SU-27.xml','Models/Stores/Missiles/R-73/R-73.ac','Models/Stores/Missiles/R-73/R-73.png','Models/Stores/Missiles/R-27R/R-27R.ac','Models/Stores/Missiles/R-27R/R-27R.png']
def fetch(path):
 target=root/path;target.parent.mkdir(parents=True,exist_ok=True)
 try:
  data=urllib.request.urlopen('https://raw.githubusercontent.com/yanes19/SU-27SK/master/'+path,timeout=60).read();target.write_bytes(data);print(path,len(data),flush=True)
 except Exception as e:print(path,e,flush=True)
with concurrent.futures.ThreadPoolExecutor(max_workers=6) as ex:list(ex.map(fetch,paths))

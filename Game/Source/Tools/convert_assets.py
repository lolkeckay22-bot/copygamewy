from pathlib import Path
import json,shlex,numpy as np
R=Path(__file__).resolve().parents[1]/'assets/external/su27'
O=Path(__file__).resolve().parents[1]/'assets/models';O.mkdir(parents=True,exist_ok=True)
def parse(path):
 lines=path.read_text().splitlines();i=1;mats=[]
 while lines[i].startswith('MATERIAL'):
  t=shlex.split(lines[i]);mats.append({'color':list(map(float,t[t.index('rgb')+1:t.index('rgb')+4])),'alpha':1-float(t[t.index('trans')+1])});i+=1
 objects=[]
 def obj(parent=np.zeros(3),rotation=np.eye(3)):
  nonlocal i
  typ=lines[i].split()[1];i+=1;name='';tex='';loc=np.zeros(3);rot=np.eye(3);verts=[];faces=[]
  while i<len(lines):
   t=shlex.split(lines[i]);i+=1
   if not t:continue
   key=t[0]
   if key=='name':name=t[1]
   elif key=='texture':tex=t[1]
   elif key=='loc':loc=np.array(list(map(float,t[1:])))
   elif key=='rot':rot=np.array(list(map(float,t[1:]))).reshape(3,3)
   elif key=='data':i+=1
   elif key=='numvert':
    for _ in range(int(t[1])):verts.append(list(map(float,lines[i].split())));i+=1
   elif key=='numsurf':
    for _ in range(int(t[1])):
     material=0
     while True:
      st=lines[i].split();i+=1
      if st[0]=='mat':material=int(st[1])
      if st[0]=='refs':break
     refs=[]
     for _ in range(int(st[1])):refs.append(list(map(float,lines[i].split())));i+=1
     faces.append((material,refs))
   elif key=='kids':
    position=parent+rotation@loc;rotation2=rotation@rot
    if verts:objects.append((name,tex,np.array(verts)@rotation2.T+position,faces))
    for _ in range(int(t[1])):obj(position,rotation2)
    return
 obj();return mats,objects
for name,file,length in [('su27','Models/Su-27.ac',21.9),('r73','Models/Stores/Missiles/R-73/R-73.ac',2.9),('r27r','Models/Stores/Missiles/R-27R/R-27R.ac',4.08)]:
 mats,objs=parse(R/file);allp=np.concatenate([o[2] for o in objs]);lo=allp.min(0);hi=allp.max(0);print(name,'bounds',lo,hi)
 scale=length/(hi[0]-lo[0]);center=(hi+lo)/2;center[1]=0;center[2]=0
 groups={}
 for objname,tex,vs,faces in objs:
  gear=objname.startswith('UC_')
  for mi,refs in faces:
   if len(refs)<3:continue
   key=(tex,mi,gear)
   g=groups.setdefault(key,{'texture':str(((R/file).parent/tex).relative_to(Path(__file__).resolve().parents[1])) if tex else '', 'color':mats[mi]['color'],'alpha':mats[mi]['alpha'],'gear':gear,'vertices':[],'uv':[]})
   for j in range(1,len(refs)-1):
    for ref in [refs[0],refs[j],refs[j+1]]:
     p=(vs[int(ref[0])]-center)*scale;g['vertices'].extend([float(-p[2]),float(p[1]),float(p[0])]);g['uv'].extend([ref[1],1-ref[2]])
 out={'surfaces':list(groups.values()),'length':length,'source':file}
 (O/(name+'.json')).write_text(json.dumps(out,separators=(',',':')))
 print(name,'triangles',sum(len(g['vertices'])//9 for g in groups.values()),'surfaces',len(groups))

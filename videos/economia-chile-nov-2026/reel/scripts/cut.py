import json, subprocess
FPS=30
chunks={c["i"]:c for c in json.load(open("speech_chunks.json"))}
# (chunk ids merged, correct text)
plan=[
 ([0,1],"El cobre, lo que más vende Chile, está carísimo…"),
 ([2],"y aun así más de un millón de personas no tiene trabajo."),
 ([3],"¿Cómo se explica eso?"),
 ([4],"El desempleo llegó a 9,8%."),
 ([5],"Son más de un millón de chilenos buscando pega,"),
 ([6],"casi como si Puente Alto y Maipú juntos estuvieran cesantes."),
 ([7],"Es la cifra más alta desde 2021."),
 ([8,9],"Y mientras tanto, todo sube."),
 ([10],"La inflación está en 4,5%."),
 ([11],"O sea, si tu almuerzo costaba 5 mil,"),
 ([12],"hoy cuesta unos 5.225 pesos."),
 ([14],"Lo que más subió fue la bencina y la comida."),
 ([15],"¿Y la economía?"),
 ([16],"Creció un 0,2%."),
 ([17],"Prácticamente nada."),
 ([18],"¿El problema?"),
 ([19],"El cobre está carísimo,"),
 ([20],"pero estamos sacando 12% menos."),
 ([23],"Es como si tu producto estuviera en su mejor precio"),
 ([24],"y tu fábrica se echara a perder."),
 ([25],"Es por eso que el Banco Central está en un dilema."),
 ([26],"Si baja las tasas, los precios pueden subir más."),
 ([28],"Y si no la baja, los créditos siguen caros."),
 ([29],"Por ahora la mantiene en 4,5%"),
 ([30],"y hasta pensó en subirla."),
 ([31],"¿Y el dólar?"),
 ([32],"Casi en mil pesos."),
 ([33],"Todo lo que viene de afuera,"),
 ([34,35],"tu celular, tu auto, la bencina,"),
 ([36,37],"sale más caro."),
 ([38,39],"Pero ¿hay luz al final del túnel?"),
 ([40],"Se aprobó la megarreforma que baja los impuestos a las empresas"),
 ([41],"para que inviertan y contraten."),
 ([42],"El Banco Central proyecta que el próximo año creceríamos entre un 2 y 3%,"),
 ([43],"pero eso todavía hay que verlo."),
 ([49,50],"En resumen: tenemos precios arriba, empleo abajo y una economía en pausa."),
 ([51],"¿Y tú ya lo estás sintiendo en tu bolsillo?"),
 ([55,56],"Cuéntame y sígueme para entender la economía sin enredos."),
]
override_start={42:154.85}
PRE,POST=0.10,0.16
segs=[]; t=0
for ids,text in plan:
    a=override_start.get(ids[0],chunks[ids[0]]["a"])-PRE
    b=chunks[ids[-1]]["b"]+POST
    fa=round(a*FPS); fb=round(b*FPS)
    n=fb-fa
    segs.append({"src_from":fa,"src_to":fb,"from":t,"dur":n,"text":text,
                 "speech_a":(chunks[ids[0]]["a"]-a)+t/FPS,"speech_b":(chunks[ids[-1]]["b"]-a)+t/FPS})
    t+=n
print("total frames",t,"=",t/FPS,"s")
# words: distribute by letter weight within speech span
words=[]
for s in segs:
    toks=s["text"].split()
    wts=[max(2,len([c for c in w if c.isalnum()]))+1 for w in toks]
    span=s["speech_b"]-s["speech_a"]; tot=sum(wts); cur=s["speech_a"]
    for w,wt in zip(toks,wts):
        d=span*wt/tot; words.append({"w":w,"s":round(cur,3),"e":round(cur+d,3)}); cur+=d
json.dump(segs,open("segments.json","w"),ensure_ascii=False,indent=1)
json.dump(words,open("words.json","w"),ensure_ascii=False)
# ffmpeg concat
fc=[];
for i,s in enumerate(segs):
    a=s["src_from"]/FPS; b=s["src_to"]/FPS; d=b-a
    fc.append(f"[0:v]trim=start_frame={s['src_from']}:end_frame={s['src_to']},setpts=PTS-STARTPTS[v{i}];")
    fc.append(f"[0:a]atrim=start={a:.4f}:end={b:.4f},asetpts=PTS-STARTPTS,afade=t=in:d=0.012,afade=t=out:st={d-0.02:.4f}:d=0.02[a{i}];")
fc.append("".join(f"[v{i}][a{i}]" for i in range(len(segs)))+f"concat=n={len(segs)}:v=1:a=1[v][a]")
open("fc.txt","w").write("".join(fc))
for s in segs: print(f"{s['from']/FPS:6.2f} +{s['dur']/FPS:4.2f}  {s['text']}")

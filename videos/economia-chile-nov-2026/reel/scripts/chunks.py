import json, re, subprocess, whisper
log = subprocess.run(["ffmpeg","-hide_banner","-i","/home/user/raw/audio16k.wav","-af","silencedetect=noise=-35dB:d=0.25","-f","null","-"],capture_output=True,text=True).stderr
starts=[float(x) for x in re.findall(r"silence_start: ([\d.]+)",log)]
ends=[float(x) for x in re.findall(r"silence_end: ([\d.]+)",log)]
# speech = gaps between silences
speech=[]; prev_end=0.0
for s,e in zip(starts,ends):
    if s-prev_end>0.12: speech.append((prev_end,s))
    prev_end=e
if 206.1-prev_end>0.12: speech.append((prev_end,206.1))
m=whisper.load_model("small")
out=[]
for i,(a,b) in enumerate(speech):
    pa,pb=max(0,a-0.15),b+0.15
    subprocess.run(["ffmpeg","-v","error","-y","-ss",str(pa),"-to",str(pb),"-i","/home/user/raw/audio16k.wav",f"c{i}.wav"])
    r=m.transcribe(f"c{i}.wav",language="es",condition_on_previous_text=False,fp16=False)
    t=r["text"].strip()
    out.append({"i":i,"a":round(a,3),"b":round(b,3),"text":t})
    print(f"{i:3d} {a:7.2f}-{b:7.2f} ({b-a:4.2f}) {t}",flush=True)
json.dump(out,open("speech_chunks.json","w"),ensure_ascii=False,indent=1)

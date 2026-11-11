"""Corte en una sola pasada (reemplaza el método de cut.py, que desfasaba el audio).

- Video: fps=30 + select por número de cuadro, con conversión HLG (HDR iPhone) -> BT.709
  mediante tone mapping 'hable' sin ajustes extra, para mantener el color original.
- Audio: atrim + concat en PCM y una sola codificación AAC al final -> 0 ms de desfase.
Genera vf.txt / af.txt para usar con:
  ffmpeg -i IMG_5768.MOV -filter_complex_script af.txt -map "[a]" -c:a pcm_s16le cut_audio.wav
  ffmpeg -i IMG_5768.MOV -filter_complex_script vf.txt -map "[v]" -c:v libx264 -crf 15 cut_video.mp4
  ffmpeg -i cut_video.mp4 -i cut_audio.wav -c:v copy -c:a aac -b:a 256k public/cut.mp4
"""
import json
FPS = 30
segs = json.load(open("src/data/segments.json"))
sel = "+".join(f"between(n\\,{s['src_from']}\\,{s['src_to']-1})" for s in segs)
open("vf.txt", "w").write(
    f"[0:v]fps=30,select='{sel}',setpts=N/30/TB,zscale=t=linear:npl=100,format=gbrpf32le,"
    "zscale=p=bt709,tonemap=tonemap=hable:desat=0,zscale=t=bt709:m=bt709:r=tv,format=yuv420p[v]")
af = []
for i, s in enumerate(segs):
    a = s["src_from"] / FPS; d = (s["src_to"] - s["src_from"]) / FPS
    af.append(f"[0:a]atrim=start={a:.6f}:duration={d:.6f},asetpts=PTS-STARTPTS,"
              f"afade=t=in:d=0.01,afade=t=out:st={d-0.015:.6f}:d=0.015[a{i}];")
af.append("".join(f"[a{i}]" for i in range(len(segs))) + f"concat=n={len(segs)}:v=0:a=1[a]")
open("af.txt", "w").write("".join(af))

import sys, json, whisper
src, out, model = sys.argv[1], sys.argv[2], sys.argv[3]
m = whisper.load_model(model)
r = m.transcribe(src, language="es", word_timestamps=True, condition_on_previous_text=False,
    initial_prompt="Economía chilena: desempleo 9,8%, inflación 4,5%, Puente Alto y Maipú, cobre, Banco Central, megarreforma, dólar.")
json.dump(r, open(out, "w"), ensure_ascii=False, indent=1)
for s in r["segments"]:
    print(f'{s["start"]:7.2f}-{s["end"]:7.2f} {s["text"]}')

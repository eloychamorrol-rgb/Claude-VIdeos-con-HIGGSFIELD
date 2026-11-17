import { Composition, Still } from "remotion";
import { Cover } from "./v2/Cover";
import { StyleBoard } from "./v4/StyleBoard";
import { REC_FPS, REC_TOTAL, RecesionReel } from "./v4/RecesionReel";
import { FPS, Reel, TOTAL } from "./Reel";

export const RemotionRoot: React.FC = () => {
  return (
    <>
    <Composition
      id="EconomiaChile"
      component={Reel}
      durationInFrames={TOTAL}
      fps={FPS}
      width={1080}
      height={1920}
    />
    <Still id="Portada" component={Cover} width={1080} height={1920} />
    <Composition id="EstiloMuestra" component={StyleBoard} durationInFrames={90} fps={30} width={1080} height={1920} defaultProps={{ scene: "unemp" as const }} />
    <Composition id="Recesion" component={RecesionReel} durationInFrames={REC_TOTAL} fps={REC_FPS} width={1080} height={1920} />
    </>
  );
};

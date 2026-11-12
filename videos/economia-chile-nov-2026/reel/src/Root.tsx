import { Composition, Still } from "remotion";
import { Cover } from "./v2/Cover";
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
    </>
  );
};

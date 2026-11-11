import { Composition } from "remotion";
import { FPS, Reel, TOTAL } from "./Reel";

export const RemotionRoot: React.FC = () => {
  return (
    <Composition
      id="EconomiaChile"
      component={Reel}
      durationInFrames={TOTAL}
      fps={FPS}
      width={1080}
      height={1920}
    />
  );
};

export type GameStatus = 'in_development' | 'playable' | 'coming_soon';

export interface GameMetadata {
  id: string;
  title: string;
  shortDescription: string;
  fullDescription: string;
  genre: string;
  engine: string;
  status: GameStatus;
  isPlayableWeb: boolean;
  route: string;
  thumbnailIcon: string;
  platforms: ('Web' | 'Android' | 'iOS' | 'PC')[];
  tags: string[];
  version?: string;
  highlightNote?: string;
}

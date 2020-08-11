import api from '@/api';
import { gameDecoder } from '@/arkham/types/Game';

export const fetchGame = (gameId: string) => api
  .get(`arkham/games/${gameId}`)
  .then((resp) => {
    const { investigatorId, game } = resp.data;
    return gameDecoder
      .decodePromise(game)
      .then((gameData) => Promise.resolve({ investigatorId, game: gameData }));
  });

export const updateGame = (gameId: string, choice: number) => api
  .put(`arkham/games/${gameId}`, { choice })
  .then((resp) => gameDecoder.decodePromise(resp.data));

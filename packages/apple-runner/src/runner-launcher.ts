import type { RunnerEndpoint } from './runner-contract.ts';

/** A launched runner owns its output and settles both streams when terminated. */
export type RunnerLaunch = {
  exited: Promise<void>;
  output: AsyncIterable<string>;
  terminate(): Promise<void>;
};

/** Launch mechanisms supply resources; the session owner controls their lifetime. */
export type RunnerLauncher = {
  endpoint: Omit<RunnerEndpoint, 'token'>;
  launch(endpoint: RunnerEndpoint, signal: AbortSignal): Promise<RunnerLaunch>;
};

export type RunnerLaunchObservation = {
  launch: RunnerLaunch;
  exited: boolean;
  failure?: unknown;
  output: Promise<void>;
  terminate(): Promise<void>;
};

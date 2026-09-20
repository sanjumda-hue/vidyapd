/**
 * Unit tests for the ingestion pipeline.
 *
 * jest and ts-jest were already installed and `npm test` ran with no config,
 * which reported success while executing nothing.
 *
 * Scope is deliberately the pure pipeline: the parser, the validator and the
 * resolver's string handling. Those three are where every data bug so far has
 * lived -- 10x decimal ranks, scientific notation, preparatory ranks, the
 * COMEDK CE collision, the UPTAC compound-code precedence -- and they need no
 * database, so these run in a second with nothing else switched on.
 *
 * Anything that needs a live API and a populated database is covered by the
 * Flutter contract tests in app/test/api_contract_test.dart instead.
 */
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  rootDir: 'src',
  testRegex: '.*\\.spec\\.ts$',
  collectCoverageFrom: ['ingestion/pipeline/**/*.ts'],
  // ts-jest reads the app tsconfig; the CLI entrypoints are excluded from it.
  transform: { '^.+\\.ts$': ['ts-jest', { tsconfig: '<rootDir>/../tsconfig.json' }] },
};

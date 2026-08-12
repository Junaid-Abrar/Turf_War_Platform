module.exports = {
  testEnvironment: 'node',
  setupFilesAfterEnv: ['<rootDir>/test/setup.js'],
  testMatch: ['<rootDir>/test/**/*.test.js'],
  collectCoverageFrom: [
    'controllers/**/*.js',
    'middleware/**/*.js',
    'utils/**/*.js',
    'models/**/*.js'
  ],
  coverageDirectory: '<rootDir>/coverage',
  testTimeout: 20000,
  forceExit: true
};

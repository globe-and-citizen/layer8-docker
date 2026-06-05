import {defineConfig, devices} from '@playwright/test';

/**
 * Read environment variables from file.
 * https://github.com/motdotla/dotenv
 */
// require('dotenv').config();

/**
 * See https://playwright.dev/docs/test-configuration.
 */
export default defineConfig({
    // Folder where tests are located ('.' = project root)
    testDir: '.',
    // If true: tests across files run in parallel.
    // If false: tests inside a single file run sequentially.
    fullyParallel: false,
    // Number of parallel worker processes (concurrent test runners)
    workers: 1,
    // Fail the run in CI if any test uses `.only`
    forbidOnly: !!process.env.CI,
    // Retry failed tests: 2 in CI, 0 locally
    retries: process.env.CI ? 2 : 0,
    // Test results reporter (here: HTML)
    reporter: 'html',
    // Shared options applied to all tests
    use: {
        // Collect trace on the first retry of a failed test
        trace: 'on-first-retry',
    },

    /* Configure projects for major browsers */
    projects: [
        // {
        //     name: 'chromium',
        //     use: { ...devices['Desktop Chrome'] },
        // },
        {
            name: 'firefox',
            use: {...devices['Desktop Firefox']},
        },
        //
        // {
        //     name: 'webkit',
        //     use: { ...devices['Desktop Safari'] },
        // },

        /* Test against mobile viewports. */
        // {
        //   name: 'Mobile Chrome',
        //   use: { ...devices['Pixel 5'] },
        // },
        // {
        //   name: 'Mobile Safari',
        //   use: { ...devices['iPhone 12'] },
        // },

        /* Test against branded browsers. */
        // {
        //   name: 'Microsoft Edge',
        //   use: { ...devices['Desktop Edge'], channel: 'msedge' },
        // },
        // {
        //   name: 'Google Chrome',
        //   use: { ...devices['Desktop Chrome'], channel: 'chrome' },
        // },
    ],

    /* Run your local dev server before starting the tests */
    // webServer: {
    //   command: 'npm run start',
    //   url: 'http://127.0.0.1:3000',
    //   reuseExistingServer: !process.env.CI,
    // },
});

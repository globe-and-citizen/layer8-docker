import {test, expect} from '@playwright/test';

test.describe.serial('Layer8 E2E', () => {
    test('register, login, upload ntor certificate', async ({page}) => {
        //
        // Unique data
        //
        // Generate unique values so the test can be run repeatedly
        // without colliding with existing database records.
        // const username = `user-${Date.now()}`;
        // const backendUrl = `https://backend-${Date.now()}.example.com`;
        const username = 'e2e-test-user';
        const password = '1234';
        const backendUrl = 'http://reverse-proxy:6193';

        //
        // Register
        //
        // Open the registration page in a browser.
        await page.goto('http://localhost:5001/client-register');

        // Fill the "Project name" field.
        await page.fill('#name', 'E2E Product');

        // Fill the redirect URL field.
        await page.fill(
            '#redirect_uri',
            'http://localhost:5173/oauth2/callback'
        );

        // Fill the backend URL field.
        await page.fill('#backend_uri', backendUrl);

        // Start waiting for the backend URI validation request.
        //
        // We do this BEFORE triggering the blur event,
        // otherwise the request could finish before Playwright
        // starts listening for it.
        const checkBackendPromise = page.waitForResponse(
            resp =>
                resp.url().includes('check-backend-uri') &&
                resp.request().method() === 'POST'
        );

        // Move focus away from the backend URL input.
        //
        // In your Vue component:
        // @blur="checkBackendUri"
        //
        // Therefore this triggers the API call.
        await page.locator('#backend_uri').blur();

        // Wait until the API response arrives.
        const checkBackendResp = await checkBackendPromise;

        // Verify HTTP status is 2xx.
        expect(checkBackendResp.ok()).toBeTruthy();

        // Fill username.
        await page.fill('#username', username);

        // Fill password.
        await page.fill('#password', password);

        // Start listening for the registration request.
        //
        // Again, we set this up BEFORE clicking the button.
        const registerPromise = page.waitForResponse(
            resp =>
                resp.url().includes('register') &&
                resp.request().method() === 'POST'
        );

        // Click the Register button.
        await page.getByRole('button', {name: 'Register'}).click();

        // Wait for registration API response.
        const registerResp = await registerPromise;

        // Verify registration succeeded.
        expect(registerResp.ok()).toBeTruthy();

        // Successful registration redirects user to login page.
        //
        // Playwright will keep checking until the timeout expires.
        await expect(page).toHaveURL(/client-login/, {
            timeout: 15000,
        });

        //
        // Login
        //
        await page.locator('input[type="text"]').fill(
            username
        );

        await page.locator('input[type="password"]').fill(
            password
        );

        await page.getByRole('button', {
            name: 'Login',
        }).click();

        await expect(page).toHaveURL(
            /client\/profile/,
            {timeout: 15000}
        );

        //
        // Verify token exists
        //
        const token = await page.evaluate(() =>
            localStorage.getItem('clientToken')
        );

        expect(token).toBeTruthy();

        //
        // Wait for profile API to load
        //
        await expect(
            page.getByText('Your data')
        ).toBeVisible();

        //
        // Upload certificate
        //
        const uploadResponsePromise =
            page.waitForResponse(
                resp =>
                    resp.request().method() === 'POST' &&
                    resp.ok()
            );

        await page.setInputFiles(
            'input[type="file"]',
            'ntor_cert.pem'
        );

        await uploadResponsePromise;

        //
        // Verify success toast
        //
        await expect(
            page.getByText('Certificate uploaded')
        ).toBeVisible();
    });

    test('test layer8 proxies', async ({page}) => {
        const errors: string[] = [];

        page.on('pageerror', error => {
            errors.push(error.message);
        });

        page.on('console', msg => {
            console.log('APP CONSOLE:', msg.text());
        });

        const responsePromise = page.waitForResponse(
            response => response.url().includes('/init-tunnel')
        );

        /*
         * Open the test page which initializes the tunnel. Layer8 responds with a 200 if the tunnel is ready, otherwise
         * the page shows an error message.
         */
        await page.goto('http://localhost:5173/');

        let init_response = await responsePromise;

        // expect no page errors during tunnel initialization
        expect(errors).toEqual([]);
        expect(init_response.ok()).toBeTruthy();
        expect(init_response.status()).toBe(200);

        /*
         * Click the "test" button — triggers a request to /ravi-test which Layer8 intercepts and proxies to /proxy.
         */
        await page.getByRole('button', {name: 'test'}).click();

        const encrypted_response = await page.waitForResponse(
            response => response.url().includes('/proxy')
        );

        // check network response and parse encrypted body
        expect(encrypted_response.ok()).toBeTruthy();
        expect(encrypted_response.status()).toBe(200);

        const encrypted_buf = Buffer.from(await encrypted_response.body());
        let parsed: { nonce: Uint8Array; data: Uint8Array };

        try {
            const text = encrypted_buf.toString('utf8');
            const j = JSON.parse(text);
            if (j && (j.nonce || j.data)) {
                const toBytes = (v: any) =>
                    typeof v === 'string' ? Buffer.from(v, 'base64') : Buffer.from(v);
                const nonceBuf = toBytes(j.nonce);
                const dataBuf = toBytes(j.data);
                parsed = {nonce: new Uint8Array(nonceBuf), data: new Uint8Array(dataBuf)};
            } else {
                throw new Error('not-json-with-nonce-data');
            }
        } catch {
            const NONCE_LEN = 12;
            const nonceBuf = encrypted_buf.slice(0, NONCE_LEN);
            const dataBuf = encrypted_buf.slice(NONCE_LEN);
            parsed = {nonce: new Uint8Array(nonceBuf), data: new Uint8Array(dataBuf)};
        }

        console.log('Test Proxy response (parsed):', parsed);
        const encrypted_body = parsed;

        expect(encrypted_body).toBeTruthy();
        const NONCE_LEN = 12;
        expect(encrypted_body.nonce).toBeTruthy();
        expect(encrypted_body.nonce.length).toBe(NONCE_LEN);

        // The decrypted response is sent to the page via window.__RaviTestResponse.
        // Wait until the page sets this variable, which indicates the response was decrypted and processed.
        const intercepted = await page.waitForFunction(
            () => window.__RaviTestResponse !== undefined
        );

        // Get the decrypted response body from the page.
        const body = await page.evaluate(
            () => window.__RaviTestResponse
        );

        expect(intercepted).toBeTruthy();
        expect(body).toEqual({
            msg: 'Thank God I\'m Done!',
        });
    });
});

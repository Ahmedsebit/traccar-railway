const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { test } = require('node:test');

const script = readFileSync(path.join(__dirname, '..', 'start.sh'), 'utf8');
const boundary = script.indexOf('\n/opt/traccar/init-db.sh');
assert.ok(boundary > 0, 'startup preflight must precede database initialization');
const preflight = script.slice(0, boundary);
const shell = process.env.BASH_PATH
  || (process.platform === 'win32' ? 'C:\\Program Files\\Git\\bin\\bash.exe' : '/bin/sh');
const baseEnv = {
  PATH: process.env.PATH,
  SystemRoot: process.env.SystemRoot,
  PGHOST: 'test.invalid',
  PGPORT: '5432',
  PGUSER: 'test-user',
  PGPASSWORD: 'dummy-database-password',
};
const lbsEnv = {
  GEOLOCATION_ENABLE: 'true',
  GEOLOCATION_KEY: 'dummy-provider-key-not-a-secret',
  GEOLOCATION_MCC: '234',
  GEOLOCATION_MNC: '15',
};

function run(env = {}) {
  const result = spawnSync(shell, ['-s'], {
    input: preflight,
    env: { ...baseEnv, ...env },
    encoding: 'utf8',
  });
  assert.ifError(result.error);
  assert.equal(result.signal, null);
  assert.ok(!result.stderr.includes(baseEnv.PGPASSWORD));
  assert.ok(!result.stderr.includes(lbsEnv.GEOLOCATION_KEY));
  return result;
}

test('startup script has valid POSIX shell syntax', () => {
  const result = spawnSync(shell, ['-n'], { input: script, encoding: 'utf8' });
  assert.ifError(result.error);
  assert.equal(result.status, 0, result.stderr);
});

test('LBS is optional and disabled configurations preserve existing startup', () => {
  for (const env of [{}, { GEOLOCATION_ENABLE: 'false' }]) {
    const result = run(env);
    assert.equal(result.status, 0, result.stderr);
    assert.equal(result.stderr, '');
  }
});

test('enabled LBS accepts explicit carrier codes, including leading-zero MNC', () => {
  for (const mnc of ['0', '01', '001', '999']) {
    const result = run({ ...lbsEnv, GEOLOCATION_MNC: mnc });
    assert.equal(result.status, 0, result.stderr);
    assert.equal(result.stderr, '');
  }
});

test('enabled LBS rejects a missing or whitespace-only provider key', () => {
  for (const key of ['', '   ']) {
    const result = run({ ...lbsEnv, GEOLOCATION_KEY: key });
    assert.equal(result.status, 1);
    assert.match(result.stderr, /GEOLOCATION_KEY is required/);
  }
});

test('enabled LBS requires a three-digit MCC rather than a country calling code', () => {
  for (const mcc of ['', '44', '000', '1234', 'abc', '234 ']) {
    const result = run({ ...lbsEnv, GEOLOCATION_MCC: mcc });
    assert.equal(result.status, 1);
    assert.match(result.stderr, /GEOLOCATION_MCC/);
  }
});

test('enabled LBS rejects missing or malformed MNC values', () => {
  for (const mnc of ['', '-1', '1234', 'abc', '1.5', '15 ']) {
    const result = run({ ...lbsEnv, GEOLOCATION_MNC: mnc });
    assert.equal(result.status, 1);
    assert.match(result.stderr, /GEOLOCATION_MNC/);
  }
});

test('unsupported enable values fail explicitly', () => {
  const result = run({ ...lbsEnv, GEOLOCATION_ENABLE: 'yes' });
  assert.equal(result.status, 1);
  assert.match(result.stderr, /GEOLOCATION_ENABLE must be true or false/);
});

test('database prerequisites are still required when LBS is disabled', () => {
  const result = run({ PGHOST: '' });
  assert.equal(result.status, 1);
  assert.match(result.stderr, /PGHOST is required/);
});

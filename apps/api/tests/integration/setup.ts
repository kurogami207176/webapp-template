import { execSync } from 'child_process';

export async function setup() {
  // Set test database URL
  process.env['DATABASE_URL'] =
    process.env['TEST_DATABASE_URL'] ?? 'postgresql://postgres:postgres@localhost:5432/webapp_test';
  process.env['JWT_SECRET'] = 'test-secret-that-is-long-enough-for-validation';
  process.env['NODE_ENV'] = 'test';

  // Run migrations on test database
  execSync('npx prisma migrate deploy', {
    env: { ...process.env },
    stdio: 'inherit',
  });
}

export async function teardown() {
  const { prisma } = await import('../../src/db/client.js');
  await prisma.$disconnect();
}

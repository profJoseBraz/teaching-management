import { env } from './config/env';
import { createContainer } from './di/container';
import { createApp } from './app';
import { prisma } from './shared/infra/prisma/prisma-client';

async function bootstrap() {
  const container = createContainer();
  const app = createApp(container);

  const server = app.listen(env.PORT, () => {
    console.log(`Gestão Docente API listening on http://localhost:${env.PORT}`);
    console.log(`Swagger UI: http://localhost:${env.PORT}/api/docs`);
  });

  const shutdown = async () => {
    server.close();
    await prisma.$disconnect();
    process.exit(0);
  };

  process.on('SIGINT', () => {
    void shutdown();
  });
  process.on('SIGTERM', () => {
    void shutdown();
  });
}

bootstrap().catch(async (error) => {
  console.error('Failed to start API', error);
  await prisma.$disconnect();
  process.exit(1);
});

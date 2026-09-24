import { Injectable, NestMiddleware, Logger } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';

@Injectable()
export class LoggingMiddleware implements NestMiddleware {
  private readonly logger = new Logger('HTTP');

  use(req: Request, res: Response, next: NextFunction): void {
    const correlationId =
      (req.headers['x-correlation-id'] as string) ||
      `plz_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    res.setHeader('X-Correlation-ID', correlationId);

    const startTime = Date.now();
    const { method, originalUrl } = req;

    res.on('finish', () => {
      const duration = Date.now() - startTime;
      const { statusCode } = res;

      this.logger.log(
        `[${correlationId}] ${method} ${originalUrl} ${statusCode} - ${duration}ms`,
      );
    });

    next();
  }
}
